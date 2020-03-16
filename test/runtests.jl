using Test
using Pkg
using AutoViz
using Colors
using Random
using AutomotiveDrivingModels

@testset "notebooks" begin
    @nbinclude(joinpath(dirname(pathof(AutoViz)),"..", "notebooks", "autoviz_tutorial.ipynb"))
end

@testset "Renderable" begin 
    rw = gen_straight_roadway(3, 100.0)
    car = ArrowCar(0.0, 0.0, 0.0, id=1)
    car2 = ArrowCar(1.0, 1.0, 1.0, color=colorant"green", text="text")

    render([rw, car, "some text"])
    render([rw, car, car2, "some text"], camera=TargetFollowCamera(0, zoom=10.))
    render([rw, car, car2, TextOverlay(text=["overlay"], color=colorant"blue")])
    c = render([rw, car, car2], camera=SceneFollowCamera(zoom=10.))
end

@testset "write SVG, PDF, PNG" begin 
    roadway = gen_stadium_roadway(4)
    c = @test_deprecated render(roadway)
    write("out.svg", c)
    @test isfile("out.svg")

    # write pdf 
    camera = StaticCamera(position=(50,30), zoom=6.)
    c = render([roadway], camera=camera, 
           surface=AutoViz.CairoPDFSurface(IOBuffer(), AutoViz.canvas_width(camera), AutoViz.canvas_height(camera)))
    write("out.pdf", c)

    # write png 
    c = render([roadway], camera=camera, 
           surface=AutoViz.CairoRGBSurface(AutoViz.canvas_width(camera), AutoViz.canvas_height(camera)))
    write("out.png", c)

    # try to write svg surface to pdf 
    c = render([roadway], camera=camera)
    @test_throws ErrorException write("out.pdf", c)
    
    # try to write pdf surface to svg 
    c = render([roadway], camera=camera, 
           surface=AutoViz.CairoPDFSurface(IOBuffer(), AutoViz.canvas_width(camera), AutoViz.canvas_height(camera)))
    @test_throws ErrorException write("out.svg", c)

    # png should always work 
    c = render([roadway], camera=camera)
    write("out2.png", c)
end

@testset "vehicle rendering" begin 
    AutoViz.set_render_mode(:basic)
    @test AutoViz.rendermode == :basic

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
    @test AutoViz.rendermode == :fancy

    render([roadway, veh1, veh2, veh3])
    scene = Frame([veh1])
    cam = TargetFollowCamera(1)
    update_camera!(cam, scene)
    render([Frame([veh1, veh2, veh3])], camera = cam)  # TODO: multiple dispatch not working on update_camera!
    render([Frame([veh1, veh2, veh3])], camera=StaticCamera(zoom=10.))
end

@testset "color theme" begin
    AutoViz.set_color_theme(OFFICETHEME)
    @test AutoViz.colortheme == OFFICETHEME

    roadway = gen_stadium_roadway(4)
    vehstate = VehicleState(VecSE2(0.0, 0.0, 0.0), roadway, 0.0)

    def1 = VehicleDef()
    def2 = BicycleModel(def1)
    def3 = VehicleDef(AgentClass.PEDESTRIAN, 1.0, 1.0)

    veh1 = Entity(vehstate, def1, 1)
    veh2 = Entity(vehstate, def2, 2)
    veh3 = Entity(vehstate, def3, 3)

    render([roadway, veh1, veh2, veh3])

    AutoViz.set_color_theme(LIGHTTHEME)
    @test AutoViz.colortheme == LIGHTTHEME

    render([roadway, veh1, veh2, veh3])

    AutoViz.set_color_theme(MONOKAY)
    @test AutoViz.colortheme == MONOKAY

    s = Frame([veh1])
    d = get_pastel_car_colors(s)
    @test length(d) == length(s)
end

@testset "doc examples" begin
    @testset "basics" begin
        include("docs/src/examples/basics.jl")
    end
    # @testset "cameras" begin
    #     include("docs/src/examples/cameras.jl")
    # end
    # @testset "overlays" begin
    #     include("docs/src/examples/overlays.jl")
    # end
end
