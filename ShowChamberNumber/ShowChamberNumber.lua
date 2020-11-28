--[[
    ShowChamberNumber
    Authors:
      Museus (Discord: Museus#7777)
      Early Access patch by ShipGoSync (Discord: Ship#0101)
      Overriding HideDepthCounter idea by Ellomenop (Discord: ellomenop#2254)

    This version of ShowChamberNumber shows the Depth immediately upon starting a room,
    rather than waiting for the CombatUI to spawn. If that fails for some reason, fall back
    to showing the Depth during ShowCombatUI.
]]
ModUtil.RegisterMod("ShowChamberNumber")

ModUtil.WrapBaseFunction("StartRoom", function ( baseFunc, currentRun, currentRoom )
    ShowDepthCounter()
    baseFunc(currentRun, currentRoom)
end, ShowChamberNumber)

ModUtil.WrapBaseFunction("ShowCombatUI", function ( baseFunc, flag )
    ShowDepthCounter()
    baseFunc(flag)
end, ShowChamberNumber)

-- Hiding Depth Counter doesn't actually do anything
ModUtil.BaseOverride("HideDepthCounter", function ( baseFunc )
end, ShowChamberNumber)