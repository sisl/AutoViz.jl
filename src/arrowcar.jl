"""
A basic drawable rectangle representing a car.
An arrow indicates the heading direction of the car.

    ArrowCar{A<:AbstractArray{Float64}, C<:Colorant} <: Renderable
    ArrowCar(pos::AbstractArray, angle::Float64=0.0; length = 4.8, width = 1.8,  color=_colortheme["COLOR_CAR_OTHER"], text="", id=0)
    ArrowCar(x::Real, y::Real, angle::Float64=0.0; length = 4.8, width = 1.8,  color=_colortheme["COLOR_CAR_OTHER"], text="", id=0)
"""
@with_kw struct ArrowCar{A<:AbstractArray{Float64}, C<:Colorant} <: Renderable
    pos::A         = SVector(0.0, 0.0)
    angle::Float64 = 0.0
    length::Float64 = 4.8
    width::Float64 = 1.8
    color::C       = _colortheme["COLOR_CAR_OTHER"]
    text::String   = "" # some debugging text to print by the car
    id::Int        = 0
end
ArrowCar(pos::AbstractArray, angle::Float64=0.0; length = 4.8, width = 1.8,  color=_colortheme["COLOR_CAR_OTHER"], text="", id=0) = ArrowCar(pos, angle, length, width, color, text, id)
ArrowCar(x::Real, y::Real, angle::Float64=0.0; length = 4.8, width = 1.8,  color=_colortheme["COLOR_CAR_OTHER"], text="", id=0) = ArrowCar(SVector(x, y), angle, length, width, color, text, id)

function render!(rm::RenderModel, c::ArrowCar)
    x = c.pos[1]
    y = c.pos[2]
    add_instruction!(rm, render_vehicle, (x, y, c.angle, c.length, c.width, c.color))
    add_instruction!(rm, render_text, (c.text, x, y-c.width/2 - 2.0, 10, colorant"white"))
    return rm
end


"""
A drawable 'fancy' svg image of a race car.
The car is placed at the position of `entity` and the width and length are scaled accordingly.
The color of the car can be specified using the `color` keyword.
"""
@with_kw struct FancyCar{C<:Colorant, I} <: Renderable
    car::Entity{VehicleState, VehicleDef, I}
    color::C = AutoViz._colortheme["COLOR_CAR_OTHER"]
end

function AutoViz.render!(rm::RenderModel, fc::FancyCar)
    x, y, yaw = posg(fc.car.state)
    l, w = length(fc.car.def), fc.car.def.width
    add_instruction!(rm, render_fancy_car, (x, y, yaw, l, w, fc.color))
    return rm
end


"""
A drawable rectangle with rounded corners representing an `entity`.
"""
@with_kw struct EntityRectangle{S,D,I, C<:Colorant} <: Renderable
    entity::Entity{S,D,I}
    color::C = AutoViz._colortheme["COLOR_CAR_OTHER"]
end

function render_entity_rectangle(ctx::CairoContext, er::EntityRectangle)
    x, y, yaw = posg(er.entity.state)
    w, h = length(er.entity.def), er.entity.def.width
    cr = 0.5 # [m]
    save(ctx); translate(ctx, x, y); rotate(ctx, yaw);
    render_round_rect(ctx, 0, 0, w, h, 1., cr, er.color, true, true, .8*er.color, .3)
    restore(ctx)
end
render!(rm::RenderModel, er::EntityRectangle) = add_instruction!(rm, render_entity_rectangle, (er,))


"""
A drawable arrow representing the current velocity vector of an `entity`.
The arrow points to the location where the vehicle will be one second in the future (assuming linear motion).
"""
@with_kw struct VelocityArrow{S,D,I, C<:Colorant} <: Renderable
    entity::Entity{S,D,I}
    color::C = colorant"white"
end

function render_velocity_arrow(ctx::CairoContext, va::VelocityArrow)
    x, y, yaw = posg(va.entity.state)
    vx, vy = velg(va.entity.state)
    save(ctx); translate(ctx, x, y); rotate(ctx, yaw);
    render_arrow(ctx, [[0.  vx];[0. vy]], va.color, .3, .8, ARROW_WIDTH_RATIO=1., ARROW_ALPHA=.12pi, ARROW_BETA=.6pi)
    restore(ctx)
end
render!(rm::RenderModel, va::VelocityArrow) = add_instruction!(rm, render_velocity_arrow, (va,))
