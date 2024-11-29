FCAIJobStartEvent = {}
local FCAIJobStartEvent_mt = Class(FCAIJobStartEvent, Event)

InitEventClass(FCAIJobStartEvent, "FCAIJobStartEvent")

-- Lines 12-15
function FCAIJobStartEvent.emptyNew()
	local self = Event.new(FCAIJobStartEvent_mt)

	return self
end

-- Lines 19-26
function FCAIJobStartEvent.new(job, superFunc, startFarmId)
  rcDebug("FCAIJobStartEvent-new")
  rcDebug(job)
  rcDebug(startFarmId)
	local self = FCAIJobStartEvent.emptyNew()
	self.job = job
	self.startFarmId = startFarmId

	return self
end

-- Lines 30-40
function FCAIJobStartEvent:readStream(streamId, connection)
	assert(connection:getIsServer(), "FCAIJobStartEvent is a server to client only event")

  self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local jobTypeIndex = streamReadInt32(streamId)
	self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)

	self.job:readStream(streamId, connection)
	self:run(connection)
end

-- Lines 44-49
function FCAIJobStartEvent:writeStream(streamId, connection)
  streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)

	local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)

	streamWriteInt32(streamId, jobTypeIndex)
	self.job:writeStream(streamId, connection)
end

-- Lines 53-55
function FCAIJobStartEvent:run(connection)
    rcDebug("FCAIJobStartEvent-run")
    rcDebug(self.startFarmId)
	g_currentMission.aiSystem:startJobInternal(self.job, self.startFarmId)
end
