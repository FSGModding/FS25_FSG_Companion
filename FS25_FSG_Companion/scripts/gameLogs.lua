GameLogs = {}

local GameLogs_mt = Class(GameLogs)

function GameLogs:new(mission, i18n, modDirectory, modName)
  local self = setmetatable({}, GameLogs_mt)

	self.lastScrollTime   = 0
	self.returnScreenName = ""
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName

	return self
end

-- Log every time a money change happens
function GameLogs:MoneyChange(amount, farmId, moneyType, forceShow)
    rcDebug("GameLogs:MoneyChange")
    rcDebug(amount)
    rcDebug(farmId)
    rcDebug(moneyType.title)
    rcDebug(moneyType.statistic)

    local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
    local modSettingsFile = modSettingsFolderPath .. "/MoneyTransactions.xml"

    local xmlFile

    -- Load if it exists, otherwise create new
    if fileExists(modSettingsFile) then
        xmlFile = loadXMLFile("transactions", modSettingsFile)
    else
        xmlFile = createXMLFile("transactions", modSettingsFile, "transactions")
    end

    -- Get next available transaction index
    local index = 0
    while hasXMLProperty(xmlFile, string.format("transactions.transaction(%d)", index)) do
        index = index + 1
    end

    -- Create new transaction entry
    local baseKey = string.format("transactions.transaction(%d)", index)
    local timestamp = getDate("%Y-%m-%d %H:%M:%S")

    setXMLString(xmlFile, baseKey .. "#timestamp", timestamp)
    setXMLFloat(xmlFile, baseKey .. "#amount", amount)
    setXMLInt(xmlFile, baseKey .. "#farmId", farmId)
    setXMLString(xmlFile, baseKey .. "#moneyTypeTitle", moneyType.title or "Unknown")
    setXMLString(xmlFile, baseKey .. "#moneyTypeStat", moneyType.statistic or "None")

    -- Save and clean up
    saveXMLFile(xmlFile)
    delete(xmlFile)

end
