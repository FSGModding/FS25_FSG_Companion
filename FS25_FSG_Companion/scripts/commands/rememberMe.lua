rcDebug("RememberMeCommand Class")

RememberMeCommand = {}
local RememberMeCommand_mt = Class(RememberMeCommand, Event)

function RememberMeCommand.rememberMe(fromUser, fromUserId)
  rcDebug("Remember Me Command")
  local userNickname = fromUser.nickname
  local uniqueUserId = fromUser.uniqueUserId

  -- Load the RememberAdmins.xml and add user to the list for auto admin
  local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
  local rememberAdminsFile = modSettingsFolderPath .. "/RememberAdmins.xml"

  local key = "admins"

	if ( fileExists(rememberAdminsFile) ) then

		local xmlFile = XMLFile.load(key, rememberAdminsFile)
		local admins = {}
		local newxmlFile
	
		if xmlFile == nil then
			return false
		end
	
		local newFarmManager = {
			userNickname = tostring(userNickname),
			uniqueUserId = tostring(uniqueUserId),
		}
	
    -- Add the new admin to the list
		table.insert(admins, newFarmManager)
	
    -- Get previous admins from xml
		xmlFile:iterate(key .. ".admin", function (_, adminKey)
			local a = {
				userNickname = xmlFile:getString(adminKey .. "#userNickname"),
				uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
			}
			table.insert(admins, a)
		end)

		local saveAdmins = {}

    -- Make all of the new and previous admins unique so we don't get duplicates
		for _, thisAdmin in ipairs(admins) do
			saveAdmins[thisAdmin.uniqueUserId] = thisAdmin
		end

		--save data to xml file
		newxmlFile = XMLFile.create(key, rememberAdminsFile, key)

		local index = 0

		for uniqueAdmin, saveAdmin in pairs(saveAdmins) do
			if saveAdmin.uniqueUserId ~= nil then
  			local subKey = string.format(".admin(%d)", index)
	  		newxmlFile:setString(key .. subKey .. "#userNickname", tostring(saveAdmin.userNickname))
		  	newxmlFile:setString(key .. subKey .. "#uniqueUserId", tostring(saveAdmin.uniqueUserId))
			  index = index + 1
      end
		end

		newxmlFile:save()
		newxmlFile:delete()

	else 

		rcDebug("No Admins.xml yet.  Creating one.")
		xmlFile = createXMLFile(key, rememberAdminsFile, key)
		setXMLString(xmlFile, key .. ".farmManager#userNickname", tostring(userNickname))
		setXMLString(xmlFile, key .. ".farmManager#uniqueUserId", tostring(uniqueUserId))
		saveXMLFile(xmlFile)
    delete(xmlFile)

	end
  
  --Send message to chat letting folks know user is now remembered as admin
  g_server:broadcastEvent(ChatEvent.new(fromUser.nickname .. g_i18n:getText("chat_rememberme"),g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))

  -- Save the game with new admin added
  -- g_currentMission:saveSavegame()

end