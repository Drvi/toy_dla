using Random: seed!, rand!
using SimpleDirectMediaLayer.LibSDL2

const WIDTH = 800
const HEIGHT = 600
const N_PARTICLES = 3 * 65_536
const FROZEN_COORDS = [
    (HEIGHT ÷ 2, WIDTH ÷ 2),
    (HEIGHT ÷ 3, WIDTH ÷ 2),
    (HEIGHT ÷ 2, WIDTH ÷ 3)
]
const RED = 0x00FF0000
const WHITE = 0x00FFFFFF

seed!(42)

mutable struct Particle
    x::UInt16
    y::UInt16
end

function add_particles!(world, n)
    height, width = size(world)
    particles = Vector{Particle}(undef, n)
    for i = 1:n
        x = rand(1:height)
        y = rand(1:width)
        while world[x, y] != 0 # BLACK ~ tile empty
            x = rand(1:height)
            y = rand(1:width)
        end
        particles[i] = Particle(x, y)
        world[x, y] = WHITE # WHITE ~ tile occupied by non-frozen
    end
    return particles
end

function resolve_move!(p::Particle, world, dest_x, dest_y)
    @inbounds candidate_spot_val = world[dest_x, dest_y]
    if candidate_spot_val == 0 # tile empty
        @inbounds world[p.x, p.y], world[dest_x, dest_y] = world[dest_x, dest_y], world[p.x, p.y]
        p.x = dest_x
        p.y = dest_y
    elseif candidate_spot_val == RED # tile frozen
        @inbounds world[p.x, p.y] = RED
        p.x = p.y = 0
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
    return
end

function step!(world, particles, directions)
    any_change = false
    for (particle, direction) in zip(particles, directions)
        particle.x == 0 && particle.y == 0 && continue
        any_change = true
        move!(particle, world, direction)
    end
    return any_change
end

function simulate()
    # The "double transpose" will leave us with a row-major array which we want to pass
    # to SDL
    world = transpose(reshape(zeros(UInt32, HEIGHT, WIDTH), WIDTH, HEIGHT))
    for (x, y) in FROZEN_COORDS
        world[x, y] = RED
    end
    particles = add_particles!(world, N_PARTICLES)
    directions = Vector{Int8}(undef, length(particles))

    window = SDL_CreateWindow("DLA", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN)
    SDL_SetWindowResizable(window, SDL_FALSE)
    
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, WIDTH, HEIGHT);
    window_should_close = false
    try
        while !window_should_close
            event_ref = Ref{SDL_Event}()
            while Bool(SDL_PollEvent(event_ref))
                evt = event_ref[]
                evt_ty = evt.type
                if evt_ty == SDL_QUIT
                    window_should_close = true
                    break
                end
            end

            rand!(directions, (1, 2, 3, 4))
            window_should_close = !step!(world, particles, directions)

            SDL_UpdateTexture(texture, C_NULL, world, WIDTH * sizeof(UInt32))
            SDL_RenderClear(renderer);
            SDL_RenderCopy(renderer, texture, C_NULL, C_NULL);
            SDL_RenderPresent(renderer);
        end
    finally
        SDL_DestroyTexture(texture)
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(window)
        SDL_Quit()
    end
    return
end

simulate()
