--print("ChatEventSaver")

ChatEventSaver = {}
local ChatEventSaver_mt = Class(ChatEventSaver, Event)

InitEventClass(ChatEventSaver, "ChatEventSaver", EventIds.EVENT_CHAT)

function ChatEventSaver.emptyNew()
	local self = Event.new(ChatEventSaver_mt, NetworkNode.CHANNEL_CHAT)

	--print("CES-EMPTY-NEW")

	return self
end

function ChatEventSaver.new(msg, sender, farmId, userId)
	local self = ChatEventSaver.emptyNew()

	--print("CES-NEW")

	assert(msg ~= nil and sender ~= nil, "ChatEventSaver msg and sender not valid")

	self.msg = filterText(msg, false, false)
	self.sender = sender
	self.farmId = farmId
	self.userId = userId

	return self
end

function ChatEventSaver:readStream(streamId, connection)

	--print("CES-READ-STREAM")

	self.msg = streamReadString(streamId)
	self.sender = streamReadString(streamId)
	self.userId = NetworkUtil.readNodeObjectId(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function ChatEventSaver:writeStream(streamId, connection)

	--print("CES-WRITE-STREAM")

	streamWriteString(streamId, self.msg)
	streamWriteString(streamId, self.sender)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function ChatEventSaver:run(connection)
	g_currentMission:addChatMessage(self.sender, self.msg, self.farmId, self.userId)

	--print("CES-RUN")

	if not connection:getIsServer() then
		local sendToAllPlayers = false

		local fromUser = g_currentMission.userManager:getUserByUserId(self.userId)
		local fromUserId = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)

		--print("Sender: " .. self.sender)
		--print("Message: " .. self.msg)
		--print("Farm ID: " .. self.farmId)
		--print("User ID: " .. fromUserId)

		--add to chat logger
		self:addChatLoggerData(self.sender, self.msg, self.farmId, fromUserId)

		--print("*** FSG Realism Companion Debug *** isMasterUser : ", fromUser.isMasterUser)

		--Setup the command with arguments
		-- print("*** FSG Realism Companion Debug *** Chat Command with Arguments : ")
		local argNum = 0
		local command
		local args = {}
		for iop in string.gmatch(self.msg, "%S+") do
			if argNum == 0 then
				command = iop
			else
				args[argNum] = iop
			end
			argNum = argNum + 1
		end

		-- print(command)
		-- DebugUtil.printTableRecursively(args, "*** FSG Realism Companion Debug *** args : ", 0, 1)

		-- Chat make user sending message admin if they are in Admin.xml command
		if (command == g_i18n:getText("chat_command_me_admin")) then
			MeAdminCommand.meAdmin(connection, fromUser, fromUserId)
		end

		--Chat command that give a user admin access based on their id from #getUsers
		if (command == g_i18n:getText("chat_command_make_admin")) and fromUser.isMasterUser then
			MakeAdminCommand.makeAdmin(connection, fromUser, fromUserId, args, self)
		end	
		
		-- Chat print out current players on server with their id on server that can be used for other commands.
		if (command == g_i18n:getText("chat_command_users")) and fromUser.isMasterUser then
			GetUsersCommand.getUsers()
		end

		-- Chat moo cow thingy because why not
		if (command == g_i18n:getText("chat_command_moo")) then
			local mooOut = "              (      )\n              ~(^^^^)~\n               ) @@ \\~_          \t|\\\n              /     | \\        \t\\~ /\n             ( 0  0  ) \\        \t| |\n              ---___/~  \\       \t| |\n               /\'__/ |   ~-_____/ |\n           _   ~----~      ___---~"
			g_server:broadcastEvent(ChatEvent.new(mooOut,g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
		end

		--Remove user admin
		--Disabled for now.  Logs user out in the backend, but visualy still looks like an admin.  Have to figure out if it is possible to refresh the player menus and walking speed. 
		-- if (self.msg == g_i18n:getText("chat_command_remove_admin")) and fromUser.isMasterUser then
		-- 	RemoveAdminCommand.removeAdmin(fromUser)
		-- end

		--Chat command that sets user to be remembered so they can be auto admin when they join the server
		if (command == g_i18n:getText("chat_command_rememberme")) and fromUser.isMasterUser then
			RememberMeCommand.rememberMe(fromUser, fromUserId)
		end

		--Chat command that sets user to no longer be remembered so they can be auto admin when they join the server
		if (command == g_i18n:getText("chat_command_forgetme")) and fromUser.isMasterUser then
			ForgetMeCommand.forgetMe(fromUser, fromUserId)
		end

		--Chat command that displays farms with id
		-- if (command == g_i18n:getText("chat_command_getfarms")) and fromUser.isMasterUser then
		-- 	GetFarmsCommand.getFarms(fromUser, fromUserId)
		-- end

		--Chat command that admin can use to make a player FM of set farm
		-- if (command == g_i18n:getText("chat_command_makefm")) and fromUser.isMasterUser then
		-- 	MakeFMCommand.makeFM(connection, fromUser, fromUserId, args, self)
		-- end

		--Send hello message if anyone says hi
		--Add ability to send random responses from a list
		if (string.lower(self.msg) == g_i18n:getText("chat_greetingTrigger01")) or (string.lower(self.msg) == g_i18n:getText("chat_greetingTrigger02")) or (string.lower(self.msg) == g_i18n:getText("chat_greetingTrigger03")) or (string.lower(self.msg) == g_i18n:getText("chat_greetingTrigger04")) or (string.lower(self.msg) == g_i18n:getText("chat_greetingTrigger05")) then
			local greeting = self:randomGreeting(self.sender)
			--greeting:setColor(0, 0, 0, 1)
			g_server:broadcastEvent(ChatEvent.new(greeting,g_currentMission.missionDynamicInfo.serverName,FarmManager.SPECTATOR_FARM_ID,0))
			sendToAllPlayers = true
		end

		--Send chat to all users on server to see
		if sendToAllPlayers == true then
			for _, toUser in ipairs(g_currentMission.userManager:getUsers()) do
				if connection ~= toUser:getConnection() and not toUser:getIsBlockedBy(fromUser) and not toUser:getConnection():getIsLocal() then
					toUser:getConnection():sendEvent(self, false)
				end
			end
		end

	end
end

function ChatEventSaver:randomGreeting(name)
	-- Get a number between 1 and 5
	local ranNumber = math.random(5)
	if ranNumber == 1 then
		return string.format(g_i18n:getText("chat_greeting01"),name)
	elseif ranNumber == 2 then
		return string.format(g_i18n:getText("chat_greeting02"),name)
	elseif ranNumber == 3 then
		return string.format(g_i18n:getText("chat_greeting03"),name)
	elseif ranNumber == 5 then
		return string.format(g_i18n:getText("chat_greeting04"),name)
	else 
		return string.format(g_i18n:getText("chat_greeting05"),name)
	end
end

function ChatEventSaver:addChatLoggerData(sender, msg, farmId, fromUserId)
	local commandOutboxDir = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion/commands/outbox"
  local transactionId = g_fsgSettings:getTransactionId()
  local confirmationFile = commandOutboxDir .. "/confirm-playerChat-" .. transactionId .. ".xml"
	local timestamp = getDate("%Y-%m-%d %H:%M:%S")
	local key = "chatLogger"
	local xmlFile
  --save player chat to outbox
  xmlFile = createXMLFile(key, confirmationFile, key)
  setXMLString(xmlFile, key .. ".chat#sender", tostring(sender))
  setXMLInt(xmlFile, key .. ".chat#transactionId", tonumber(transactionId))
  setXMLString(xmlFile, key .. ".chat#msg", HTMLUtil.encodeToHTML(msg))
  setXMLString(xmlFile, key .. ".chat#farmId", tostring(farmId))
  setXMLString(xmlFile, key .. ".chat#fromUserId", tostring(fromUserId))
  setXMLString(xmlFile, key .. ".chat#timestamp", tostring(timestamp))
  saveXMLFile(xmlFile)
  delete(xmlFile)
end

-- Get user data based on user id for the current server session
function ChatEventSaver:getUserDataById(currentUsers, userId) 
	-- print("*** FSG Realism Companion Debug *** getUserDataById Function - userId : " .. userId)
	local userDataOut
	if currentUsers ~= nil then
		-- DebugUtil.printTableRecursively(currentUsers, "*** FSG Realism Companion Debug *** currentUsers : ", 0, 1)
		--Loop through the users and put id with nick in a string for output
		for _, usersOut in ipairs(currentUsers) do 
			-- print("*** FSG Realism Companion Debug *** usersOut.id : " .. usersOut.id)
			if math.floor(usersOut.id) == math.floor(userId) then 
				userDataOut = usersOut
			end
		end
		if userDataOut ~= nil then 
			return userDataOut
		else
			return false
		end
	else
		return false
	end
end