export message

Base.eltype(::Type{Type{T}}) where T = T

"""
    ccal(f, R, ts, vals...)
Calls a C-function `f` with return type `R`, argument types `ts` and argument
values `vals`.
"""
function ccal(f, R, ts, vals...)
  AS = Expr(:tuple, ts...)
  @eval ccall($f, $R, $AS, $(vals...))
end

# Doesn't make a lot of sense, but we use this to convert
# Julia UTF-8 strings to objects in Foundation
toobject(o::Object) = o
toobject(c::Class) = c
toobject(p::Ptr) = p

ctype(x) = x
ctype(o::Type{Object}) = Ptr{Cvoid}
ctype(s::Type{Selector}) = Ptr{Cvoid}
ctype(a::AbstractArray) = map(ctype, a)

const cmsgsend = cglobal(:objc_msgSend)

"""
    message(obj, sel, args...)
Send a message to an objective-c object `obj` using selector `sel`.
"""
function message(obj::Union{Class, Object}, sel::Selector, args...)
  obj = toobject(obj)
  clarse = class(obj)
  m = method(clarse, sel)
  m == C_NULL && error("$clarse does not respond to $sel")
  types = signature(m)
  ctypes = ctype(types)

  args = Any[args...]
  for i = 1:length(args)
    types[i+3] == Object && (args[i] = toobject(args[i]))
  end

  result = ccal(cmsgsend, ctypes[1], tuple(ctypes[2:end]...),
                obj, sel, args...)
  types[1] in (Object, Selector) && return types[1](result)
  return result
end
