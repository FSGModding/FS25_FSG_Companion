VehicleEditEvent = {}
local VehicleEditEvent_mt = Class(VehicleEditEvent, Event)

InitEventClass(VehicleEditEvent, "VehicleEditEvent")

function VehicleEditEvent.emptyNew()
  --rcDebug(' Info: VehicleEditEvent:emptyNew')
  return Event.new(VehicleEditEvent_mt)
end

function VehicleEditEvent.new(vehicle, ownerFarmId)
  --rcDebug(' Info: VehicleEditEvent:new')
  local self = VehicleEditEvent.emptyNew()

  --printf(' Info: ==VehicleEditEvent:new:vehicle: %s', vehicle)
  --printf(' Info: ==VehicleEditEvent:new:ownerFarmId: %s', ownerFarmId)

  self.vehicle = vehicle
  self.ownerFarmId = tonumber(ownerFarmId)

  return self
end

function VehicleEditEvent:readStream(streamId, connection)
  --rcDebug(' Info: VehicleEditEvent:readStream')
  self.vehicle = NetworkUtil.readNodeObject(streamId)
  self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

  self:run(connection)
end

function VehicleEditEvent:writeStream(streamId, connection)
  --rcDebug(' Info: VehicleEditEvent:writeStream')
  NetworkUtil.writeNodeObject(streamId, self.vehicle)
  --rcDebug(' Info: VehicleEditEvent:writeStream:A')
  streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  --rcDebug(' Info: VehicleEditEvent:writeStream:B')
end

function VehicleEditEvent:run(connection)
  --rcDebug(' Info: VehicleEditEvent:run') 
  if not connection:getIsServer() then
    --rcDebug(' Info: VehicleEditEvent:run:notServer')
    g_server:broadcastEvent(VehicleEditEvent.new(self.vehicle, self.ownerFarmId))
  end
  if g_vehicleEdit ~= nil then
    --rcDebug(' Info: VehicleEditEvent:run:isServer')
    g_vehicleEdit:setVehicleOwnerFarmId(self.vehicle, self.ownerFarmId)
    --rcDebug(' Info: Vehicle Operating Time Updated')
  end
end

function VehicleEditEvent.sendEvent(...)
  --rcDebug(' Info: VehicleEditEvent:sendEvent')
	if g_server ~= nil then
		g_server:broadcastEvent(VehicleEditEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(VehicleEditEvent.new(...))
	end
end