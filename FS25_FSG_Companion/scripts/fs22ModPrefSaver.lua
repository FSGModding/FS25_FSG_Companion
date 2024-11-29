FS22PrefSaver = {}

FS22PrefSaver.typeMap = {
	boolean = "bool",
	number  = "float",
	string  = "string"
}

local FS22PrefSaver_mt = Class(FS22PrefSaver)


function FS22PrefSaver:new(modName, fileName, perSaveSlot, defaults, loadHookFunction, saveHookFunction)
	local self = setmetatable({}, FS22PrefSaver_mt)

	self.modName        = modName
	self.fileName       = fileName
	self.perSaveSlot    = perSaveSlot or false
	self.settings       = {}
	self.defaults       = {}

	self:addDefaults(defaults)

	self.loadHookFunction = loadHookFunction
	self.saveHookFunction = saveHookFunction

	if self.fileName:sub(-4) ~= ".xml" then
		self.fileName = self.fileName .. ".xml"
	end

	return self
end

function FS22PrefSaver:addDefaults(defaults)
	if type(defaults) == "table" then
		for defName, defSetting in pairs(defaults) do
			if type(defSetting) == "table" then
				self.defaults[defName] = defSetting
			else
				self.defaults[defName] = {
					defSetting,
					FS22PrefSaver.typeMap[type(defSetting)]
				}
			end
		end
	end
end

function FS22PrefSaver:dumpSettings()
  -- rcDebug("Settings Current")
	-- rcDebug(self.settings)
end

function FS22PrefSaver:dumpDefaults()
  -- rcDebug("Settings Default")
	-- rcDebug(self.defaults)
end

function FS22PrefSaver:getValue(name)
	if self.settings[name] == nil then
		if self.defaults[name] == nil or self.defaults[name][1] == nil then
			-- rcDebug("UnKnown Setting: " .. name)
			return nil
		else
			-- rcDebug("UnSet Setting (return default): " .. name)
			return self.defaults[name][1]
		end
	else
		-- rcDebug("Found Setting (return): " .. name)
		return self.settings[name]
	end
end

function FS22PrefSaver:setValue(name, newValue)
	if self.settings[name] == nil and self.defaults[name] == nil then
		-- rcDebug("Unknown Setting (return nil): " .. name)
		return nil
	end

	self.settings[name] = newValue

	-- rcDebug("Set Setting: " .. name)

	return self:getValue(name)
end


function FS22PrefSaver:createSavePath()
	local saveFolder = ('%smodSettings/%s'):format(
		getUserProfileAppPath(),
		self.modName
	)
	if ( not fileExists(saveFolder) ) then createFolder(saveFolder) end

	if self.perSaveSlot then
		saveFolder = ('%smodSettings/%s/savegame%d'):format(
			getUserProfileAppPath(),
			self.modName,
			g_currentMission.missionInfo.savegameIndex
		)
		if ( not fileExists(saveFolder) ) then createFolder(saveFolder) end
	end
end

function FS22PrefSaver:getXMLFileName()
	local name = self.perSaveSlot and
		('%smodSettings/%s/savegame%d/%s'):format(
			getUserProfileAppPath(),
			self.modName,
			g_currentMission.missionInfo.savegameIndex,
			self.fileName
		) or ('%smodSettings/%s/%s'):format(
			getUserProfileAppPath(),
			self.modName,
			self.fileName
		)

	-- rcDebug("XML File Name: " .. name)
	return name
end

function FS22PrefSaver:xmlPathMaker(key, element, attrib)
	return key .. "." .. element .. "#" .. attrib
end

function FS22PrefSaver:saveSettings()
  --print("FS22PrefSaver:saveSettings - Saving data to xml")
	self:createSavePath()

	local key     = "prefSaver"
	local xmlFile = createXMLFile(key, self:getXMLFileName(), key)
  local saveData = {}

	for thisSettingName, thisSettingVal in pairs(self.defaults) do

		if thisSettingVal[2] == "bool" then
			setXMLBool(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "string" then
			setXMLString(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "int" then
			setXMLInt(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "float" then
			setXMLFloat(
				xmlFile,
				self:xmlPathMaker(key, thisSettingName, "value"),
				self:getValue(thisSettingName)
			)
		elseif thisSettingVal[2] == "color" then
			local r, g, b, a = unpack(Utils.getNoNil(self:getValue(thisSettingName), thisSettingVal[1]))
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "r"), r)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "g"), g)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "b"), b)
			setXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "a"), a)
		end
	end

	saveXMLFile(xmlFile)

	-- rcDebug("Saved Settings")

	if type(self.saveHookFunction) == "function" then
		self.saveHookFunction()
	end
end

function FS22PrefSaver:loadSettings()
	local key     = "prefSaver"

	if fileExists(self:getXMLFileName()) then
		local xmlFile = loadXMLFile(key, self:getXMLFileName())

		for thisSettingName, thisSettingVal in pairs(self.defaults) do
			if thisSettingVal[2] == "bool" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLBool(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "string" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLString(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "int" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLInt(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "float" then
				self:setValue(
					thisSettingName, 
					Utils.getNoNil(getXMLFloat(
						xmlFile,
						self:xmlPathMaker(key, thisSettingName, "value")
					), thisSettingVal[1])
				)
			elseif thisSettingVal[2] == "color" then
				local r, g, b, a = unpack(thisSettingVal[1])
				r = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "r")), r)
				g = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "g")), g)
				b = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "b")), b)
				a = Utils.getNoNil(getXMLFloat(xmlFile, self:xmlPathMaker(key, thisSettingName, "a")), a)
				self:setValue(thisSettingName, {r, g, b, a})
			end
		end

		delete(xmlFile)
	end

	-- rcDebug("Loaded Settings")

	if type(self.loadHookFunction) =="function" then
		self.loadHookFunction()
	end
end