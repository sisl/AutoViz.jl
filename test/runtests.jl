using Test
using Pkg
using AutoViz
using NBInclude
using Colors
using Random
using AutomotiveDrivingModels

@testset "notebooks" begin
    @warn "Notebook testset temporarily disabled - enable"
    # @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "tutorial.ipynb"))
    # @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "overlay_tutorial.ipynb"))
    # @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "AutoViz.ipynb"))
end

@testset "Renderable" begin 
    rw = gen_straight_roadway(3, 100.0)
    car = ArrowCar(0.0, 0.0, 0.0, id=1)
    car2 = ArrowCar(1.0, 1.0, 1.0, color=colorant"green", text="text")

    @test_deprecated render([rw, car, "some text"])

    @test_deprecated render([rw, car, car2, "some text"], cam=TargetFollowCamera(target_id=0))

    @test_deprecated render([rw, car, car2], overlays=[TextOverlay(text=["overlay"], color=colorant"blue")])

    c = @test_deprecated render([rw, car, car2], cam=SceneFollowCamera())
end

@testset "write SVG" begin 
    roadway = gen_stadium_roadway(4)
    c = @test_deprecated render(roadway)
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

    @test_deprecated render([roadway, veh1, veh2, veh3])

    AutoViz.set_render_mode(:fancy)
    @test AutoViz._rendermode == :fancy

    @test_deprecated render([roadway, veh1, veh2, veh3])
    # render(Frame([veh1, veh2, veh3]), camera_zoom=15., camera_center=VecE2(1.,1.), camera_motion=TargetFollowCamera(target_id=1))  # TODO: multiple dispatch not working on update_camera!
    render(Frame([veh1, veh2, veh3]), camera_zoom=15., camera_center=VecE2(1.,1.), camera_motion=StaticCamera())
end

@testset "color theme" begin
    AutoViz.set_color_theme(OFFICETHEME)
    @test AutoViz._colortheme == OFFICETHEME

    roadway = gen_stadium_roadway(4)
    vehstate = VehicleState(VecSE2(0.0, 0.0, 0.0), roadway, 0.0)

    def1 = VehicleDef()
    def2 = BicycleModel(def1)
    def3 = VehicleDef(AgentClass.PEDESTRIAN, 1.0, 1.0)

    veh1 = Entity(vehstate, def1, 1)
    veh2 = Entity(vehstate, def2, 2)
    veh3 = Entity(vehstate, def3, 3)

    @test_deprecated render([roadway, veh1, veh2, veh3])

    AutoViz.set_color_theme(LIGHTTHEME)
    @test AutoViz._colortheme == LIGHTTHEME

    @test_deprecated render([roadway, veh1, veh2, veh3])

    AutoViz.set_color_theme(MONOKAY)
    @test AutoViz._colortheme == MONOKAY
end
