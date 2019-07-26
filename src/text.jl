isrenderable(::Type{String}) = true

function render!(rm::RenderModel, t::String)
    font_size = 12
    x = 10
    y = 1.5*font_size
    y_jump = 1.5 * font_size
    for line in split(t, '\n')
        add_instruction!(rm, render_text, (line, x, y, font_size, colorant"gray75"), incameraframe=false)
        y += y_jump
    end
    return rm
end
