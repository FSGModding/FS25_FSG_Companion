ChatLogger = {}

local ChatLogger_mt = Class(ChatLogger)

function ChatLogger:new(mission, i18n, modDirectory, modName)
  local self = setmetatable({}, ChatLogger_mt)

	self.lastScrollTime   = 0
	self.returnScreenName = ""
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName

	return self
end

function ChatLogger:onClose(superFunc)
	ChatLogger:superClass().onClose(self)

	if g_currentMission ~= nil then
		g_currentMission:scrollChatMessages(-9999999)
		g_currentMission:toggleChat(false)

		g_currentMission.isPlayerFrozen = false
	end

	self.textElement:abortIme()
	self.textElement:setForcePressed(false)
end

function ChatLogger:onSendClick(superFunc)

  -- Nothing returned, no need to call the superFunc

	if self.textElement.text ~= "" then
		local nickname = g_currentMission.playerNickname
		local farmId = g_currentMission:getFarmId()
		local isAllowed = true

		if GS_PLATFORM_TYPE == GS_PLATFORM_TYPE_GGP then
			isAllowed = getAllowTextCommunication()
		end

		if isAllowed then
			if g_server ~= nil and g_dedicatedServer ~= nil then
				g_server:broadcastEvent(ChatEvent.new(self.textElement.text, nickname, farmId, g_currentMission.playerUserId))
				g_server:broadcastEvent(ChatEventSaver.new(self.textElement.text, nickname, farmId, g_currentMission.playerUserId))
                --rcDebug("g_server local", false)
            else
				g_client:getServerConnection():sendEvent(ChatEvent.new(self.textElement.text, nickname, farmId, g_currentMission.playerUserId))
				g_client:getServerConnection():sendEvent(ChatEventSaver.new(self.textElement.text, nickname, farmId, g_currentMission.playerUserId))
                --rcDebug("g_server client", false)
			end

			g_currentMission:addChatMessage(nickname, self.textElement.text, farmId, g_currentMission.playerUserId)
		end

		self.textElement:setText("")

	end

	g_gui:showGui("")
end

function ChatLogger:loadMapDataHelpLineManager(superFunc, ...)
    local ret = superFunc(self, ...)
    if ret then
        self:loadFromXML(Utils.getFilename("help/HelpMenu.xml", g_chatLogger.modDirectory))
        return true
    end
    return false
end