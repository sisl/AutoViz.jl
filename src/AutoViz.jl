__precompile__(true)

module AutoViz

using Reexport
using Parameters
using StaticArrays
using AutomotiveDrivingModels
using Printf
using LightXML
using Rsvg

@reexport using Colors
@reexport using Cairo

import Reel
Reel.set_output_type("gif")

export
        DEFAULT_CANVAS_WIDTH,
        DEFAULT_CANVAS_HEIGHT

const DEFAULT_CANVAS_WIDTH = 1000
const DEFAULT_CANVAS_HEIGHT = 600

global _rendermode = :fancy

function set_render_mode(m::Symbol)
    global _rendermode
    _rendermode = m
end

export
    COLOR_ASPHALT,
    COLOR_LANE_MARKINGS_WHITE,
    COLOR_LANE_MARKINGS_YELLOW,
    COLOR_CAR_EGO,
    COLOR_CAR_OTHER,
    MONOKAY,
    OFFICETHEME,
    LIGHTTHEME,
    set_color_theme

include("colorscheme.jl")

# Cairo drawing utilities
export
        RenderModel,

        render,
        add_instruction!,
        camera_fit_to_content!,
        camera_move!,
        camera_move_pix!,
        camera_rotate!,
        camera_setrotation!,
        camera_zoom!,
        camera_setzoom!,
        camera_set_pos!,
        camera_set_x!,
        camera_set_y!,
        camera_reset!,
        camera_set!,
        clear_setup!,
        set_background_color!,

        render_paint,
        render_text,
        render_circle,
        render_arc,
        render_rect,
        render_round_rect,
        render_car,
        render_vehicle,
        render_point_trail,
        render_line,
        render_closed_line,
        render_fill_region,
        render_line_segment,
        render_dashed_line,
        render_arrow,
        render_colormesh,
        grayscale_transform,
        render_fancy_car,
        render_fancy_pedestrian

include("rendermodels.jl")
include("fancy_render.jl")

# Cameras
export
    Camera,
    StaticCamera,
    FitToContentCamera,
    CarFollowCamera,
    SceneFollowCamera


include("cameras.jl")

# main interface
export  render!,
        render,
        get_pastel_car_colors

include("interface.jl")

# renderable interface
export  Renderable,
        render,
        isrenderable,
        write_to_svg,
        ArrowCar


include("renderable.jl")
include("arrowcar.jl")
include("text.jl")

# Overlays
export  SceneOverlay,
        TextOverlay,
        Overwash,
        NeighborsOverlay,
        CarFollowingStatsOverlay,
        MarkerDistOverlay,
        HistogramOverlay,
        IDOverlay,
        TextParams,
        drawtext,
        LineToCenterlineOverlay,
        LineToFrontOverlay,
        BlinkerOverlay,
        RenderableOverlay


include("overlays.jl")

export PNGFrames,
       SVGFrames

include("reel_drive.jl")

# Convenient implementation for roadway and vehicle rendering

include("roadways.jl")
include("vehicles.jl")


end # module
