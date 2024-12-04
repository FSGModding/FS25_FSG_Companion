-- Updated to FS25 standards with farmId bits corrected.
-- Custom bits added for hire limits as well.
FCAIJobStartRequestEvent = {}
local FCAIJobStartRequestEvent_mt = Class(FCAIJobStartRequestEvent, Event)
InitEventClass(FCAIJobStartRequestEvent, "FCAIJobStartRequestEvent")
function FCAIJobStartRequestEvent.emptyNew()
	return Event.new(FCAIJobStartRequestEvent_mt)
end
function FCAIJobStartRequestEvent.new(job, startFarmId)
	local self = FCAIJobStartRequestEvent.emptyNew()
	self.job = job
	self.startFarmId = startFarmId
	return self
end
function FCAIJobStartRequestEvent.newServerToClient(state, jobTypeIndex)
	local self = FCAIJobStartRequestEvent.emptyNew()
	self.state = state
	self.jobTypeIndex = jobTypeIndex
	return self
end
function FCAIJobStartRequestEvent.readStream(self, streamId, connection)
	if connection:getIsServer() then
    self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.state = streamReadUInt8(streamId)
		self.jobTypeIndex = streamReadUInt16(streamId)
	else
		self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local jobTypeIndex = streamReadUInt16(streamId)
		self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
		self.job:readStream(streamId, connection)
	end
	self:run(connection)
end
function FCAIJobStartRequestEvent.writeStream(self, streamId, connection)
	if connection:getIsServer() then
		streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		streamWriteUInt16(streamId, jobTypeIndex)
		self.job:writeStream(streamId, connection)
	else
    streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteUInt8(streamId, self.state)
		streamWriteUInt16(streamId, self.jobTypeIndex)
	end
end
function FCAIJobStartRequestEvent.run(self, connection)
  rcDebug("FCFCAIJobStartRequestEvent-run")
	if connection:getIsServer() then
		g_messageCenter:publish(FCAIJobStartRequestEvent, self.state, self.jobTypeIndex)
		return
	else
		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		local startable, state = self.job:getIsStartable(connection)

    -- Start custom bits to make sure within our settings
    rcDebug(self.startFarmId)

    -- If starterFarmId nil then use default
    local newStarterFarmId = FarmManager.SINGLEPLAYER_FARM_ID
    if self.startFarmId ~= nil then
      newStarterFarmId = self.startFarmId
    end

    -- Check if farm is at limit
    -- Get number of active jobs for farm
    local activeJobVehicles = 0
    for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
      if job.startedFarmId == newStarterFarmId then
        activeJobVehicles = activeJobVehicles + 1
      end
    end

    local hireLimit = math.floor(g_fsgSettings.settings:getValue("hireLimit")) - 1 or 2
    rcDebug("Hire Limit")
    rcDebug(hireLimit)

    -- If there are multipe missions, loop through them to check what farms they belong to
    if activeJobVehicles ~= nil then
      -- Check to see how many AI are hired for current farmId
      if activeJobVehicles >= hireLimit then
        rcDebug("Max AI Hired For Farm")
        startable = false
        if g_client then
          -- g_currentMission:showBlinkingWarning(g_i18n:getText("rc_max_hire_warn"), 5000)
          InfoDialog.show(g_i18n:getText("rc_max_hire_warn"), nil, nil, DialogElement.TYPE_WARNING)
        end        
      end
    end
    -- End custom Bits to make sure within our settings


		if startable then
			connection:sendEvent(FCAIJobStartRequestEvent.newServerToClient(0, jobTypeIndex))
			g_currentMission.aiSystem:startJob(self.job, newStarterFarmId)
		else
			connection:sendEvent(FCAIJobStartRequestEvent.newServerToClient(state, jobTypeIndex))
		end
	end
end
