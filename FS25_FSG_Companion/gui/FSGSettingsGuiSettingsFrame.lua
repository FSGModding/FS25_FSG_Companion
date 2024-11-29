--
-- FSG Settings - Settings Page
--

FSGSettingsGuiSettingsFrame = {}

local FSGSettingsGuiSettingsFrame_mt = Class(FSGSettingsGuiSettingsFrame, TabbedMenuFrameElement)

function FSGSettingsGuiSettingsFrame:new(subclass_mt, l10n)
    local self = FSGSettingsGuiSettingsFrame:superClass().new(nil, subclass_mt or FSGSettingsGuiSettingsFrame_mt)

    rcDebug("FSGSettingsGuiSettingsFrame-new")

    self.messageCenter      = g_messageCenter
    self.l10n               = l10n
    self.isMPGame           = g_currentMission.missionDynamicInfo.isMultiplayer

    return self
end

function FSGSettingsGuiSettingsFrame:copyAttributes(src)
    FSGSettingsGuiSettingsFrame:superClass().copyAttributes(self, src)

    self.ui   = src.ui
    self.l10n = src.l10n
end

function FSGSettingsGuiSettingsFrame:initialize()
    self.backButtonInfo = {inputAction = InputAction.MENU_BACK}
end

function FSGSettingsGuiSettingsFrame:onGuiSetupFinished()
    FSGSettingsGuiSettingsFrame:superClass().onGuiSetupFinished(self)

end

function FSGSettingsGuiSettingsFrame:delete()
    FSGSettingsGuiSettingsFrame:superClass().delete(self)
    self.messageCenter:unsubscribeAll(self)
end

function FSGSettingsGuiSettingsFrame:updateMenuButtons()
    self.menuButtonInfo = {}
    self.menuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK
        }
    }

    self:setMenuButtonInfoDirty()
end

function FSGSettingsGuiSettingsFrame:onFrameOpen()
    FSGSettingsGuiSettingsFrame:superClass().onFrameOpen(self)

    rcDebug("FSGSettingsGuiSettingsFrame:onFrameOpen")

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

function FSGSettingsGuiSettingsFrame:onRefreshEvent()
  -- do nothing for now
end


function FSGSettingsGuiSettingsFrame:onFrameClose()
    FSGSettingsGuiSettingsFrame:superClass().onFrameClose(self)

    self.messageCenter:unsubscribeAll(self)
end

-- Update all of the settings
function FSGSettingsGuiSettingsFrame:updateSettings()
  rcDebug("FSGSettingsGuiSettingsFrame:updateSettings")

  local dismissWorkers = g_fsgSettings.settings:getValue("dismissWorkers")
  self.updateDismissWorkers:setIsChecked(dismissWorkers, self.isOpening)
  self.updateDismissWorkers:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local inboxActive = g_fsgSettings.settings:getValue("inboxActive")
  self.updateInboxActive:setIsChecked(inboxActive, self.isOpening)
  self.updateInboxActive:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local hireLimit = g_fsgSettings.settings:getValue("hireLimit")
  self.updateHireLimit:setState(hireLimit)
  self.updateHireLimit:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local maxMissions = g_fsgSettings.settings:getValue("maxMissions")
  self.updateMaxMissions:setState(maxMissions)
  self.updateMaxMissions:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local husbandryLimit = g_fsgSettings.settings:getValue("husbandryLimit")
  self.updateHusbandryLimit:setState(husbandryLimit)
  self.updateHusbandryLimit:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local productionPoints = g_fsgSettings.settings:getValue("productionPoints")
  self.updateProductionPoints:setState(productionPoints)
  self.updateProductionPoints:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local sellingPoints = g_fsgSettings.settings:getValue("sellingPoints")
  self.updateSellingPoints:setState(sellingPoints)
  self.updateSellingPoints:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local farmHouses = g_fsgSettings.settings:getValue("farmHouses")
  self.updateFarmHouses:setState(farmHouses)
  self.updateFarmHouses:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local generators = g_fsgSettings.settings:getValue("generators")
  self.updateGenerators:setState(generators)
  self.updateGenerators:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local gardenSheds = g_fsgSettings.settings:getValue("gardenSheds")
  self.updateGardenSheds:setState(gardenSheds)
  self.updateGardenSheds:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local floodLighting = g_fsgSettings.settings:getValue("floodLighting")
  self.updateFloodLighting:setState(floodLighting)
  self.updateFloodLighting:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local otherPlaceables = g_fsgSettings.settings:getValue("otherPlaceables")
  self.updateOtherPlaceables:setState(otherPlaceables)
  self.updateOtherPlaceables:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local transactionId = g_fsgSettings.settings:getValue("transactionId")
  self.updateTransactionId:setText(tostring(transactionId))
  self.updateTransactionId:setDisabled(true) -- for display only

  local coopLimitsEnabled = g_fsgSettings.settings:getValue("coopLimitsEnabled")
  self.updateCoopLimitsEnabled:setIsChecked(coopLimitsEnabled, self.isOpening)
  self.updateCoopLimitsEnabled:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local coopMinCruiseSpeed = g_fsgSettings.settings:getValue("coopMinCruiseSpeed")
  self.updateCoopMinCruiseSpeed:setState(coopMinCruiseSpeed)
  self.updateCoopMinCruiseSpeed:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local coopMinCruiseMin = g_fsgSettings.settings:getValue("coopMinCruiseMin")
  self.updateCoopMinCruiseMin:setState(coopMinCruiseMin)
  self.updateCoopMinCruiseMin:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

  local disableSleep = g_fsgSettings.settings:getValue("disableSleep")
  self.updateDisableSleep:setIsChecked(disableSleep, self.isOpening)
  self.updateDisableSleep:setDisabled(not g_currentMission:getIsServer() and not g_currentMission.isMasterUser)

end

-- Update Functions to update settings changes

function FSGSettingsGuiSettingsFrame:onClickUpdateDismissWorkers(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateDismissWorkers")
  g_fsgSettings.settings:setValue(
    "dismissWorkers",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateDismissWorkers: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "dismissWorkers", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateInboxActive(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateInboxActive")
  g_fsgSettings.settings:setValue(
    "inboxActive",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateInboxActive: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "inboxActive", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateHireLimit(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateHireLimit")
  g_fsgSettings.settings:setValue("hireLimit",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateHireLimit: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "hireLimit", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateMaxMissions(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateMaxMissions")
  g_fsgSettings.settings:setValue("maxMissions",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateMaxMissions: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "maxMissions", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateHusbandryLimit(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateHusbandryLimit")
  g_fsgSettings.settings:setValue("husbandryLimit",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateHusbandryLimit: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "husbandryLimit", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateProductionPoints(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateProductionPoints")
  g_fsgSettings.settings:setValue("productionPoints",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateProductionPoints: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "productionPoints", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateSellingPoints(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateSellingPoints")
  g_fsgSettings.settings:setValue("sellingPoints",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateSellingPoints: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "sellingPoints", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateFarmHouses(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateFarmHouses")
  g_fsgSettings.settings:setValue("farmHouses",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateFarmHouses: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "farmHouses", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateGenerators(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateGenerators")
  g_fsgSettings.settings:setValue("generators",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateGenerators: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "generators", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateGardenSheds(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateGardenSheds")
  g_fsgSettings.settings:setValue("gardenSheds",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateGardenSheds: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "gardenSheds", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateFloodLighting(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateFloodLighting")
  g_fsgSettings.settings:setValue("floodLighting",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateFloodLighting: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "floodLighting", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateOtherPlaceables(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateOtherPlaceables")
  g_fsgSettings.settings:setValue("otherPlaceables",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateOtherPlaceables: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "otherPlaceables", state)
  end
end

function FSGSettingsGuiSettingsFrame:onEnterPressedUpdateTransactionId()
end

function FSGSettingsGuiSettingsFrame:onClickUpdateCoopLimitsEnabled(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateCoopLimitsEnabled")
  g_fsgSettings.settings:setValue(
    "coopLimitsEnabled",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateCoopLimitsEnabled: ')
    rcDebug(state)

    FCSettingEvent.sendEvent(2, "coopLimitsEnabled", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseSpeed(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseSpeed")
  g_fsgSettings.settings:setValue("coopMinCruiseSpeed",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseSpeed: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "coopMinCruiseSpeed", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseMin(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseMin")
  g_fsgSettings.settings:setValue("coopMinCruiseMin",state)
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateCoopMinCruiseMin: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(3, "coopMinCruiseMin", state)
  end
end

function FSGSettingsGuiSettingsFrame:onClickUpdateDisableSleep(state)
  rcDebug("FSGSettingsGuiSettingsFrame:onClickUpdateDisableSleep")
  g_fsgSettings.settings:setValue(
    "disableSleep",
    state == CheckedOptionElement.STATE_CHECKED
  )
  g_fsgSettings.settings:saveSettings()
  if not self.isServer then
    -- Send setting data to the server
    if state == 1 then state = false else state = true end
    rcDebug('FSGSettingsGuiSettingsFrame:onClickUpdateDisableSleep: ')
    rcDebug(state)
    FCSettingEvent.sendEvent(2, "disableSleep", state)
  end
end
