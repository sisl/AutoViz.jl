# Scene Overlays

Overlays provide a means of showing additional information. 


## AutoViz Overlays

```julia
# Here we show the car following stats for vehicle 1 (the red one)
render(scene, roadway, [CarFollowingStatsOverlay(1)], cam=SceneFollowCamera(zoom), canvas_height=250, car_colors=carcolors)
```
![png](output_18_0.png)




```julia
render(scene, roadway, [LineToFrontOverlay(1)], cam=SceneFollowCamera(zoom), canvas_height=250, car_colors=carcolors)
```

![png](output_19_0.png)







## Custom Overlays

### TODO: show a custom overlay (e.g. two concentric bounding boxes for a vehicle)
### TODO: show a custom overlay (e.g. lines of sight between ego and all others)


#######################################################


# Overlays

Overlays are useful to display extra information on top of a given driving scene. They can be use to display the ID of the vehicle, their speed, or any useful information. 


```julia
using AutomotiveDrivingModels
using AutoViz
```

For this tutorial, we will use a simple driving scene with two lanes on a straight roadway and three vehicles.


```julia
roadway = gen_straight_roadway(2, 50.0) # 2 lanes 50m
scene = Scene()
state1 = VehicleState(Frenet(roadway[LaneTag(1,1)],3.0), roadway, 10.0)
veh1 = Vehicle(state1, VehicleDef(), 1)
state2 = VehicleState(Frenet(roadway[LaneTag(1,1)],35.0), roadway, 10.0)
veh2 = Vehicle(state2, VehicleDef(), 2)
state3 = VehicleState(Frenet(roadway[LaneTag(1,2)],15.0), roadway, 10.0)
veh3 = Vehicle(state3, VehicleDef(), 3)
push!(scene, veh1)
push!(scene, veh2)
push!(scene, veh3)
render(scene, roadway, cam=FitToContentCamera(0.))
```


![png](output_4_0.png)


Overlays can be passed to the render function as an optional argument. This argument should be a list of overlays:
`render(scene, roadway, overlays::Vector{SceneOverlay} = SceneOverlay[])`


Below we demonstrate the default overlay implemented in this package

## TextOverlay

The `TextOverlay` display some text at the desired location. The coordinates and size units are in pixels by default. The option `incameraframe` allow to use the scene units.


```julia
text_overlay = TextOverlay(text=["Overlays are nice!", "second line"], font_size=30, pos = VecE2(50.0, 100.0))
render(scene, roadway, [text_overlay], cam=FitToContentCamera(0.))
```


![png](output_8_0.png)


## IDOverlay

The ID Overlay displays the ID of each vehicle present in the scene on top of them.


```julia
render(scene, roadway, [IDOverlay()], cam=FitToContentCamera(0.0))
```


![png](output_10_0.png)


## HistogramOverlay

Display a bar at the specified position `pos`, the bar is of size `width`, `height` and is filled up to a given proportion of its height. 
The fill proportion is set using `val`, it should be a number between 0 and 1. If it is 0, the bar is not filled, if it is 1 it is filled to the top.
The default units are in the camera frame.


```julia
max_speed = 14.0
histogram_overlay = HistogramOverlay(pos = VecE2(15.0, 10.0), val=veh1.state.v/max_speed, label="veh1 speed")
render(scene, roadway, [histogram_overlay], cam=FitToContentCamera(0.))
```


![png](output_12_0.png)


## NeighborsOverlay



```julia
neighbors_overlay = NeighborsOverlay(3)
render(scene, roadway, [neighbors_overlay], cam=FitToContentCamera(0.))
```


![png](output_14_0.png)


## CarFollowingStatsOverlay


```julia
follow_overlay = CarFollowingStatsOverlay(1, font_size=20)
render(scene, roadway, [follow_overlay], cam=FitToContentCamera(0.))
```


![png](output_16_0.png)





















## Implementing your own overlay

To implement your own overlay you should define a custom overlay type that is a subtype of the abstract type `SceneOverlay`. Then you should define the `render!` function. The `render!` function should add instruction to the `rendermodel` object. To learn more about the `rendermodel` look at the rendermodel tutorial [TODO].

As an example we show an overlay that highlights a lane.


```julia
struct LaneOverlay <: SceneOverlay
    lane::Lane
    color::Colorant
end

function AutoViz.render!(rendermodel::RenderModel, overlay::LaneOverlay, scene::Scene, roadway::Roadway)
    render!(rendermodel, overlay.lane, roadway, color_asphalt=overlay.color) # this display a lane with the specified color
    return rendermodel
end

```


```julia
lane_overlay = LaneOverlay(roadway[LaneTag(1,1)], RGBA(0.0,0.0,1.0,0.5))
render(scene, roadway, [lane_overlay], cam=FitToContentCamera(0.))
```


![png](output_19_0.png)



```julia

```
