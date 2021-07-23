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
      -- Beo Route
      588384,
      1123323008,
      -1312722704,
      444389298,
      1501741483,
      984170559,
      -1496182771,
      -651885696,
      -1539109952,
      1323767801,
      -22236989,
      663998103,
      -773466173,
      -1272405814,
      1976652988,
      1620444090,
      -1411792967,
      -876083783,
      1767260490,
      1312255047,
      1422679429,
      -859577256,
      446090851,
      -818917367,
      -826183828,
      780225667,
      -1040602957,
      -628103582,
      1195302451,
      1961970774,
      -984109,
      427567441,
      -1959782252,
      -1014273309,
      695773260,
      -1729341710,
      1483416299,
      -817935511,
      855611882,
      -1868021254,
      1241724750,
      11325215,
      -1092406353,
      1067572172,
      -1804376631,
      -2112617507,
      -1045069623,
      -1227795609
    },
    OutputToDebug = false
}
config.OutputToDebug = config.OutputToDebug and DebugBoxMod
RouteVerifier.config = config

--- Given previous seed, current seed, and target seed, calculate offset
--  between current seed and target seed.
--  Original Credit: paradigmsort#1061
local function GetSeedOffset( previousSeed, currentSeed, targetSeed )
  -- save RngInterface state
  local rngState = {
    Seed = RngInterface.CurrentSeed,
    Uses = RngInterface.CurrentUses,
  }
  RngInterface.DisableHooks()

  -- set seed to previous
  NextSeeds[1] = previousSeed
  RandomSynchronize()

  local currentSeedOffset = nil
  local targetSeedOffset = nil
  for i=1,200 do
    local s = RandomInt(-2147483647, 2147483646)
    if s == currentSeed then
      currentSeedOffset = i
    end
    if s == targetSeed then
      targetSeedOffset = i
    end
    if currentSeedOffset and targetSeedOffset then
      break
    end
  end

  -- restore
  RngInterface.EnableHooks()
  NextSeeds[1] = rngState.Seed
  RandomSynchronize( rngState.Uses )

  if currentSeedOffset and targetSeedOffset then
    return currentSeedOffset - targetSeedOffset
  else
    return nil
  end
end

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
        if chamber_number > 1 then
          local offset = GetSeedOffset(
            RouteVerifier.config.SeedList[chamber_number - 1],
            RngInterface.CurrentSeed,
            RouteVerifier.config.SeedList[chamber_number],
          )
          if offset then
            message = string.format("%s %+d", message, offset)
          end
        end
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
        RngInterface.AddSeedHook(DisplayOnRoute)
    end
end)
