rcDebug("FarmManagerRC Class")

FarmManagerRC = {}
local FarmManagerRC_mt = Class(FarmManagerRC, Event)

InitEventClass(FarmManagerRC, "FarmManagerRC", EventIds.EVENT_PLAYER_PERMISSIONS)

function FarmManagerRC.new(mission, i18n, modDirectory, modName)
  rcDebug("FM-new")
  local self = setmetatable({}, FarmManagerRC_mt)
  
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName

	return self
end

function FarmManagerRC:addFarmManager(userId)
  rcDebug("FM-addFarmManager")

	local user = g_currentMission.userManager:getUserByUserId(userId)

  if user ~= nil then 

    local farm = g_farmManager:getFarmByUserId(userId)

    if farm ~= nil then 

      local farmId = farm.farmId
      local action = tostring('addFM')

      rcDebug("Player now Farm Manager.")

      if not self.isServer then
        rcDebug("FarmManagerEvent:sendEvent - data being sent from client to server")
        FarmManagerEvent.sendEvent(userId, farmId, user.uniqueUserId, user.nickname, action)
      end

    end
  end
end

function FarmManagerRC:removeFarmManager(userId)
  rcDebug("FM-removeFarmManager")

	local user = g_currentMission.userManager:getUserByUserId(userId)

  if user ~= nil then 

    local farm = g_farmManager:getFarmByUserId(userId)

    if farm ~= nil then 

      local farmId = farm.farmId
      local action = tostring('removeFM')

      rcDebug("Player no longer Farm Manager.")

      if not self.isServer then
        rcDebug("FarmManagerEvent:sendEvent - data being sent from client to server")
        FarmManagerEvent.sendEvent(userId, farmId, user.uniqueUserId, user.nickname, action)
      end

    end
  end
end

-- Update farmManagers.xml on the server side
function FarmManagerRC:updateFarmManager(userId, farmId, uniqueUserId, userNickname, action)
  rcDebug("FM-updateFarmManager")
  
  -- Do stuff with farm and user info
  if action == "addFM" then
    self:addFarmManagerLog(userNickname, uniqueUserId, farmId)
  elseif action == "removeFM" then
    self:removeFarmManagerLog(userNickname, uniqueUserId, farmId)
  end
end

-- Runs when user joins farm
function FarmManagerRC.userJoinFarm(farmUser)

  rcDebug("FM-userJoinFarm")

  -- Check with server to see if user should be FM, and make them one if so.
  FarmManagerJoinEvent.sendEvent(farmUser.selectedFarmId,farmUser.currentUser.uniqueUserId,farmUser.currentUser.id)

end

-- Check to see if user is first to join farm, if so then make them FM if password is correct
function FarmManagerRC:onFarmPasswordEntered(password, hasConfirmed, farmId)
  rcDebug("FM-playerJoinFarm")
  
  if hasConfirmed and password ~= nil and password ~= "" then
    -- Send new farm manager event when they join a farm
    NewFarmManagerJoinEvent.sendEvent(self.player, farmId, password)
  end

end

-- Check if player is first to join the farm and give them FM if so
function FarmManagerRC:checkFirstFarmer(player,farmId,password)
  rcDebug("FM-checkFirstFarmer")

  -- Check to see if farm is new and no assigned FMs, and assign first person as FM.
  local farm = g_farmManager:getFarmById(farmId);
  -- make sure farm and player data is good
  if farm ~= nil and player ~= nil then
    -- Check to make sure password is correct
    if password ~= nil and password ~= "" and password == farm.password then
      -- Get player uniqueUserId to see if they should be made FM
      local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(player.userId)
      -- Check if any players are already assigned to farm log
      local checkFarm = self:checkFarmManagerLogByFarmId(farmId)
      if not checkFarm then
        -- Check if farm has not players logged in, if none then give first user FM
        if farm.players[1] ~= nil and farm.players[2] == nil and farm.players[1].uniqueUserId == uniqueUserId then
          -- Add the FM to the remember thingy for future logins
          rcDebug("Player is first to join farm with correct password.  Make them FM.")
          local user = g_currentMission.userManager:getUserByUserId(player.userId)
          local userNickname = user:getNickname()
          self:addFarmManagerLog(userNickname, uniqueUserId, farmId)
          farm:promoteUser(player.userId)
          -- trigger a save to ensure that if player leaves farm and another player joins it does not give the second user FM
          g_currentMission:saveSavegame()
        end
      end
    end
  end

end

-- checks if user should be farm manager when they join farm
function FarmManagerRC:updateFarmUserPermission(selectedFarmId,player)

  rcDebug("FM-updateFarmUserPermission")

  local userId = player.userId

  local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByUserId(player.userId)

  local isSelectedUserFarmManager = self.selectedUserId ~= nil and self.selectedUserFarm:isUserFarmManager(self.selectedUserId)

  if not isSelectedUserFarmManager then

    rcDebug("Player not Farm Manager, lets check if they should be and make them one.")

    if uniqueUserId ~= nil then
      local playerFarm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
      if selectedFarmId ~= nil and playerFarm ~= nil then
        local checkFarmManagerLog = self:checkFarmManagerLog(selectedFarmId,uniqueUserId)
        if checkFarmManagerLog then
          playerFarm:promoteUser(userId)
        end
      end
    end
  end
end

-- checks to see if any users are in the farm manager list by farm id
function FarmManagerRC:checkFarmManagerLogByFarmId(farmId)
  rcDebug("FM-checkFarmManagerLog")
  -- Load the farm managers xml and check if current user should be fm of farm.
  local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
  local modSettingsFile = modSettingsFolderPath .. "/FarmManagers.xml"

  local key = "farmManagers"

  if ( fileExists(modSettingsFile) ) then

    local xmlFile = XMLFile.load(key, modSettingsFile)
    local farmManagers = {}

    if xmlFile == nil then
      return false
    end

    -- Get previous farm managers from xml
    xmlFile:iterate(key .. ".farmManager", function (_, adminKey)
      local fm = {
        userNickname = xmlFile:getString(adminKey .. "#userNickname"),
        uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
        farmId       = xmlFile:getString(adminKey .. "#farmId"),
      }
      table.insert(farmManagers, fm)
    end)

    local uniqueUserFarm = nil

    -- Loop through all existing farm mangers and skip the one that needs removed.  
    for _, thisFM in ipairs(farmManagers) do
      uniqueUserFarm = thisFM.farmId
      if farmId == uniqueUserFarm then
        -- Match found.  Return true
        return true
      end
    end
  end
  return false
end

-- checks to see if user is in the farm manager list
function FarmManagerRC:checkFarmManagerLog(farmId,uniqueUserId)
  rcDebug("FM-checkFarmManagerLog")
  if farmId ~= nil and uniqueUserId ~= nil then
    -- Load the farm managers xml and check if current user should be fm of farm.
    local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
    local modSettingsFile = modSettingsFolderPath .. "/FarmManagers.xml"

    local key = "farmManagers"

    if ( fileExists(modSettingsFile) ) then

      local xmlFile = XMLFile.load(key, modSettingsFile)
      local farmManagers = {}

      if xmlFile == nil then
        return false
      end

      -- Get previous farm managers from xml
      xmlFile:iterate(key .. ".farmManager", function (_, adminKey)
        local fm = {
          userNickname = xmlFile:getString(adminKey .. "#userNickname"),
          uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
          farmId       = xmlFile:getString(adminKey .. "#farmId"),
        }
        table.insert(farmManagers, fm)
      end)

      local uniqueUserFarm = nil

      -- Loop through all existing farm mangers and skip the one that needs removed.  
      for _, thisFM in ipairs(farmManagers) do
        uniqueUserFarm = thisFM.uniqueUserId .. "-" .. thisFM.farmId
        if uniqueUserId .. "-" .. farmId == uniqueUserFarm then
          -- Match found.  Return true
          return true
        end
      end
    end
    return false
  end
end

-- adds farm manager to remember file
function FarmManagerRC:addFarmManagerLog(userNickname, uniqueUserId, farmId)
  rcDebug("FM-addFarmManagerLog")
	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
	local modSettingsFile = modSettingsFolderPath .. "/FarmManagers.xml"

	local key = "farmManagers"

	if ( fileExists(modSettingsFile) ) then

		local xmlFile = XMLFile.load(key, modSettingsFile)
		local farmManagers = {}
		local newxmlFile
	
		if xmlFile == nil then
			return false
		end
	
		local newFarmManager = {
			userNickname = tostring(userNickname),
			uniqueUserId = tostring(uniqueUserId),
      farmId       = tostring(farmId),
		}
	
    -- Add the new farm manager to the list
		table.insert(farmManagers, newFarmManager)
	
    -- Get previous farm managers from xml
		xmlFile:iterate(key .. ".farmManager", function (_, adminKey)
			local fm = {
				userNickname = xmlFile:getString(adminKey .. "#userNickname"),
				uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
        farmId       = xmlFile:getString(adminKey .. "#farmId"),
			}
			table.insert(farmManagers, fm)
		end)

		local saveFarmManagers = {}
    local uniqueUserFarm = nil

    -- Make all of the new and previous farm managers unique so we don't get duplicates
		for _, thisFM in ipairs(farmManagers) do
      uniqueUserFarm = thisFM.uniqueUserId .. "-" .. thisFM.farmId
			saveFarmManagers[uniqueUserFarm] = thisFM
		end

		--save data to xml file
		newxmlFile = XMLFile.create(key, modSettingsFile, key)

		local index = 0

		for uniqueFM, saveFM in pairs(saveFarmManagers) do
			if saveFM.uniqueUserId ~= nil then
  			local subKey = string.format(".farmManager(%d)", index)
	  		newxmlFile:setString(key .. subKey .. "#userNickname", tostring(saveFM.userNickname))
		  	newxmlFile:setString(key .. subKey .. "#uniqueUserId", tostring(saveFM.uniqueUserId))
        newxmlFile:setString(key .. subKey .. "#farmId", tostring(saveFM.farmId))
			  index = index + 1
      end
		end

		newxmlFile:save()
		newxmlFile:delete()

	else 

		rcDebug("No FarmManagers.xml yet.  Creating one.")

		xmlFile = createXMLFile(key, modSettingsFile, key)

		setXMLString(xmlFile, key .. ".farmManager#userNickname", tostring(userNickname))
		setXMLString(xmlFile, key .. ".farmManager#uniqueUserId", tostring(uniqueUserId))
    setXMLString(xmlFile, key .. ".farmManager#farmId", tostring(farmId))

		saveXMLFile(xmlFile)
    delete(xmlFile)

	end

end

-- Removes farm manager from remember file
function FarmManagerRC:removeFarmManagerLog(userNickname, uniqueUserId, farmId)
  rcDebug("FM-removeFarmManagerLog")
	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
	local modSettingsFile = modSettingsFolderPath .. "/FarmManagers.xml"

	local key = "farmManagers"

  local xmlFile = XMLFile.load(key, modSettingsFile)
  local farmManagers = {}	
  local newxmlFile

  if xmlFile == nil then
    return false
  end

  -- Get previous farm managers from xml
  xmlFile:iterate(key .. ".farmManager", function (_, adminKey)
    local fm = {
      userNickname = xmlFile:getString(adminKey .. "#userNickname"),
      uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
      farmId       = xmlFile:getString(adminKey .. "#farmId"),
    }
    table.insert(farmManagers, fm)
  end)

  local saveFarmManagers = {}
  local uniqueUserFarm = nil

  -- Loop through all existing farm mangers and skip the one that needs removed.  
  for _, thisFM in ipairs(farmManagers) do
    uniqueUserFarm = thisFM.uniqueUserId .. "-" .. thisFM.farmId
    if uniqueUserId .. "-" .. farmId ~= uniqueUserFarm then
      saveFarmManagers[uniqueUserFarm] = thisFM
    end
  end

  --save data to xml file
  newxmlFile = XMLFile.create(key, modSettingsFile, key)

  local index = 0

  for uniqueFM, saveFM in pairs(saveFarmManagers) do
    if saveFM.uniqueUserId ~= nil then
      local subKey = string.format(".farmManager(%d)", index)
      newxmlFile:setString(key .. subKey .. "#userNickname", tostring(saveFM.userNickname))
      newxmlFile:setString(key .. subKey .. "#uniqueUserId", tostring(saveFM.uniqueUserId))
      newxmlFile:setString(key .. subKey .. "#farmId", tostring(saveFM.farmId))
      index = index + 1
    end
  end

  newxmlFile:save()
  newxmlFile:delete()

end

-- Remove all remembered users by farm id
function FarmManagerRC:removeFarm(farmId) 
  rcDebug("FM-removeFarm")
  rcDebug(farmId)
  -- Remove remembered farm users from farm
	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
	local modSettingsFile = modSettingsFolderPath .. "/FarmManagers.xml"

	local key = "farmManagers"

  local xmlFile = XMLFile.load(key, modSettingsFile)
  local farmManagers = {}	
  local newxmlFile

  if xmlFile == nil then
    return false
  end

  -- Get previous farm managers from xml
  xmlFile:iterate(key .. ".farmManager", function (_, adminKey)
    local fm = {
      userNickname = xmlFile:getString(adminKey .. "#userNickname"),
      uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
      farmId       = xmlFile:getString(adminKey .. "#farmId"),
    }
    table.insert(farmManagers, fm)
  end)

  local saveFarmManagers = {}
  local uniqueUserFarm = nil

  -- Loop through all existing farm mangers and skip the one that needs removed.  
  for _, thisFM in ipairs(farmManagers) do
    uniqueUserFarm = thisFM.uniqueUserId .. "-" .. thisFM.farmId
    if thisFM.farmId ~= farmId then
      saveFarmManagers[uniqueUserFarm] = thisFM
    end
  end

  --save data to xml file
  newxmlFile = XMLFile.create(key, modSettingsFile, key)

  local index = 0

  for uniqueFM, saveFM in pairs(saveFarmManagers) do
    if saveFM.uniqueUserId ~= nil then
      local subKey = string.format(".farmManager(%d)", index)
      newxmlFile:setString(key .. subKey .. "#userNickname", tostring(saveFM.userNickname))
      newxmlFile:setString(key .. subKey .. "#uniqueUserId", tostring(saveFM.uniqueUserId))
      newxmlFile:setString(key .. subKey .. "#farmId", tostring(saveFM.farmId))
      index = index + 1
    end
  end

  newxmlFile:save()
  newxmlFile:delete() 

end


function FarmManagerRC:createFarm(name, color, password, farmId)
	rcDebug("FarmManagerRC - createFarm")
  if not g_currentMission:getIsServer() then
		print("Error: FarmManager:createFarm() only allowed on server")

		return nil
	end

	if not g_currentMission.missionDynamicInfo.isMultiplayer and table.getn(g_farmManager.farms) > 2 then
		return nil
	end

	local farm = Farm.new(true, g_client ~= nil)

	if table.getn(g_farmManager.farms) == FarmManager.MAX_FARM_ID + 1 then
		return nil, "Farm limit reached"
	end

	farm.farmId = farmId
	farm.name = name
	farm.color = color

	if password ~= "" then
		farm.password = password
	end

  rcDebug("create farm farm")
  rcDebug(farm)

	farm:register()
	table.insert(g_farmManager.farms, farm)

	g_farmManager.farmIdToFarm[farm.farmId] = farm

	g_messageCenter:publish(MessageType.FARM_CREATED, farm.farmId)

	return farm
end