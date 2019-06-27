using Test
using Pkg
using AutoViz
using NBInclude
using Colors
using Random
using AutomotiveDrivingModels

@testset "notebooks" begin
    @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "tutorial.ipynb"))
    @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "overlay_tutorial.ipynb"))
    @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "AutoViz.ipynb"))
end

@testset "Renderable" begin 
    rw = gen_straight_roadway(3, 100.0)
    car = ArrowCar(0.0, 0.0, 0.0, id=1)
    car2 = ArrowCar(1.0, 1.0, 1.0, color=colorant"green", text="text")

    render([rw, car, "some text"])

    render([rw, car, car2, "some text"], cam=CarFollowCamera(0))

    render([rw, car, car2], overlays=[TextOverlay(text=["overlay"], color=colorant"blue")])

    c = render([rw, car, car2], cam=SceneFollowCamera())
end

@testset "write SVG" begin 
    roadway = gen_stadium_roadway(4)
    c = render(roadway)
    write_to_svg(c, "out.svg")
    @test isfile("out.svg")
end

@testset "vehicle rendering" begin 
    AutoViz.set_render_mode(:basic)
    @test AutoViz._rendermode == :basic

    roadway = gen_stadium_roadway(4)
    vehstate = VehicleState(VecSE2(0.0, 0.0, 0.0), roadway, 0.0)

    def1 = VehicleDef()
    def2 = BicycleModel(def1)
    def3 = VehicleDef(AgentClass.PEDESTRIAN, 1.0, 1.0)

    veh1 = Entity(vehstate, def1, 1)
    veh2 = Entity(vehstate, def2, 2)
    veh3 = Entity(vehstate, def3, 3)

    render([roadway, veh1, veh2, veh3])

    AutoViz.set_render_mode(:fancy)
    @test AutoViz._rendermode == :fancy

    render([roadway, veh1, veh2, veh3])
end

