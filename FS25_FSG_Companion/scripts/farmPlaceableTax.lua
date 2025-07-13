rcDebug("FarmPlaceableTax Class")

FarmPlaceableTax = {}
local FarmPlaceableTax_mt = Class(FarmPlaceableTax, Event)

InitEventClass(FarmPlaceableTax, "FarmPlaceableTax")

function FarmPlaceableTax.new(mission, i18n, modDirectory, modName)
  rcDebug("FCU-New")
  local self = setmetatable({}, FarmPlaceableTax_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.runCurrentDay    = 0
  self.isServer         = g_currentMission:getIsServer()

  g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)

        return self
end

function FarmPlaceableTax:delete()
  g_messageCenter:unsubscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
end

function FarmPlaceableTax:onDayChanged(currentDay)
  rcDebug("FarmPlaceableTax:onDayChanged")
  if g_server ~= nil and self.isServer and g_dedicatedServer ~= nil then
    -- Make sure we only run once per minute
    if self.runCurrentDay ~= currentDay then
      FarmPlaceableTax:taxPlaceables()
      self.runCurrentDay = currentDay
    end
  end
end

function FarmPlaceableTax:taxPlaceables()
  rcDebug("FarmPlaceableTax:taxPlaceables")

  -- Loop though placeables to check for matches
  for v=1, #g_currentMission.placeableSystem.placeables do
    local thisPlaceable = g_currentMission.placeableSystem.placeables[v]

    if thisPlaceable.storeItem.rawXMLFilename == "placeables/productionPoints/miningShaftTower/miningShaftTower.xml" then

      g_currentMission:addMoney(-50000, thisPlaceable.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)

    end

  end

end