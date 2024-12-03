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


-- MARK: onHourChanged
-- FS25 - Looks like some things changed here.  Will have to revisit to get field stats - FSGSettings.lua:458: attempt to index nil with 'hud' - fieldStats.lua:237: attempt to call a nil value
function FieldStats:onHourChanged(currentHour)
  -- rcDebug("FieldStats:onHourChanged")
  if g_server ~= nil then
    -- Make sure we only run once per hour
    if self.runCurrentHour ~= currentHour then
      FieldStats:getFieldStats()
      self.runCurrentHour = currentHour
    end
  end
end

-- MARK: getFieldStats
function FieldStats:getFieldStats()
  rcDebug("FieldStats:getFieldStats")

  -- Shows notification when this script is running as it tends to take a bit to run.  Most cases it does not really lag, so can quote out to disable.
  if g_server ~= nil and g_dedicatedServer ~= nil then
    g_server:broadcastEvent(ChatEvent.new("Lag Warning! Updating Field Stats for website!",g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
  end

  -- Delete any files that are in FieldsData folder
	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/FieldsData"
  if ( not fileExists(modSettingsFolderPath) ) then createFolder(modSettingsFolderPath) end
	getFiles(modSettingsFolderPath, "clearFieldsFiles", self)

  local fields = g_fieldManager:getFields()

  -- Loop through each field
	if fields ~= nil then
		for _, field in pairs(fields) do
			if field.farmland ~= nil then
        local fieldFruitType = "Unknown"
        if field.fruitType ~= nil then
          fieldFruitType = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
        end
        local fieldFruitName = "Unknown"
        if fieldFruitType ~= nil and fieldFruitType.fillType ~= nil and fieldFruitType.fillType.title then
          fieldFruitName = fieldFruitType.fillType.title
        elseif fieldFruitType.name ~= nil then
          fieldFruitName = fieldFruitType.name
        end

        -- rcDebug("Getting Field Data")
        -- rcDebug(field)
        local extraData = {
          currentField = field.farmland.id,
          fieldAreaFull = field.fieldArea,
          fieldFruitName = fieldFruitName,
          posX = field.posX,
          posZ = field.posZ
        }
        local sizeX = 5
        local sizeZ = 5
        local distance = 2
        local dirX, dirZ = MathUtil.getDirectionFromYRotation(0)
        local sideX, _, sideZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
        local startWorldX = field.posX - sideX * sizeX * 0.5 - dirX * distance
        local startWorldZ = field.posZ - sideZ * sizeX * 0.5 - dirZ * distance
        local widthWorldX = field.posX + sideX * sizeX * 0.5 - dirX * distance
        local widthWorldZ = field.posZ + sideZ * sizeX * 0.5 - dirZ * distance
        local heightWorldX = field.posX - sideX * sizeX * 0.5 - dirX * (distance + sizeZ)
        local heightWorldZ = field.posZ - sideZ * sizeX * 0.5 - dirZ * (distance + sizeZ)
        self.requestedFieldData = true

        FieldStats.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.onFieldDataUpdateFinished, self, extraData)

      end
    end
  end

end

function FieldStats:clearFieldsFiles(filename, isDirectory)
  rcDebug("FieldStats:clearFieldsFiles")
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

function FieldStats.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, callbackFunc, callbackTarget, extraData)
	g_asyncTaskManager:addTask(function ()
		local functionData = FSDensityMapUtil.functionCache.getFieldStatusAsync

		if functionData == nil then
			local weedSystem = g_currentMission.weedSystem
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			functionData = {
				fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			}

			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.plowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)

			functionData.plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
			functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
			functionData.sprayLevelMaxValue = sprayLevelMaxValue

			if Platform.gameplay.useLimeCounter then
				local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
				functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
				functionData.limeLevelFilter = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)

				functionData.limeLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
			end

			if weedSystem:getMapHasWeed() then
				local states = weedSystem:getFieldInfoStates()
				local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
				functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
				functionData.weedStateFilters = {}

				for state, _ in pairs(states) do
					local filter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)

					filter:setValueCompareParams(DensityValueCompareType.EQUAL, state)

					functionData.weedStateFilters[state] = filter
				end
			end

			functionData.fruitModifiers = {}
			functionData.fruitFilters = {}

			for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
				if desc.terrainDataPlaneId ~= nil then
					local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					functionData.fruitModifiers[index] = fruitModifier
					local fruitFilters = {}
					functionData.fruitFilters[index] = fruitFilters

					for i = 0, 2^desc.numStateChannels - 1 do
						local fruitFilter = DensityMapFilter.new(fruitModifier)

						fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)
						table.insert(fruitFilters, fruitFilter)
					end
				end
			end

			FSDensityMapUtil.functionCache.getFieldStatusAsync = functionData
		end

		local fieldFilter = functionData.fieldFilter
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local _, fieldArea, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		if fieldArea == 0 then
			callbackFunc(callbackTarget, nil)

			return
		end

		local status = {
      currentField = extraData.currentField,
      fieldAreaFull = extraData.fieldAreaFull,
      fieldFruitName = extraData.fieldFruitName,
      posX = extraData.posX,
      posZ = extraData.posZ,
			fieldArea = fieldArea,
			farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((startWorldX + widthWorldX + heightWorldX) / 3, (startWorldZ + widthWorldZ + heightWorldZ) / 3)
		}
		status.ownerFarmId = g_farmlandManager:getFarmlandOwner(status.farmlandId)

		g_asyncTaskManager:addSubtask(function ()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
			local _, numPixels, _ = FSDensityMapUtil.getAreaDensity(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, cultivatedType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			status.cultivatorFactor = numPixels / fieldArea
		end)

		if Platform.gameplay.useLimeCounter then
			g_asyncTaskManager:addSubtask(function ()
				local limeLevelModifier = functionData.limeLevelModifier
				local limeLevelFilter = functionData.limeLevelFilter

				limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

				local _, numPixels, _ = limeLevelModifier:executeGet(limeLevelFilter, fieldFilter)
				status.needsLimeFactor = numPixels / fieldArea
			end)
		end

		g_asyncTaskManager:addSubtask(function ()
			local plowLevelModifier = functionData.plowLevelModifier
			local plowLevelFilter = functionData.plowLevelFilter

			plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			local _, numPixels, _ = plowLevelModifier:executeGet(plowLevelFilter, fieldFilter)
			status.plowFactor = numPixels / fieldArea
		end)

		-- if Platform.gameplay.useRolling then
		-- 	g_asyncTaskManager:addSubtask(function ()
		-- 		status.needsRollingFactor = FSDensityMapUtil.getRollerFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		-- 	end)
		-- end

		if Platform.gameplay.useStubbleShred then
			g_asyncTaskManager:addSubtask(function ()
				status.stubbleFactor = FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end)
		end

		g_asyncTaskManager:addSubtask(function ()
			local sprayLevelModifier = functionData.sprayLevelModifier
			local sprayLevelFilter = functionData.sprayLevelFilter
			local sprayLevelMaxValue = functionData.sprayLevelMaxValue

			sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			status.fertilizerFactor = 0

			for i = 1, sprayLevelMaxValue do
				sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

				local _, numPixels, _ = sprayLevelModifier:executeGet(sprayLevelFilter, fieldFilter)
				status.fertilizerFactor = status.fertilizerFactor + i * numPixels
			end

			status.fertilizerFactor = status.fertilizerFactor / (sprayLevelMaxValue * fieldArea)
		end)

		status.fruits = {}
		status.fruitPixels = {}
		local fruitMaxPixels = 0

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				g_asyncTaskManager:addSubtask(function ()
					local fruitModifier = functionData.fruitModifiers[index]
					local fruitFilters = functionData.fruitFilters[index]

					fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

					local maxState = 0
					local maxPixels = 0

					for i = 0, 2^desc.numStateChannels - 1 do
						local _, numPixels, _ = fruitModifier:executeGet(fruitFilters[i + 1], fieldFilter)

						if maxPixels < numPixels then
							maxState = i
							maxPixels = numPixels
						end
					end

					status.fruits[desc.index] = maxState
					status.fruitPixels[desc.index] = maxPixels

					if fruitMaxPixels < maxPixels then
						status.fruitTypeMax = desc.index
						status.fruitStateMax = maxState
						fruitMaxPixels = maxPixels
					end
				end)
			end
		end

		local weedModifier = functionData.weedModifier

		if weedModifier ~= nil then
			status.weed = {}

			weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			local weedStateFilters = functionData.weedStateFilters

			for state, filter in pairs(weedStateFilters) do
				g_asyncTaskManager:addSubtask(function ()
					local _, numPixels, _ = weedModifier:executeGet(filter, fieldFilter)
					status.weed[state] = numPixels
				end)
			end

			g_asyncTaskManager:addSubtask(function ()
				status.weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end)
		end

		g_asyncTaskManager:addSubtask(function ()
			callbackFunc(callbackTarget, status)
		end)
	end)
end

function FieldStats:getFieldFruitStatus(data)

  -- Using PF
  local fruitTypeIndex = data.fruitTypeMax
  local fruitGrowthState = data.fruitStateMax

  if fruitTypeIndex == nil then
    return
  end

  local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

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
  end

end

function FieldStats:getFieldFruitStatusStage(data)
  
  -- rcDebug("FieldStats:getFieldFruitStatusStage")

	if (self.fruitTypes == nil) then
		self.fruitTypes = g_fruitTypeManager.indexToFruitType;
	end

	if (data == nil) then
		do return end;
	end

  local growthState = "Unknown";
  local wheelsInfo = "Unknown";

	-- nil checks: when field does not contain a crop (plowed/cultivated), fruit data will be nil
	local fruitIndex = data.fruitTypeMax;
	if (fruitIndex ~= nil and data.fruits ~= nil) then
		local currentGrowthState = data.fruits[fruitIndex];
		local maxGrowthState = self.fruitTypes[fruitIndex].numGrowthStates - 1; -- numGrowthStates includes the harvesting state, therefore -1
		
		-- Growth stage info
		if (currentGrowthState ~= nil and currentGrowthState > 0 and currentGrowthState <= maxGrowthState) then
			-- Crop is in the one of the 'growing' states
			if (currentGrowthState >= self.fruitTypes[fruitIndex].minForageGrowthState) then
				-- Crop can be harvested by forage harvester already
				growthState = string.format("%s/%s (%s)", currentGrowthState, maxGrowthState, g_i18n:getText("text_Foragable"));
			else
				-- Crop cannot be harvested by forage harvester yet
				growthState =  string.format("%s/%s", currentGrowthState, maxGrowthState);
			end
		end

		-- Wheel type info
		local destructionInfo = self.fruitTypes[fruitIndex].destruction
		if (currentGrowthState ~= nil and destructionInfo ~= nil and destructionInfo.filterStart ~= nil and destructionInfo.filterEnd ~= nil) then
			-- Crops like SugarBeets have the cutState (harvested state) within the bounds of the crop destruction filter. Therefore, explicitly exclude that state
			local narrowWheelsRequired = currentGrowthState >= destructionInfo.filterStart 
										and currentGrowthState <= destructionInfo.filterEnd 
										and currentGrowthState ~= self.fruitTypes[fruitIndex].cutState
			wheelsInfo = (narrowWheelsRequired and g_i18n:getText("text_Narrow_Wheels")) or g_i18n:getText("text_All_Wheels")
		end
	end

  return growthState, wheelsInfo
end

function FieldStats:getFieldInfo(data)

	local fruitTypeIndex = data.fruitTypeMax
	local fruitGrowthState = data.fruitStateMax

	self.texts = {
		expectedYield = g_i18n:getText("fieldInfo_expectedYield"),
		yieldPotential = g_i18n:getText("fieldInfo_yieldPotential")
	}

  if self.fieldInfos == nil then
    self.fieldInfos = {}
  end

	if fruitTypeIndex == nil then
		return
	end

	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local maxGrowingState = fruitType.minHarvestingGrowthState - 1

	if fruitType.minPreparingGrowthState >= 0 then
		maxGrowingState = math.min(maxGrowingState, fruitType.minPreparingGrowthState - 1)
	end

	local isGrowing = false

	if fruitGrowthState > 0 and fruitGrowthState <= maxGrowingState then
		isGrowing = true
	elseif fruitType.minPreparingGrowthState >= 0 and fruitType.minPreparingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxPreparingGrowthState then
		isGrowing = true
	elseif fruitType.minHarvestingGrowthState <= fruitGrowthState and fruitGrowthState <= fruitType.maxHarvestingGrowthState then
		isGrowing = true
	end

	if isGrowing then
		local plowFactor = data.plowFactor
		local weedFactor = data.weedFactor
		local stubbleFactor = data.stubbleFactor
		-- local rollerFactor = 1 - data.needsRollingFactor
		local missionInfo = g_currentMission.missionInfo

		if not missionInfo.plowingRequiredEnabled then
			plowFactor = 1
		end

		if not missionInfo.weedsEnabled then
			weedFactor = 1
		end

		local harvestMultiplier = 0
		harvestMultiplier = harvestMultiplier + plowFactor * 0.1
		harvestMultiplier = harvestMultiplier + weedFactor * 0.15
		harvestMultiplier = harvestMultiplier + stubbleFactor * 0.025
		-- harvestMultiplier = harvestMultiplier + rollerFactor * 0.025
		local yieldPotential = 1
		local yieldPotentialToHa = 0

		-- for i = 1, #self.fieldInfos do
		-- 	local fieldInfo = self.fieldInfos[i]

		-- 	if fieldInfo.yieldChangeFunc ~= nil then
		-- 		local factor, proportion, _yieldPotential, _yieldPotentialToHa = fieldInfo.yieldChangeFunc(fieldInfo.object, fieldInfo)
		-- 		harvestMultiplier = harvestMultiplier + factor * proportion
		-- 		yieldPotential = _yieldPotential or yieldPotential
		-- 		yieldPotentialToHa = _yieldPotentialToHa or yieldPotentialToHa
		-- 	end
		-- end

		if yieldPotential > 0 then
			harvestMultiplier = math.ceil(50 + harvestMultiplier * 50) / 100
			local expectedYield = harvestMultiplier * yieldPotential
      local expectedYieldOutput = "Unknown"
      local yieldPotentialOutput = "Unknown"
      local expectedYieldOutputNum = "Unknown"
      local yieldPotentialOutputNum = "Unknown"

			if yieldPotentialToHa ~= 0 then
				expectedYieldOutput = self.texts.expectedYield
        expectedYieldOutputNum = string.format("%d %% | %.1f to/ha", expectedYield * 100, harvestMultiplier * yieldPotentialToHa)
				yieldPotentialOutput = self.texts.yieldPotential
        yieldPotentialOutputNum = string.format("%d %% | %.1f to/ha", yieldPotential * 100, yieldPotentialToHa)
			else
				expectedYieldOutput = self.texts.expectedYield
        expectedYieldOutputNum = string.format("%d %%", expectedYield * 100)
				yieldPotentialOutput = self.texts.yieldPotential
        yieldPotentialOutputNum = string.format("%d %%", yieldPotential * 100)
			end

      return expectedYieldOutput, expectedYieldOutputNum, yieldPotentialOutput, yieldPotentialOutputNum
		end
	end

end


function FieldStats:onFieldDataUpdateFinished(data) 
  -- rcDebug("Returned Field Data")
  -- rcDebug(data)
  
  if data ~= nil then
    -- Get Field Status
    local getFieldFruitStatus = FieldStats:getFieldFruitStatus(data)
    if getFieldFruitStatus == nil then
      getFieldFruitStatus = "Unknown"
    end
    -- Get Field Stage
    local getFieldStage, getWheelsInfo = FieldStats:getFieldFruitStatusStage(data)
    if getFieldStage == nil then
      getFieldStage = "Unknown"
    end
    if getWheelsInfo == nil then
      getWheelsInfo = "Unknown"
    end

    -- Get Precision Farming Data
    local expectedYieldOutput, expectedYieldOutputNum, yieldPotentialOutput, yieldPotentialOutputNum = FieldStats:getFieldInfo(data)
    -- Get Field Needs
		local weedInfo = FieldStats:fieldAddWeed(data)
		local limeInfo = FieldStats:fieldAddLime(data)
		local plowingInfo = FieldStats:fieldAddPlowing(data)
		-- local rollingInfo = FieldStats:fieldAddRolling(data)
    local fertilizationInfo = FieldStats:fieldAddFertilization(data)

    -- Put the field data together in a single table before sending to xml
    local fieldData = {
      fieldId = data.currentField,
      ownerFarmId = data.ownerFarmId,
      farmlandId = data.farmlandId,
      fieldArea = data.fieldArea,
      getFieldFruitStatus = getFieldFruitStatus,
      getFieldStage = getFieldStage,
      getWheelsInfo = getWheelsInfo,
      expectedYieldOutput = expectedYieldOutput,
      expectedYieldOutputNum = expectedYieldOutputNum,
      yieldPotentialOutput = yieldPotentialOutput,
      yieldPotentialOutputNum = yieldPotentialOutputNum,
      weedInfo = weedInfo,
      limeInfo = limeInfo,
      plowingInfo = plowingInfo,
      -- rollingInfo = rollingInfo,
      fertilizationInfo = fertilizationInfo,
      fieldAreaFull = data.fieldAreaFull,
      fieldFruitName = data.fieldFruitName,
      posX = data.posX,
      posZ = data.posZ
    }

    FieldStats:saveFieldDataXML(fieldData)
  end

end

function FieldStats:fieldAddWeed(data)
	if g_currentMission.missionInfo.weedsEnabled then
		local weedSystem = g_currentMission.weedSystem
		local fieldInfoStates = weedSystem:getFieldInfoStates()
		local maxState = nil
		local maxPixels = 0

		for state, pixels in pairs(data.weed) do
			if maxPixels < pixels then
				maxState = state
				maxPixels = pixels
			end
		end

		if maxState == nil then
			return
		end

		local toolName = nil
		local fruitTypeIndex = data.fruitTypeMax
		local fruitGrowthState = data.fruitStateMax
		local fruitTypeDesc = nil

		if fruitTypeIndex ~= nil then
			fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		end

		if fruitTypeIndex == nil or fruitGrowthState < fruitTypeDesc.minHarvestingGrowthState and fruitGrowthState <= fruitTypeDesc.maxWeederState then
			local weederReplacements = weedSystem:getWeederReplacements(false)
			local weed = weederReplacements.weed
			local targetState = weed.replacements[maxState]

			if targetState == 0 then
				toolName = g_i18n:getText("weed_destruction_weeder")
			end
		end

		if toolName == nil and (fruitTypeIndex == nil or fruitGrowthState < fruitTypeDesc.minHarvestingGrowthState and fruitGrowthState <= fruitTypeDesc.maxWeederHoeState) then
			local hoeReplacements = weedSystem:getWeederReplacements(true)
			local weed = hoeReplacements.weed
			local targetState = weed.replacements[maxState]

			if targetState == 0 then
				toolName = g_i18n:getText("weed_destruction_hoe")
			end
		end

		if toolName == nil and (fruitTypeIndex == nil or fruitGrowthState < fruitTypeDesc.minHarvestingGrowthState) then
			toolName = g_i18n:getText("weed_destruction_herbicide")
		end

		local title = fieldInfoStates[maxState]

    if toolName ~= nil then
  		return title .. " " .. toolName
    else 
      return title
    end
	end
end

function FieldStats:fieldAddLime(data)
	if not Platform.gameplay.useLimeCounter then
		return
	end

	local isRequired = MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME < data.needsLimeFactor

	if isRequired and g_currentMission.missionInfo.limeRequired then
		return g_i18n:getText("ui_growthMapNeedsLime")
	end
  return "None"
end

function FieldStats:fieldAddPlowing(data)
	local isRequired = data.plowFactor < MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING

	if isRequired and g_currentMission.missionInfo.plowingRequiredEnabled then
		return g_i18n:getText("ui_growthMapNeedsPlowing")
	end
  return "None"
end

function FieldStats:fieldAddRolling(data)
	if not Platform.gameplay.useRolling then
		return
	end

	local isRequired = MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING < data.needsRollingFactor

	if isRequired then
		return g_i18n:getText("ui_growthMapNeedsRolling")
	end
  return "None"
end

function FieldStats:fieldAddFertilization(data)
	local fertilizationFactor = data.fertilizerFactor

	if fertilizationFactor >= 0 then
		return g_i18n:getText("ui_growthMapFertilized") .. " " .. string.format("%d %%", fertilizationFactor * 100)
	end
  return "None"
end

-- adds farm manager to remember file
function FieldStats:saveFieldDataXML(fieldData)
  rcDebug("FM-saveFieldDataXML")
  rcDebug(fieldData)

	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/FieldsData"
	local modSettingsFile = modSettingsFolderPath .. "/Field-" .. fieldData.fieldId .. "-" .. fieldData.ownerFarmId .. ".xml"

	local key = "fields"
  local subKey = ".field"

  rcDebug("Creating Field Data File")

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

  saveXMLFile(xmlFile)
  delete(xmlFile)

end