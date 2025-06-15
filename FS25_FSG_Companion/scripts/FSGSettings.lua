rcDebug("FSGSettings Class")

FSGSettings = {}
FSGSettings.modName = g_currentModName
FSGSettings.modDirectory = g_currentModDirectory
FSGSettings.baseXmlKey = "FSGSettings"
FSGSettings.xmlKey = FSGSettings.baseXmlKey.."."

local FSGSettings_mt = Class(FSGSettings, Event)

InitEventClass(FSGSettings, "FSGSettings")

function FSGSettings.new(mission, i18n, modDirectory, modName)
  rcDebug("FSGS-New")
  local self = setmetatable({}, FSGSettings_mt)
  self.mission                = mission
  self.i18n                   = i18n
  self.modDirectory           = modDirectory
  self.modName                = modName
  self.isServer               = g_currentMission:getIsServer()
  self.justSetFalse           = false
  self.speedFix               = false
  self.setValueTimerFrequency = 60
  self.ServerUpdate           = false
  self.ServerHour             = 0
  self.ServerMinCleanUTC      = 0
  self.TimeSpeed              = 1
  self.actionEventId          = nil

  -- Load mod default settings
  self.settings = FS25PrefSaver:new(
    "FS25_FSG_Companion",
    "CompanionSettings.xml",
    false,
    {
      dismissWorkers          = {true, "bool"},
      inboxActive             = {true, "bool"},
      paintAnywhere           = {false, "bool"},
      hireLimit               = {3, "int"},
      maxMissions             = {3, "int"},
      husbandryLimit          = {3, "int"},
      productionPoints        = {3, "int"},
      sellingPoints           = {2, "int"},
      farmHouses              = {2, "int"},
      generators              = {2, "int"},
      gardenSheds             = {21, "int"},
      floodLighting           = {21, "int"},
      otherPlaceables         = {6, "int"},
      progressNoti            = {true, "bool"},
      timeSyncEnable          = {true, "bool"},
      serverOffset            = {1, "int"},
      timeFixHour             = {1, "int"},
      autoSetTime             = {false, "bool"},
      transactionId           = {0, "int"},
      coopLimitsEnabled       = {false, "bool"},
      coopMinCruiseSpeed      = {3, "int"},
      coopMinCruiseMin        = {3, "int"},
      disableSleep            = {true, "bool"},
      disableBorrowEquipment  = {false, "bool"},
      placeableGreenhouses    = {2, "int"}
    },
		nil,
		nil
  )

	return self
end

-- Run on map load
-- FS25 - There is a new way to load menus.  Will have to come back to this.
function FSGSettings:loadMap(filename)
  rcDebug(" Info: FSGS-loadMap")

	self.settings:loadSettings()
	self.settings:saveSettings()

  local FSGInfoFrame = FSGSettingsGuiInfoFrame:new(nil, g_i18n)
  -- local FSGToolsFrame = FSGSettingsGuiToolsFrame:new(nil, g_i18n)
  local FSGSettingsFrame = FSGSettingsGuiSettingsFrame:new(nil, g_i18n)
  local FSGTimeSyncFrame = FSGSettingsGuiTimeSyncFrame:new(nil, g_i18n)
  -- local FSGFarmTransactionsFrame = FSGSettingsFarmTransactionsFrame:new(nil, g_i18n)

  g_gui:loadProfiles(FSGSettings.modDirectory .. "gui/guiProfiles.xml")

  FSGSettings.gui = FSGSettingsGui:new(g_messageCenter, g_i18n, g_inputBinding)

  g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsGuiInfoFrame.xml", "FSGSettingsGuiInfoFrame", FSGInfoFrame, true)
  -- g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsGuiToolsFrame.xml", "FSGSettingsGuiToolsFrame", FSGToolsFrame, true)
  g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsGuiSettingsFrame.xml", "FSGSettingsGuiSettingsFrame", FSGSettingsFrame, true)
  g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsGuiTimeSyncFrame.xml", "FSGSettingsGuiTimeSyncFrame", FSGTimeSyncFrame, true)
  -- g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsFarmTransactionsFrame.xml", "FSGSettingsFarmTransactionsFrame", FSGFarmTransactionsFrame, true)
  g_gui:loadGui(FSGSettings.modDirectory .. "gui/FSGSettingsGui.xml", "FSGSettingsGui", FSGSettings.gui)

end

-- Register Player Interaction
function FSGSettings:updateActionEvents()
  if g_currentMission:getIsClient() == true then
    -- rcDebug(" Info: FSGS-updateActionEvents")
    -- We have to run this often to work in MP
    local _, actionEventId = g_inputBinding:registerActionEvent('FSG_MENU', self, FSGSettings.actionAdditionalInfo_openGui, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("FSG_MENU"))
    self.actionEventId = actionEventId
  end
end

-- Load the gui
function FSGSettings:actionAdditionalInfo_openGui(actionName, keyStatus, arg3, arg4, arg5)
  rcDebug(" Info: FSGS-actionAdditionalInfo_openGui")
  if g_gui.currentGui == nil then
    -- Load the gui
    g_gui:showGui("FSGSettingsGui")
  end
end

function FSGSettings:update(dt)
  -- Register the button input
  FSGSettings:updateActionEvents()

  -- Set Defaults
  local TimeDiff = 0
  local TimeSpeed = 1

  -- check if within the loopCount, and if server or single player.  Don't run on server clients.

  -- If the game timescale IS NOT 1x then run the time adjustments every 60 milliseconds. -- Myrithis (Catalyzer Industries)
  -- If the game timescale IS     1x then run the time adjustments every 10 minutes. -- Myrithis (Catalyzer Industries)
  if (g_currentMission.missionInfo.timeScale ~= 1 and g_updateLoopIndex % self.setValueTimerFrequency and FSGSettings:singleServerCheck())
      or (g_updateLoopIndex % ((self.setValueTimerFrequency*60)*10) == 0 and FSGSettings:singleServerCheck()) then

    self.settings:loadSettings()
    if self.settings:getValue("timeSyncEnable") == false then
      -- Check to see if just set as false.  if so then set speed to 1
      if self.justSetFalse == true then
        if FSGSettings:isSinglePlayer() then
          g_currentMission.missionInfo.timeScale = 1
        else
          g_currentMission:setTimeScale(1);
        end
        self.justSetFalse = false
      end
      return
    else
      self.justSetFalse = true
    end
    -- Get server hour and min
    local getServerHour = getTime()
    -- Get current hour from time
    local getTotalHours = (getServerHour / 60) / 60
    local getTotalDays = (getTotalHours / 24) - math.floor(getTotalHours / 24)
    local ServerHour = math.floor(getTotalDays * 24)
    -- Get current minute from time
    local ServerMinuteUTC = ((getTotalDays * 24) - math.floor(getTotalDays * 24)) * 60
    local ServerMinCleanUTC = math.floor(ServerMinuteUTC)
    -- Setup the times so they work with game times
    local ServerMin = MathUtil.round(ServerMinuteUTC / 60, 2)
    local ServerTime = ServerHour + ServerMin
    -- Set defaults for later changed vars
    local AlwaysRun = false
    local SetServerTime = 0
    -- Convert timeFixHour to a read able format
    local setTimeFixHour = self.settings:getValue("timeFixHour")
    local setServerOffset = self.settings:getValue("serverOffset") - 11
    local setAutoSetTime = self.settings:getValue("autoSetTime")
    -- Start the time fix process if enabled
    rcDebug("setTimeFixHour: " .. setTimeFixHour)
    local runTimeFixHour = 1
    if setTimeFixHour == 1 then
      AlwaysRun = true;
    else
      runTimeFixHour = setTimeFixHour
      rcDebug("runTimeFixHour: " .. runTimeFixHour)
    end
    -- get the current hour with offset if one is set
    -- check if there is a time offset - if so then offset the server time so we can match the game time to that offset
    if type(setServerOffset) == "number" and setServerOffset ~= 0 then
      rcDebug("FSGSettings:serverTimeBeforeOffset: " .. ServerHour + ServerMin)
      ServerHour = (ServerHour + setServerOffset);
    end
    -- check if timeFixHour is set and if so then check if that time matches current time.  Stop script if not 0 or hour matches
    if AlwaysRun == false and runTimeFixHour ~= tonumber(ServerHour) then
      rcDebug("FSGSettings:TimeFixHour not Always and ServerHour does not match TimeFixHour: " .. ServerHour .. "~=" .. runTimeFixHour)
      -- Set the speed to 1 just in case server was not done fixing the time.
      if self.speedFix == true then
        if FSGSettings:isSinglePlayer() then
          g_currentMission.missionInfo.timeScale = 1
        else
          g_currentMission:setTimeScale(1);
        end
        self.ServerUpdate = false -- Disable notifcation
        TimeSpeed = 1 -- Time scale speed
        self.speedFix = false
      end
      return
    end
    -- Get the game time for comparison 
    local GameHour = g_currentMission.environment.currentHour
    local GameMinute = g_currentMission.environment.currentMinute
    local GameMin = MathUtil.round(GameMinute / 60, 2)
    local GameTime = GameHour + GameMin
    -- Set the current server time with minutes added
    ServerTime = ServerHour + ServerMin;
    -- Check if ServerTime is greater than 24 and subtract if so so that it is not getting an invalid number
    if ServerTime > 24 then
      ServerTime = (ServerTime - 24)
    elseif ServerTime < 0 then
      ServerTime = (ServerTime + 24)
    end
    -- Time to set the game to if game is too far ahead of server time
    SetServerTime = ServerTime - 0.03

    -- get the time differance between server time and game time so we can see if we need to speed up or slow down
    TimeDiff = MathUtil.round(ServerTime - GameTime, 2);

    rcDebug("FSGSettings:SetServerTime: " .. SetServerTime)
    rcDebug("FSGSettings:ServerTime: " .. ServerTime)
    rcDebug("FSGSettings:GameTime: " .. GameTime)
    rcDebug("FSGSettings:TimeDiff: " .. TimeDiff)

    -- Set server time to global for notfication use
    self.ServerHour = ServerHour
    self.ServerMinCleanUTC = ServerMinCleanUTC

    -- Check if time if server time is greater than game time, if so then speed up time to catch up
    -- If server time is less than in game time, then pause time until caught up
    -- Need a 5 minute window to keep it from constantly changing

    -- Check if Game time is less than server time by more than 1 hour.  Speed time way up if so.
    if GameTime < ServerTime and TimeDiff > 1 then
      rcDebug("FSGSettings:GameTime < ServerTime and time is off by more than an hour - speed up time x240")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 240
      else
        g_currentMission:setTimeScale(240);
      end
      self.ServerUpdate = true -- Enable notifcation
      TimeSpeed = 240 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.75 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.75 then
      rcDebug("FSGSettings:GameTime < ServerTime and time is off by more than an hour - speed up time x120")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 120
      else
        g_currentMission:setTimeScale(120);
      end
      self.ServerUpdate = true -- Enable notifcation
      TimeSpeed = 120 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.5 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.5 then
      rcDebug("FSGSettings:GameTime < ServerTime and time is off by more than an hour - speed up time x60")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 60
      else
        g_currentMission:setTimeScale(60);
      end
      self.ServerUpdate = true -- Enable notifcation
      TimeSpeed = 60 -- Time scale speed

    -- Check if Game time is less than server time by more than 0.25 hours.  Speed time way up if so.
    elseif GameTime < ServerTime and TimeDiff > 0.25 then
      rcDebug("FSGSettings:GameTime < ServerTime and time is off by more than an hour - speed up time x30")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 30
      else
        g_currentMission:setTimeScale(30);
      end
      self.ServerUpdate = true -- enable notifcation
      TimeSpeed = 30 -- Time scale speed

    -- Check if Game time is less than server time.  Speed time up if so.
    elseif GameTime < ServerTime and TimeDiff > 0 then
      rcDebug("FSGSettings:GameTime < ServerTime - speed up time x5")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 5
      else
        g_currentMission:setTimeScale(5);
      end
      self.ServerUpdate = false -- disable notifcation
      TimeSpeed = 5 -- Time scale speed

    -- Check if Game time is greater than server time and set time is true.  Set the time to match
    elseif GameTime > ServerTime and TimeDiff < 0 and TimeDiff < -0.8 and setAutoSetTime == true then
      rcDebug("FSGSettings:GameTime > ServerTime - slow way down time")
      -- Looks to be changing both server time and game time
      g_currentMission.environment:consoleCommandSetDayTime(SetServerTime);
      -- Check if server then broadcast, if not then send local
      local setNotificationData = g_i18n:getText("title_realTimeSync_setInProgress") .. self.ServerHour .. ":" .. self.ServerMinCleanUTC - 2
      if self.isServer then
        g_server:broadcastEvent(FCSettingEvent.new(1, "realTimeSyncNoti", setNotificationData), nil, connection)
      else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, setNotificationData)
      end
      self.ServerUpdate = false -- disable notifcation
      TimeSpeed = 1 -- Time scale speed

    -- Check if Game time is greater than server time.  Slow time down if so.
    elseif GameTime > ServerTime and TimeDiff < -0.03 then
      rcDebug("FSGSettings:GameTime > ServerTime - slow way down time")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 0.1
      else
        g_currentMission:setTimeScale(0.1);
      end
      self.ServerUpdate = false -- disable notifcation
      TimeSpeed = 0.1 -- Time scale speed

    -- Check if Game time is greater than server time.  Slow time down if so.
    elseif GameTime > ServerTime then
      rcDebug("FSGSettings:GameTime > ServerTime - slow down time")
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 0.5
      else
        g_currentMission:setTimeScale(0.5);
      end
      self.ServerUpdate = false -- disable notifcation
      TimeSpeed = 0.5 -- Time scale speed

    -- If time matches, then keep at scale 1
    elseif g_currentMission.missionInfo.timeScale ~= 1 then	  
      if FSGSettings:isSinglePlayer() then
        g_currentMission.missionInfo.timeScale = 1
      else
        g_currentMission:setTimeScale(1);
      end
      self.ServerUpdate = false -- Disable notifcation
      TimeSpeed = 1 -- Time scale speed
    end
  end
  -- Check if we should notify players that there was a change
  if self.ServerUpdate == true and TimeDiff ~= 0 and TimeSpeed ~= self.TimeSpeed then
    -- Add zerof to min if less than 10
    local addZero = "";
    if self.ServerMinCleanUTC < 10 then addZero = "0" else addZero = "" end
    -- Check if player has time sync message enabled
    local progressNoti = self.settings:getValue("progressNoti")
    rcDebug("progressNoti:")
    rcDebug(progressNoti)
    if progressNoti == true then
      rcDebug("progressNoti Do It Yo!")
      -- Notify players time sync in progress
      local notificationData = g_i18n:getText("title_realTimeSync_inProgress") .. self.ServerHour .. ":" .. addZero .. self.ServerMinCleanUTC
      -- Check if server then broadcast, if not then send local
      if self.isServer then
        g_server:broadcastEvent(FCSettingEvent.new(1, "realTimeSyncNoti", notificationData), nil, connection)
      else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, notificationData)
      end
    end
    self.TimeSpeed = TimeSpeed -- Time scale speed
    self.ServerUpdate = false
    self.speedFix = true
  end
end

-- Run on savegame
function FSGSettings:onSaveComplete()
  rcDebug(" Info: FSGS-onSaveComplete")

  g_fsgSettings.settings:saveSettings()

end

-- Disable the sleep stuffs
function FSGSettings:disableSleep()
  -- Check to see if sleep is disabled
  local canDisableSleep = g_fsgSettings.settings:getValue("disableSleep")
  if canDisableSleep ~= nil and canDisableSleep then
    return false
  else
    return not g_sleepManager.isSleeping
  end
end

-- Check if client is a server or single player
function FSGSettings:singleServerCheck()
  -- Check if server
  if g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer ~= nil and g_server ~= nil then 
    -- Multiplayer Server Host
    return true
  -- Check if single player
  elseif g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer == nil and g_server ~= nil then 
    -- Single player client
    return true
  else
    -- Client on dedicated server
    return false
  end
end

-- Check if single player
function FSGSettings:isSinglePlayer()
  if g_currentMission:getIsServer() == true and g_currentMission:getIsClient() == true and g_dedicatedServer == nil and g_server ~= nil then 
    return true
  else
    return false
  end
end

-- Refresh Settings Menus
function FSGSettings:refresh()
  if g_dedicatedServer == nil then
    FSGSettingsGuiSettingsFrame:updateSettings()
    FSGSettingsGuiTimeSyncFrame:updateSettings()
    FSGSettingsGuiToolsFrame:updateSettings()
  end
end

-- Gets transactionId for current command to help avoid duplicates
function FSGSettings:getTransactionId()
  -- Get current transactionId
  local lastTransactionId = g_fsgSettings.settings:getValue("transactionId")
  -- Generate the new transactionId
  local newTranansactionId = lastTransactionId + 1 or 1
  -- Update the transactionId
  rcDebug("FSGSettings:getTransactionId: " .. newTranansactionId)
  g_fsgSettings.settings:setValue("transactionId",newTranansactionId)
  g_fsgSettings.settings:saveSettings()
  -- Send out the new transaction id to everyone
  FCSettingEvent.sendEvent(4, "transactionId", newTranansactionId)
  return newTranansactionId
end

-- Event when player joins server
function FSGSettings:join()
  rcDebug("FSGSettings:join")
  -- Send settings to new client
  FCSettingEvent.sendEvent(2, "paintAnywhere", g_fsgSettings.settings:getValue("paintAnywhere"))
  FCSettingEvent.sendEvent(2, "dismissWorkers", g_fsgSettings.settings:getValue("dismissWorkers"))
  FCSettingEvent.sendEvent(2, "inboxActive", g_fsgSettings.settings:getValue("inboxActive"))
  FCSettingEvent.sendEvent(3, "hireLimit", g_fsgSettings.settings:getValue("hireLimit"))
  FCSettingEvent.sendEvent(3, "maxMissions", g_fsgSettings.settings:getValue("maxMissions"))
  FCSettingEvent.sendEvent(3, "husbandryLimit", g_fsgSettings.settings:getValue("husbandryLimit"))
  FCSettingEvent.sendEvent(3, "productionPoints", g_fsgSettings.settings:getValue("productionPoints"))
  FCSettingEvent.sendEvent(3, "sellingPoints", g_fsgSettings.settings:getValue("sellingPoints"))
  FCSettingEvent.sendEvent(3, "farmHouses", g_fsgSettings.settings:getValue("farmHouses"))
  FCSettingEvent.sendEvent(3, "generators", g_fsgSettings.settings:getValue("generators"))
  FCSettingEvent.sendEvent(3, "gardenSheds", g_fsgSettings.settings:getValue("gardenSheds"))
  FCSettingEvent.sendEvent(3, "floodLighting", g_fsgSettings.settings:getValue("floodLighting"))
  FCSettingEvent.sendEvent(3, "otherPlaceables", g_fsgSettings.settings:getValue("otherPlaceables"))
  FCSettingEvent.sendEvent(2, "progressNoti", g_fsgSettings.settings:getValue("progressNoti"))
  FCSettingEvent.sendEvent(2, "timeSyncEnable", g_fsgSettings.settings:getValue("timeSyncEnable"))
  FCSettingEvent.sendEvent(3, "serverOffset", g_fsgSettings.settings:getValue("serverOffset"))
  FCSettingEvent.sendEvent(3, "timeFixHour", g_fsgSettings.settings:getValue("timeFixHour"))
  FCSettingEvent.sendEvent(2, "autoSetTime", g_fsgSettings.settings:getValue("autoSetTime"))
  FCSettingEvent.sendEvent(4, "transactionId", g_fsgSettings.settings:getValue("transactionId"))
  FCSettingEvent.sendEvent(2, "coopLimitsEnabled", g_fsgSettings.settings:getValue("coopLimitsEnabled"))
  FCSettingEvent.sendEvent(3, "coopMinCruiseSpeed", g_fsgSettings.settings:getValue("coopMinCruiseSpeed"))
  FCSettingEvent.sendEvent(3, "coopMinCruiseMin", g_fsgSettings.settings:getValue("coopMinCruiseMin"))
  FCSettingEvent.sendEvent(2, "disableSleep", g_fsgSettings.settings:getValue("disableSleep"))
  FCSettingEvent.sendEvent(3, "placeableGreenhouses", g_fsgSettings.settings:getValue("placeableGreenhouses"))
  
end