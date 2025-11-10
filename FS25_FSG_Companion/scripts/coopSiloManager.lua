rcDebug("Co-Op Silo Manager Class")

CoopSiloManager = {}
local CoopSiloManager_mt = Class(CoopSiloManager, Event)

InitEventClass(CoopSiloManager, "CoopSiloManager")

function CoopSiloManager.new(mission, i18n, modDirectory, modName)
  rcDebug("CoopSiloManager - New")
  local self = setmetatable({}, CoopSiloManager_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.runCurrentMinute = 0
  self.isServer         = g_currentMission:getIsServer()
  self.setValueTimerFrequency = 180
  self.inboundCoopSilos = {}
  self.outboundCoopSilos = {}
  self.inboundObjectSilos = {}

  self:cacheCoopSilos()

  g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)

        return self
end

function CoopSiloManager:delete()
  g_messageCenter:unsubscribe(MessageType.MINUTE_CHANGED, self.onMinuteChanged, self)
end

function CoopSiloManager:cacheCoopSilos()
  self.inboundCoopSilos = {}
  self.outboundCoopSilos = {}
  self.inboundObjectSilos = {}
  for _, placeable in ipairs(g_currentMission.placeableSystem.placeables) do
    if placeable.typeName == "FS25_FSG_CoopSilo.siloStorageInbound" then
      table.insert(self.inboundCoopSilos, placeable)
    elseif placeable.typeName == "FS25_FSG_CoopSilo.siloStorageOutbound" then
      table.insert(self.outboundCoopSilos, placeable)
    elseif placeable.typeName == "FS25_FSG_CoopSilo.siloStorageInboundObjects" then
      table.insert(self.inboundObjectSilos, placeable)
    end
  end
end

function CoopSiloManager:update(dt)
  if g_server ~= nil and self.isServer and g_dedicatedServer ~= nil then
    if g_updateLoopIndex % self.setValueTimerFrequency == 0 then
      CoopSiloManager:checkCoopObjectStorage()
    end
  end
end

function CoopSiloManager:onMinuteChanged(currentMinute)
  if g_currentMission.missionInfo.timeScale > 1 then	
    return
  end
  if g_server ~= nil and self.isServer and g_dedicatedServer ~= nil then
    -- Make sure we only run once per minute
    if self.runCurrentMinute ~= currentMinute then
      CoopSiloManager:checkCoopSilos()
      self.runCurrentMinute = currentMinute
    end
  end
end

function CoopSiloManager:checkCoopSilos()
    -- rcDebug("CoopSiloManager:checkCoopSilos")

    if self.outboundCoopSilos == nil or #self.outboundCoopSilos == 0 then
      self:cacheCoopSilos()
    end

    for _, thisPlaceable in ipairs(self.outboundCoopSilos) do
        for _, storage in ipairs(thisPlaceable.spec_silo.storages) do
            -- Check if farm owner id exists
            local farm = g_farmManager:getFarmById(storage.ownerFarmId)
            if farm ~= nil and storage.fillLevels ~= nil then
                -- Check if any fills
                for fillType, fillLevel in pairs(storage.fillLevels) do
                    if fillLevel > 0 then
                      local thisFillData = {
                        fillType    = g_fillTypeManager:getFillTypeNameByIndex(fillType),
                        amount      = fillLevel
                      }
                      -- Send the fill to the website
                      CoopSiloManager:createFillXml(farm,thisFillData)
                      -- Empty this storage
                      storage:setFillLevel(0, fillType, nil)
                      storage:raiseDirtyFlags(storage.storageDirtyFlag)
                    end
                end
            end
        end
    end
end

function CoopSiloManager:checkCoopObjectStorage()
    -- rcDebug("CoopSiloManager:checkCoopObjectStorage")

    if (self.inboundCoopSilos == nil or #self.inboundCoopSilos == 0) and (self.inboundObjectSilos == nil or #self.inboundObjectSilos == 0) then
      self:cacheCoopSilos()
    end

    for _, thisPlaceable in ipairs(self.inboundCoopSilos) do

        local productFound = false

        -- Loop through pallets and bales if any
        for i = 1, #thisPlaceable.spec_objectStorage.storedObjects do

          local object = thisPlaceable.spec_objectStorage.storedObjects[i]

          -- If pallet then process pallet
          if object ~= nil and object.palletAttributes ~= nil then

            local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(object.palletAttributes.fillType)
            rcDebug("palletAttributes")
            rcDebug(object.palletAttributes)
            rcDebug(fillTypeName)

            -- Check if dlc and if so then alter the configFileName
            local configFileName = object.palletAttributes.configFileName
            if string.contains(object.palletAttributes.configFileName, "pdlc") then
              local dlcTitle = getDlcTitle(object.palletAttributes.configFileName)
              configFileName = dlcTitle
            end

            local commandOutboxDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox"
            local transactionId = g_fsgSettings:getTransactionId()
            local confirmationFile = "/coopPalletStore-" .. transactionId .. ".xml"
            local outboxFile = commandOutboxDir .. confirmationFile
            local timestamp = getDate("%Y-%m-%d %H:%M:%S")
            local key = "commands"
            local xmlFile
            --save player coopSilo to outbox
            xmlFile = createXMLFile(key, outboxFile, key)
            setXMLString(xmlFile, key .. ".command#command", "coopPalletStore")
            setXMLInt(xmlFile, key .. ".command#id", tonumber("0"))
            setXMLInt(xmlFile, key .. ".command#transactionId", tonumber(transactionId))
            setXMLString(xmlFile, key .. ".command#className", "Vehicle")
            setXMLString(xmlFile, key .. ".command#farmId", tostring(object.palletAttributes.ownerFarmId))
            setXMLString(xmlFile, key .. ".command#configFileName", NetworkUtil.convertToNetworkFilename(configFileName))
            setXMLString(xmlFile, key .. ".command#isBigBag", tostring(object.palletAttributes.isBigBag))
            setXMLString(xmlFile, key .. ".command#fillTypeName", tostring(fillTypeName))
            setXMLString(xmlFile, key .. ".command#fillLevel", tostring(object.palletAttributes.fillLevel))
            setXMLString(xmlFile, key .. ".command#timestamp", tostring(timestamp))
            if object.palletAttributes.configurations.fillUnit ~= nil then
              setXMLString(xmlFile, key .. ".command#configFillUnit", tostring(object.palletAttributes.configurations.fillUnit))
            end
            if object.palletAttributes.configurations.fillVolume ~= nil then
              setXMLString(xmlFile, key .. ".command#configFillVolume", tostring(object.palletAttributes.configurations.fillVolume))
            end
            if object.palletAttributes.configurations.treeSaplingType ~= nil then
              setXMLString(xmlFile, key .. ".command#ConfigTreeSaplingType", tostring(object.palletAttributes.configurations.treeSaplingType))
            end
            saveXMLFile(xmlFile)
            delete(xmlFile)

            -- Copy the file to backup location just in case
            local commandBackupDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/backup"
            local backupFile = commandBackupDir .. confirmationFile
            copyFile(outboxFile, backupFile, true)

            -- remove the pallet from storage
            g_farmManager:updateFarmStats(object.palletAttributes.ownerFarmId, "storedPallets", -1)
            table.remove(thisPlaceable.spec_objectStorage.storedObjects, i)

            productFound = true
      
          -- If Bale then process bale
          elseif object ~= nil and (object.baleObject ~= nil or object.baleAttributes ~= nil) then
            
            local objectBale = object.baleObject or object.baleAttributes

            -- Make sure bale is not part of a mission.
            if objectBale.isMissionBale ~= true then
    
              rcDebug(objectBale)

              local farmId = objectBale.ownerFarmId or objectBale.farmId

              local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(objectBale.fillType)

              local wrappingColor = nil
              if objectBale.wrappingColor[4] ~= nil then
                wrappingColor = objectBale.wrappingColor[1] .. "-" .. objectBale.wrappingColor[2] .. "-" .. objectBale.wrappingColor[3] .. "-" .. objectBale.wrappingColor[4]
              else
                wrappingColor = objectBale.wrappingColor[1] .. "-" .. objectBale.wrappingColor[2] .. "-" .. objectBale.wrappingColor[3]
              end

              local commandOutboxDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox"
              local transactionId = g_fsgSettings:getTransactionId()
              local confirmationFile = "/coopBaleStore-" .. transactionId .. ".xml"
              local outboxFile = commandOutboxDir .. confirmationFile
              local timestamp = getDate("%Y-%m-%d %H:%M:%S")
              local key = "commands"
              local xmlFile
              --save player coopSilo to outbox
              xmlFile = createXMLFile(key, outboxFile, key)
              setXMLString(xmlFile, key .. ".command#command", "coopBaleStore")
              setXMLInt(xmlFile, key .. ".command#id", tonumber("0"))
              setXMLInt(xmlFile, key .. ".command#transactionId", tonumber(transactionId))
              setXMLString(xmlFile, key .. ".command#farmId", tostring(farmId))
              setXMLString(xmlFile, key .. ".command#xmlFilename", NetworkUtil.convertToNetworkFilename(objectBale.xmlFilename))
              setXMLString(xmlFile, key .. ".command#fillLevel", tostring(objectBale.fillLevel))
              setXMLString(xmlFile, key .. ".command#wrappingState", tostring(objectBale.wrappingState))
              setXMLString(xmlFile, key .. ".command#supportsWrapping", tostring(objectBale.supportsWrapping))
              setXMLString(xmlFile, key .. ".command#baleValueScale", tostring(objectBale.baleValueScale))
              setXMLString(xmlFile, key .. ".command#wrappingColor", tostring(wrappingColor))
              setXMLString(xmlFile, key .. ".command#fillTypeName", tostring(fillTypeName))
              setXMLString(xmlFile, key .. ".command#isFermenting", tostring(objectBale.isFermenting))
              if objectBale.isFermenting then
                setXMLString(xmlFile, key .. ".command#fermentationTime", tostring(objectBale.fermentationTime))
              end
              setXMLString(xmlFile, key .. ".command#timestamp", tostring(timestamp))
              saveXMLFile(xmlFile)
              delete(xmlFile)
            
              -- Copy the file to backup location just in case
              local commandBackupDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/backup"
              local backupFile = commandBackupDir .. confirmationFile
              copyFile(outboxFile, backupFile, true)

              -- remove the bale from storage
              g_farmManager:updateFarmStats(farmId, "storedBales", -1)
              table.remove(thisPlaceable.spec_objectStorage.storedObjects, i)

              productFound = true
            
            end

          end

        end

        if productFound then
          thisPlaceable.spec_objectStorage.numStoredObjects = #thisPlaceable.spec_objectStorage.storedObjects
          thisPlaceable:setObjectStorageObjectInfosDirty()		
          thisPlaceable:updateObjectStorageObjectInfos()			
          thisPlaceable:raiseDirtyFlags(thisPlaceable.spec_objectStorage.dirtyFlag)
        end
    end
end

-- Function to add fill to silo from remote
function CoopSiloManager:addFillToSilo(farmId,fillTypeName,fillAmount)
    rcDebug("CoopSiloManager - addFillToSilo")

    -- Get the fillType id by fillName
    local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
    local fillTypeIndex = nil

    if fillType ~= nil then
      fillTypeIndex = fillType.index
    end

    if #self.inboundCoopSilos == 0 then
      self:cacheCoopSilos()
    end

    for _, thisPlaceable in ipairs(self.inboundCoopSilos) do

        -- Loop though the storages to see if farm owns it, if so then add the fill
        for _, storage in ipairs(thisPlaceable.spec_silo.storages) do
            -- Only add the fill to the storage that is owned by the farmId
            if storage.ownerFarmId == farmId then
              storage:setFillLevel(storage:getFillLevel(fillTypeIndex) + fillAmount, fillTypeIndex, nil)
              storage:raiseDirtyFlags(storage.storageDirtyFlag)
            end
        end
    end
end

-- Add pallet to object storage
function CoopSiloManager:addPallet(farmId,configFileName,isBigBag,fillTypeName,fillLevel,fillUnit,fillVolume,treeSaplingType,storeItem)
    rcDebug("CoopSiloManager - addPallet")

    -- Get the fillType id by fillName
    local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName).index

    if #self.inboundObjectSilos == 0 then
      self:cacheCoopSilos()
    end

    for _, thisPlaceable in ipairs(self.inboundObjectSilos) do

        -- Loop though the storages to see if farm owns it, if so then add the fill
        local storage = thisPlaceable

        local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME["Vehicle"]
        local abstractPallet = abstractObjectClass.new()

        -- Check if dlc and if so then alter the configFileName
        if string.contains(configFileName, "$pdlcdir$") then
          local dlcTitle = getDlcDir(configFileName)
          configFileName = dlcTitle
        end

        abstractPallet.palletAttributes = {}
        abstractPallet.palletAttributes.ownerFarmId = tonumber(farmId)
        abstractPallet.palletAttributes.configFileName = NetworkUtil.convertFromNetworkFilename(configFileName)
        abstractPallet.palletAttributes.isBigBag = convertToBool(isBigBag)
        abstractPallet.palletAttributes.fillType = tonumber(fillType)
        abstractPallet.palletAttributes.fillLevel = tonumber(fillLevel)
        abstractPallet.palletAttributes.configurations = {}
        if fillUnit ~= nil then
          abstractPallet.palletAttributes.configurations.fillUnit = tonumber(fillUnit)
        end
        if fillVolume ~= nil then
          abstractPallet.palletAttributes.configurations.fillVolume = tonumber(fillVolume)
        end
        if treeSaplingType ~= nil then
          abstractPallet.palletAttributes.configurations.treeSaplingType = tonumber(treeSaplingType)
        end

        g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedPallets", 1)

        storage:addAbstactObjectToObjectStorage(abstractPallet)

        storage:setObjectStorageObjectInfosDirty()		
        storage:updateObjectStorageObjectInfos()		
        storage:raiseDirtyFlags(storage.spec_objectStorage.dirtyFlag)
    end

end

-- Add bale to object storage
function CoopSiloManager:addBale(farmId,xmlFilename,fillLevel,wrappingState,supportsWrapping,baleValueScale,wrappingColor,fillTypeName,isFermenting,fermentationTime,variationIndex)
  rcDebug("CoopSiloManager - addBale")

  -- Split up the wrapping colors
  local wrapColors = string.split(wrappingColor, "-")
  local wc1, wc2, wc3, wc4 = 1, 1, 1, 1
  if wrapColors[1] ~= nil then
    wc1 = wrapColors[1]
  end
  if wrapColors[2] ~= nil then
    wc2 = wrapColors[2]
  end
  if wrapColors[3] ~= nil then
    wc3 = wrapColors[3]
  end
  if wrapColors[4] ~= nil then
    wc4 = wrapColors[4]
  end

  -- Get the fillType id by fillName
  local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName).index

  if #self.inboundObjectSilos == 0 then
    self:cacheCoopSilos()
  end

  for _, thisPlaceable in ipairs(self.inboundObjectSilos) do

      -- Loop though the storages to see if farm owns it, if so then add the fill
      local storage = thisPlaceable

      local abstractObjectClass = PlaceableObjectStorage.ABSTRACT_OBJECTS_BY_CLASS_NAME["Bale"]
      local abstractBale = abstractObjectClass.new()

      abstractBale.baleAttributes = {}
      abstractBale.baleAttributes.farmId = tonumber(farmId)
      abstractBale.baleAttributes.xmlFilename = NetworkUtil.convertFromNetworkFilename(xmlFilename)
      abstractBale.baleAttributes.isFermenting = convertToBool(isFermenting)
      abstractBale.baleAttributes.baleValueScale = tonumber(baleValueScale)
      abstractBale.baleAttributes.fillLevel = tonumber(fillLevel)
      abstractBale.baleAttributes.wrappingState = tonumber(wrappingState)
      abstractBale.baleAttributes.supportsWrapping = convertToBool(supportsWrapping)
      abstractBale.baleAttributes.wrappingColor = {}
      abstractBale.baleAttributes.wrappingColor[1] = tonumber(wc1)
      abstractBale.baleAttributes.wrappingColor[2] = tonumber(wc2)
      abstractBale.baleAttributes.wrappingColor[3] = tonumber(wc3)
      if wc4 ~= nil then
        abstractBale.baleAttributes.wrappingColor[4] = tonumber(wc4)
      end
      abstractBale.baleAttributes.isMissionBale = false
      abstractBale.baleAttributes.fillType = tonumber(fillType)
      if abstractBale.baleAttributes.isFermenting then
        if abstractBale.baleAttributes.fermentationTime ~= nil then
          abstractBale.baleAttributes.fermentationTime = tonumber(fermentationTime)
        else
          abstractBale.baleAttributes.fermentationTime = 0
        end
      end
      if variationIndex ~= nil then
        abstractBale.baleAttributes.variationIndex = variationIndex
      else
        abstractBale.baleAttributes.variationIndex = "1"
      end

      g_farmManager:updateFarmStats(storage:getOwnerFarmId(), "storedBales", 1)

      storage:addAbstactObjectToObjectStorage(abstractBale)

      storage:setObjectStorageObjectInfosDirty()		
      storage:updateObjectStorageObjectInfos()		
      storage:raiseDirtyFlags(storage.spec_objectStorage.dirtyFlag)
  
    end
end


-- Create fill xml data output
function CoopSiloManager:createFillXml(farm,fillData)
  rcDebug("CoopSiloManager - creatFillXml")

  local commandOutboxDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox"
  local transactionId = g_fsgSettings:getTransactionId()
  local confirmationFile = "/coopSiloStore-" .. transactionId .. ".xml"
  local outboxFile = commandOutboxDir .. confirmationFile
  local timestamp = getDate("%Y-%m-%d %H:%M:%S")
  local key = "commands"
  local xmlFile
  --save player coopSilo to outbox
  xmlFile = createXMLFile(key, outboxFile, key)
  setXMLString(xmlFile, key .. ".command#command", "coopSiloStore")
  setXMLInt(xmlFile, key .. ".command#id", tonumber("0"))
  setXMLInt(xmlFile, key .. ".command#transactionId", tonumber(transactionId))
  setXMLString(xmlFile, key .. ".command#farmId", tostring(farm.farmId))
  setXMLString(xmlFile, key .. ".command#fillType", tostring(fillData.fillType))
  setXMLString(xmlFile, key .. ".command#amount", tostring(fillData.amount))
  setXMLString(xmlFile, key .. ".command#timestamp", tostring(timestamp))
  saveXMLFile(xmlFile)
  delete(xmlFile)

  -- Copy the file to backup location just in case
  local commandBackupDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/backup"
  local backupFile = commandBackupDir .. confirmationFile
  copyFile(outboxFile, backupFile, true)

end

function CoopSiloManager:getIsActivatable()
  rcDebug("CoopSiloManager - getIsActivatable")

	if self.objectStorage.spec_objectStorage.objectSpawn.isActive then
		return false
	end

	return true
end


-- Overwrite the basegame function to only show objects that are owned by current farm.
function CoopSiloManager:setObjectInfos(superFunc, objectInfos, maxUnloadAmount)
  rcDebug("CoopSiloManager - getIsActivatable")
	local farmId = FarmManager.SINGLEPLAYER_FARM_ID
  if g_localPlayer and g_localPlayer.farmId ~= nil then
    farmId = g_localPlayer.farmId
  else
    farmId = g_currentMission:getFarmId()
  end

  rcDebug("farmId")
  rcDebug(farmId)

	self.objectInfos = objectInfos
	self.maxUnloadAmount = maxUnloadAmount or self.maxUnloadAmount
	local objectInfoTable = {}

	for _, objectInfo in pairs(objectInfos) do
    -- Remove ojbects that are not owned by current farm
    -- rcDebug("objectInfo")
    -- rcDebug(objectInfo)

    -- rcDebug("objectInfo.objects Table")
    -- rcDebug(objectInfo.objects)
    for i = 1, #objectInfo.objects do
      rcDebug("objectInfo.objects Single")
      rcDebug(objectInfo.objects[i])
      if (objectInfo.objects[i] ~= nil and objectInfo.objects[i].palletAttributes ~= nil and objectInfo.objects[i].palletAttributes.ownerFarmId ~= nil and objectInfo.objects[i].palletAttributes.ownerFarmId ~= farmId)
      or (objectInfo.objects[i] ~= nil and objectInfo.objects[i].baleAttributes~= nil and objectInfo.objects[i].baleAttributes.ownerFarmId ~= nil and objectInfo.objects[i].baleAttributes.ownerFarmId ~= farmId)
      or (objectInfo.objects[i] ~= nil and objectInfo.objects[i].palletAttributes ~= nil and objectInfo.objects[i].palletAttributes.farmId ~= nil and objectInfo.objects[i].palletAttributes.farmId ~= farmId)
      or (objectInfo.objects[i] ~= nil and objectInfo.objects[i].baleAttributes~= nil and objectInfo.objects[i].baleAttributes.farmId ~= nil and objectInfo.objects[i].baleAttributes.farmId ~= farmId) then
        table.remove(objectInfo.objects, i)
      end
    end

		if objectInfo.objects[1] ~= nil then
			table.insert(objectInfoTable, objectInfo.objects[1]:getDialogText())
		end
	end

	self.itemsElement:setTexts(objectInfoTable)
	self.itemsElement:setState(1, true)

end