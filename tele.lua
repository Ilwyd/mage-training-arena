-- Telekinetic Arena
-- Draws a line on the floor indicating where the statue needs to be pulled

local tele_data = require("teledata")

local BASE_FLOOR_FINE_UNITS = 1600

-- Checks to see if the player is in the instance of the given puzzle
local function isInPuzzleArea(puzzle)
    local area = Rect.new(
        puzzle.bottom_left_tile.mapSquareX * 64 + puzzle.bottom_left_tile.localX,
        puzzle.bottom_left_tile.mapSquareZ * 64 + puzzle.bottom_left_tile.localZ,
        puzzle.grid_width * 8,
        puzzle.grid_length * 8
    )

    local source_coord_grid = World.GetRegionSourceForCoordGrid(Player.GetEntity().coordGrid)

    if source_coord_grid == nil then
        return false
    end

    if puzzle.bottom_left_tile.level ~= source_coord_grid.level then
        return false
    end

    return area:Contains(
        source_coord_grid.mapSquareX * 64 + source_coord_grid.localX + 1,
        source_coord_grid.mapSquareZ * 64 + source_coord_grid.localZ + 1
    )
end

Event.Draw.Subscribe("teleLines", function(drawEvent)
    if not World.IsRegion() then
        return
    end
    
    -- Finding what puzzle instance the player is in
    local exit = true
    local curr_puzzle = nil
    for _, puzzle in ipairs(tele_data) do
        if isInPuzzleArea(puzzle) then
            exit = false
            curr_puzzle = puzzle
        end
    end

    -- If the puzzle wasn't found, return
    if exit or curr_puzzle == nil then
        return
    end

    -- Getting all of the details for the current puzzle from tele_data
    local level = curr_puzzle.level
    local start_pos = curr_puzzle.start_pos
    local positions = curr_puzzle.positions
    local rgba = curr_puzzle.rgba
    local lines = curr_puzzle.lines

    -- Getting the player's coordGrid and offsetting it with the start positions from tele_data
    local player_coord_grid = Player.GetEntity().coordGrid
    local coord_grid = CoordGrid.new(
        player_coord_grid.level,
        player_coord_grid.mapSquareX,
        player_coord_grid.mapSquareZ,
        start_pos.x,
        start_pos.y
    )

    -- Creating the translation for ShapeList.Draw. Shifting it up if needed
    local translation = coord_grid:ToCoordFine(true).position + Vector3.new(0, BASE_FLOOR_FINE_UNITS * level, 0)

---@diagnostic disable-next-line: missing-fields
    ShapeList.Draw {
        shapePositions = positions,
        shapeRGBA = rgba,
        shapeTris = {},
        shapeLines = lines,
        translation = translation,
        ignoreDepth = true,
        lineWidth = 3
    }

end)

