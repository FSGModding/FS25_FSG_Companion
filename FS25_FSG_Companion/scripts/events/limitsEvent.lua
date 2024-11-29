---@class LimitsEvent
LimitsEvent = {}
local LimitsEvent_mt = Class(LimitsEvent, Event)

InitEventClass(LimitsEvent, "LimitsEvent")

function LimitsEvent.emptyNew()
  rcDebug("LE-emptyNew")
	return Event.new(LimitsEvent_mt)
end

function LimitsEvent.new(selfData, ownerFarmId, activeJobVehicles, sequence)
  rcDebug("LE-new")
	local self = LimitsEvent.emptyNew()
  self.selfData = selfData
  self.ownerFarmId = ownerFarmId
  self.activeJobVehicles = activeJobVehicles
  self.sequence = sequence + 1
	return self
end

function LimitsEvent:readStream(streamId, connection)
  rcDebug("LE-readStream")
  -- Get data from clients
  self.selfData = NetworkUtil.readNodeObject(streamId)
  self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  self.activeJobVehicles = streamReadInt32(streamId)
  self.sequence = streamReadInt32(streamId) + 1
	self:run(connection)
end

function LimitsEvent:writeStream(streamId, connection)
  rcDebug("LE-writeStream")
  -- Send data out to clients
  NetworkUtil.writeNodeObject(streamId, self.selfData)
  streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteInt32(streamId, self.activeJobVehicles)
  streamWriteInt32(streamId, self.sequence)
end

function LimitsEvent:run(connection)
  rcDebug("LE-run")
  if g_server ~= nil then 
    local farmHiredCount = {}
    if self.activeJobVehicles == nil or self.activeJobVehicles == 0 then 
      -- Get total number of AI vehicles for farm
      local activeJobVehiclesData = g_currentMission.aiSystem.activeJobVehicles
      rcDebug("activeJobVehiclesData: " .. #activeJobVehiclesData)
      if #activeJobVehiclesData > 0 then
        -- Loop through all active missions
        for _, activeJobVehicle in ipairs(activeJobVehiclesData) do
          -- Check if job has owner assigned
          if activeJobVehicle.spec_aiJobVehicle.startedFarmId ~= nil then
            local ownerFarm = activeJobVehicle.spec_aiJobVehicle.startedFarmId;
            if farmHiredCount[ownerFarm] ~= nil then
              farmHiredCount[ownerFarm] = tonumber(farmHiredCount[ownerFarm]) + 1
            else
              farmHiredCount[ownerFarm] = 1
            end
          end
        end
      end
    end
    if farmHiredCount[self.ownerFarmId] ~= nil then
      self.activeJobVehicles = farmHiredCount[self.ownerFarmId]
    else
      self.activeJobVehicles = 0
    end
    rcDebug("activeJobVehicles: " .. self.activeJobVehicles)
    rcDebug("ownerFarmId: " .. self.ownerFarmId)
    self.sendEvent(self.selfData, self.ownerFarmId, self.activeJobVehicles, self.sequence)
  else
    g_limits:toggleAIVehicleSecond(self.selfData, self.ownerFarmId, self.activeJobVehicles, self.sequence, false)
  end
end

function LimitsEvent.sendEvent(...)
  rcDebug("LE-sendEvent")
	if g_server ~= nil then
		g_server:broadcastEvent(LimitsEvent.new(...))
	else
		g_client:getServerConnection():sendEvent(LimitsEvent.new(...))
	end
end