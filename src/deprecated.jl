# TODO: add fallback implementations and more informative deprecation warnings

"""
    render(scene)
    render(scene; kwargs...)

Render all the items in `scene` to a Cairo surface and return it.

# `scene` is simply an iterable object (e.g. a vector) of items that are either directly renderable or renderable by conversion. See the AutoViz README for more details.
# """
function render(scene; # iterable of renderable objects
                overlays=[],
                rendermodel::RenderModel=RenderModel(),
                cam::Camera=FitToContentCamera(),
                canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
                canvas_width::Int=DEFAULT_CANVAS_WIDTH,
                surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
               )
    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")
    ctx = creategc(surface)
    clear_setup!(rendermodel)
    for x in scene
        render!(rendermodel, isrenderable(x) ? x : convert(Renderable, x))
    end
    for o in overlays
        render!(rendermodel, o, scene)
    end
    camera_set!(rendermodel, cam, scene, canvas_width, canvas_height)
    render(rendermodel, ctx, canvas_width, canvas_height)
    return surface
end

function render(scene::EntityFrame{S,D,I}, roadway::R, overlays::AbstractVector{O};
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,C}=Dict{I,Colorant}(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
    ) where {S,D,I,O<:SceneOverlay,R,C<:Colorant}

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    ctx = creategc(surface)
    clear_setup!(rendermodel)

    render!(rendermodel, roadway)
    render!(rendermodel, scene, car_colors=car_colors)

    for overlay in overlays
        render!(rendermodel, overlay, scene, roadway)
    end

    camera_set!(rendermodel, cam, scene, roadway, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)
    return surface
end

function render!(
    rendermodel::RenderModel,
    scene::EntityFrame{S,D,I};
    car_color::Colorant=_colortheme["COLOR_CAR_OTHER"], # default color
    car_colors::Dict{I,C}=Dict{I,Colorant}(), #  id -> color
    ) where {S,D,I,C<:Colorant}

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    for veh in scene
        render!(rendermodel, veh, get(car_colors, veh.id, car_color))
    end

    rendermodel
end

function render(roadway::R;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = FitToContentCamera(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
    ) where {R<:Roadway}

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    ctx = creategc(surface)
    clear_setup!(rendermodel)
    render!(rendermodel, roadway)
    camera_set!(rendermodel, cam, canvas_width, canvas_height)
    render(rendermodel, ctx, canvas_width, canvas_height)
    return surface
end

function render(ctx::CairoContext, scene::EntityFrame{S,D,I}, roadway::R;
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,C}=Dict{I,Colorant}(),
    ) where {S,D,I,R,C<:Colorant}

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    canvas_width = floor(Int, Cairo.width(ctx))
    canvas_height = floor(Int, Cairo.height(ctx))

    clear_setup!(rendermodel)

    render!(rendermodel, roadway)
    render!(rendermodel, scene, car_colors=car_colors)

    camera_set!(rendermodel, cam, scene, roadway, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)
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

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    ctx = creategc(surface)
    render(ctx, scene, roadway, rendermodel=rendermodel, cam=cam, car_colors=car_colors)

    return surface
end

function render(roadway::StraightRoadway;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = FitToContentCamera(),
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
    )

    Base.depwarn("You are sing an old rendering interface. Please use render(rendermodel::RenderModel, renderables) instead. This implementation will most probably crash.")

    ctx = creategc(surface)
    clear_setup!(rendermodel)
    add_renderable!(rendermodel, roadway)
    camera_set!(rendermodel, cam, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)

    return surface
end

Base.show(io::IO, ::MIME"image/png", roadway::StraightRoadway) = show(io, MIME"image/png"(), render(roadway))
