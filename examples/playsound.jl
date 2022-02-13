# This works best in the REPL
using ObjCWrap

# Load AppKit which contains the NSSound class
framework("AppKit")

# Load NSSound class. In Julia terms, this means setting a variable
# named NSSound to point to the NSSound class object
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

