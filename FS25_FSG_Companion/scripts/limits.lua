rcDebug("Limits Class")

Limits = {}
local Limits_mt = Class(Limits, Event)

InitEventClass(Limits, "Limits", EventIds.EVENT_FINISHED_LOADING)

function Limits.new(mission, i18n, modDirectory, modName)
  rcDebug("Limits - New")
  local self = setmetatable({}, Limits_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.aiVehicles       = {}
  
  return self
end

-- Set global limits on map load
function Limits:loadMap()
  rcDebug("Limits - loadMap")
  -- Set the max helpers limit
	g_currentMission.maxNumHirables = 32
  ProductionChainManager.NUM_MAX_PRODUCTION_POINTS = 240.00000;

  -- Check if map has active collectables then remove them
  -- local collectiblesSystem = g_currentMission.collectiblesSystem
  -- g_currentMission.collectiblesSystem.isComplete = true
  -- if collectiblesSystem ~= nil then
  --   rcDebug("Collectables Found - Removing Them")
	-- 	for _, info in pairs(collectiblesSystem.collectibles) do
	-- 		collectiblesSystem.collected[info.index] = true
	-- 		if info.groupName ~= nil then
	-- 			collectiblesSystem.groups[info.groupName].collectedItems = collectiblesSystem.groups[info.groupName].collectedItems + 1
	-- 		end
	-- 	end
  --   collectiblesSystem:updateCollectiblesState(collectiblesSystem)
  --   collectiblesSystem:updateTargetState(collectiblesSystem)
  --   collectiblesSystem:updateHotspotState(collectiblesSystem)
  -- end

end

-- Disable ability to buy existing productions
function Limits:disableBuyProduction()
  -- Let the player know they can not buy productions
  InfoDialog.show(g_i18n:getText("rc_production_purchase_disabled"), nil, nil, DialogElement.TYPE_WARNING)
end

-- Limit the number of AI that any given farm can hire.
function Limits:getAILimitedReached()
  rcDebug("Limits - getAILimitedReached")
  -- Checks to see if overall hire limit is reached for the server or client.
  return g_currentMission.maxNumHirables <= #g_currentMission.aiSystem.activeJobVehicles
end

-- Update aidVehicles for clients
function Limits:updateVehiclesAI(aiVehicles)
  rcDebug("Limits - updateVehiclesAI")
  g_limits.aiVehicles = aiVehicles
end

-- Update aidVehicles for clients
function Limits:getVehiclesAI()
  rcDebug("Limits - getVehiclesAI")
  return g_limits.aiVehicles
end

function Limits:toggleAIVehicle()
  rcDebug("Limits - toggleAIVehicle")
  local selfData = self
  local sequence = 1
  local ownerFarmId = selfData:getOwnerFarmId()
  local activeJobVehicles = 0
  rcDebug("ownerFarmId")
  rcDebug(ownerFarmId)
  -- Get number of active jobs for farm
  for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
    if job.startedFarmId == ownerFarmId then
      activeJobVehicles = activeJobVehicles + 1
    end
  end
  -- If server then send to everyone, if not then we are local
  if g_server ~= nil and g_dedicatedServer ~= nil then
    LimitsEvent.sendEvent(selfData, ownerFarmId, activeJobVehicles, sequence)
  else
    Limits:toggleAIVehicleSecond(selfData, ownerFarmId, activeJobVehicles, sequence, true)
  end
end

-- Check if a player is trying to hire a worker
function Limits:toggleAIVehicleSecond(selfData, ownerFarmId, activeJobVehicles, sequence, localUser)
  rcDebug("Limits - toggleAIVehicle2")
  rcDebug("ownerFarmId: " .. ownerFarmId)
  rcDebug("sequence: " .. sequence)
  rcDebug("activeJobVehicles: " .. activeJobVehicles)
  rcDebug("Mission FarmId: " .. g_currentMission:getFarmId())

  -- Only run if player farm matches farm that was triggered
  if g_currentMission:getFarmId() ~= ownerFarmId then 
    -- rcDebug("Mission farm does not match job farm.")
    g_currentMission:showBlinkingWarning(g_i18n:getText("rc_own_hire_warn"), 5000)
    return
  end

  -- Check current farm to see if max hires for farm is reached
  local currentOwnerFarmId = selfData:getOwnerFarmId()

  -- Check if current ai is active, then dismiss.  If not then do other stuffs
	if selfData:getIsAIActive() then
		selfData:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	else

    local hireLimit = math.floor(g_fsgSettings.settings:getValue("hireLimit")) - 1 or 2
    rcDebug("Hire Limit")
    rcDebug(hireLimit)
    local startableJob = selfData:getStartableAIJob()
    
    -- If there are multipe missions, loop through them to check what farms they belong to
    if activeJobVehicles ~= nil and ownerFarmId == currentOwnerFarmId then
      -- Check to see how many AI are hired for current farmId
      if activeJobVehicles >= hireLimit then
        rcDebug("Max AI Hired For Farm")
        startableJob = false
        if localUser then
          g_currentMission:showBlinkingWarning(g_i18n:getText("rc_max_hire_warn"), 5000)
        end        
      end
    end

		if startableJob then
			g_client:getServerConnection():sendEvent(FCAIJobStartRequestEvent.new(startableJob, nil, currentOwnerFarmId))
			return
		end

    -- Only show this to the local user
    if localUser then
  		g_gui:showGui("InGameMenu")
	  	g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_AI_SCREEN, selfData)
    end
	end
end

-- 
function Limits.startContract(self, superFunc, leaseVehicles)
  local contract = self:getSelectedContract()
  local farmId = g_currentMission:getFarmId()

  -- Check to see if the player has taken max contracts
	if Limits:hasFarmReachedMissionLimit(farmId) then
		InfoDialog.show(g_i18n:getText("rc_max_missions"), nil, nil, DialogElement.TYPE_WARNING)

		return
	end

  if contract == nil then
    return
  else
    if leaseVehicles and not contract.mission:isSpawnSpaceAvailable() then
      InfoDialog.show(g_i18n:getText("warning_noFreeMissionSpace"), nil, nil, DialogElement.TYPE_WARNING)
    else
      g_messageCenter:subscribe(MissionStartEvent, self.onMissionStarted, self)
      g_client:getServerConnection():sendEvent(MissionStartEvent.new(contract.mission, farmId, leaseVehicles))
    end
  end

end

-- Set a hard limit of missions any given farm can have
function Limits:hasFarmReachedMissionLimit(farmId)
  rcDebug("Limits - hasFarmReachedMissionLimit")
	local maxMissions = math.floor(g_fsgSettings.settings:getValue("maxMissions")) - 1 or 2
	local total = 0
	for _, mission in ipairs(g_missionManager:getMissions()) do
		if mission.farmId == farmId and
			(mission.status == MissionStatus.RUNNING or mission.status == MissionStatus.FINISHED) then
			total = total + 1
		end
	end
	return maxMissions <= total
end

-- Set a hard limit of placeable animal pins
function Limits:updateAnimalHusbandryLimitRules(superFunc, ...)
  rcDebug("Limits - updateAnimalHusbandryLimitRules")

	if self.spec_husbandryAnimals then
    local husbandryLimit = math.floor(g_fsgSettings.settings:getValue("husbandryLimit")) - 1 or 2
		local animalType = self.spec_husbandryAnimals.animalType
		local husbandryList = g_currentMission.husbandrySystem:getPlaceablesByFarm(nil)
		local animalTypeList = {}
    local animalTypeName = string.lower(animalType.name)
		for i, p in pairs(husbandryList) do
			if p:getAnimalTypeIndex() == animalType.typeIndex and p.ownerFarmId == g_currentMission:getFarmId() then
				table.insert(animalTypeList, p)
			end
		end
    if husbandryLimit <= #animalTypeList then
      return false, string.format(g_i18n:getText("rc_max_pens"),animalTypeName)
    end
	end

	return superFunc(self, ...)
end

-- Set limit on buyable placeables
function Limits:canBuyPlaceable()
  -- rcDebug("Limits - canBuyPlaceable")
	local storeItem = self.storeItem
	local maxItemCount = math.floor(g_fsgSettings.settings:getValue("otherPlaceables")) - 1 or 5
  local infoText = g_i18n:getText("rc_max_placeables")

  rcDebug("Store Item Category Name")
  rcDebug(self.storeItem.categoryName)

  -- Check if placeable is a set type and has a different limit
  if self.storeItem.categoryName == "PRODUCTIONPOINTS" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("productionPoints")) - 1 or 2
    infoText = g_i18n:getText("rc_max_productions")
  elseif self.storeItem.categoryName == "SELLINGPOINTS" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("sellingPoints")) - 1 or 1
    infoText = g_i18n:getText("rc_max_sellingpoints")
  elseif self.storeItem.categoryName == "FARMHOUSES" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("farmHouses")) - 1 or 1
    infoText = g_i18n:getText("rc_max_farmhouses")
  elseif self.storeItem.categoryName == "GENERATORS" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("generators")) - 1 or 1
    infoText = g_i18n:getText("rc_max_generators")
  elseif self.storeItem.categoryName == "GARDENSHEDS" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("gardenSheds")) - 1 or 20
    infoText = g_i18n:getText("rc_max_items")
  elseif self.storeItem.categoryName == "FLOODLIGHTING" then
    maxItemCount = math.floor(g_fsgSettings.settings:getValue("floodLighting")) - 1 or 20
    infoText = g_i18n:getText("rc_max_lights")
  elseif self.storeItem.categoryName == "PLACEABLEMISC" then
    if string.find(self.storeItem.rawXMLFilename:lower(), "greenhouses") then
      maxItemCount = math.floor(g_fsgSettings.settings:getValue("placeableGreenhouses")) - 1 or 1
      infoText = g_i18n:getText("rc_max_greenhouses")
    end
  end

  -- Checks to see if brand is fsg-coop and only allows admins to place
  rcDebug("Store Item XML Filename")
  rcDebug(self.storeItem.rawXMLFilename)
  if self.storeItem.rawXMLFilename == "fsgCoopInbound.xml" 
    or self.storeItem.rawXMLFilename == "fsgCoopOutbound.xml" 
    or self.storeItem.rawXMLFilename == "fsgCoopInboundObjects.xml"
    
    -- Block easy money stuff
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/electricityGenerators/level05/electricityGenerator05.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/productionPointsGeneric/stoneQuarry/stoneQuarry.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/mapEU/cementFactoryEU/cementFactoryPlaceable.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/productionPointsSmall/cementFactory/cementFactory.xml"

    -- Block Selling Stations US
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/farmerKioskBig/farmerKioskBig.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/mapUS/farmersMarketUS/farmersMarketUS.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/farmerKioskSmall/farmerKioskSmall.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/sellingStationGeneric/debrisCrusher/debrisCrusher.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/productionPointsSmall/biomassHeatingPlant/biomassHeatingPlant.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/mapEU/pianoFactory/pianoFactoryPlaceable.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/productionPointsSmall/debrisCrusher/debrisCrusher.xml"
    or self.storeItem.rawXMLFilename == "$data/placeables/brandless/productionPointsGeneric/biomassHeatingPlant/biomassHeatingPlant.xml"
    

  then
      -- Make sure we are on server and user is master before allowing 
      rcDebug("Checking to make sure user is on server and master user.")
      if g_currentMission:getIsServer() or g_currentMission.isMasterUser then
        return true
      else
        infoText = g_i18n:getText("rc_admin_only_place")
        return false, infoText
      end
  end

  -- Checks to see how many of the selected item are already placed
	if g_currentMission:getNumOfItems(storeItem, g_currentMission:getFarmId()) < maxItemCount then
		return true
	end

	return false, infoText
end

-- Disable the buy farmland button
function Limits:setMapInputContext(enterVehicle, resetVehicle, sellVehicle, visitPlace, setMarker, removeMarker, buy, sell, manage)
  self.contextActions[InGameMenuMapFrame.ACTIONS.BUY].isActive = false
  self.contextActions[InGameMenuMapFrame.ACTIONS.SELL].isActive = false
  self:updateContextInputBarVisibility()
end

-- Disables farmland buy sell
function Limits:blockFarmland()
	-- Do nothing
end


-- Disable map productions
function Limits:loadItem(super, rawXMLFilename, baseDir, customEnvironment, isMod, isBundleItem, dlcTitle, extraContentId, ignoreAdd)

  local mapStoreItem = false
  local placeableStoreItem = false

  -- If you don't want custom map items to be loaded with custom maps add them here.
  if 
    customEnvironment == "FS25_CustomMapName" or 
    customEnvironment == "FS25_AnotherCustomMapName"
  then
    mapStoreItem = true
  end

	local xmlFilename = Utils.getFilename(rawXMLFilename, baseDir)
	local xmlFile = loadXMLFile("storeItemXML", xmlFilename)

	if xmlFile == 0 then
		return nil
	end

	local baseXMLName = getXMLRootName(xmlFile)
	local storeDataXMLKey = baseXMLName .. ".storeData"
	local species = getXMLString(xmlFile, storeDataXMLKey .. ".species") or "vehicle"
	local xmlSchema = nil

	if species == "vehicle" then
		xmlSchema = Vehicle.xmlSchema
	elseif species == "handTool" then
		xmlSchema = HandTool.xmlSchema
	elseif species == "placeable" then
		xmlSchema = Placeable.xmlSchema
    placeableStoreItem = true
	end

	if xmlSchema ~= nil then
		delete(xmlFile)

		xmlFile = XMLFile.load("storeManagerLoadItemXml", xmlFilename, xmlSchema)
	else
		Logging.xmlError(xmlFile, "Unable to get xml schema for species '%s' in '%s'", species, xmlFilename)

		return nil
	end

	local xmlName = Utils.getFilenameInfo(xmlFilename, true)

	if xmlName:sub(1, 1) ~= xmlName:sub(1, 1):lower() then
		Logging.xmlDevWarning(xmlFile, "Filename is starting with upper case character. Please follow the lower camel case naming convention.")
	end

	if tonumber(xmlName:sub(1, 1)) ~= nil then
		Logging.xmlDevWarning(xmlFile, "Filename is starting with a number. Please start always with a character.")
	end

	local xmlPathPaths = xmlFilename:split("/")
	local numParts = #xmlPathPaths

	if numParts >= 4 and xmlPathPaths[numParts - 3] == "vehicles" and string.startsWith(xmlPathPaths[numParts]:lower(), xmlPathPaths[numParts - 2]:lower()) then
		Logging.xmlDevWarning(xmlFile, "Vehicle filename '%s' starts with brand name '%s'.", xmlName, xmlPathPaths[numParts - 2])
	end

	if not xmlFile:hasProperty(storeDataXMLKey) then
		Logging.xmlError(xmlFile, "No storeData found. StoreItem will be ignored!")
		xmlFile:delete()

		return nil
	end

	local isValid = true
	local name = xmlFile:getValue(storeDataXMLKey .. ".name", nil, customEnvironment, true)

	if name == nil then
		Logging.xmlWarning(xmlFile, "Name missing for storeitem. Ignoring store item!")

		isValid = false
	end

	if name ~= nil then
		local params = xmlFile:getValue(storeDataXMLKey .. ".name#params")

		if params ~= nil then
			params = params:split("|")

			for i = 1, #params do
				params[i] = g_i18n:convertText(params[i], customEnvironment)
			end

			name = string.format(name, unpack(params))
		end
	end

	local imageFilename = xmlFile:getValue(storeDataXMLKey .. ".image", "")

	if imageFilename == "" then
		imageFilename = nil
	end

	if imageFilename == nil and xmlFile:getValue(storeDataXMLKey .. ".showInStore", true) then
		Logging.xmlWarning(xmlFile, "Image icon is missing for storeitem. Ignoring store item!")

		isValid = false
	end

	if not isValid then
		xmlFile:delete()

		return nil
	end

	local storeItem = {
		name = name,
		extraContentId = extraContentId,
		rawXMLFilename = rawXMLFilename,
		baseDir = baseDir,
		xmlSchema = xmlSchema,
		xmlFilename = xmlFilename,
		xmlFilenameLower = xmlFilename:lower(),
		imageFilename = imageFilename and Utils.getFilename(imageFilename, baseDir),
		species = species,
		functions = StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLKey, customEnvironment),
		specs = nil,
		brandIndex = StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey),
		brandNameRaw = xmlFile:getValue(storeDataXMLKey .. ".brand", ""),
		customBrandIcon = xmlFile:getValue(storeDataXMLKey .. ".brand#customIcon"),
		customBrandIconOffset = xmlFile:getValue(storeDataXMLKey .. ".brand#imageOffset")
	}

	if storeItem.customBrandIcon ~= nil then
		storeItem.customBrandIcon = Utils.getFilename(storeItem.customBrandIcon, baseDir)
	end

	storeItem.isBundleItem = isBundleItem
	storeItem.allowLeasing = xmlFile:getValue(storeDataXMLKey .. ".allowLeasing", true)
	storeItem.maxItemCount = xmlFile:getValue(storeDataXMLKey .. ".maxItemCount")
	storeItem.rotation = xmlFile:getValue(storeDataXMLKey .. ".rotation", 0)
	storeItem.shopDynamicTitle = xmlFile:getValue(storeDataXMLKey .. ".shopDynamicTitle", false)
	storeItem.shopTranslationOffset = xmlFile:getValue(storeDataXMLKey .. ".shopTranslationOffset", nil, true)
	storeItem.shopRotationOffset = xmlFile:getValue(storeDataXMLKey .. ".shopRotationOffset", nil, true)
	storeItem.shopIgnoreLastComponentPositions = xmlFile:getValue(storeDataXMLKey .. ".shopIgnoreLastComponentPositions", false)
	storeItem.shopInitialLoadingDelay = xmlFile:getValue(storeDataXMLKey .. ".shopLoadingDelay#initial")
	storeItem.shopConfigLoadingDelay = xmlFile:getValue(storeDataXMLKey .. ".shopLoadingDelay#config")
	storeItem.shopHeight = xmlFile:getValue(storeDataXMLKey .. ".shopHeight", 0)
	storeItem.financeCategory = xmlFile:getValue(storeDataXMLKey .. ".financeCategory")
	storeItem.shopFoldingState = xmlFile:getValue(storeDataXMLKey .. ".shopFoldingState", 0)
	storeItem.shopFoldingTime = xmlFile:getValue(storeDataXMLKey .. ".shopFoldingTime")
	local sharedVramUsage, perInstanceVramUsage, ignoreVramUsage = StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLKey)

	for _, func in ipairs(self.vramUsageFunctions) do
		local customSharedVramUsage, customPerInstanceVramUsage = func(xmlFile)
		sharedVramUsage = sharedVramUsage + customSharedVramUsage
		perInstanceVramUsage = perInstanceVramUsage + customPerInstanceVramUsage
	end

	storeItem.ignoreVramUsage = ignoreVramUsage
	storeItem.perInstanceVramUsage = perInstanceVramUsage
	storeItem.sharedVramUsage = sharedVramUsage
	storeItem.dlcTitle = dlcTitle
	storeItem.isMod = isMod
	storeItem.customEnvironment = customEnvironment
	storeItem.categoryNames = {}
	local categoryName = xmlFile:getValue(storeDataXMLKey .. ".category")
	local categoryNames = categoryName:split(" ")

	for i = 1, #categoryNames do
		local category = self:getCategoryByName(categoryNames[i])

		if category == nil then
			Logging.xmlWarning(xmlFile, "Invalid category '%s' in store data!", tostring(categoryNames[i]))
		end

		table.insert(storeItem.categoryNames, category.name)
	end

	if #storeItem.categoryNames == 0 then
		Logging.xmlWarning(xmlFile, "No categories defined in store data! Using 'misc' instead!")
		table.insert(storeItem.categoryNames, "MISC")
	end

	storeItem.categoryName = storeItem.categoryNames[1]

  -- Added check to see if map placeable and if so then make sell and show store false
  if mapStoreItem and placeableStoreItem and storeItem.categoryName == "productionPoints" then
  	storeItem.canBeSold = false
    storeItem.showInStore = false
  else
    storeItem.canBeSold = xmlFile:getValue(storeDataXMLKey .. ".canBeSold", true)
    storeItem.showInStore = xmlFile:getValue(storeDataXMLKey .. ".showInStore", not isBundleItem)
  end

	if species == "vehicle" then
		storeItem.configurations, storeItem.defaultConfigurationIds = StoreItemUtil.getConfigurationsFromXML(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, storeItem)
		storeItem.subConfigurations = StoreItemUtil.getSubConfigurationsFromXML(storeItem.configurations)
		storeItem.configurationSets = StoreItemUtil.getConfigurationSetsFromXML(storeItem, xmlFile, baseXMLName, baseDir, customEnvironment, isMod)
		storeItem.hasLicensePlates = xmlFile:hasProperty("vehicle.licensePlates.licensePlate(0)")
	end

	storeItem.price = xmlFile:getValue(storeDataXMLKey .. ".price", 0)

	if storeItem.price < 0 then
		Logging.xmlWarning(xmlFile, "Price has to be greater than 0. Using default 10.000 instead!")

		storeItem.price = 10000
	end

	storeItem.dailyUpkeep = xmlFile:getValue(storeDataXMLKey .. ".dailyUpkeep", 0)
	storeItem.runningLeasingFactor = xmlFile:getValue(storeDataXMLKey .. ".runningLeasingFactor", EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
	storeItem.lifetime = xmlFile:getValue(storeDataXMLKey .. ".lifetime", 600)

	xmlFile:iterate("handTool.storeData.storePacks.storePack", function (_, key)
		local packName = xmlFile:getValue(key)

		self:addPackItem(packName, xmlFilename)
	end)
	xmlFile:iterate("vehicle.storeData.storePacks.storePack", function (_, key)
		local packName = xmlFile:getValue(key)

		self:addPackItem(packName, xmlFilename)
	end)

	local bundleItemsToAdd = {}

	if xmlFile:hasProperty(storeDataXMLKey .. ".bundleElements") then
		local bundleInfo = {
			bundleItems = {},
			attacherInfo = {}
		}
		local price = 0
		local lifetime = math.huge
		local dailyUpkeep = 0
		local runningLeasingFactor = 0
		local i = 0

		while true do
			local bundleKey = string.format(storeDataXMLKey .. ".bundleElements.bundleElement(%d)", i)

			if not xmlFile:hasProperty(bundleKey) then
				break
			end

			local bundleXmlFile = xmlFile:getValue(bundleKey .. ".xmlFilename")
			local offset = xmlFile:getValue(bundleKey .. ".offset", "0 0 0", true)
			local rotationOffset = xmlFile:getValue(bundleKey .. ".rotationOffset", "0 0 0", true)
			local rotation = xmlFile:getValue(bundleKey .. ".yRotation", 0)
			rotationOffset[2] = rotationOffset[2] + rotation

			if bundleXmlFile ~= nil then
				local completePath = Utils.getFilename(bundleXmlFile, baseDir)
				local item = self:getItemByXMLFilename(completePath)

				if item == nil then
					item = self:loadItem(bundleXmlFile, baseDir, customEnvironment, isMod, true, dlcTitle, nil, true)

					table.insert(bundleItemsToAdd, item)
				end

				if item ~= nil then
					price = price + item.price
					dailyUpkeep = dailyUpkeep + item.dailyUpkeep
					runningLeasingFactor = runningLeasingFactor + item.runningLeasingFactor
					lifetime = math.min(lifetime, item.lifetime)

					if item.configurations ~= nil then
						storeItem.configurations = storeItem.configurations or {}

						for configName, configOptions in pairs(item.configurations) do
							if storeItem.configurations[configName] ~= nil then
								local itemConfigOptions = storeItem.configurations[configName]

								for j = 1, #configOptions do
									if itemConfigOptions[j] == nil then
										itemConfigOptions[j] = configOptions[j]
									else
										itemConfigOptions[j].price = itemConfigOptions[j].price + configOptions[j].price
									end
								end
							else
								storeItem.configurations[configName] = table.copy(configOptions, math.huge)
							end
						end
					end

					if item.defaultConfigurationIds ~= nil then
						storeItem.defaultConfigurationIds = storeItem.defaultConfigurationIds or {}
					end

					if item.subConfigurations ~= nil then
						storeItem.subConfigurations = storeItem.subConfigurations or {}

						for configName, configOptions in pairs(item.subConfigurations) do
							storeItem.subConfigurations[configName] = configOptions
						end
					end

					if item.configurationSets ~= nil then
						storeItem.configurationSets = storeItem.configurationSets or {}

						for configName, configOptions in pairs(item.configurationSets) do
							storeItem.configurationSets[configName] = configOptions
						end
					end

					local preSelectedConfigurations = {}

					xmlFile:iterate(bundleKey .. ".configurations.configuration", function (_, configKey)
						local configName = xmlFile:getValue(configKey .. "#name")
						local configValue = xmlFile:getValue(configKey .. "#value")

						if configName ~= nil and configValue ~= nil then
							local allowChange = xmlFile:getValue(configKey .. "#allowChange", false)
							local hideOption = xmlFile:getValue(configKey .. "#hideOption", false)
							local disableOption = xmlFile:getValue(configKey .. "#disableOption", false)

							if not disableOption then
								preSelectedConfigurations[configName] = {
									configValue = configValue,
									allowChange = allowChange,
									hideOption = hideOption
								}
							else
								local configElements = storeItem.configurations[configName]

								if configElements ~= nil then
									for j = 1, #configElements do
										if j == configValue then
											configElements[j].isSelectable = not configElements[j].isSelectable
										end
									end
								end
							end
						end
					end)

					storeItem.hasLicensePlates = storeItem.hasLicensePlates or item.hasLicensePlates

					table.insert(bundleInfo.bundleItems, {
						rotation = 0,
						item = item,
						xmlFilename = item.xmlFilename,
						offset = offset,
						rotationOffset = rotationOffset,
						price = item.price,
						preSelectedConfigurations = preSelectedConfigurations
					})
				end
			end

			i = i + 1
		end

		i = 0

		while true do
			local attachKey = string.format(storeDataXMLKey .. ".attacherInfo.attach(%d)", i)

			if not xmlFile:hasProperty(attachKey) then
				break
			end

			local bundleElement0 = xmlFile:getValue(attachKey .. "#bundleElement0")
			local bundleElement1 = xmlFile:getValue(attachKey .. "#bundleElement1")
			local attacherJointIndex = xmlFile:getValue(attachKey .. "#attacherJointIndex")
			local inputAttacherJointIndex = xmlFile:getValue(attachKey .. "#inputAttacherJointIndex")

			if bundleElement0 ~= nil and bundleElement1 ~= nil and attacherJointIndex ~= nil and inputAttacherJointIndex ~= nil then
				table.insert(bundleInfo.attacherInfo, {
					bundleElement0 = bundleElement0,
					bundleElement1 = bundleElement1,
					attacherJointIndex = attacherJointIndex,
					inputAttacherJointIndex = inputAttacherJointIndex
				})
			end

			i = i + 1
		end

		storeItem.price = price
		storeItem.dailyUpkeep = dailyUpkeep
		storeItem.runningLeasingFactor = runningLeasingFactor
		storeItem.lifetime = lifetime
		storeItem.bundleInfo = bundleInfo
	end

	if xmlFile:hasProperty(storeDataXMLKey .. ".brush") and storeItem.showInStore then
		local brushType = xmlFile:getValue(storeDataXMLKey .. ".brush.type")

		if brushType ~= nil and brushType ~= "none" then
			local parameters = {}

			xmlFile:iterate(storeDataXMLKey .. ".brush.parameters.parameter", function (index, key)
				local value = xmlFile:getValue(key)

				if xmlFile:getValue(key .. "#isFilename", false) then
					value = Utils.getFilename(value, baseDir)
				end

				parameters[index] = value
			end)

			local brushCategory = self:getConstructionCategoryByName(xmlFile:getValue(storeDataXMLKey .. ".brush.category"))

			if brushCategory ~= nil then
				local tab = self:getConstructionTabByName(xmlFile:getValue(storeDataXMLKey .. ".brush.tab"), brushCategory.name)

				if tab ~= nil then
					storeItem.brush = {
						type = brushType,
						parameters = parameters,
						category = brushCategory,
						tab = tab
					}
				else
					Logging.xmlWarning(xmlFile, "Missing brush tab")
				end
			else
				Logging.xmlWarning(xmlFile, "Missing brush category")
			end
		end
	elseif storeItem.species == "placeable" and storeItem.showInStore then
		storeItem.brush = {
			type = "placeable",
			parameters = {},
			category = self.constructionCategories[1],
			tab = self.constructionCategories[1].tabs[1]
		}
	end

	if not ignoreAdd then
		self:addItem(storeItem)

		for i = 1, #bundleItemsToAdd do
			self:addItem(bundleItemsToAdd[i])
		end
	end

	xmlFile:delete()

	return storeItem
end

-- Hide the borrow items button for contracts
function Limits:setButtonsForState()
  -- Check to see if contract borrow equipment disabled
  if g_fsgSettings.settings:getValue("disableBorrowEquipment") then
	  self.leaseButtonInfo.disabled = true
  end
  -- Disable the ability to cancel contracts
  self.cancelButtonInfo.disabled = true
  -- Disable the ability to accept contracts
  self.acceptButtonInfo.disabled = true
end

function Limits.actionEventPlant(self, actionName, inputValue, callbackState, isAnalog)
	local spec_treePlanter = self.spec_treePlanter
	if spec_treePlanter.hasGroundContact then
		if g_treePlantManager:canPlantTree() then
			local x, y, z = getWorldTranslation(spec_treePlanter.node)

      -- Check if current location is a field.
      if FSDensityMapUtil.getIsFieldAtWorldPos(x, z) then
        g_currentMission:showBlinkingWarning(g_i18n:getText("warning_canNotPlantOnField"))
        return
      end

			if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x, z) then
				if PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z, true) then
					g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"))
				else
					self:createTree()
				end
			else
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
				return
			end
		else
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyTrees"))
			return
		end
	else
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_treePlanterNoGroundContact"))
		return
	end
end