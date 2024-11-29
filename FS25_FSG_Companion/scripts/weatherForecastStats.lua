rcDebug("WeatherForecastStats Class")

WeatherForecastStats = {}
local WeatherForecastStats_mt = Class(WeatherForecastStats)

function WeatherForecastStats.new(mission, i18n, modDirectory, modName)
  rcDebug("WeatherForecastStats-New")
  local self = setmetatable({}, WeatherForecastStats_mt)
  self.mission          = mission
  self.i18n             = i18n
  self.modDirectory     = modDirectory
  self.modName          = modName
  self.runCurrentHour   = 0
  self.forecast         = {}
  
  g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)

	return self
end

function WeatherForecastStats:onHourChanged(currentHour)
  -- rcDebug("WeatherForecastStats:onHourChanged")
  if g_server ~= nil then
    -- Make sure we only run once per hour
    if self.runCurrentHour ~= currentHour then
      WeatherForecastStats:updateWeather(currentHour)
      self.runCurrentHour = currentHour
    end
  end
end

function WeatherForecastStats:updateWeather(currentHour)
  rcDebug("WeatherForecastStats:updateWeather")

  local newxmlFile

	if g_currentMission ~= nil then
		self.forecast = g_currentMission.environment.weather.forecast
	end

  local forecastTable = {}

  rcDebug("Get Hourly Forecast")  
  for i = 1, 12 do
    local forecastInfo = self.forecast:getHourlyForecast(i)
    -- rcDebug(forecastInfo)
    local forecastInfoData = {
      format = "hourly",
      temp = forecastInfo.temperature,
      type = forecastInfo.forecastType,
      windSpeed = forecastInfo.windSpeed,
      windDirection = forecastInfo.windDirection,
      time = forecastInfo.time,
      day = forecastInfo.day
    }
    table.insert(forecastTable,forecastInfoData)
  end

  rcDebug("Get Daily Forecast")
  for i = 1, 8 do
    local forecastInfo = self.forecast:getDailyForecast(i)
    -- rcDebug(forecastInfo)
    local forecastInfoData = {
      format = "daily",
      lowTemp = forecastInfo.lowTemperature,
      highTemp = forecastInfo.highTemperature,
      type = forecastInfo.forecastType,
      windSpeed = forecastInfo.windSpeed,
      windDirection = forecastInfo.windDirection,
      day = forecastInfo.day
    }
    table.insert(forecastTable,forecastInfoData)
  end

  -- Save weather forecast to xml
	local modSettingsFolderPath = getUserProfileAppPath()  .. "modSettings/FS25_FSG_Companion"
	local weatherForecastFile = modSettingsFolderPath .. "/WeatherForecast.xml"

	local key = "forecast"

  --save data to xml file
  newxmlFile = XMLFile.create(key, weatherForecastFile, key)

  local index = 0

  for _, fc in pairs(forecastTable) do
    local subKey = string.format(".forecast(%d)", index)
    newxmlFile:setString(key .. subKey .. "#format", tostring(fc.format))
    newxmlFile:setString(key .. subKey .. "#type", tostring(fc.type))
    newxmlFile:setString(key .. subKey .. "#windSpeed", tostring(fc.windSpeed))
    newxmlFile:setString(key .. subKey .. "#windDirection", tostring(fc.windDirection))
    newxmlFile:setString(key .. subKey .. "#day", tostring(fc.day))
    -- These may be nil
    newxmlFile:setString(key .. subKey .. "#temp", tostring(fc.temp))
    newxmlFile:setString(key .. subKey .. "#time", tostring(fc.time))
    newxmlFile:setString(key .. subKey .. "#lowTemp", tostring(fc.lowTemp))
    newxmlFile:setString(key .. subKey .. "#highTemp", tostring(fc.highTemp))
    index = index + 1
  end

  newxmlFile:save()
  newxmlFile:delete()   

end