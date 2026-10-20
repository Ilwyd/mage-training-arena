-- Graveyard
-- Draws a red or green box around the bones in the player's inventory
-- Red boxes turn to green once the player has enough bones to created 16 fruit (for 1 pizzaz point)

local graveyard_data = require("graveyarddata")

local INV_COMPONENT = 5
local RED = Vector4.new(1, 0, 0, 1)
local GREEN = Vector4.new(0, 1, 0, 1)
local inv = Inventory.Find(config.Inv.INV)
local rects = {}

-- Initial set up of the rects table
-- 1 rect for each of the inventory slots
for i=1, 28 do
    rects[i] = nil
end

-- Gets the total number of fruit the player could make at the current time
local function getTotalFruit(inv)
    local total_1 = inv:GetTotal(graveyard_data.bones[1])
    local total_2 = inv:GetTotal(graveyard_data.bones[2])
    local total_3 = inv:GetTotal(graveyard_data.bones[3])
    local total_4 = inv:GetTotal(graveyard_data.bones[4])

    return total_1 + total_2 * 2 + total_3 * 3 + total_4 * 4
end


local rectColour = Vector4.new(1, 0, 0, 1)
local colourChanged = false
Event.Draw.Subscribe("boneCheck", function(inventoryUpdatedEvent)
    -- Getting the inventory and the inventory component
    local inv_inter = ui.Interfaces:GetInterface(id.Interface.TOPLEVEL_V2_INVENTORY)

    if inv_inter == nil then
        return
    end

    local inv_component = inv_inter:GetComponent(INV_COMPONENT)

    if inv_component == nil then
        return
    end

    -- Current number of fruit the player could make
    local total_fruit = getTotalFruit(inv)

    -- Swap the rectColour if the player's total_fruit goes above or below 16
    if total_fruit > 15 and rectColour ~= GREEN then
        rectColour = GREEN
        colourChanged = true
    elseif total_fruit < 16 and rectColour ~= RED then
        rectColour = RED
        colourChanged = true
    end

    -- Looping over every inventory slot
    inv_component:IterateDynamicComponents(function (component, visible)
        if component == nil then
            return false
        end

        -- We only care about SPRITEs
        if component.type ~= ui.ComponentType.SPRITE then
            return false
        end

        -- Generating the id to be used as an index to the rects table
        local id = component.dynamicID + 1

        -- Looping over each bone in graveyard_data
        -- If the sprite is the sprite of a bone, draw a rect around it and add it to the rects table
        for _, bone in ipairs(graveyard_data.bones) do
            if component.associatedObjectID == bone.id then
                if rects[id] ~= nil then
                    return false
                end

                local rect = ui.Rectangle.new(inv_component)
                rect:SetPos(component.x, component.y)
                rect:SetSize(component.width, component.height)
                rect.colour = rectColour
                rects[id] = rect

                return false
            end
        end
        
        -- If the sprite was not a bone and the rects table has a rect at this inventory slot, remove it
        if rects[id] ~= nil then
            rects[id]:Destroy()
            rects[id] = nil
        end

        return false -- Keep iterating
    end)

    -- If the colour has changed, loop over all of the rects and change their colour
    if colourChanged then
        for idx, _ in pairs(rects) do
            if rects[idx] ~= nil then
                rects[idx].colour = rectColour
            end
        end
        colourChanged = false
    end
    
end)