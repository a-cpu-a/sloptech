local mn = "sloptech";

local globalMachineMap

core.register_globalstep(function(dtime)
    --globalMachineMap
end)

core.register_node(mn .. ':test_machine', {
    description = "Test machine\nDoes nothing\nVoltage in: 8 EU/t (ULV)\nEnergy capacity: 1,024 EU",
    tiles = { mn .. '_blocks.machines.test_in.png' },
    groups = {
        cracky = 1,
        [mn .. ':' .. 'machine'] = 1
    },

    on_construct = function(pos)
        core.log('cons ' .. dump(pos))
        core.get_node_timer(pos):start(0.2);
    end,
    on_destruct = function(pos)

    end,

    -- 2. What happens when the timer triggers
    on_timer = function(pos, elapsed)
        core.log('E: ' .. elapsed)
        -- Add the smoke particle
        core.add_particle({
            pos = {
                x = pos.x + math.random() * 0.5 - 0.25,
                y = pos.y + 0.5,
                z = pos.z + math.random() * 0.5 - 0.25
            },

            velocity = { x = 0, y = 0.5, z = 0 },           -- Move upward
            acceleration = { x = 0.05, y = 0.1, z = 0.05 }, -- Constant speed

            expirationtime = 3.5,                           -- How long the smoke lasts
            size = 4,                                       -- Size of the smoke puff
            collisiondetection = true,

            texture = "sloptech_particles.smoke.png"
        })

        -- Return true to keep the timer running (loops the tick)
        return true
    end,

    after_place_node = sloptech._priv.handleMachineConnect
})

core.register_node(mn .. ':creative_generator', {
    description = "Creative generator\nFree energy",
    tiles = { mn .. '_blocks.machines.test_out.png' },
    groups = {
        cracky = 1,
        [mn .. ':' .. 'machine'] = 1
    },
    after_place_node = sloptech._priv.handleMachineConnect
})
