var documenterSearchIndex = {"docs": [

{
    "location": "api/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api/#AutoViz.ArrowCar",
    "page": "API",
    "title": "AutoViz.ArrowCar",
    "category": "type",
    "text": "ArrowCar{A<:AbstractArray{Float64}, C<:Colorant} <: Renderable\nArrowCar(pos::AbstractArray, angle::Float64=0.0; length = 4.8, width = 1.8,  color=COLOR_CAR_OTHER, text=\"\", id=0)\nArrowCar(x::Real, y::Real, angle::Float64=0.0; length = 4.8, width = 1.8,  color=COLOR_CAR_OTHER, text=\"\", id=0)\n\nA renderable type to represent a rectangular car with an arrow in the middle. \n\n\n\n\n\n"
},

{
    "location": "api/#AutoViz.BlinkerOverlay",
    "page": "API",
    "title": "AutoViz.BlinkerOverlay",
    "category": "type",
    "text": "BlinkerOverlay\n\nDisplays a circle on one of the top corner of a vehicle to symbolize a blinker.  fields: \n\non: turn the blinker on\nright: blinker on the top right corner, if false, blinker on the left \nveh: the vehicle for which to display the blinker \ncolor: the color of the blinker\nsize: the size of the blinker \n\n\n\n\n\n"
},

{
    "location": "api/#AutoViz.HistogramOverlay",
    "page": "API",
    "title": "AutoViz.HistogramOverlay",
    "category": "type",
    "text": "HistogramOverlay\n\nDisplay a bar at the specified position pos, the bar is of size width, height and is filled up to a given proportion of its height.  The fill proportion is set using val, it should be a number between 0 and 1. If it is 0, the bar is not filled, if it is 1 it is filled to the top.\n\n\n\n\n\n"
},

{
    "location": "api/#AutoViz.SceneFollowCamera",
    "page": "API",
    "title": "AutoViz.SceneFollowCamera",
    "category": "type",
    "text": "SceneFollowCamera{R<:Real}\n\nCamera centered over all vehicles  The zoom can be adjusted. \n\nFields\n\nzoom::R\n\n\n\n\n\n"
},

{
    "location": "api/#AutoViz.isrenderable",
    "page": "API",
    "title": "AutoViz.isrenderable",
    "category": "function",
    "text": "Return true if an object or type is directly renderable, false otherwise.\n\nNew types should implement the isrenderable(t::Type{NewType}) method.\n\n\n\n\n\n"
},

{
    "location": "api/#AutoViz.render-Tuple{Any}",
    "page": "API",
    "title": "AutoViz.render",
    "category": "method",
    "text": "render(scene)\nrender(scene; kwargs...)\n\nRender all the items in scene to a Cairo surface and return it.\n\nscene is simply an iterable object (e.g. a vector) of items that are either directly renderable or renderable by conversion. See the AutoViz README for more details.\n\n\n\n\n\n"
},

{
    "location": "api/#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "List of functions and datastructure available in AutoVizModules = [AutoViz]"
},

{
    "location": "#",
    "page": "About",
    "title": "About",
    "category": "page",
    "text": ""
},

{
    "location": "#About-1",
    "page": "About",
    "title": "About",
    "category": "section",
    "text": "This the documentation for AutoViz.jl. For now it is just a list of functions. "
},

]}
