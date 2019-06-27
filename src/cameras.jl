abstract type Camera end
camera_set!(::RenderModel, cam::Camera, ::EntityFrame{S,D,I}, ::R, canvas_width::Int, canvas_height::Int) where {S,D,I,R} = error("camera_set! not implemented for Camera $cam")

mutable struct StaticCamera <: Camera
    pos::VecE2
    zoom::Float64 # [pix/meter]
    StaticCamera(pos::VecE2, zoom::Float64=3.0) = new(pos, zoom)
    StaticCamera(x::Float64, y::Float64, zoom::Float64=3.0) = new(VecE2(x,y), zoom)
end
function camera_set!(rendermodel::RenderModel, cam::StaticCamera, canvas_width::Int, canvas_height::Int)

    camera_set_pos!(rendermodel, cam.pos)
    camera_setzoom!(rendermodel, cam.zoom)

    rendermodel
end
camera_set!(rendermodel::RenderModel, cam::StaticCamera, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S,D,I,R} = camera_set!(rendermodel, cam, canvas_width, canvas_height)

# method for new interface
camera_set!(rm::RenderModel, cam::StaticCamera, scene, canvas_width::Int, canvas_height::Int) = camera_set!(rm, cam, canvas_width, canvas_height)

mutable struct FitToContentCamera <: Camera
    percent_border::Float64
    FitToContentCamera(percent_border::Float64=0.1) = new(percent_border)
end
function camera_set!(rendermodel::RenderModel, cam::FitToContentCamera, canvas_width::Int, canvas_height::Int)
    camera_fit_to_content!(rendermodel, canvas_width, canvas_height, percent_border=cam.percent_border)
    rendermodel
end
camera_set!(rendermodel::RenderModel, cam::FitToContentCamera, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S,D,I,R} = camera_set!(rendermodel, cam, canvas_width, canvas_height)

# method for new interface
camera_set!(rendermodel::RenderModel, cam::FitToContentCamera, scene, canvas_width::Int, canvas_height::Int) = camera_set!(rendermodel, cam, canvas_width, canvas_height)

mutable struct CarFollowCamera{I} <: Camera
    targetid::I
    zoom::Float64 # [pix/meter]
end
CarFollowCamera(targetid::I) where {I} = CarFollowCamera{I}(targetid, 3.0)

function camera_set!(rendermodel::RenderModel, cam::CarFollowCamera{I}, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S<:State1D,D,I,R}

    veh_index = findfirst(cam.targetid, scene)
    if veh_index != nothing
        camera_set_pos!(rendermodel, VecE2(scene[veh_index].state.s, 0.0))
        camera_setzoom!(rendermodel, cam.zoom)
    else
        add_instruction!( rendermodel, render_text, ("CarFollowCamera did not find id $(cam.targetid)", 10, 15, 15, colorant"white"), incameraframe=false)
        camera_fit_to_content!(rendermodel, canvas_width, canvas_height)
    end

    rendermodel
end
function camera_set!(rendermodel::RenderModel, cam::CarFollowCamera{I}, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S<:VehicleState,D,I,R}

    veh_index = findfirst(cam.targetid, scene)
    if veh_index != nothing
        camera_set_pos!(rendermodel, scene[veh_index].state.posG)
        camera_setzoom!(rendermodel, cam.zoom)
    else
        add_instruction!( rendermodel, render_text, ("CarFollowCamera did not find id $(cam.targetid)", 10, 15, 15, colorant"white"), incameraframe=false)
        camera_fit_to_content!(rendermodel, canvas_width, canvas_height)
    end

    rendermodel
end

# method for new interface
function camera_set!(rendermodel::RenderModel, cam::CarFollowCamera, scene, canvas_width::Int, canvas_height::Int)

    inds = findall(x -> x isa ArrowCar && id(x) == cam.targetid, scene)
    if isempty(inds)
        ids = [c.id for c in scene if c isa ArrowCar]
        add_instruction!( rendermodel, render_text, ("CarFollowCamera did not find an ArrowCar with id $(cam.targetid) (found ids: $ids)", 10, 15, 15, colorant"white"), incameraframe=false)
        camera_fit_to_content!(rendermodel, canvas_width, canvas_height)
    else
        veh_index = first(inds)
        camera_set_pos!(rendermodel, pos(scene[veh_index])...)
        camera_setzoom!(rendermodel, cam.zoom)
    end

    rendermodel
end

"""
    SceneFollowCamera{R<:Real}

Camera centered over all vehicles 
The zoom can be adjusted. 
# Fields 
- `zoom::R`

"""
@with_kw struct SceneFollowCamera{R<:Real} <: Camera
    zoom::R = 3.0 # [pix/meter]
end

function camera_set!(rendermodel::RenderModel, cam::SceneFollowCamera, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S<:State1D,D,I,R}


    if length(scene) > 0

        # get camera center
        C = 0.0
        for veh in scene
            C += veh.state.s
        end
        C = C / length(scene)

        camera_set_pos!(rendermodel, VecE2(C, 0.0))
        camera_setzoom!(rendermodel, cam.zoom)
    else
        add_instruction!( rendermodel, render_text, ("SceneFollowCamera did not find any vehicles", 10, 15, 15, colorant"white"), incameraframe=false)
        camera_fit_to_content!(rendermodel, canvas_width, canvas_height)
    end

    rendermodel
end
function camera_set!(rendermodel::RenderModel, cam::SceneFollowCamera, scene::EntityFrame{S,D,I}, roadway::R, canvas_width::Int, canvas_height::Int) where {S<:VehicleState,D,I,R}


    if length(scene) > 0

        # get camera center
        C = VecE2(0.0,0.0)
        for veh in scene
            C += convert(VecE2, veh.state.posG)
        end
        C = C / length(scene)

        camera_set_pos!(rendermodel, C)
        camera_setzoom!(rendermodel, cam.zoom)
    else
        add_instruction!( rendermodel, render_text, ("SceneFollowCamera did not find any vehicles", 10, 15, 15, colorant"white"), incameraframe=false)
        camera_fit_to_content!(rendermodel, canvas_width, canvas_height)
    end

    rendermodel
end