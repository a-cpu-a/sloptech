local mn = "sloptech";

local globalMachineMap = {}

core.register_globalstep(function(_dtime)
    for pk, p in pairs(globalMachineMap) do
        local node = core.get_node(p)
        local bad = true
        if p ~= 'unknown' then
            local r = core.registered_nodes[node.name];
            local f = r[mn .. ':' .. 'tick']
            if f ~= nil then
                f(p, node)
                bad = false
            end
        end
        if bad then globalMachineMap[pk] = nil end
    end
end)
local function pos2Str(p)
    return p[1] .. '_' .. p[2] .. '_' .. p[3]
end

core.register_node(mn .. ':test_machine', {
    description = "Test machine\nDoes nothing\nVoltage in: 8 EU/t (ULV)\nEnergy capacity: 1,024 EU",
    tiles = { mn .. '_blocks.machines.test_in.png' },
    groups = {
        cracky = 1,
        [mn .. ':' .. 'machine'] = 1
    },

    [mn .. ':' .. 'tick'] = function(pos, node)
        core.get_meta(pos):set_int('active', 1)
        if math.random() > 0.1 then
            core.get_meta(pos):set_string('active', '')
        end
    end,

    on_construct = function(pos)
        core.get_node_timer(pos):start(0.2);
        globalMachineMap[pos2Str(pos)] = pos
    end,
    on_destruct = function(pos)
        globalMachineMap[pos2Str(pos)] = nil
    end,

    -- 2. What happens when the timer triggers
    on_timer = function(pos, _el, node, _timeout)
        if core.get_meta(pos):contains('active') then
            core.add_particle({
                pos = {
                    x = pos.x + math.random() * 0.5 - 0.25,
                    y = pos.y + 0.5,
                    z = pos.z + math.random() * 0.5 - 0.25
                },
                velocity = { x = 0, y = 0.5, z = 0 },
                acceleration = { x = 0.2, y = 0.4, z = 0.2 },
                expirationtime = 5.5,
                size = 4,
                collisiondetection = true,
                texture = "sloptech_particles.smoke.png"
            })
        end
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
