function render!{I}(
    rendermodel::RenderModel,
    veh::Entity{PosSpeed1D, BoundingBoxDef, I},
    color::Colorant=RGB(rand(), rand(), rand())
    )

    s = veh.state.s
    add_instruction!(rendermodel, render_vehicle, (s, 0.0, 0.0, veh.def.len, veh.def.wid, color))
    return rendermodel
end