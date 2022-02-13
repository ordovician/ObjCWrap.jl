export YES, NO, nil
export hostname
export release # TODO: remove
export loadbundle, framework

@classes NSString, NSBundle, NSArray, NSObject, NSHost
export   NSString, NSBundle, NSArray, NSObject, NSHost

const YES = true
const NO  = false
const nil = C_NULL

toobject(s::String) = @objc [[NSString alloc] initWithUTF8String:s]

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

