FarmManagerJoinEvent = {}
local FarmManagerJoinEvent_mt = Class(FarmManagerJoinEvent, Event)

InitEventClass(FarmManagerJoinEvent, "FarmManagerJoinEvent")

function FarmManagerJoinEvent.emptyNew()
  rcDebug("FME-emptyNew")
	return Event.new(FarmManagerJoinEvent_mt)
end
---@class FarmManagerJoinEvent
function FarmManagerJoinEvent.new(selectedFarmId,uniqueUserId,userId)
  rcDebug("FME-new")
	local self = FarmManagerJoinEvent.emptyNew()
	self.selectedFarmId = selectedFarmId
  self.uniqueUserId   = uniqueUserId
  self.userId         = userId
	return self
end

function FarmManagerJoinEvent:readStream(streamId, connection)
  rcDebug("FME-readStream")
  -- Get data from clients
	self.selectedFarmId  = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  self.uniqueUserId    = streamReadString(streamId)
  self.userId          = NetworkUtil.readNodeObjectId(streamId)
	self:run(connection)
end

function FarmManagerJoinEvent:writeStream(streamId, connection)
  rcDebug("FME-writeStream")
  -- Send data out to clients
  streamWriteUIntN(streamId, self.selectedFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteString(streamId, self.uniqueUserId)
  NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function FarmManagerJoinEvent:run(connection)
  rcDebug("FME-run")
  local player = {
    userId = self.userId,
  }
  g_farmManagerRC:updateFarmUserPermission(self.selectedFarmId, player)
end

function FarmManagerJoinEvent.sendEvent(...)
  rcDebug("FME-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(FarmManagerJoinEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(FarmManagerJoinEvent.new(...))
	end
end