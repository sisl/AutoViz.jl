function render!{I}(
    rendermodel::RenderModel,
    veh::Entity{RoadwayState, BoundingBoxDef, I},
    color::Colorant=RGB(rand(), rand(), rand())
    )

    p = veh.state.posG
    add_instruction!(rendermodel, render_vehicle, (p.x, p.y, p.θ, veh.def.len, veh.def.wid, color))
    return rendermodel
end