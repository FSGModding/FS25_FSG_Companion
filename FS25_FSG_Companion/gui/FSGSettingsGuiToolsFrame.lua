--
-- FSG Settings - Settings Page
--

FSGSettingsGuiToolsFrame = {}

local FSGSettingsGuiToolsFrame_mt = Class(FSGSettingsGuiToolsFrame, TabbedMenuFrameElement)

function FSGSettingsGuiToolsFrame:new(subclass_mt, l10n)
    local self = FSGSettingsGuiToolsFrame:superClass().new(nil, subclass_mt or FSGSettingsGuiToolsFrame_mt)

    rcDebug("FSGSettingsGuiToolsFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end


function FSGSettingsGuiToolsFrame:copyAttributes(src)
    FSGSettingsGuiToolsFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function FSGSettingsGuiToolsFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function FSGSettingsGuiToolsFrame:onGuiSetupFinished()
    FSGSettingsGuiToolsFrame:superClass().onGuiSetupFinished(self)

end


function FSGSettingsGuiToolsFrame:delete()
    FSGSettingsGuiToolsFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function FSGSettingsGuiToolsFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function FSGSettingsGuiToolsFrame:onFrameOpen()
    FSGSettingsGuiToolsFrame:superClass().onFrameOpen(self)

    rcDebug("FSGSettingsGuiToolsFrame:onFrameOpen")

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
      if tableRow.name == "sectionHeader" then
        set = true
      elseif tableRow:getIsVisible() then
        local color = InGameMenuSettingsFrame.COLOR_ALTERNATING[set]
        tableRow:setImageColor(nil, unpack(color))
        set = not set
      end
    end

end


function FSGSettingsGuiToolsFrame:onRefreshEvent()

end


function FSGSettingsGuiToolsFrame:onFrameClose()
    FSGSettingsGuiToolsFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end

function FSGSettingsGuiToolsFrame:onClickUpdatePaintAnywhere(state)
  rcDebug("FSGSettingsGuiToolsFrame:onClickUpdatePaintAnywhere")
  g_fsgSettings.settings:setValue(
    "paintAnywhere",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiToolsFrame:onClickUpdatePaintAnywhere: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "paintAnywhere", state)
  end
end

function FSGSettingsGuiToolsFrame:updateSettings()
  rcDebug("FSGSettingsGuiToolsFrame:updateSettings")

  local paintAnywhere = g_fsgSettings.settings:getValue("paintAnywhere")

  self.updatePaintAnywhere:setIsChecked(paintAnywhere, self.isOpening)

  self.updatePaintAnywhere:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

end
