function render!(
    rendermodel::RenderModel,
    veh::Vehicle1D,
    color::Colorant=RGB(rand(), rand(), rand())
    )

    s = veh.state.s

    add_instruction!(rendermodel, renderfun(veh), (s, 0.0, 0.0, veh.def.length, veh.def.width, color))
    return rendermodel
end

function render!(
    rendermodel::RenderModel,
    veh::Entity{VehicleState,D,I},
    color::Colorant=RGB(rand(), rand(), rand())
    ) where {D<:AbstractAgentDefinition, I}

    p = veh.state.posG
    l, w = length(veh.def), AutomotiveDrivingModels.width(veh.def)
    add_instruction!(rendermodel, renderfun(veh), (p.x, p.y, p.θ, l, w, color))
    return rendermodel
end

"""
    renderfun(veh::Entity{S,D,I}) where {S,D,I}
decides which rendering function to use based on the class of veh and AutoViz RENDER_MODE
"""
function renderfun(veh::Entity{S,D,I}) where {S,D,I}
    if _rendermode == :fancy && class(veh.def) == AgentClass.PEDESTRIAN
        return render_fancy_pedestrian
    elseif _rendermode == :fancy
        return render_fancy_car
    end
    return render_vehicle
end