--[[
    RouteVerifier
    Authors:
        Museus (Discord: Museus#7777)

    Allows you to populate a list of seeds, and notifies you when you are off route.

    To set your route, populate SeedList with a comma separated list of seeds.
    e.g.
    SeedList = {
        000000001,
        000000002,
        ...
    }
]]
ModUtil.RegisterMod("RouteVerifier")
local config = {
    ShowBelowRngDisplay = true,
    DisplayFormat = {
        x_pos = UIData.CurrentRunDepth.X, -- Ignored if ShowBelowRngDisplay is true and RngDisplay is installed
        y_pos = UIData.CurrentRunDepth.Y + 25, -- Ignored if ShowBelowRngDisplay is true and RngDisplay is installed
        color = Color.UpgradeGreen
    },
    TrackRun = true,
    SeedList = {
        436159,
        1986760314,
        406074603,
        160448433,
        1315722240,
        -86510397,
        -1541732175,
        -244316655,
        -2047268340,
        -382364750,
        -392624732,
        -1387678312,
        -1645995698,
        1491740693,
        -1173845701,
        -1569982661,
        -200551125,
        1823074467,
        -1554287023,
        890544923,
        -620189253,
        788488425,
        -1298381135,
        2056809742,
        -224681519,
        1418351507,
        680038026,
        716023311,
        -448519370,
        1053625744,
        -1335624333,
        207026649,
        -144540804,
        -940794411,
        -1866532976,
        -769303042,
        -1048772740,
        2012142207,
        869109455,
        -1494782611,
        -1257436870,
        279728086,
        -798446530,
        -1234109731,
        188502245,
        -2110558149,
        -1107125730,
        1133800054,
    },
    OutputToDebug = false
}
config.OutputToDebug = config.OutputToDebug and DebugBoxMod
RouteVerifier.config = config

--[[ DISPLAY FUNCTIONS ]]
local function DisplayOnRoute()
    if not RouteVerifier.config.TrackRun then
        return -- Don't display if TrackRun is false
    end

    local format = ShallowCopyTable(RouteVerifier.config.DisplayFormat)
    -- Set position to below RngDisplay if specified and installed
    if RouteVerifier.config.ShowBelowRngDisplay and RngDisplay then
        -- Set starting position
        format.x_pos = RngDisplay.config.DisplayFormat.x_pos
        format.y_pos = RngDisplay.config.DisplayFormat.y_pos

        -- Move down if Seed is shown
        if RngDisplay.config.ShowSeed then
            format.y_pos = format.y_pos + 25
        end
        -- Move down if Uses is shown
        if RngDisplay.config.ShowUses then
            format.y_pos = format.y_pos + 25
        end
    end

    local chamber_number = 1
    -- Check if sitting in Courtyard
    if CurrentRun.Hero and not CurrentRun.Hero.IsDead then
        chamber_number = GetRunDepth(CurrentRun)
    end

    local message = "On Route!"
    -- If fell off the route, update message and color
    if RouteVerifier.config.SeedList[chamber_number] ~= RngInterface.CurrentSeed then
        message = "Off Route!"
        format.color = Color.PenaltyRed
    end

    PrintUtil.createOverlayLine(
        "RouteVerifier",
        message,
        format
    )
end

ModUtil.LoadOnce(function()
    -- Make sure RngInterface exists. If it doesn't, throw an error and disable mod
    if not RngInterface then
        local error = "RngInterface does not exist! Please install it to use RouteVerifier."
        if config.OutputToDebug then
            DebugBoxMod.writeToDebugBox(error)
        else
            ModUtil.Hades.PrintOverhead(error)
        end

        config.TrackRun = false
    else
        -- Tell RngInterface to call Display Function when seed changes
        RngInterface.AddUseHook(DisplayOnRoute)
    end
end)
