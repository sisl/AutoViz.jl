
function AutoViz.render!(rendermodel::RenderModel, roadway::OpenMap)
    for (segid, segment) in roadway.road_segments
        render!(rendermodel, roadway, segment)
    end
    return rendermodel
end

function AutoViz.render!(rendermodel::RenderModel, roadway::OpenMap, segment::RoadSegment,
    color_asphalt::Colorant=COLOR_ASPHALT
    )
    # fill in road area
    bounds = get_segment_bounds(roadway, segment.id)
    road_area = Array{Float64}(undef, 2, length(bounds))
    for i=1:length(bounds)
        road_area[1,i] = bounds[i].x
        road_area[2,i] = bounds[i].y
    end    
    add_instruction!(rendermodel, render_fill_region, (road_area,color_asphalt))  

    # Outside boundaries
    for boundary_id in segment.boundaries
        boundary = roadway.boundaries[boundary_id]
        render!(rendermodel, roadway, boundary)
    end   

    # Lane boundaries
    for lane_id in segment.lanes
        lane_segment = roadway.lane_segments[lane_id]
        render!(rendermodel, roadway, lane_segment)
    end
    return rendermodel
end

function AutoViz.render!(rendermodel::RenderModel, roadway::OpenMap, lane::LaneSegment)
    # render boundaries 
    for boundary_left_id in lane.boundaries_left
        render!(rendermodel, roadway, roadway.boundaries[boundary_left_id])
    end
    for boundary_right_id in lane.boundaries_right
        render!(rendermodel, roadway, roadway.boundaries[boundary_right_id])
    end     
    return rendermodel   
end


function AutoViz.render!(rendermodel::RenderModel, roadway::OpenMap, boundary::Boundary,
    lane_marking_width  :: Real=0.15, # [m] 
    lane_dash_len       :: Real=0.91, # [m]
    lane_dash_spacing   :: Real=2.74, # [m]
    lane_dash_offset    :: Real=0.00,  # [m]
    marker_color::RGB = COLOR_LANE_MARKINGS_WHITE
    )
    
    cached_curve = roadway.cached_curves[boundary.curve]
    pts = Array{Float64, 2}(undef, 2, length(cached_curve.pts))
    for (i, pt) in enumerate(cached_curve.pts)
        pts[1, i] = pt.x 
        pts[2, i] = pt.y
    end 
    # marker_color= boundary.color == :yellow ? COLOR_LANE_MARKINGS_YELLOW : COLOR_LANE_MARKINGS_WHITE
    if boundary.boundary_type == :dashed
        add_instruction!(rendermodel, render_dashed_line, (pts, marker_color, lane_marking_width, lane_dash_len, lane_dash_spacing, lane_dash_offset))
    else
        add_instruction!(rendermodel, render_line, (pts, marker_color, lane_marking_width))
    end
    return rendermodel
end