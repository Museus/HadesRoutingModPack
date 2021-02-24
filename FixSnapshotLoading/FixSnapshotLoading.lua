ModUtil.RegisterMod("FixSnapshotLoading")

--[[
  When RewardStores are updated during a run, the items
  are just nil'd out as they are used up. However, when
  saving/loading, the table is collapsed. This causes
  the iteration order to be different, which matters when
  the reward store is refilled, causing the items to be
  at different keys (and thus, rooms to have different
  rewards) from that point on.

  Fix by reconstructing the table as it was during the run
  ie. with the entries nil'd out but the proper iteration
  order.
]]
function UncollapseTable(tableArg)
  local highest = GetHighestIndex( tableArg )
  local sorted = {}
  for i = 1, highest do
    if tableArg[i] ~= nil then
      table.insert(sorted, tableArg[i])
    else
      table.insert(sorted, {})
    end
  end
  for i = 1, highest do
    if tableArg[i] == nil then
      sorted[i] = nil
    end
  end
  return sorted
end

ModUtil.WrapBaseFunction("Load", function(baseFunc, ...)
  baseFunc(...)
  if CurrentRun and CurrentRun.RewardStores then
    for k,v in pairs(CurrentRun.RewardStores) do
      CurrentRun.RewardStores[k] = UncollapseTable(v)
    end
  end
end, FixSnapshotLoading)
