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

macro objc(ex)
  esc(objcm(ex))
end

# Import Classes

macro classes(names)
    if typeof(names) == Symbol
        names = [names]
    else
        names = names.args
    end
    classdefs = [:(const $(esc(name)) = Class($(Expr(:quote, name))))
                for name in names]
    Expr(:block, classdefs..., nothing)
end
