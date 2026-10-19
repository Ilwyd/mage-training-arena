-- Alchemists' Playground
--
-- Highlights in the game world, no extra interface:
--   * An arrow over the cupboard that holds the item currently worth 30 coins.
--   * The coin collector, when you have enough coins that you should deposit them, or when
--     you are about to leave the room while still holding coins (they would be lost).
--
-- How the cupboard is found:
--   The values window (interface 194) shows each item's coin value, so we know which item
--   is worth 30. The cupboards always hold the same sequence (boots, kiteshield, helm,
--   emerald, sword, then 3 empty), shifted by a random amount at every shuffle. As soon as
--   the player searches any cupboard that holds an item, we know the shift and therefore
--   where the 30-coin item is. Every shuffle (when the values change) forgets the layout.

local alch_data = require("alchdata")

-- When true, one search is used to work out what all eight cupboards hold.
-- When false, only cupboards the player has searched since the last shuffle are used.
-- NOTE: deducing unsearched cupboards needs a moderator ruling before this is submitted.
local PREDICT_LAYOUT = true

-- An item gained this many server ticks before a cupboard opens came out of that cupboard.
-- (In testing the item always arrived exactly one tick before the cupboard opened.)
local GAIN_MATCH_TICKS = 2

local ARROW_COLOUR = 0xFFD700FF           -- gold
local COLLECTOR_COLOUR = 0xFF8C00FF       -- orange: deposit now
local COLLECTOR_DANGER_COLOUR = 0xFF2020FF  -- red: more than the 12,000 deposit limit
-- Arrow tip height above the room's floor, in fine units (512 = one tile).
-- Tuned in the beta (2026-10-20): 900 + 1,600 looks right.
local ARROW_HEIGHT = 900 + 1600
local ARROW_SCALE = 0.6                   -- 1.0 = 700 units tall

local state = {
    tick = 0,                 -- server ticks counted while in the room
    in_room = false,
    values_signature = nil,   -- text of the five values, to notice when they change
    best_row = nil,           -- row in alch_data.ITEMS of the item worth 30 coins
    last_shuffle_tick = nil,
    boots_index = nil,        -- cupboard holding the boots in the current layout
    searched = {},            -- cupboard index -> row found there (0 = empty), this shuffle
    clicked_cupboard = nil,   -- cupboard the player last clicked "Search" on
    last_gain = nil,          -- { row, tick } of the last arena item added to the backpack
    item_counts = {},         -- row -> how many the backpack held last time we looked
    coins = 0,
    arrow_target = nil,       -- cupboard the arrow points at (nil = no arrow)
    collector_colour = nil,   -- colour for the coin collector highlight (nil = none)
}

---------------------------------------------------------------------------
-- Shapes
---------------------------------------------------------------------------

-- A downward arrow, drawn upright and always facing the camera.
local function arrowShape()
    local k = ARROW_SCALE
    local shape = ShapeData.new()
    shape.positions = {
        -- shaft
        Vector3.new(-60 * k, 700 * k, 0), Vector3.new(60 * k, 700 * k, 0),
        Vector3.new(60 * k, 300 * k, 0), Vector3.new(-60 * k, 300 * k, 0),
        -- head, pointing down
        Vector3.new(-180 * k, 300 * k, 0), Vector3.new(180 * k, 300 * k, 0), Vector3.new(0, 0, 0),
    }
    shape.tris = { 0, 1, 2, 0, 2, 3, 4, 5, 6 }
    shape.lines = { 0, 1, 1, 2, 3, 0, 4, 5, 5, 6, 6, 4 }
    return shape
end

-- A square on the floor: solid outline with a see-through fill.
local function floorSquareShape(half_size)
    local h = half_size
    local corners = {
        Vector3.new(-h, 0, -h), Vector3.new(h, 0, -h), Vector3.new(h, 0, h), Vector3.new(-h, 0, h),
    }
    local shape = ShapeData.new()
    shape.positions = { corners[1], corners[2], corners[3], corners[4], corners[1], corners[2], corners[3], corners[4] }
    shape.rgba = {
        0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,   -- outline
        0xFFFFFF50, 0xFFFFFF50, 0xFFFFFF50, 0xFFFFFF50,   -- fill
    }
    shape.lines = { 0, 1, 1, 2, 2, 3, 3, 0 }
    shape.tris = { 4, 5, 6, 4, 6, 7 }
    return shape
end

-- Shapes are drawn every frame with ShapeList.Draw (the same way tele.lua draws its paths).
-- ShapeEntity crashed the client when it was moved to a cupboard, so it isn't used.
local ARROW_SHAPE = arrowShape()
local COLLECTOR_SHAPE = floorSquareShape(400)

-- World position of a tile's centre, `height` fine units above that room's floor.
local function tilePosition(coord, height)
    return coord:ToCoordFine(true).position + Vector3.new(0, coord.level * alch_data.FLOOR_HEIGHT + height, 0)
end

---------------------------------------------------------------------------
-- Reading the game
---------------------------------------------------------------------------

local function playerCoord()
    if not Player.IsAvailable() then return nil end
    local me = Player.GetEntity()
    if me == nil or not me.isValid then return nil end
    return me.coordGrid
end

local function isInRoom(coord)
    local room = alch_data.ROOM
    return coord ~= nil
        and coord.level == room.level
        and coord.mapSquareX == room.map_square_x
        and coord.mapSquareZ == room.map_square_z
end

local function isNear(coord, target, range)
    return coord.level == target.level
        and math.abs(coord.x - target.x) <= range
        and math.abs(coord.z - target.z) <= range
end

-- Reads the five item values from the values window.
-- Returns (values by row, signature text), or nil while the window isn't ready.
local function readValues()
    local iface = ui.Interfaces:GetInterface(alch_data.INTERFACE_ID)
    if iface == nil then return nil end

    local values, parts = {}, {}
    for row, item in ipairs(alch_data.ITEMS) do
        local component = iface:GetComponent(item.value_static)
        if component == nil then return nil end
        local value = tonumber(component.content)
        -- The window shows 999 placeholders before the first real update.
        if value == nil or value >= 999 then return nil end
        values[row] = value
        parts[row] = tostring(value)
    end
    return values, table.concat(parts, ",")
end

local function bestRow(values)
    for row, value in ipairs(values) do
        if value == alch_data.BEST_VALUE then return row end
    end
    return nil
end

---------------------------------------------------------------------------
-- Cupboard layout
---------------------------------------------------------------------------

local function forgetLayout()
    state.searched = {}
    state.boots_index = nil
end

-- What a cupboard holds this shuffle (row, 0 = empty), or nil if we don't know.
local function contentsOf(index)
    if state.searched[index] ~= nil then return state.searched[index] end
    if PREDICT_LAYOUT and state.boots_index ~= nil then
        return alch_data.SEQUENCE[(index - state.boots_index) % 8 + 1]
    end
    return nil
end

-- Store what a search found. An item tells us where the boots are.
local function learn(index, row)
    if row > 0 then
        local boots_index = (index - (row - 1)) % 8
        if state.boots_index ~= nil and state.boots_index ~= boots_index then
            -- The layout moved without us noticing the shuffle; start over from this search.
            state.searched = {}
        end
        state.boots_index = boots_index
    end
    state.searched[index] = row
end

-- Cupboard holding the 30-coin item, if we know it.
local function targetCupboard()
    if state.best_row == nil then return nil end
    for index = 0, 7 do
        if contentsOf(index) == state.best_row then return index end
    end
    return nil
end

local function onShuffle(shuffle_tick)
    forgetLayout()
    state.last_shuffle_tick = shuffle_tick
end

---------------------------------------------------------------------------
-- Backpack
---------------------------------------------------------------------------

-- Re-counts the arena items and coins. With note_gains, an increase is remembered as
-- "just gained", so the next cupboard that opens can be matched to it.
local function countBackpack(note_gains)
    local backpack = Inventory.Find(config.Inv.INV)
    if backpack == nil or not backpack.isValid then return end

    for row, item in ipairs(alch_data.ITEMS) do
        local count = backpack:GetTotal(item.obj)
        if note_gains and count > (state.item_counts[row] or 0) then
            state.last_gain = { row = row, tick = state.tick }
        end
        state.item_counts[row] = count
    end
    state.coins = backpack:GetTotal(alch_data.COIN_OBJ)
end

---------------------------------------------------------------------------
-- Highlights
---------------------------------------------------------------------------

local function hideAll()
    state.arrow_target = nil
    state.collector_colour = nil
end

-- Decides what to highlight; drawing happens in onDraw.
local function updateHighlights(coord)
    state.arrow_target = targetCupboard()

    local leaving = state.coins > 0 and isNear(coord, alch_data.EXIT_TILE, alch_data.EXIT_WARN_RANGE)
    if state.coins >= alch_data.COIN_MAX then
        state.collector_colour = COLLECTOR_DANGER_COLOUR
    elseif state.coins >= alch_data.COIN_WARN or leaving then
        state.collector_colour = COLLECTOR_COLOUR
    else
        state.collector_colour = nil
    end
end

-- Draws the current highlights. ShapeList.Draw only works inside the Draw event.
local function onDraw()
    if state.arrow_target ~= nil then
---@diagnostic disable-next-line: missing-fields
        ShapeList.Draw {
            shapeData = ARROW_SHAPE,
            translation = tilePosition(alch_data.CUPBOARDS[state.arrow_target], ARROW_HEIGHT),
            colour = ARROW_COLOUR,
            asBillboard = true,
            ignoreDepth = true,
            lineWidth = 3
        }
    end
    if state.collector_colour ~= nil then
---@diagnostic disable-next-line: missing-fields
        ShapeList.Draw {
            shapeData = COLLECTOR_SHAPE,
            translation = tilePosition(alch_data.COIN_COLLECTOR_TILE, 10),
            colour = state.collector_colour,
            lineWidth = 4
        }
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local function enterRoom()
    state.in_room = true
    state.tick = 0
    state.values_signature = nil
    state.last_shuffle_tick = nil
    state.clicked_cupboard = nil
    state.last_gain = nil
    forgetLayout()
    countBackpack(false)
end

local function leaveRoom()
    state.in_room = false
    hideAll()
end

local function onServerTick()
    local coord = playerCoord()
    if not isInRoom(coord) then
        if state.in_room then leaveRoom() end
        return
    end
    if not state.in_room then enterRoom() end
    state.tick = state.tick + 1

    local values, signature = readValues()
    if values ~= nil then
        -- New values = a shuffle (the first reading after entering is just the starting point).
        if state.values_signature ~= nil and signature ~= state.values_signature then
            onShuffle(state.tick)
        end
        state.values_signature = signature
        state.best_row = bestRow(values)
    end

    -- A shuffle can repeat the same values, so also forget the layout on schedule.
    if state.last_shuffle_tick ~= nil and state.tick - state.last_shuffle_tick > alch_data.SHUFFLE_TICKS + 2 then
        onShuffle(state.last_shuffle_tick + alch_data.SHUFFLE_TICKS)
    end

    updateHighlights(coord)
end

local function onInventoryUpdated()
    if state.in_room then countBackpack(true) end
end

local function onMenuSelected(event)
    if not state.in_room then return end
    local loc = event.entry.locData
    if loc == nil or loc.config == nil then return end
    local index = loc.config.configName:match("^MAGICTRAINING_ALCHEM_CUPBOARD(%d)$")
    if index ~= nil then state.clicked_cupboard = tonumber(index) end
end

local function onLocAdded(event)
    if not state.in_room or event.config == nil then return end
    local index = event.config.configName:match("^MAGICTRAINING_ALCHEM_CUPBOARD(%d)_OPEN$")
    -- Other players open cupboards too; only use the one this player searched.
    if index == nil or tonumber(index) ~= state.clicked_cupboard then return end

    local gain = state.last_gain
    local row = 0
    if gain ~= nil and state.tick - gain.tick <= GAIN_MATCH_TICKS then row = gain.row end
    learn(tonumber(index), row)

    state.clicked_cupboard = nil
    state.last_gain = nil
end

-- Runs an event handler without letting an error stop the plugin.
local function safe(name, fn)
    return function(event)
        local ok, err = pcall(fn, event)
        if not ok then print("[MTA alch] " .. name .. " failed: " .. tostring(err)) end
    end
end

Event.ServerLogic.Subscribe("alchTick", safe("tick", onServerTick))
Event.Draw.Subscribe("alchDraw", safe("draw", onDraw))
Event.InventoryUpdated.Subscribe("alchInventory", safe("inventory", onInventoryUpdated))
Event.MiniMenuEntrySelected.Subscribe("alchSearch", safe("search", onMenuSelected))
Event.LocAdded.Subscribe("alchCupboard", safe("cupboard", onLocAdded))
