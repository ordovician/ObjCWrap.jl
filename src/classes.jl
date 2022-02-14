export @class, @-

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

macro class(cname, body)
    name, supername = class_name(cname)    
end

function class_name(cname::Expr)
    if cname.head == :(<:)
        (string(cname.args[1]), string(cname.args[2]))
    else
        error("You need to write class name or 'classname <: superclass'")
    end
end

function class_name(cname::Symbol)
    (string(cname), "NSObject")
end

### Methods ###################

macro -(rettype::Symbol, params...)
    string(rettype)
    dump(params[1])
end