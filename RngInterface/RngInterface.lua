--[[
  RngInterface
  Authors:
    Museus (Discord: Museus#7777)
    Ellomenop (Discord: ellomenop#2254)

  Adds an interface to allow other mods to track Seed and RNG Increments.
]]
ModUtil.RegisterMod("RngInterface")

local config = {
    OutputToDebug = true, -- If true, each roll will be printed to the DebugBoxMod
}
config.OutputToDebug = config.OutputToDebug and DebugBoxMod
RngInterface.config = config
RngInterface.UseHooks = {}
RngInterface.SeedHooks = {}

--- Increments the global RNG counter or resets it to a specfic value
function RngInterface.UpdateCurrentUses( resetToOffset )
    if resetToOffset ~= nil then
        RngInterface.CurrentUses = resetToOffset
    else
        RngInterface.CurrentUses = (RngInterface.CurrentUses or 0) + 1
    end

    for idx, func in ipairs(RngInterface.UseHooks) do
        func()
    end
end


function RngInterface.UpdateCurrentSeed( seed )
    RngInterface.CurrentSeed = seed
    for idx, func in ipairs(RngInterface.SeedHooks) do
        func()
    end
end


function RngInterface.AddUseHook( target_function )
    table.insert(RngInterface.UseHooks, target_function)
end

function RngInterface.AddSeedHook( target_function )
    table.insert(RngInterface.SeedHooks, target_function)
end

--[[ Hooks for tracking Rng ]]

--- Called by RandomSynchronize to set up the rng and seed.
-- Wrap this so we can also see the latest seed when RNG is reset.
-- Scripts/Random.lua : 54
ModUtil.WrapBaseFunction("RandomInit", function ( baseFunc, rngId )
    local result = baseFunc( rngId )
    RngInterface.UpdateCurrentSeed(result.seed)

    if config.OutputToDebug then
        DebugBoxMod.writeToDebugBox(
            string.format("-- SEED: %s --", ModUtil.ToString(RngInterface.CurrentSeed))
        )
    end

    return result
end, RngInterface)

--- Syncs the RNG to a particular offset.
-- Usually called with nil {rngId} and uses the global rng.
-- Offset will be treated as 0 if nil
-- Scripts/Random.lua : 85
ModUtil.WrapBaseFunction("RandomSynchronize", function ( baseFunc, offset, rngId )
    RngInterface.UpdateCurrentUses(0)

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format(
                "-- RESET RNG <%s> TO OFFSET <%s> --",
                ModUtil.ToString(rngId),
                ModUtil.ToString(offset)
            )
        )
    end

    baseFunc( offset, rngId )
end, RngInterface)

--- Roll a random integer between {low} and {high}
-- Scripts/Random.lua : 122
ModUtil.WrapBaseFunction("RandomInt", function (baseFunc, low, high, rng)
    local result = baseFunc(low, high, rng)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomInt: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngInterface)

--- Roll a random float from {low} to {high}
-- Scripts/Random.lua : 130
ModUtil.WrapBaseFunction("RandomFloat", function (baseFunc, low, high, rng)
    local result = baseFunc(low, high, rng)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomFloat: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngInterface)

--- Roll a random number between 1 and {number}
-- Scripts/Random.lua : 138
ModUtil.WrapBaseFunction("RandomNumber", function (baseFunc, number, rng)
    local result = baseFunc(number, rng)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomNumber: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngInterface)

--- Roll a random float between 0 and 1 and return if its <= {chance}
-- Scripts/Random.lua : 143
ModUtil.BaseOverride("RandomChance", function ( chance, rng )
    local rngObj = rng or GetGlobalRng()
    local rand = rngObj:Random()
    local result = rand <= chance

    RngInterface.UpdateCurrentUses()
    local caller = PrintUtil.traceback()
    if config.OutputToDebug then
        DebugBoxMod.writeToDebugBox(
            string.format("%s called RandomChance: %s (%d / %d)", caller or "Unknown", ModUtil.ToString(result), rand, chance)
        )
    end

    return result
end, RngInterface)

--- Roll a random float between 0 and 1 and return true if > 0.5
-- Scripts/Random.lua : 155
ModUtil.WrapBaseFunction("CoinFlip", function (baseFunc, rng)
    local result = baseFunc(rng)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("Coinflip: %s", ModUtil.ToString(result))
        )
    end

    return result
end, RngInterface)

--- Roll a value in a normal distribution with provided mean/stddev
-- Scripts/Random.lua : 162
ModUtil.WrapBaseFunction("RandomNormal", function (baseFunc, mean, stddev, rng)
    local result = baseFunc(mean, stddev, rng)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomNormal: %s", ModUtil.ToString(result))
        )
    end

    return result
end, RngInterface)

--- Select a random value from {tableArg}
-- Calls RNG directly
-- Scripts/UtilityScripts.lua : 1389
ModUtil.BaseOverride("GetRandomValue", function ( tableArg, rng )
    if tableArg == nil then
        return
    end

    rng = rng or GetGlobalRng()

    local numItems = TableLength( tableArg )
    local randomIndex = rng:Random( numItems )
    RngInterface.UpdateCurrentUses()

    -- CollapseTable implicitly makes a shallow copy
    local sortedTable = CollapseTableOrdered( tableArg )
    local result = sortedTable[randomIndex]

    if config.OutputToDebug then
        local caller = PrintUtil.traceback()
        DebugBoxMod.writeToDebugBox(
            string.format("%s called GetRandomValue: %s (%d / %d)", caller or "Unknown", ModUtil.ToString(result), randomIndex, numItems)
        )
    end

    return result
end, RngInterface)

--- Select a random key from {tableArg}
-- Calls RNG directly
-- Scripts/UtilityScripts.lua : 1406
ModUtil.BaseOverride("GetRandomKey", function ( tableArg, rng )
    if tableArg == nil then
        return
    end

    rng = rng or GetGlobalRng()

    local numItems = TableLength( tableArg )
    local randomIndex = rng:Random( numItems )
    local sortedKeys = __genOrderedIndex(tableArg)
    RngInterface.UpdateCurrentUses()

    if config.OutputToDebug then
        local caller = PrintUtil.traceback()
        DebugBoxMod.writeToDebugBox(
            string.format("%s called GetRandomKey: %s (%d / %d)", caller or "Unknown", ModUtil.ToString(sortedTable[randomIndex]), randomIndex, numItems)
        )
    end

    return sortedKeys[randomIndex]
end, RngInterface)

--- Pop a random value from {tableArg}
-- Calls RNG directly
-- Scripts/UtilityScripts.lua : 1445
ModUtil.BaseOverride("RemoveRandomValue", function ( tableArg, rng )
    local numItems = TableLength( tableArg )

    if tableArg == nil or numItems <= 0 then
        return
    end

    rng = rng or GetGlobalRng()
    local retVal = nil
    local randomIndex = 1
    tableArg = OverwriteAndCollapseTable( tableArg )

    if numItems > 1 then
        randomIndex = rng:Random( numItems )
        RngInterface.UpdateCurrentUses()
    else
        retVal = tableArg[1]
        tableArg[1] = nil
        return retVal
    end

    table.sort(tableArg, cmp_multitype)

    retVal = tableArg[randomIndex]

    if config.OutputToDebug then
        local caller = PrintUtil.traceback()
        DebugBoxMod.writeToDebugBox(
            string.format("%s called RemoveRandomValue: %s (%d / %d)", caller or "Unknown",  retVal, randomIndex, numItems)
        )
    end

    tableArg[randomIndex] = nil
    return retVal
end, RngInterface)