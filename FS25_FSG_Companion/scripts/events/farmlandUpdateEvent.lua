---@class FarmlandUpdateEvent
FarmlandUpdateEvent = {}
local FarmlandUpdateEvent_mt = Class(FarmlandUpdateEvent, Event)

InitEventClass(FarmlandUpdateEvent, "FarmlandUpdateEvent")

function FarmlandUpdateEvent.emptyNew()
  rcDebug("FUE-emptyNew")
	return Event.new(FarmlandUpdateEvent_mt)
end

function FarmlandUpdateEvent.new(farmlandId, farmId)
  rcDebug("FUE-new")
	local self = FarmlandUpdateEvent.emptyNew()
  self.farmlandId       = farmlandId
	self.farmId           = farmId
	return self
end

function FarmlandUpdateEvent:readStream(streamId, connection)
  rcDebug("FUE-readStream")
  -- Get data from clients
  self.farmlandId       = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self.farmId           = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function FarmlandUpdateEvent:writeStream(streamId, connection)
  rcDebug("FUE-writeStream")

  -- Send data out to clients
  streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
  streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function FarmlandUpdateEvent:run(connection)
  rcDebug("FUE-run")
  g_farmlandManager:setLandOwnership(self.farmlandId, self.farmId)
  -- g_fieldManager:updateFieldOwnership() -- Looks like this is no longer a thing
end

function FarmlandUpdateEvent.sendEvent(...)
  rcDebug("FUE-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(FarmlandUpdateEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(FarmlandUpdateEvent.new(...))
	end
end