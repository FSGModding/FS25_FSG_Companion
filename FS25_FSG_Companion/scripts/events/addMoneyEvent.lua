AddMoneyEvent = {}
local AddMoneyEvent_mt = Class(AddMoneyEvent, Event)

InitEventClass(AddMoneyEvent, "AddMoneyEvent")

function AddMoneyEvent.emptyNew()
  -- rcDebug(' Info: AddMoneyEvent:emptyNew')
  return Event.new(AddMoneyEvent_mt)
end

function AddMoneyEvent.new(amount, farmId, moneyType)
  -- rcDebug(' Info: AddMoneyEvent:new')
  local self = AddMoneyEvent.emptyNew()

	self.amount = amount
  self.farmId = farmId
	self.moneyType = moneyType

  return self
end

function AddMoneyEvent:readStream(streamId, connection)
  -- rcDebug(' Info: AddMoneyEvent:readStream')

	self.amount = streamReadFloat32(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
  local moneyId = streamReadUInt16(streamId)
	self.moneyType = MoneyType.getMoneyTypeById(moneyId)

  self:run(connection)
end

function AddMoneyEvent:writeStream(streamId, connection)
  -- rcDebug(' Info: AddMoneyEvent:writeStream')

	streamWriteFloat32(streamId, self.amount)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
  streamWriteUInt16(streamId, self.moneyType.id)
end

function AddMoneyEvent:run(connection)
  -- rcDebug(' Info: AddMoneyEvent:run') 

  if not connection:getIsServer() then
    -- rcDebug(' Info: AddMoneyEvent:run:notServer')
    g_server:broadcastEvent(AddMoneyEvent.new(self.amount, self.farmId, self.moneyType))
  end

  g_currentMission:addMoney(-self.amount, self.farmId, self.moneyType, true)
end

function AddMoneyEvent.sendEvent(self, amount, farmId, moneyType)
  -- rcDebug(' Info: AddMoneyEvent:sendEvent')
  if g_currentMission.missionDynamicInfo.isMultiplayer then 
    if g_server ~= nil then
      g_server:broadcastEvent(AddMoneyEvent.new(amount, farmId, moneyType))
    else
      g_client:getServerConnection():sendEvent(AddMoneyEvent.new(amount, farmId, moneyType))
    end
  else
    g_currentMission:addMoney(-amount, farmId, moneyType, true)
  end
end