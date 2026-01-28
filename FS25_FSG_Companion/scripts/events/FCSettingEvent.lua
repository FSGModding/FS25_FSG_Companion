-- Note to self, need to update the UIntN to enable addition of bit size form external

FCSettingEvent = {}
local FCSettingEvent_mt = Class(FCSettingEvent, Event)

InitEventClass(FCSettingEvent, "FCSettingEvent")

function FCSettingEvent.emptyNew()
	return Event.new(FCSettingEvent_mt)
end
---@class FCSettingEvent
function FCSettingEvent.new(valueType, valueName, valueData)
	local self = FCSettingEvent.emptyNew()
  self.valueType = valueType
	self.valueName = valueName
  self.valueData = valueData
	return self
end

function FCSettingEvent:readStream(streamId, connection)
  rcDebug("FCSettingEvent:readStream")
  self.valueType = streamReadUInt8(streamId)
  self.valueName = streamReadString(streamId)
  -- Check if valuetype is nil
  if self.valueType == nil then 
    print('FCSettingEvent:readStream:Error:valueType=nil - valueType can not be nil.  Must be int.')
    return
  end
  -- Check if valueName is nil
  if self.valueName == nil then 
    print('FCSettingEvent:readStream:Error:valueName=nil - valueName can not be nil.  Must be string.')
    return
  end
  -- String
  if     self.valueType == 1 then self.valueData = streamReadString(streamId) 
  -- Bool - True or False | 1 or 0
  elseif self.valueType == 2 then self.valueData = streamReadBool(streamId) 
  -- Int8 - Number from 0 to 255
  elseif self.valueType == 3 then self.valueData = streamReadInt8(streamId) 
  -- Int32 - Number from 0 to 4294967295
  elseif self.valueType == 4 then self.valueData = streamReadInt32(streamId) 
  -- UInt8 - Number from 0 to 255 - No negitive
  elseif self.valueType == 5 then self.valueData = streamReadUInt8(streamId) 
  -- UInt16 - Number from 0 to 4294967295 - No negitive
  elseif self.valueType == 6 then self.valueData = streamReadUInt16(streamId) 
  -- UIntN - 1 to 32 bits to be set by function
  elseif self.valueType == 7 then self.valueData = streamReadUIntN(streamId) 
  -- Float32 - 32 bit float number
  elseif self.valueType == 8 then self.valueData = streamReadFloat32(streamId)
  -- Unknown
  else printf('FCSettingEvent:readStream:Error:valueType: %s not correct type.') end
  -- Debug
	self:run(connection)
end

function FCSettingEvent:writeStream(streamId, connection)
  rcDebug("FCSettingEvent:writeStream")
  streamWriteUInt8(streamId, self.valueType)
  streamWriteString(streamId, self.valueName)
  -- Check if valuetype is nil
  if self.valueType == nil then 
    return
  end
  -- Check if valueName is nil
  if self.valueName == nil then 
    return
  end
  -- String
  if     self.valueType == 1 then streamWriteString(streamId, self.valueData) 
  -- Bool
  elseif self.valueType == 2 then streamWriteBool(streamId, self.valueData) 
  -- Int8
  elseif self.valueType == 3 then streamWriteInt8(streamId, self.valueData) 
  -- Int32
  elseif self.valueType == 4 then streamWriteInt32(streamId, self.valueData)
  -- UInt8
  elseif self.valueType == 5 then streamWriteUInt8(streamId, self.valueData) 
  -- UInt16
  elseif self.valueType == 6 then streamWriteUInt16(streamId, self.valueData) 
  -- UIntN
  elseif self.valueType == 7 then streamWriteUIntN(streamId, self.valueData) 
  -- Float32
  elseif self.valueType == 8 then streamWriteFloat32(streamId, self.valueData)
  -- Unknown
  else 
    streamWriteInt8(streamId, 0)
  end
  
end

function FCSettingEvent:run(connection)
	if not connection:getIsServer() then
		FCSettingEvent.sendEvent(self.valueType, self.valueName, self.valueData)
  end
  -- Save data to xml file if global var is set
  if g_fsgSettings ~= nil then
    if self.valueName ~= nil and self.valueName == "realTimeSyncNoti" then
      -- Display notification to player
      g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, self.valueData)
    else
      -- Save realtime data from server to local
      g_fsgSettings.settings:setValue(self.valueName, self.valueData)
      g_fsgSettings.settings:saveSettings()
    end
  end
end

function FCSettingEvent.sendEvent(...)
	if g_server ~= nil then
		g_server:broadcastEvent(FCSettingEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(FCSettingEvent.new(...))
	end
end