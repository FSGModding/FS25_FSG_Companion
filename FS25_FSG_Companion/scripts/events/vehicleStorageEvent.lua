---@class VehicleStorageEvent
VehicleStorageEvent = {}
local VehicleStorageEvent_mt = Class(VehicleStorageEvent, Event)

InitEventClass(VehicleStorageEvent, "VehicleStorageEvent")

function VehicleStorageEvent.emptyNew()
  rcDebug("LE-emptyNew")
	return Event.new(VehicleStorageEvent_mt)
end

function VehicleStorageEvent.new(vehicle)
  rcDebug("LE-new")
	local self = VehicleStorageEvent.emptyNew()
  self.vehicle = vehicle
	return self
end

function VehicleStorageEvent:readStream(streamId, connection)
  rcDebug("LE-readStream")
  -- Get data from clients
  self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function VehicleStorageEvent:writeStream(streamId, connection)
  rcDebug("LE-writeStream")
  -- Send data out to clients
  NetworkUtil.writeNodeObject(streamId, self.vehicle)  
end

function VehicleStorageEvent:run(connection)
  rcDebug("LE-run")
  VehicleStorage:storeVehicle(self.vehicle)
end

function VehicleStorageEvent.sendEvent(...)
  rcDebug("LE-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(VehicleStorageEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(VehicleStorageEvent.new(...))
	end
end