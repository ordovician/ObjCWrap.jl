export @class, @-
export makefunc, MethodDef, Signature, Param

# TODO: Remove. Just added to help debug in REPL
export allocclass, createclass, register

# function createmethod end

"""
    allocclass(name::Union{AbstractString, Symbol}, super::Class) -> Class

Allocate memory for structures to represent a new class named `name` which is
a subclass of `super`. This just creates the class objects. You still need to
register the class returned with `register(class)`.
"""
function allocclass(name::Union{AbstractString, Symbol}, super::Class)
  ptr = ccall(:objc_allocateClassPair, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cchar}, Csize_t),
              super, name, 0)
  ptr == C_NULL && error("Couldn't allocate class $name")
  return Class(ptr)
end

function register(class::Class)
  ccall(:objc_registerClassPair, Cvoid, (Ptr{Cvoid},),
        class)
  return class
end

"""
    createclass(name::Union{AbstractString, Symbol}, super::Class) -> Class
Allocates and register a new class named `name` which is sublcassing `super`.
"""
function createclass(name::Union{AbstractString, Symbol}, super::Class)
    allocclass(name, super) |> register
end

getmethod(class::Class, sel::Selector) =
  ccall(:class_getInstanceMethod, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}),
        class, sel)

methodtypeenc(method::Ptr) =
  ccall(:method_getTypeEncoding, Ptr{Cchar}, (Ptr{Cvoid},),
        method) |> unsafe_string

methodtypeenc(class::Class, sel::Selector) = methodtypeenc(getmethod(class, sel))

methodtype(args...) = methodtypeenc(args...) |> parseencoding

replacemethod(class::Class, sel::Selector, imp::Ptr{Cvoid}, types::String) =
  ccall(:class_replaceMethod, Bool, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cchar}),
        class, sel, imp, types)

function setmethod(class::Class, sel::Selector, imp::Ptr{Cvoid}, types::String)
  meth = getmethod(class, sel)
  meth ≠ C_NULL && methodtype(meth) != parseencoding(types) &&
    error("New method $(name(sel)) of $class must match $(methodtype(meth))")
  replacemethod(class, sel, imp, types)
end

### Syntax ###################

"""
    @class(classname, body)
    
Define a new Objective-C class with method. Instance methods are marked
with a `@-`. Class methods are not yet supported.

# Examples
```julia-repl
julia> @class Foobar begin
          @- (Cdouble) multiply:(Cdouble)x by:(Cdouble)y begin
            x * y
          end
       end
       
julia> foo = @objc [[Foobar alloc] init]

julia> @objc [foo multiply:4 by:5]
20.0
```
"""
macro class(cname, body)
    name, supername = class_name(cname)
    if !isexpr(body, :block)
        error("You need to provide a block for class methods")
    end

    if classexists(name)
        classobj = Class(name)
    else
        classobj = createclass(name, Class(supername))
    end
    
    methodexpressions = filter(body.args) do arg
        isexpr(arg, :macrocall)
    end

    for mexpr in methodexpressions
        sign, fnbody = eval(mexpr)
        mdef = makefunc(sign, fnbody)
        setmethod(classobj, mdef.selector, mdef.cfunc, mdef.typestr)
    end
    :(const $(esc(name)) = Class($(Expr(:quote, name))))
end

function class_name(cname::Expr)
    if cname.head == :(<:)
        (cname.args[1], cname.args[2])
    else
        error("You need to write class name or 'classname <: superclass'")
    end
end

function class_name(cname::Symbol)
    (cname, :NSObject)
end

### Methods ###################

"Represent an ObjC parameter such as `multiply:(Ddouble)x`"
struct Param
    name::Symbol
    kind::Symbol
    value::Symbol
end

"ObjC method signature"
struct Signature
    params::Vector{Param}
    returntype::Symbol
end

"Method definition which we can register with a ObjC class"
struct MethodDef
    selector::Selector  # Selector which will cause method to be called
    typestr::String     # Tells ObjC what type each argument each
    cfunc::Ptr{Cvoid}   # C function pointer to implementation of method
end

"Produce a selector from a signature"
function Selector(sig::Signature)
    map(sig.params) do param
      string(param.name, ':')
    end |> join |> Selector    
end

"An arbitrary name to use for Julia functions registered as ObjC method"
funcname(sign::Signature) = Symbol(join([p.name for p in sign.params], '_'))    


argtypes(sign::Signature) = (param.kind for param in sign.params)

"""
    argtuple(sig::Signature) -> Expr
Returns a tuple expression with all the types of the arguments in the signature `sig`.
"""
argtuple(sign::Signature) = Expr(:tuple, argtypes(sign)...)

macro -(rettype::Symbol, parts...)
    # string(rettype)
    # dump(params[1])
    fnbody = parts[end]
    params = map(parts[1:end-1]) do part
        Param(
            part.args[2],
            part.args[3].args[2],
            part.args[3].args[3]
        )
    end
    sign = Signature(collect(params), rettype)
    (sign, fnbody)
end

"Create a Julia function with signature `sign` and `body`"
function makefunc(sign::Signature, body::Expr)
    atuple = argtuple(sign)
    params = map(sign.params) do param
        :($(param.value)::$(param.kind))
    end
    
    # Code in method without line number info
    stmts = filter(body.args) do exp
        !isa(exp, LineNumberNode)
    end
    
    # NOTE: Not sure why we cannot use method name directly for
    # @cfunction. That is why we store function in fn    
    methodname = funcname(sign)
    fn = @eval begin
       function $methodname($(params...)) 
           $(stmts...)
       end
    end
    
    # Turn Julia function in a C function
    @eval begin
        imp = @cfunction($fn, $(sign.returntype), $atuple)
        typestr = encodetype(
            $(sign.returntype), 
            Object, 
            Selector, 
            $(argtypes(sign)...)) 
    end
    
    MethodDef(Selector(sign), typestr, imp)
end
