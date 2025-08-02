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
    -- Make sure money type is not a repetitive one.
    if amount < -10 or amount > 10 then 
    
        rcDebug("GameLogs:MoneyChange")

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
end

-- Logs Inbox filenames and checks if they have already been added or not.  
function GameLogs:InboxLog(filename, xmlFile)
    rcDebug("GameLogs:InboxLog")

    local key = "commands"
    local command = nil

    xmlFile:iterate(key .. ".command", function (_, commandKey)
      command = xmlFile:getString(commandKey .. "#command");
    end)

    -- Ignore logging for sendChat commands
    if command ~= nil and command == "sendChat" then
      return true
    end

    -- Ok for us to accept duplicates for the following commands
    if command ~= nil and (command == "createFarm" or command == "makeFarmManager") then
      return true
    end

    local modSettingsFolderPath = getUserProfileAppPath() .. "modSettings/FS25_FSG_Companion"
    local modSettingsFile = modSettingsFolderPath .. "/InboxLog.xml"

    local logXmlFile

    -- Load if it exists, otherwise create new
    if fileExists(modSettingsFile) then
        logXmlFile = loadXMLFile("transactions", modSettingsFile)
    else
        logXmlFile = createXMLFile("transactions", modSettingsFile, "transactions")
    end

    -- Check if filename already exists
    local index = 0
    while hasXMLProperty(logXmlFile, string.format("transactions.transaction(%d)", index)) do
        local entryKey = string.format("transactions.transaction(%d)", index)
        local existingFilename = getXMLString(logXmlFile, entryKey .. "#filename")
        if existingFilename == filename then
            delete(logXmlFile)
            return false -- Filename already logged
        end
        index = index + 1
    end

    -- Create new transaction entry
    local baseKey = string.format("transactions.transaction(%d)", index)
    local timestamp = getDate("%Y-%m-%d %H:%M:%S")

    setXMLString(logXmlFile, baseKey .. "#timestamp", timestamp)
    setXMLString(logXmlFile, baseKey .. "#filename", filename)

    -- Prune log to last 100 entries
    local totalEntries = index + 1
    if totalEntries > 100 then
        local removeCount = totalEntries - 100
        for i = 1, removeCount do
            removeXMLProperty(logXmlFile, "transactions.transaction(0)")
        end
    end

    -- Save and clean up
    saveXMLFile(logXmlFile)
    delete(logXmlFile)

    return true -- New filename added
end
