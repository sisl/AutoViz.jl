#TODO: Add doc string
@with_kw struct ArrowCar{A<:AbstractArray{Float64}, C<:Color} <: Renderable
    pos::A         = SVector(0.0, 0.0)
    angle::Float64 = 0.0
    length::Float64 = 4.8
    width::Float64 = 1.8
    color::C       = COLOR_CAR_OTHER
    text::String   = "" # some debugging text to print by the car
    id::Int        = 0
end

ArrowCar(pos::AbstractArray, angle::Float64=0.0; length = 4.8, width = 1.8,  color=COLOR_CAR_OTHER, text="", id=0) = ArrowCar(pos, angle, color, length, width, "", id)

function render!(rm::RenderModel, object::ArrowCar)
    add_instruction!(rm, render_vehicle, (object.pos[1], object.pos[2], object.angle, object.length, object.width, object.color))
    #TODO: Add text instructions
    return rendermodel
end

#TODO: Convert to ArrowCar type
#function ArrowCar(pos::AbstractArray, angle::Float64=0.0, vehicletype::String)
#
#end
