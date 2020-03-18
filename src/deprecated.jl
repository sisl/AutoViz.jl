render_depwarn_msg = "This version of the render function is deprecated since v0.8. Please use render!(renderables) instead."

function render(scene::EntityFrame{S,D,I}, roadway::R, overlays::AbstractVector{O};
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,C}=Dict{I,Colorant}(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
) where {S,D,I,O,R,C<:Colorant}
    Base.depwarn(render_depwarn_msg, :render)
    renderables = [roadway]
    for (i, veh) in enumerate(scene)
        c = car_colors[i]
        if rendermode == :fancy
            r = (
                class(veh.def) == AgentClass.PEDESTRIAN
                ? FancyPedestrian(ped=veh, color=c)
                : FancyCar(car=veh, color=c)
            )
        else
            x, y, theta = posg(veh)
            r = ArrowCar(x, y, theta, length=length(veh.def), width=width(veh.def), color=c, id=veh.id)
        end
        push!(renderables, r)
    end
    for o in overlays
        push!(renderables, RenderableOverlay(o, scene, roadway))
    end
    update_camera!(cam, scene)
    render(renderables, camera=cam, surface=surface)
    return surface
end

function render!(
    rendermodel::RenderModel,
    scene::EntityFrame{S,D,I};
    car_color::Colorant=colortheme["COLOR_CAR_OTHER"], # default color
    car_colors::Dict{I,C}=Dict{I,Colorant}(), #  id -> color
) where {S,D,I,C<:Colorant}
    Base.depwarn(render_depwarn_msg, :render)
    renderables = []
    for (i, veh) in enumerate(scene)
        c = car_colors[i]
        if rendermode == :fancy
            r = (
                class(veh.def) == AgentClass.PEDESTRIAN
                ? FancyPedestrian(ped=veh, color=c)
                : FancyCar(car=veh, color=c)
            )
        else
            x, y, theta = posg(veh)
            r = ArrowCar(x, y, theta, length=length(veh.def), width=width(veh.def), color=c, id=veh.id)
        end
        push!(renderables, r)
    end
    render(renderables, camera=cam, surface=surface)
    return rendermodel
end

function render(roadway::R;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = SceneFollowCamera(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
) where {R<:Roadway}
    Base.depwarn(render_depwarn_msg, :render)
    renderables = [roadway]
    render(renderables, camera=cam, surface=surface)
    return surface
end

function render(ctx::CairoContext, scene::EntityFrame{S,D,I}, roadway::R;
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,C}=Dict{I,Colorant}(),
) where {S,D,I,R,C<:Colorant}
    Base.depwarn(render_depwarn_msg, :render)
    renderables = [roadway]
    for (i, veh) in enumerate(scene)
        c = car_colors[i]
        if rendermode == :fancy
            r = (
                class(veh.def) == AgentClass.PEDESTRIAN
                ? FancyPedestrian(ped=veh, color=c)
                : FancyCar(car=veh, color=c)
            )
        else
            x, y, theta = posg(veh)
            r = ArrowCar(x, y, theta, length=length(veh.def), width=width(veh.def), color=c, id=veh.id)
        end
        push!(renderables, r)
    end
    reset_instructions!(rendermodel)
    update_camera!(cam, scene)
    for renderable in renderables
        add_renderable!(rendermodel, renderable)
    end
    render_to_canvas(rendermodel, cam, ctx)
    ctx
end
function render(scene::EntityFrame{S,D,I}, roadway::R;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,C}=Dict{I,Colorant}(), # id
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
) where {S,D,I,R, C<:Colorant}
    Base.depwarn(render_depwarn_msg, :render)
    ctx = creategc(surface)
    render(ctx, scene, roadway, rendermodel=rendermodel, cam=cam, car_colors=car_colors)
    return surface
end

function render(roadway::StraightRoadway;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = SceneFollowCamera(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
)
    Base.depwarn(render_depwarn_msg, :render)
    renderables = [roadway]
    update_camera!(cam, scene)
    render(renderables, camera=cam, surface=surface)
    return surface
end

Base.show(io::IO, ::MIME"image/png", roadway::StraightRoadway) = show(io, MIME"image/png"(), render(roadway))
