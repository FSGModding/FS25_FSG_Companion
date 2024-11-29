SuperStrengthEvent = {}
local SuperStrengthEvent_mt = Class(SuperStrengthEvent, Event)

InitEventClass(SuperStrengthEvent, "SuperStrengthEvent")

function SuperStrengthEvent.emptyNew()
  rcDebug(' Info: SuperStrengthEvent:emptyNew')
  return Event.new(SuperStrengthEvent_mt)
end

function SuperStrengthEvent.new(disable)
  rcDebug(' Info: SuperStrengthEvent:new')
  local self = SuperStrengthEvent.emptyNew()
  self.disable = disable
  return self
end

function SuperStrengthEvent:readStream(streamId, connection)
  rcDebug(' Info: SuperStrengthEvent:readStream')
  self.disable = streamReadBool(streamId)
  self:run(connection)
end

function SuperStrengthEvent:writeStream(streamId, connection)
  rcDebug(' Info: SuperStrengthEvent:writeStream')
  streamWriteBool(streamId, self.disable)
end

function SuperStrengthEvent:run(connection)
  rcDebug(' Info: SuperStrengthEvent:run') 
  if not connection:getIsServer() then
    g_server:broadcastEvent(SuperStrengthEvent.new(self.disable))
  end
  if g_farmCleanUp ~= nil then
    g_farmCleanUp:disableSuperStrength(self.disable)
  end
end

function SuperStrengthEvent.sendEvent(...)
  rcDebug(' Info: SuperStrengthEvent:sendEvent')
	if g_server ~= nil then
		g_server:broadcastEvent(SuperStrengthEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(SuperStrengthEvent.new(...))
	end
end