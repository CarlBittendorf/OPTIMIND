using Pkg

if isfile("Project.toml") && isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end

include("types.jl")
include("../secrets.jl")

using Chain, DataFrames, MiniLoggers, PyCall, HTTP, JSON, Hyperscript
using Dates

@pyinclude("src/email.py")

include("utils.jl")
include("constants.jl")
include("interaction_designer.jl")
include("email.jl")
include("logging.jl")