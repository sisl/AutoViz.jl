abstract type SceneOverlay end

@with_kw mutable struct TextParams
    size::Int = 12
    color::Colorant = colorant"white"
    x::Int = 20
    y_start::Int = 20
    y_jump::Int = round(Int, size*1.2)
end
function drawtext(text::AbstractString, y::Int, rendermodel::RenderModel, t::TextParams; coordinate_system::Symbol=:camera_pixels)
    add_instruction!(rendermodel, render_text, (text, t.x, y, t.size, t.color), coordinate_system=coordinate_system)
    y + t.y_jump
end

"""
    TextOverlay

Displays some text at the desired location. 
The coordinates and size units are in pixels by default. 
The option `coordinate_system` allows to use different units.

# Fields 
- `text::Vector{String}`
- `color::Colorant = colorant"white"`
- `font_size::Int = 10`
- `pos::VecE2 = VecE2(10, font_size)`
- `line_spacing::Float64 = 1.5` multiple of `font_size`
- `coordinate_system::Symbol=:camera_pixels`
"""
@with_kw mutable struct TextOverlay <: SceneOverlay
    text::Vector{String}
    color::Colorant = colorant"white"
    font_size::Int = 10 # [pix]
    pos::VecE2 = VecE2(10, font_size)
    line_spacing::Float64 = 1.5 # multiple of font_size
    coordinate_system::Symbol=:camera_pixels
end
function add_renderable!(rendermodel::RenderModel, overlay::TextOverlay)
    x = overlay.pos.x
    y = overlay.pos.y
    y_jump = overlay.line_spacing*overlay.font_size
    for line in overlay.text
        add_instruction!(rendermodel, render_text, (line, x, y, overlay.font_size, overlay.color), coordinate_system=overlay.coordinate_system)
        y += y_jump
    end
    rendermodel
end

# method for new interface
function add_renderable!(rendermodel::RenderModel, overlay::TextOverlay, scene)
    x = overlay.pos.x
    y = overlay.pos.y
    y_jump = overlay.line_spacing*overlay.font_size
    for line in overlay.text
        add_instruction!(rendermodel, render_text, (line, x, y, overlay.font_size, overlay.color), coordinate_system=overlay.coordinate_system)
        y += y_jump
    end
    rendermodel
end

"""
    Overwash 
overlay that renders a plain color on the whole canvas.
"""
mutable struct Overwash <: SceneOverlay
    color::Colorant
end
function add_renderable!(rendermodel::RenderModel, overlay::Overwash)
    add_instruction!(rendermodel, render_paint, (overlay.color,))
    rendermodel
end

"""
    HistogramOverlay

Display a bar at the specified position `pos`, the bar is of size `width`, `height` and is filled up to a given proportion of its height. 
The fill proportion is set using `val`, it should be a number between 0 and 1. If it is 0, the bar is not filled, if it is 1 it is filled to the top.

# Fields 
- `pos::VecE2{Float64} = VecE2(0.,0.)`
- `coordinate_system::Symbol = :scene`
- `label::String = "histogram"`
- `val::Float64 = 0.5` should be between 0 and 1
- `width::Float64 = 2.`
- `height::Float64 = 5.`
- `fill_color::Colorant = colorant"blue"`
- `line_color::Colorant = colorant"white"`
- `font_size::Int64 = 15 # [pix]`
- `label_pos::VecSE2{Float64} = pos + VecSE2(0., -height/2)` position of the label

"""
@with_kw mutable struct HistogramOverlay <: SceneOverlay
    pos::VecE2{Float64} = VecE2(0.,0.)
    coordinate_system::Symbol = :scene
    label::String = "histogram"
    val::Float64 = 0.5 # should be between 0 and 1
    width::Float64 = 2.
    height::Float64 = 5. 
    fill_color::Colorant = colorant"blue"
    line_color::Colorant = colorant"white"
    font_size::Int64 = 15 # [pix]
    label_pos::VecSE2{Float64} = pos + VecSE2(0., -height/2)
end

function AutoViz.add_renderable!(rendermodel::RenderModel, overlay::HistogramOverlay)
    # render value 
    add_instruction!(rendermodel, render_rect, (overlay.pos.x, overlay.pos.y, overlay.width, overlay.val*overlay.height,overlay.fill_color, true, false), coordinate_system=overlay.coordinate_system)
    # render histogram outline 
    add_instruction!(rendermodel, render_rect, (overlay.pos.x, overlay.pos.y, overlay.width, overlay.height, overlay.line_color), coordinate_system=overlay.coordinate_system)
     # label 
    add_instruction!(rendermodel, render_text, (overlay.label, overlay.label_pos.x, overlay.label_pos.y, overlay.font_size, overlay.line_color), coordinate_system=overlay.coordinate_system)
end

"""
    IDOverlay

Display the ID on top of each entity in a scene.
The text can be customized with the `color::Colorant` (default=white) and `font_size::Int64` (default=15) keywords.
The position of the ID can be adjusted using `x_off::Float64` and `y_off::Float64` (in camera coordinates).

# Fields
- `color::Colorant = colorant"white"`
- `font_size::Int = 15`
- `x_off::Float64 = 0.`
- `y_off::Float64 = 0.`
"""
@with_kw mutable struct IDOverlay <: SceneOverlay
    color::Colorant = colorant"white"
    font_size::Int = 15
    x_off::Float64 = 0.
    y_off::Float64 = 0.
end

function AutoViz.add_renderable!(rendermodel::RenderModel, overlay::IDOverlay, scene::Frame{Entity{S,D,I}}, env::E) where {S,D,I,E}
    font_size = overlay.font_size
    for veh in scene
        add_instruction!(rendermodel, render_text, ("$(veh.id)", veh.state.posG.x + overlay.x_off, veh.state.posG.y + overlay.y_off, font_size, overlay.color), coordinate_system=:scene)
    end
    return rendermodel
end


@with_kw mutable struct LineToCenterlineOverlay <: SceneOverlay
    target_id::Int # if -1 does it for all
    line_width::Float64 = 0.5
    color::Colorant = colorant"blue"
end
function add_renderable!(rendermodel::RenderModel, overlay::LineToCenterlineOverlay, scene::Frame{Entity{S,D,I}}, roadway::Any) where {S,D,I}

    if overlay.target_id < 0
        target_inds = 1:length(scene)
    else
        target_inds = overlay.target_id:overlay.target_id
    end

    for ind in target_inds
        veh = scene[ind]
        footpoint = get_footpoint(veh)
        add_instruction!(rendermodel, render_line_segment,
            (veh.state.posG.x, veh.state.posG.y, footpoint.x, footpoint.y, overlay.color, overlay.line_width))
    end

    rendermodel
end


@with_kw mutable struct LineToFrontOverlay <: SceneOverlay
    target_id::Int # if -1 does it for all
    line_width::Float64 = 0.5
    color::Colorant = colorant"blue"
end
function add_renderable!(rendermodel::RenderModel, overlay::LineToFrontOverlay, scene::Frame{Entity{S,D,I}}, roadway::Roadway) where {S,D,I}

    if overlay.target_id < 0
        target_inds = 1:length(scene)
    else
        target_inds = overlay.target_id:overlay.target_id
    end

    for ind in target_inds
        veh = scene[ind]
        veh_ind_front = get_neighbor_fore_along_lane(scene, ind, roadway).ind
        if veh_ind_front != nothing
            v2 = scene[veh_ind_front]
            add_instruction!(rendermodel, render_line_segment,
                (veh.state.posG.x, veh.state.posG.y, v2.state.posG.x, v2.state.posG.y, overlay.color, overlay.line_width))
        end
    end

    rendermodel
end

"""
    BlinkerOverlay
Displays a circle on one of the top corner of a vehicle to symbolize a blinker. 
fields: 
- on: turn the blinker on
- right: blinker on the top right corner, if false, blinker on the left 
- veh: the vehicle for which to display the blinker 
- color: the color of the blinker
- size: the size of the blinker 
""" 
@with_kw struct BlinkerOverlay <: SceneOverlay
    on::Bool = false 
    right::Bool = true
    veh::Vehicle = Vehicle(VehicleState(), VehicleDef(), 0)
    color::Colorant = colorant"0xFFEF00" # yellow 
    size::Float64 = 0.3
end

function add_renderable!(rendermodel::RenderModel, overlay::BlinkerOverlay)
    if !overlay.on
        return nothing 
    end
    if overlay.right 
        pos = get_front(overlay.veh) + polar(overlay.veh.def.width/2, overlay.veh.state.posG.θ - pi/2)
    else
        pos = get_front(overlay.veh) + polar(overlay.veh.def.width/2, overlay.veh.state.posG.θ + pi/2)
    end
    add_instruction!(rendermodel, render_circle, (pos.x, pos.y, overlay.size, overlay.color))    
end

"""
    CarFollowingStatsOverlay

Displays statistics about the front neighbor of the car of id `target_id`.

# Constructor

`CarFollowingStatsOverlay(;target_id, verbosity=1, color=colorant"white", font_size=10)`
"""
@with_kw mutable struct CarFollowingStatsOverlay <: SceneOverlay
    target_id::Int
    verbosity::Int = 1
    color::Colorant = colorant"white"
    font_size::Int = 10 
end
function add_renderable!(rendermodel::RenderModel, overlay::CarFollowingStatsOverlay, scene::Frame{Entity{S,D,I}}, roadway::Roadway) where {S,D,I}

    font_size = overlay.font_size
    text_y = font_size
    text_y_jump = round(Int, font_size*1.2)
    fmt_txt = @sprintf("id %d", overlay.target_id)
    add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
        text_y += text_y_jump

    veh_index = findfirst(overlay.target_id, scene)
    if veh_index != nothing
        veh = scene[veh_index]

        if overlay.verbosity ≥ 2
            add_instruction!( rendermodel, render_text, ("posG: " * string(veh.state.posG), 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
            text_y += text_y_jump
            add_instruction!( rendermodel, render_text, ("posF: " * string(veh.state.posF), 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
            text_y += text_y_jump
        end
        fmt_txt = @sprintf("speed: %0.3f", veh.state.v)
        add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
        text_y += text_y_jump


        foreinfo = get_neighbor_fore_along_lane(scene, veh_index, roadway; max_distance_fore=Inf)
        if foreinfo.ind != nothing
            v2 = scene[foreinfo.ind]
            rel_speed = v2.state.v - veh.state.v
            fmt_txt = @sprintf("Δv = %10.3f m/s", rel_speed)
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
            text_y += text_y_jump
            fmt_txt = @sprintf("Δs = %10.3f m/s", foreinfo.Δs)
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
            text_y += text_y_jump

            if overlay.verbosity ≥ 2
                add_instruction!( rendermodel, render_text, ("posG: " * string(v2.state.posG), 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
                text_y += text_y_jump
                add_instruction!( rendermodel, render_text, ("posF: " * string(v2.state.posF), 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
                text_y += text_y_jump
                fmt_txt = @sprintf("speed: %.3f", v2.state.v)
                add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
                text_y += text_y_jump
            end
        else
            fmt_txt = @sprintf("no front vehicle")
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
        end
    else
        fmt_txt = @sprintf("vehicle %d not found", overlay.target_id)
        add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), coordinate_system=:camera_pixels)
    end

    rendermodel
end
""" 
    NeighborsOverlay

Draws a line between a vehicle and its neighbors. The neighbors are linked with different colors depending on their lanes.
This overlay needs to be wrapped as a RenderableOverlay which needs a scene and a roadway to perform the calculation of the neighbors.

# Fields 

-  `target_id::Int`
-  `color_L::Colorant = colorant"blue"`
-  `color_M::Colorant = colorant"green`
-  `color_R::Colorant = colorant"red"`
-  `line_width::Float64 = 0.5` 
-  `textparams::TextParams = TextParams()`
"""
@with_kw mutable struct NeighborsOverlay <: SceneOverlay
    target_id::Int
    color_L::Colorant = colorant"blue"
    color_M::Colorant = colorant"green"
    color_R::Colorant = colorant"red"
    line_width::Float64 = 0.5 # [m]
    textparams::TextParams = TextParams()
end
function add_renderable!(rendermodel::RenderModel, overlay::NeighborsOverlay, scene::Frame{Entity{S,D,I}}, roadway::Roadway) where {S,D,I}

    textparams = overlay.textparams
    yₒ = textparams.y_start
    Δy = textparams.y_jump

    vehicle_index = findfirst(overlay.target_id, scene)
    if vehicle_index != nothing

        veh_ego = scene[vehicle_index]
        t = veh_ego.state.posF.t
        ϕ = veh_ego.state.posF.ϕ
        v = veh_ego.state.v
        len_ego = veh_ego.def.length

        fore_L = get_neighbor_fore_along_left_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_L.ind != nothing
            veh_oth = scene[fore_L.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_L, overlay.line_width))
            drawtext(@sprintf("d fore left:   %10.3f", fore_L.Δs), yₒ + 0*Δy, rendermodel, textparams)
        end

        fore_M = get_neighbor_fore_along_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_M.ind != nothing
            veh_oth = scene[fore_M.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_M, overlay.line_width))
            drawtext(@sprintf("d fore middle: %10.3f", fore_M.Δs), yₒ + 1*Δy, rendermodel, textparams)
        end

        fore_R = get_neighbor_fore_along_right_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_R.ind != nothing
            veh_oth = scene[fore_R.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_R, overlay.line_width))
            drawtext(@sprintf("d fore right:  %10.3f", fore_R.Δs), yₒ + 2*Δy, rendermodel, textparams)
        end

        rear_L = get_neighbor_rear_along_left_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_L.ind != nothing
            veh_oth = scene[rear_L.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_L, overlay.line_width))
            drawtext(@sprintf("d rear left:   %10.3f", rear_L.Δs), yₒ + 3*Δy, rendermodel, textparams)
        end

        rear_M = get_neighbor_rear_along_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_M.ind != nothing
            veh_oth = scene[rear_M.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_M, overlay.line_width))
            drawtext(@sprintf("d rear middle: %10.3f", rear_M.Δs), yₒ + 4*Δy, rendermodel, textparams)
        end

        rear_R = get_neighbor_rear_along_right_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_R.ind != nothing
            veh_oth = scene[rear_R.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_R, overlay.line_width))
            drawtext(@sprintf("d rear right:  %10.3f", rear_R.Δs), yₒ + 5*Δy, rendermodel, textparams)
        end
    end

    rendermodel
end

mutable struct MarkerDistOverlay <: SceneOverlay
    target_id::Int
    textparams::TextParams
    rec::SceneRecord
    function MarkerDistOverlay(target_id::Int;
        textparams::TextParams=TextParams(),
        )

        new(target_id, textparams, SceneRecord(1, 0.1))
    end
end

function add_renderable!(rendermodel::RenderModel, overlay::MarkerDistOverlay, scene::Frame{Entity{S,D,I}}, roadway::Roadway) where {S,D,I}

    textparams = overlay.textparams
    yₒ = textparams.y_start
    Δy = textparams.y_jump

    update!(overlay.rec, scene)

    vehicle_index = findfirst(scene, overlay.target_id)
    if vehicle_index != nothing
        veh_ego = scene[vehicle_index]
        drawtext(@sprintf("lane offset:       %10.3f", veh_ego.state.posF.t), yₒ + 0*Δy, rendermodel, textparams)
        drawtext(@sprintf("markerdist left:   %10.3f", convert(Float64, get(MARKERDIST_LEFT, overlay.rec, roadway, vehicle_index))), yₒ + 1*Δy, rendermodel, textparams)
        drawtext(@sprintf("markerdist right:  %10.3f", convert(Float64, get(MARKERDIST_RIGHT, overlay.rec, roadway, vehicle_index))), yₒ + 2*Δy, rendermodel, textparams)
    end

    rendermodel
end


"""
    RenderableOverlay

Decorator which allows to use `SceneOverlay` objects together with the method
    render([Renderables])

This is required primarily for allowing backward compatibility with overlays
that use the old rendering interface.

usage:  `RenderableOverlay(o::Overlay, scene::Frame, roadway::Roadway)`
"""
struct RenderableOverlay{O,S,D,I} <: Renderable where {O<:SceneOverlay,S,D,I}
    overlay::O
    scene::Union{Nothing, Frame{Entity{S,D,I}}}
    roadway::Union{Nothing, Roadway}
end
RenderableOverlay(overlay::O) where {O<:SceneOverlay} = RenderableOverlay(overlay, nothing, nothing)

function add_renderable!(rm::RenderModel, ro::RenderableOverlay{O,S,D,I}) where {O<:SceneOverlay,S,D,I}
    if (ro.scene === nothing) && (ro.roadway === nothing)
        # These are the overlays that could also be used without scene and roadway,
        # they do not require the RenderableOverlay wrapper
        add_renderable!(rm, ro.overlay)
    else
        # These overlays rely on the `RenderableOverlay` wrapper to provide scene and roadway
        @assert (ro.scene !== nothing) && (ro.roadway !== nothing)
        add_renderable!(rm, ro.overlay, ro.scene, ro.roadway)
    end
end

function add_renderable!(rm::RenderModel, iterable::Union{Array{<:RenderableOverlay},Tuple{<:RenderableOverlay}})
    for ro in iterable add_renderable!(rm, ro) end
end
isrenderable(::Type{Array{<:RenderableOverlay}}) = true
isrenderable(::Type{Tuple{<:RenderableOverlay}}) = true
