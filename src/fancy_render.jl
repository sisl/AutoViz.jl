const CARFILE = joinpath(@__DIR__, "..", "icons", "racing_car_top_view.svg")
const PEDFILE = joinpath(@__DIR__, "..", "icons", "walking_person.svg")

function render_fancy_car(
    ctx           :: CairoContext,
    x             :: Real, # x-pos of the center of the vehicle
    y             :: Real, # y-pos of the center of the vehicle
    yaw           :: Real, # heading angle [rad]
    length        :: Real, # vehicle length
    width         :: Real, # vehicle width
    color_fill    :: Colorant
    )

    # # renders a car from the top view sport car svg
    # # (x,y) are in meters and yaw is the radians, counter-clockwise from pos x axis

    save(ctx)
    open(CARFILE, "r") do car_svg
        car_svg = replace(car_svg, "#CAAC00"=>"#"*hex(color_fill))
        r = Rsvg.handle_new_from_data(car_svg)
    end
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
    open(PEDFILE, "r") do ped_svg
        ped_svg = replace(ped_svg, "#C90000"=>"#"*hex(color_fill))
        r = Rsvg.handle_new_from_data(ped_svg)
    end
    d = Rsvg.handle_get_dimensions(r)

    # scaling factor
    xdir, ydir = length/d.width, width/d.height

    translate(ctx, x, y)
    scale(ctx, xdir, ydir)
    rotate(ctx, yaw + pi/2)
    translate(ctx, -d.width/2, -d.height/2)

    Rsvg.handle_render_cairo(ctx, r)

    restore(ctx)
end
