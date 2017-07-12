__precompile__(true)

module AutoViz

using Reexport
using Parameters
using AutomotiveDrivingModels

@reexport using Colors
@reexport using Cairo

import Reel
Reel.set_output_type("gif")

export
        DEFAULT_CANVAS_WIDTH,
        DEFAULT_CANVAS_HEIGHT,
        render!,
        get_pastel_car_colors

const DEFAULT_CANVAS_WIDTH = 1000
const DEFAULT_CANVAS_HEIGHT = 600

include("colorscheme.jl")
include("rendermodels.jl")

include("cameras.jl")
include("interface.jl")
include("overlays.jl")
include("reel_drive.jl")

include("1d/main.jl")
include("2d/main.jl")



end # module
