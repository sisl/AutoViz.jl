"""
Model to keep track of rendering parameters such as position, rotation and zoom level as well as background color.

 - `instruction_set::AbstractVector{Tuple}`: set of render instructions (function, array of inputs sans ctx, incameraframe)
 - `camera_center::VecE2`: position of camera in [N,E] relative to the mean point. meters
 - `camera_zoom::Float64`: camera zoom in [pix/m]
 - `camera_rotation::Float64`: camera rotation in [rad]
 - `background_color::RGB`: background color
"""
@with_kw mutable struct RenderModel
    instruction_set  :: AbstractVector{Tuple} = Array{Tuple}(undef, 0)
    camera_center    :: VecE2 = VecE2(0.0,0.0)
    camera_zoom      :: Float64 = 1.
    camera_rotation  :: Float64 = 0.
    background_color :: RGB = _colortheme["background"]
end

"""
Add an instruction to the rendermodel

INPUT:
    rendermodel   - the RenderModel we are adding the instruction to
    f             - the function to be called, the first argument must be a CairoContext
    arr           - tuple of input arguments to f, skipping the CairoContext
    incameraframe - we render in the camera frame by default.
                    To render in the canvas frame (common with text) set this to false

ex: add_instruction!(rendermodel, render_text, ("hello world", 10, 20, 15, [1.0,1.0,1.0]))
"""
function add_instruction!(rm::RenderModel, f::Function, arr::Tuple; incameraframe::Bool=true)
    push!(rm.instruction_set, (f, arr, incameraframe))
    rm
end

camera_move!(rm::RenderModel, dx::Real, dy::Real) = rm.camera_center = rm.camera_center + VecE2(dx, dy)
camera_move!(rm::RenderModel, Δ::VecE2) = rm.camera_center = rm.camera_center + Δ
camera_move_pix!(rm::RenderModel, dx::Real, dy::Real) = rm.camera_center = rm.camera_center + VecE2(dx/rm.camera_zoom, dy/rm.camera_zoom)
camera_move_pix!(rm::RenderModel, Δ::VecE2) = rm.camera_center = rm.camera_center + VecE2(Δ.x/rm.camera_zoom, Δ.y/rm.camera_zoom)
camera_rotate!(rm::RenderModel, θ::Real) = rm.camera_rotation += θ # [radians]
camera_zoom!(rm::RenderModel, factor::Real) = rm.camera_zoom *= factor
set_background_color!(rm::RenderModel, color::Colorant) = rm.background_color = convert(RGB{U8}, color)

function reset_camera!(rm::RenderModel)
    rm.camera_center = VecE2(0.0,0.0)
    rm.camera_zoom = 1.0
    rm.camera_rotation = 0.0
    rm
end
reset_instructions!(rm::RenderModel) = empty!(rm.instruction_set)
function reset_model!(rm::RenderModel)
    reset_instructions!(rm)
    reset_camera!(rm)
end

function set_camera!(
    rm::RenderModel;
    x::Real=rm.camera_center.x,
    y::Real=rm.camera_center.y,
    zoom::Real=rm.camera_zoom,
    rotation::Real=rm.camera_rotation
)
    rm.camera_center = VecE2(x,y)
    rm.camera_zoom = zoom
    rm.camera_rotation = rotation
    rm
end
set_camera!(rm::RenderModel, xy::AbstractVec, zoom::Real=rm.camera_zoom) = set_camera!(rm; x=xy[1], y=xy[2], zoom=zoom)


"""
Draw all `renderables` to a `surface` using the parameters specified in `rendermodel`.
The canvas is initialized to a `CairoSurface` of dimensions `canvas_width`, `canvas_height`.
All renderables must inherit from `Renderable` and implement the `add_renderable!` function
which adds instructions for rendering to the render model.

You should call `update_camera!` before calling `render` to adapt the camera to the new scene.
The instructions of the `rendermodel` are reset automatically at the beginning of this function.
"""
function render!(rendermodel::RenderModel, renderables::AbstractVector;  # TODO: specify type ::Vector{<:Renderable};
    canvas_width::Int=AutoViz.DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=AutoViz.DEFAULT_CANVAS_HEIGHT,
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
)
    reset_instructions!(rendermodel)
    ctx = creategc(surface)
    for renderable in renderables
        add_renderable!(rendermodel, renderable)
    end
    render_to_canvas(rendermodel, ctx, canvas_width, canvas_height)
    return surface
end


function render_to_canvas(rendermodel::RenderModel, ctx::CairoContext, canvas_width::Integer, canvas_height::Integer)

    # TODO: debug
    # render_fancy_car(ctx, 400., 400., 0pi, 500., 200., colorant"yellow")

    # fill with background color
    bgc = rendermodel.background_color
    r,g,b,a = red(bgc), green(bgc), blue(bgc), alpha(bgc)
    set_source_rgba(ctx, a,r,g,b)
    paint(ctx)

    # render text if no other instructions
    if isempty(rendermodel.instruction_set)
        text_color = RGB(1.0 - convert(Float64, red(rendermodel.background_color)),
                         1.0 - convert(Float64, green(rendermodel.background_color)),
                         1.0 - convert(Float64, blue(rendermodel.background_color)))
        render_text(ctx, "This screen left intentionally blank", canvas_width/2, canvas_height/2, 40, text_color, true)
        return
    end

    # reset the transform
    reset_transform(ctx)
    translate(ctx, canvas_width/2, canvas_height/2)                              # translate to image center
    Cairo.scale(ctx, rendermodel.camera_zoom, -rendermodel.camera_zoom )               # [pix -> m]
    rotate(ctx, rendermodel.camera_rotation)
    translate(ctx, -rendermodel.camera_center.x, -rendermodel.camera_center.y) # translate to camera location

    # TODO: debug
    # render_fancy_car(ctx, 0., 0., 0pi, 30., 10., colorant"yellow")

    # execute all instructions
    for tup in rendermodel.instruction_set
        func = tup[1]
        content = tup[2]
        incameraframe = tup[3]

        if !incameraframe
            save(ctx)
            reset_transform(ctx)
            func(ctx, content...)
            restore(ctx)
        else

            if func == render_text
                # deal with the inverted y-axis issue for text rendered
                mat = get_matrix(ctx)
                mat2 = [mat.xx mat.xy mat.x0;
                        mat.yx mat.yy mat.y0]
                pos = mat2*[content[2] content[3] 1.0]'
                content = tuple(content[1], pos..., content[4:end]...)

                save(ctx)
                reset_transform(ctx)
                render_text(ctx, content... )
                restore(ctx)
            else
                # just use the function normally
                func(ctx, content...)
            end
        end
    end

    ctx
end
