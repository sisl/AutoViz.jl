"""
Camera abstract type
"""
abstract type Camera end

"""
Camera which follows the vehicle with ID `target_id`.
By default, the target vehicle is tracked in x and y direction.
Tracking in either direction can be disabled by setting the 
`x` or `y` keys to a desired value.
"""
@with_kw mutable struct TargetFollowCamera{I} <: Camera where I
    target_id::I
    x::Float64 = NaN
    y::Float64 = NaN
end

function update_camera!(rendermodel::RenderModel, camera::TargetFollowCamera{I}, scene::Frame{Entity{S,D,I}}) where {S,D,I}
    target = get_by_id(scene, camera.target_id)
    pos_target = VecE2(posg(target.state)[1:2]...)
    x = isnan(camera.x) ? pos_target.x : camera.x
    y = isnan(camera.y) ? pos_target.y : camera.y
    set_camera!(rendermodel, x=x, y=y)
end

"""
    SceneFollowCamera{R<:Real}

Camera centered over all vehicles, does not change the zoom level.
"""
struct SceneFollowCamera <: Camera end

function update_camera!(rendermodel::RenderModel, camera::SceneFollowCamera, scene::Frame{E}) where {E<:Entity}
    C = sum([posg(veh.state)[1:2] for veh in scene])/length(scene)  # center of mass
    set_camera!(rendermodel, x=C[1], y=C[2])
end

@with_kw mutable struct FitToContentCamera <: Camera
    canvas_width::Int64 = DEFAULT_CANVAS_WIDTH
    canvas_height::Int64 = DEFAULT_CANVAS_HEIGHT
    percent_border::Float64 = 0.1
end
function update_camera!(rendermodel::RenderModel, cam::FitToContentCamera, scene::Frame{E}) where {E<:Entity}
    camera_fit_to_content!(rendermodel, cam.canvas_width, cam.canvas_height, percent_border=cam.percent_border)
    rendermodel
end

"""
Positions the camera so that all content is visible within its field of view
This will always set the camera rotation to zero
An extra border can be added as well
"""
function camera_fit_to_content!(
    rendermodel    :: RenderModel,
    canvas_width   :: Integer,
    canvas_height  :: Integer;
    percent_border :: Real = 0.1 # amount of extra border we add
    )

    rendermodel.camera_rotation = 0.0

    if isempty(rendermodel.instruction_set)
        return
    end

    # determine render bounds
    xmax = -Inf; xmin = Inf
    ymax = -Inf; ymin = Inf

    for tup in rendermodel.instruction_set
        f = tup[1]
        in_camera_frame = tup[3]
        if !in_camera_frame
            continue
        end

        (x,y,flag) = (0,0,false)
        if f == render_circle || f == render_round_rect
            (x,y,flag) = (tup[2][1],tup[2][2],true)
        elseif f == render_text
            (x,y,flag) = (tup[2][2],tup[2][3],true)
        elseif f == render_point_trail || f == render_line ||
               f == render_dashed_line || f == render_fill_region

            pts = tup[2][1]
            if isa(pts, AbstractArray{Float64})
                for i in 1 : size(pts, 2)
                    xmax = max(xmax, pts[1,i])
                    xmin = min(xmin, pts[1,i])
                    ymax = max(ymax, pts[2,i])
                    ymin = min(ymin, pts[2,i])
                end
            elseif isa(pts, AbstractVector{VecE2{T}} where T<:Real)
                for P in pts
                    xmax = max(xmax, P.x)
                    xmin = min(xmin, P.x)
                    ymax = max(ymax, P.y)
                    ymin = min(ymin, P.y)
                end
            end

        # vehicles - center + sqrt((width/2)^2 + (height/2)^2)
        elseif f == render_vehicle
            x = tup[2][1]
            y = tup[2][2]
            width = tup[2][5]
            height = tup[2][4]
            bounding_radius = sqrt((width/2)^2 + (height/2)^2)
            xmax = max(xmax, x + bounding_radius)
            xmin = min(xmin, x - bounding_radius)
            ymax = max(ymax, y + bounding_radius)
            ymin = min(ymin, y - bounding_radius)
        end

        if flag
            xmax = max(xmax, x)
            xmin = min(xmin, x)
            ymax = max(ymax, y)
            ymin = min(ymin, y)
        end
    end

    if isinf(xmin) || isinf(ymin)
        return
    end

    if xmax < xmin
        xmax = xmin + 1.0
    end
    if ymax < ymin
        ymax = ymin + 1.0
    end

    # compute zoom to fit
    world_width = xmax - xmin
    world_height = ymax - ymin
    canvas_aspect = canvas_width / canvas_height
    world_aspect = world_width / world_height

    if world_aspect > canvas_aspect
        # expand height to fit
        half_diff =  (world_width * canvas_aspect - world_height) / 2
        world_height = world_width * canvas_aspect # [m]
        ymax += half_diff
        ymin -= half_diff
    else
        # expand width to fit
        half_diff = (canvas_aspect * world_height - world_width) / 2
        world_width = canvas_aspect * world_height
        xmax += half_diff
        xmin -= half_diff
    end

    rendermodel.camera_center = VecE2(xmin + world_width/2, ymin + world_height/2) # [m]
    rendermodel.camera_zoom   = (canvas_width*(1-percent_border)) / world_width # [pix / m]

    rendermodel
end

