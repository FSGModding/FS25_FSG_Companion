--
-- FSG Settings - Settings Page
--

FSGSettingsGuiInfoFrame = {}

local FSGSettingsGuiInfoFrame_mt = Class(FSGSettingsGuiInfoFrame, TabbedMenuFrameElement)

function FSGSettingsGuiInfoFrame:new(subclass_mt, l10n)
    local self = FSGSettingsGuiInfoFrame:superClass().new(nil, subclass_mt or FSGSettingsGuiInfoFrame_mt)

    rcDebug("FSGSettingsGuiInfoFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end

function FSGSettingsGuiInfoFrame:copyAttributes(src)
    FSGSettingsGuiInfoFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function FSGSettingsGuiInfoFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function FSGSettingsGuiInfoFrame:onGuiSetupFinished()
    FSGSettingsGuiInfoFrame:superClass().onGuiSetupFinished(self)

end


function FSGSettingsGuiInfoFrame:delete()
    FSGSettingsGuiInfoFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function FSGSettingsGuiInfoFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function FSGSettingsGuiInfoFrame:onFrameOpen()
    FSGSettingsGuiInfoFrame:superClass().onFrameOpen(self)

    rcDebug("FSGSettingsGuiInfoFrame:onFrameOpen")

end


function FSGSettingsGuiInfoFrame:onRefreshEvent()

end


function FSGSettingsGuiInfoFrame:onFrameClose()
    FSGSettingsGuiInfoFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end