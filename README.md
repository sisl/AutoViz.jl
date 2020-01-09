# AutoViz

[![Build Status](https://travis-ci.org/sisl/AutoViz.jl.svg?branch=master)](https://travis-ci.org/sisl/AutoViz.jl)
[![Coverage Status](https://coveralls.io/repos/sisl/AutoViz.jl/badge.svg)](https://coveralls.io/r/sisl/AutoViz.jl)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://sisl.github.io/AutoViz.jl/latest)

A package for rendering simple scenes primarily consisting of cars on roadways using Cairo.

AutoViz is undergoing significant changes. If you are looking for the version before these changes that is designed around AutomotiveDrivingModels.jl, please checkout the v0.6.0 tag.

![AutoViz](readmeimage.png)

## Installation 

In julia 1.1+, the preferred way is to add the SISL registry and install AutoViz as follows:

```julia 
] registry add https://github.com/sisl/Registry
] add AutoViz
```

You can also manually add all the dependencies:
```julia
using Pkg
Pkg.add(PackageSpec(url="https://github.com/sisl/Vec.jl"))
Pkg.add(PackageSpec(url="https://github.com/sisl/Records.jl"))
Pkg.add(PackageSpec(url="https://github.com/sisl/AutomotiveDrivingModels.jl"))
Pkg.add(PackageSpec(url="https://github.com/sisl/AutoViz.jl"))
```

## Usage

AutoViz works by adding rendering instructions to a `RenderModel`,
and finally applying those instructions to a canvas using the
`render` function.

### Basic Usage

In the simplest case, a `roadway` and a `scene` of types `Roadway` and `Scene`
respectively can be rendered via

```julia
render([roadway, scene])
```

However, the rendering interface is much more flexible than that,
supporting custom rendering and cameras.

### Renderable Objects

In order for an object of type `ObjectType` to be "renderable",
we need to provide a function with the signature
``` julia
    add_renderable!(rendermodel::RenderModel, obj::ObjectType)
```
The basic example above works, because AutoViz implements the
`add_renderable!` function for commonly used types such as
`Roadway`, `Vehicle` or `Scene`.
In general, the `render(renderables)` function can take any collection
of renderable objects.
AutoViz provides a series of convenient wrapper objects such as
`FancyCar`, `FancyPedestrian`, `EntityRectangle` to make entities
renderable.

### Cameras

A `Camera` object specifies what portion of the scene should be rendered.

By default, `render(renderables)` uses a static camera.
In order to use an adaptive camera, the `camera` object
needs to be updated before rendering and passed in to the
`render` function as a keyword argument.

```julia
update_camera!(scene, camera)
render([roadway, scene], camera=camera)
```

### Full Example

```julia
# define roadway and vewhicle objects
roadway = gen_straight_roadway(3, 100.0)
lane = roadway[LaneTag(1,2)]
def = VehicleDef(length=5., width=2.)
ego = Entity(VehicleState(Frenet(lane, 50.,  0., 0.), roadway, 5rand()), def, :ego)
carA = Entity(VehicleState(Frenet(lane, 20.,  2., -.2), roadway, 5rand()), def, :carA)
carB = Entity(VehicleState(Frenet(lane, 40.,  -2., -.1), roadway, 5rand()), def, :carB)
carC = Entity(VehicleState(Frenet(lane, 60.,  0., .4), roadway, 5rand()), def, :carC)
carD = Entity(VehicleState(Frenet(lane, 80.,  3., .1), roadway, 5rand()), def, :carD)
scene = Frame([ego, carA, carB, carC, carD])

# define camera and adjust to scene
camera = TargetFollowCamera(:ego; y=0., zoom=12.)
update_camera!(camera, scene)

# render
renderables = [
    roadway,
    FancyCar(car=ego, color=colorant"blue"),
    FancyCar(car=carA, color=rand(RGB)),
    FancyCar(car=carB, color=rand(RGB)),
    EntityRectangle(entity=carC, color=rand(RGB)),
    EntityRectangle(entity=carD, color=rand(RGB)),
    TextOverlay(text=["AutoViz rocks!"], font_size=60, pos=VecE2(400, 100), color=colorant"green")
]
for veh in scene
    push!(renderables, VelocityArrow(entity=veh))
end
img = render(renderables, camera=camera)
```

In a jupyter notebook, an image will appear, otherwise see the [Saving images](#saving-images) section below. A short tutorial is located in [notebooks/tutorial.ipynb](notebooks/tutorial.ipynb).


### Roadways and ArrowCars

The primary basic directly renderable types are `Roadway` (now from `AutomotiveDrivingModels`; soon from `Roadways.jl`) and `ArrowCar`.

`ArrowCar`s are the pink cars with arrows that are in everyone's videos. You can construct one like this:

```julia
using Colors
using AutoViz

# x, y, angle and velocity are from your simulation

ArrowCar(x, y, angle; color=colorant"green", text="v: $velocity")
```

### How to make types renderable

There are two ways to make renderable types.

1. You can make your existing types renderable by conversion by defining `convert(::Type{Renderable}, ::MyType)` which should return a directly renderable object, e.g. an `ArrowCar`.
2. You can make types directly renderable by defining `render!(::RenderModel, ::MyType)`. To make things easier for the compiler, you can also define `isrenderable(::Type{MyType}) = true`. If you want to allow others to convert to this type to make their types renderable by conversion, make your type a subtype of `Renderable`.

## Overlays

Overlays will function as in the previous version of AutoViz. They will be rendered last with `render!(rendermodel, overlay, scene)`.

## Additional keyword arguments for `render()`

The following additional keyword arguments will accepted by `render()`:

- `canvas_width`
- `canvas_height`
- `rendermodel`
- `overlays`
- `cam` - a camera controlling the field of view as in the previous version of AutoViz

## Saving images

Png images can be saved with `write_to_png(render(scene), "filename.png")` or `write_to_svg(render(scene), "filename.svg")`.
 Gif animations may be created with e.g. [Reel.jl](https://github.com/shashi/Reel.jl).

## `RenderModel`s

The mid-level interface for this package (which is what you will use when you write `render!()` for your types or when you write an overlay) revolves around adding instructions to a `RenderModel`. Each instruction consists of a function and a tuple of arguments for the function. This is not documented in this readme, but it is fairly easy to figure out by reading `rendermodels.jl`, `overlays.jl`, and `arrowcar.jl`.

## Customization

AutoViz.jl has two display mode: a "fancy" mode (default) that uses the svg representations in `icons/` to display cars and pedestrian, and a more basic mode where cars are rendered as rounded rectangles. To turn-off the fancy mode you can run:
```julia
AutoViz.set_render_mode(:basic) # set to :fancy for fancy mode
```

In addition you can also change the color theme. Three color themes are provided: `MONOKAY` (default), `OFFICETHEME`, `LIGHTTHEME`. You can change the color theme by running:
```julia
using AutoViz
set_color_theme(LIGHTTHEME)
```
You can also define your own color theme using a dictionary. Look at the example in `src/colorscheme.jl` to have the correct key names.


## Change Log

### v0.8.x

#### Rendering
 - Clean-up of the rendering interface: there is now only one single rendering function with the signature
```
render!(rendermodel::RenderModel, renderables::AbstractVector; canvas_width::Int, canvas_height::Int, surface::CairoSurface))
```
All keyword arguments are optional. Objects of type `Renderable` now no longer have to implement the `render!` function (which is a misleading name). Instead one must implement the `add_renderable!` function which adds the rendering instructions to the `RenderModel`.
 - Implicit conversions of non-renderable objects (such as `obj::Frame{Entity{S,D,I}}`) via implementations of `Base.convert(Renderable, obj)` are now discouraged. Instead, one can overwrite the `add_renderable!` method for such types. This is done for some very common types.
 - The new `render!` function now only takes objects which are renderable, i.e. which implement the `add_renderable(rm::RenderModel, obj)` function. There is no longer a distinction between drawing roadways, scenes or overlays. They all need to satisfy the same interface, and they are drawn in the order in which they are passed to the `render!` function. This change decreases the number of available render functions from almost ten to one and should make the control flow more clear.
 - Additional arguments to `render!` such as `camera` and `car_colors` are no longer supported. Camera effects should be applied before calling `render!` (see section below) and rendering attributes such as colors should be passed in as part of a renderable object.

#### Overlays
 - Changed the interface for rendering overlays to only take an instance of `RenderModel` and the overlay itself. All additional data must be stored as part of the overlay if it is needed during rendering.
 - Added a `RenderableOverlay` wrapper which makes the legacy overlays work with the new rendering interface (in which overlays do not get any input arguments for rendering)

#### Cameras
 - Changed the camera interface. The full state of the camera, such as `camera_pos`, `camera_zoom`, `camera_rotation` is stored in `RenderModel` (this has already been the case in previous AutoViz versions). A `Camera` acts upon a `RenderModel` by changing these internal variables. The function `camera_set!` now becomes `update_camera!`.
 - Many setter functions for the camera have been replaced by the `set_camera!()` function which takes keyword arguments for `x`, `y` and `zoom`.
 - The implementations of `TargetFollowCamera` (former `CarFollowCamera`) and `SceneFollowCamera` have been reviewed and simplified. Additionally, a `ZoomingCamera` type which gradually changes the zoom level has been introduced and for easy extensibility there is also a `ComposedCamera` type which takes a list of cameras and applies their effects sequentially to the `RenderModel`.
 - The new `render!` function no longer takes a camera as an input argument, but assumes that the camera settings have already been applied to the `RenderModel` via `update_camera!` prior to calling `render!`. User code should be adapted accordingly.
 - The `FitToContentCamera` is no longer available. To replace it, the method `camera_fit_to_content` is provided which computes camera parameters for which the entire content of the scene fits on the canvas. For most purposes, the `SceneFollowCamera` should be a good alternative.
 
#### Visualization of Entities
 - Controlling the appearance of vehicles by setting `set_render_mode(:basic|:fancy)` is no longer encouraged. Instead, we provide new renderable types such as `EntityRectangle`, `FancyCar`, `FancyPedestrian`, `VelocityArrow` in addition to the already implemented `ArrowCar` type which can all be used to conveniently display entities.
 - A convenience function for rendering scenes directly (i.e. without explicit conversion to a `Renderable` type) is still supported.
 - TODO: make FancyCar work on my platform

#### 1D Vehicles
 - Support for 1D vehicles has mostly been discontinued and some of the related functions were removed. However, the new functions should work seamlessly in many cases as long as the 1D vehicles implement basic functions such as `posg`, `width`, `length` from `AutomotiveDrivingModels.jl`
