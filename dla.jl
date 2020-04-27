using Random: seed!, rand!
using Makie: heatmap

const STEPS_TO_FRAME = 100 # do so many steps (of all walkers) before refreshing display
const WORLD_HEIGHT = 512
const WORLD_WIDTH = 512
const N_PARTICLES = 65_536
const FROZEN_COORDS = [
    (WORLD_HEIGHT÷2, WORLD_WIDTH÷2),
    (WORLD_HEIGHT÷3, WORLD_WIDTH÷2),
    (WORLD_HEIGHT÷2, WORLD_WIDTH÷3)
]

seed!(42)

mutable struct Particle
    x::UInt16
    y::UInt16
    frozen::Bool
end

function add_particles!(world, n)
    height, width = size(world)
    particles = Vector{Particle}(undef, n)
    for i = 1:n
        x = rand(1:height)
        y = rand(1:width)
        while world[x, y] != 0 # 0 ~ tile empty
            x = rand(1:height)
            y = rand(1:width)
        end
        particles[i] = Particle(x, y, false)
        world[x, y] = 1 # 1 ~ tile occupied by non-frozen
    end
    particles
end

function resolve_move!(p::Particle, world, dest_x, dest_y)
    @inbounds candidate_spot_val = world[dest_x, dest_y]
    if candidate_spot_val == 0 # tile empty
        @inbounds world[p.x, p.y], world[dest_x, dest_y] = world[dest_x, dest_y], world[p.x, p.y]
        p.x = dest_x
        p.y = dest_y
    elseif candidate_spot_val == -1 # tile frozen
        @inbounds world[p.x, p.y] = -1
        p.frozen = true
    end # don't move if you were about to collide with a non frozen
    return
end

function move!(p::Particle, world, direction)
    height, width = size(world)
    if direction == 1 # down
        x = p.x + 1
        x = x > height ? 1 : x
        resolve_move!(p, world, x, p.y)
    elseif direction == 2 # up
        x = p.x - 1
        x = x < 1 ? height : x
        resolve_move!(p, world, x, p.y)
    elseif direction == 3 # right
        y = p.y + 1
        y = y > width ? 1 : y
        resolve_move!(p, world, p.x, y)
    else # left
        y = p.y - 1
        y = y < 1 ? width : y
        resolve_move!(p, world, p.x, y)
    end
end

function step!(world, particles, directions)
    for (particle, direction) in zip(particles, directions)
        particle.frozen && continue
        move!(particle, world, direction)
    end
    world
end

function run!(world, particles, directions, n)
    for _ = 1:n
        rand!(directions, (1, 2, 3, 4))
        step!(world, particles, directions)
    end
    world
end

function simulate(
    world_height,
    world_width,
    frozen_coords::Vector{<:Tuple{Integer,Integer}},
    n_particles,
    steps_to_frame,
)
    world = zeros(Int8, world_height, world_width)
    for (x, y) in frozen_coords
        world[x, y] = -1
    end
    particles = add_particles!(world, n_particles)
    directions_buf = Vector{Int8}(undef, length(particles))

    scene = heatmap(
        world,
        show_axis = false,
        scale_plot = false,
        resolution = size(world) .* 2,
        colormap = [:red, :black, :white],
    )
    display(scene)

    while true
        run!(world, particles, directions_buf, steps_to_frame)
        scene.plots[end][1] = world
        sleep(0.00001)
    end
end

simulate(WORLD_HEIGHT, WORLD_WIDTH, FROZEN_COORDS, N_PARTICLES, STEPS_TO_FRAME)
