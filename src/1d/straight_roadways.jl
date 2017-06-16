function render!(rendermodel::RenderModel, roadway::Straight1DRoadway;
    color_asphalt::Colorant=COLOR_ASPHALT,
    lane_width::Float64 = DEFAULT_LANE_WIDTH,
    extra_length::Float64 = 50.0, # [m]
    lane_marking_width::Float64 = 0.15, # [m]
    )

    pts = Array(VecE2, 2)
    pts[1] = VecE2(-extra_length, 0)
    pts[2] = VecE2( extra_length + roadway.len, 0)

    add_instruction!(rendermodel, render_line, (pts, color_asphalt, lane_width))
    add_instruction!(rendermodel, render_line, ([p + VecE2(0, -lane_width/2) for p in pts], COLOR_LANE_MARKINGS_WHITE, lane_marking_width))
    add_instruction!(rendermodel, render_line, ([p + VecE2(0,  lane_width/2) for p in pts], COLOR_LANE_MARKINGS_WHITE, lane_marking_width))
    return rendermodel
end
function render(roadway::Straight1DRoadway;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = FitToContentCamera(),
    )

    s = CairoRGBSurface(canvas_width, canvas_height)
    ctx = creategc(s)
    clear_setup!(rendermodel)

    render!(rendermodel, roadway)

    camera_set!(rendermodel, cam, canvas_width, canvas_height)
    render(rendermodel, ctx, canvas_width, canvas_height)
    return s
end
Base.show(io::IO, ::MIME"image/png", roadway::Straight1DRoadway) = show(io, MIME"image/png"(), render(roadway))