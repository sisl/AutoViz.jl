module AutoViz

using Reexport

using AutomotiveDrivingModels

@reexport using Colors
@reexport using Cairo

import Reel

# using Reactive
# import Gtk
# using PGFPlots

export
        DEFAULT_CANVAS_WIDTH,
        DEFAULT_CANVAS_HEIGHT,
        render!

const DEFAULT_CANVAS_WIDTH = 1000
const DEFAULT_CANVAS_HEIGHT = 600

include(Pkg.dir("AutoViz", "src", "colorscheme.jl"))
include(Pkg.dir("AutoViz", "src", "rendermodels.jl"))
include(Pkg.dir("AutoViz", "src", "camera.jl"))

include(Pkg.dir("AutoViz", "src", "render_roadways.jl"))
include(Pkg.dir("AutoViz", "src", "render_vehicles.jl"))
include(Pkg.dir("AutoViz", "src", "render_scenes.jl"))

include(Pkg.dir("AutoViz", "src", "overlays.jl"))

# include(Pkg.dir("AutomotiveDrivingModels", "src", "viz", "reel_drive.jl"))
# include(Pkg.dir("AutomotiveDrivingModels", "src", "viz", "gtk.jl"))

end # module
