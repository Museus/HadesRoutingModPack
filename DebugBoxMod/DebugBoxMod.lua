--[[
    DebugBoxMod
    Authors:
      Museus (Discord: Museus#7777)
      Ellomenop (Discord: ellomenop#2254)

    Adds a Debug Text Overlay to Hades, allowing mods to print data to the screen
    For actual debugging, it is better to use the official DebugOverlay provided
    by Supergiant, but this can be used for players not running in debug-mode.
]]
ModUtil.RegisterMod("DebugBoxMod")

local config = {
    -- If ShowDebug is false, no output will be shown
    ShowDebug = true,
    -- If ShowDetailedDebug is false, stack prints will not be shown
    ShowDetailedDebug = true,
    -- Maximum number of lines displayed in Debug Box
    LinesToShow = 25,
    -- Default font size
    FontSize = 12,
    -- Default space between lines (0 = lines are touching)
    LineSpacing = 0,
    -- Position of DebugBox (Defaults are below Chamber Number)
    BoxXPosition = 1740, -- Default: 1740
    BoxYPosition = 105, -- Default: 105

}
DebugBoxMod.config = config

--[[ Lua Queue Implementation + max size & clear function ]]

DebugBoxMod.Queue  = {}
function DebugBoxMod.Queue.new ( max_size )
    return {
        first = 0,
        last = -1,
        max = max_size
    }
end

function DebugBoxMod.Queue.addEntry ( list, value )
    local last = list.last + 1
    list.last = last
    list[last] = value

    if (list.last - list.first) > list.max then
        DebugBoxMod.Queue.deleteOldestEntry(list)
    end
end

function DebugBoxMod.Queue.deleteOldestEntry (list)
    local first = list.first
    if first > list.last then
        error("DebugBoxMod: Trying to delete from empty log")
    end

    local value = list[first]
    list[first] = nil -- to allow garbage collection
    list.first = first + 1
    return value
end

function DebugBoxMod.Queue.containsEntries ( list )
    return not (list.first > list.last)
end

function DebugBoxMod.Queue.clearList ( list )
    while DebugBoxMod.Queue.containsEntries(list) do
        DebugBoxMod.Queue.deleteOldestEntry(list)
    end
end

-- Define fixed size lists to hold the last X debug events
DebugBoxMod.DebugLineList = DebugBoxMod.Queue.new ( config.LinesToShow )

--- Prints current DebugBox queue to the screen
function DebugBoxMod.displayDebugBox()
    for i = DebugBoxMod.DebugLineList.first, DebugBoxMod.DebugLineList.last do
        local debug_entry = DebugBoxMod.DebugLineList[i]
        local line_age = DebugBoxMod.DebugLineList.last - i
        local line_height = config.FontSize + config.LineSpacing
        local text_config_table = {
            x_pos = config.BoxXPosition,
            y_pos = config.BoxYPosition + line_height * line_age,
            font_size = DebugBoxMod.config.FontSize
        }
        if debug_entry then
            text_config_table.color = debug_entry.text_color or DebugBoxMod.getLineColor(line_age)
            
            PrintUtil.createOverlayLine(
                "FloatDebugBoxLine" .. line_age,
                debug_entry.text,
                text_config_table
            )
        end
    end
end

--- Empty out the Debug Box
-- This function will replace all lines in the Debug Box with blank lines
function DebugBoxMod.clearDebugBox()
    for i = DebugBoxMod.DebugLineList.first, DebugBoxMod.DebugLineList.last do
        local line_age = DebugBoxMod.DebugLineList.last - i
        PrintUtil.destroyScreenAnchor("FloatDebugBoxLine" .. line_age)
    end
    DebugBoxMod.Queue.clearList(DebugBoxMod.DebugLineList)
end

--- Applies gradient to font color based on age of line
-- Darkest is 155, Brightest is 255
-- @param line_age Age of line to gradient
function DebugBoxMod.getLineColor( line_age )
    local grad_per_line = 105 / DebugBoxMod.config.LinesToShow
    local end_color = 255 - (grad_per_line * line_age)

    return {end_color, end_color, end_color, 255}
end

--- Toggle Debug Box on and off
-- This function is designed to be used for a configuration screen
function DebugBoxMod.toggleDebug()
    DebugBoxMod.config.ShowDebug = not DebugBoxMod.config.ShowDebug

    if not DebugBoxMod.config.ShowDebug then
        DebugBoxMod.clearDebugBox()
    end
end

--- Write text to the Debug Box
-- This function will add a line to the list, and display the updated list
-- via the Debug Box.
-- @param text The text to display
-- @param kwargs Table optionally containing:
    -- text_color The color to display text, can be Color or rgba table
function DebugBoxMod.writeToDebugBox( text, kwargs )
    if not DebugBoxMod.config.ShowDebug then
        return nil, "DebugBoxMod: All logging is turned off"
    end

    local debug_entry = {text = text}
    if kwargs ~= nil then
        -- Allow user to specify Color, default to nil (DebugBox will populate)
        debug_entry.text_color = kwargs.text_color or nil
    end

    DebugBoxMod.Queue.addEntry( DebugBoxMod.DebugLineList, debug_entry )
    DebugBoxMod.displayDebugBox()
end

--- Print the stack trace with a provided string suffix to Debug Box
-- Calls writeToDebugBox and swallows any exceptions
-- @param suffix The suffix text to display
-- @param kwargs Optional parameters for writeToDebugBox (text_color)
function DebugBoxMod.printStackTraceToDebugBox( suffix, kwargs )
    if not DebugBoxMod.config.ShowDetailedDebug then
        return nil, "DebugBoxMod: Detailed logging is turned off"
    end

    local caller = PrintUtil.traceback()
    DebugBoxMod.writeToDebugBox(
        string.format("%s %s", caller or "", suffix),
        kwargs
    )
end

--- Prints values in a table to Debug Box with a provided prefix
-- Can crash the game if called in certain contexts / with certain tables
-- Prints 5 values per line, until table is exhausted
-- @param prefix Text to prefix table lines with
-- @param table Table to iterate over
-- @param property Property to print from values
-- @param kwargs Optional parameters for writeToDebugBox (text_color)
function DebugBoxMod.printTableContentsToDebugBox( prefix, table, property, kwargs )
    -- Normally would let writeToDebugBox handle whether logging is turned on
    -- but iterating is a bit expensive to just throw away, so check ShowDebug first
    if not DebugBoxMod.config.ShowDebug then
        return nil, "DebugBoxMod: All logging is turned off"
    end

    if table == nil then
        DebugBoxMod.writeToDebugBox(
            string.format("%s: table is nil", prefix),
            {text_color = Color.Red}
        )
        return
    end

    local contents = prefix
    local count = 0

    for _, value in pairs( table ) do
        if value ~= nil then
            contents = contents .. ModUtil.ToString(value[property])
            count = count + 1
            if count > 5 then
                DebugBoxMod.writeToDebugBox(contents, kwargs)
                count = 0
                contents = prefix
            end
        else
            DebugBoxMod.writeToDebugBox(contents, kwargs)
        end
    end
end
