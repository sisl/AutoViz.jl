#TODO: Renderable type
abstract type Renderable end

"""
Return true if an object or type is *directly renderable*, false otherwise.

New types should implement the `isrenderable(t::Type{NewType})` method.
"""
function isrenderable end

isrenderable(object) = isrenderable(typeof(object))
isrenderable(::Type{R}) where R <: Renderable = true
isrenderable(t::Type) = method_exists(render!, Tuple{RenderModel, t})
isrenderable(t::Type{Roadway}) = true

"""
    render(scene)
    render(scene; kwargs...)

Render all the items in `scene` to a Cairo surface and return it.

`scene` is simply an iterable object (e.g. a vector) of items that are either directly renderable or renderable by conversion. See the AutoViz README for more details.
"""
function render(scene; # iterable of renderable objects
                overlays=[],
                rendermodel::RenderModel=RenderModel(),
                cam::Camera=FitToContentCamera(),
                canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
                canvas_width::Int=DEFAULT_CANVAS_WIDTH,
                surface=CairoRGBSurface(canvas_width, canvas_height)
               )

    ctx = creategc(surface)
    clear_setup!(rendermodel)

    for x in scene
        if isrenderable(x)
            render!(rendermodel, x)
        else
            render!(rendermodel, convert(Renderable, x))
        end
    end

    for o in overlays
        render!(rendermodel, o, scene)
    end

    camera_set!(rendermodel, cam, scene, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)
    return surface
end

function Base.convert(::Type{Renderable}, x::AbstractVector{R}) where R <: Real
    @assert length(x) >= 2
    if length(x) == 2
        ac = ArrowCar(SVector(x[1],x[2]))
    else
        ac = ArrowCar(SVector(x[1],x[2]), x[3])
    end
    ac
end

#TODO: Tutorial notebook -> roadways, arrow cars, how to convert: Ekhlas
