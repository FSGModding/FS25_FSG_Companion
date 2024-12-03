rcDebug("VehicleStorage Class")

VehicleStorage = {}
local VehicleStorage_mt = Class(VehicleStorage)

function VehicleStorage.new(mission, i18n, modDirectory, modName)
  rcDebug("VehicleStorage-New")
  local self = setmetatable({}, VehicleStorage_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.previousVehicle  = nil
	return self
end

-- Add store vehicle button to shop menu
function VehicleStorage:setVehicle(vehicle, second)
  -- rcDebug("VehicleStorage-setVehicle")
  -- rcDebug(self)
  if vehicle ~= nil and self.isDealer == true then 
    -- Do not display on single player.
    if g_currentMission.missionDynamicInfo.isMultiplayer then
      if vehicle.propertyState == VehiclePropertyState.OWNED then

        -- Get vehicle id
        if vehicle.id ~= self.previousVehicle then

          rcDebug("Vehicle Owned")
        
          if self.storageButton == nil then
            local storageCost = 1000
            local StorageElement = self.sellButton:clone()
            StorageElement:setText(string.format("%s (%s)", g_i18n:getText("button_storeVehicle"),g_i18n:formatMoney(storageCost, 0, true, true)))
            StorageElement:setInputAction("MENU_MAP_ACTION_1")
            StorageElement:setVisible(vehicle ~= nil)
            StorageElement.onClickCallback = function ()
              VehicleStorage:storeVehicleConfirm(vehicle)
            end
            self.sellButton.parent:addElement(StorageElement)
            self.storageButton = StorageElement

            self.previousVehicle = vehicle.id
          end
        end
      else
        rcDebug("Vehicle Not Owned")
        if self.storageButton ~= nil then
          self.storageButton:setText(string.format("%s", g_i18n:getText("button_storeVehicle")))
          self.storageButton:setDisabled(true)
        end
      end
    end
  else
    rcDebug("No Vehicles Found")
    if self.storageButton ~= nil then
      self.storageButton:setText(string.format("%s", g_i18n:getText("button_storeVehicle")))
      self.storageButton:setDisabled(true)
    end
  end
end

-- Confirm with player to store vehicle
function VehicleStorage:storeVehicleConfirm(vehicle)
	YesNoDialog.show(function(yes)
    if yes then
      if g_currentMission.missionDynamicInfo.isMultiplayer then
        VehicleStorageEvent.sendEvent(vehicle)
      else
        -- VehicleStorage:storeVehicle(vehicle)
      end
    end
	end, nil, g_i18n:getText("button_storeVehicleConfirm"))
end

-- Store the vehicle.  Save xml to outbox and remove from game.
function VehicleStorage:storeVehicle(vehicle)
  rcDebug("VehicleStorage-storeVehicle")

  if vehicle ~= nil then

    -- Register new xml schema for vehicles
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#imageFilename", "Mod Image Filename")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#vehType", "Vehicle Type")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#sellPrice", "Vehicle Sell Price")
    schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#name", "Vehicle Name")

    local vehicleId = vehicle.id
    local vehicleOwnerFarmId = vehicle.ownerFarmId

    local commandOutboxDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"    
    local transactionId = g_fsgSettings:getTransactionId()
    local vehicleFileName = commandOutboxDir .. "storeVehicle-" .. vehicleId .. "-" .. transactionId .. "-" .. vehicleOwnerFarmId .. ".xml"
    local vehicleXMLFile = XMLFile.create("vehicleXMLFile", vehicleFileName, "vehicles", Vehicle.xmlSchemaSavegame)
    
    if vehicleXMLFile ~= nil then
      local key = string.format("vehicles.vehicle(%d)", 0)
      vehicle.currentSavegameId = 1
      local vehicle_getSellPrice = "0"
      if vehicle.getSellPrice ~= nil then vehicle_getSellPrice = vehicle:getSellPrice() end 
      local modName = vehicle.customEnvironment
      if modName ~= nil then
        vehicleXMLFile:setValue(key .. "#modName", modName)
      end
      -- More Details For Website Display
      vehicle:saveToXMLFile(vehicleXMLFile, key, {})
      vehicleXMLFile:setValue(key .. "#name", tostring(vehicle:getFullName()))
      vehicleXMLFile:setValue(key .. "#imageFilename", tostring(vehicle:getImageFilename()))
      vehicleXMLFile:setValue(key .. "#vehType", tostring(vehicle.typeName))
      vehicleXMLFile:setValue(key .. "#sellPrice", tostring(vehicle_getSellPrice))
      vehicleXMLFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
      vehicleXMLFile:save()
      vehicleXMLFile:delete()
      -- Remove vehicle from game
      vehicle:delete()
      -- Chage the farm for the transfer fee
      local farm = g_farmManager:getFarmById(vehicleOwnerFarmId)
      if farm ~= nil then
      local storageCost = -1000
      local moneyType = MoneyType.VEHICLE_RUNNING_COSTS
      g_currentMission:addMoneyChange(storageCost, vehicleOwnerFarmId, moneyType, true)
        rcDebug("Website Money Transfer")
        farm:changeBalance(storageCost, moneyType)
      end
    end

    -- Create a backup of the vehicle transfer just in case there is an error on server side.  
    local commandBackupDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/backup/"
    local vehicleFileNameBackup = commandBackupDir .. "storeVehicle-" .. vehicleId .. "-" .. transactionId .. "-" .. vehicleOwnerFarmId .. ".xml"
    copyFile(vehicleFileName, vehicleFileNameBackup, true)

  else
    rcDebug("Vehicle Data Missing")
  end
end

-- Load vehicle from xml file
function VehicleStorage:loadVehicle(xmlFileVehicle)
  rcDebug("VehicleStorage-storeVehicle")

  local function asyncCallbackFunction(_, vehicle, vehicleLoadState, arguments)
    rcDebug("vehicleLoadState")
    rcDebug(vehicleLoadState)
    if vehicleLoadState == VehicleLoadingState.OK then
      print("Vehcile Spawned From Storage.  Send Confirmation.")
      return true
    else  
      printf("Warning: corrupt vehicles xml '%s', vehicle '%s' could not be loaded", arguments.xmlFilename, arguments.key)
      return false
    end
  end

  if xmlFileVehicle then

    local xmlFile = XMLFile.load("VehiclesXML", xmlFileVehicle, Vehicle.xmlSchemaSavegame)
    local i = 1
    local key = string.format("vehicles.vehicle(%d)", i - 1)
    self.vehiclesToSpawnLoading = true
    local args = {
      xmlFilename = xmlFileVehicle,
      key = key,
      xmlFile = xmlFile
    }

    -- Get the farmId for vehicle from xml and make sure the farm exists.
    local vehicleFarmId = xmlFile:getValue(key .. "#farmId")
    rcDebug("Vehicle Farm Id:")
    rcDebug(vehicleFarmId)
    if g_farmManager:getFarmById(vehicleFarmId) == nil and vehicleFarmId ~= 0 then
      -- Return the error data
      local errorMsg = { 
        farmId = vehicleFarmId,
        errorMsg = "Vehicle Load Error - Farm Not Found"
      }
      return errorMsg
    end

    local vehicle = VehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, nil, args, true, false)

    if vehicle ~= VehicleLoadingState.OK then
      local transferData = {
        farmId = vehicleFarmId,
        info = "Vehicle Transfer Successful"
      }
      return transferData
    else
      -- Return the error data
      local errorMsg = { 
        farmId = vehicleFarmId,
        errorMsg = "Vehicle Load Error"
      }
      return errorMsg
    end
    
  end
end
