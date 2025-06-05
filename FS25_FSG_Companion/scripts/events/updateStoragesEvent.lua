UpdateStoragesEvent = {}
local UpdateStoragesEvent_mt = Class(UpdateStoragesEvent, Event)

InitEventClass(UpdateStoragesEvent, "UpdateStoragesEvent")

function UpdateStoragesEvent.emptyNew()
  rcDebug(' Info: UpdateStoragesEvent:emptyNew')
  return Event.new(UpdateStoragesEvent_mt)
end

function UpdateStoragesEvent.new(update)
  rcDebug(' Info: UpdateStoragesEvent:new')
  local self = UpdateStoragesEvent.emptyNew()
  self.update = update
  return self
end

function UpdateStoragesEvent:readStream(streamId, connection)
  rcDebug(' Info: UpdateStoragesEvent:readStream')
  self.update = streamReadBool(streamId)
  self:run(connection)
end

function UpdateStoragesEvent:writeStream(streamId, connection)
  rcDebug(' Info: UpdateStoragesEvent:writeStream')
  streamWriteBool(streamId, self.update)
end

function UpdateStoragesEvent:run(connection)
  rcDebug(' Info: UpdateStoragesEvent:run') 
  if g_fillManager ~= nil then
    g_fillManager:updateStorages()
  end
end

function UpdateStoragesEvent.sendEvent(...)
  rcDebug(' Info: UpdateStoragesEvent:sendEvent')
	if g_server ~= nil then
		g_server:broadcastEvent(UpdateStoragesEvent.new(...))
	end
end