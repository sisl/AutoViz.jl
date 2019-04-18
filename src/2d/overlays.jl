export
    LineToCenterlineOverlay,
    LineToFrontOverlay,
    CarFollowingStatsOverlay,
    NeighborsOverlay,
    MOBILOverlay,
    MarkerDistOverlay,
    BlinkerOverlay

mutable struct LineToCenterlineOverlay <: SceneOverlay
    target_id::Int # if -1 does it for all
    line_width::Float64
    color::Colorant

    function LineToCenterlineOverlay(target_id::Int=-1;
        line_width::Float64=0.5, #[m]
        color::Colorant=colorant"blue",
        )

        new(target_id, line_width, color)
    end
end
function render!(rendermodel::RenderModel, overlay::LineToCenterlineOverlay, scene::Scene, roadway::Any)

    if overlay.target_id < 0
        target_inds = 1:length(scene)
    else
        target_inds = overlay.target_id:overlay.target_id
    end

    for ind in target_inds
        veh = scene[ind]
        footpoint = get_footpoint(veh)
        add_instruction!(rendermodel, render_line_segment,
            (veh.state.posG.x, veh.state.posG.y, footpoint.x, footpoint.y, overlay.color, overlay.line_width))
    end

    rendermodel
end


mutable struct LineToFrontOverlay <: SceneOverlay
    target_id::Int # if -1 does it for all
    line_width::Float64
    color::Colorant

    function LineToFrontOverlay(target_id::Int=-1;
        line_width::Float64=0.5, #[m]
        color::Colorant=colorant"blue",
        )

        new(target_id, line_width, color)
    end
end
function render!(rendermodel::RenderModel, overlay::LineToFrontOverlay, scene::Scene, roadway::Roadway)

    if overlay.target_id < 0
        target_inds = 1:length(scene)
    else
        target_inds = overlay.target_id:overlay.target_id
    end

    for ind in target_inds
        veh = scene[ind]
        veh_ind_front = get_neighbor_fore_along_lane(scene, ind, roadway).ind
        if veh_ind_front != nothing
            v2 = scene[veh_ind_front]
            add_instruction!(rendermodel, render_line_segment,
                (veh.state.posG.x, veh.state.posG.y, v2.state.posG.x, v2.state.posG.y, overlay.color, overlay.line_width))
        end
    end

    rendermodel
end

"""
    BlinkerOverlay
Displays a circle on one of the top corner of a vehicle to symbolize a blinker. 
fields: 
- on: turn the blinker on
- right: blinker on the top right corner, if false, blinker on the left 
- veh: the vehicle for which to display the blinker 
- color: the color of the blinker
- size: the size of the blinker 
""" 
@with_kw struct BlinkerOverlay <: SceneOverlay
    on::Bool = false 
    right::Bool = true
    veh::Vehicle = Vehicle(VehicleState(), VehicleDef(), 0)
    color::Colorant = colorant"0xFFEF00FF" # yellow 
    size::Float64 = 0.3
end

function AutoViz.render!(rendermodel::RenderModel, overlay::BlinkerOverlay, scene::Scene, roadway::R) where R
    if !overlay.on
        return nothing 
    end
    if overlay.right 
        pos = get_front(overlay.veh) + polar(overlay.veh.def.width/2, overlay.veh.state.posG.θ - pi/2)
    else
        pos = get_front(overlay.veh) + polar(overlay.veh.def.width/2, overlay.veh.state.posG.θ + pi/2)
    end
    add_instruction!(rendermodel, render_circle, (pos.x, pos.y, overlay.size, overlay.color))    
end

mutable struct CarFollowingStatsOverlay <: SceneOverlay
    target_id::Int
    verbosity::Int
    color::Colorant
    font_size::Int

    function CarFollowingStatsOverlay(target_id::Int, verbosity::Int=1;
        color::Colorant=colorant"white",
        font_size::Int=10,
        )

        new(target_id, verbosity, color,font_size)
    end
end
function render!(rendermodel::RenderModel, overlay::CarFollowingStatsOverlay, scene::Scene, roadway::Roadway)

    font_size = overlay.font_size
    text_y = font_size
    text_y_jump = round(Int, font_size*1.2)
    fmt_txt = @sprintf("id %d", overlay.target_id)
    add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
        text_y += text_y_jump

    veh_index = findfirst(overlay.target_id, scene)
    if veh_index != nothing
        veh = scene[veh_index]

        if overlay.verbosity ≥ 2
            add_instruction!( rendermodel, render_text, ("posG: " * string(veh.state.posG), 10, text_y, font_size, overlay.color), incameraframe=false)
            text_y += text_y_jump
            add_instruction!( rendermodel, render_text, ("posF: " * string(veh.state.posF), 10, text_y, font_size, overlay.color), incameraframe=false)
            text_y += text_y_jump
        end
        fmt_txt = @sprintf("speed: %0.3f", veh.state.v)
        add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
        text_y += text_y_jump


        foreinfo = get_neighbor_fore_along_lane(scene, veh_index, roadway; max_distance_fore=Inf)
        if foreinfo.ind != nothing
            v2 = scene[foreinfo.ind]
            rel_speed = v2.state.v - veh.state.v
            fmt_txt = @sprintf("Δv = %10.3f m/s", rel_speed)
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
            text_y += text_y_jump
            fmt_txt = @sprintf("Δs = %10.3f m/s", foreinfo.Δs)
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
            text_y += text_y_jump

            if overlay.verbosity ≥ 2
                add_instruction!( rendermodel, render_text, ("posG: " * string(v2.state.posG), 10, text_y, font_size, overlay.color), incameraframe=false)
                text_y += text_y_jump
                add_instruction!( rendermodel, render_text, ("posF: " * string(v2.state.posF), 10, text_y, font_size, overlay.color), incameraframe=false)
                text_y += text_y_jump
                fmt_txt = @sprintf("speed: %.3f", v2.state.v)
                add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
                text_y += text_y_jump
            end
        else
            fmt_txt = @sprintf("no front vehicle")
            add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
        end
    else
        fmt_txt = @sprintf("vehicle %d not found", overlay.target_id)
        add_instruction!( rendermodel, render_text, (fmt_txt, 10, text_y, font_size, overlay.color), incameraframe=false)
    end

    rendermodel
end

mutable struct NeighborsOverlay <: SceneOverlay
    target_id::Int
    color_L::Colorant
    color_M::Colorant
    color_R::Colorant
    line_width::Float64
    textparams::TextParams
    function NeighborsOverlay(target_id::Int;
        color_L::Colorant=colorant"blue",
        color_M::Colorant=colorant"green",
        color_R::Colorant=colorant"red",
        line_width::Float64=0.5, # [m]
        textparams::TextParams=TextParams(),
        )

        new(target_id, color_L, color_M, color_R, line_width, textparams)
    end
end
function render!(rendermodel::RenderModel, overlay::NeighborsOverlay, scene::Scene, roadway::Roadway)

    textparams = overlay.textparams
    yₒ = textparams.y_start
    Δy = textparams.y_jump

    vehicle_index = findfirst(overlay.target_id, scene)
    if vehicle_index != nothing

        veh_ego = scene[vehicle_index]
        t = veh_ego.state.posF.t
        ϕ = veh_ego.state.posF.ϕ
        v = veh_ego.state.v
        len_ego = veh_ego.def.length

        fore_L = get_neighbor_fore_along_left_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_L.ind != nothing
            veh_oth = scene[fore_L.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_L, overlay.line_width))
            drawtext(@sprintf("d fore left:   %10.3f", fore_L.Δs), yₒ + 0*Δy, rendermodel, textparams)
        end

        fore_M = get_neighbor_fore_along_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_M.ind != nothing
            veh_oth = scene[fore_M.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_M, overlay.line_width))
            drawtext(@sprintf("d fore middle: %10.3f", fore_M.Δs), yₒ + 1*Δy, rendermodel, textparams)
        end

        fore_R = get_neighbor_fore_along_right_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
        if fore_R.ind != nothing
            veh_oth = scene[fore_R.ind]
            A = get_front(veh_ego)
            B = get_rear(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_R, overlay.line_width))
            drawtext(@sprintf("d fore right:  %10.3f", fore_R.Δs), yₒ + 2*Δy, rendermodel, textparams)
        end

        rear_L = get_neighbor_rear_along_left_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_L.ind != nothing
            veh_oth = scene[rear_L.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_L, overlay.line_width))
            drawtext(@sprintf("d rear left:   %10.3f", rear_L.Δs), yₒ + 3*Δy, rendermodel, textparams)
        end

        rear_M = get_neighbor_rear_along_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_M.ind != nothing
            veh_oth = scene[rear_M.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_M, overlay.line_width))
            drawtext(@sprintf("d rear middle: %10.3f", rear_M.Δs), yₒ + 4*Δy, rendermodel, textparams)
        end

        rear_R = get_neighbor_rear_along_right_lane(scene, vehicle_index, roadway, VehicleTargetPointRear(), VehicleTargetPointFront(), VehicleTargetPointRear())
        if rear_R.ind != nothing
            veh_oth = scene[rear_R.ind]
            A = get_rear(veh_ego)
            B = get_front(veh_oth)
            add_instruction!(rendermodel, render_line_segment, (A.x, A.y, B.x, B.y, overlay.color_R, overlay.line_width))
            drawtext(@sprintf("d rear right:  %10.3f", rear_R.Δs), yₒ + 5*Δy, rendermodel, textparams)
        end
    end

    rendermodel
end

# type MOBILOverlay <: SceneOverlay
#     egoid::Int
#     mobil::MOBIL
#     rec::SceneRecord
#     textparams::TextParams

#     function MOBILOverlay(
#         egoid::Int,
#         mobil::MOBIL;
#         rec::SceneRecord=SceneRecord(1, 0.1),
#         textparams::TextParams = TextParams(x=275, y_start=120),
#         )

#         retval = new()
#         retval.egoid = egoid
#         retval.mobil = mobil
#         retval.rec = rec
#         retval.textparams = textparams
#         retval
#     end
# end
# function render!(rendermodel::RenderModel, overlay::MOBILOverlay, scene::Scene, roadway::Roadway)

#     rec = overlay.rec
#     update!(rec, scene)

#     mobil = overlay.mobil
#     textparams = overlay.textparams
#     yₒ = textparams.y_start

#     vehicle_index = findfirst(rec, overlay.egoid)
#     veh_ego = scene[vehicle_index]
#     v = veh_ego.state.v
#     egostate_M = veh_ego.state

#     drawtext(@sprintf("speed: %10.3f", v), yₒ, rendermodel, textparams)

#     left_lane_exists = convert(Float64, get(N_LANE_LEFT, rec, roadway, vehicle_index)) > 0
#     right_lane_exists = convert(Float64, get(N_LANE_RIGHT, rec, roadway, vehicle_index)) > 0
#     fore_M = get_neighbor_fore_along_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointRear(), VehicleTargetPointFront())
#     rear_M = get_neighbor_rear_along_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointFront(), VehicleTargetPointRear())

#     drawtext(@sprintf("left lane exists: %s", string(left_lane_exists)), yₒ +   textparams.y_jump, rendermodel, textparams)
#     drawtext(@sprintf("right lane exists: %s", string(right_lane_exists)), yₒ + 2*textparams.y_jump, rendermodel, textparams)

#     # accel if we do not make a lane change
#     accel_M_orig = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, overlay.egoid))
#     dir = DIR_MIDDLE

#     drawtext(@sprintf("accel M orig: %10.3f", accel_M_orig), yₒ + 3*textparams.y_jump, rendermodel, textparams)

#     advantage_threshold = mobil.advantage_threshold
#     if right_lane_exists

#         rear_R = get_neighbor_rear_along_right_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointFront(), VehicleTargetPointRear())

#         # candidate position after lane change is over
#         footpoint = get_footpoint(veh_ego)
#         lane = roadway[veh_ego.state.posF.roadind.tag]
#         lane_R = roadway[LaneTag(lane.tag.segment, lane.tag.lane - 1)]
#         roadproj = proj(footpoint, lane_R, roadway)
#         frenet_R = Frenet(RoadIndex(roadproj), roadway)
#         egostate_R = VehicleState(frenet_R, roadway, veh_ego.state.v)

#         Δaccel_n = 0.0
#         passes_safety_criterion = true
#         if rear_R.ind != 0
#             id = scene[rear_R.ind].def.id
#             accel_n_orig = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#             veh_ego.state = egostate_R
#             accel_n_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#             veh_ego.state = egostate_M
#             passes_safety_criterion = accel_n_test ≥ -mobil.safe_decel
#             Δaccel_n = accel_n_test - accel_n_orig
#         end
#         drawtext(@sprintf("Δaccel n: %10.3f", Δaccel_n), yₒ + 5*textparams.y_jump, rendermodel, textparams)

#         if passes_safety_criterion

#             Δaccel_o = 0.0
#             if rear_M.ind != 0
#                 id = scene[rear_M.ind].def.id
#                 accel_o_orig = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#                 veh_ego.state = egostate_R
#                 accel_o_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#                 veh_ego.state = egostate_M
#                 Δaccel_o = accel_o_test - accel_o_orig
#             end
#             drawtext(@sprintf("Δaccel o: %10.3f", Δaccel_o), yₒ + 6*textparams.y_jump, rendermodel, textparams)

#             veh_ego.state = egostate_R
#             accel_M_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, overlay.egoid))
#             veh_ego.state = egostate_M
#             Δaccel_M = accel_M_test - accel_M_orig

#             drawtext(@sprintf("Δaccel M: %10.3f", Δaccel_M), yₒ + 7*textparams.y_jump, rendermodel, textparams)

#             Δaₜₕ = Δaccel_M + mobil.politeness*(Δaccel_n + Δaccel_o)
#             if Δaₜₕ > advantage_threshold
#                 dir = DIR_RIGHT
#                 advantage_threshold = Δaₜₕ
#             end

#             drawtext(@sprintf("Δaₜₕ: %10.3f", Δaₜₕ), yₒ + 8*textparams.y_jump, rendermodel, textparams)
#             drawtext(@sprintf("advantage_threshold: %10.3f", advantage_threshold), yₒ + 9*textparams.y_jump, rendermodel, textparams)
#         end
#     end

#     if left_lane_exists
#         rear_L = get_neighbor_rear_along_left_lane(scene, vehicle_index, roadway, VehicleTargetPointFront(), VehicleTargetPointFront(), VehicleTargetPointRear())

#         # candidate position after lane change is over
#         footpoint = get_footpoint(veh_ego)
#         lane = roadway[veh_ego.state.posF.roadind.tag]
#         lane_L = roadway[LaneTag(lane.tag.segment, lane.tag.lane + 1)]
#         roadproj = proj(footpoint, lane_L, roadway)
#         frenet_L = Frenet(RoadIndex(roadproj), roadway)
#         egostate_L = VehicleState(frenet_L, roadway, veh_ego.state.v)

#         Δaccel_n = 0.0
#         passes_safety_criterion = true
#         if rear_L.ind != 0
#             id = scene[rear_L.ind].def.id
#             accel_n_orig = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#             veh_ego.state = egostate_L
#             # render!(rendermodel, veh_ego, RGBA(0.0,0.0,1.0,0.5))
#             accel_n_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#             # accel_n_test = rand(track_longitudinal!(reset_hidden_state!(mobil.mlon), scene, roadway, id, vehicle_index))
#             drawtext(@sprintf("accel n test: %10.3f", accel_n_test), yₒ + 10*textparams.y_jump, rendermodel, textparams)

#             body = inertial2body(get_rear(scene[rear_L.ind]), get_front(veh_ego)) # project target to be relative to ego
#             s_gap = body.x
#             drawtext(@sprintf("s_gap L: %10.3f", s_gap), yₒ + 9*textparams.y_jump, rendermodel, textparams)

#             veh_ego.state = egostate_M
#             passes_safety_criterion = accel_n_test ≥ -mobil.safe_decel
#             Δaccel_n = accel_n_test - accel_n_orig
#         end
#         drawtext(@sprintf("Δaccel n: %10.3f", Δaccel_n), yₒ + 11*textparams.y_jump, rendermodel, textparams)

#         if passes_safety_criterion


#             Δaccel_o = 0.0
#             if rear_M.ind != 0
#                 id = scene[rear_M.ind].def.id
#                 accel_o_orig = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#                 veh_ego.state = egostate_L
#                 accel_o_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, id))
#                 veh_ego.state = egostate_M
#                 Δaccel_o = accel_o_test - accel_o_orig
#             end
#             drawtext(@sprintf("Δaccel o: %10.3f", Δaccel_o), yₒ + 12*textparams.y_jump, rendermodel, textparams)

#             veh_ego.state = egostate_L
#             accel_M_test = rand(observe!(reset_hidden_state!(mobil.mlon), scene, roadway, overlay.egoid))
#             veh_ego.state = egostate_M
#             Δaccel_M = accel_M_test - accel_M_orig
#             drawtext(@sprintf("Δaccel M: %10.3f", Δaccel_M), yₒ + 13*textparams.y_jump, rendermodel, textparams)

#             Δaₜₕ = Δaccel_M + mobil.politeness*(Δaccel_n + Δaccel_o)
#             if Δaₜₕ > advantage_threshold
#                 dir = DIR_LEFT
#                 advantage_threshold = Δaₜₕ
#             end

#             drawtext(@sprintf("Δaₜₕ: %10.3f", Δaₜₕ), yₒ + 14*textparams.y_jump, rendermodel, textparams)
#             drawtext(@sprintf("advantage_threshold: %10.3f", advantage_threshold), yₒ + 15*textparams.y_jump, rendermodel, textparams)
#         end
#     end

#     drawtext(@sprintf("dir: %10d", dir), yₒ + 17*textparams.y_jump, rendermodel, textparams)

#     rendermodel
# end

# type CollisionOverlay <: SceneOverlay
#     target_id::Int # if -1 does it for all
#     color::Colorant
#     mem::CPAMemory

#     CollisionOverlay(target_id::Int=-1; color::Colorant=RGBA(1.0,0.0,0.0,0.5)) = new(target_id, color, CPAMemory())
# end
# function render!(rendermodel::RenderModel, overlay::CollisionOverlay, scene::Scene, roadway::Roadway)

#     if overlay.target_id < 0
#         target_inds = 1:length(scene)
#     else
#         ind = findfirst(scene, overlay.target_id)
#         target_inds = ind:ind
#     end

#     for ind in target_inds
#         veh = scene[ind]
#         if get_first_collision(scene, ind, overlay.mem).is_colliding
#             render!(rendermodel, scene[ind], overlay.color)
#         end
#     end

#     rendermodel
# end

mutable struct MarkerDistOverlay <: SceneOverlay
    target_id::Int
    textparams::TextParams
    rec::SceneRecord
    function MarkerDistOverlay(target_id::Int;
        textparams::TextParams=TextParams(),
        )

        new(target_id, textparams, SceneRecord(1, 0.1))
    end
end
function render!(rendermodel::RenderModel, overlay::MarkerDistOverlay, scene::Scene, roadway::Roadway)

    textparams = overlay.textparams
    yₒ = textparams.y_start
    Δy = textparams.y_jump

    update!(overlay.rec, scene)

    vehicle_index = findfirst(scene, overlay.target_id)
    if vehicle_index != nothing
        veh_ego = scene[vehicle_index]
        drawtext(@sprintf("lane offset:       %10.3f", veh_ego.state.posF.t), yₒ + 0*Δy, rendermodel, textparams)
        drawtext(@sprintf("markerdist left:   %10.3f", convert(Float64, get(MARKERDIST_LEFT, overlay.rec, roadway, vehicle_index))), yₒ + 1*Δy, rendermodel, textparams)
        drawtext(@sprintf("markerdist right:  %10.3f", convert(Float64, get(MARKERDIST_RIGHT, overlay.rec, roadway, vehicle_index))), yₒ + 2*Δy, rendermodel, textparams)
    end

    rendermodel
end
