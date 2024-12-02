--
-- main
-- 
-- Author: DaVaR
-- Description: Loads the mod and such
-- Name: main
-- Hide: yes
--

-- Designed for Farm Sim Game's FSGRealism Dedicated Servers
local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"
local modEnvironmentChat
local modEnvironmentonSave
local modEnvironmentgetAdminLogin
local modEnvironmentNewJoin
local modEnvironmentFarmMangerRC
local modEnvironmentRemoteCommands
local modEnvironmentFarmCleanUp
local modEnvironmentLimits
local modEnvironmentVehicleStorage
local modEnvironmentFieldStats
local modEnvironmentVehicleEdit
local modEnvironmentWeatherForecastStats
local modEnvironmentCoopSiloManager
local modEnvironmentFarmPlaceableTax
local modEnvironmentFillManager
local modEnvironmentFSGSettings
local modEnvironmentInfoMessages

---Source files 
local sourceFiles = {
  -- Main Functions
  "scripts/globalFuncs.lua",
	"scripts/onSave.lua",
  "scripts/chatEventSaver.lua",
  "scripts/chatLogger.lua",
	"scripts/getAdminLogin.lua",
	"scripts/getNewJoin.lua",
  "scripts/farmManager.lua",
  "scripts/remoteCmds.lua",
  "scripts/farmCleanUp.lua",
  "scripts/limits.lua",
  "scripts/vehicleStorage.lua",
  "scripts/fieldStats.lua",
  "scripts/vehicleEdit.lua",
  "scripts/weatherForecastStats.lua",
  "scripts/coopSiloManager.lua",
  "scripts/farmPlaceableTax.lua",
  "scripts/fillManager.lua",
  "scripts/FSGSettings.lua",
  "scripts/fs22ModPrefSaver.lua",
  -- "scripts/paintAndTerraformAnywhere.lua",
  "scripts/infoMessages.lua",
  -- Gui
  "gui/FSGSettingsGui.lua",
  "gui/FSGSettingsGuiInfoFrame.lua",
  "gui/FSGSettingsGuiToolsFrame.lua",
  "gui/FSGSettingsGuiSettingsFrame.lua",
  "gui/FSGSettingsGuiTimeSyncFrame.lua",
  -- Events
  "scripts/events/farmManagerEvent.lua",
  "scripts/events/farmManagerJoinEvent.lua",
  "scripts/events/newFarmManagerJoinEvent.lua",
  "scripts/events/limitsEvent.lua",
  "scripts/events/vehicleStorageEvent.lua",
  "scripts/events/vehicleEditEvent.lua",
  "scripts/events/superStrengthEvent.lua",
  "scripts/events/farmlandUpdateEvent.lua",
  "scripts/events/FCAIJobStartRequestEvent.lua",
  "scripts/events/FCAIJobStartEvent.lua",
  "scripts/events/FCTreePlantEvent.lua",
  "scripts/events/FCSettingEvent.lua",
	-- Load all command files
	"scripts/commands/forgetMe.lua",
	"scripts/commands/getFarms.lua",
	"scripts/commands/getUsers.lua",
	"scripts/commands/makeAdmin.lua",
	"scripts/commands/meAdmin.lua",
	"scripts/commands/rememberMe.lua",
}

---Load all of the soruce files
for _, file in ipairs(sourceFiles) do
  source(modDirectory .. file)
end

---Load the mod
local function load(mission)
  assert(g_chatLogger == nil)
  modEnvironmentChat = ChatLogger:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_chatLogger"] = modEnvironmentChat

  assert(g_onSave == nil)
  modEnvironmentonSave = onSave:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_onSave"] = modEnvironmentonSave

  assert(g_getAdminLogin == nil)
  modEnvironmentgetAdminLogin = GetAdminLogin:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_getAdminLogin"] = modEnvironmentgetAdminLogin

  assert(g_getNewJoin == nil)
  modEnvironmentNewJoin = GetNewJoin:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_getNewJoin"] = modEnvironmentNewJoin

  assert(g_farmManagerRC == nil)
  modEnvironmentFarmMangerRC = FarmManagerRC:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_farmManagerRC"] = modEnvironmentFarmMangerRC

  assert(g_remoteCommands == nil)
  modEnvironmentRemoteCommands = RemoteCommands:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_remoteCommands"] = modEnvironmentRemoteCommands

  assert(g_farmCleanUp == nil)
  modEnvironmentFarmCleanUp = FarmCleanUp:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_farmCleanUp"] = modEnvironmentFarmCleanUp

  assert(g_limits == nil)
  modEnvironmentLimits = Limits:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_limits"] = modEnvironmentLimits

  assert(g_vehicleStorage == nil)
  modEnvironmentVehicleStorage = VehicleStorage:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_vehicleStorage"] = modEnvironmentVehicleStorage

  assert(g_fieldStats == nil)
  modEnvironmentFieldStats = FieldStats:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_fieldStats"] = modEnvironmentFieldStats

  assert(g_vehicleEdit == nil)
  modEnvironmentVehicleEdit = VehicleEdit:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_vehicleEdit"] = modEnvironmentVehicleEdit

  assert(g_weatherForecastStats == nil)
  modEnvironmentWeatherForecastStats = WeatherForecastStats:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_weatherForecastStats"] = modEnvironmentWeatherForecastStats

  assert(g_coopSiloManager == nil)
  modEnvironmentCoopSiloManager = CoopSiloManager:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_coopSiloManager"] = modEnvironmentCoopSiloManager

  assert(g_farmPlaceableTax == nil)
  modEnvironmentFarmPlaceableTax = FarmPlaceableTax:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_farmPlaceableTax"] = modEnvironmentFarmPlaceableTax

  assert(g_fillManager == nil)
  modEnvironmentFillManager = FillManager:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_fillManager"] = modEnvironmentFillManager

  assert(g_fsgSettings == nil)
  modEnvironmentFSGSettings = FSGSettings:new(mission, g_i18n, modDirectory, modName)
  getfenv(0)["g_fsgSettings"] = modEnvironmentFSGSettings

  assert(g_infoMessages == nil)
  modEnvironmentInfoMessages = InfoMessages:new()
  getfenv(0)["g_infoMessages"] = modEnvironmentInfoMessages

  if mission:getIsClient() then
    addModEventListener(modEnvironmentChat)
    addModEventListener(modEnvironmentonSave)
    addModEventListener(modEnvironmentgetAdminLogin)
    addModEventListener(modEnvironmentNewJoin)
    addModEventListener(modEnvironmentFarmMangerRC)
    addModEventListener(modEnvironmentRemoteCommands)
    addModEventListener(modEnvironmentFarmCleanUp)
    addModEventListener(modEnvironmentLimits)
    addModEventListener(modEnvironmentVehicleStorage)
    addModEventListener(modEnvironmentFieldStats)
    addModEventListener(modEnvironmentVehicleEdit)
    addModEventListener(modEnvironmentWeatherForecastStats)
    addModEventListener(modEnvironmentCoopSiloManager)
    addModEventListener(modEnvironmentFarmPlaceableTax)
    addModEventListener(modEnvironmentFillManager)
    addModEventListener(modEnvironmentFSGSettings)
    addModEventListener(modEnvironmentInfoMessages)
  end

end

---Unload the mod when the mod is unselected and savegame is (re)loaded or game is closed.
local function unload()

  -- Run shutdown stuffs for the mod
  FieldStats:delete()

  removeModEventListener(modEnvironmentChat)
  if modEnvironmentChat ~= nil then
    modEnvironmentChat = nil
    if g_chatLogger ~= nil then
      getfenv(0)["g_chatLogger"] = nil
    end
  end
  removeModEventListener(modEnvironmentonSave)
  if modEnvironmentonSave ~= nil then
    modEnvironmentonSave = nil
    if g_onSave ~= nil then
      getfenv(0)["g_onSave"] = nil
    end
  end
  removeModEventListener(modEnvironmentgetAdminLogin)
  if modEnvironmentgetAdminLogin ~= nil then
    modEnvironmentgetAdminLogin = nil
    if g_getAdminLogin ~= nil then
      getfenv(0)["g_getAdminLogin"] = nil
    end
  end
  removeModEventListener(modEnvironmentNewJoin)
  if modEnvironmentNewJoin ~= nil then
    modEnvironmentNewJoin = nil
    if g_getNewJoin ~= nil then
      getfenv(0)["g_getNewJoin"] = nil
    end
  end
  removeModEventListener(modEnvironmentFarmMangerRC)
  if modEnvironmentFarmMangerRC ~= nil then
    modEnvironmentFarmMangerRC = nil
    if g_farmManagerRC ~= nil then
      getfenv(0)["g_farmManagerRC"] = nil
    end
  end
  removeModEventListener(modEnvironmentRemoteCommands)
  if modEnvironmentRemoteCommands ~= nil then
    modEnvironmentRemoteCommands = nil
    if g_remoteCommands ~= nil then
      getfenv(0)["g_remoteCommands"] = nil
    end
  end
  removeModEventListener(modEnvironmentFarmCleanUp)
  if modEnvironmentFarmCleanUp ~= nil then
    modEnvironmentFarmCleanUp = nil
    if g_farmCleanUp ~= nil then
      getfenv(0)["g_farmCleanUp"] = nil
    end
  end
  removeModEventListener(modEnvironmentLimits)
  if modEnvironmentLimits ~= nil then
    modEnvironmentLimits = nil
    if g_limits ~= nil then
      getfenv(0)["g_limits"] = nil
    end
  end
  removeModEventListener(modEnvironmentVehicleStorage)
  if modEnvironmentVehicleStorage ~= nil then
    modEnvironmentVehicleStorage = nil
    if g_vehicleStorage ~= nil then
      getfenv(0)["g_vehicleStorage"] = nil
    end
  end
  removeModEventListener(modEnvironmentFieldStats)
  if modEnvironmentFieldStats ~= nil then
    modEnvironmentFieldStats = nil
    if g_fieldStats ~= nil then
      getfenv(0)["g_fieldStats"] = nil
    end
  end
  removeModEventListener(modEnvironmentVehicleEdit)
  if modEnvironmentVehicleEdit ~= nil then
    modEnvironmentVehicleEdit = nil
    if g_vehicleEdit ~= nil then
      getfenv(0)["g_vehicleEdit"] = nil
    end
  end
  removeModEventListener(modEnvironmentWeatherForecastStats)
  if modEnvironmentWeatherForecastStats ~= nil then
    modEnvironmentWeatherForecastStats = nil
    if g_weatherForecastStats ~= nil then
      getfenv(0)["g_weatherForecastStats"] = nil
    end
  end
  removeModEventListener(modEnvironmentCoopSiloManager)
  if modEnvironmentCoopSiloManager ~= nil then
    modEnvironmentCoopSiloManager = nil
    if g_coopSiloManager ~= nil then
      getfenv(0)["g_coopSiloManager"] = nil
    end
  end
  removeModEventListener(modEnvironmentFarmPlaceableTax)
  if modEnvironmentFarmPlaceableTax ~= nil then
    modEnvironmentFarmPlaceableTax = nil
    if g_farmPlaceableTax ~= nil then
      getfenv(0)["g_farmPlaceableTax"] = nil
    end
  end
  removeModEventListener(modEnvironmentFillManager)
  if modEnvironmentFillManager ~= nil then
    modEnvironmentFillManager = nil
    if g_fillManager ~= nil then
      getfenv(0)["g_fillManager"] = nil
    end
  end
  removeModEventListener(modEnvironmentFSGSettings)
  if modEnvironmentFSGSettings ~= nil then
    modEnvironmentFSGSettings = nil
    if g_fsgSettings ~= nil then
      getfenv(0)["g_fsgSettings"] = nil
    end
  end
  removeModEventListener(modEnvironmentInfoMessages)
  if modEnvironmentInfoMessages ~= nil then
    modEnvironmentInfoMessages = nil
    if g_infoMessages ~= nil then
      getfenv(0)["g_infoMessages"] = nil
    end
  end
end

local function loadedMission(mission, node)
  -- Do stuff when mission is loaded
end

---Init the mod.
local function init()

  -- Mod is loaded in to the game here.  Yay!
  rcDebug("Starting the FSG Realism Companion")

  -- FS25 - This is not needed.  Not planning to add new crops at this time
  -- FillManager:loadMod()

  -- Create folder for this mod if not one already
  local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
  if ( not fileExists(modSettingsFolderPath) ) then createFolder(modSettingsFolderPath) end
  -- Create folder for commands is not one already
  local commandsFolderPath = modSettingsFolderPath  .. "/commands"
  if ( not fileExists(commandsFolderPath) ) then createFolder(commandsFolderPath) end
  local commandsInboxFolderPath = commandsFolderPath  .. "/inbox"
  if ( not fileExists(commandsInboxFolderPath) ) then createFolder(commandsInboxFolderPath) end
  local commandsOutboxFolderPath = commandsFolderPath  .. "/outbox"
  if ( not fileExists(commandsOutboxFolderPath) ) then createFolder(commandsOutboxFolderPath) end
  local commandsBackupFolderPath = commandsFolderPath  .. "/backup"
  if ( not fileExists(commandsBackupFolderPath) ) then createFolder(commandsBackupFolderPath) end
  -- Create folder for fields data files
  local fieldsDataFolderPath = modSettingsFolderPath  .. "/FieldsData"
  if ( not fileExists(fieldsDataFolderPath) ) then createFolder(fieldsDataFolderPath) end

  FSBaseMission.delete = Utils.appendedFunction(FSBaseMission.delete, unload)
  Mission00.load = Utils.prependedFunction(Mission00.load, load)
  Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, loadedMission)

  MissionManager.MAX_MISSIONS_PER_FARM = 10

  FarmManager.MAX_NUM_FARMS = 20
  FarmManager.FARM_ID_SEND_NUM_BITS = 12
  FarmManager.MAX_FARM_ID = 4095
  FarmManager.INVALID_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS^2 - 1

  Farm.COLORS = {
    {1, 0.4287, 0, 1}, 
    {1, 0.1221, 0.0003, 1}, 
    {0.7084, 0.0203, 0.2086, 1}, 
    {0.2541, 0.0065, 0.5089, 1}, 
    {0.1921, 0.0976, 0.8632, 1}, 
    {0.1248, 0.2541, 1, 1}, 
    {0.1248, 0.9216, 1, 1}, 
    {0.2307, 1, 0.2232, 1}, 
    {0.5, 0, 0.5, 1},    
    {0, 0.5, 0.5, 1},    
    {0.5, 0.5, 0, 1},    
    {0.3, 0.6, 0.9, 1},  
    {0.7, 0.3, 0.5, 1},  
    {0.8, 0.8, 0.2, 1},  
    {0.6, 0.1, 0.4, 1},  
    {0.2, 0.4, 0.1, 1},  
    {0.4, 0.2, 0.7, 1},  
    {0.1, 0.7, 0.6, 1},  
    {0.9, 0.5, 0.2, 1},  
    {0.9, 0.1, 0.1, 1},  
    {0.5, 0.5, 0.5, 1},  
    {0, 0, 1, 1},        
    {1, 1, 0, 1},        
    {0, 1, 1, 1},        
    {1, 0, 1, 1},        
    {0.5, 0, 0, 1},      
    {0, 0.5, 0, 1},      
  }

  Farm.COLOR_SEND_NUM_BITS = 6 -- Adjusting to accommodate more colors

  Farm.ICON_UVS = {
    {330,0,256,256},
    {660,0,256,256},
    {330,310,256,256},
    {0,310,256,256},
    {660,310,256,256},
    {0,620,256,256},
    {330,620,256,256},
    {660,620,256,256},
    {330,0,256,256},
    {660,0,256,256},
    {330,310,256,256},
    {0,310,256,256},
    {660,310,256,256},
    {0,620,256,256},
    {330,620,256,256},
    {660,620,256,256},
    {330,0,256,256},
    {660,0,256,256},
    {330,310,256,256},
    {0,310,256,256},
    {660,310,256,256},
    {0,620,256,256},
    {330,620,256,256},
    {660,620,256,256},
    {330,0,256,256},
    {660,0,256,256},
    {330,310,256,256},
    {0,310,256,256},
    {660,310,256,256},
    {0,620,256,256},
    {330,620,256,256},
    {660,620,256,256},        
  }

  -- runs when player sends a message in multiplayer chat
  ChatDialog.onSendClick = Utils.overwrittenFunction(ChatDialog.onSendClick, ChatLogger.onSendClick)

  -- run when the game is saved either manualy or auto
  FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, onSave.saveToXMLFile)
  FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, FSGSettings.saveToXMLFile)
  
  -- Runs when player becomes an admin
  FSBaseMission.onMasterUserAdded = Utils.appendedFunction(FSBaseMission.onMasterUserAdded, GetAdminLogin.userNowAdminEvent)

  -- runs when the game is finished loading or player leaves welcome screen after joining game
  FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, onConnectionFinishedLoading)

  -- Loads up the help menu for this mod
  HelpLineManager.loadMapData = Utils.overwrittenFunction(HelpLineManager.loadMapData, ChatLogger.loadMapDataHelpLineManager)

  -- Overwrites the dedi xml link output
  FSBaseMission.updateGameStatsXML = Utils.overwrittenFunction(FSBaseMission.updateGameStatsXML, onUpdateGameStatsXML)

  -- Triggers when a user is given farm manager aka all permissions
  Farm.promoteUser = Utils.appendedFunction(Farm.promoteUser, FarmManagerRC.addFarmManager)

  -- Triggers when a user is removed as farm amanger
  Farm.demoteUser = Utils.appendedFunction(Farm.demoteUser, FarmManagerRC.removeFarmManager)

  -- Triggers when a user joins a farm
  InGameMenuMultiplayerFrame.doJoinFarm = Utils.appendedFunction(InGameMenuMultiplayerFrame.doJoinFarm, FarmManagerRC.userJoinFarm)

  -- Triggers when user has joined farm
  InGameMenuMultiplayerFrame.onFarmPasswordEntered = Utils.appendedFunction(InGameMenuMultiplayerFrame.onFarmPasswordEntered, FarmManagerRC.onFarmPasswordEntered)

  -- Trigger when a user joins server before the sync stuffs
  FSBaseMission.onUserAdded = Utils.appendedFunction(FSBaseMission.onUserAdded, onSyncWarning)

  -- Trigger when checking AI hired limit
  AIJobVehicle.toggleAIVehicle = Utils.overwrittenFunction(AIJobVehicle.toggleAIVehicle, Limits.toggleAIVehicle)

  -- Check if max missions
  -- MissionManager.hasFarmReachedMissionLimit = Utils.overwrittenFunction(MissionManager.hasFarmReachedMissionLimit, Limits.hasFarmReachedMissionLimit)
  InGameMenuContractsFrame.startContract = Utils.overwrittenFunction(InGameMenuContractsFrame.startContract, Limits.startContract)

  -- Trigger Husbandry Limits
  HusbandrySystem.GAME_LIMIT = 1000
  PlaceableHusbandry.getCanBePlacedAt = Utils.overwrittenFunction(PlaceableHusbandry.getCanBePlacedAt, Limits.updateAnimalHusbandryLimitRules)
  PlaceableHusbandry.canBuy = Utils.overwrittenFunction(PlaceableHusbandry.canBuy, Limits.updateAnimalHusbandryLimitRules)

  -- Limit all placeables
  Placeable.canBuy = Utils.overwrittenFunction(Placeable.canBuy, Limits.canBuyPlaceable)

  -- Vehicle Storage Stuffs
  WorkshopScreen.setVehicle = Utils.appendedFunction(WorkshopScreen.setVehicle, VehicleStorage.setVehicle)

  -- Vehicle Edit Stuffs
  Vehicle.showInfo = Utils.appendedFunction(Vehicle.showInfo, VehicleEdit.showInfo)

  -- Overwrite how object storage player interaction works
  PlaceableObjectStorageActivatable.getIsActivatable = Utils.overwrittenFunction(PlaceableObjectStorageActivatable.getIsActivatable, CoopSiloManager.getIsActivatable)

  -- Overwrite how object storage selection is displayed.  Limit to farm only stuffs.
  ObjectStorageDialog.setObjectInfos = Utils.overwrittenFunction(ObjectStorageDialog.setObjectInfos, CoopSiloManager.setObjectInfos)

  -- Overwrite the button to buy or sell land so that it is always disabled
  InGameMenuMapFrame.showContextInput = Utils.appendedFunction(InGameMenuMapFrame.showContextInput, Limits.showContextInput)
  InGameMenuMapFrame.onClickBuyFarmland = Utils.overwrittenFunction(InGameMenuMapFrame.onClickBuyFarmland, Limits.blockFarmland)
  InGameMenuMapFrame.onClickSellFarmland = Utils.overwrittenFunction(InGameMenuMapFrame.onClickSellFarmland, Limits.blockFarmland)
  InGameMenuMapFrame.onYesNoBuyFarmland = Utils.overwrittenFunction(InGameMenuMapFrame.onYesNoBuyFarmland, Limits.blockFarmland)
  InGameMenuMapFrame.onYesNoSellFarmland = Utils.overwrittenFunction(InGameMenuMapFrame.onYesNoSellFarmland, Limits.blockFarmland)
  
  -- Disable loans in game by removing the button
  InGameMenuStatisticsFrame.hasPlayerLoanPermission = Utils.appendedFunction(InGameMenuStatisticsFrame.hasPlayerLoanPermission, hasPlayerLoanPermission)

  -- FS25 - Not needed anymore as we are not going to add new animals or crops to the game
  -- FillTypeManager.loadMapData = Utils.appendedFunction(FillTypeManager.loadMapData, FillManager.loadMapData)
  -- PlaceableHusbandryAnimals.createHusbandry = Utils.overwrittenFunction(PlaceableHusbandryAnimals.createHusbandry, FillManager.createHusbandry)
  -- AnimalSystem.loadMapData = Utils.overwrittenFunction(AnimalSystem.loadMapData, FillManager.loadMapDataAnimals)
  -- I18N.getText = Utils.overwrittenFunction(I18N.getText, FillManager.getText)

  ProductionPoint.buyRequest = Utils.overwrittenFunction(ProductionPoint.buyRequest, Limits.disableBuyProduction)

  -- FS25 - They changed up the store loading process.  Will have to revisit this in time to block things we don't want to allow in game.
  -- StoreManager.loadItem = Utils.overwrittenFunction(StoreManager.loadItem, Limits.loadItem)

  InGameMenuContractsFrame.setButtonsForState = Utils.appendedFunction(InGameMenuContractsFrame.setButtonsForState, Limits.setButtonsForState)

  PlaceableSilo.onLoad = Utils.overwrittenFunction(PlaceableSilo.onLoad, FillManager.onLoad)

  FSBaseMission.onFinishedLoading = Utils.appendedFunction(FSBaseMission.onFinishedLoading, FillManager.updateStorages)

  -- Disables Sleeping in Game
  SleepManager.getCanSleep = Utils.overwrittenFunction(SleepManager.getCanSleep, FSGSettings.disableSleep)

  -- Overwrite AI Job Start Event to use new farm Id settings
  AIJobStartEvent.new = Utils.overwrittenFunction(AIJobStartEvent.new, FCAIJobStartEvent.new)
  AIJobStartRequestEvent.new = Utils.overwrittenFunction(AIJobStartRequestEvent.new, FCAIJobStartRequestEvent.new)

  -- Overwrite Tree Plant Event to use new farm Id settings
  TreePlantEvent.new = Utils.overwrittenFunction(TreePlantEvent.new, FCTreePlantEvent.new)

  -- Updates the silo buy price factor
  PlaceableSiloActivatable.run = Utils.overwrittenFunction(PlaceableSiloActivatable.run, function(self, superFunc)
    local data = {}

    for _, storage in pairs(self.placeable.spec_silo.storages) do
      for fillType, fillLevel in pairs(storage:getFillLevels()) do
        if data[fillType] == nil then
          data[fillType] = 0
        end

        data[fillType] = data[fillType] + storage:getFreeCapacity(fillType)
      end
    end

    RefillDialog.show({
      data = data,
      priceFactor = 2.1,
      callback = self.placeable.refillAmount,
      target = self.placeable
    })
  end)



end

---Run when player is connected to server
function onConnectionFinishedLoading(connection, ...)
	GetNewJoin.newUserJoin(...)
  FSGSettings.join()
end

---Run when game stats are getting updated
function onUpdateGameStatsXML(...)
  -- Nothing returned, no need to call the superFunc
  ---Replaces the base game xml link output
  onSave.dediStatsUpdate(...)
  ---Update Save Savegame XML files
  -- onSave.saveSaveGameXmlFiles(...)
end

-- Run when a player is starting to connect to server
function onSyncWarning(user)
  if g_server ~= nil and g_dedicatedServer ~= nil then
    g_server:broadcastEvent(ChatEvent.new(g_i18n:getText("sync_warning"),g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
  end
end

-- Run when farm is removed from server
function onRemoveFarm(farmId)
  rcDebug("onRemoveFarm")
  rcDebug(farmId)
  -- Remove remembered farm managers for farm id
  FarmManagerRC.removeFarm(farmId)
  -- Remove els loans for farm id
  -- FarmCleanUp.elsRemoveFarm(farmId)
end

-- Removes button for loans in game
function hasPlayerLoanPermission()
    return false
end

--- Makes things tick
init()