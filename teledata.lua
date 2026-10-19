local TILE_WIDTH = 512
local START = Vector3.new(0, 0, 0)
local NORTH = Vector3.new(0, 0, TILE_WIDTH)
local EAST = Vector3.new(TILE_WIDTH, 0, 0)
local SOUTH = Vector3.new(0, 0, -TILE_WIDTH)
local WEST = Vector3.new(-TILE_WIDTH, 0, 0)
local LINE_COLOUR = 0x00FFFFFF

local tele_data = {
    -- Level 0
    -- NW
    {
        bottom_left_tile = CoordGrid.new(0, 52, 151, 0, 32),
        grid_width = 4,
        grid_length = 4,
        start_pos = { x = 15, y = 9},
        level = 0,
        positions = {
            START,
            NORTH * 3,
            WEST * 4,
            NORTH * 2,
            EAST * 3,
            NORTH * 2,
            WEST * 2,
            SOUTH,
            WEST * 2,
            NORTH * 3,
            EAST * 9
        }
    },

    -- NE
    {
        bottom_left_tile = CoordGrid.new(0, 52, 151, 32, 40),
        grid_width = 4,
        grid_length = 3,
        start_pos = { x = 8, y = 8},
        level = 0,
        positions = {
            START,
            NORTH,
            EAST * 2,
            NORTH * 4,
            WEST * 4,
            NORTH * 2,
            EAST * 7,
            NORTH,
            WEST * 6
        }
    },

    -- SW
    {
        bottom_left_tile = CoordGrid.new(0, 52, 151, 0, 8),
        grid_width = 4,
        grid_length = 3,
        start_pos = { x = 15, y = 16},
        level = 0,
        positions = {
            START,
            EAST * 4,
            SOUTH * 5,
            WEST * 5,
            NORTH * 5,
            WEST * 4,
            NORTH * 4,
            EAST * 4
        }
    },

    -- SE
    {
        bottom_left_tile = CoordGrid.new(0, 52, 151, 32, 0),
        grid_width = 4,
        grid_length = 5,
        start_pos = { x = 13, y = 14},
        level = 0,
        positions = {
            START,
            NORTH * 3,
            EAST * 1,
            SOUTH * 3,
            EAST * 3,
            SOUTH * 2,
            WEST * 3,
            NORTH * 1,
            EAST * 4,
            NORTH * 5,
            WEST * 3
        }
    },

    -- -- Level 1
    -- NW
    {
        bottom_left_tile = CoordGrid.new(1, 52, 151, 0, 40),
        grid_width = 5,
        grid_length = 3,
        start_pos = { x = 22, y = 13},
        level = 1,
        positions = {
            START,
            SOUTH * 9,
            WEST,
            NORTH * 8,
            WEST * 2,
            SOUTH * 6,
            WEST * 4,
            SOUTH * 2,
            WEST * 2
        }
    },

    -- NE
    {
        bottom_left_tile = CoordGrid.new(1, 52, 151, 40, 40),
        grid_width = 3,
        grid_length = 3,
        start_pos = { x = 6, y = 9},
        level = 1,
        positions = {
            START,
            NORTH * 9,
            EAST * 3,
            SOUTH * 9,
            EAST * 3,
            NORTH * 9,
            EAST * 3,
            SOUTH * 9
        }
    },

    -- SW
    {
        bottom_left_tile = CoordGrid.new(1, 52, 151, 0, 0),
        grid_width = 5,
        grid_length = 4,
        start_pos = { x = 23, y = 20},
        level = 1,
        positions = {
            START,
            NORTH * 3,
            WEST * 2,
            SOUTH * 4,
            EAST * 4,
            NORTH * 5,
            WEST * 6,
            SOUTH * 8,
            EAST * 6
        }
    },

    -- SE
    {
        bottom_left_tile = CoordGrid.new(1, 52, 151, 40, 8),
        grid_width = 3,
        grid_length = 4,
        start_pos = { x = 8, y = 22},
        level = 1,
        positions = {
            START,
            SOUTH * 9,
            EAST * 4,
            NORTH * 6,
            WEST * 2,
            SOUTH * 3,
            EAST * 7,
            NORTH * 6
        }
    },
    
    -- -- Level 2
    -- North
    {
        bottom_left_tile = CoordGrid.new(2, 52, 151, 0, 32),
        grid_width = 6,
        grid_length = 4,
        start_pos = { x = 18, y = 22},
        level = 1,
        positions = {
            START,
            SOUTH * 5,
            WEST,
            SOUTH * 2,
            EAST,
            SOUTH * 2,
            EAST * 3,
            NORTH * 8,
            WEST * 4,
            NORTH
        }
    },
    
    -- South
    {
        bottom_left_tile = CoordGrid.new(2, 52, 151, 0, 0),
        grid_width = 6,
        grid_length = 4,
        start_pos = { x = 20, y = 10},
        level = 1,
        positions = {
            START,
            NORTH * 9,
            WEST * 3,
            SOUTH * 8,
            WEST * 3,
            NORTH * 8,
            WEST,
            SOUTH * 9,
            WEST * 2,
            NORTH * 9
        }
    }
}

local function genPositions(positions)
    local out_positions = {}

    local curr_position = START
    for _, position in ipairs(positions) do
        curr_position = curr_position + position
        table.insert(out_positions, curr_position)
    end

    return out_positions
end

local function genRGBA(positions)
    local rgba = {}
    for i=1, #positions do
        rgba[i] = LINE_COLOUR
    end
    return rgba
end

local function genLines(positions)
    local lines = {}
    local count = 0

    for i=1, #positions-1 do
        table.insert(lines, 0 + count)
        table.insert(lines, 1 + count)
        count = count + 1
    end
    return lines
end

local function genData()
    local out_data = {}
    
    for _, puzzle in ipairs(tele_data) do
        local puzzle_data = {
            coord_grid = puzzle.coord_grid,
            bottom_left_tile = puzzle.bottom_left_tile,
            grid_width = puzzle.grid_width,
            grid_length = puzzle.grid_length,
            start_pos = puzzle.start_pos,
            level = puzzle.level,
            positions = genPositions(puzzle.positions),
            rgba = genRGBA(puzzle.positions),
            lines = genLines(puzzle.positions)
        }

        table.insert(out_data, puzzle_data)
    end

    return out_data
end

local out_data = genData()

return out_data
