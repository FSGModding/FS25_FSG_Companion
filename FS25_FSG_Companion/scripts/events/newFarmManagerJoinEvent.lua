NewFarmManagerJoinEvent = {}
local NewFarmManagerJoinEvent_mt = Class(NewFarmManagerJoinEvent, Event)

InitEventClass(NewFarmManagerJoinEvent, "NewFarmManagerJoinEvent")

function NewFarmManagerJoinEvent.emptyNew()
  rcDebug("NFME-emptyNew")
	return Event.new(NewFarmManagerJoinEvent_mt)
end
---@class NewFarmManagerJoinEvent
function NewFarmManagerJoinEvent.new(player, farmId, password)
  rcDebug("NFME-new")
	local self = NewFarmManagerJoinEvent.emptyNew()
  self.farmId = farmId
  self.password = password
  self.player = player
	return self
end

function NewFarmManagerJoinEvent:readStream(streamId, connection)
  rcDebug("NFME-readStream")
  -- Get data from clients
  self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  self.password = streamReadString(streamId)
  self.player = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function NewFarmManagerJoinEvent:writeStream(streamId, connection)
  rcDebug("NFME-writeStream")
  -- Send data out to clients
  streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteString(streamId, self.password)
  NetworkUtil.writeNodeObject(streamId, self.player)
end

function NewFarmManagerJoinEvent:run(connection)
  rcDebug("NFME-run")
  g_farmManagerRC:updateFarmUserPermission(self.farmId, self.player)
  g_farmManagerRC:checkFirstFarmer(self.player,self.farmId,self.password)
end

function NewFarmManagerJoinEvent.sendEvent(...)
  rcDebug("NFME-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(NewFarmManagerJoinEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(NewFarmManagerJoinEvent.new(...))
	end
end