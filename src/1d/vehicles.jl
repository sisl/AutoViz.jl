function render!(
    rendermodel::RenderModel,
    veh::Vehicle1D,
    color::Colorant=RGB(rand(), rand(), rand())
    )

    s = veh.state.s
    add_instruction!(rendermodel, render_vehicle, (s, 0.0, 0.0, veh.def.length, veh.def.width, color))
    return rendermodel
end