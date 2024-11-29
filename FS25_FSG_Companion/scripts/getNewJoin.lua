rcDebug("getNewJoin Class")

GetNewJoin = {}
local GetNewJoin_mt = Class(GetNewJoin, Event)

InitEventClass(GetNewJoin, "GetNewJoin", EventIds.EVENT_FINISHED_LOADING)

function GetNewJoin.new(mission, i18n, modDirectory, modName)
  rcDebug("GNJ-New")
  local self = setmetatable({}, GetNewJoin_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
	return self
end

function GetNewJoin.newUserJoin(user)

  rcDebug("===New=Player=Join===")

  local userData = g_currentMission.userManager:getUserByConnection(user)

  --ChatEventSaver.addChatLoggerData(g_currentMission.missionDynamicInfo.serverName, userData.nickname .. " joined the game.", "<:fsg_wave:796240141000638474>", "0")

  if not userData.isMasterUser then 

    rcDebug("Player not Admin, lets check if they should be and make them one.")

    local userNickname = userData.nickname
    local uniqueUserId = userData.uniqueUserId

    -- Load the RememberAdmins.xml and add user to the list for auto admin
    local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
    local rememberAdminsFile = modSettingsFolderPath .. "/RememberAdmins.xml"

    -- Check if RememberAdmins.xml file exists
    if ( fileExists(rememberAdminsFile) ) then

      local key = "admins"

      local xmlFile = XMLFile.load(key, rememberAdminsFile)
      local admins = {}

      if xmlFile == nil then
        return false
      end

      -- Get remembered admins from xml
      xmlFile:iterate(key .. ".admin", function (_, adminKey)
        local a = {
          userNickname = xmlFile:getString(adminKey .. "#userNickname"),
          uniqueUserId = xmlFile:getString(adminKey .. "#uniqueUserId"),
        }
        table.insert(admins, a)
      end)

      rcDebug(admins)

      -- Loop through admins on remember list, and make them admin if match.  
      for _, thisAdmin in ipairs(admins) do
        rcDebug(uniqueUserId)
        rcDebug(thisAdmin.uniqueUserId)
        if uniqueUserId == thisAdmin.uniqueUserId then
          -- Match found.  Make user admin
          g_currentMission.userManager:addMasterUser(userData)
          rcDebug(userNickname .. g_i18n:getText("chat_now_admin"))
          g_server:broadcastEvent(ChatEvent.new(userNickname .. g_i18n:getText("chat_now_admin"),g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
        end
      end

    end

  end

end