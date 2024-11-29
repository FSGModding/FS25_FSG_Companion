rcDebug("farmCleanUp Class")

FarmCleanUp = {}
local FarmCleanUp_mt = Class(FarmCleanUp, Event)

InitEventClass(FarmCleanUp, "FarmCleanUp")

function FarmCleanUp.new(mission, i18n, modDirectory, modName)
  rcDebug("FCU-New")
  local self = setmetatable({}, FarmCleanUp_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.runCurrentMinute = 0
  self.isServer         = g_currentMission:getIsServer()
  self.coopCruiseAbuse  = {}

  g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
  g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)

	return self
end

function FarmCleanUp:onMinuteChanged(currentMinute)
  if g_currentMission.missionInfo.timeScale > 1 then	
    return
  end
  -- rcDebug("FarmCleanUp:onMinuteChanged")
  -- if g_server ~= nil and self.isServer and g_dedicatedServer ~= nil then
    -- Make sure we only run once per minute
    if self.runCurrentMinute ~= currentMinute then
      FarmCleanUp:checkSuperStrength()
      FarmCleanUp:checkCoopLimits()
      self.runCurrentMinute = currentMinute
    end
  -- end
end

function FarmCleanUp:onDayChanged()
  rcDebug("FarmCleanUp:onDayChanged")
  if g_server ~= nil and self.isServer and g_dedicatedServer ~= nil then
    -- Run stump clean up
    FarmCleanUp:cleanStumps()
    -- Run log clean up
    FarmCleanUp:cleanLogs()
    -- Run pallet cleanup process
    FarmCleanUp:cleanPallets()
    -- Run bale cleanup process
    FarmCleanUp:cleanBales()
  end
end

function FarmCleanUp:checkSuperStrength()
  rcDebug("FCU-checkSuperStrength")

  local superStrengthOn = false

  -- Check if super strength is enabled for any players
  for _, player in pairs(g_currentMission.players) do
    if player.superStrengthEnabled ~= nil and player.maxPickableMass ~= nil then
      if player.superStrengthEnabled and player.maxPickableMass > 50 then
        superStrengthOn = true
      end
    end
  end

  -- Super strength is on, turn it off
  if superStrengthOn then
    if g_dedicatedServer ~= nil then
      FarmCleanUp:disableSuperStrength(true)
      SuperStrengthEvent.sendEvent(true)
    end
  end

  -- Run empty farm ai check
  FarmCleanUp.checkEmptyFarmsHiredWorkers()
end

-- Disables super strength if on
function FarmCleanUp:disableSuperStrength(disable)
  rcDebug("FCU-disableSuperStrength")
  if disable and g_currentMission ~= nil and g_currentMission.players ~= nil then
    local pickupDistanceBackup = nil
    local pickupMassBackup = nil

    local maxPickableDistance = 3
    local maxPickableMass = 0.2

    Player.MAX_PICKABLE_OBJECT_DISTANCE = maxPickableDistance
    Player.MAX_PICKABLE_OBJECT_MASS = maxPickableMass

    for _, player in pairs(g_currentMission.players) do
        player.superStrengthEnabled = false

        player.maxPickableDistance = maxPickableDistance
        player.maxPickableMass = maxPickableMass

        player.superStrengthPickupDistanceBackup = pickupDistanceBackup -- compatibility
        player.superStrengthPickupMassBackup = pickupMassBackup -- compatibility
    end

    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, g_i18n:getText("rc_ss_off"))

  end
end

-- Loops through farms to see if empty, then checks for AI, if any it dismisses them
function FarmCleanUp:checkEmptyFarmsHiredWorkers()
  rcDebug("FCU-checkEmptyFarmsHiredWorkers")
  -- Check if enabled
  local dismissWorkers = g_fsgSettings.settings:getValue("dismissWorkers")
  if dismissWorkers then
    -- Check if any active workers
    if g_currentMission.aiSystem.activeJobs ~= nil and #g_currentMission.aiSystem.activeJobs > 0 then
      -- Loop through all active workers and see if they are part of current farm that is empty
      for _, job in ipairs(g_currentMission.aiSystem.activeJobs) do
        -- Loop through all farms
        for _, farm in ipairs(g_farmManager:getFarms()) do
          -- check if active players on farm
          if farm.activeUsers ~= nil and #farm.activeUsers > 0 then
            -- do nothing
          else
            if job.startedFarmId == farm.farmId then
              -- Worker is part of current farm and should be dismissed
              -- g_currentMission.aiSystem:removeJob(job)
              g_currentMission.aiSystem:stopJob(job, AIMessageErrorUnknown.new())
            end
          end
        end
      end
    end
  end
end

-- Loops through all stumps found on map and charges farm owner for the stump removal, then removes the stump.
function FarmCleanUp:cleanStumps()
  rcDebug("Scanning for stumps to clean up.")

  local newxmlFile
  local removedStumps = {}
  local numRemoved = 1
  local removeLogs = false
  local removeStumps = true
  local stumpCharge = -1000

  local _, numSplit = getNumOfSplitShapes()

  if numSplit > 0 then
      local densityManager = g_densityMapHeightManager
      local aiSystem = g_currentMission.aiSystem
      local splitSplitShapes = {}


      self:findAllSplitSplitShapes(getRootNode(), removeLogs, removeStumps, splitSplitShapes)

      for _, splitShape in pairs (splitSplitShapes) do
          local x, _, z = getWorldTranslation(splitShape)

          local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x,z)
          local farmId = g_farmlandManager:getFarmlandOwner(farmlandId)

          -- save the stump to table
          table.insert(removedStumps, {
            id = numRemoved,
            farmId = farmId,
            farmlandId = farmlandId,
            x = x,
            z = z
          })

          local farm = g_farmManager:getFarmById(farmId)
          if farm ~= nil then
            -- Charge farm for stump removal
            local moneyType = MoneyType.SOLD_WOOD
            g_currentMission:addMoneyChange(stumpCharge, farmId, moneyType, true)
            if farm ~= nil then
              rcDebug("Stump Removal Charge for farm: " .. farmId)
              farm:changeBalance(stumpCharge, moneyType)
            end
          end

          delete(splitShape)

          densityManager:setCollisionMapAreaDirty(x - 10, z - 10, x + 10, z + 10, true)
          aiSystem:setAreaDirty(x - 10, x + 10, z - 10, z + 10)

          numRemoved = numRemoved + 1
      end

      if numRemoved > 0 then
          g_treePlantManager:cleanupDeletedTrees()

          rcDebug("Saving Deleted Stumps to Outbox")

          --Save path and filename
          local commandOutboxDir       = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"
          local saveedFile       = commandOutboxDir .. "/removedStumps.xml"
          local transactionId = g_fsgSettings:getTransactionId()
          --File Key for xml output
          local key ="removedStumps"

          --save data to xml file
          newxmlFile = XMLFile.create(key, saveedFile, key)

          local index = 0

          for _, p in pairs(removedStumps) do
            --rcDebug(p)
            local subKey = string.format(".stump(%d)", index)

            newxmlFile:setString(key .. subKey .. "#id", tostring(p.id))
            newxmlFile:setInt(key .. subKey .. "#transactionId", tonumber(transactionId))
            newxmlFile:setString(key .. subKey .. "#farmId", tostring(p.farmId))
            newxmlFile:setString(key .. subKey .. "#farmlandId", tostring(p.farmlandId))
            newxmlFile:setString(key .. subKey .. "#x", tostring(p.x))
            newxmlFile:setString(key .. subKey .. "#z", tostring(p.z))

            index = index + 1
            p = {}
          end

          newxmlFile:save()
          newxmlFile:delete()

      end
  end

end

-- Loops through all stumps found on map and charges farm owner for the stump removal, then removes the stump.
function FarmCleanUp:cleanLogs()
  rcDebug("Scanning for logs to clean up.")

  local newxmlFile
  local removedLogs = {}
  local farmTreeCount = {}
  local numRemoved = 1
  local removeLogs = true
  local removeStumps = false

  local _, numSplit = getNumOfSplitShapes()

  if numSplit > 0 then
      local densityManager = g_densityMapHeightManager
      local aiSystem = g_currentMission.aiSystem
      local splitSplitShapes = {}


      self:findAllSplitSplitShapes(getRootNode(), removeLogs, removeStumps, splitSplitShapes)

      for _, splitShape in pairs (splitSplitShapes) do

          local x, _, z = getWorldTranslation(splitShape)

          local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x,z)
          local farmId = g_farmlandManager:getFarmlandOwner(farmlandId)

          if farmTreeCount[farmId] == nil then
            farmTreeCount[farmId] = 1
          end

          -- Check if farm has over 20 trees
          if farmTreeCount[farmId] < 20 then

              -- save the stump to table
              table.insert(removedLogs, {
                id = numRemoved,
                farmId = farmId,
                farmlandId = farmlandId,
                x = x,
                z = z
              })

              delete(splitShape)

              numRemoved = numRemoved + 1

          end

          farmTreeCount[farmId] = farmTreeCount[farmId] + 1

      end

      if numRemoved > 0 then
          g_treePlantManager:cleanupDeletedTrees()

          rcDebug("Saving Deleted Stumps to Outbox")

          --Save path and filename
          local commandOutboxDir       = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"
          local saveedFile       = commandOutboxDir .. "/removedLogs.xml"
          local transactionId = g_fsgSettings:getTransactionId()

          --File Key for xml output
          local key ="removedLogs"

          --save data to xml file
          newxmlFile = XMLFile.create(key, saveedFile, key)

          local index = 0

          for _, p in pairs(removedLogs) do
            --rcDebug(p)
            local subKey = string.format(".log(%d)", index)

            newxmlFile:setString(key .. subKey .. "#id", tostring(p.id))
            newxmlFile:setInt(key .. subKey .. "#transactionId", tonumber(transactionId))
            newxmlFile:setString(key .. subKey .. "#farmId", tostring(p.farmId))
            newxmlFile:setString(key .. subKey .. "#farmlandId", tostring(p.farmlandId))
            newxmlFile:setString(key .. subKey .. "#x", tostring(p.x))
            newxmlFile:setString(key .. subKey .. "#z", tostring(p.z))

            index = index + 1
            p = {}
          end

          newxmlFile:save()
          newxmlFile:delete()

      end
  end

end

function FarmCleanUp:findAllSplitSplitShapes(node, findLogs, findStumps, splitSplitShapes)
    for i = 0, getNumOfChildren(node) - 1 do
        local node = getChildAt(node, i)

        if (getName(node) == "splitGeom" and getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE)) and (getSplitType(node) ~= 0 and getIsSplitShapeSplit(node)) then
            local rigidBodyType = getRigidBodyType(node)

            if (findLogs and rigidBodyType == RigidBodyType.DYNAMIC) or (findStumps and rigidBodyType == RigidBodyType.STATIC) then
                splitSplitShapes[node] = node
            end
        else
            self:findAllSplitSplitShapes(node, findLogs, findStumps, splitSplitShapes)
        end
    end
end

function FarmCleanUp:cleanPallets()
    rcDebug("FarmCleanUp - cleanPallets")

    local numRemoved = 0

    local mission = g_currentMission

    local function getVehicleIsPallet(vehicle)
        if vehicle.isPallet or vehicle.typeName == "pallet" or vehicle.typeName == "treeSaplingPallet" or vehicle.typeName == "bigBag" then
            return true
        end

        if vehicle.spec_wheels == nil and vehicle.spec_enterable == nil then
            -- Allow custom pallets with different type names. Must include a valid spec of either Pallet, BigBag or TreeSaplingPallet
            -- Specialisations 'Wheels' and 'Enterable' are not invalid and ignored as these should not be part of a pallet
            for _, spec in pairs(vehicle.specializations) do
                if spec == Pallet or spec == BigBag or spec == TreeSaplingPallet then
                    return true
                end
            end
        end

        return false
    end

    local palletSpawnPlaces = {}

    -- Loop through all placeables
    for v = 1, #g_currentMission.placeableSystem.placeables do
      local thisPlaceable = g_currentMission.placeableSystem.placeables[v]
      local typeName = tostring(thisPlaceable.typeName)
      local palletSpawner = nil

      -- Check if pallet spawner data is in placeable by type
      if string.find(typeName, "Husbandry") then
        local specHusbandryPallets = thisPlaceable.spec_husbandryPallets
        if specHusbandryPallets ~= nil then
          palletSpawner = specHusbandryPallets.palletSpawner
        end
      elseif typeName == "productionPoint" or typeName == "productionPointWardrobe" or typeName == "greenhouse" then
        local specProductionPoint = thisPlaceable.spec_productionPoint.productionPoint
        if specProductionPoint ~= nil then
          palletSpawner = specProductionPoint.palletSpawner
        end
      elseif typeName == "beehivePalletSpawner" then
        local specBeehiveSpawner = thisPlaceable.spec_beehivePalletSpawner
        if specBeehiveSpawner ~= nil then
          palletSpawner = specBeehiveSpawner.palletSpawner
        end
      end

      -- Add the pallet spawner locations to table if found
      if palletSpawner ~= nil and palletSpawner.spawnPlaces ~= nil and #palletSpawner.spawnPlaces > 0 then
        for v = 1, #palletSpawner.spawnPlaces do
          local spawnPlace = palletSpawner.spawnPlaces[v]
          table.insert(palletSpawnPlaces, spawnPlace)
        end
      end
    end

    local removedPallets = {}

    for i = #mission.vehicles, 1, -1 do
        local vehicle = mission.vehicles[i]

        if vehicle.isa ~= nil and vehicle:isa(Vehicle) and vehicle.trainSystem == nil then
            if getVehicleIsPallet(vehicle) then
                local x, _, z = getWorldTranslation(vehicle.rootNode)
                -- Check if pallet is in a spawn area, if so then ignore it.
                local withinRadius = false
                if #palletSpawnPlaces ~= nil then
                    for _, s in pairs(palletSpawnPlaces) do
                        local radius = s.width
                        if s.length > s.width then
                          radius = s.length
                        end
                        withinRadius = FarmCleanUp:isPointWithinRadius(s.startX, s.startZ, x, z, radius)
                    end
                end
                if withinRadius == false then
                    local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x,z)
                    local baleData = {
                      id = numRemoved,
                      type = "pallet",
                      farmId = vehicle.ownerFarmId,
                      farmlandId = farmlandId,
                      x = x,
                      z = z,
                      xmlFilename = vehicle.configFileName,
                      isMissionBale = false
                    }
                    local checkItem = FarmCleanUp:checkItem(baleData)
                    if checkItem then
                        rcDebug("Removing Pallet: " .. vehicle.configFileName)
                        -- save the pallet to table
                        table.insert(removedPallets, {
                          id = baleData.id,
                          farmId = baleData.farmId,
                          farmlandId = baleData.farmlandId,
                          x = baleData.x,
                          z = baleData.z
                        })
                        mission:removeVehicle(vehicle)
                        numRemoved = numRemoved + 1
                    end
                end
            end
        end
    end

    -- Check if pallets removed and send them to website
    if removedPallets ~= nil and #removedPallets > 0 then
      --Save path and filename
      local commandOutboxDir       = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"
      local saveedFile       = commandOutboxDir .. "/removedPallets.xml"
      local transactionId = g_fsgSettings:getTransactionId()

      --File Key for xml output
      local key ="removedPallets"

      --save data to xml file
      newxmlFile = XMLFile.create(key, saveedFile, key)

      local index = 0

      for _, p in pairs(removedPallets) do
        --rcDebug(p)
        local subKey = string.format(".pallet(%d)", index)

        newxmlFile:setString(key .. subKey .. "#id", tostring(p.id))
        newxmlFile:setInt(key .. subKey .. "#transactionId", tonumber(transactionId))
        newxmlFile:setString(key .. subKey .. "#farmId", tostring(p.farmId))
        newxmlFile:setString(key .. subKey .. "#farmlandId", tostring(p.farmlandId))
        newxmlFile:setString(key .. subKey .. "#x", tostring(p.x))
        newxmlFile:setString(key .. subKey .. "#z", tostring(p.z))

        index = index + 1
        p = {}
      end

      newxmlFile:save()
      newxmlFile:delete()
    end

    rcDebug("Pallets Removed: " .. numRemoved)

end

function FarmCleanUp:cleanBales()
    rcDebug("FarmCleanUp - cleanBales")

    local numRemoved = 0
    local removedBales = {}

    local itemsToSave = g_currentMission.itemSystem.itemsToSave
    local balesToRemove = {}

    for _, item in pairs(itemsToSave) do
        local object = item.item

        if object.isa ~= nil and object:isa(Bale) then
            balesToRemove[#balesToRemove + 1] = object
        end
    end

    for i = #balesToRemove, 1, -1 do
        -- rcDebug(balesToRemove[i])
        if balesToRemove[i].nodeId ~= nil then
            local x, _, z = getWorldTranslation(balesToRemove[i].nodeId)
            local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x,z)
            local baleData = {
              id = numRemoved,
              type = "bale",
              farmId = balesToRemove[i].ownerFarmId,
              farmlandId = farmlandId,
              x = x,
              z = z,
              xmlFilename = balesToRemove[i].xmlFilename,
              isMissionBale = balesToRemove[i].isMissionBale
            }
            local checkItem = FarmCleanUp:checkItem(baleData)
            if checkItem then
              rcDebug("Removing bale: " .. balesToRemove[i].xmlFilename)
              -- save the bale to table
              table.insert(removedBales, {
                id = baleData.id,
                farmId = baleData.farmId,
                farmlandId = baleData.farmlandId,
                x = baleData.x,
                z = baleData.z
              })
              balesToRemove[i]:delete()
              numRemoved = numRemoved + 1
            end
        end
    end

    -- Check if bales removed and send them to website
    if removedBales ~= nil and #removedBales > 0 then
      --Save path and filename
      local commandOutboxDir       = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"
      local saveedFile       = commandOutboxDir .. "/removedBales.xml"
      local transactionId = g_fsgSettings:getTransactionId()

      --File Key for xml output
      local key ="removedBales"

      --save data to xml file
      newxmlFile = XMLFile.create(key, saveedFile, key)

      local index = 0

      for _, p in pairs(removedBales) do
        --rcDebug(p)
        local subKey = string.format(".bale(%d)", index)

        newxmlFile:setString(key .. subKey .. "#id", tostring(p.id))
        newxmlFile:setInt(key .. subKey .. "#transactionId", tonumber(transactionId))
        newxmlFile:setString(key .. subKey .. "#farmId", tostring(p.farmId))
        newxmlFile:setString(key .. subKey .. "#farmlandId", tostring(p.farmlandId))
        newxmlFile:setString(key .. subKey .. "#x", tostring(p.x))
        newxmlFile:setString(key .. subKey .. "#z", tostring(p.z))

        index = index + 1
        p = {}
      end

      newxmlFile:save()
      newxmlFile:delete()
    end

    rcDebug("Bales Removed: " .. numRemoved)

end

function FarmCleanUp:checkItem(data)
    rcDebug("FarmCleanUp - checkItem")
    -- rcDebug(data)

    local currentDay = g_currentMission.environment.currentDay
    rcDebug("currentDay: " .. currentDay)
    -- Check to see if item is already logged, if so then check if the logDay is > than 3 from current day.
    -- If 3+ days old, then delete the item / return true
    -- Otherwise return false
    local removeItem = false
    local matchFound = false

    local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
    local modSettingsFile = modSettingsFolderPath .. "/LooseItems.xml"

    local key = "items"

    local itemData = {
      id = tonumber(data.id),
      type = tostring(data.type),
      farmId = tonumber(data.farmId),
      farmlandId = tonumber(data.farmlandId),
      x = data.x,
      z = data.z,
      xmlFilename = tostring(data.xmlFilename),
      logDay = tonumber(currentDay)
    }

    -- rcDebug(itemData)

    if ( fileExists(modSettingsFile) ) then

      local xmlFile = XMLFile.load(key, modSettingsFile)
      local existingItems = {}
      local updatedItems = {}
      local newxmlFile
    
      if xmlFile == nil then
        return false
      end
        
      -- Get items from xml file
      xmlFile:iterate(key .. ".item", function (_, itemKey)
        --print("itemKey: " .. itemKey)
        local existingItem = {
          id = xmlFile:getInt(itemKey .. "#id"),
          type = xmlFile:getString(itemKey .. "#type"),
          farmId = xmlFile:getInt(itemKey .. "#farmId"),
          farmlandId = xmlFile:getInt(itemKey .. "#farmlandId"),
          x = xmlFile:getFloat(itemKey .. "#x"),
          z = xmlFile:getFloat(itemKey .. "#z"),
          xmlFilename = xmlFile:getString(itemKey .. "#xmlFilename"),
          logDay = xmlFile:getInt(itemKey .. "#logDay"),
        }
        table.insert(existingItems, existingItem)
      end)

      -- Loop through existing items to see if there is a match to current
      for _, eis in ipairs(existingItems) do
        rcDebug("Checking for item match.")
        if eis.type == itemData.type 
          and eis.farmId == itemData.farmId 
          and eis.farmlandId == itemData.farmlandId 
          and MathUtil.round(eis.x,1) == MathUtil.round(itemData.x,1)
          and MathUtil.round(eis.z,1) == MathUtil.round(itemData.z,1)
          and eis.xmlFilename == itemData.xmlFilename 
        then
          -- Match found
          rcDebug("Item match found.")
          matchFound = true
          -- Get days diff
          local daysDiff = 0
          if eis.logDay ~= nil and eis.logDay > 0 and currentDay > 0 then
            daysDiff = tonumber(currentDay) - tonumber(eis.logDay)
          end
          rcDebug("Item days diff: " .. daysDiff)
          -- Check if mission bale and give them more time
          local daysAllowed = 3
          if data.isMissionBale then 
            daysAllowed = 5
          end
          -- Check if days diff is more than allowed for type
          if daysDiff > daysAllowed then
            rcDebug("Found Item To Remove")
            removeItem = true
            table.removeElement(updatedItems, eis)
          else
            -- Age good, keep in file
            table.insert(updatedItems, eis)
          end
        else
            -- No Match, keep in file
            table.insert(updatedItems, eis)
        end
      end

      -- Check to see if no match, if not then add to file
      if matchFound == false then 
          -- No Match, add to file
          table.insert(updatedItems, itemData)
      end

      --save data to xml file
      newxmlFile = XMLFile.create(key, modSettingsFile, key)

      local index = 0

      for _, ui in pairs(updatedItems) do
        local subKey = string.format(".item(%d)", index)

        newxmlFile:setInt(key .. subKey .. "#id", tonumber(ui.id))
        newxmlFile:setString(key .. subKey .. "#type", tostring(ui.type))
        newxmlFile:setInt(key .. subKey .. "#farmId", tonumber(ui.farmId))
        newxmlFile:setInt(key .. subKey .. "#farmlandId", tonumber(ui.farmlandId))
        newxmlFile:setFloat(key .. subKey .. "#x", tonumber(ui.x))
        newxmlFile:setFloat(key .. subKey .. "#z", tonumber(ui.z))
        newxmlFile:setString(key .. subKey .. "#xmlFilename", tostring(ui.xmlFilename))
        newxmlFile:setInt(key .. subKey .. "#logDay", tonumber(ui.logDay))

        index = index + 1
      end

      newxmlFile:save()
      newxmlFile:delete()

    else 

      rcDebug("No LooseItems.xml yet.  Creating one.")

      local xmlFile = createXMLFile(key, modSettingsFile, key)

      setXMLInt(xmlFile, key .. ".item#id",tonumber(itemData.id))
      setXMLString(xmlFile, key .. ".item#type",tostring(itemData.type))
      setXMLInt(xmlFile, key .. ".item#farmId",tonumber(itemData.farmId))
      setXMLInt(xmlFile, key .. ".item#farmlandId",tonumber(itemData.farmlandId))
      setXMLFloat(xmlFile, key .. ".item#x",tonumber(itemData.x))
      setXMLFloat(xmlFile, key .. ".item#z",tonumber(itemData.z))
      setXMLString(xmlFile, key .. ".item#xmlFilename",tostring(itemData.xmlFilename))
      setXMLInt(xmlFile, key .. ".item#logDay",tonumber(itemData.logDay))

      saveXMLFile(xmlFile)
      delete(xmlFile)

    end

    return removeItem
end

-- Check to see if item is within radius
function FarmCleanUp:isPointWithinRadius(startX, startZ, pointX, pointZ, radius)
    -- Create a radius around the pallet spawn start point
    local x1 = startX + radius
    local x2 = startX - radius
    local z1 = startZ + radius
    local z2 = startZ - radius
    
    -- Check if point is within the x and z ranges
    local inRangeX = FarmCleanUp:isWithinRange(pointX, x2, x1)
    local inRangeZ = FarmCleanUp:isWithinRange(pointZ, z2, z1)

    return inRangeX and inRangeZ
end

-- Helper function to check if a point is within a range
function FarmCleanUp:isWithinRange(value, min, max)
    return value >= min and value <= max
end

-- Run coop limits check
function FarmCleanUp:checkCoopLimits()
  rcDebug("Check CO-OP Limits")
  -- Check if coop limits are enabled
  if g_fsgSettings.settings:getValue("coopLimitsEnabled") then
    rcDebug("CO-OP Limits Enabled")
    -- Get vehcile cruise min speed 
    local coopMinCruiseSpeed = g_fsgSettings.settings:getValue("coopMinCruiseSpeed")
    local coopMinCruiseMin = g_fsgSettings.settings:getValue("coopMinCruiseMin")
    if coopMinCruiseSpeed ~= nil and coopMinCruiseSpeed > 0 then
      coopMinCruiseSpeed = coopMinCruiseSpeed - 1
      coopMinCruiseMin = coopMinCruiseMin - 1
      -- Loop through all the vehicles and send their data to a table if they are not farm 0
      if g_currentMission.vehicles ~= nil then
        for _, vehicle in ipairs(g_currentMission.vehicles) do
          -- Check each vehicle to see if cruise is active
          if vehicle.getCruiseControlState ~= nil and vehicle:getCruiseControlState() == Drivable.CRUISECONTROL_STATE_ACTIVE then
            -- Check if speed is less than limit
            if vehicle.getCruiseControlSpeed and vehicle:getCruiseControlSpeed() <= coopMinCruiseSpeed then
              -- Check to see if player has been in this vehicle for more than the set amount of min
              if vehicle.getControllerName ~= nil then
                rcDebug("Found Player In Vehicle")
                local playerName = vehicle:getControllerName()
                local vehicleName = vehicle:getFullName()
                rcDebug(playerName)
                rcDebug(vehicleName)
                local playerUpdated = false
                -- Check if player is already in array or not
                if self.coopCruiseAbuse ~= nil then
                  for _, cca in ipairs(self.coopCruiseAbuse) do
                    -- Check to see if current vehicle and player has a match
                    if cca.playerName == playerName and cca.vehicleName == vehicleName then
                      rcDebug("Existing Entry Found for Player")
                      -- Player and vehicle found, check to see if they are over the limit
                      local minutesFound = 1
                      if cca.minutesFound ~= nil then
                        minutesFound = tonumber(cca.minutesFound)
                      end 
                      local minutesFoundPlus = minutesFound + 1
                      rcDebug(minutesFoundPlus)
                      rcDebug(coopMinCruiseMin)
                      if tonumber(minutesFoundPlus) >= tonumber(coopMinCruiseMin) then
                        rcDebug("Turn Cruise Off for Player")
                        print(string.format(" Info: %s detected using cruise below %d kph for %d min.  Cruise control has been turned off on %s", playerName, coopMinCruiseSpeed, coopMinCruiseMin, vehicleName))
                        -- Turn off cruse for going too slow
                        vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
                        -- Remove from table
                        table.removeElement(self.coopCruiseAbuse, cca)
                        playerUpdated = true
                      else 
                        rcDebug("Add Min To Player")
                        -- Update mins for table entry
                        cca.minutesFound = minutesFoundPlus
                        playerUpdated = true
                      end
                    else
                      rcDebug("New Player Found - Add new to table.")
                      -- Player and vehicle not found, add them to the array
                      local newData = {
                        playerName = playerName,
                        vehicleName = vehicleName,
                        minutesFound = 1
                      }
                      table.insert(self.coopCruiseAbuse, newData)
                      playerUpdated = true
                    end
                  end
                else
                  self.coopCruiseAbuse = {}
                  -- Table Empty, add new data to it
                  local newData = {
                    playerName = playerName,
                    vehicleName = vehicleName,
                    minutesFound = 1
                  }
                  table.insert(self.coopCruiseAbuse, newData)
                  playerUpdated = true
                end
                -- Failsafe to make sure player was added
                if not playerUpdated then
                  local newData = {
                    playerName = playerName,
                    vehicleName = vehicleName,
                    minutesFound = 1
                  }
                  table.insert(self.coopCruiseAbuse, newData)
                end
                -- Debug stuffs
                if self.coopCruiseAbuse ~= nil then
                  rcDebug("coopCruiseAbuse Table")
                  rcDebug(self.coopCruiseAbuse)
                end
              end
            end
          end
        end
      end
    end
  end
end