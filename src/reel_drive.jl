export
    PNGFrames,
    SVGFrames

PNGFrames(; fps::Int=24) = Frames(MIME("image/png"), fps=fps)
SVGFrames(; fps::Int=24) = Frames(MIME("image/svg"), fps=fps)