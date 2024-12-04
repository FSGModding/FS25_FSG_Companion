-- Updated to FS25 standards with farmId bits corrected.
FCAIJobStartEvent = {}
local FCAIJobStartEvent_mt = Class(FCAIJobStartEvent, Event)
InitEventClass(FCAIJobStartEvent, "FCAIJobStartEvent")
function FCAIJobStartEvent.emptyNew()
	return Event.new(FCAIJobStartEvent_mt)
end
function FCAIJobStartEvent.new(job, startFarmId)
	local self = FCAIJobStartEvent.emptyNew()
	self.job = job
	self.startFarmId = startFarmId
	return self
end
function FCAIJobStartEvent.readStream(self, streamId, connection)
	local isServer = connection:getIsServer()
	assert(isServer, "FCAIJobStartEvent is a server to client only event")
	self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local jobTypeIndex = streamReadInt32(streamId)
	self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
	self.job:readStream(streamId, connection)
	self:run(connection)
end
function FCAIJobStartEvent.writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
	streamWriteInt32(streamId, jobTypeIndex)
	self.job:writeStream(streamId, connection)
end
function FCAIJobStartEvent.run(self, _)
	g_currentMission.aiSystem:startJobInternal(self.job, self.startFarmId)
end
