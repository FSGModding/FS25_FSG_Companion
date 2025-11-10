rcDebug("RemoteCommands Class")

RemoteCommands = {}
local RemoteCommands_mt = Class(RemoteCommands)

function RemoteCommands.new(mission, i18n, modDirectory, modName)
  rcDebug("RC-new")
	local self = setmetatable({}, RemoteCommands_mt)
  self.mission                = mission
  self.i18n                   = i18n
  self.modDirectory           = modDirectory
  self.modName                = modName
  self.setValueTimerFrequency = 600
  self.commandInboxDir        = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/inbox/"
  self.commandOutboxDir       = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox/"
  self.files                  = {}
  self.fileTimestamps         = {}

        return self
end

function RemoteCommands:update(dt)
        if not g_server and not g_dedicatedServer then
                return
        end

        if g_updateLoopIndex % self.setValueTimerFrequency == 0 then
    getFiles(self.commandInboxDir, "checkNewFiles", self)
  end

  -- Periodically clean up stale timestamp entries to avoid memory growth
  self:cleanOldFileTimestamps(3600)
end

function RemoteCommands:checkNewFiles(filename, isDirectory)
  rcDebug("RC-checkNewFiles")
  if isDirectory then 
    return
  end
  if filename ~= nil then
    -- Check to see if inbox is enabled
    local inboxActive = g_fsgSettings.settings:getValue("inboxActive")
	  if inboxActive then
      self:runNewFiles(filename)
    end
  end
end

-- Checks for incoming new commands from bot to server
function RemoteCommands:runNewFiles(file)
  rcDebug("RC-runNewFiles")
  rcDebug(file)

  if file ~= nil then

    -- make sure file exists
    local loadFile = self.commandInboxDir .. file
    if ( fileExists (loadFile) ) then

      local key = "commands"

      local xmlFile = XMLFile.load(key, loadFile)

      local commandData = {}
      local commandComplete = false
      local transferData = nil
      local command = nil

      -- Delete the file if not valid
      if xmlFile == nil then
        print(string.format("  Info: FSG Companion Command File Not Complete or Valid.  File: %s",(tostring(file))))
        if self:isFileTooOld(file, 600) then
          rcDebug("RemoteCommands: Deleting old invalid file (older than 10 min): " .. tostring(file))
          deleteFile(loadFile)
          self.fileTimestamps[file] = nil
        else
          rcDebug("RemoteCommands: Skipping file, not a valid XML yet: " .. tostring(file))
        end
        return false
      end

      -- File valid - Remove from log
      self.fileTimestamps[file] = nil

      -- Check if file has already been processed
      if g_GameLogs:InboxLog(file, xmlFile) then

        -- Get command data
        xmlFile:iterate(key .. ".command", function (_, commandKey)
          command = xmlFile:getString(commandKey .. "#command");

          if command ~= nil then 
            -- Start commands loop
            rcDebug("Process Remote Command")

            -- Send Chat command 
            if command == "sendChat" then 
              commandData = {
                id       = xmlFile:getInt(commandKey .. "#id"),
                command  = xmlFile:getString(commandKey .. "#command"),
                fromUser = xmlFile:getString(commandKey .. "#fromUser"),
                content  = xmlFile:getString(commandKey .. "#content"),
              }
              if commandData ~= nil then 
                if RemoteCommands:runChatCommand(commandData) then
                  commandComplete = true
                end
              end
            -- Command that makes a user farm manager based on their farm id and unique user id
            elseif command == "makeFarmManager" then 
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                userNickname = xmlFile:getString(commandKey .. "#userNickname"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                uniqueUserId = xmlFile:getString(commandKey .. "#uniqueUserId"),
              }
              if commandData ~= nil then 
                if RemoteCommands:makeFarmManager(commandData) then
                  commandComplete = true
                end
              end
            -- Command that bands a user based on their unique user id
            elseif command == "banUser" then 
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                userNickname = xmlFile:getString(commandKey .. "#userNickname"),
                uniqueUserId = xmlFile:getString(commandKey .. "#uniqueUserId"),
              }
              if commandData ~= nil then 
                transferData = RemoteCommands:banUser(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that bands a user based on their unique user id
            elseif command == "unBanUser" then 
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                userNickname = xmlFile:getString(commandKey .. "#userNickname"),
                uniqueUserId = xmlFile:getString(commandKey .. "#uniqueUserId"),
              }
              if commandData ~= nil then 
                transferData = RemoteCommands:unBanUser(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that adds money for farm based on farm id
            elseif command == "moneyTransfer" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                amount = xmlFile:getInt(commandKey .. "#amount"), 
              }
              if commandData ~= nil then
                transferData = RemoteCommands:moneyTransfer(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that triggers a savegame
            elseif command == "saveGame" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
              }
              if commandData ~= nil then
                g_currentMission:saveSavegame()
                commandComplete = true
              end
            -- Commaand that creates a new farm
            elseif command == "createFarm" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                name = xmlFile:getString(commandKey .. "#name"),
                color = xmlFile:getInt(commandKey .. "#color"),
                password = xmlFile:getString(commandKey .. "#password"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                startMoney = xmlFile:getInt(commandKey .. "#startMoney"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:createFarm(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Commaand that creates a new farm
            elseif command == "deleteFarm" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:deleteFarm(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that adds fill to coop silo
            elseif command == "coopSiloStore" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                fillType = xmlFile:getString(commandKey .. "#fillType"),
                amount = xmlFile:getInt(commandKey .. "#amount"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:coopSiloStore(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that adds pallet to coop silo
            elseif command == "coopPalletStore" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                configFileName = xmlFile:getString(commandKey .. "#configFileName"),
                isBigBag = xmlFile:getString(commandKey .. "#isBigBag"),
                fillTypeName = xmlFile:getString(commandKey .. "#fillTypeName"),
                fillLevel = xmlFile:getInt(commandKey .. "#fillLevel"),
                configFillUnit = xmlFile:getInt(commandKey .. "#configFillUnit"),
                configFillVolume = xmlFile:getInt(commandKey .. "#configFillVolume"),
                ConfigTreeSaplingType = xmlFile:getInt(commandKey .. "#ConfigTreeSaplingType")
              }
              if commandData ~= nil then
                transferData = RemoteCommands:coopPalletStore(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Command that adds bale to coop silo
            elseif command == "coopBaleStore" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
                xmlFilename = xmlFile:getString(commandKey .. "#xmlFilename"),
                fillLevel = xmlFile:getString(commandKey .. "#fillLevel"),
                wrappingState = xmlFile:getString(commandKey .. "#wrappingState"),
                supportsWrapping = xmlFile:getString(commandKey .. "#supportsWrapping"),
                baleValueScale = xmlFile:getString(commandKey .. "#baleValueScale"),
                wrappingColor = xmlFile:getString(commandKey .. "#wrappingColor"),
                fillTypeName = xmlFile:getString(commandKey .. "#fillTypeName"),
                isFermenting = xmlFile:getString(commandKey .. "#isFermenting"),
                fermentationTime = xmlFile:getString(commandKey .. "#fermentationTime"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:coopBaleStore(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Commaand that sets ownership of farmland
            elseif command == "purchaseFarmland" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmlandId = xmlFile:getInt(commandKey .. "#farmlandId"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:purchaseFarmland(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Commaand that removes ownership of farmland
            elseif command == "sellFarmland" then
              commandData = {
                id = xmlFile:getInt(commandKey .. "#id"),
                command = xmlFile:getString(commandKey .. "#command"),
                farmlandId = xmlFile:getInt(commandKey .. "#farmlandId"),
                farmId = xmlFile:getInt(commandKey .. "#farmId"),
              }
              if commandData ~= nil then
                transferData = RemoteCommands:sellFarmland(commandData)
                if transferData ~= nil then
                  commandComplete = true
                end
              end
            -- Add elseif above here for another command
            -- End of command watch
            end
            -- End Commands loop
          end

        end) -- end xmlFile:iterate

        -- Check to see if not a direct command file
        if command == nil then
          rcDebug("Getting Command From Filename")
          local fileSplit = string.split(file, "-")
          if fileSplit ~= nil and fileSplit[2] ~= nil then 
            local id = 0
            if fileSplit[6] ~= nil then 
              id = fileSplit[6]
            end
            command = fileSplit[2]
            commandData = {
              serverId = fileSplit[1],
              command = fileSplit[2],
              vehicleId = fileSplit[3],
              randomNum = fileSplit[4],
              farmId = fileSplit[5],
              id = id,
            }
          end
          -- Command that add vehicle to game from website
          if command == "storeVehicle" then
            -- Run the vehicleStorage load function
            rcDebug("Command: storeVehicle")
            transferData = VehicleStorage:loadVehicle(loadFile)
            commandData.id = commandData.vehicleId
            if transferData ~= nil then
              commandComplete = true
            end
          -- Add elseif here for another command
          end
        end

        -- check if the command completed
        if commandComplete then
          -- create confirmation command
          rcDebug("Creating confirmation file.")
          local confirmationFile = self.commandOutboxDir .. "confirm-" .. commandData.id .. "-" .. tostring(commandData.command) .. "-" .. math.random(9999) .. math.random(9999) .. ".xml"
          xmlFile = createXMLFile(key, confirmationFile, key)
          setXMLInt(xmlFile, key .. ".command#id", tonumber(commandData.id))
          setXMLString(xmlFile, key .. ".command#command", tostring(commandData.command))
          if transferData ~= nil then
            if transferData.before ~= nil then 
              setXMLString(xmlFile, key .. ".command#before", tostring(transferData.before))
            end 
            if transferData.amount ~= nil then
              setXMLInt(xmlFile, key .. ".command#amount", tonumber(transferData.amount))
            end 
            if transferData.after ~= nil then
              setXMLInt(xmlFile, key .. ".command#after", tonumber(transferData.after))
            end
            if transferData.errorMsg ~= nil then
              setXMLString(xmlFile, key .. ".command#errorMsg", tostring(transferData.errorMsg))
            end
            if transferData.info ~= nil then
              setXMLString(xmlFile, key .. ".command#info", tostring(transferData.info))
            end
            if transferData.farmlandId ~= nil then
              setXMLString(xmlFile, key .. ".command#farmlandId", tostring(transferData.farmlandId))
            end
          end
          if commandData.farmId ~= nil and tonumber(commandData.farmId) ~= nil then
            setXMLInt(xmlFile, key .. ".command#farmId", tonumber(commandData.farmId))
          elseif transferData ~= nil and transferData.farmId ~= nil and tonumber(transferData.farmId) ~= nil then
            setXMLInt(xmlFile, key .. ".command#farmId", tonumber(transferData.farmId))
          end 
          setXMLString(xmlFile, key .. ".command#confirmation", "true")
          saveXMLFile(xmlFile)
          delete(xmlFile)

          print(string.format("  Info: FSG Companion Command File Successfully Processed.  File: %s",(tostring(file))))

          -- delete the command file
          deleteFile(loadFile)
        end
      else
        -- Command file already accepted.  Delete it.
        print(string.format("  Info: FSG Companion Command File Already Processed.  Deleting file: %s",(tostring(file))))
        deleteFile(loadFile)
      end
    end 
  end
end


-- chat command funciton 
function RemoteCommands:runChatCommand(commandData)
  rcDebug("RemoteCommands:runChatCommand")
  -- Send chat message to multiplayer chat
  if commandData ~= nil then
    local fromUser = commandData.fromUser
    local content = commandData.content
    if g_server ~= nil and g_dedicatedServer ~= nil and fromUser ~= nil and content ~= nil then
        g_server:broadcastEvent(ChatEvent.new(content,"Discord: " .. fromUser,FarmManager.SPECTATOR_FARM_ID,0))
        return true
    end
  end
end

-- make user farm manager of farm
function RemoteCommands:makeFarmManager(commandData)
  rcDebug("RemoteCommands:makeFarmManager")
  -- Add user to the Farm Manager file as a FM based on uniqueUserId and farmId
  if commandData ~= nil then
    local userNickname = commandData.userNickname
    local farmId = tonumber(commandData.farmId)
    local uniqueUserId = commandData.uniqueUserId
    if g_server ~= nil and farmId ~= nil and uniqueUserId ~= nil then
      -- Check if user is on server, and give them fm for said farm
      local user = g_currentMission.userManager:getUserByUniqueId(uniqueUserId)
      if user ~= nil then
        local userFarm = g_farmManager:getFarmByUserId(user:getId())
        local userFarmId = tonumber(userFarm.farmId)
        if user ~= nil and userFarm ~= nil and userFarmId == farmId then
          rcDebug("Giving Player FM Perms")
          userFarm:promoteUser(user:getId())
        end
      end
      -- We want to add fm to log file if they are on server or not.  
      g_farmManagerRC:addFarmManagerLog(userNickname, uniqueUserId, farmId)
      return true
    end
  end
end

-- make user farm manager of farm
function RemoteCommands:moneyTransfer(commandData)
  rcDebug("RemoteCommands:moneyTransfer")
  -- Transfer money to or from farm
  if commandData ~= nil then
    local destinationFarmId = tonumber(commandData.farmId)
    local amount = tonumber(commandData.amount)
    if g_server ~= nil and destinationFarmId ~= nil and amount ~= nil then
      if g_currentMission:getIsServer() then
        if amount < 0 then amount = amount + 1 end
        -- Get the farm data
        local farm = g_farmManager:getFarmById(destinationFarmId)
        if farm ~= nil then
          -- -- Make sure farm does not have an active loan
          -- local gameLoan = 0
          -- if farm.gameLoan ~= nil then
          --   gameLoan = farm:getLoan()
          -- end
          -- Get total before Transfer
          local beforeAmount = farm:getBalance()
          -- Make sure amount is not more than the farm has
          local newBal = beforeAmount + amount
          -- Check if balnace is positive, then check if adding money
          if newBal > 0 and amount ~= 0 then
            -- Transfer Money
            local moneyType = MoneyType.TRANSFER
            g_currentMission:addMoneyChange(amount, destinationFarmId, moneyType, true)
            if farm ~= nil then
              rcDebug("Website Money Transfer")
              farm:changeBalance(amount, moneyType)
            end
          end
          -- Get total after Transfer
          local afterAmount = farm:getBalance()
          -- Return the transfer data
          local transferData = {
            before = beforeAmount,
            amount = amount,
            after  = afterAmount,
          }
          return transferData
        else 
          -- Return the transfer data
          local errorMsg = { 
            errorMsg = "farmId error"
          }
          return errorMsg
        end
      end
    end
  end
end

-- Function to create or update farm.  
function RemoteCommands:createFarm(commandData)
  rcDebug('RemoteCommands:createFarm')
  rcDebug(commandData)
  -- Check if farm already exists by farmId
  if commandData.farmId ~= nil then
    rcDebug('Update Farm')
    local farm = g_farmManager:getFarmById(commandData.farmId)
    rcDebug(farm)
    if farm ~= nil then

      -- Farm already exists, lets check if we are updating stuff from website
      local newFarm = {}
      -- Check if farm name is being updated
      if commandData.name ~= nil then
        newFarm.name = HTMLUtil.decodeFromHTML(commandData.name)
      else 
        newFarm.name = tostring(farm.name)
      end
      -- Check if password is being updated
      if commandData.password ~= nil then
        newFarm.password = tostring(commandData.password)
      else 
        newFarm.password = tostring(farm.password)
      end

      -- Check if color is being updated
      if commandData.color ~= nil then
        newFarm.color = tonumber(commandData.color)
      else 
        newFarm.color = tonumber(farm.color)
      end
      if newFarm.color == nil or type(newFarm.color) ~= "number" then
        -- Get next avaialbe farm color
        newFarm.color = RemoteCommands:getNextFarmColor()
      end

      rcDebug("Farm Update Data")
      rcDebug(newFarm)
      rcDebug(farm.farmId)

      -- Send the farm update to server
      g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(newFarm.name, newFarm.color, newFarm.password, true, farm.farmId))

      -- Send new farm data back to website log
      local confirmData = {
        farmId = farm.farmId,
        info = "Farm Updated Successfully."
      }
      return confirmData

    else

      -- Try creating new farm
      rcDebug('New Farm')
      -- Start the process of creating a new farm
      local newFarm = {}
      -- Make sure we do not have the max number of farms on the server
      -- if table.getn(g_farmManager:getFarms()) == 9 then
      --   local confirmData = { 
      --     errorMsg = "Max Farms Limit Reached on Server.",
      --     info = "New farm was not created on the server."
      --   }
      --   return confirmData
      -- end

      -- Put the new farm data together
      if commandData.farmId ~= nil then 
        newFarm.farmId = tonumber(commandData.farmId)
      end

      if commandData.name ~= nil then 
        newFarm.name = tostring(commandData.name)
      else 
        newFarm.name = tostring("Unknown")
      end

      if commandData.color ~= nil then
        newFarm.color = tonumber(commandData.color)
      end

      if newFarm.color == nil or type(newFarm.color) ~= "number" then
        -- Get next avaialbe farm color
        newFarm.color = RemoteCommands:getNextFarmColor()
      end

      if commandData.password ~= "" then
        newFarm.password = tostring(commandData.password)
      end

      rcDebug("Farm Create Data")
      rcDebug(newFarm)

      -- Create a new farm on the server
      local farm = g_farmManagerRC:createFarm(newFarm.name, newFarm.color, newFarm.password, newFarm.farmId)

      rcDebug("Created Farm Data")
      rcDebug(farm)

      if farm ~= nil then
        local newFarmId = tonumber(farm.farmId)
        -- Check if start money is being set
        if commandData.startMoney ~= nil then
          local startMoney = tonumber(commandData.startMoney)
          local currentBalance = farm:getBalance()
          local moneyChange = startMoney - currentBalance
          local moneyType = MoneyType.TRANSFER
          g_currentMission:addMoneyChange(moneyChange, newFarmId, moneyType, true)
          if farm ~= nil then
            rcDebug("Start Money Update")
            farm:changeBalance(moneyChange, moneyType)
          end
        end

        -- Check for loan set
        local startLoan = tonumber(0)

        -- Set the loan amount
        farm.loan = startLoan
        
        g_server:broadcastEvent(ChangeLoanEvent.new(startLoan, newFarmId), false, nil)
        g_messageCenter:publish(ChangeLoanEvent)

        -- Update storages for all placeables to match farms
        g_fillManager:updateStorages()

        local confirmData = {}
        if newFarmId ~= nil then 
          -- Send new farm data back to website log
          confirmData = {
            farmId = newFarmId,
            info = "Farm Created Successfully."
          }
        else
          -- Send new farm data back to website log
          confirmData = {
            info = "Error Creating New Farm.",
            errorMsg = "create farm error"
          }
        end
        return confirmData
      else
        -- Send new farm data back to website log
        local confirmData = {
          info = "Error Creating New Farm.",
          errorMsg = "create farm error"
        }
        return confirmData
      end

    end
  else
    -- Send new farm data back to website log
    local confirmData = {
      info = "Error Creating New Farm.",
      errorMsg = "create farm error"
    }
    return confirmData
  end
end

-- Function the deletes a farm from a server
function RemoteCommands:deleteFarm(commandData)
  rcDebug('RemoteCommands:deleteFarm')
  rcDebug(commandData)
  -- Check if farm already exists by farmId
  if commandData.farmId ~= nil then
    rcDebug('Delete Farm')
    local farm = g_farmManager:getFarmById(commandData.farmId)
    rcDebug(farm)
    if farm ~= nil then
      -- Farm found, let's start the deletion process
      -- Check for users on farm, and kick them
      if farm.activeUsers ~= nil then
        for _, user in ipairs(farm.activeUsers) do
          g_farmManager:removeUserFromFarm(user.userId)
        end
      end
      if farm:canBeDestroyed() then
        -- Delete the farm and everything tied to it
        g_client:getServerConnection():sendEvent(FarmDestroyEvent.new(commandData.farmId))
        -- Update storages for all placeables to match farms
        g_fillManager:updateStorages()
        -- Send new farm data back to website log
        local confirmData = {
          farmId = commandData.farmId,
          info = "Farm Deleted Successfully."
        }
        return confirmData
      else
        -- Send new farm data back to website log
        local confirmData = {
          info = "Error Deleting Farm.",
          errorMsg = "delete farm error"
        }
        return confirmData
      end
    else
      -- Farm not found or already deleted
      -- Send new farm data back to website log
      local confirmData = {
        info = "Error Deleting Farm.",
        errorMsg = "delete farm error"
      }
      return confirmData
    end
  else
    -- Farm Id missing
    -- Send new farm data back to website log
    local confirmData = {
      info = "Error Deleting Farm.",
      errorMsg = "delete farm error"
    }
    return confirmData
  end
end

-- Function that gets next avaialbe farm color
function RemoteCommands:getNextFarmColor()
	local farms = g_farmManager:getFarms()

	for farmColorIndex, color in ipairs(Farm.COLORS) do
		local colorTaken = false

		for _, farm in pairs(farms) do
			if farm.farmId ~= FarmManager.SPECTATOR_FARM_ID and farm.color == farmColorIndex then
				colorTaken = true

				break
			end
		end

		if not colorTaken then
			return farmColorIndex
		end
	end
  return 1
end

-- Function to create event for adding fill to silo
function RemoteCommands:coopSiloStore(commandData)
  rcDebug("RC-coopSiloStore")
  if commandData.farmId ~= nil and commandData.fillType ~= nil and commandData.amount ~= nil then
    -- Check to make sure this server supports the fillType being sent
    local fillType = g_fillTypeManager:getFillTypeByName(commandData.fillType)
    if fillType ~= nil then
      g_coopSiloManager:addFillToSilo(commandData.farmId,commandData.fillType,commandData.amount)
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "Fill Transfer Successful."
      }
      return confirmData
    else
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "FillType Not Supported.",
        errorMsg = "fill transfer error"
      }
      return confirmData
    end
  end
  -- Send data back to website
  local confirmData = {
    farmId = commandData.farmId,
    info = "Fill Transfer Unsuccessful.",
    errorMsg = "fill transfer error"
  }
  return confirmData
end

-- Function to create event for adding pallets to coop spawn area
function RemoteCommands:coopPalletStore(commandData)
  rcDebug("RC-coopPalletStore")
  if commandData.farmId ~= nil and commandData.configFileName ~= nil and commandData.isBigBag ~= nil and commandData.fillTypeName ~= nil and commandData.fillLevel ~= nil then
    -- Check to make sure this server supports the fillType being sent
    local fillType = g_fillTypeManager:getFillTypeByName(commandData.fillTypeName)
    if fillType ~= nil then
      g_coopSiloManager:addPallet(commandData.farmId,commandData.configFileName,commandData.isBigBag,commandData.fillTypeName,commandData.fillLevel,commandData.configFillUnit,commandData.configFillVolume,commandData.ConfigTreeSaplingType,storeItem)
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "Pallet Transfer Successful."
      }
      return confirmData
    else
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "Pallet Store Item Not Supported.",
        errorMsg = "pallet transfer error"
      }
      return confirmData
    end
  end
  -- Send data back to website
  local confirmData = {
    farmId = commandData.farmId,
    info = "Pallet Transfer Unsuccessful.",
    errorMsg = "pallet transfer error"
  }
  return confirmData  
end

-- Function to create event for adding bales to coop spawn area
function RemoteCommands:coopBaleStore(commandData)
  rcDebug("RC-coopBaleStore")
  if commandData.farmId ~= nil and commandData.xmlFilename ~= nil and commandData.fillLevel ~= nil and commandData.wrappingState ~= nil and commandData.supportsWrapping ~= nil and commandData.fillTypeName ~= nil then
    -- Check to make sure this server supports the fillType being sent
    rcDebug("commandData.fillTypeName")
    rcDebug(commandData.fillTypeName)
    local fillType = g_fillTypeManager:getFillTypeByName(commandData.fillTypeName)
    rcDebug("fillType")
    rcDebug(fillType)
    if fillType ~= nil then
      -- Check if wrapping colors are set
      if commandData.wrappingColor == nil or commandData.wrappingColor == '' then
        commandData.wrappingColor = "1-1-1"
      end
      if commandData.variationIndex == nil or commandData.variationIndex == '' then
        commandData.variationIndex = "1"
      end
      g_coopSiloManager:addBale(commandData.farmId,commandData.xmlFilename,commandData.fillLevel,commandData.wrappingState,commandData.supportsWrapping,commandData.baleValueScale,commandData.wrappingColor,commandData.fillTypeName,commandData.isFermenting,commandData.fermentationTime,commandData.variationIndex)
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "Bale Transfer Successful."
      }
      return confirmData
    else
      -- Send data back to website
      local confirmData = {
        farmId = commandData.farmId,
        info = "FillType Not Supported.",
        errorMsg = "bale transfer error"
      }
      return confirmData
    end
  end
  -- Send data back to website
  local confirmData = {
    farmId = commandData.farmId,
    info = "Bale Transfer Unsuccessful.",
    errorMsg = "bale transfer error"
  }
  return confirmData  
end

-- Function to set ownership of farmland to a farmId
function RemoteCommands:purchaseFarmland(commandData)
  rcDebug("RemoteCommands - purchaseFarmland")

  -- Check to make sure the farm exists
  local farm = g_farmManager:getFarmById(commandData.farmId)
  if farm == nil then
    -- Send data back to website
    local confirmData = {
      farmlandId = commandData.farmlandId,
      farmId = commandData.farmId,
      info = "Farm Not Found.",
      errorMsg = "farmland error"
    }
    return confirmData 
  end

  -- Check to make sure the farmland is not already owned
  if g_farmlandManager:getFarmlandOwner(commandData.farmlandId) ~= FarmlandManager.NO_OWNER_FARM_ID then
    -- Send data back to website
    local confirmData = {
      farmlandId = commandData.farmlandId,
      farmId = commandData.farmId,
      info = "Farmland already owned.",
      errorMsg = "farmland error"
    }
    return confirmData 
  end

  -- Set the land ownership to the new farm
  if g_farmlandManager:setLandOwnership(commandData.farmlandId, commandData.farmId) then
    rcDebug("Farmland Ownership Set.  Update Clients.")
    FarmlandUpdateEvent.sendEvent(commandData.farmlandId, commandData.farmId)
    -- Send data back to website
    local confirmData = {
      farmlandId = commandData.farmlandId,
      farmId = commandData.farmId,
      info = "Farmland Purchase Successful."
    }
    return confirmData
  else
    -- Send data back to website
    local confirmData = {
      farmlandId = commandData.farmlandId,
      farmId = commandData.farmId,
      info = "Farmland purchase error.",
      errorMsg = "farmland error"
    }
    return confirmData 
  end
end

-- Function to set ownership of farmland to a non owned state
function RemoteCommands:sellFarmland(commandData)

  -- Check to make sure the farmland is not already owned
  if g_farmlandManager:getFarmlandOwner(commandData.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID then
    -- Send data back to website
    local confirmData = {
      farmlandId = commandData.farmlandId,
      farmId = commandData.farmId,
      info = "Farmland not owned.",
      errorMsg = "farmland error"
    }
    return confirmData 
  end

  -- Check for any owned building on land and remove them
  rcDebug("Check placeables to see if they are on this land.")
  for i = #g_currentMission.placeableSystem.placeables, 1, -1 do
    local placeable = g_currentMission.placeableSystem.placeables[i]
    if placeable ~= nil then
      local placeableFarmlandId = nil
      if placeable.spec_fence ~= nil and placeable.spec_fence.segments ~= nil and placeable.spec_fence.segments[i] then
        rcDebug("Fence Found")
        rcDebug(placeable.spec_fence.segments[i].x1)
        rcDebug(placeable.spec_fence.segments[i].z1)
        placeableFarmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(placeable.spec_fence.segments[i].x1 + placeable.position.x, placeable.spec_fence.segments[i].z1 + placeable.position.z)
        rcDebug("placeableFarmlandId")
        rcDebug(placeableFarmlandId)
      else
        local posX, _, posZ = getWorldTranslation(placeable.rootNode)
        placeableFarmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(posX, posZ)
      end
      if placeableFarmlandId == commandData.farmlandId or (placeable.farmlandId ~= nil and placeable.farmlandId == commandData.farmlandId) then
        if placeable:getOwnerFarmId() == commandData.farmId then
          if placeable:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
            placeable:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
          else
            placeable:delete()
          end
        end
      end
    end
  end

  -- Update the farm ownership to none
  g_farmlandManager:setLandOwnership(commandData.farmlandId, FarmlandManager.NO_OWNER_FARM_ID)
  FarmlandUpdateEvent.sendEvent(commandData.farmlandId, FarmlandManager.NO_OWNER_FARM_ID)

  -- Send data back to website
  local confirmData = {
    farmlandId = commandData.farmlandId,
    farmId = commandData.farmId,
    info = "Farmland Successfully Sold."
  }
  return confirmData 

end

function RemoteCommands:isFileTooOld(file, ageLimitSeconds)
  rcDebug("RemoteCommands:isFileTooOld")
  if self.fileTimestamps[file] == nil then
    self.fileTimestamps[file] = getTime()
    rcDebug("File: " .. file .. " - TS: " .. self.fileTimestamps[file])
  end
  
  local fileAge = getTime() - self.fileTimestamps[file]
  if fileAge > ageLimitSeconds then
    return true
  end
  return false
end

-- Removes timestamp entries for files that no longer exist or are older than
-- the provided max age in seconds
function RemoteCommands:cleanOldFileTimestamps(maxAgeSeconds)
  if self.fileTimestamps == nil then
    return
  end
  for filename, ts in pairs(self.fileTimestamps) do
    local filePath = self.commandInboxDir .. filename
    if not fileExists(filePath) or (getTime() - ts) > maxAgeSeconds then
      self.fileTimestamps[filename] = nil
    end
  end
end


function RemoteCommands:banUser(commandData)
    local uniqueUserId = commandData.uniqueUserId
    if not uniqueUserId then
        -- Send data back to website
        return {
          info = "Ban Error.",
          errorMsg = "Unique User Id Missing."
        }
    end

    local nickname = commandData.userNickname

    local user = g_currentMission.userManager:getUserByUniqueId(uniqueUserId)

    if user then
        nickname = user.nickname
    else
        local assignedFarm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
        if assignedFarm then
            for _, member in ipairs(assignedFarm.players) do
                if member.uniqueUserId == uniqueUserId then
                    nickname = member.lastNickname
                    break
                end
            end
        end
    end

    local targetUser = g_currentMission.userManager:getUserByUniqueId(uniqueUserId)
    if targetUser then
        targetUser:block()
    else
        setIsUserBlocked(uniqueUserId, "", 1, true, nickname)
    end

    -- Prepare and return response
    return {
        info = "User Ban Successful."
    }
end

function RemoteCommands:unBanUser(commandData)
    local uniqueUserId = commandData.uniqueUserId
    if not uniqueUserId then
        -- Send data back to website
        return {
          info = "UnBan Error.",
          errorMsg = "Unique User Id Missing."
        }
    end

    local isBanned = getIsUserBlocked(uniqueUserId, "", 1)
    if not isBanned then
        -- Send data back to website
        return {
          info = "UnBan Error.",
          errorMsg = "User not on the ban list to remove them from."
        }
    end

    setIsUserBlocked(uniqueUserId, "", 1, false, "")

    -- Prepare and return response
    return {
        info = "User UnBan Successful."
    }
end