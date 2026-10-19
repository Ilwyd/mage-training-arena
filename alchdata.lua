-- Static data for the Alchemists' Playground.
-- All values were found in the plugin beta world with the mta-devlog helper.

local alch_data = {}

-- The room is on level 2 of mapsquare 52,150 (not an instance).
alch_data.ROOM = { level = 2, map_square_x = 52, map_square_z = 150 }

-- Shapes are placed at the ground height of the lowest floor, so add this much per level
-- (same value tele.lua uses as BASE_FLOOR_FINE_UNITS).
alch_data.FLOOR_HEIGHT = 1600

-- The five items, in the order of the values window rows.
-- This is also their order around the cupboards (see SEQUENCE below).
--   obj          : object id of the item
--   value_static : component in the values window that shows the item's coin value
alch_data.ITEMS = {
    { name = "Leather boots",      obj = 6893, value_static = 10 },
    { name = "Adamant kiteshield", obj = 6894, value_static = 11 },
    { name = "Adamant helm",       obj = 6895, value_static = 12 },
    { name = "Emerald",            obj = 6896, value_static = 13 },
    { name = "Rune longsword",     obj = 6897, value_static = 14 },
}

-- What the cupboards hold, going up through the cupboard indices from wherever the boots are.
-- Numbers are rows in ITEMS, 0 = empty. The whole sequence shifts by a random amount at
-- every shuffle, so finding one item tells us where all the others are.
alch_data.SEQUENCE = { 1, 2, 3, 4, 5, 0, 0, 0 }

-- The values window (it is click-through, but can still be read).
alch_data.INTERFACE_ID = 194

-- The item worth this many coins is the one to alch.
alch_data.BEST_VALUE = 30

-- Cupboard index -> tile. Indices run up the west wall, then down the east wall.
alch_data.CUPBOARDS = {
    [0] = CoordGrid.new(2, 52, 150, 32, 32),
    [1] = CoordGrid.new(2, 52, 150, 32, 36),
    [2] = CoordGrid.new(2, 52, 150, 32, 40),
    [3] = CoordGrid.new(2, 52, 150, 32, 44),
    [4] = CoordGrid.new(2, 52, 150, 41, 44),
    [5] = CoordGrid.new(2, 52, 150, 41, 40),
    [6] = CoordGrid.new(2, 52, 150, 41, 36),
    [7] = CoordGrid.new(2, 52, 150, 41, 32),
}

alch_data.COIN_COLLECTOR_TILE = CoordGrid.new(2, 52, 150, 36, 50)
alch_data.EXIT_TILE = CoordGrid.new(2, 52, 150, 34, 23)

-- Arena coins are their own item, separate from normal coins.
alch_data.COIN_OBJ = 8890
alch_data.COIN_WARN = 11000   -- the game starts warning here
alch_data.COIN_MAX = 12000    -- depositing more than this removes you and wipes the coins

-- Standing this close to the exit with coins counts as "about to leave without depositing".
alch_data.EXIT_WARN_RANGE = 6

-- Items and values shuffle every 42 seconds = 70 server ticks of 0.6 seconds.
alch_data.SHUFFLE_TICKS = 70

return alch_data
