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

function render(scene; # iterable of renderable objects
                overlays=[],
                rendermodel::RenderModel=RenderModel(),
                cam::Camera=FitToContentCamera(),
                canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
                canvas_width::Int=DEFAULT_CANVAS_WIDTH
               )

    s = CairoRGBSurface(canvas_width, canvas_height)
    ctx = creategc(s)
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
    return s
end

#TODO: default rendering function: Ekhlas: Take abstract vectors of (x,y,θ=0) and make ArrowCar
#TODO: Tutorial notebook -> roadways, arrow cars, how to convert: Ekhlas
#TODO: test -> run tutorial notebook, default conversions, isrenderable(), etc.: Ekhlas
#TODO: Hints for figuring out rendermodels: Zach
#TODO: make roadways directly renderable : isrenderable(::Type{Roadway}) = true, render!(): Ekhlas
