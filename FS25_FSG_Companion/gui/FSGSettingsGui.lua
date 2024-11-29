--
-- AdvancedFarmManager - GUI Layout
--

FSGSettingsGui = {}

local FSGSettingsGui_mt = Class(FSGSettingsGui, TabbedMenu)

function FSGSettingsGui:new(messageCenter, l18n, inputManager)
    local self = TabbedMenu.new(nil, FSGSettingsGui_mt, messageCenter, l18n, inputManager)

    rcDebug("FSGSettingsGui-new")

    self.messageCenter = messageCenter
    self.l18n          = l18n
    self.inputManager  = g_inputBinding

    return self
end

function FSGSettingsGui:onGuiSetupFinished()
    
    rcDebug("FSG-SG-onGuiSetupFinished")

    FSGSettingsGui:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self.pageFSGInfo:initialize()
    self.pageFSGTools:initialize()
    self.pageFSGSettings:initialize()
    self.pageFSGTimeSync:initialize()

    self:initData()

    self:setupPages(self)

    self:setupMenuButtonInfo(self)

end

function FSGSettingsGui:setupPages(gui)

    rcDebug("FSG-SG-setupPages")

    local pages = {
        {gui.pageFSGInfo,       'gui.icon_options_help2'},
        {gui.pageFSGTools,      'gui.icon_options_gameSettings2'},
        {gui.pageFSGSettings,   'gui.icon_options_generalSettings2'},
        {gui.pageFSGTimeSync,   'gui.icon_ingameMenu_calendar'},
    }

    for idx, thisPage in ipairs(pages) do
        local page, icon  = unpack(thisPage)

        gui:registerPage(page, idx)

        gui:addPageTab(page, nil, nil, icon)

    end
    gui:rebuildTabList()

    rcDebug("FSG-SG-setupPages: after page loads")

end

function FSGSettingsGui:initData()
  rcDebug("FSGSettingsGui:initData")
end

function FSGSettingsGui:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback;

    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text        = g_i18n:getText("button_back"),
            callback    = onButtonBackFunction
        },
        {
            inputAction = InputAction.MENU_ACTIVATE,
            text        = g_i18n:getText("button_back"),
            callback    = onButtonBackFunction
        }
    }

    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK]     = self.defaultMenuButtonInfo[1]

    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function FSGSettingsGui:exitMenu()
    rcDebug("FSGSettingsGui:exitMenu")
    self:initData()
    self:changeScreen()
end
