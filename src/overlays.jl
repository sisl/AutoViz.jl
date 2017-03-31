export
        SceneOverlay,
        TextOverlay,
        Overwash,

        NeighborsOverlay,
        CarFollowingStatsOverlay,
        MOBILOverlay,
        CollisionOverlay,
        MarkerDistOverlay,

        TextParams,
        drawtext

abstract SceneOverlay

function render{S,D,I,O<:SceneOverlay,R}(scene::EntityFrame{S,D,I}, roadway::R, overlays::AbstractVector{O};
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,Colorant}=Dict{I,Colorant}(),
    )

    s = CairoRGBSurface(canvas_width, canvas_height)
    ctx = creategc(s)
    clear_setup!(rendermodel)

    render!(rendermodel, roadway)
    render!(rendermodel, scene, car_colors=car_colors)

    for overlay in overlays
        render!(rendermodel, overlay, scene, roadway)
    end

    camera_set!(rendermodel, cam, scene, roadway, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)
    s
end

type TextParams
    size::Int
    color::Colorant
    x::Int
    y_start::Int
    y_jump::Int

    function TextParams(;
        size::Int=12,
        color::Colorant=colorant"white",
        x::Int=20,
        y_start::Int=20,
        y_jump::Int=round(Int, size*1.2),
        )

        retval = new()
        retval.size = size
        retval.color = color
        retval.x = x
        retval.y_start = y_start
        retval.y_jump = y_jump
        retval
    end
end
function drawtext(text::AbstractString, y::Int, rendermodel::RenderModel, t::TextParams; incameraframe::Bool=false)
    add_instruction!(rendermodel, render_text, (text, t.x, y, t.size, t.color), incameraframe=incameraframe)
    y + t.y_jump
end

@with_kw type TextOverlay <: SceneOverlay
    text::Vector{String}
    color::Colorant = colorant"white"
    font_size::Int = 10 # [pix]
    pos::VecE2 = VecE2(10, font_size)
    line_spacing::Float64 = 1.5 # multiple of font_size
    incameraframe=false
end
function render!{S,D,I,R}(rendermodel::RenderModel, overlay::TextOverlay, scene::EntityFrame{S,D,I}, roadway::R)
    x = overlay.pos.x
    y = overlay.pos.y
    y_jump = overlay.line_spacing*overlay.font_size
    for line in overlay.text
        add_instruction!(rendermodel, render_text, (line, x, y, overlay.font_size, overlay.color), incameraframe=overlay.incameraframe)
        y += y_jump
    end
    rendermodel
end

type Overwash <: SceneOverlay
    color::Colorant
end
function render!{S,D,I,R}(rendermodel::RenderModel, overlay::Overwash, scene::EntityFrame{S,D,I}, roadway::R)
    add_instruction!(rendermodel, render_paint, (overlay.color,))
    rendermodel
end

