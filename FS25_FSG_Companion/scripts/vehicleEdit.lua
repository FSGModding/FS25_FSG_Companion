-- Mod: FS25_VehicleEdit

VehicleEdit = {}

local VehicleEdit_mt = Class(VehicleEdit)

function VehicleEdit:new(mission, i18n, modDirectory, modName)
	local self = setmetatable({}, VehicleEdit_mt)

	self.isServer          = mission:getIsServer()
	self.isClient          = mission:getIsClient()
	self.isMPGame          = g_currentMission.missionDynamicInfo.isMultiplayer
	self.mission           = mission
  self.i18n              = i18n
	self.modDirectory      = modDirectory
	self.modName           = modName
  self.ownerFarmId       = 0
  self.operatingTime     = 0
  self.hudUpdater        = {}
  self.curVeh                 = nil
  self.currentVehicle         = nil
  self.setValueTimerFrequency = 60

  addConsoleCommand("editVehicleFarmId", "Set the vehicle owner farm id. [farmId]", "consoleCommandEditVehicleFarmId", self)
  addConsoleCommand("storeVehicle", "Sends vehicle to users garage on website.", "consoleCommandStoreVehicle", self)

  return self
end

function VehicleEdit:update(dt)
  if g_updateLoopIndex % self.setValueTimerFrequency == 0 then
    if g_localPlayer ~= nil then
      self.hudUpdater = g_localPlayer.hudUpdater
      if type(self.hudUpdater) == "table" and self.hudUpdater ~= nil then
        if type(self.hudUpdater.object) == "table" and self.hudUpdater.object ~= nil and self.hudUpdater.object.isActive ~= nil then
          if self.hudUpdater.isVehicle then
            if self.hudUpdater.object.trainSystem == nil then
              local vehicleInView = self.hudUpdater.object:getName()
              self.ownerFarmId = self.hudUpdater.object:getOwnerFarmId()
              self.operatingTime = self.hudUpdater.object.operatingTime
            end
          end
        end
      end
    end
  end
end

function VehicleEdit:onStartMission(mission)
  rcDebug('  Info: ==VehicleEdit:onStartMission')
	if not self.isClient then
		return
	end
end

function VehicleEdit:save(mission)
  rcDebug('  Info: ==VehicleEdit:save')
end

function VehicleEdit:delete(mission)
  rcDebug('  Info: ==VehicleEdit:delete')
end

function VehicleEdit:consoleCommandEditVehicleFarmId(ownerFarmId)
  rcDebug(string.format('  Info: ==VehicleEdit:consoleCommandEditVehicleFarmId:ownerFarmId: %s', ownerFarmId))
  -- Get vehicle data for current user
  if g_currentMission.hud.controlledVehicle ~= nil then 
    self.currentVehicle = g_currentMission.hud.controlledVehicle
  elseif self.hudUpdater.object ~= nil and self.hudUpdater.object.isActive ~= nil and self.hudUpdater.isVehicle then
    self.currentVehicle = self.hudUpdater.object
  else
    self.currentVehicle = nil
  end
  -- Do stuff with vehicle
  if self.currentVehicle ~= nil then
    -- Check if user put an operating time in
    if ownerFarmId ~= nil then
      -- Check if is server or host.  If host, let the user do what is needed.
      if self.isServer then
        -- User is server or host
        rcDebug('  Info: ==VehicleEdit:consoleCommandEditVehicleFarmId: user is server.')
        -- Since we are local, go ahead and set the hours for vehicle
        self:setVehicleownerFarmId(self.currentVehicle, ownerFarmId)
        print(string.format("  Info: Vehicle FarmId set to %d", ownerFarmId))
      else
        -- Make sure user is a client
        if self.isClient then
          -- User is client.  Make sure they are admin then broadcast to server
          if g_currentMission.isMasterUser then
            rcDebug('  Info: ==VehicleEdit:consoleCommandEditVehicleFarmId: user is client and admin.')
            -- Send event data to server
            VehicleEditEvent.sendEvent(self.currentVehicle, ownerFarmId)
            rcDebug(string.format("Sent to server: Vehicle FarmId set to %.1f", ownerFarmId))
          else
            rcDebug('  Info: ==VehicleEdit:consoleCommandEditVehicleFarmId: user is client and not admin.')
            print('Info: Must be logged in as admin to run that command.')
          end
        end
      end
    else
      print("  Info: No ownerFarmId given! Usage: editVehicleFarmId [ownerFarmId (#)]")
    end
  else
    print("  Info: No Vehicle Found.  You must be next to vehicle or in it to use this command.")
  end
end

function VehicleEdit:consoleCommandStoreVehicle()
  rcDebug("  Info: ==VehicleEdit:consoleCommandStoreVehicle")
  -- Get vehicle data for current user
  if g_currentMission.hud.controlledVehicle ~= nil then 
    self.currentVehicle = g_currentMission.hud.controlledVehicle
  elseif self.hudUpdater.object ~= nil and self.hudUpdater.object.isActive ~= nil and self.hudUpdater.isVehicle then
    self.currentVehicle = self.hudUpdater.object
  else
    self.currentVehicle = nil
  end
  -- Do stuff with vehicle
  if self.currentVehicle ~= nil then
    local isOwned     = self.currentVehicle.propertyState == VehiclePropertyState.OWNED
    local isLeased    = self.currentVehicle.propertyState == VehiclePropertyState.LEASED
    local isMission   = self.currentVehicle.propertyState == VehiclePropertyState.MISSION
    if isOwned and not isLeased and not isMission then
      -- Check if is server or host.  If host, let the user do what is needed.
      if self.isServer then
        -- User is server or host
        rcDebug('  Info: ==VehicleEdit:consoleCommandStoreVehicle: user is server.')
        -- Since we are local, go ahead store vehicle
        VehicleStorageEvent.sendEvent(self.currentVehicle)
        rcDebug("Selected Vehicle was sent to storage.")
      else
        -- Make sure user is a client
        if self.isClient then
          -- User is client.  Make sure they are admin then broadcast to server
          if g_currentMission.isMasterUser then
            rcDebug('  Info: ==VehicleEdit:consoleCommandStoreVehicle: user is client and admin.')
            -- Send event data to server
            VehicleStorageEvent.sendEvent(self.currentVehicle)
            rcDebug("Selected Vehicle was sent to storage.")
          else
            rcDebug('  Info: ==VehicleEdit:consoleCommandStoreVehicle: user is client and not admin.')
            print('Info: Must be logged in as admin to run that command.')
          end
        end
      end
    else
      print("  Info: Vehicle is not owned.  You can not transfer leased or mission vehicles.")
    end
  else
    print("  Info: No Vehicle Found.  You must be next to vehicle or in it to use this command.")
  end
end

function VehicleEdit:showInfo(box)
  -- Display vehicle operating time in hud
  local minutes = self.operatingTime / 60000
	local hours = math.floor(minutes / 60)
	minutes = math.floor((minutes - hours * 60) / 6) * 10
	box:addLine(g_i18n:getText("infohud_vehicleOperatingTime"), string.format("%d.%d h", hours, minutes))
  -- Display farm owner id
  local ownerFarmId = self.ownerFarmId
	box:addLine(g_i18n:getText("infohud_vehicleOwnerFarmId"), string.format("%d", ownerFarmId))
end

function VehicleEdit:setVehicleOwnerFarmId(vehicle, ownerFarmId)
  rcDebug(' Info: ==VehicleEdit:setVehicleownerFarmId')
  rcDebug(string.format(' Info: ==VehicleEdit:setVehicleownerFarmId:vehicle: %s', vehicle))
  rcDebug(string.format(' Info: ==VehicleEdit:setVehicleownerFarmId:ownerFarmId: %s', ownerFarmId))
  if vehicle ~= nil and ownerFarmId ~= nil then
    rcDebug(string.format(' Info: ==VehicleEdit:setVehicleownerFarmId: %s', ownerFarmId))
    vehicle:setOwnerFarmId(ownerFarmId)
  else
    rcDebug(' Info: ==VehicleEdit:setVehicleownerFarmId: vehicle or operating time missing.  No worky.')
    if vehicle == nil then
      rcDebug("No Vehicle Found.  You must be next to vehicle or in it to use this command.")
    end
  end
end

-- Anything in here true will not load in game.
VehicleEdit.blockedStoreItems = {
    ["$data/objects/shippingContainer/shippingContainer.xml"] = true, -- Container
    ["$data/vehicles/fliegl/varioV2/varioV2.xml"] = true, -- Container Trailer
    ["$data/vehicles/andersonGroup/hybridX/hybridX.xml"] = true, -- Inline Bailer
    -- Block easy money stuff
    ["$data/placeables/brandless/electricityGenerators/level05/electricityGenerator05.xml"] = true,
    ["$data/placeables/brandless/productionPointsGeneric/stoneQuarry/stoneQuarry.xml"] = true,
    ["$data/placeables/mapEU/cementFactoryEU/cementFactoryPlaceable.xml"] = true,
    ["$data/placeables/brandless/productionPointsSmall/cementFactory/cementFactory.xml"] = true,
    -- add more exact items here...
}

function VehicleEdit:loadItemsFromXML(superFunc, filename, baseDirectory, customEnvironment)
    rcDebug("VehicleEdit:loadItemsFromXML")
    local xmlFile = XMLFile.load("storeItemsXML", filename)

    if xmlFile == nil then
        return
    end

    xmlFile:iterate("storeItems.storeItem", function(_, itemKey)
        local itemXmlFilename   = xmlFile:getString(itemKey .. "#xmlFilename")
        local extraContentId    = xmlFile:getString(itemKey .. "#extraContentId")

        rcDebug(tostring(itemXmlFilename))

        if itemXmlFilename ~= nil and VehicleEdit.blockedStoreItems[itemXmlFilename] then
            print(("Info: Blocked store item: %s"):format(itemXmlFilename))
        else

            g_asyncTaskManager:addSubtask(function()
                local modTitle = ""

                -- Resolve full path to the store item XML
                local resolvedFilename = Utils.getFilename(itemXmlFilename, baseDirectory)

                -- Detect if the item comes from a mod
                local modName, _ = Utils.getModNameAndBaseDirectory(resolvedFilename)

                local allowScripts
                if modName == nil then
                    -- Basegame item
                    allowScripts = false
                else
                    local mod = g_modManager:getModByName(modName)
                    if mod ~= nil then
                        modTitle = mod.title
                    end

                    -- Scripts allowed only for non-DLC mods
                    allowScripts = not mod.isDLC
                end

                -- Load the store item into the shop
                self:loadItem(
                    itemXmlFilename,
                    baseDirectory,
                    customEnvironment,
                    allowScripts,
                    false,
                    modTitle,
                    extraContentId
                )
            end, string.format(
                "StoreManager - Load store item '%s'",
                itemXmlFilename
            ))
        end
    end)

    xmlFile:delete()
end