InfoMessages = {}

local infoMessages = Class(InfoMessages, HUDDisplay)

function InfoMessages.new()
	
  rcDebug("InfoMessages - new")

	local self = InfoMessages:superClass().new(infoMessages)

  self.displayMessage         = 1
  self.serverMin              = 0

  -- Messagess to diplay in rotation on bottom left of screen
  self.messages = {
    "Welcome to Farm Sim Game Realism Servers",
    "Powered By Fragnet.net/FSG",
    "Powered By FSGRealism.com",
    "Thank you for playing on FSG Realism"
  }

  -- Setup the background
  local colorBackground = HUD.COLOR.BACKGROUND
  local r, g, b, a = unpack(colorBackground)
  self.bgScale = g_overlayManager:createOverlay("gui.gameInfo_middle", 0, 0, 0, 0)
  self.bgScale:setColor(r, g, b, a)
  self.bgLeft = g_overlayManager:createOverlay("gui.gameInfo_left", 0, 0, 0, 0)
  self.bgLeft:setColor(r, g, b, a)
  self.bgRight = g_overlayManager:createOverlay("gui.gameInfo_right", 0, 0, 0, 0)
  self.bgRight:setColor(r, g, b, a)
  self.icons = {}

  return self

end

-- Removes the info message
function InfoMessages.delete()

  rcDebug("InfoMessages - delete")

	self.bgLeft:delete()
	self.bgScale:delete()
	self.bgRight:delete()
end

-- Draws the info message
function InfoMessages.draw(self)
	InfoMessages:superClass().draw(self)

  -- No need to render on a server
  if not g_client then
    return
  end 

  -- If the hud is hidden, don't show messages
  if g_noHudModeEnabled or not g_currentMission.hud.isVisible then
    return
  end

	-- Check to see which message to display
	local currentMin = g_currentMission.environment.currentMinute

	if currentMin ~= self.serverMin then
		self.displayMessage = self.displayMessage + 1

		if self.displayMessage > #self.messages then
			self.displayMessage = 1
		end

		self.serverMin = currentMin
	end

	-- Make sure text is enabled
	local text = self.messages[self.displayMessage]

	-- If no text then don't draw duh
	if text == nil or text == "" then
		return
	end

	-- Text properties
	local textSize = 0.015
	local textWidth = getTextWidth(textSize, text)

	-- Set background dimensions dynamically based on text width
	local padding = 0.005 -- Add some padding around the text
	local bgWidth = (textWidth + padding * 2)
	local bgHeight = 0.02 -- Fixed height for the background

	-- Set location and render the background
	local posX, posY = self:findOrigin()
	local bgPosX = posX - bgWidth * 0.5
	local bgPosY = posY - bgHeight * 0.5 -- Center vertically around text

	self.bgScale:setDimension(bgWidth, bgHeight)
	self.bgScale:setPosition(bgPosX, bgPosY)
	self.bgScale:render()

	-- Render left and right parts of the background (optional)
	self.bgLeft:setDimension(padding, bgHeight)
	self.bgLeft:setPosition(bgPosX - padding, bgPosY)
	self.bgLeft:render()

	self.bgRight:setDimension(padding, bgHeight)
	self.bgRight:setPosition(bgPosX + bgWidth, bgPosY)
	self.bgRight:render()

	-- Render the text at the center of the background
	local textPosX = posX - textWidth * 0.5
	local textPosY = (posY - textSize * 0.5) + 0.002 -- Adjust to center vertically

	-- Store the color in a local for faster access
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)

	-- Render the text
	renderText(textPosX, textPosY, textSize, text)

	-- Reset text rendering properties
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)

	self:setScale(g_currentMission.hud.topNotification.uiScale)
	self:setVisible(g_currentMission.hud.isVisible)
end


-- Sets the location of the info message display
function InfoMessages:findOrigin()
	local tmpX = 0.50000
	local tmpY = 0.02000

	return tmpX, tmpY
end

