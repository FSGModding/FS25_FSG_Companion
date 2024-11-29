---@class FarmManagerEvent
FarmManagerEvent = {}
local FarmManagerEvent_mt = Class(FarmManagerEvent, Event)

InitEventClass(FarmManagerEvent, "FarmManagerEvent")

function FarmManagerEvent.emptyNew()
  rcDebug("FME-emptyNew")
	return Event.new(FarmManagerEvent_mt)
end

function FarmManagerEvent.new(userId, farmId, uniqueUserId, userNickname, action)
  rcDebug("FME-new")
	local self = FarmManagerEvent.emptyNew()
  self.userId       = userId
	self.farmId       = farmId
  self.uniqueUserId = uniqueUserId
  self.userNickname = userNickname
  self.action       = action
	return self
end

function FarmManagerEvent:readStream(streamId, connection)
  rcDebug("FME-readStream")
  -- Get data from clients
  self.userId       = NetworkUtil.readNodeObjectId(streamId)
	self.farmId       = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  self.uniqueUserId = streamReadString(streamId)
  self.userNickname = streamReadString(streamId)
  self.action       = streamReadString(streamId)
	self:run(connection)
end

function FarmManagerEvent:writeStream(streamId, connection)
  rcDebug("FME-writeStream")

  -- Send data out to clients
  NetworkUtil.writeNodeObjectId(streamId, self.userId)
  streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteString(streamId, self.uniqueUserId)
  streamWriteString(streamId, self.userNickname)
  streamWriteString(streamId, self.action)
end

function FarmManagerEvent:run(connection)
  rcDebug("FME-run")
  g_farmManagerRC:updateFarmManager(self.userId, self.farmId, self.uniqueUserId, self.userNickname, self.action)
end

function FarmManagerEvent.sendEvent(...)
  rcDebug("FME-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(FarmManagerEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(FarmManagerEvent.new(...))
	end
end