local mn = "sloptech";

local WIRE_TIERS = {
    x1 = {
        thickness = 3 / 32,
    },
    x2 = {
        thickness = 5 / 32
    },
    x4 = {
        thickness = 7 / 32
    },
    x8 = {
        thickness = 9 / 32
    },
    x16 = {
        thickness = 13 / 32
    }
}
local CABLE_TIERS = {
    x1 = {
        thickness = 4 / 32,
    },
    x2 = {
        thickness = 6 / 32
    },
    x4 = {
        thickness = 8 / 32
    },
    x8 = {
        thickness = 10 / 32
    },
    x16 = {
        thickness = 14 / 32
    }
}
local PIPE_TIERS = {
    tiny = { --2
        thickness = 4 / 32,
    },
    small = { --4
        thickness = 6 / 32,
    },
    normal = { --12
        thickness = 8 / 32
    },
    large = { --24
        thickness = 10 / 32
    },
    huge = { --48
        thickness = 12 / 32
    },
    quadruple = {
        thickness = 14 / 32
    },
    nonuple = {
        thickness = 14 / 32
    }
}
local ITEM_PIPE_TIERS = {
    small = {
        thickness = 6 / 32,
    },
    normal = {
        thickness = 8 / 32
    },
    large = {
        thickness = 10 / 32
    },
    huge = {
        thickness = 12 / 32
    },
}
local VENT_TIERS = {
}

local b = '0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

local handleRclick;
local function regPipeyBlocks(kind, tierName, tierInfo)
    for shape = 1, 64 do -- Skip 0 (usually invisible/air)
        -- Box list, with the center
        local nodebox = { { -tierInfo.thickness, -tierInfo.thickness, -tierInfo.thickness, tierInfo.thickness, tierInfo
            .thickness, tierInfo.thickness } }

        -- Add arms: [-y-x-zZXY]
        for i = 0, 5 do
            if bit.band(shape - 1, 2 ^ i) ~= 0 then
                local x, y, z = -0.5, -0.5, -0.5;
                local pX, pY, pZ = 0.5, 0.5, 0.5;
                if i == 0 or i == 5 then
                    if i < 3 then
                        pY = -tierInfo.thickness;
                    else
                        y = tierInfo.thickness
                    end
                else
                    y = -tierInfo.thickness; pY = tierInfo.thickness
                end
                if i == 1 or i == 4 then
                    if i < 3 then
                        pX = -tierInfo.thickness;
                    else
                        x = tierInfo.thickness
                    end
                else
                    x = -tierInfo.thickness; pX = tierInfo.thickness
                end
                if i == 2 or i == 3 then
                    if i < 3 then
                        pZ = -tierInfo.thickness;
                    else
                        z = tierInfo.thickness
                    end
                else
                    z = -tierInfo.thickness; pZ = tierInfo.thickness
                end

                table.insert(nodebox,
                    { x, y, z, pX, pY, pZ })
            end
        end

        local shapeId = '00';
        if shape ~= 64 then shapeId = b:sub(shape, shape) end

        -- 2. Register the Node
        local name = mn .. ":" .. kind .. "_" .. tierName .. "_" .. shapeId

        core.register_node(name, {
            description = "Someium " .. kind .. "\n⁂₂\n"
                .. "Max voltage: 64 (HV)\nMax amperage: 1\nLoss/meter/ampere: 6 EU-volt\n"
                .. "Transfer rate: 64/s\nPriority: 64\n"
                .. "Air transfer rate: 64\n"
                ..
                "Transfer rate: 69L/t\nTemperature limit: 6900K\nCan handle gases, acids, cryogenics, all plasmas\nHAZARDOUS:\nCarcinogenic, caused by any contact",
            drawtype = "nodebox",
            paramtype = "light",
            paramtype2 = "color",                                                     -- CRITICAL: Stores the material color
            tiles = { mn .. "_blocks." .. kind .. "_base.png" .. "^[multiply:#FFF" }, -- Base texture

            -- We use color to tint the texture
            color = "#FFFFFF",

            node_box = {
                type = "fixed",
                fixed = nodebox
            },

            groups = {
                cracky = 1,
                [mn .. ":" .. kind .. "_" .. tierName] = 1, -- Group for ABM
                not_in_creative_inventory = (shapeId ~= 'B') and 1 or 0
            },

            drop = mn .. ":" .. kind .. "_" .. tierName .. "_B", -- Drop the base item

            -- Logic to toggle connection with Wrench
            on_rightclick = handleRclick
        })
    end
end

local function getDirIdx(dir)
    if dir.y == 1 then
        return 5 -- Top
    elseif dir.y == -1 then
        return 0 -- Bottom
    elseif dir.x == 1 then
        return 4 -- Right
    elseif dir.x == -1 then
        return 1 -- Left
    elseif dir.z == 1 then
        return 3 -- Front
    elseif dir.z == -1 then
        return 2 -- Back
    end
    return nil
end

local function mapNodeId2ShapeNum(id)
    local suffix = id:sub(-2)

    if suffix == "00" then
        return 64
    end

    local last = suffix:sub(-1)

    --print('mapNodeId2ShapeNum, noden: ' ..
    --    id .. ' suffix: ' .. suffix .. ' last: ' .. last)

    for i = 1, #b - 1 do -- -1 cuz no need to check last one
        if last == b:sub(i, i) then
            return i
        end
    end
    return 63
end

handleRclick = function(pos, node, clicker, itemstack, pointed_thing)
    if itemstack:get_name() ~= "sloptech:test_wrench" then
        return
    end

    local dir = vector.subtract(pointed_thing.above, pointed_thing.under)
    local idx = getDirIdx(dir)

    if not idx then -- Clicked from inside?
        print(dump(dir) .. "! hi")
        return
    end

    local shapeNum = mapNodeId2ShapeNum(node.name);
    local bits = shapeNum - 1
    bits = bit.bxor(bits, 2 ^ idx) -- Toggle the bit at index 'idx'
    local newShape = bits + 1

    local newShapeId = "00"
    if newShape ~= 64 then
        newShapeId = b:sub(newShape, newShape)
    end

    local was64 = 0;
    if shapeNum == 64 then was64 = 1 end
    local new = node.name:sub(1, -2 - was64) .. newShapeId

    --print('hi, noden: ' ..
    --    node.name .. ' fidx: ' .. idx .. ' sn: ' .. shapeNum .. ' news: ' .. newShape .. ' newi: ' .. new)

    core.swap_node(pos, { name = new, param2 = node.param2 })
end




for k, def in pairs(PIPE_TIERS) do
    regPipeyBlocks('pipe', k, def);
end
