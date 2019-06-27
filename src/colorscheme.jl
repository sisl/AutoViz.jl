const COLOR_ASPHALT       = colorant"0x708090FF"
const COLOR_LANE_MARKINGS_WHITE = colorant"0xDFDFDFFF"
const COLOR_LANE_MARKINGS_YELLOW = colorant"0xFFEF00FF"
const COLOR_CAR_EGO       = colorant"0x00FFFFFF" # bluish
const COLOR_CAR_OTHER     = colorant"0xFF007FFF" # reddish
const COLOR_ROAD_BOUNDARIES = colorant"black"

const MONOKAY = Dict(
            "COLOR_ASPHALT"              => colorant"0x708090FF",
            "COLOR_LANE_MARKINGS_WHITE"  => colorant"0xDFDFDFFF",
            "COLOR_LANE_MARKINGS_YELLOW" => colorant"0xFFEF00FF",
            "COLOR_CAR_EGO"              => colorant"0x00FFFFFF",
            "COLOR_CAR_OTHER"            => colorant"0xFF007FFF", 
            "COLOR_ROAD_BOUNDARIES"      => colorant"white",
            "foreground" => colorant"0xCFBFADFF",
            "background" => colorant"0x272822FF",
            "color1"     => colorant"0x52E3F6FF", # light blue
            "color2"     => colorant"0xA7EC21FF", # light green
            "color3"     => colorant"0xFF007FFF", # red
            "color4"     => colorant"0xF9971FFF", # orange
            "color5"     => colorant"0x79ABFFFF", # cobalt
    )

const OFFICETHEME = Dict(
            "COLOR_ASPHALT"              => colorant"0x708090FF",
            "COLOR_LANE_MARKINGS_WHITE"  => colorant"0xDFDFDFFF",
            "COLOR_LANE_MARKINGS_YELLOW" => colorant"0xFFEF00FF",
            "COLOR_CAR_EGO"              => colorant"#0090bc",
            "COLOR_CAR_OTHER"            => colorant"#ce0300" ,
            "COLOR_ROAD_BOUNDARIES"      => colorant"white",
            "foreground" => colorant"0xCFBFADFF",
            "background" => colorant"transparent",
            "color1"     => colorant"#0090bc", # light blue
            "color2"     => colorant"#00a321", # light green
            "color3"     => colorant"#ce0300", # red
    )


const LIGHTTHEME = Dict(
            "COLOR_ASPHALT"              => colorant"transparent",
            "COLOR_LANE_MARKINGS_WHITE"  => colorant"black",
            "COLOR_LANE_MARKINGS_YELLOW" => colorant"0xFFEF00FF",
            "COLOR_CAR_EGO"              => colorant"#0090bc",
            "COLOR_CAR_OTHER"            => colorant"#ce0300" ,
            "COLOR_ROAD_BOUNDARIES"      => colorant"white",
            "foreground" => colorant"0xCFBFADFF",
            "background" => colorant"transparent",
            "color1"     => colorant"#0090bc", # light blue
            "color2"     => colorant"#00a321", # light green
            "color3"     => colorant"#ce0300", # red
    )


global _colortheme = MONOKAY

""" 
    set_color_theme(colortheme)
Change the color theme of the package
"""
function set_color_theme(colortheme)
    global _colortheme
    _colortheme = colortheme
end

function Vec.lerp(a::Colorant, b::Colorant, t::Real)

    ra = red(a)
    rb = red(b)
    ga = green(a)
    gb = green(b)
    ba = blue(a)
    bb = blue(b)
    aa = alpha(a)
    ab = alpha(b)

    r = ra + (rb - ra)*t
    g = ga + (gb - ga)*t
    b = ba + (bb - ba)*t
    a = aa + (ab - aa)*t

    RGBA(r,g,b,a)
end
