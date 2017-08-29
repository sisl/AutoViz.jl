function render!{S,D,I}(
    rendermodel::RenderModel,
    scene::EntityFrame{S,D,I};
    car_color::Colorant=COLOR_CAR_OTHER, # default color
    car_colors::Dict{I,Colorant}=Dict{I,Colorant}(), #  id -> color
    )

    for veh in scene
        render!(rendermodel, veh, get(car_colors, veh.id, car_color))
    end

    rendermodel
end

function render{R}(roadway::R;
    canvas_width::Int=DEFAULT_CANVAS_WIDTH,
    canvas_height::Int=DEFAULT_CANVAS_HEIGHT,
    rendermodel = RenderModel(),
    cam::Camera = FitToContentCamera(),
    )

    image = Array(UInt32, canvas_width,canvas_height)
    s = CairoImageSurface(image, Cairo.FORMAT_ARGB32, flipxy=false)
    ctx = CairoContext(s)
    # s = CairoRGBSurface(canvas_width, canvas_height)
    # ctx = creategc(s)
    clear_setup!(rendermodel)

    render!(rendermodel, roadway)

    camera_set!(rendermodel, cam, canvas_width, canvas_height)
    render(rendermodel, ctx, canvas_width, canvas_height)
    return s
end

function render{S,D,I,R}(ctx::CairoContext, scene::EntityFrame{S,D,I}, roadway::R;
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
function render{S,D,I,R}(scene::EntityFrame{S,D,I}, roadway::R;
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

function get_pastel_car_colors{S,D,I}(scene::EntityFrame{S,D,I}; saturation::Float64=0.85, value::Float64=0.85)
    retval = Dict{I,Colorant}()
    n = length(scene)
    for (i,veh) in enumerate(scene)
        retval[veh.id] = convert(RGB, HSV(180*(i-1)/max(n-1,1), saturation, value))
    end
    return retval
end
