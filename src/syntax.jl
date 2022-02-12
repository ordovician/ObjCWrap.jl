using Base.Meta

export @objc, @classes

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
  args = ex.args[2:end]
  isempty(args) && callerror()
  if typeof(args[1]) == Symbol
    length(args) > 1 && callerror()
    return :($message($obj, $(Selector(args[1]))))
  end
  all(arg->isexpr(arg, :(:)) && isexpr(arg.args[1], Symbol), args) || callerror()
  msg = join(vcat([arg.args[1] for arg in args], ""), ":") |> Selector
  args = [objcm(arg.args[2]) for arg in args]
  :($message($obj, $msg, $(args...)))
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
