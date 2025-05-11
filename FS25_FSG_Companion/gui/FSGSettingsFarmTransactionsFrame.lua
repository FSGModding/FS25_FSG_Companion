--
-- FSG Settings - Settings Page
--

FSGSettingsFarmTransactionsFrame = {}

local FSGSettingsFarmTransactionsFrame_mt = Class(FSGSettingsFarmTransactionsFrame, TabbedMenuFrameElement)

function FSGSettingsFarmTransactionsFrame:new(subclass_mt, l10n)
    local self = FSGSettingsFarmTransactionsFrame:superClass().new(nil, subclass_mt or FSGSettingsFarmTransactionsFrame_mt)

    rcDebug("FSGSettingsFarmTransactionsFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer
    self.transactions = {}

    return self
end

function FSGSettingsFarmTransactionsFrame:copyAttributes(src)
    FSGSettingsFarmTransactionsFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end


function FSGSettingsFarmTransactionsFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end


function FSGSettingsFarmTransactionsFrame:onGuiSetupFinished()
    FSGSettingsFarmTransactionsFrame:superClass().onGuiSetupFinished(self)

end


function FSGSettingsFarmTransactionsFrame:delete()
    FSGSettingsFarmTransactionsFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end


function FSGSettingsFarmTransactionsFrame:updateMenuButtons()


    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end


function FSGSettingsFarmTransactionsFrame:onFrameOpen()
    FSGSettingsFarmTransactionsFrame:superClass().onFrameOpen(self)

    rcDebug("FSGSettingsFarmTransactionsFrame:onFrameOpen")

    self:rebuildTable()

end


function FSGSettingsFarmTransactionsFrame:onRefreshEvent()

end


function FSGSettingsFarmTransactionsFrame:onFrameClose()
    FSGSettingsFarmTransactionsFrame:superClass().onFrameClose(self)

    self.transactions = {}

    self.messageCenter:unsubscribeAll(self)
end

function FSGSettingsFarmTransactionsFrame:rebuildTable()

    rcDebug("FSGSettingsFarmTransactionsFrame:rebuildTable")

    self.transactions = {}

    -- Load all transactions for this server
    -- Sort out all of the ones for the current user's farm
    
    local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
    local modSettingsFile = modSettingsFolderPath .. "/MoneyTransactions.xml"

    local xmlFile

    -- Load if it exists, otherwise create new
    if fileExists(modSettingsFile) then
        xmlFile = loadXMLFile("transactions", modSettingsFile)
    

        -- Get transactions
        xmlFile:iterate("transactions", function (_, transactionKey)
          local transactionData = {
            timestamp =       xmlFile:getString(transactionKey .. "#timestamp"),
            amount =          xmlFile:getXMLFloat(transactionKey .. "#amount"),
            farmId =          xmlFile:getXMLInt(transactionKey .. "#farmId"),
            moneyTypeTitle =  xmlFile:getString(transactionKey .. "#moneyTypeTitle"),
            moneyTypeStat =   xmlFile:getString(transactionKey .. "#moneyTypeStat"),
          }
          table.insert(self.transactions, transactionData)
        end)

    end

    rcDebug("Transactions")
    rcDebug(self.transactions)

    if self.transactions ~= nil and #self.transactions > 0 then
        self.transactionsList:reloadData()
    else
        -- Farm does not have any transactions.
        self.transactionsList:setVisible(false)
        -- Show Empty Info
        self.mainBoxEmpty:setVisible(true)
    end
    self:updateView()

end

function FSGSettingsFarmTransactionsFrame:updateView()
    rcDebug("FSGSettingsFarmTransactionsFrame:updateView")

    self.transactionsList:reloadData()
    self:updateMenuButtons()
end

function FSGSettingsFarmTransactionsFrame:getNumberOfItemsInSection(list, section)
    local selectedIndex = self.transactionsList:getSelectedIndexInSection()

    if selectedIndex ~= nil then
        if list == self.transactionsList and self.transactionsList ~= nil then
            return #self.transactions
        end
    end
    return 0
end