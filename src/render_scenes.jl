function render!{S,D,I}(
    rendermodel::RenderModel,
    scene::Frame{Entity{S,D,I}};
    car_color::Colorant=COLOR_CAR_OTHER,
    car_colors::Dict{I,Colorant}=Dict{I,Colorant}(), #  id -> color
    )

    for veh in scene
        render!(rendermodel, veh, get(car_colors, veh.id, car_color))
    end

    rendermodel
end

function render{S,D,I}(ctx::CairoContext, scene::Frame{Entity{S,D,I}}, roadway::Any;
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,Colorant}=Dict{I,Colorant}(),
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
function render{S,D,I}(scene::Frame{Entity{S,D,I}}, roadway::Any;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel::RenderModel=RenderModel(),
    cam::Camera=SceneFollowCamera(),
    car_colors::Dict{I,Colorant}=Dict{I,Colorant}(), # id
    )

    s, ctx = get_surface_and_context(canvas_width, canvas_height)
    render(ctx, scene, roadway, rendermodel=rendermodel, cam=cam, car_colors=car_colors)
    s
end

###

function get_pastel_car_colors{S,D,I}(scene::Frame{Entity{S,D,I}})
    retval = Dict{I,Colorant}()
    n = length(scene)
    for (i,veh) in enumerate(scene)
        retval[veh.id] = convert(RGB, HSV(180*(i-1)/(n-1), 0.85, 0.85))
    end
    return retval
end