--[[
  RngDisplay
  Authors:
    Museus (Discord: Museus#7777)
    Ellomenop (Discord: ellomenop#2254)
    Kossetsu (Discord: Kossetsu#7660)

  Adds an RNG Overlay to Hades, to display Seed and RNG Uses
]]
ModUtil.RegisterMod("RngDisplay")

local config = {
    ShowSeed = true, -- If true, Seed will be displayed in the top right
    ShowUses = true, -- If true, RNG Increments will be displayed in the top right
    -- (If both ShowSeed and ShowUses are true, both will appear stacked vertically)
    DisplayFormat = {
        x_pos = UIData.CurrentRunDepth.X,
        y_pos = UIData.CurrentRunDepth.Y + 25,
        color = UIData.CurrentRunDepth.TextFormat.Color
    },
    OutputToDebug = false, -- If true, each roll will be printed to the DebugBoxMod
}
config.OutputToDebug = config.OutputToDebug and DebugBoxMod
RngDisplay.config = config

--[[ DISPLAY FUNCTIONS ]]
local function DisplayCurrentUses()
    if not RngDisplay.config.ShowUses then
        return -- Don't display if ShowUses is false
    end

    local format = ShallowCopyTable(RngDisplay.config.DisplayFormat)
    if RngDisplay.config.ShowSeed then -- Move down if Seed is also shown
        format.y_pos = format.y_pos + 25
    end

    PrintUtil.createOverlayLine(
        "CurrentUses",
        string.format("RNG Uses: %s", RngInterface.CurrentUses),
        format
    )
end

-- Sets the seed display to the current seed
local function DisplayCurrentSeed()
    if not RngDisplay.config.ShowSeed then
        return -- Don't display if ShowSeed is false
    end

    PrintUtil.createOverlayLine(
        "CurrentSeed",
        string.format("RNG Seed: %s", RngInterface.CurrentSeed),
        RngDisplay.config.DisplayFormat
    )
end

ModUtil.LoadOnce(function()
    -- Make sure RngInterface exists. If it doesn't, throw an error and disable mod
    if not RngInterface then
        local error = "RngInterface does not exist! Please install it to use RngDisplay."
        if config.OutputToDebug then
            DebugBoxMod.writeToDebugBox(error)
        else
            ModUtil.Hades.PrintOverhead(error)
        end

        RngDisplay.config.ShowSeed = false
        RngDisplay.config.ShowUses = false
    else
        -- Tell RngInterface to call these functions when necessary
        RngInterface.AddUseHook(DisplayCurrentUses)
        RngInterface.AddSeedHook(DisplayCurrentSeed)
    end
end)
