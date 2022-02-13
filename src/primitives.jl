export Selector, Class, Object
export @sel_str

# import Base: show, convert, unsafe_convert, super, methods
import Base: show, unsafe_convert

int2bool(x::Integer) = x != 0

## Selector ###############################################

struct Selector
  ptr::Ptr{Cvoid}
  # Selector(ptr::Ptr{CVoid}) = new(ptr)
end

unsafe_convert(::Type{Ptr{Cvoid}}, sel::Selector) = sel.ptr

"Turn a selector name into a selector"
function Selector(name::Union{AbstractString, Symbol})
  Selector(ccall(:sel_registerName, Ptr{Cvoid}, (Ptr{Cchar},),
                 pointer(string(name))))
end

macro sel_str(name)
  Selector(name)
end

selname(s::Ptr{Cvoid}) =
  ccall(:sel_getName, Ptr{Cchar}, (Ptr{Cvoid},),
        s) |> unsafe_string
        
name(sel::Selector) = selname(sel.ptr)

function show(io::IO, sel::Selector)
  print(io, "sel")
  show(io, string(name(sel)))
end

## Class ###############################################

struct Class
  ptr::Ptr{Cvoid}
  # Class(ptr::Ptr{Void}) = new(ptr)
end

"Get class pointer"
classptr(name) = ccall(:objc_getClass, Ptr{Cvoid}, (Ptr{Cchar},),
                       pointer(string(name)))
                       
unsafe_convert(::Type{Ptr{Cvoid}}, class::Class) = class.ptr

function Class(name::Union{AbstractString, Symbol})
  ptr = classptr(name)
  ptr == C_NULL && error("Couldn't find class $name")
  return Class(ptr)
end

classexists(name) = classptr(name) ≠ C_NULL


function name(class::Class)
  cname = ccall(:class_getName, Ptr{Cchar}, (Ptr{Cvoid},), class) 
  @assert cname != nil
  Symbol(unsafe_string(cname))
end

function ismeta(class::Class)
  ismeta = ccall(:class_isMetaClass, Cint, (Ptr{Cvoid},), class)
  int2bool(ismeta)
end

function show(io::IO, class::Class)
  ismeta(class) && print(io, "^")
  print(io, name(class))
end


## Object ###############################################
function release end

mutable struct Object
  ptr::Ptr{Cvoid}
  # function Object(ptr)
  #     obj = new(ptr)
  #     function f(t)
  #         # msg = string("About to release ", repr(UInt(t.ptr)))
  #         # TODO: Remove println, just for debugging. Call release directly
  #         @async begin
  #             println("Releasing $t")
  #             release(t)
  #         end
  #     end
  #     finalizer(f, obj)
  # end
end

unsafe_convert(::Type{Ptr{Cvoid}}, obj::Object) = obj.ptr

class(obj) =
  ccall(:object_getClass, Ptr{Cvoid}, (Ptr{Cvoid},),
        obj) |> Class

methods(obj::Object) = methods(class(obj))

# function show(io::IO, obj::Object)
#     addr = repr(UInt(obj.ptr))
#     println(io, class(obj), " Object $addr")
# end


