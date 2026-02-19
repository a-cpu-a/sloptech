local mn = "sloptech";

local globalMachineMap = {}

core.register_globalstep(function(_dtime)
    for pk, p in pairs(globalMachineMap) do
        local node = core.get_node(p)
        local bad = true
        if node.name ~= 'unknown' then
            local r = core.registered_nodes[node.name];
            local f = r[mn .. ':tick']
            if f ~= nil then
                f(p, node)
                bad = false
            end
        end
        if bad then globalMachineMap[pk] = nil end
    end
end)
core.register_on_shutdown(function()
    globalMachineMap = {}
end)
local function pos2Str(p)
    return p[1] .. '_' .. p[2] .. '_' .. p[3]
end
local function onConstructRegister(pos)
    globalMachineMap[pos2Str(pos)] = pos
end
local function onDestructUnregister(pos)
    globalMachineMap[pos2Str(pos)] = nil
end
local tickingNodes = {}

local function nodeMaxEnergy(pos, node)
    return 1024
end
local function nodeVoltage(pos, node)
    return 8
end

core.register_node(mn .. ':test_machine', {
    description = "Test machine\nDoes nothing\nVoltage in: 8 EU/t (ULV)\nEnergy capacity: 1,024 EU",
    tiles = { mn .. '_blocks.machines.test_in.png' },
    groups = {
        cracky = 1,
        [mn .. ':machine'] = 1
    },

    [mn .. ':tick'] = function(pos, node)
        local meta = core.get_meta(pos)
        local e = meta:get_int('energy')
        if e >= 8 then
            meta:set_int('energy', e - 8)
            meta:set_int('active', 1)
        else
            meta:set_string('active', '')
            --core.log('no e: ' .. e)
        end
    end,

    on_construct = function(pos)
        core.get_node_timer(pos):start(0.2);
        globalMachineMap[pos2Str(pos)] = pos
    end,
    on_destruct = onDestructUnregister,

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
table.insert(tickingNodes, mn .. ':test_machine')

--[[
local function debugParticle(p_from, p_to, p_type)
    local tex = "unknown_node.png"
    local vel_y = 0

    if p_type == "charge" then
        tex = "aa.png"
        vel_y = 2
    elseif p_type == "wire" then
        tex = "miner_pipe.png"
    elseif p_type == "block" then
        tex = "pipe_optical_in.png"
    elseif p_type == "block2" then
        tex = "pipe_duct_in.png"
    end

    -- Calculate direction vector from center of p_from to center of p_to
    local dir = vector.direction(
        p_from,
        p_to
    )

    -- Adjust speed (distance is 1, so speed 2 makes it cross in 0.5s)
    dir = vector.multiply(dir, 2)

    core.add_particle({
        pos = vector.add(p_from, 0.5),
        velocity = { x = dir.x, y = dir.y + vel_y, z = dir.z },
        expirationtime = 0.5,
        size = 2,
        collisiondetection = false,
        texture = tex,
        glow = 5
    })
end]]

core.register_node(mn .. ':creative_generator', {
    description = "Creative generator\nFree energy",
    tiles = { mn .. '_blocks.machines.test_out.png' },
    groups = {
        cracky = 1,
        [mn .. ':machine'] = 1
    },

    [mn .. ':tick'] = function(pos, node)
        local voltage = 8
        local energyLeft = 8

        local lookList = { pos }
        local used = {}
        used[pos2Str(pos)] = 0 --loss

        while #lookList ~= 0 do
            local nextLookList = {}
            for _i, p in ipairs(lookList) do
                for i = 1, 6 do
                    local p2 = vector.add(p, sloptech.dir.fromIdx(i))
                    local str = pos2Str(p2);
                    if used[str] == nil then
                        --todo: check neighbors for loss instead (take smallest loss, tweak it)
                        local n = core.get_node(p2)

                        if core.get_item_group(n.name, mn .. ':machine') == 1 then
                            used[str] = -1

                            local meta = core.get_meta(p2)
                            local e = meta:get_int('energy')
                            local max = nodeMaxEnergy(p2, n)
                            local neededVolts = nodeVoltage(p2, n)
                            if neededVolts <= voltage and e ~= max then
                                if neededVolts > voltage then
                                    --TODO: boom!
                                else
                                    --debugParticle(p, p2, "charge") -- Visual: Charge (Remaining energy used)
                                    local needCount = max - e
                                    if needCount >= energyLeft then
                                        meta:set_int('energy', e + energyLeft)
                                        return
                                    else
                                        meta:set_int('energy', max)
                                        energyLeft = energyLeft - needCount
                                    end
                                end
                            else
                                -- Machine found but didn't accept energy (full or low voltage)
                                --debugParticle(p, p2, "block")
                            end
                        elseif core.get_item_group(n.name, mn .. ':wiring') == 1 then
                            if sloptech.pipey.connected(n.name, sloptech.dir.rev(i)) then
                                table.insert(nextLookList, p2)
                                used[str] = 0 -- todo store loss?
                                --debugParticle(p, p2, "wire") -- Visual: Wire path
                            else
                                --debugParticle(p, p2, "block2")
                            end
                        else
                            used[str] = -1
                            --debugParticle(p, p2, "block")
                        end
                    end
                end
            end
            lookList = nextLookList;
        end

        --core.get_meta(pos):set_int('active', 1)
        --TODO: output
    end,
    on_construct = onConstructRegister,
    on_destruct = onDestructUnregister,

    after_place_node = sloptech._priv.handleMachineConnect
})
table.insert(tickingNodes, mn .. ':creative_generator')


core.register_lbm({
    name = mn .. ":restart_ticking",
    nodenames = tickingNodes,
    run_at_every_load = true,
    action = function(pos, node)
        globalMachineMap[pos2Str(pos)] = pos
    end
})
tickingNodes = nil
