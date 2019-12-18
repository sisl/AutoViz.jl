"""
Model to keep track of rendering instructions and background color.

 - `instruction_set::AbstractVector{Tuple}`: set of render instructions (function, array of inputs sans ctx, incameraframe)
 - `background_color::RGB`: background color
"""
@with_kw mutable struct RenderModel
    instruction_set  :: AbstractVector{Tuple} = Array{Tuple}(undef, 0)
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

set_background_color!(rm::RenderModel, color::Colorant) = rm.background_color = convert(RGB{U8}, color)
reset_instructions!(rm::RenderModel) = empty!(rm.instruction_set)

"""
Draw all `renderables` to a `surface` using the parameters specified in `rendermodel`.
The canvas is initialized to a `CairoSurface` of dimensions `canvas_width`, `canvas_height`.
All renderables must inherit from `Renderable` and implement the `add_renderable!` function
which adds instructions for rendering to the render model.

You should call `update_camera!` before calling `render` to adapt the camera to the new scene.
The instructions of the `rendermodel` are reset automatically at the beginning of this function.
"""
function render(renderables::AbstractVector;  # TODO: specify type ::Vector{<:Renderable};
    camera::Camera=SceneFollowCamera(),
    canvas_width::Int=AutoViz.DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=AutoViz.DEFAULT_CANVAS_HEIGHT,
    surface::CairoSurface = CairoSVGSurface(IOBuffer(), canvas_width, canvas_height)
)
    rendermodel = RenderModel()
    reset_instructions!(rendermodel)
    ctx = creategc(surface)
    for renderable in renderables
        add_renderable!(rendermodel, renderable)
    end
    render_to_canvas(rendermodel, camera, ctx, canvas_width, canvas_height)
    return surface
end


function render_to_canvas(rendermodel::RenderModel, camera_state::CameraState, ctx::CairoContext, canvas_width::Integer, canvas_height::Integer)

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
    translate(ctx, canvas_width/2, canvas_height/2)  # translate to image center
    Cairo.scale(ctx, zoom(camera_state), -zoom(camera_state))    # [pix -> m]
    rotate(ctx, rotation(camera_state))
    x, y = position(camera_state)
    translate(ctx, x, y) # translate to camera location

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
function render_to_canvas(rendermodel::RenderModel, camera::Camera, ctx::CairoContext, canvas_width::Integer, canvas_height::Integer)
    render_to_canvas(rendermodel, camera.state, ctx, canvas_width, canvas_height)
end


"""
Helper function that determines camera parameters such that all rendered content fits on the canvas.
The camera rotation will always be set to 0. An additional border can be added around the content using the keyword argument `percent_border` (default 0.1)
"""
function camera_fit_to_content(
    rendermodel::RenderModel, ctx::CairoContext,
    canvas_width::Integer = DEFAULT_CANVAS_WIDTH,
    canvas_height::Integer = DEFAULT_CANVAS_HEIGHT;
    percent_border::Real = 0.1
)

    xmax, xmin, ymax, ymin = -Inf, Inf, -Inf, Inf

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

    camera_state = CameraState(
        position = VecE2(xmin + world_width/2, ymin + world_height/2), # [m]
        zoom     = (canvas_width*(1-percent_border)) / world_width, # [pix / m]
        rotation = 0.
    )
    return camera_state
end
