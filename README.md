# ObjCWrap

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

ObjCWrap.jl is an Objective-C bridge for Julia. The library allows you to call Objective-C methods using native syntax:

```julia
using ObjCWrap

@classes NSNumber

num = @objc [NSNumber numberWithInt:42]
@objc [num intValue]
```

This makes it easy to wrap Objective-C APIs from Julia.

```julia
using ObjCWrap

framework("AppKit")

@classes NSSound

function play(name::String)
  @objc begin
    sound = [NSSound soundNamed:name]
    if [sound isPlaying] |> Bool
      [sound stop]
    end
    [sound play]
  end
end

play("Purr")
```

Example of working with strings:

```julia
str = @objc [[NSString alloc] initWithUTF8String: "hello"]
plain_chars = @objc [str UTF8String]
s = unsafe_string(plain_chars)
println(s)
```

To make it easier to work with Objective-C in Julia we have defines various aliases such as:

```julia
const YES = true
const NO  = false
const nil = C_NULL
```

ObjCWrap.jl also supports defining classes, using a variant of Objective-C
syntax (which eschews the interface/implementation distinction):

```julia
@class type Foo
  @- (Cdouble) multiply:(Cdouble)x by:(Cdouble)y begin
    x*y # Note that this is Julia code
  end
end

@objc [[Foo new] multiply:5 by:3]
```

Please note that class definitions are still a bit buggy and need further testing.

# History
This code is a fork of [ObjectiveC](https://github.com/JuliaInterop/ObjectiveC.jl) interop package originally created by Mike Innes. It was created before Julia 1.x and thus no longer works.

If you want to help out or fork this code, you can read the `code-guide.md` file to better understand how the wrapping works.

# Installation
This package is not distributed on JuliaHub yet. Thus to install you need to specify the URL directly. Get into package mode on the Julia command line using the ']' key.

    pkg> add https://github.com/ordovician/ObjCWrap.jl

