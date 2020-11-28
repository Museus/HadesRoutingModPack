--[[
  RngDisplayMod
  Authors:
    Museus (Discord: Museus#7777)
    Ellomenop (Discord: ellomenop#2254)
    Kossetsu (Discord: Kossetsu#7660)

  Adds an RNG Overlay to Hades, to display Seed and RNG Uses
  Optional DebugBoxMod support
]]
ModUtil.RegisterMod("RngDisplayMod")

local config = {
    ShowSeed = true, -- If true, Seed will be displayed in the top right
    ShowUses = true, -- If true, RNG Increments will be displayed in the top right
    -- (If both ShowSeed and ShowUses are true, both will appear stacked vertically)
    OutputToDebug = false, -- If true, each roll will be printed to the DebugBoxMod
}
config.OutputToDebug = config.OutputToDebug and DebugBoxMod
RngDisplayMod.config = config

--[[ DISPLAY FUNCTIONS ]]

--- Increments the global RNG counter or resets it to a specfic value
function updateCurrentUses( resetToOffset )
    if resetToOffset ~= nil then
        RngDisplayMod.CurrentUses = resetToOffset
    else
        RngDisplayMod.CurrentUses = (RngDisplayMod.CurrentUses or 0) + 1
    end

    displayCurrentUses()
end

function displayCurrentUses()
    if not config.ShowUses then
        return -- Don't display if ShowUses is false
    end

    local text_config_table = {
        x_pos = UIData.CurrentRunDepth.X,
        y_pos = UIData.CurrentRunDepth.Y + 25,
        color = Color.White
    }

    if config.ShowSeed then -- Move down if Seed is also shown
        text_config_table.y_pos = UIData.CurrentRunDepth.Y + 50
    end

    PrintUtil.createOverlayLine(
        "CurrentUses",
        string.format("RNG Uses: %s", RngDisplayMod.CurrentUses),
        text_config_table
    )
end

-- Sets the seed display to the current seed
function displayCurrentSeed()
    if not config.ShowSeed then
        return -- Don't display if ShowSeed is false
    end

    local text_config_table = {
        x_pos = UIData.CurrentRunDepth.X,
        y_pos = UIData.CurrentRunDepth.Y + 25,
        color = Color.White
    }

    PrintUtil.createOverlayLine(
        "CurrentSeed",
        string.format("RNG Seed: %s", RngDisplayMod.CurrentSeed),
        text_config_table
    )
end

--[[ Hooks for tracking Rng ]]

--- Called by RandomSynchronize to set up the rng and seed.
-- Wrap this so we can also see the latest seed when RNG is reset.
-- Scripts/Random.lua : 54
ModUtil.WrapBaseFunction("RandomInit", function ( baseFunc, rngId )
    local result = baseFunc( rngId )
    RngDisplayMod.CurrentSeed = result.seed
    displayCurrentSeed()

    if config.OutputToDebug then
        DebugBoxMod.writeToDebugBox(
            string.format("-- SEED: %s --", ModUtil.ToString(RngDisplayMod.CurrentSeed))
        )
    end


    return result
end, RngDisplayMod)

--- Syncs the RNG to a particular offset.
-- Usually called with nil {rngId} and uses the global rng.
-- Offset will be treated as 0 if nil
-- Scripts/Random.lua : 85
ModUtil.WrapBaseFunction("RandomSynchronize", function ( baseFunc, offset, rngId )
    updateCurrentUses(0)

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
end, RngDisplayMod)

--- Roll a random integer between {low} and {high}
-- Scripts/Random.lua : 122
ModUtil.WrapBaseFunction("RandomInt", function (baseFunc, low, high, rng)
    local result = baseFunc(low, high, rng)
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomInt: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngDisplayMod)

--- Roll a random float from {low} to {high}
-- Scripts/Random.lua : 130
ModUtil.WrapBaseFunction("RandomFloat", function (baseFunc, low, high, rng)
    local result = baseFunc(low, high, rng)
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomFloat: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngDisplayMod)

--- Roll a random number between 1 and {number}
-- Scripts/Random.lua : 138
ModUtil.WrapBaseFunction("RandomNumber", function (baseFunc, number, rng)
    local result = baseFunc(number, rng)
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomNumber: %d", ModUtil.ToString(result))
        )
    end

    return result
end, RngDisplayMod)

--- Roll a random float between 0 and 1 and return if its <= {chance}
-- Scripts/Random.lua : 143
ModUtil.BaseOverride("RandomChance", function ( chance, rng )
    local rngObj = rng or GetGlobalRng()
    local rand = rngObj:Random()
    local result = rand <= chance

    updateCurrentUses()
    local caller = PrintUtil.traceback()
    if config.OutputToDebug then
        if not string.find(caller, "Breakable") or not string.find(caller, "IsVoiceLineEligible") then
            DebugBoxMod.writeToDebugBox(
                string.format("%s RandomChance: %s (%d / %d)", caller or "", ModUtil.ToString(result), rand, chance)
            )
        end
    end

    return result
end, RngDisplayMod)

--- Roll a random float between 0 and 1 and return true if > 0.5
-- Scripts/Random.lua : 155
ModUtil.WrapBaseFunction("CoinFlip", function (baseFunc, rng)
    local result = baseFunc(rng)
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("Coinflip: %s", ModUtil.ToString(result))
        )
    end

    return result
end, RngDisplayMod)

--- Roll a value in a normal distribution with provided mean/stddev
-- Scripts/Random.lua : 162
ModUtil.WrapBaseFunction("RandomNormal", function (baseFunc, mean, stddev, rng)
    local result = baseFunc(mean, stddev, rng)
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.printStackTraceToDebugBox(
            string.format("RandomNormal: %s", ModUtil.ToString(result))
        )
    end

    return result
end, RngDisplayMod)

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
    updateCurrentUses()

    -- CollapseTable implicitly makes a shallow copy
    local sortedTable = CollapseTableOrdered( tableArg )
    if not config.OutputToDebug then
        return sortedTable[randomIndex]
    end

    local caller = PrintUtil.traceback()

    if not pcall(function()
        if not string.find(caller, "PickEnemyAI") and not string.find(caller, "SelectWeapon") and not string.find(caller, "GetNextSpawn") and not string.find(caller, "CombatPresentation") then
            if sortedTable[randomIndex].Name ~= nil then
                DebugBoxMod.writeToDebugBox(
                    string.format("Rolled Named Result: %s (%d / %d)", sortedTable[randomIndex].Name, randomIndex, numItems)
                )
            else
                if not string.find(sortedTable[randomIndex], "Breakable") and not string.find(sortedTable[randomIndex], "Rubble") then
                    DebugBoxMod.writeToDebugBox(
                        string.format("Rolled %s (%d / %d)", ModUtil.ToString(sortedTable[randomIndex]), randomIndex, numItems)
                    )
                end
            end
        end
    end) then
        pcall(function()
            if string.find(ModUtil.ToString(sortedTable[randomIndex]), "Cue") then
                DebugBoxMod.writeToDebugBox(
                    string.format("%s Rolled Voice Cue (%d / %d)", caller, randomIndex, numItems)
                )
            elseif string.find(caller, "GhostScripts") then
                DebugBoxMod.writeToDebugBox(
                    string.format("%s Shade Patrol (%d / %d)", randomIndex, numItems)
                )
            elseif string.find(caller, "GetPriorityTraits") then
                DebugBoxMod.writeToDebugBox(
                    string.format("%s Priority Traits %s (%d / %d)", ModUtil.ToString(sortedTable[randomIndex].ItemName), randomIndex, numItems)
                )
            elseif string.find(caller, "SetTraitsOnLoot") or string.find(caller, "ElloPredictLootData") or string.find(caller, "PredictGodBoonOptions") then
                if sortedTable[randomIndex] ~= nil then
                    DebugBoxMod.writeToDebugBox(
                        string.format("Traits on Loot: %s (%d / %d) ", ModUtil.ToString(sortedTable[randomIndex].ItemName), randomIndex, numItems)
                    )
                else
                    DebugBoxMod.writeToDebugBox(
                        string.format("Traits on Loot nil: %s (%d / %d)", ModUtil.ToString(sortedTable[randomIndex]), randomIndex, numItems)
                    )
                end
            elseif string.find(caller, "GetRandomEligibleTextLines") then
                DebugBoxMod.writeToDebugBox(
                    string.format("Random Eligible Text Lines (%d / %d)", randomIndex, numItems)
                )
            elseif string.find(caller, "HandleSecretSpawns") then
                DebugBoxMod.writeToDebugBox(
                    string.format("%s Rolled for ExtraRoomFeature (%d / %d)", ModUtil.ToString(sortedTable), randomIndex, numItems)
                )
            elseif string.find(caller, "DoUnlockRoomExits") then
                DebugBoxMod.writeToDebugBox(
                    string.format("Unlock Room Exits: %s (%d / %d)", ModUtil.ToString(sortedTable),  randomIndex, numItems)
                )
            else
                DebugBoxMod.writeToDebugBox(
                    string.format("%s Rolled ??????: %s (%d / %d)", caller or "", ModUtil.ToString(sortedTable), randomIndex, numItems)
                )
            end
        end)
    end

    return sortedTable[randomIndex]
end, RngDisplayMod)

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
    updateCurrentUses()

    if config.OutputToDebug then
        DebugBoxMod.writeToDebugBox(
            string.format("Random Key Result: %s (%d / %d)", ModUtil.ToString(sortedTable[randomIndex]), randomIndex, numItems)
        )
    end

    return sortedKeys[randomIndex]
end, RngDisplayMod)

--- Pop a random value from {tableArg}
-- Calls RNG directly
-- Scripts/UtilityScripts.lua : 1445
function RemoveRandomValue( tableArg, rng )
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
        updateCurrentUses()
	else
		retVal = tableArg[1]
		tableArg[1] = nil
		return retVal
	end

	table.sort(tableArg, cmp_multitype)

    local caller = PrintUtil.traceback()
    if config.OutputToDebug then
        if string.find(caller, "FillEnemyTypes") then
            DebugBoxMod.writeToDebugBox(
                string.format("Fill Enemy Type: %s (%d / %d)", ModUtil.ToString(tableArg[randomIndex]), randomIndex, numItems)
            )
        elseif string.find(caller, "GenerateEncounter") then
            DebugBoxMod.writeToDebugBox(
                string.format("Generate Encounter: %s (%d / %d)", ModUtil.ToString(tableArg[randomIndex]), randomIndex, numItems)
            )
        elseif string.find(caller, "CreateLoot") or string.find(caller, "PredictGodBoonOptions") then
            DebugBoxMod.printTableContentsToDebugBox(
                "exclude: ",
                tableArg[randomIndex],
                "ItemName"
            )
            DebugBoxMod.writeToDebugBox(
                string.format("Remove Random Loot: %s (%d / %d)", ModUtil.ToString(tableArg[randomIndex].ItemName), randomIndex, numItems)
            )
        elseif string.find(caller, "AudioScripts") then
            DebugBoxMod.writeToDebugBox(
                string.format("Remove Random Audio Cue: %s (%d / %d)", ModUtil.ToString(tableArg[randomIndex]), randomIndex, numItems)
            )
        elseif string.find(caller, "CreateBoonLootButtons") then
            DebugBoxMod.writeToDebugBox(
                string.format("Approval Process: %s (%d / %d)", ModUtil.ToString(tableArg[randomIndex]), randomIndex, numItems)
            )
        else
            if not string.find(caller, "HandleBreakableSwap") then
                if tableArg[randomIndex] ~= nil then
                    DebugBoxMod.writeToDebugBox(
                        string.format("%s Remove Random Value Result: %s (%d / %d)", caller or "", ModUtil.ToString(tableArg[randomIndex].Name), randomIndex, numItems)
                    )
                else
                    DebugBoxMod.writeToDebugBox(
                        string.format("%s Failed to Remove Random Value Result: (%d / %d)", caller or "", randomIndex, numItems)
                    )
                end
            end
        end
    end

	retVal = tableArg[randomIndex]
	tableArg[randomIndex] = nil
	return retVal
end