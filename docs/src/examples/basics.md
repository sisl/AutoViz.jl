# AutoViz Basics

The core function of the `AutoViz.jl` package is `AutoViz.render()`

```@docs
render
```

In its simplest form, the `render` function only takes one argument:
an iterable collection of renderable objects, `renderables`.
In order for an object to be renderable, it needs to implement the
`add_renderable!()` function.

By default, the `render()` function will do its best to make all the contents of
the scene fit to the canvas of dimensions `canvas_width` x `canvas_height`.
More fine-grained control over camera positioning can be achieved by providing
the `camera` keyword.
In case a custom camera is used, it is important to call
`update_camera!(camera, scene)` before rendering.

The Cairo surface to be used for plotting can be specified using the `surface` keyword.
The `render()` function applies the rendering instructions to the `surface` and
returns it. In the tutorials, we will denote the returned `surface` as a
`snapshot` of the scene. Such snapshots can be saved to file using the command

```julia
write("snapshot.svg", snapshot)
```


## Basic rendering

We start our example by rendering an empty roadway

```@example intro
using AutomotiveDrivingModels
using AutoViz

roadway = gen_straight_roadway(3, 100.0)

snapshot = render([roadway], canvas_height=120)
write("empty_roadway.svg", snapshot) # hide
```
![empty roadway](empty_roadway.svg)

We can change the background color and render again

```@example intro
AutoViz.colortheme["background"] = colorant"white"
snapshot = render([roadway], canvas_height=120)
write("empty_roadway_whitebg.svg", snapshot) # hide
```
![empty roadway](empty_roadway_whitebg.svg)


Let's add some vehicles

```@example intro
car_len = 4.8
car_width = 1.8
def = VehicleDef(AgentClass.CAR, car_len, car_width)
w = DEFAULT_LANE_WIDTH
scene = Scene(4)  # allocate a scene for 4 agents

# add three cars
push!.(Ref(scene), [
    Vehicle(VehicleState(VecSE2(10.0,   w, 0.0), roadway, 4.0 + 2.0randn()), def, 1),
    Vehicle(VehicleState(VecSE2(40.0, 0.0, 0.0), roadway, 4.0 + 2.0randn()), def, 2),
    Vehicle(VehicleState(VecSE2(70.0,   w, 0.0), roadway, 4.0 + 2.0randn()), def, 3),
])

# add a pedestrian
push!(scene, Vehicle(
    VehicleState(VecSE2(80.0, 0., π/2), roadway, 2.0),
    VehicleDef(AgentClass.PEDESTRIAN, 1., 1.),
    42
))
snapshot = render([roadway, scene], canvas_height=120)
write("roadway_with_cars.svg", snapshot) # hide
```
![roadway with cars](roadway_with_cars.svg)


## TODO: Colorthemes


## Vehicle Shapes

The `render` function provides some defaults for rendering basic building blocks
such as entities or roadways.
If the value of `AutoViz.rendermode` is set to `:basic`, entities are simply
rendered as rectangles with arrows indicating their velocities.
This can also be done explicitly via

```@example intro
renderables = [
    roadway,
    (EntityRectangle(entity=x) for x in scene)...,
    (VelocityArrow(entity=x) for x in scene)...,
]
snapshot = render(renderables, canvas_height=120)
write("roadway_basic_manual.svg", snapshot) # hide
```
![roadway basic manual](roadway_basic_manual.svg)

The result remains the same. The velocity arrows point to the location at which
the vehicle would be 1 second in the future.

Setting `AutoViz.rendermode` to `:fancy`, the rectangles are replaced by SVG
images of cars (or pedestrians). 

```@example intro
# AutoViz.rendermode = :fancy # cannot assign variables in other modules
@eval(AutoViz, rendermode = :fancy)
snapshot = render([roadway, scene], canvas_height=120)
write("roadway_fancy.svg", snapshot) # hide
```
![roadway fancy](roadway_fancy.svg)

Which is shorthand for

```@example intro
renderables = [
    roadway, (FancyCar(car=scene[i]) for i in 1:3)..., FancyPedestrian(ped=scene[4])
]
snapshot = render(renderables, canvas_height=120)
write("roadway_fancy_manual.svg", snapshot) # hide
```
![roadway fancy manual](roadway_fancy_manual.svg)

A third visualization mode is available in the form of arrow cars, in which the
arrow indicates the heading direction of the car but does not scale with speed.

```@example intro
renderables = [
    roadway, (ArrowCar(car=scene[i]) for i in 1:3)..., FancyPedestrian(ped=scene[4])
]
snapshot = render(renderables, canvas_height=120)
write("roadway_arrow.svg", snapshot) # hide
```
![roadway arrow](roadway_arrow.svg)


## Vehicle Colors

By default, the `render` function generates a random color for each entity based
on its ID using the `id_to_color()` function.
However, vehicle colors can also be assigned explicitly:

```@example intro
colors = [colorant"red", colorant"blue", colorant"green"]
renderables = [
    roadway,
    (FancyCar(car=scene[i], color=colors[i]) for i in 1:3)...,
    FancyPedestrian(ped=scene[4], color=colorant"yellow")
]
snapshot = render(renderables, canvas_height=120)
write("scene_custom_colors.svg", snapshot) # hide
```
![cars with custom colors](scene_custom_colors.svg)



## Simulation and Animations

We can simulate the scenario over time and visualize the results using `Reel`
(based on `ffmpeg`).

```@example intro
using Reel

timestep = 0.1
nticks = 50

models = Dict((i => Tim2DDriver(timestep) for i in 1:3))  # car models
# TODO: use a different model for pedestrian
models[42] = Tim2DDriver(timestep)  # pedestrian model

scenes = simulate(scene, roadway, models, nticks, timestep)

animation = roll(fps=1.0/timestep, duration=nticks*timestep) do t, dt
    i = Int(floor(t/dt)) + 1
    render([roadway, scenes[i]])
end

write("roadway_animated.gif", animation)
```
![animated roadway](roadway_animated.gif)

Alternatively, the scene can also be visualized interactively using `Interact`

```julia
using Interact
using Reel
using Blink

w = Window()
viz = @manipulate for step in 1 : length(scenes)
    render([roadway, scenes[step]])
end
body!(w, viz)
```

You can use Reactive to have them endlessly drive in real time in your browser.

### TODO: is this a thing? If yes, provide snippet
