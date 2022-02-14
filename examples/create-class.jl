# Try this out by copy pasting each line into the Julia REPL
# That helps understand how an Objective-C class with the ObjC runtime system
# using Julia
using ObjCWrap

if !classexists(:Foobar)
    Foobar = createclass(:Foobar, NSObject)
end

# Create an instance
foo = @objc [[Foobar alloc] init]

function multiply(x::Float64, y::Float64)
   x * y 
end

imp = @cfunction(multiply, Cdouble, (Cdouble, Cdouble))
    
# Call the C function we just made
result = ccall(imp, Cdouble, (Cdouble, Cdouble), 3, 4)

# Register method on Foobar class
# Notice that the signature includes: return value, self, selector, arg1, arg2
typestr = ObjCWrap.encodetype(Cdouble, Object, Selector, Cdouble, Cdouble) 
ObjCWrap.setmethod(Foobar, sel"multiply:by:", imp, typestr)

# Check that the method is actually there
m = method(Foobar, sel"multiply:by:")
types = signature(m)
ctypes = ctype(types)


# Without DSL
result = message(foo, sel"multiply:by:", 3, 4)

# With DSL
result = @objc [foo multiply:3 by:4]
