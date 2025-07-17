rcDebug("Field Stats Class")

FieldStats = {}
local FieldStats_mt = Class(FieldStats, Event)

InitEventClass(FieldStats, "FieldStats")

-- MARK: new
function FieldStats.new(mission, i18n, modDirectory, modName)
  rcDebug("FieldStats - New")
  local self = setmetatable({}, FieldStats_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.setValueTimerFrequency = 60
  self.fieldStatsData   = {}
  self.firstRun         = true
  self.runCurrentHour   = 0
  self.fruitTypes       = {}

  g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)

        return self
end

function FieldStats:delete()
  g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
end


-- MARK: onHourChanged
-- FS25 - Looks like some things changed here.  Will have to revisit to get field stats - FSGSettings.lua:458: attempt to index nil with 'hud' - fieldStats.lua:237: attempt to call a nil value
function FieldStats:onHourChanged(currentHour)
  -- rcDebug("FieldStats:onHourChanged")
  if g_server ~= nil then
    -- Make sure we only run once per hour
    if self.runCurrentHour ~= currentHour then
      -- Delete any files that are in FieldsData folder
      local fieldsDataFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/FieldsData"
      if ( not fileExists(fieldsDataFolderPath) ) then createFolder(fieldsDataFolderPath) end
      getFiles(fieldsDataFolderPath, "clearFieldsFiles", self)
      -- Get field stats
      FieldStats:getFieldStats()
      self.runCurrentHour = currentHour
    end
  end
end

-- MARK: getFieldStats
function FieldStats:getFieldStats()
  rcDebug("FieldStats:getFieldStats")

  -- Shows notification when this script is running as it tends to take a bit to run.  Most cases it does not really lag, so can quote out to disable.
  -- if g_server ~= nil and g_dedicatedServer ~= nil then
  --   g_server:broadcastEvent(ChatEvent.new("Lag Warning! Updating Field Stats for website!",g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
  -- end

  local fields = g_fieldManager:getFields()

  -- Loop through each field
	if fields ~= nil then
		for _, field in pairs(fields) do
			if field.farmland ~= nil then

        local x, z              = field:getCenterOfFieldWorldPosition()
        local fruitTypeIndexPos, growthState = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
        local fruitDesc         = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndexPos)
        local fillType          = nil

        -- Get the field crop
        local fruitName = g_i18n:getText("text_unknown")
        if fruitDesc ~= nil and fruitDesc.fillType ~= nil then
            fruitName = fruitDesc.fillType.title
            fillType = g_fillTypeManager:getFillTypeByIndex(fruitDesc.fillType.index)

            -- if fruitDesc:getIsGrowing(growthState) or fruitDesc:getIsPreparable(growthState) or fruitDesc:getIsHarvestable(growthState) then
            --     showYieldData = true
            -- end
        end

        -- Get Field Status
        local getFieldFruitStatus = FieldStats:getFieldFruitStatus(fruitTypeIndexPos,growthState)
        if getFieldFruitStatus == nil then
          getFieldFruitStatus = g_i18n:getText("text_unknown")
        end
        -- Get Field Stage
        local getFieldStage, getWheelsInfo = FieldStats:getFieldFruitStatusStage(fruitTypeIndexPos,growthState)
        if getFieldStage == nil then
          getFieldStage = g_i18n:getText("text_unknown")
        end
        if getWheelsInfo == nil then
          getWheelsInfo = g_i18n:getText("text_unknown")
        end

        -- Get Field Needs
        local weedInfo = FieldStats:fieldAddWeed(field.fieldState)
        local limeInfo = FieldStats:fieldAddLime(field.fieldState)
        local plowingInfo = FieldStats:fieldAddPlowing(field.fieldState)
        local rollingInfo = FieldStats:fieldAddRolling(field.fieldState)
        local fertilizationInfo = FieldStats:fieldAddFertilization(field.fieldState)

        -- Not seeing where fields have their own numbers anymore.  Looks like they all use farmland id.

        local fieldData = {
          fieldId                = field.farmland.id,
          ownerFarmId            = field.farmland.farmId,
          farmlandId             = field.farmland.id, 
          fieldArea              = field.areaHa, 
          getFieldFruitStatus    = getFieldFruitStatus,
          getFieldStage          = getFieldStage,
          getWheelsInfo          = getWheelsInfo,
          weedInfo               = weedInfo, 
          limeInfo               = limeInfo,
          plowingInfo            = plowingInfo,
          rollingInfo            = rollingInfo,
          fertilizationInfo      = fertilizationInfo,
          fieldAreaFull          = field.farmland.areaInHa,
          fieldFruitName         = fruitName,
          posX                   = field.posX,
          posZ                   = field.posZ,
          farmlandPrice          = field.farmland.price

        }

        FieldStats:saveFieldDataXML(fieldData)

      end
    end
  end

end

function FieldStats:clearFieldsFiles(filename, isDirectory)
  -- rcDebug("FieldStats:clearFieldsFiles")
  if isDirectory then 
    return
  end
  if filename ~= nil then
    local loadFile = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/FieldsData/" .. filename
    if ( fileExists (loadFile) ) then
      --rcDebug("Deleting File")
      deleteFile(loadFile)
    end
  end
end

function FieldStats:getFieldFruitStatus(fruitTypeIndex,fruitGrowthState)
  if fruitTypeIndex == nil then
    return
  end
  local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
  if fruitType ~= nil then
    local witheredState = fruitType.maxHarvestingGrowthState + 1
    if fruitType.maxPreparingGrowthState >= 0 then
      witheredState = fruitType.maxPreparingGrowthState + 1
    end
    local maxGrowingState = fruitType.minHarvestingGrowthState - 1
    if fruitType.minPreparingGrowthState >= 0 then
      maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
    end
    local text = nil
    if fruitGrowthState == fruitType.cutState then
      text = g_i18n:getText("ui_growthMapCut")
    elseif fruitGrowthState == witheredState then
      text = g_i18n:getText("ui_growthMapWithered")
    elseif fruitGrowthState > 0 and fruitGrowthState <= maxGrowingState then
      text = g_i18n:getText("ui_growthMapGrowing")
    elseif fruitType.minPreparingGrowthState >= 0 and fruitType.minPreparingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxPreparingGrowthState then
      text = g_i18n:getText("ui_growthMapReadyToPrepareForHarvest")
    elseif fruitType.minHarvestingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxHarvestingGrowthState then
      text = g_i18n:getText("ui_growthMapReadyToHarvest")
    end
    if text ~= nil then
      return text
    else 
      return g_i18n:getText("text_unknown")
    end
  else
    return g_i18n:getText("text_unknown")
  end
end

function FieldStats:getFieldFruitStatusStage(fruitTypeIndex,fruitGrowthState)
  -- rcDebug("FieldStats:getFieldFruitStatusStage")
  local fruitType
  if fruitTypeIndex == nil then
    fruitType = nil
  else
    fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
  end
  local growthState = g_i18n:getText("text_none")
  local wheelsInfo = g_i18n:getText("text_All_Wheels")
	-- nil checks: when field does not contain a crop (plowed/cultivated), fruit data will be nil
	if (fruitType ~= nil and fruitGrowthState ~= nil) then
    local witheredState = fruitType.maxHarvestingGrowthState + 1
    if fruitType.maxPreparingGrowthState >= 0 then
      witheredState = fruitType.maxPreparingGrowthState + 1
    end
		local maxGrowthState = fruitType.numGrowthStates - 1; -- numGrowthStates includes the harvesting state, therefore -1
		-- Growth stage info
		if (fruitGrowthState ~= nil and fruitGrowthState > 0 and fruitGrowthState <= maxGrowthState) then
			-- Crop is in the one of the 'growing' states
			if fruitType.minForageGrowthState ~= 0 and fruitType.maxForageGrowthState ~= 0 and (fruitGrowthState >= fruitType.minForageGrowthState and fruitGrowthState <= fruitType.maxForageGrowthState) then
				-- Crop can be harvested by forage harvester already
				growthState = string.format("%s/%s (%s)", fruitGrowthState, maxGrowthState, g_i18n:getText("text_Foragable"));
			else
				-- Crop cannot be harvested by forage harvester yet
				growthState =  string.format("%s/%s", fruitGrowthState, maxGrowthState);
			end
    elseif fruitGrowthState == witheredState then
      growthState = g_i18n:getText("ui_growthMapWithered")
    elseif fruitType.minHarvestingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxHarvestingGrowthState then
      growthState = g_i18n:getText("ui_growthMapReadyToHarvest")
		end

		-- Wheel type info
		if (fruitGrowthState ~= nil and fruitType ~= nil and fruitType.minWheelDestructionState ~= nil and fruitType.maxWheelDestructionState ~= nil) then
			-- Crops like SugarBeets have the cutState (harvested state) within the bounds of the crop destruction filter. Therefore, explicitly exclude that state
			local narrowWheelsRequired = fruitGrowthState >= fruitType.minWheelDestructionState 
										and fruitGrowthState <= fruitType.maxWheelDestructionState 
										and fruitGrowthState ~= fruitType.wheelDestructionState
			wheelsInfo = (narrowWheelsRequired and g_i18n:getText("text_Narrow_Wheels")) or g_i18n:getText("text_All_Wheels")
		end
	end
  return growthState, wheelsInfo
end

function FieldStats.fieldAddWeed(_, fieldState)
	if g_currentMission.missionInfo.weedsEnabled then
		local weedSystem = g_currentMission.weedSystem
		local fieldInfoStates = weedSystem:getFieldInfoStates()
		local weedState = fieldState.weedState
		local fruitTypeIndex = fieldState.fruitTypeIndex or FruitType.UNKNOWN
		local growthState = fieldState.growthState or 0
		local toolName = nil
		if weedState ~= 0 then
			local fruitType
			if fruitTypeIndex == nil then
				fruitType = nil
			else
				fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
			end
			if Platform.gameplay.hasWeeder then
				if (fruitType == nil or fruitType:getIsWeedable(growthState)) and weedSystem:getWeederReplacements(false).weed.replacements[weedState] == 0 then
					toolName = g_i18n:getText("weed_destruction_weeder")
				end
				if toolName == nil and (fruitType == nil or fruitType:getIsHoeable(growthState)) and weedSystem:getWeederReplacements(true).weed.replacements[weedState] == 0 then
					toolName = g_i18n:getText("weed_destruction_hoe")
				end
			end
			if toolName == nil and (fruitType == nil or fruitType:getIsGrowing(growthState)) then
				toolName = g_i18n:getText("weed_destruction_herbicide")
			end
			local title = fieldInfoStates[weedState]
      if title ~= nil then
        if toolName ~= nil then
          return title .. " " .. toolName
        else 
          return title
        end
      else
        if toolName ~= nil then
          return toolName
        else
          return g_i18n:getText("text_none")
        end
      end
		end
	else
		return
	end
end

function FieldStats:fieldAddLime(fieldState)
  if Platform.gameplay.useLimeCounter and (g_currentMission.missionInfo.limeRequired and fieldState.limeLevel == 0) then
		return g_i18n:getText("ui_growthMapNeedsLime")
	end
  return g_i18n:getText("text_none")
end

function FieldStats:fieldAddPlowing(fieldState)
	if fieldState.plowLevel == 0 and g_currentMission.missionInfo.plowingRequiredEnabled then
		return g_i18n:getText("ui_growthMapNeedsPlowing")
	end
  return g_i18n:getText("text_none")
end

function FieldStats:fieldAddRolling(fieldState)
if Platform.gameplay.useRolling and fieldState.rollerLevel > 0 then
		return g_i18n:getText("ui_growthMapNeedsRolling")
	end
  return g_i18n:getText("text_none")
end

function FieldStats:fieldAddFertilization(fieldState)
	if fieldState.sprayLevel >= 0 then
		local v81 = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v82 = fieldState.sprayLevel / v81
		return g_i18n:getText("ui_growthMapFertilized"), string.format("%d %%", v82 * 100)
	end
  return g_i18n:getText("text_none")
end

-- adds farm manager to remember file
function FieldStats:saveFieldDataXML(fieldData)
  -- rcDebug("FM-saveFieldDataXML")

	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/FieldsData"
	local modSettingsFile = modSettingsFolderPath .. "/Field-" .. fieldData.fieldId .. "-" .. fieldData.ownerFarmId .. ".xml"

	local key = "fields"
  local subKey = ".field"

  -- rcDebug("Creating Field Data File")

  xmlFile = createXMLFile(key, modSettingsFile, key)
  
  setXMLString(xmlFile, key .. subKey .. "#fieldId", tostring(fieldData.fieldId))
  setXMLString(xmlFile, key .. subKey .. "#ownerFarmId", tostring(fieldData.ownerFarmId))
  setXMLString(xmlFile, key .. subKey .. "#farmlandId", tostring(fieldData.farmlandId))
  setXMLString(xmlFile, key .. subKey .. "#fieldArea", tostring(fieldData.fieldArea))
  setXMLString(xmlFile, key .. subKey .. "#getFieldFruitStatus", tostring(fieldData.getFieldFruitStatus))
  setXMLString(xmlFile, key .. subKey .. "#getFieldStage", tostring(fieldData.getFieldStage))
  setXMLString(xmlFile, key .. subKey .. "#getWheelsInfo", tostring(fieldData.getWheelsInfo))
  setXMLString(xmlFile, key .. subKey .. "#weedInfo", tostring(fieldData.weedInfo))
  setXMLString(xmlFile, key .. subKey .. "#limeInfo", tostring(fieldData.limeInfo))
  setXMLString(xmlFile, key .. subKey .. "#plowingInfo", tostring(fieldData.plowingInfo))
  setXMLString(xmlFile, key .. subKey .. "#rollingInfo", tostring(fieldData.rollingInfo))
  setXMLString(xmlFile, key .. subKey .. "#fertilizationInfo", tostring(fieldData.fertilizationInfo))
  setXMLString(xmlFile, key .. subKey .. "#fieldAreaFull", tostring(fieldData.fieldAreaFull))
  setXMLString(xmlFile, key .. subKey .. "#fieldFruitName", tostring(fieldData.fieldFruitName))
  setXMLString(xmlFile, key .. subKey .. "#posX", tostring(fieldData.posX))
  setXMLString(xmlFile, key .. subKey .. "#posZ", tostring(fieldData.posZ))
  setXMLString(xmlFile, key .. subKey .. "#farmlandPrice", tostring(fieldData.farmlandPrice))
  
  saveXMLFile(xmlFile)
  delete(xmlFile)

end

-- Adds more info to the field info box
function FieldStats.fieldAddField(_, fieldData, box)
  -- Add growth stage and wheel info to field box
  local growthState, wheelsInfo = FieldStats:getFieldFruitStatusStage(fieldData.fruitTypeIndex,fieldData.growthState)
  if growthState ~= nil then
    box:addLine(g_i18n:getText("text_growth_stage"),growthState)
  end
  if wheelsInfo ~= nil then
    box:addLine(g_i18n:getText("text_wheel_type"),wheelsInfo)
  end
end