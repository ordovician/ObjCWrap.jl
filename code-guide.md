# Guide to Code

This code allows us to write something that looks like Objective-C code such as:

    @objc [NSString new]

Using the `@objc` macro (defined in `syntax.jl`) we transform this to a Julia call which looks like this:

    message(Class("NSString"), Selector("new"))

This is all based on calling various C functions defined in Apple's Objective-C runtime. See [Objective-C Runtime documentation](https://developer.apple.com/documentation/objectivec/objective-c_runtime?language=objc).

This code translates to the following low-level C call in Julia. First we get a pointer to some C struct representing the class named `NSString`:

    rettype = Ptr{Cvoid}
    argtypes = (Ptr{Cchar},)
    classname = pointer(string("NSString"))
    class = ccall(:objc_getClass, rettype, argtypes, classname)

Next we get a pointer to a C struct representing the selector. In Objective-C terminology, the _selector_ is what we use to select the method to call. In essence it is just a text string of the method name. However to speed up things Objective-C requires reuse the same string over and over again. Thus for a given method name, we need to lookup a point to the already registered name. That is what we call the selector.

    selname = pointer(string("new"))
    sel = call(:sel_registerName, Ptr{Cvoid}, (Ptr{Cchar},), selname)

Once we got a pointer to the class and the selector we can lookup the method registered on the given class for that selector. It is essentially a C function pointer which we are looking up. We are looking a pointer to the funcion which implements `[NSString new]`.

    argtypes = (Ptr{Cvoid}, Ptr{Cvoid})
    m = ccall(:class_getInstanceMethod, rettype, argtypes, class, sel)

We later make a call to `objc_msgSend` to actually send the message to the class object `NSString`. It is worth nothing that `objc_msgSend` is not a normal C function. It is implemented in assembly and has a bit unsual call stack behavior. I suppose that is why `cglobal` is used.

    cmsgsend = cglobal(:objc_msgSend)
    argstypes = (Ptr{Cvoid}, Ptr{Cvoid})
    result = ccall(cmsgsend, Ptr{Cvoid}, argstypes, class, sel)

    objc_msgSend(class("NSString"), selector("new"))
    