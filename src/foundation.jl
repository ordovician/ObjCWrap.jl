export YES, NO, nil
export hostname
export release # TODO: remove
export loadbundle, framework

@classes NSString, NSNumber, NSBundle, NSArray, NSObject, NSHost
export   NSString, NSNumber, NSBundle, NSArray, NSObject, NSHost

const YES = true
const NO  = false
const nil = C_NULL

toobject(s::String) = @objc [[NSString alloc] initWithUTF8String:s]

# Conversion of numbers to NSNumber
# See: https://developer.apple.com/documentation/foundation/nsnumber?language=objc
toobject(num::Signed) = @objc [NSNumber numberWithInt:num]
toobject(num::Unsigned) = @objc [NSNumber numberWithUnsignedInt:num]
toobject(num::Float32) = @objc [NSNumber numberWithFloat:num]
toobject(num::Float64) = @objc [NSNumber numberWithDouble:num]
toobject(num::Bool) = @objc [NSNumber numberWithBool:num]

function hostname()
  cstr = @objc [[[NSHost currentHost] localizedName] UTF8String]
  unsafe_string(cstr)
end

release(obj) = @objc [obj release]

# function Base.gc(obj::Object)
#   finalizer(obj, release)
#   obj
# end

function loadbundle(path)
  bundle = @objc [NSBundle bundleWithPath:path]
  bundle.ptr |> Int |> int2bool || error("Bundle $path not found")
  loadedStuff = @objc [bundle load]
  loadedStuff |> int2bool || error("Couldn't load bundle $path")
  return
end

framework(name) = loadbundle("/System/Library/Frameworks/$name.framework")

