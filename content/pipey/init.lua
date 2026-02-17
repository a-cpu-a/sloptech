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

local LUT = {}
local function buildPipeyBlockName(info)
    local suf = "";
    if #info.type ~= 0 then
        suf = info.type .. '_'
    end
    --print(mn .. ":" .. info.kind .. "_" .. info.tier .. "_" .. suf .. info.shapeId)
    return mn .. ":" .. info.kind .. "_" .. info.tier .. "_" .. suf .. info.shapeId
end
local function updatePipeyBlockName(oldInfo, newShapeId)
    return buildPipeyBlockName({
        kind = oldInfo.kind,
        type = oldInfo.type,
        tier = oldInfo.tier,
        shapeId = newShapeId
    });
end
local function shapeNum2Id(num)
    if num == 64 then
        return '00'
    end
    return b:sub(num, num)
end

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

        local shapeId = shapeNum2Id(shape);

        local info = { kind = kind, tier = tierName, type = "", shapeId = shapeId };
        local name = buildPipeyBlockName(info);
        LUT[name] = info;


        local tiertex = "";
        if tierName == 'quadruple' or tierName == 'nonuple' then tiertex = '_' .. tierName end

        core.register_node(name, {
            description = "Someium " .. kind .. "\n⁂₂\n"
                .. "Max voltage: 64 (HV)\nMax amperage: 1\nLoss/meter/ampere: 6 EU-volt\n"
                .. "Transfer rate: 64/s\nPriority: 64\n"
                .. "Air transfer rate: 64\n"
                ..
                "Transfer rate: 69L/t\nTemperature limit: 6900K\nCan handle gases, acids, cryogenics, all plasmas\nHAZARDOUS:\nCarcinogenic, caused by any contact",
            drawtype = "nodebox",
            paramtype = "light",
            paramtype2 = "color",                                                                -- CRITICAL: Stores the material color
            tiles = { mn .. "_blocks." .. kind .. tiertex .. "_base.png" .. "^[multiply:#FFF" }, -- Base texture

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

            on_place = function(itemstack, placer, pointedThing)
                local info = LUT[itemstack:get_name()];
                local tmp = ItemStack(itemstack);
                tmp:set_name(updatePipeyBlockName(info, '0'));
                core.item_place(tmp, placer, pointedThing, math.random() * 256);
                itemstack:set_count(itemstack:get_count() - 1);
            end
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
local function opDirIdx(dir)
    if dir == 0 then
        return 5 -- Top
    end
    if dir == 5 then
        return 0 -- Bottom
    end
    if dir == 1 then
        return 4 -- Right
    end
    if dir == 4 then
        return 1 -- Left
    end
    if dir == 2 then
        return 3 -- Front
    end
    return 2     -- Back
end
local function areKindsCompatible(k1, k2)
    if k1 == k2 then return true end
    if k1 == 'wire' or k1 == 'cable' then
        return k2 == 'wire' or k2 == 'cable'
    end
    return false;
end

local function mapNodeId2ShapeNum(shapeId)
    if shapeId == "00" then
        return 64
    end
    for i = 1, #b - 1 do -- -1 cuz no need to check last one
        if shapeId == b:sub(i, i) then
            return i
        end
    end
    return 63
end

sloptech.wrenchUse = function(pos, posAbove)
    local dir = vector.subtract(posAbove, pos)
    local idx = getDirIdx(dir)

    if not idx then -- Clicked from inside?
        print(dump(dir) .. "! hi")
        return
    end

    local node = core.get_node(pos);
    local nodeInfo = LUT[node.name];
    local shapeNum = mapNodeId2ShapeNum(nodeInfo.shapeId);
    local newShape = bit.bxor(shapeNum - 1, 2 ^ idx) + 1
    local connecting = bit.band(shapeNum - 1, 2 ^ idx) == 0;
    local shapeId = shapeNum2Id(newShape);
    local new = updatePipeyBlockName(nodeInfo, shapeId)
    core.swap_node(pos, { name = new, param2 = node.param2 })

    --print('hi, noden: ' ..
    --    node.name .. ' fidx: ' .. idx .. ' sn: ' .. shapeNum .. ' news: ' .. newShape .. ' newi: ' .. new)

    local p2 = vector.add(pos, dir);
    local n2 = core.get_node(p2);
    local n2Info = LUT[n2.name];
    if n2Info ~= nil and areKindsCompatible(n2Info.kind, nodeInfo.kind) then
        idx = opDirIdx(idx);
        shapeNum = mapNodeId2ShapeNum(n2Info.shapeId);
        local alreadyConnected = bit.band(shapeNum - 1, 2 ^ idx) ~= 0;
        if alreadyConnected ~= connecting then
            -- if user has odd mismatching ones, then match them together
            newShape = bit.bxor(shapeNum - 1, 2 ^ idx) + 1
            shapeId = shapeNum2Id(newShape);
            new = updatePipeyBlockName(n2Info, shapeId)
            core.swap_node(p2, { name = new, param2 = node.param2 })
        end
    end
end

for k, def in pairs(PIPE_TIERS) do
    regPipeyBlocks('pipe', k, def);
end
for k, def in pairs(WIRE_TIERS) do
    regPipeyBlocks('wire', k, def);
end
for k, def in pairs(CABLE_TIERS) do
    regPipeyBlocks('cable', k, def);
end
