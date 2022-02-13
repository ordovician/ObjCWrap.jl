using Base.Meta

export @objc, @classes
export objcm # Just for easy debugging. Don't normally export

callerror() = error("ObjectiveC call: use [obj method] or [obj method:param ...]")

function flatvcat(ex::Expr)
  any(ex->isexpr(ex, :row), ex.args) || return ex
  flat = Expr(:hcat)
  for row in ex.args
    isexpr(row, :row) ?
      push!(flat.args, row.args...) :
      push!(flat.args, row)
  end
  return calltransform(flat)
end

"""
    calltransform(ex::Expr)

Transform and expression such as `[NSString new]` into 
    
    message(NSString, Selector("new"))
    
For this to work you would have had to have loaded the class `NSString` first.
This is done with:

    @classes NSString
    
That line basically translates into the following Julia code:

    NSString = Class("NSString")
"""
function calltransform(ex::Expr)
  obj = objcm(ex.args[1])
  params = ex.args[2:end]
  isempty(params) && callerror()
  
  # Simple case such as [NSString new]
  # params[1] would be symbol :new
  if typeof(params[1]) == Symbol
    if length(params) > 1
        callerror()
    end
    return :($message($obj, $(Selector(params[1]))))
  end
  
  # Make sure each parameter is valid
  # Assume params = [setObject:12 forKey: foo]
  ok = all(params) do param
      # assume param = [call:, :, setObject, 12]
      isexpr(param, :call, 3) &&  
      param.args[1] == :(:)   &&  
      typeof(param.args[2]) == Symbol
  end
  ok || callerror()
  
  param_names = [param.args[2] for param in params]
  
  # Turn e.g. [setObject:12 forKey: foo] into "setObject:forKey:"
  selector = map(param_names) do param
    string(param, ':')
  end |> join |> Selector
  
  values = [objcm(param.args[3]) for param in params]
  :($message($obj, $selector, $(values...)))
end

function objcm(ex::Expr)
  if isexpr(ex, :hcat)
      calltransform(ex)
  elseif isexpr(ex, :vcat)
      flatvcat(ex)
  elseif isexpr(ex, [:block, :let])
      Expr(:block, map(objcm, ex.args)...)
  else
      esc(ex)
  end
end

objcm(ex) = ex

"""
    @objc expr
Interprets `expr` as Objective-C code to call. This creates a new string:

    str = @objc [NSString new]
"""
macro objc(ex)
  esc(objcm(ex))
end

# Import Classes

"""
    @classes klass
     
Imports the class `klass`. It basically assigns a class object to the
given Julia variable `klass`. So this would lookup the `NSString` class and assign
the corresponding `NSString` class object to the a variable named `NSString`

    @classes NSString

You can load multiple classes:

    @classes NSString, NSBundle, NSArray, NSObject
"""
macro classes(names)
    if typeof(names) == Symbol
        names = [names]
    else
        names = names.args
    end
    
    classdefs = map(names) do name
        :(const $(esc(name)) = Class($(Expr(:quote, name))))    
    end

    Expr(:block, classdefs..., nothing)
end
