local graveyard_data = require("graveyarddata")

local INV_COMPONENT = 5
local inv = Inventory.Find(config.Inv.INV)
local rects = {}

for i=1, 28 do
    rects[i] = nil
end

local function getTotalPoints(inv)
    local total_1 = inv:GetTotal(graveyard_data.bones[1])
    local total_2 = inv:GetTotal(graveyard_data.bones[2])
    local total_3 = inv:GetTotal(graveyard_data.bones[3])
    local total_4 = inv:GetTotal(graveyard_data.bones[4])

    return total_1 + total_2 * 2 + total_3 * 3 + total_4 * 4
end


local rectColour = Vector4.new(1, 0, 0, 1)
local red = Vector4.new(1, 0, 0, 1)
local green = Vector4.new(0, 1, 0, 1)
local colourChanged = false
Event.Draw.Subscribe("boneCheck", function(inventoryUpdatedEvent)
    local inv_inter = ui.Interfaces:GetInterface(id.Interface.TOPLEVEL_V2_INVENTORY)

    if inv_inter == nil then
        return
    end

    local inv_component = inv_inter:GetComponent(INV_COMPONENT)

    if inv_component == nil then
        return
    end

    local held_points = getTotalPoints(inv)


    if held_points > 15 and rectColour ~= green then
        rectColour = green
        colourChanged = true
    elseif held_points < 16 and rectColour ~= red then
        rectColour = red
        colourChanged = true
    end

    inv_component:IterateDynamicComponents(function (component, visible)
        if component == nil then
            return false
        end

        if component.type ~= ui.ComponentType.SPRITE then
            return false
        end

        local id = component.dynamicID + 1

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
        
        if rects[id] ~= nil then
            rects[id]:Destroy()
            rects[id] = nil
        end
        return false -- Keep iterating
    end)

    if colourChanged then
        for idx, _ in pairs(rects) do
            if rects[idx] ~= nil then
                rects[idx].colour = rectColour
            end
        end
        colourChanged = false
    end
    
end)