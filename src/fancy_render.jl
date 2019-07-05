
const CARFILE = joinpath(@__DIR__, "..", "icons", "racing_car_top_view.svg")
const PEDFILE = joinpath(@__DIR__, "..", "icons", "walking_person.svg")
const CARDATA = parse_file(CARFILE)
const PEDDATA = parse_file(PEDFILE)


function set_car_color!(color::Colorant, doc::XMLDocument)
    xroot = root(doc)
    body = xroot["g"][1]["g"][1]["path"][2]
    color_code ="#"*hex(color)
    set_attribute(body, "style", "fill:$color_code;fill-opacity:0.99607843;stroke:none")
end

function set_ped_color!(color::Colorant, doc::XMLDocument)
    xroot = root(doc)
    body = xroot["g"][1]["path"][6]
    color_code = "#"*hex(color)
    set_attribute(body, "fill", color_code)
end


function render_fancy_car(
    ctx           :: CairoContext,
    x             :: Real, # x-pos of the center of the vehicle
    y             :: Real, # y-pos of the center of the vehicle
    yaw           :: Real, # heading angle [rad]
    length        :: Real, # vehicle length
    width         :: Real, # vehicle width
    color_fill    :: Colorant
    )

    # renders a car from the top view sport car svg
    # (x,y) are in meters and yaw is the radians, counter-clockwise from pos x axis

    save(ctx)
    cardata = parse_file(CARFILE)
    set_car_color!(color_fill, cardata)

    r = Rsvg.handle_new_from_data(string(cardata))

    
    d = Rsvg.handle_get_dimensions(r)
    # scaling factor
    xdir, ydir = length/d.width, width/d.height

    translate(ctx, x, y)
    scale(ctx, xdir, ydir)
    rotate(ctx, yaw)
    translate(ctx, -d.width/2, -d.height/2)

    Rsvg.handle_render_cairo(ctx, r)

    restore(ctx)
end

function render_fancy_pedestrian(
    ctx           :: CairoContext,
    x             :: Real, # x-pos of the center of the vehicle
    y             :: Real, # y-pos of the center of the vehicle
    yaw           :: Real, # heading angle [rad]
    length        :: Real, # vehicle length
    width         :: Real, # vehicle width
    color_fill    :: Colorant
    )
    # renders a car from the top view sport car svg
    # (x,y) are in meters and yaw is the radians, counter-clockwise from pos x axis

    save(ctx)

    peddata = parse_file(PEDFILE)
    set_ped_color!(color_fill, peddata)

    r = Rsvg.handle_new_from_data(string(peddata))

    d = Rsvg.handle_get_dimensions(r)

    # scaling factor
    xdir, ydir = length/d.width, width/d.height

    translate(ctx, x, y)
    scale(ctx, xdir, ydir)
    rotate(ctx, yaw - pi/2)
    translate(ctx, -d.width/2, -d.height/2)

    Rsvg.handle_render_cairo(ctx, r)

    restore(ctx)
end
