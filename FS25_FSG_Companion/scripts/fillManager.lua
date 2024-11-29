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

-- FS25 - Not needed as this loads the custom xmls and such.
-- Would like to come up with a better way to unify map pricing though
-- function FillManager:loadMap()
--   rcDebug("FillManger - loadMap")

--   local baseDirectory = modDirectory
--   local isBaseType = false
--   local customEnv = g_fillManager
--   local mainKey = "map"

--   local oldNumFillTypes = #g_fillTypeManager.fillTypes

--   -- load all fill types located in xml/fillTypes folder
--   local files = Files.new(modDirectory .. "xml/fillTypes/").files

--   -- Check if no folder found, then manually add them
--   if files == nil or #files == 0 then
--     files = {}
--     table.insert(files, { filename = "AIR.xml" })
--     table.insert(files, { filename = "ALFALFA.xml" })
--     table.insert(files, { filename = "ALFALFA_WINDROW.xml" })
--     table.insert(files, { filename = "ANHYDROUS.xml" })
--     table.insert(files, { filename = "BAKEDPOPPY.xml" })
--     table.insert(files, { filename = "BARLEY.xml" })
--     table.insert(files, { filename = "BEER.xml" })
--     table.insert(files, { filename = "BOARDS.xml" })
--     table.insert(files, { filename = "BREAD.xml" })
--     table.insert(files, { filename = "BULL_ANGUS.xml" })
--     table.insert(files, { filename = "BULL_HOLSTEIN.xml" })
--     table.insert(files, { filename = "BUN.xml" })
--     table.insert(files, { filename = "BUTTER.xml" })
--     table.insert(files, { filename = "CAKE.xml" })
--     table.insert(files, { filename = "CANOLA.xml" })
--     table.insert(files, { filename = "CANOLA_OIL.xml" })
--     table.insert(files, { filename = "CARDBOARD.xml" })
--     table.insert(files, { filename = "CARP.xml" })
--     table.insert(files, { filename = "CARROTJUICE.xml" })
--     table.insert(files, { filename = "CARROTSALAD.xml" })
--     table.insert(files, { filename = "CEREAL.xml" })
--     table.insert(files, { filename = "CHAFF.xml" })
--     table.insert(files, { filename = "CHEESE.xml" })
--     table.insert(files, { filename = "CHICKEN.xml" })
--     table.insert(files, { filename = "CHICKENFEED.xml" })
--     table.insert(files, { filename = "CHICKEN_ROOSTER.xml" })
--     table.insert(files, { filename = "CHIPS.xml" })
--     table.insert(files, { filename = "CHOCOLATE.xml" })
--     table.insert(files, { filename = "CHOCOLATEICECREAM.xml" })
--     table.insert(files, { filename = "CLOTHES.xml" })
--     table.insert(files, { filename = "CLOVER.xml" })
--     table.insert(files, { filename = "CLOVER_WINDROW.xml" })
--     table.insert(files, { filename = "COLESLAW.xml" })
--     table.insert(files, { filename = "COMPOST.xml" })
--     table.insert(files, { filename = "CORN_STALKS.xml" })
--     table.insert(files, { filename = "COTTON.xml" })
--     table.insert(files, { filename = "COW_ANGUS.xml" })
--     table.insert(files, { filename = "COW_HOLSTEIN.xml" })
--     table.insert(files, { filename = "COW_SWISS_BROWN.xml" })
--     table.insert(files, { filename = "CREAM.xml" })
--     table.insert(files, { filename = "DEF.xml" })
--     table.insert(files, { filename = "DIESEL.xml" })
--     table.insert(files, { filename = "DIGESTATE.xml" })
--     table.insert(files, { filename = "DRYALFALFA.xml" })
--     table.insert(files, { filename = "DRYALFALFA_WINDROW.xml" })
--     table.insert(files, { filename = "DRYCLOVER.xml" })
--     table.insert(files, { filename = "DRYCLOVER_WINDROW.xml" })
--     table.insert(files, { filename = "DRYGRASS.xml" })
--     table.insert(files, { filename = "DRYGRASS_WINDROW.xml" })
--     table.insert(files, { filename = "DUCK.xml" })
--     table.insert(files, { filename = "EGG.xml" })
--     table.insert(files, { filename = "ELECTRICCHARGE.xml" })
--     table.insert(files, { filename = "EMPTYPALLET.xml" })
--     table.insert(files, { filename = "ETHANOL.xml" })
--     table.insert(files, { filename = "FABRIC.xml" })
--     table.insert(files, { filename = "FERTILIZER.xml" })
--     table.insert(files, { filename = "FISH_FEED.xml" })
--     table.insert(files, { filename = "FISH_FLOUR.xml" })
--     table.insert(files, { filename = "FLOUR.xml" })
--     table.insert(files, { filename = "FORAGE.xml" })
--     table.insert(files, { filename = "FORAGE_MIXING.xml" })
--     table.insert(files, { filename = "FRENCHFRIES.xml" })
--     table.insert(files, { filename = "FURNITURE.xml" })
--     table.insert(files, { filename = "GOATCHEESE.xml" })
--     table.insert(files, { filename = "GOATMILK.xml" })
--     table.insert(files, { filename = "GOAT_LANDRACE.xml" })
--     table.insert(files, { filename = "GOAT_MALE.xml" })
--     table.insert(files, { filename = "GRAPE.xml" })
--     table.insert(files, { filename = "GRAPEJUICE.xml" })
--     table.insert(files, { filename = "GRASS.xml" })
--     table.insert(files, { filename = "GRASS_WINDROW.xml" })
--     table.insert(files, { filename = "GREENSALAD.xml" })
--     table.insert(files, { filename = "HERBICIDE.xml" })
--     table.insert(files, { filename = "HONEY.xml" })
--     table.insert(files, { filename = "HORSE_BAY.xml" })
--     table.insert(files, { filename = "HORSE_BLACK.xml" })
--     table.insert(files, { filename = "HORSE_CESTNUT.xml" })
--     table.insert(files, { filename = "HORSE_DUN.xml" })
--     table.insert(files, { filename = "HORSE_GRAY.xml" })
--     table.insert(files, { filename = "HORSE_PALOMINO.xml" })
--     table.insert(files, { filename = "HORSE_PINTO.xml" })
--     table.insert(files, { filename = "HORSE_SEAL_BROWN.xml" })
--     table.insert(files, { filename = "LETTUCE.xml" })
--     table.insert(files, { filename = "LIME.xml" })
--     table.insert(files, { filename = "LIQUIDFERTILIZER.xml" })
--     table.insert(files, { filename = "LIQUIDMANURE.xml" })
--     table.insert(files, { filename = "MAIZE.xml" })
--     table.insert(files, { filename = "MAIZE2.xml" })
--     table.insert(files, { filename = "MANURE.xml" })
--     table.insert(files, { filename = "MASHEDPOTATO.xml" })
--     table.insert(files, { filename = "MEADOW.xml" })
--     table.insert(files, { filename = "METHANE.xml" })
--     table.insert(files, { filename = "MILK.xml" })
--     table.insert(files, { filename = "MINERAL_FEED.xml" })
--     table.insert(files, { filename = "OAT.xml" })
--     table.insert(files, { filename = "OATDRINK.xml" })
--     table.insert(files, { filename = "OATMEAL.xml" })
--     table.insert(files, { filename = "OILSEEDRADISH.xml" })
--     table.insert(files, { filename = "OLIVE.xml" })
--     table.insert(files, { filename = "OLIVE_OIL.xml" })
--     table.insert(files, { filename = "ONION.xml" })
--     table.insert(files, { filename = "ONIONJUICE.xml" })
--     table.insert(files, { filename = "PASTA.xml" })
--     table.insert(files, { filename = "PIGFOOD.xml" })
--     table.insert(files, { filename = "PIG_BERKSHIRE.xml" })
--     table.insert(files, { filename = "PIG_BLACK_PIED.xml" })
--     table.insert(files, { filename = "PIG_GERMANPIG.xml" })
--     table.insert(files, { filename = "PIG_LANDRACE.xml" })
--     table.insert(files, { filename = "PIKE.xml" })
--     table.insert(files, { filename = "PIZZA.xml" })
--     table.insert(files, { filename = "POMACE.xml" })
--     table.insert(files, { filename = "POPCORN.xml" })
--     table.insert(files, { filename = "POPLAR.xml" })
--     table.insert(files, { filename = "POPPY.xml" })
--     table.insert(files, { filename = "POPPYSEEDBUN.xml" })
--     table.insert(files, { filename = "POTATO.xml" })
--     table.insert(files, { filename = "POTATOPANCAKE.xml" })
--     table.insert(files, { filename = "POTATOSALAD.xml" })
--     table.insert(files, { filename = "PRALINE.xml" })
--     table.insert(files, { filename = "PROPANE.xml" })
--     table.insert(files, { filename = "RAISINS.xml" })
--     table.insert(files, { filename = "REDCABBAGE.xml" })
--     table.insert(files, { filename = "ROADSALT.xml" })
--     table.insert(files, { filename = "ROUNDBALE.xml" })
--     table.insert(files, { filename = "ROUNDBALE_COTTON.xml" })
--     table.insert(files, { filename = "ROUNDBALE_DRYGRASS.xml" })
--     table.insert(files, { filename = "ROUNDBALE_GRASS.xml" })
--     table.insert(files, { filename = "ROUNDBALE_WOOD.xml" })
--     table.insert(files, { filename = "RYE.xml" })
--     table.insert(files, { filename = "SALMON.xml" })
--     table.insert(files, { filename = "SALT.xml" })
--     table.insert(files, { filename = "SEEDS.xml" })
--     table.insert(files, { filename = "SHEEP_BLACK_WELSH.xml" })
--     table.insert(files, { filename = "SHEEP_LANDRACE.xml" })
--     table.insert(files, { filename = "SHEEP_RAM.xml" })
--     table.insert(files, { filename = "SHEEP_STEINSCHAF.xml" })
--     table.insert(files, { filename = "SHEEP_SWISS_MOUNTAIN.xml" })
--     table.insert(files, { filename = "SILAGE.xml" })
--     table.insert(files, { filename = "SILAGE_ADDITIVE.xml" })
--     table.insert(files, { filename = "SNOW.xml" })
--     table.insert(files, { filename = "SODIUMCHLORID.xml" })
--     table.insert(files, { filename = "SORGHUM.xml" })
--     table.insert(files, { filename = "SOYBEAN.xml" })
--     table.insert(files, { filename = "SOYBEANSTRAW.xml" })
--     table.insert(files, { filename = "SOYDRINK.xml" })
--     table.insert(files, { filename = "SOYMILK.xml" })
--     table.insert(files, { filename = "SOY_FLOUR.xml" })
--     table.insert(files, { filename = "SPAGHETTI.xml" })
--     table.insert(files, { filename = "SPELT.xml" })
--     table.insert(files, { filename = "SQUAREBALE.xml" })
--     table.insert(files, { filename = "SQUAREBALE_COTTON.xml" })
--     table.insert(files, { filename = "SQUAREBALE_DRYGRASS.xml" })
--     table.insert(files, { filename = "SQUAREBALE_GRASS.xml" })
--     table.insert(files, { filename = "SQUAREBALE_WOOD.xml" })
--     table.insert(files, { filename = "STONE.xml" })
--     table.insert(files, { filename = "STRAW.xml" })
--     table.insert(files, { filename = "STRAWBERRY.xml" })
--     table.insert(files, { filename = "STRAWBERRYCREAMCAKE.xml" })
--     table.insert(files, { filename = "STRAWBERRYICECREAM.xml" })
--     table.insert(files, { filename = "STRAWBERRYJUICE.xml" })
--     table.insert(files, { filename = "SUGAR.xml" })
--     table.insert(files, { filename = "SUGARBEET.xml" })
--     table.insert(files, { filename = "SUGARBEET_CUT.xml" })
--     table.insert(files, { filename = "SUGARCANE.xml" })
--     table.insert(files, { filename = "SUN.xml" })
--     table.insert(files, { filename = "SUNFLOWER.xml" })
--     table.insert(files, { filename = "SUNFLOWER_OIL.xml" })
--     table.insert(files, { filename = "TARP.xml" })
--     table.insert(files, { filename = "TOMATO.xml" })
--     table.insert(files, { filename = "TOMATOJUICE.xml" })
--     table.insert(files, { filename = "TOMATOSALAD.xml" })
--     table.insert(files, { filename = "TREESAPLINGS.xml" })
--     table.insert(files, { filename = "VINEGAR.xml" })
--     table.insert(files, { filename = "VITAMINS.xml" })
--     table.insert(files, { filename = "WATER.xml" })
--     table.insert(files, { filename = "WEED.xml" })
--     table.insert(files, { filename = "WHEAT.xml" })
--     table.insert(files, { filename = "WHEATSEMOLINA.xml" })
--     table.insert(files, { filename = "WHISKEY.xml" })
--     table.insert(files, { filename = "WHITECABBAGE.xml" })
--     table.insert(files, { filename = "WIND.xml" })
--     table.insert(files, { filename = "WINE.xml" })
--     table.insert(files, { filename = "WOOD.xml" })
--     table.insert(files, { filename = "WOODCHIPS.xml" })
--     table.insert(files, { filename = "WOOL.xml" })
--   end

--   FillManager:loadFillTypes(files, baseDirectory, customEnv, isBaseType, mainKey)

--   -- Load the fill type categories file
--   local xmlFile = XMLFile.load(mainKey, Utils.getFilename("xml/fillTypeCategories.xml", modDirectory), FillTypeManager.xmlSchema)

-- 	xmlFile:iterate(mainKey .. ".fillTypeCategories.fillTypeCategory", function (_, key)
-- 		local name = xmlFile:getValue(key .. "#name")
-- 		local fillTypesStr = xmlFile:getValue(key) or ""
--     rcDebug("Add Fill Type Category: " .. name)
-- 		local fillTypeCategoryIndex = g_fillTypeManager:addFillTypeCategory(name, isBaseType)

-- 		if fillTypeCategoryIndex ~= nil then
-- 			local fillTypeNames = fillTypesStr:split(" ")

-- 			for _, fillTypeName in ipairs(fillTypeNames) do
-- 				local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

-- 				if fillType ~= nil then
-- 					if not g_fillTypeManager:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
-- 						Logging.warning("Could not add fillType '" .. tostring(fillTypeName) .. "' to fillTypeCategory '" .. tostring(name) .. "'!")
-- 					end
-- 				else
-- 					Logging.warning("Unknown FillType '" .. tostring(fillTypeName) .. "' in fillTypeCategory '" .. tostring(name) .. "'!")
-- 				end
-- 			end
-- 		end
-- 	end)

--   xmlFile:delete()

--   -- Load the fill type converter file
--   local xmlFile = XMLFile.load(mainKey, Utils.getFilename("xml/fillTypeConverters.xml", modDirectory), FillTypeManager.xmlSchema)

-- 	xmlFile:iterate(mainKey .. ".fillTypeConverters.fillTypeConverter", function (_, key)
-- 		local name = xmlFile:getValue(key .. "#name")
--     rcDebug("Add Fill Type Converter: " .. name)
-- 		local converter = g_fillTypeManager:addFillTypeConverter(name, isBaseType)

-- 		if converter ~= nil then
-- 			xmlFile:iterate(key .. ".converter", function (_, converterKey)
-- 				local from = xmlFile:getValue(converterKey .. "#from")
-- 				local to = xmlFile:getValue(converterKey .. "#to")
-- 				local factor = xmlFile:getValue(converterKey .. "#factor")
-- 				local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
-- 				local targetFillType = g_fillTypeManager:getFillTypeByName(to)

-- 				if sourceFillType ~= nil and targetFillType ~= nil and factor ~= nil then
-- 					g_fillTypeManager:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
-- 				end
-- 			end)
-- 		end
-- 	end)

--   xmlFile:delete()

--   -- Load the fill type converter file
--   local xmlFile = XMLFile.load(mainKey, Utils.getFilename("xml/fillTypeSounds.xml", modDirectory), FillTypeManager.xmlSchema)
  
--   rcDebug("Add Fill Type Sounds")
-- 	xmlFile:iterate(mainKey .. ".fillTypeSounds.fillTypeSound", function (_, key)
-- 		local sample = g_soundManager:loadSampleFromXML(xmlFile, key, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)

-- 		if sample ~= nil then
-- 			local entry = {
-- 				sample = sample,
-- 				fillTypes = {}
-- 			}
-- 			local fillTypesStr = xmlFile:getValue(key .. "#fillTypes") or ""

-- 			if fillTypesStr ~= nil then
-- 				local fillTypeNames = fillTypesStr:split(" ")

-- 				for _, fillTypeName in ipairs(fillTypeNames) do
-- 					local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

-- 					if fillType ~= nil then
-- 						table.insert(entry.fillTypes, fillType)
--             rcDebug("Add Fill Type Sound: " .. fillTypeName)
-- 						g_fillTypeManager.fillTypeToSample[fillType] = sample
-- 					else
-- 						Logging.warning("Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, key)
-- 					end
-- 				end
-- 			end

-- 			if xmlFile:getValue(key .. "#isDefault") then
-- 				for fillType, _ in ipairs(g_fillTypeManager.fillTypes) do
-- 					if g_fillTypeManager.fillTypeToSample[fillType] == nil then
-- 						g_fillTypeManager.fillTypeToSample[fillType] = sample
-- 					end
-- 				end
-- 			end

-- 			table.insert(g_fillTypeManager.fillTypeSamples, entry)
-- 		end
-- 	end)

--   xmlFile:delete()

--   rcDebug("Prev Num Fill Types: " .. oldNumFillTypes)
--   rcDebug("New Num Fill Types: " .. #g_fillTypeManager.fillTypes)

-- 	if #g_fillTypeManager.fillTypes ~= oldNumFillTypes then
-- 		g_fillTypeManager:constructFillTypeTextureArrays()
-- 	end

--   rcDebug("Load Map FruitTypes")
--   local xmlFile = loadXMLFile("fuitTypes", Utils.getFilename("xml/maps_fruitTypes.xml", modDirectory))
  
--   --g_fruitTypeManager:loadFruitTypes(xmlFile,self.mission.missionInfo,false)

-- 	local rootName = getXMLRootName(xmlFile)
-- 	local i = 0

-- 	while true do
-- 		local key = string.format("%s.fruitTypes.fruitType(%d)", rootName, i)

-- 		if not hasXMLProperty(xmlFile, key) then
-- 			break
-- 		end

-- 		local name = getXMLString(xmlFile, key .. "#name")
-- 		local shownOnMap = getXMLBool(xmlFile, key .. "#shownOnMap")
-- 		local useForFieldJob = getXMLBool(xmlFile, key .. "#useForFieldJob")
-- 		local missionMultiplier = getXMLFloat(xmlFile, key .. "#missionMultiplier")
--     rcDebug("Add Fruit Type: " .. name)
-- 		local fruitType = g_fruitTypeManager:addFruitType(name, shownOnMap, useForFieldJob, missionMultiplier, isBaseType)

-- 		if fruitType ~= nil then
-- 			local success = true
-- 			success = success and g_fruitTypeManager:loadFruitTypeGeneral(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeWindrow(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeGrowth(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeHarvest(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeCultivation(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypePreparing(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeCropCare(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeOptions(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeMapColors(fruitType, xmlFile, key)
-- 			success = success and g_fruitTypeManager:loadFruitTypeDestruction(fruitType, xmlFile, key)

-- 			if success and g_fruitTypeManager.indexToFruitType[fruitType.index] == nil then
-- 				local maxNumFruitTypes = 2^FruitTypeManager.SEND_NUM_BITS - 1

-- 				if maxNumFruitTypes <= #g_fruitTypeManager.fruitTypes then
-- 					Logging.error("FruitTypeManager.loadFruitTypes too many fruit types. Only %d fruit types are supported", maxNumFruitTypes)

-- 					return
-- 				end

-- 				table.insert(g_fruitTypeManager.fruitTypes, fruitType)

-- 				g_fruitTypeManager.nameToFruitType[fruitType.name] = fruitType
-- 				g_fruitTypeManager.nameToIndex[fruitType.name] = fruitType.index
-- 				g_fruitTypeManager.indexToFruitType[fruitType.index] = fruitType
-- 				g_fruitTypeManager.fillTypeIndexToFruitTypeIndex[fruitType.fillType.index] = fruitType.index
-- 				g_fruitTypeManager.fruitTypeIndexToFillType[fruitType.index] = fruitType.fillType
-- 			end
-- 		end

-- 		i = i + 1
-- 	end

-- 	i = 0

-- 	while true do
-- 		local key = string.format("%s.fruitTypeCategories.fruitTypeCategory(%d)", rootName, i)

-- 		if not hasXMLProperty(xmlFile, key) then
-- 			break
-- 		end

-- 		local name = getXMLString(xmlFile, key .. "#name")
-- 		local fruitTypesStr = getXMLString(xmlFile, key)
-- 		local fruitTypeCategoryIndex = g_fruitTypeManager:addFruitTypeCategory(name, isBaseType)

-- 		if fruitTypeCategoryIndex ~= nil then
-- 			local fruitTypeNames = string.split(fruitTypesStr, " ")

-- 			for _, fruitTypeName in ipairs(fruitTypeNames) do
-- 				local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)

--         rcDebug("Add Fruit to Category: " .. fruitTypeName)

-- 				if fruitType ~= nil then
-- 					if not g_fruitTypeManager:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
-- 						print("Warning: Could not add fruitType '" .. tostring(fruitTypeName) .. "' to fruitTypeCategory '" .. tostring(name) .. "'!")
-- 					end
-- 				else
-- 					print("Warning: FruitType '" .. tostring(fruitTypeName) .. "' referenced in fruitTypeCategory '" .. tostring(name) .. "' is not defined!")
-- 				end
-- 			end
-- 		end

-- 		i = i + 1
-- 	end

-- 	i = 0

-- 	while true do
-- 		local key = string.format("%s.fruitTypeConverters.fruitTypeConverter(%d)", rootName, i)

-- 		if not hasXMLProperty(xmlFile, key) then
-- 			break
-- 		end

-- 		local name = getXMLString(xmlFile, key .. "#name")
-- 		local converter = g_fruitTypeManager:addFruitTypeConverter(name, isBaseType)

-- 		if converter ~= nil then
-- 			local j = 0

-- 			while true do
-- 				local converterKey = string.format("%s.converter(%d)", key, j)

-- 				if not hasXMLProperty(xmlFile, converterKey) then
-- 					break
-- 				end

-- 				local from = getXMLString(xmlFile, converterKey .. "#from")
-- 				local to = getXMLString(xmlFile, converterKey .. "#to")
-- 				local factor = getXMLFloat(xmlFile, converterKey .. "#factor")
-- 				local windrowFactor = getXMLFloat(xmlFile, converterKey .. "#windrowFactor")
-- 				local fruitType = g_fruitTypeManager:getFruitTypeByName(from)
-- 				local fillType = g_fillTypeManager:getFillTypeByName(to)

-- 				if fruitType ~= nil and fillType ~= nil and factor ~= nil then
--           rcDebug("Adding Fruit Type Conversion: " .. from .. " > " .. to)
-- 					g_fruitTypeManager:addFruitTypeConversion(converter, fruitType.index, fillType.index, factor, windrowFactor)
-- 				end

-- 				j = j + 1
-- 			end
-- 		end

-- 		i = i + 1
-- 	end

--   delete(xmlFile)

--   rcDebug("Load Map Density Height Types")

--   -- Load up the desnsity map height types
--   local xmlFile = loadXMLFile("heightTypes", Utils.getFilename("xml/maps_densityMapHeightTypes.xml", modDirectory))

-- 	local rootName = getXMLRootName(xmlFile)
-- 	g_densityMapHeightManager.heightTypeFirstChannel = getXMLInt(xmlFile, rootName .. ".densityMapHeightTypes#firstChannel") or g_densityMapHeightManager.heightTypeFirstChannel or 0
-- 	g_densityMapHeightManager.heightTypeNumChannels = getXMLInt(xmlFile, rootName .. ".densityMapHeightTypes#numChannels") or g_densityMapHeightManager.heightTypeNumChannels or 6
-- 	local i = 0

-- 	while true do
-- 		local key = string.format("%s.densityMapHeightTypes.densityMapHeightType(%d)", rootName, i)

-- 		if not hasXMLProperty(xmlFile, key) then
-- 			break
-- 		end

-- 		local fillTypeName = getXMLString(xmlFile, key .. "#fillTypeName")
-- 		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

-- 		if fillTypeIndex == nil then
-- 			Logging.xmlError(xmlFile, "'%s' has invalid fill type '%s'!", key, fillTypeName)

-- 			return
-- 		end

-- 		local heightType = g_densityMapHeightManager.fillTypeNameToHeightType[fillTypeName] or {}
-- 		local maxAngle = getXMLFloat(xmlFile, key .. "#maxSurfaceAngle")
-- 		local maxSurfaceAngle = heightType.maxSurfaceAngle or math.rad(26)

-- 		if maxAngle ~= nil then
-- 			maxSurfaceAngle = math.rad(maxAngle)
-- 		end

-- 		local fillToGroundScale = getXMLFloat(xmlFile, key .. "#fillToGroundScale") or heightType.fillToGroundScale or 1
-- 		local allowsSmoothing = Utils.getNoNil(Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowsSmoothing"), heightType.allowsSmoothing), false)
-- 		local collisionScale = getXMLFloat(xmlFile, key .. ".collision#scale") or heightType.collisionScale or 1
-- 		local collisionBaseOffset = getXMLFloat(xmlFile, key .. ".collision#baseOffset") or heightType.collisionBaseOffset or 0
-- 		local minCollisionOffset = getXMLFloat(xmlFile, key .. ".collision#minOffset") or heightType.minCollisionOffset or 0
-- 		local maxCollisionOffset = getXMLFloat(xmlFile, key .. ".collision#maxOffset") or heightType.maxCollisionOffset or 1

--     rcDebug('Adding Density Map Height Type: ' .. fillTypeName)
-- 		g_densityMapHeightManager:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, isBaseType)

-- 		i = i + 1
-- 	end

--   delete(xmlFile)

--   -- Load custom bales
--   FillManager:loadBales()

--   -- Load custom animal food
--   FillManager:loadMapDataAnimalFood()

--   -- Load custom motion effects
--   FillManager:loadMotionPathEffects()

-- end 

function FillManager:loadMod()
  rcDebug("Add New Foliage Types to Game")
  -- load all foliage types that are located in xml/foliage folder
  rcDebug("modDirectory")
  rcDebug(modDirectory)
  local files = Files.new(modDirectory .. "xml/foliage/").files
  local gameBaseFoliagePath = getAppBasePath() .. "data/foliage/"
  rcDebug("gameBaseFoliagePath")
  rcDebug(gameBaseFoliagePath)
  rcDebug("files")
  rcDebug(files)
  -- Check if no folder found, then manually add them
  if files == nil or #files == 0 then
    files = {}
    table.insert(files, { filename = "alfalfa" })
    table.insert(files, { filename = "clover" })
    table.insert(files, { filename = "onion" })
    table.insert(files, { filename = "redCabbage" })
    table.insert(files, { filename = "rye" })
    table.insert(files, { filename = "spelt" })
    table.insert(files, { filename = "whiteCabbage" })
  end
  -- Loop though all the files found and load them into the game
  for _, file in ipairs(files) do
    local filename = file.filename
    local getName = string.split(filename,".")
    local folderName = getName[1]
    if folderName ~= nil and filename ~= nil then
      local currentBaseGameFolderPath = gameBaseFoliagePath .. folderName .. "/"
      local currentModFolderPath = modDirectory .. "xml/foliage/" .. folderName .. "/"
      -- Check if folder exists in the data/foliage folder
      if ( not fileExists(currentBaseGameFolderPath) ) then createFolder(currentBaseGameFolderPath) end
      rcDebug("currentBaseGameFolderPath: " .. currentBaseGameFolderPath)
      rcDebug("currentModFolderPath: " .. currentModFolderPath)
      -- Copy the files over
      local foliageFiles = Files.new(currentModFolderPath).files
      -- Check if no folder found, then manually add them
      if foliageFiles == nil or #foliageFiles == 0 then
        foliageFiles = {}
        if folderName == "alfalfa" then
          table.insert(foliageFiles, { filename = "alfalfa.i3d" })
          table.insert(foliageFiles, { filename = "alfalfa.i3d.shapes" })
          table.insert(foliageFiles, { filename = "alfalfa.xml" })
          table.insert(foliageFiles, { filename = "alfalfa_diffuse.dds" })
          table.insert(foliageFiles, { filename = "dryAlfalfa_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance2_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance6_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_alfalfa_distance7_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_luzerne_alpha.dds" })
          table.insert(foliageFiles, { filename = "foliage_luzerne_diffuse.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_alfalfa.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_dryAlfalfa.dds" })
          table.insert(foliageFiles, { filename = "luzerne01LOD_alpha.dds" })
          table.insert(foliageFiles, { filename = "luzerne01LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne01LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne02LOD_alpha.dds" })
          table.insert(foliageFiles, { filename = "luzerne02LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne02LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne03LOD_alpha.dds" })
          table.insert(foliageFiles, { filename = "luzerne03LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne03LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne04LOD_alpha.dds" })
          table.insert(foliageFiles, { filename = "luzerne04LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne04LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne05LOD_alpha.dds" })
          table.insert(foliageFiles, { filename = "luzerne05LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "luzerne05LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "alfalfaDistance_diffuse.dds" })
        end
        if folderName == "clover" then
          table.insert(foliageFiles, { filename = "clover.i3d" })
          table.insert(foliageFiles, { filename = "clover.i3d.shapes" })
          table.insert(foliageFiles, { filename = "clover.xml" })
          table.insert(foliageFiles, { filename = "clover_diffuse.dds" })
          table.insert(foliageFiles, { filename = "dryClover_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover01LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover01LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover01LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover02LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover02LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover02LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover03LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover03LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover03LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover04LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover04LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover04LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover05LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover05LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover05LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_alpha.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance2_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance6_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_clover_distance7_diffuse.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_clover.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_dryClover.dds" })
          table.insert(foliageFiles, { filename = "cloverDistance_diffuse.dds" })
        end
        if folderName == "onion" then
          table.insert(foliageFiles, { filename = "onion.i3d" })
          table.insert(foliageFiles, { filename = "onion.i3d.shapes" })
          table.insert(foliageFiles, { filename = "onion.xml" })
          table.insert(foliageFiles, { filename = "onionStage01_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage01_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage01_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage01_specular.dds" })
          table.insert(foliageFiles, { filename = "onionStage02_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage02_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage02_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage02_specular.dds" })
          table.insert(foliageFiles, { filename = "onionStage03_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage03_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage03_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage03_specular.dds" })
          table.insert(foliageFiles, { filename = "onionStage04_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage04_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage04_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage04_specular.dds" })
          table.insert(foliageFiles, { filename = "onionStage05_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage05_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage05_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage05_specular.dds" })
          table.insert(foliageFiles, { filename = "onionStage1LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage1LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage1LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage2LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage2LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage2LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage3LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage3LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage3LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage4LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage4LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage4LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage5LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage5LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage5LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "onionStage6LOD1_alpha.dds" })
          table.insert(foliageFiles, { filename = "onionStage6LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onionStage6LOD1_normal.dds" })
          table.insert(foliageFiles, { filename = "sugarbeetHaulm.i3d" })
          table.insert(foliageFiles, { filename = "sugarbeetHaulm.i3d.shapes" })
          table.insert(foliageFiles, { filename = "hud_fill_onion.dds" })
          table.insert(foliageFiles, { filename = "onion_diffuse.dds" })
          table.insert(foliageFiles, { filename = "onion_normal.dds" })
          table.insert(foliageFiles, { filename = "onion_specular.dds" })
          table.insert(foliageFiles, { filename = "onionDistance_diffuse.dds" })
        end
        if folderName == "redCabbage" then
          table.insert(foliageFiles, { filename = "cabbage01LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage01LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage01LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage_alpha.dds" })
          table.insert(foliageFiles, { filename = "cabbage_diffuse.dds" })
          table.insert(foliageFiles, { filename = "cabbage_normal.dds" })
          table.insert(foliageFiles, { filename = "redCabbage.i3d" })
          table.insert(foliageFiles, { filename = "redCabbage.i3d.shapes" })
          table.insert(foliageFiles, { filename = "redCabbage.xml" })
          table.insert(foliageFiles, { filename = "redCabbageHaulm_alpha.dds" })
          table.insert(foliageFiles, { filename = "redCabbageHaulm_diffuse.dds" })
          table.insert(foliageFiles, { filename = "redCabbageHaulm_normal.dds" })
          table.insert(foliageFiles, { filename = "redCabbage_Haulm.i3d" })
          table.insert(foliageFiles, { filename = "redCabbage_Haulm.i3d.shapes" })
          table.insert(foliageFiles, { filename = "hud_fill_redcabbage.dds" })
          table.insert(foliageFiles, { filename = "redCabbage_diffuse.dds" })
          table.insert(foliageFiles, { filename = "redCabbage_normal.dds" })
          table.insert(foliageFiles, { filename = "redCabbage_specular.dds" })
          table.insert(foliageFiles, { filename = "foliage_redCabbage_distance6_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_redCabbage_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_redCabbage_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_redCabbage_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_redCabbage_distance2_diffuse.dds" })
        end
        if folderName == "rye" then
          table.insert(foliageFiles, { filename = "rye.i3d" })
          table.insert(foliageFiles, { filename = "rye.i3d.shapes" })
          table.insert(foliageFiles, { filename = "rye.xml" })
          table.insert(foliageFiles, { filename = "ryeStage04LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "ryeStage04_diffuse.dds" })
          table.insert(foliageFiles, { filename = "ryeStage06LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "ryeStage06_diffuse.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_rye.dds" })
          table.insert(foliageFiles, { filename = "foliage_barley_distance2_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_barley_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_barley_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_barley_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_barley_distance6_diffuse.dds" })
          table.insert(foliageFiles, { filename = "rye_diffuse.dds" })
          table.insert(foliageFiles, { filename = "rye_normal.dds" })
          table.insert(foliageFiles, { filename = "rye_specular.dds" })
        end
        if folderName == "spelt" then
          table.insert(foliageFiles, { filename = "spelt.i3d" })
          table.insert(foliageFiles, { filename = "spelt.i3d.shapes" })
          table.insert(foliageFiles, { filename = "spelt.xml" })
          table.insert(foliageFiles, { filename = "speltStage04LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "speltStage04_diffuse.dds" })
          table.insert(foliageFiles, { filename = "speltStage06LOD1_diffuse.dds" })
          table.insert(foliageFiles, { filename = "speltStage06_diffuse.dds" })
          table.insert(foliageFiles, { filename = "spelt_diffuse.dds" })
          table.insert(foliageFiles, { filename = "hud_fill_spelt.dds" })
          table.insert(foliageFiles, { filename = "foliage_wheat_distance2_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_wheat_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_wheat_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_wheat_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_wheat_distance6_diffuse.dds" })
        end
        if folderName == "whiteCabbage" then
          table.insert(foliageFiles, { filename = "cabbage01LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage01LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage01LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage02LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage03LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage04LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_alpha_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_diffuse_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage05LOD_normal_H.dds" })
          table.insert(foliageFiles, { filename = "cabbage_alpha.dds" })
          table.insert(foliageFiles, { filename = "cabbage_diffuse.dds" })
          table.insert(foliageFiles, { filename = "cabbage_normal.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbage.i3d" })
          table.insert(foliageFiles, { filename = "whiteCabbage.i3d.shapes" })
          table.insert(foliageFiles, { filename = "whiteCabbage.xml" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_alpha.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_diffuse.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_normal.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbage_Haulm.i3d" })
          table.insert(foliageFiles, { filename = "whiteCabbage_Haulm.i3d.shapes" })
          table.insert(foliageFiles, { filename = "hud_fill_whitecabbage.dds" })
          table.insert(foliageFiles, { filename = "foliage_cabbage_distance2_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_cabbage_distance3_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_cabbage_distance4_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_cabbage_distance5_diffuse.dds" })
          table.insert(foliageFiles, { filename = "foliage_cabbage_distance6_diffuse.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_normal.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_diffuse.dds" })
          table.insert(foliageFiles, { filename = "whiteCabbageHaulm_alpha.dds" })
          table.insert(foliageFiles, { filename = "whitecabbage_diffuse.dds" })
          table.insert(foliageFiles, { filename = "whitecabbage_normal.dds" })
          table.insert(foliageFiles, { filename = "whitecabbage_specular.dds" })
        end
      end
      for _, file in ipairs(foliageFiles) do
        -- rcDebug('Found File: ' .. file.filename)
        local secFilename = file.filename
        if secFilename ~= nil then
          -- rcDebug("Copy File To Data Foliage: " .. secFilename)
          -- Copies all files over each time just in case if something changed.
          -- Would like to figure out a way to compare the files before replacing them. 
          copyFile(currentModFolderPath .. secFilename,currentBaseGameFolderPath .. secFilename, true)
        end
      end
      rcDebug("Adding Foliage to Load List: " .. folderName .. " - " .. filename .. ".xml")
      table.insert(g_fruitTypeManager.modFoliageTypesToLoad, {
        name = folderName,
        filename = "data/foliage/" .. folderName .. "/" .. filename .. ".xml"
      })
    end
  end

end


function FillManager:loadMapData()

  -- Load fillTypes for animals
  rcDebug("FillManger - loadMapData")

  local baseDirectory = modDirectory
  local isBaseType = false
  local customEnv = g_fillManager
  local mainKey = "map"

  -- load all fill types located in xml/fillTypes folder
  local files = {}

  table.insert(files, { filename = "BULL_HOLSTEIN.xml" })
  table.insert(files, { filename = "SHEEP_RAM.xml" })
  table.insert(files, { filename = "GOAT_LANDRACE.xml" })
  table.insert(files, { filename = "DUCK.xml" })
  table.insert(files, { filename = "CHICKENFEED.xml" })
  table.insert(files, { filename = "BULL_ANGUS.xml" })
  table.insert(files, { filename = "GOAT_MALE.xml" })

  FillManager:loadFillTypes(files, baseDirectory, customEnv, isBaseType, mainKey)

end

function FillManager:loadFillTypes(files, baseDirectory, customEnv, isBaseType, mainKey)
  -- Loop though all the files found and load them into the game
  for _, file in ipairs(files) do
    rcDebug("Loading File: " .. file.filename)

	  local xmlFile = XMLFile.load(mainKey, modDirectory .. "xml/fillTypes/" .. file.filename, FillTypeManager.xmlSchema)

    xmlFile:iterate(mainKey .. ".fillTypes.fillType", function (_, key)
      rcDebug(key)
      local name = xmlFile:getValue(key .. "#name")
      local title = xmlFile:getValue(key .. "#title")
      local achievementName = xmlFile:getValue(key .. "#achievementName")
      local showOnPriceTable = xmlFile:getValue(key .. "#showOnPriceTable")
      local fillPlaneColors = xmlFile:getValue(key .. "#fillPlaneColors", "1.0 1.0 1.0", true)
      local unitShort = xmlFile:getValue(key .. "#unitShort", "")
      local kgPerLiter = xmlFile:getValue(key .. ".physics#massPerLiter")
      local massPerLiter = kgPerLiter and kgPerLiter / 1000
      local maxPhysicalSurfaceAngle = xmlFile:getValue(key .. ".physics#maxPhysicalSurfaceAngle")
      local hudFilename = xmlFile:getValue(key .. ".image#hud")
      local palletFilename = xmlFile:getValue(key .. ".pallet#filename")
      local pricePerLiter = xmlFile:getValue(key .. ".economy#pricePerLiter")
      local economicCurve = {}

      xmlFile:iterate(key .. ".economy.factors.factor", function (_, factorKey)
        local period = xmlFile:getValue(factorKey .. "#period")
        local factor = xmlFile:getValue(factorKey .. "#value")

        if period ~= nil and factor ~= nil then
          economicCurve[period] = factor
        end
      end)

      local diffuseMapFilename = xmlFile:getValue(key .. ".textures#diffuse")
      local normalMapFilename = xmlFile:getValue(key .. ".textures#normal")
      local specularMapFilename = xmlFile:getValue(key .. ".textures#specular")
      local distanceFilename = xmlFile:getValue(key .. ".textures#distance")
      local prioritizedEffectType = xmlFile:getValue(key .. ".effects#prioritizedEffectType") or "ShaderPlaneEffect"
      local fillSmokeColor = xmlFile:getValue(key .. ".effects#fillSmokeColor", nil, true)
      local fruitSmokeColor = xmlFile:getValue(key .. ".effects#fruitSmokeColor", nil, true)

      -- Replace title with l10n
      local splitTitle = string.split(title,"$l10n_")
      local newTitle = g_i18n:getText(splitTitle[2])

      rcDebug("Add Fill Type: " .. name .. " - " .. newTitle)
      g_fillTypeManager:addFillType(name, newTitle, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudFilename, baseDirectory, customEnv, fillPlaneColors, unitShort, palletFilename, economicCurve, diffuseMapFilename, normalMapFilename, specularMapFilename, distanceFilename, prioritizedEffectType, fillSmokeColor, fruitSmokeColor, achievementName, isBaseType or false)
    end)

    xmlFile:delete()    
  end
end

function FillManager:loadBales()

  -- load bales
  local baleFiles = {}
  
  table.insert(baleFiles, { filename = "bales/roundbales/roundbale125.xml" })
  table.insert(baleFiles, { filename = "bales/roundbales/roundbale150.xml" })
  table.insert(baleFiles, { filename = "bales/roundbales/roundbale180.xml" })
  table.insert(baleFiles, { filename = "bales/squarebales/squarebale120.xml" })
  table.insert(baleFiles, { filename = "bales/squarebales/squarebale180.xml" })
  table.insert(baleFiles, { filename = "bales/squarebales/squarebale220.xml" })
  table.insert(baleFiles, { filename = "bales/squarebales/squarebale240.xml" })

  rcDebug("FillManager:loadBales")
  for _, file in ipairs(baleFiles) do
    rcDebug("Loading File: " .. file.filename)

		local bale = {
			xmlFilename = Utils.getFilename(file.filename, modDirectory),
			isAvailable = true
		}
		local baleXmlFile = XMLFile.load("TempBale", bale.xmlFilename, BaleManager.baleXMLSchema)

		if baleXmlFile ~= nil then
			local success = g_baleManager:loadBaleDataFromXML(bale, baleXmlFile, modDirectory)

			baleXmlFile:delete()

			if success then
				table.insert(g_baleManager.bales, bale)
			end
		end
	end

end

function FillManager:loadMapDataAnimals(xmlFile, missionInfo, baseDirectory)
  -- Load custom animals.xml
  rcDebug("Loading Custom animals.xml")

	local filename = Utils.getFilename("animals/animals.xml", modDirectory)
	local xmlFileAnimals = XMLFile.load("animals", filename)

	if xmlFileAnimals == nil then
		return false
	end

	self:loadAnimals(xmlFileAnimals, modDirectory)
	xmlFileAnimals:delete()

  return #self.types > 0

end


function FillManager:loadMapDataAnimalFood()
  -- Load custom animalFood.xml
  rcDebug("Loading Custom animalFood.xml")

	local filename = Utils.getFilename("animals/animalFood.xml", modDirectory)
	local xmlFileFood = XMLFile.load("animalFood", filename, AnimalFoodSystem.xmlSchema)

	if xmlFileFood == nil then
		return false
	end

	local modMapName, _ = Utils.getModNameAndBaseDirectory(filename)
	g_currentMission.animalFoodSystem.customEnvironment = modMapName

	if not g_currentMission.animalFoodSystem:loadAnimalFood(xmlFileFood, modDirectory) then
		xmlFileFood:delete()

		return false
	end

	if not g_currentMission.animalFoodSystem:loadMixtures(xmlFileFood, modDirectory) then
		xmlFileFood:delete()

		return false
	end

	if not g_currentMission.animalFoodSystem:loadRecipes(xmlFileFood, modDirectory) then
		xmlFileFood:delete()

		return false
	end

	xmlFileFood:delete()

  return true

end

function FillManager:createHusbandry()
  rcDebug("FillManager:createHusbandry")
	local spec = self.spec_husbandryAnimals

	if spec.navigationMesh == nil then
		Logging.error("Navigation mesh node not defined for animal husbandry!")

		return
	end

	if not getHasClassId(spec.navigationMesh, ClassIds.NAVIGATION_MESH) then
		Logging.error("Given mesh node '%s' is not a navigation mesh!", getName(spec.navigationMesh))

		return
	end

	local collisionMaskFilter = CollisionMask.ANIMAL_SINGLEPLAYER

	if g_currentMission.missionDynamicInfo.isMultiplayer then
		collisionMaskFilter = CollisionMask.ANIMAL_MULTIPLAYER
	end

  local newBaseDir = modDirectory
  -- if spec.baseDirectory ~= nil and spec.baseDirectory ~= "" then
  --   newBaseDir = spec.baseDirectory
  -- end
  rcDebug(newBaseDir)

  rcDebug(spec.animalType.configFilename)
  

	local xmlFilename = Utils.getFilename(spec.animalType.configFilename, newBaseDir)
	local husbandry = spec.clusterHusbandry:create(xmlFilename, spec.navigationMesh, spec.placementRaycastDistance, collisionMaskFilter)

	if husbandry == nil or husbandry == 0 then
		Logging.error("Could not create animal husbandry!")

		return
	end

	if husbandry ~= nil then
		g_currentMission.husbandrySystem:addClusterHusbandry(spec.clusterHusbandry)
	end

	SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsCreated", husbandry)
end

function FillManager:getText(super, name, customEnv)
  
	local ret = nil

	if customEnv ~= nil then
		local modEnv = self.modEnvironments[customEnv]

		if modEnv ~= nil then
			ret = modEnv.texts[name]
		end
	end

	if ret == nil then
		ret = self.texts[name]

		if ret == nil then
      -- Try to load data from custom xml
      if FillManager:customLang() ~= nil then
        local customLang = FillManager:customLang()
        ret = customLang[name]
      end

      if ret == nil then

			  ret = string.format("Missing '%s' in l10n%s.xml", name, g_languageSuffix)
      
        if g_showDevelopmentWarnings then
          Logging.devWarning(ret)
        end

      end
		end
	end

	if self.debugActive then
		self.usedTexts[name] = true
	end

	if ret:upper():trim() == "TODO" then
		if self.debugActive and self.printedWarnings[name] == nil then
			Logging.devWarning("TODO:" .. name)

			self.printedWarnings[name] = true
		end

		return "TODO:" .. name
	end

	return ret
end

function FillManager:customLang()

  local output = {}
  local l10nXmlFile, l10nFilename = nil
  local langs = {
    g_languageShort,
    "en",
    "de"
  }

  for _, lang in ipairs(langs) do
    l10nFilename = modDirectory .. "lang/l10n" .. "_" .. lang .. ".xml"

    if fileExists(l10nFilename) then
      l10nXmlFile = loadXMLFile("modL10n", l10nFilename)

      break
    end
  end

  if l10nXmlFile ~= nil then
    local textI = 0

    while true do
      local key = string.format("l10n.texts.text(%d)", textI)

      if not hasXMLProperty(l10nXmlFile, key) then
        break
      end

      local name = getXMLString(l10nXmlFile, key .. "#name")
      local text = getXMLString(l10nXmlFile, key .. "#text")

      if name ~= nil and text ~= nil then
        output[name] = text:gsub("\r\n", "\n")
      end

      textI = textI + 1
    end

    if output ~= nil then
      return output
    end

    delete(l10nXmlFile)
  else
    print("Warning: Custom l10n xml file not found.")
  end

end

-- Change up how farm ids are handled in storages
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

  local avaialbeFarmIds = {}

  for _, farm in ipairs(g_farmManager:getFarms()) do
    if farm.farmId ~= 0 then
      table.insert(avaialbeFarmIds, farm.farmId)
    end
  end

	local numStorageSets = spec.storagePerFarm and #avaialbeFarmIds or 1

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
        if avaialbeFarmIds[j] ~= nil then
          storage.ownerFarmId = avaialbeFarmIds[j]
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
	      local storageSystem = g_currentMission.storageSystem

        if spec.storagePerFarm then
          rcDebug("Silo Has Storage Per Farm Enabled")

          -- Create a set of existing storage owner farm IDs
          local existingStorageFarmIds = {}
          for _, storage in ipairs(spec.storages) do
            existingStorageFarmIds[storage.ownerFarmId] = true
          end

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
                
                if g_currentMission:getIsServer() then
                  storage:raiseDirtyFlags(storage.storageDirtyFlag)
                end
                storage:updateFillPlanes()

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

                  if g_currentMission:getIsServer() then
                    storage:raiseDirtyFlags(storage.storageDirtyFlag)
                  end
                  storage:updateFillPlanes()
                  
                end
              end
            end
          end

        end
      end
    end

  end
end

-- Updates the motion path effects to include new stuffs
function FillManager:loadMotionPathEffects()

  rcDebug("FillManager - loadMotionPathEffects")

  g_motionPathEffectManager.createMotionPathEffectXMLSchema()

  local customEnvironment, _ = Utils.getModNameAndBaseDirectory(modDirectory)
  local filename = Utils.getFilename("effects/motionPathEffects.xml", modDirectory)
  local xmlFile = XMLFile.load("motionPathXML", filename)

  rcDebug(customEnvironment)
  rcDebug(filename)
  rcDebug(xmlFile)

  if fileExists(filename) then
    rcDebug("filename exists")
  end

  if xmlFile ~= nil then
      rcDebug("Load Motions Effects")
      g_motionPathEffectManager:loadMotionPathEffects(xmlFile.handle, "motionPathEffects.motionPathEffect", modDirectory, customEnvironment)
      xmlFile:delete()
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