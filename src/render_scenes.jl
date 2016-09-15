function render!(
    rendermodel::RenderModel,
    scene::Scene;
    car_color::Colorant=COLOR_CAR_OTHER,
    car_colors::Dict{Int,Colorant}=Dict{Int,Colorant}(), #  id -> color
    )

    for veh in scene
        render!(rendermodel, veh, get(car_colors, veh.def.id, car_color))
    end

    rendermodel
end

function render(ctx::CairoContext, scene::Scene, roadway::Roadway;
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{Int,Colorant}=Dict{Int,Colorant}(),
    )

    canvas_width = floor(Int, Cairo.width(ctx))
    canvas_height = floor(Int, Cairo.height(ctx))

    clear_setup!(rendermodel)

    render!(rendermodel, roadway)
    render!(rendermodel, scene, car_colors=car_colors)

    camera_set!(rendermodel, cam, scene, roadway, canvas_width, canvas_height)

    render(rendermodel, ctx, canvas_width, canvas_height)
    ctx
end
function render(scene::Scene, roadway::Roadway;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{Int,Colorant}=Dict{Int,Colorant}(), # id
    )

    s, ctx = get_surface_and_context(canvas_width, canvas_height)
    render(ctx, scene, roadway, rendermodel=rendermodel, cam=cam, car_colors=car_colors)
    s
end