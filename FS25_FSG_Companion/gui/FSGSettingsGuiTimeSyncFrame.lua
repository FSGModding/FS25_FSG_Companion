--
-- FSG Settings - Settings Page
--

FSGSettingsGuiTimeSyncFrame = {}

local FSGSettingsGuiTimeSyncFrame_mt = Class(FSGSettingsGuiTimeSyncFrame, TabbedMenuFrameElement)

function FSGSettingsGuiTimeSyncFrame:new(subclass_mt, l10n)
    local self = FSGSettingsGuiTimeSyncFrame:superClass().new(nil, subclass_mt or FSGSettingsGuiTimeSyncFrame_mt)

    rcDebug("FSGSettingsGuiTimeSyncFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end


function FSGSettingsGuiTimeSyncFrame:copyAttributes(src)
    FSGSettingsGuiTimeSyncFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function FSGSettingsGuiTimeSyncFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function FSGSettingsGuiTimeSyncFrame:onGuiSetupFinished()
    FSGSettingsGuiTimeSyncFrame:superClass().onGuiSetupFinished(self)

end


function FSGSettingsGuiTimeSyncFrame:delete()
    FSGSettingsGuiTimeSyncFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function FSGSettingsGuiTimeSyncFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function FSGSettingsGuiTimeSyncFrame:onFrameOpen()
    FSGSettingsGuiTimeSyncFrame:superClass().onFrameOpen(self)

    rcDebug("FSGSettingsGuiTimeSyncFrame:onFrameOpen")

    -- Load Settings
    g_fsgSettings.settings:loadSettings()

    self.isOpening = true

    -- Reload the fsg settings
    self:updateSettings()

		self.companionSettingsLayout:setVisible(true)
		self.companionSettingsLayout:invalidateLayout()

    -- Alternates the background colors
    local set = true
    for _, tableRow in pairs(self.companionSettingsLayout.elements) do
      if tableRow.name == "sectionHeader" or tableRow.name == "fsgSettingsNoPermissionText" then
        set = true
      elseif tableRow:getIsVisible() then
        local color = InGameMenuSettingsFrame.COLOR_ALTERNATING[set]
        tableRow:setImageColor(nil, unpack(color))
        set = not set
      end
    end

    self.fsgSettingsNoPermissionText:setVisible(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

end


function FSGSettingsGuiTimeSyncFrame:onRefreshEvent()

end


function FSGSettingsGuiTimeSyncFrame:onFrameClose()
    FSGSettingsGuiTimeSyncFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end

function FSGSettingsGuiTimeSyncFrame:updateSettings()
  rcDebug("FSGSettingsGuiTimeSyncFrame:updateSettings")

  local timeSyncEnable = g_fsgSettings.settings:getValue("timeSyncEnable")
  self.updateTimeSyncEnable:setIsChecked(timeSyncEnable, self.isOpening)
  self.updateTimeSyncEnable:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)
  
  local serverOffset = g_fsgSettings.settings:getValue("serverOffset")
  self.updateTimeSyncServerOffset:setState(serverOffset)
  self.updateTimeSyncServerOffset:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local timeFixHour = g_fsgSettings.settings:getValue("timeFixHour")
  self.updateTimeSyncTimeFixHour:setState(timeFixHour)
  self.updateTimeSyncTimeFixHour:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local autoSetTime = g_fsgSettings.settings:getValue("autoSetTime")
  self.updateTimeSyncAutoSetTime:setIsChecked(autoSetTime, self.isOpening)
  self.updateTimeSyncAutoSetTime:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local progressNoti = g_fsgSettings.settings:getValue("progressNoti")
  self.updateTimeSyncProgressNotification:setIsChecked(progressNoti, self.isOpening)
  self.updateTimeSyncProgressNotification:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

end

function FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable(state)
  rcDebug("FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable")
  g_fsgSettings.settings:setValue(
    "timeSyncEnable",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncEnable: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "timeSyncEnable", state)
  end
end

function FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset(state)
  rcDebug("FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset")
  g_fsgSettings.settings:setValue("serverOffset",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncServerOffset: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(3, "serverOffset", state)
  end
end

function FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour(state)
  rcDebug("FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour")
  g_fsgSettings.settings:setValue("timeFixHour",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncTimeFixHour: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(3, "timeFixHour", state)
  end
end

function FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime(state)
  rcDebug("FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime")
  g_fsgSettings.settings:setValue(
    "autoSetTime",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncAutoSetTime: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "autoSetTime", state)
  end
end

function FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification(state)
  rcDebug("FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification")
  g_fsgSettings.settings:setValue(
    "progressNoti",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiTimeSyncFrame:onClickUpdateTimeSyncProgressNotification: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "progressNoti", state)
  end
end