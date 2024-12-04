-- Updated to FS25 standards with farmId bits corrected.
FCTreePlantEvent = {}
local FCTreePlantEvent_mt = Class(FCTreePlantEvent, Event)
InitEventClass(FCTreePlantEvent, "FCTreePlantEvent")
function FCTreePlantEvent.emptyNew()
	return Event.new(FCTreePlantEvent_mt)
end
function FCTreePlantEvent.new(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, splitShapeFileId, isGrowing, price, farmId)
	local self = FCTreePlantEvent.emptyNew()
	self.treeType = treeType
	self.x = x
	self.y = y
	self.z = z
	self.rx = rx
	self.ry = ry
	self.rz = rz
	self.growthStateI = growthStateI
	self.variationIndex = variationIndex
	self.splitShapeFileId = splitShapeFileId
	self.isGrowing = isGrowing
	self.price = price or 0
	self.farmId = farmId or 0
	return self
end
function FCTreePlantEvent.readStream(_, streamId, connection)
	local treeType = streamReadUInt8(streamId)
	local x = streamReadFloat32(streamId)
	local y = streamReadFloat32(streamId)
	local z = streamReadFloat32(streamId)
	local rx = streamReadFloat32(streamId)
	local ry = streamReadFloat32(streamId)
	local rz = streamReadFloat32(streamId)
	local growthStateI = streamReadUIntN(streamId, TreePlantManager.STAGE_NUM_BITS)
	local variationIndex = streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS)
	if connection:getIsServer() then
		local serverSplitShapeFileId = streamReadInt32(streamId)
		local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromIndex(treeType)
		if treeTypeDesc ~= nil then
			local nodeId, splitShapeFileId = g_treePlantManager:loadTreeNode(treeTypeDesc, x, y, z, rx, ry, rz, growthStateI, variationIndex, -1)
			setSplitShapesFileIdMapping(splitShapeFileId, serverSplitShapeFileId)
			g_treePlantManager:addClientTree(serverSplitShapeFileId, nodeId)
		end
	else
		local isGrowing = streamReadBool(streamId)
		local price = streamReadInt32(streamId)
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		g_treePlantManager:plantTree(treeType, x, y, z, rx, ry, rz, growthStateI, variationIndex, isGrowing)
		if price > 0 then
			g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_PROPERTY_BUY, true)
			return
		end
	end
end
function FCTreePlantEvent.writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.treeType)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.y)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rx)
	streamWriteFloat32(streamId, self.ry)
	streamWriteFloat32(streamId, self.rz)
	streamWriteUIntN(streamId, self.growthStateI, TreePlantManager.STAGE_NUM_BITS)
	streamWriteUIntN(streamId, self.variationIndex, TreePlantManager.VARIATION_NUM_BITS)
	if connection:getIsServer() then
		streamWriteBool(streamId, self.isGrowing)
		streamWriteInt32(streamId, self.price)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteInt32(streamId, self.splitShapeFileId)
	end
end
function FCTreePlantEvent.run(_, _)
	printError("Error: FCTreePlantEvent is not allowed to be executed on a local client")
end
