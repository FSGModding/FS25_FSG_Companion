FCAIJobStartRequestEvent = {}
local FCAIJobStartRequestEvent_mt = Class(FCAIJobStartRequestEvent, Event)

InitEventClass(FCAIJobStartRequestEvent, "FCAIJobStartRequestEvent")

-- Lines 12-15
function FCAIJobStartRequestEvent.emptyNew()
	local self = Event.new(FCAIJobStartRequestEvent_mt)

	return self
end

-- Lines 19-26
function FCAIJobStartRequestEvent.new(job, superFunc, startFarmId)
  rcDebug("FCAIJobStartRequestEvent-new")
	local self = FCAIJobStartRequestEvent.emptyNew()
	rcDebug(job)
  rcDebug(startFarmId)
  self.job = job
	self.startFarmId = startFarmId

	return self
end

-- Lines 30-36
function FCAIJobStartRequestEvent.newServerToClient(state, jobTypeIndex)
	local self = FCAIJobStartRequestEvent.emptyNew()
	self.state = state
	self.jobTypeIndex = jobTypeIndex

	return self
end

-- Lines 40-52
function FCAIJobStartRequestEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.startFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local jobTypeIndex = streamReadUInt16(streamId)
		self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)

		self.job:readStream(streamId, connection)
	else
		self.state = streamReadUInt8(streamId)
		self.jobTypeIndex = streamReadUInt16(streamId)
	end

	self:run(connection)
end

-- Lines 56-66
function FCAIJobStartRequestEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
    streamWriteUIntN(streamId, self.startFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)

		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)

		streamWriteUInt16(streamId, jobTypeIndex)
		self.job:writeStream(streamId, connection)
	else
		streamWriteUInt8(streamId, self.state)
		streamWriteUInt16(streamId, self.jobTypeIndex)
	end
end

-- Lines 70-86
function FCAIJobStartRequestEvent:run(connection)
	if not connection:getIsServer() then
    rcDebug("FCAIJobStartRequestEvent-run")
    rcDebug(self.startFarmId)
		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		local startable, state = self.job:getIsStartable(connection)

    -- Check if farm is at limit
    -- Get number of active jobs for farm
    local activeJobVehicles = 0
    for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
      if job.startedFarmId == self.startFarmId then
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
          g_currentMission:showBlinkingWarning(g_i18n:getText("rc_max_hire_warn"), 5000)
        end        
      end
    end

		if not startable then
			connection:sendEvent(FCAIJobStartRequestEvent.newServerToClient(state, jobTypeIndex))

			return
		end

		connection:sendEvent(FCAIJobStartRequestEvent.newServerToClient(0, jobTypeIndex))
		g_currentMission.aiSystem:startJob(self.job, self.startFarmId)
	else
		g_messageCenter:publish(FCAIJobStartRequestEvent, self.state, self.jobTypeIndex)
	end
end
