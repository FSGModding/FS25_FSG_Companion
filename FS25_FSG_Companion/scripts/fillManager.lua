rcDebug("FillManager Class")

FillManager = {}
local modDirectory = g_currentModDirectory
local FillManager_mt = Class(FillManager, Event)

InitEventClass(FillManager, "FillManager")

function FillManager.new(mission, i18n, modDirectory, modName)
  rcDebug("FCU-New")
  local self = setmetatable({}, FillManager_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.runCurrentDay    = 0
  self.isServer         = g_currentMission:getIsServer()
  self.isClient         = g_currentMission:getIsClient()

  g_messageCenter:subscribe(MessageType.FARM_CREATED, self.updateStorages, self)
  g_messageCenter:subscribe(MessageType.FARM_DELETED, self.updateStorages, self)

	return self
end


-- Change up how farm ids are handled in storages
-- Base game will create a farm id for all possible farms, and we don't want that.  We only want storage for existing farms.
function FillManager:onLoad(superFunc,savegame)
  rcDebug("FillManager - onLoad");
	local spec = self.spec_silo
	local xmlFile = self.xmlFile
	spec.playerActionTrigger = xmlFile:getValue("placeable.silo#playerActionTrigger", nil, self.components, self.i3dMappings)
	if spec.playerActionTrigger ~= nil then
		spec.activatable = PlaceableSiloActivatable.new(self)
	end
	spec.storagePerFarm = xmlFile:getValue("placeable.silo.storages#perFarm", false)
	spec.foreignSilo = xmlFile:getValue("placeable.silo.storages#foreignSilo", spec.storagePerFarm)
  spec.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)
	spec.unloadingStation:load(self.components, xmlFile, "placeable.silo.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	spec.unloadingStation.owningPlaceable = self
	spec.unloadingStation.hasStoragePerFarm = spec.storagePerFarm
  spec.loadingStation = LoadingStation.new(self.isServer, self.isClient)
	spec.loadingStation:load(self.components, xmlFile, "placeable.silo.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)
	spec.loadingStation.owningPlaceable = self
	spec.loadingStation.hasStoragePerFarm = spec.storagePerFarm
  spec.fillTypesAndLevelsAuxiliary = {}
	spec.fillTypeToFillTypeStorageTable = {}
	spec.infoTriggerFillTypesAndLevels = {}
  local availableFarmIds = {}
  for _, farm in ipairs(g_farmManager:getFarms()) do
    if farm.farmId ~= 0 then
      table.insert(availableFarmIds, farm.farmId)
    end
  end
	local numStorageSets = spec.storagePerFarm and #availableFarmIds or 1
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		numStorageSets = 1
	end
	spec.storages = {}
	local i = 0
	while true do
		local storageKey = string.format("placeable.silo.storages.storage(%d)", i)
		if not xmlFile:hasProperty(storageKey) then
			break
		end
		for j = 1, numStorageSets do
			local storage = Storage.new(self.isServer, self.isClient)
			if storage:load(self.components, xmlFile, storageKey, self.i3dMappings) then
        if availableFarmIds[j] ~= nil then
          storage.ownerFarmId = availableFarmIds[j]
        else
          storage.ownerFarmId = 1
        end
				storage.foreignSilo = spec.foreignSilo
        -- rcDebug("Storage for Farm: " .. storage.ownerFarmId)
        -- rcDebug(storage)
				table.insert(spec.storages, storage)
			end
		end
		i = i + 1
	end
	spec.sellWarningText = g_i18n:convertText(xmlFile:getValue("placeable.silo#sellWarningText", "$l10n_info_siloExtensionNotEmpty"))
end


-- Loop through all placeables that have multi farm storages enabled and update their farms
function FillManager:updateStorages()
  rcDebug("FillManager:updateStorages")
  
  if g_currentMission ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer ~= nil then

    local availableFarmIds = {}

    -- Collect all farm IDs except the default farm ID (0)
    for _, farm in ipairs(g_farmManager:getFarms()) do
      if farm.farmId ~= 0 then
        table.insert(availableFarmIds, farm.farmId)
      end
    end

    -- Loop through all placeables
    for v = 1, #g_currentMission.placeableSystem.placeables do
      local thisPlaceable = g_currentMission.placeableSystem.placeables[v]
      if thisPlaceable.spec_silo ~= nil then
        local spec = thisPlaceable.spec_silo

        if spec.storagePerFarm then
          rcDebug("Silo Has Storage Per Farm Enabled")

          -- Create a set of existing storage owner farm IDs
          local existingStorageFarmIds = {}
          for _, storage in ipairs(spec.storages) do
            existingStorageFarmIds[storage.ownerFarmId] = true
          end

          local storageSystem = g_currentMission.storageSystem

          -- Check if each farm has a storage
          for _, farmId in ipairs(availableFarmIds) do
            rcDebug("Checking Farm Id: " .. farmId)
            if not existingStorageFarmIds[farmId] then
              rcDebug("Storage Not Found for Farm ID: " .. farmId)
              -- Add a storage for this farm
              rcDebug("Adding storage for Farm ID: " .. farmId)
              local storageKey = string.format("placeable.silo.storages.storage(%d)", 0)

              local storage = Storage.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
              if storage:load(thisPlaceable.components, thisPlaceable.xmlFile, storageKey, thisPlaceable.i3dMappings) then
                storage.ownerFarmId = farmId
                storage.foreignSilo = spec.foreignSilo

                table.insert(spec.storages, storage)
                
                -- if g_currentMission:getIsServer() then
                --   storage:raiseDirtyFlags(storage.storageDirtyFlag)
                -- end
                -- storage:updateFillPlanes()

                -- Updated bits to make the storage good.
                storage:register(true)
                storage:addFillLevelChangedListeners(function()
                  thisPlaceable:raiseActive()
                end)

                -- Update the unload and load stations 
                if spec.unloadingStation ~= nil then
                  storageSystem:addStorageToUnloadingStation(storage, spec.unloadingStation)
                end
                if spec.loadingStation ~= nil then
                  storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
                end
              end
            end
          end

          -- Check if any storages no longer have a corresponding farm
          for storageFarmId, _ in pairs(existingStorageFarmIds) do
            if not table.contains(availableFarmIds, storageFarmId) then
              rcDebug("Storage Found with No Corresponding Farm for Farm ID: " .. storageFarmId)
              -- Remove storage for the farm that no longer exists
              for _, storage in ipairs(spec.storages) do
                if storage.ownerFarmId == storageFarmId then
                  rcDebug("Deleting Storage for FarmId: " .. storageFarmId)
                  -- rcDebug(storage)
                  
                  table.removeElement(spec.storages, storage)

                  -- if g_currentMission:getIsServer() then
                  --   storage:raiseDirtyFlags(storage.storageDirtyFlag)
                  -- end
                  -- storage:updateFillPlanes()

                  -- Updated bits to make the storage good.
                  -- storage:register(true)
                  storage:addFillLevelChangedListeners(function()
                    thisPlaceable:raiseActive()
                  end)
                end
              end
            end
          end

          -- Trigger client updates
          if g_currentMission:getIsServer() then
            UpdateStoragesEvent.sendEvent(true)
          end

        end
      end
    end

  end
end


-- Utility function to check if a table contains a value
function table.contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end