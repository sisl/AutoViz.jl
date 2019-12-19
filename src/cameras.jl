"""
Representation of camera parameters such as position, rotation and zoom level.

 - `camera_center::VecE2`: position of camera in [N,E] relative to the mean point. meters
 - `camera_zoom::Float64`: camera zoom in [pix/m]
 - `camera_rotation::Float64`: camera rotation in [rad]
"""
@with_kw mutable struct CameraState
    position  :: VecE2 = VecE2(0.0,0.0)  # TODO: this could simply be a tuple?
    zoom      :: Float64 = 1.
    rotation  :: Float64 = 0.
end
position(cs::CameraState) = cs.position
zoom(cs::CameraState) = cs.zoom
rotation(cs::CameraState) = cs.rotation

camera_move!(cs::CameraState, dx::Real, dy::Real) = cs.position = cs.position + VecE2(dx, dy)
camera_move!(cs::CameraState, Δ::VecE2) = cs.position = cs.position + Δ
camera_move_pix!(cs::CameraState, dx::Real, dy::Real) = cs.position = cs.position + VecE2(dx/cs.zoom, dy/cs.zoom)
camera_move_pix!(cs::CameraState, Δ::VecE2) = cs.position = cs.position + VecE2(Δ.x/cs.zoom, Δ.y/cs.zoom)
camera_rotate!(cs::CameraState, θ::Real) = cs.rotation += θ # [radians]
camera_zoom!(cs::CameraState, factor::Real) = cs.zoom *= factor

function set_camera!(
    cs::CameraState;
    x::Real=cs.position.x,
    y::Real=cs.position.y,
    zoom::Real=cs.zoom,
    rotation::Real=cs.rotation
)
    cs.position = VecE2(x,y)
    cs.zoom = zoom
    cs.rotation = rotation
    return cs
end
reset_camera!(cs::CameraState) = set_camera!(cs, x=0., y=0., zoom=1., rotation=0.)


"""
Camera abstract type
"""
abstract type Camera end
position(c::Camera) = position(c.state)
zoom(c::Camera) = zoom(c.state)
rotation(c::Camera) = rotation(c.state)

"""
Static  camera, does nothing
"""
struct StaticCamera <: Camera
    state::CameraState
end
StaticCamera(;kwargs...) = StaticCamera(CameraState(;kwargs...))
update_camera!(::StaticCamera, ::Frame) = nothing

"""
Camera which follows the vehicle with ID `target_id`.
By default, the target vehicle is tracked in x and y direction.
Tracking in either direction can be disabled by setting the 
`x` or `y` keys to a desired value.
"""
mutable struct TargetFollowCamera{I} <: Camera where I
    state::CameraState
    target_id::I
    x::Float64
    y::Float64
end
function TargetFollowCamera(target_id; x=NaN, y=NaN, kwargs...)
    TargetFollowCamera(CameraState(;kwargs...), target_id, x, y)
end

function update_camera!(camera::TargetFollowCamera{I}, scene::Frame{Entity{S,D,I}}) where {S,D,I}
    target = get_by_id(scene, camera.target_id)
    x, y = posg(target.state)[1:2]
    x = isnan(camera.x) ? x : camera.x
    y = isnan(camera.y) ? y : camera.y
    set_camera!(camera.state, x=x, y=y)
end

"""
Camera which gradually changes the zoom level of the scene to `zoom_target` with step size `dz`.
"""
mutable struct ZoomingCamera <: Camera
    state::CameraState
    zoom_target::Float64
    dz::Float64
end
function ZoomingCamera(;zoom_target=20., dz=.5, kwargs...)
    ZoomingCamera(CameraState(;kwargs...), zoom_target, dz)
end

function update_camera!(camera::ZoomingCamera, scene::Frame{E}) where {E<:Entity}
    zt, zc = camera.zoom_target, zoom(camera)
    if zt < zc  # zooming in 
        set_camera!(camera.cs, zoom=max(zt, zc-camera.dz))
    elseif zt > zc  # zooming out
        set_camera!(camera.cs, zoom=min(zt, zc+camera.dz))
    end
end

"""
    SceneFollowCamera{R<:Real}

Camera centered over all vehicles, does not change the zoom level.
"""
struct SceneFollowCamera <: Camera
    state::CameraState
end
SceneFollowCamera(;kwargs...) = SceneFollowCamera(CameraState(;kwargs...))
function update_camera!(camera::SceneFollowCamera, scene::Frame{E}) where {E<:Entity}
    C = sum([posg(veh.state)[1:2] for veh in scene])/length(scene)  # center of mass
    set_camera!(camera.cs, x=C[1], y=C[2])
    # should also add capabilities for adapting zoom level to make all vehicles of the scene fit
    # along the lines of FitToContentCamera, but much simpler (just using entity coordinates to determine bounding box but INCLUDING zoom)
end


"""
Composition of several cameras. The `update_camera` actions of the individual cameras are applied in the order in which they are saved in the `cameras` array.
States of individual cameras are ignored, the state of the composed camera is the one that will be used for rendering.

Example Usage

    cam = ComposedCamera(cameras=[SceneFollowCamera(), ZoomingCamera()])
"""
mutable struct ComposedCamera <: Camera
    state::CameraState
    cameras::Array{Camera}
end
ComposedCamera(cameras; kwargs...) = ComposedCamera(CameraState(;kwargs...), cameras)

function update_camera!(camera::ComposedCamera, scene::Frame{E}) where {E<:Entity}
    for cam in camera.cameras
        update_camera!(camera.cs, cam, scene)
    end
end
