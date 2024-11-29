---@class GetTerrainHeightAtWorldPosEvent
GetTerrainHeightAtWorldPosEvent = {}
local GetTerrainHeightAtWorldPosEvent_mt = Class(GetTerrainHeightAtWorldPosEvent, Event)

InitEventClass(GetTerrainHeightAtWorldPosEvent, "GetTerrainHeightAtWorldPosEvent")

function GetTerrainHeightAtWorldPosEvent.emptyNew()
  rcDebug("TTH-emptyNew")
	return Event.new(GetTerrainHeightAtWorldPosEvent_mt)
end

function GetTerrainHeightAtWorldPosEvent.new(userId, farmId, uniqueUserId, userNickname, action)
  rcDebug("TTH-new")
	local self = GetTerrainHeightAtWorldPosEvent.emptyNew()
  self.userId       = userId
	self.farmId       = farmId
  self.uniqueUserId = uniqueUserId
  self.userNickname = userNickname
  self.action       = action
	return self
end

function GetTerrainHeightAtWorldPosEvent:readStream(streamId, connection)
  rcDebug("TTH-readStream")
  -- Get data from clients
  self.userId       = NetworkUtil.readNodeObjectId(streamId)
	self.farmId       = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  self.uniqueUserId = streamReadString(streamId)
  self.userNickname = streamReadString(streamId)
  self.action       = streamReadString(streamId)
	self:run(connection)
end

function GetTerrainHeightAtWorldPosEvent:writeStream(streamId, connection)
  rcDebug("TTH-writeStream")

  -- Send data out to clients
  NetworkUtil.writeNodeObjectId(streamId, self.userId)
  streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteString(streamId, self.uniqueUserId)
  streamWriteString(streamId, self.userNickname)
  streamWriteString(streamId, self.action)
end

function GetTerrainHeightAtWorldPosEvent:run(connection)
  rcDebug("TTH-run")
  g_farmManagerRC:updateFarmManager(self.userId, self.farmId, self.uniqueUserId, self.userNickname, self.action)
end

function GetTerrainHeightAtWorldPosEvent.sendEvent(...)
  rcDebug("TTH-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(GetTerrainHeightAtWorldPosEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(GetTerrainHeightAtWorldPosEvent.new(...))
	end
end