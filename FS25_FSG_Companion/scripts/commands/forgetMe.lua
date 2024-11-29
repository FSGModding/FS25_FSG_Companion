rcDebug("ForgetMeCommand Class")

ForgetMeCommand = {}
local ForgetMeCommand_mt = Class(ForgetMeCommand, Event)

function ForgetMeCommand.forgetMe(fromUser, fromUserId)
  rcDebug("Forget Me Command Start")
  local userNickname = fromUser.nickname
  local uniqueUserId = fromUser.uniqueUserId

  -- Load the RememberAdmins.xml and add user to the list for auto admin
  local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
  local rememberAdminsFile = modSettingsFolderPath .. "/RememberAdmins.xml"

  if ( fileExists(rememberAdminsFile) ) then

    local key = "admins"

    local xmlFile = XMLFile.load(key, rememberAdminsFile)
    local admins = {}
    local adminsIds = {}	
    local newxmlFile

    if xmlFile == nil then
      return false
    end

    -- Get previous farm managers from xml
    xmlFile:iterate(key .. ".admin", function (_, adminKey)
      local a = {
        userNickname = xmlFile:getString(adminKey .. "#userNickname"),
        uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
      }
      table.insert(admins, a)
      adminsIds[uniqueUserId] = a
    end)

    local saveAdmins = {}

    -- Loop through all existing farm mangers and skip the one that needs removed.  
    for _, thisAdmin in ipairs(admins) do
      if uniqueUserId ~= thisAdmin.uniqueUserId then
        saveAdmins[thisAdmin.uniqueUserId] = thisAdmin
      end
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

    g_server:broadcastEvent(ChatEvent.new(userNickname .. g_i18n:getText("chat_forgetme"),g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))

  else
    g_server:broadcastEvent(ChatEvent.new(userNickname .. g_i18n:getText("chat_forgetme_error"),g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
  end

end