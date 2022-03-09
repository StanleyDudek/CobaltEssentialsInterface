--CEI (CLIENT) by Dudekahedron, 2022

local M = {}

local logTag = "CEI"

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local windowOpen = im.BoolPtr(true)
local ffi = require('ffi')

local canTeleport

local includeForRace = false
local includeForRaceSent = false

local nametagWhitelisted = false
local nametagBlockerActive = false
local nametagBlockerTimeout

local originalMpLayout

local ignitionEnabled = {}
local isFrozen = {}
local playersCurrentVehicle = {}

local currentRole

local roles = {}
roles.owner = {}
roles.admin = {}
roles.mod = {}
roles.player = {}
roles.guest = {}
roles.spectator = {}

local self = {}

local players = {}

local config = {}
config.server = {}
config.server.nameInput = im.ArrayChar(128)
config.server.mapInput = im.ArrayChar(128)
config.server.descriptionInput = im.ArrayChar(256)
config.cobalt = {}
config.cobalt.newRCONport = im.ArrayChar(128)
config.cobalt.newRCONpassword = im.ArrayChar(128)
config.cobalt.newCobaltDBport = im.ArrayChar(128)
config.cobalt.newGroupInput = im.ArrayChar(128)
config.cobalt.whitelistNameInput = im.ArrayChar(128)
config.cobalt.groups = {}
config.cobalt.permissions = {}
config.cobalt.permissions.newLevelInput = im.ArrayChar(128)
config.cobalt.permissions.vehicleCaps = {}
config.cobalt.vehicles = {}
config.cobalt.vehicles.newVehicleInput = im.ArrayChar(128)
config.cobalt.vehicles.vehiclePerms = {}
config.cobalt.interface = {}
config.nametags = {}
config.nametags.settings = {}
config.nametags.whitelistNameInput = im.ArrayChar(128)

local stats = {}

local vehiclePermsFiltering = {}
vehiclePermsFiltering.filter = ffi.new('ImGuiTextFilter[1]')

local environment = {}
environment.useTempCurveSent = false

local defaultTempCurve
local defaultTempCurveSet = false

local envReportRate = 3
local lastEnvReport = 0
local firstReport = false
local envObjectIdCache = {}

local lastTeleport = 0

local worldReadyState = 0

local function rxNametagWhitelisted(data)
	if data == "false" then
		nametagWhitelisted = false
	elseif data == "true" then
		nametagWhitelisted = true
	end
end

local function rxNametagBlockerActive(data)
	if data == "false" then
		nametagBlockerActive = false
	elseif data == "true" then
		nametagBlockerActive = true
	end
end

local function rxNametagBlockerTimeout(data)
	if tonumber(data) == 0 then
		nametagBlockerTimeout = nil
	else
		nametagBlockerTimeout = tonumber(data)
	end
end

local function rxCEIstate(state)
	if state == "show" then
		windowOpen[0] = true
		gui.showWindow("CEI")
	elseif state == "hide" then
		windowOpen[0] = false
		gui.hideWindow("CEI")
	end
end

local function rxCEItp(tp)
	if tp == "true" then
		canTeleport = true
	elseif tp == "false" then
		canTeleport = false
	end
end

local function rxStats(data)

end

local function rxEnvironment(data)
	data = string.sub(data, 2)
	local envData = split(data,"$")
	environment.ToD = envData[1]
	environment.todVal = im.FloatPtr(tonumber(environment.ToD))
	environment.timePlay = envData[2]
	environment.dayScale = envData[3]
	environment.dayScaleVal = im.FloatPtr(tonumber(environment.dayScale))
	environment.nightScale = envData[4]
	environment.nightScaleVal = im.FloatPtr(tonumber(environment.nightScale))
	environment.azimuthOverride = envData[5]
	environment.azimuthOverrideVal = im.FloatPtr(tonumber(environment.azimuthOverride))
	environment.sunSize = envData[6]
	environment.sunSizeVal = im.FloatPtr(tonumber(environment.sunSize))
	environment.skyBrightness = envData[7]
	environment.skyBrightnessVal = im.FloatPtr(tonumber(environment.skyBrightness))
	environment.sunLightBrightness = envData[8]
	environment.sunLightBrightnessVal = im.FloatPtr(tonumber(environment.sunLightBrightness))
	environment.exposure = envData[9]
	environment.exposureVal = im.FloatPtr(tonumber(environment.exposure))
	environment.shadowDistance = envData[10]
	environment.shadowDistanceVal = im.FloatPtr(tonumber(environment.shadowDistance))
	environment.shadowSoftness = envData[11]
	environment.shadowSoftnessVal = im.FloatPtr(tonumber(environment.shadowSoftness))
	environment.shadowSplits = envData[12]
	environment.shadowSplitsInt = im.IntPtr(tonumber(environment.shadowSplits))
	environment.fogDensity = envData[13]
	environment.fogDensityVal = im.FloatPtr(tonumber(environment.fogDensity))
	environment.fogDensityOffset = envData[14]
	environment.fogDensityOffsetVal = im.FloatPtr(tonumber(environment.fogDensityOffset))
	environment.cloudCover = envData[15]
	environment.cloudCoverVal = im.FloatPtr(tonumber(environment.cloudCover))
	environment.cloudSpeed = envData[16]
	environment.cloudSpeedVal = im.FloatPtr(tonumber(environment.cloudSpeed))
	environment.rainDrops = envData[17]
	environment.rainDropsInt = im.IntPtr(tonumber(environment.rainDrops))
	environment.dropSize = envData[18]
	environment.dropSizeVal = im.FloatPtr(tonumber(environment.dropSize))
	environment.dropMinSpeed = envData[19]
	environment.dropMinSpeedVal = im.FloatPtr(tonumber(environment.dropMinSpeed))
	environment.dropMaxSpeed = envData[20]
	environment.dropMaxSpeedVal = im.FloatPtr(tonumber(environment.dropMaxSpeed))
	environment.precipType = envData[21]
	environment.teleportTimeout = envData[22]
	environment.teleportTimeoutInt = im.IntPtr(tonumber(environment.teleportTimeout))
	environment.simSpeed = envData[23]
	environment.simSpeedVal = im.FloatPtr(tonumber(environment.simSpeed))
	environment.gravity = envData[24]
	environment.gravityVal = im.FloatPtr(tonumber(environment.gravity))
	environment.tempCurveNoon = envData[25]
	environment.tempCurveNoonInt = im.IntPtr(tonumber(environment.tempCurveNoon))
	environment.tempCurveDusk = envData[26]
	environment.tempCurveDuskInt = im.IntPtr(tonumber(environment.tempCurveDusk))
	environment.tempCurveMidnight = envData[27]
	environment.tempCurveMidnightInt = im.IntPtr(tonumber(environment.tempCurveMidnight))
	environment.tempCurveDawn = envData[28]
	environment.tempCurveDawnInt = im.IntPtr(tonumber(environment.tempCurveDawn))
	environment.useTempCurve = envData[29]
	if environment.useTempCurve == "true" then
		environment.useTempCurveVal = true
	elseif environment.useTempCurve == "false" then
		environment.useTempCurveVal = false
	end
end

local function rxPreferences(data)

end

local function rxPlayerRole(data)
	currentRole = data
end

local function rxPlayersRoles(data)
	data = string.sub(data, 2)
	local tempData = split(data, "|")
	for k,v in pairs(tempData) do
		local rolesData = split(v, "_")
		local playerStatus = rolesData[1]
		local playerServerID = rolesData[2]
		local playerName = rolesData[3]
		if playerStatus == "owner" then
			roles.owner[playerServerID] = playerName
			roles.admin[playerServerID] = nil
			roles.mod[playerServerID] = nil
			roles.player[playerServerID] = nil
			roles.guest[playerServerID] = nil
			roles.spectator[playerServerID] = nil
		elseif playerStatus == "admin" then
			roles.owner[playerServerID] = nil
			roles.admin[playerServerID] = playerName
			roles.mod[playerServerID] = nil
			roles.player[playerServerID] = nil
			roles.guest[playerServerID] = nil
			roles.spectator[playerServerID] = nil
		elseif playerStatus == "mod" then
			roles.owner[playerServerID] = nil
			roles.admin[playerServerID] = nil
			roles.mod[playerServerID] = playerName
			roles.player[playerServerID] = nil
			roles.guest[playerServerID] = nil
			roles.spectator[playerServerID] = nil
		elseif playerStatus == "player" then
			roles.owner[playerServerID] = nil
			roles.admin[playerServerID] = nil
			roles.mod[playerServerID] = nil
			roles.player[playerServerID] = playerName
			roles.guest[playerServerID] = nil
			roles.spectator[playerServerID] = nil
		elseif playerStatus == "guest" then
			roles.owner[playerServerID] = nil
			roles.admin[playerServerID] = nil
			roles.mod[playerServerID] = nil
			roles.player[playerServerID] = nil
			roles.guest[playerServerID] = playerName
			roles.spectator[playerServerID] = nil
		elseif playerStatus == "spectator" then
			roles.owner[playerServerID] = nil
			roles.admin[playerServerID] = nil
			roles.mod[playerServerID] = nil
			roles.player[playerServerID] = nil
			roles.guest[playerServerID] = nil
			roles.spectator[playerServerID] = playerName
		end
	end
end

local function rxPlayerLeave(data)
	players[data] = nil
end

local function rxConfigData(data)
	data = string.sub(data, 2)
	local configData = split(data,"$")
	config.server.name = configData[1]
	config.server.debug = configData[2]
	config.server.private = configData[3]
	config.server.maxCars = configData[4]
	config.server.maxPlayers = configData[5]
	config.server.map = configData[6]
	config.server.description = configData[7]
	config.server.maxCarsInt = im.IntPtr(tonumber(config.server.maxCars))
	config.server.maxPlayersInt = im.IntPtr(tonumber(config.server.maxPlayers))
	config.cobalt.maxActivePlayers = configData[8]
	config.cobalt.enableWhitelist = configData[9]
	config.cobalt.enableColors = configData[10]
	config.cobalt.enableDebug = configData[11]
	config.cobalt.RCONenabled = configData[12]
	config.cobalt.RCONkeepAliveTick = configData[13]
	config.cobalt.RCONpassword = configData[14]
	config.cobalt.RCONport = configData[15]
	config.cobalt.CobaltDBport = configData[16]
	config.cobalt.maxActivePlayersInt = im.IntPtr(tonumber(config.cobalt.maxActivePlayers))
	local tempString = configData[17]
	local tempData = string.sub(tempString, 2)
	local tempGroups = split(tempData,"|")
	for k,v in pairs(tempGroups) do
		config.cobalt.groups[k] = {}
		config.cobalt.groups[k].groupPlayers = {}
		local nameCounter = 0
		local tempGroup = tempGroups[k]
		local tempGroupData = split(tempGroup,":")
		local tempGroupInfo = tempGroupData[2]
		local groupInfo = split(tempGroupInfo,"@")
		config.cobalt.groups[k].groupName = groupInfo[1]
		for x,y in pairs(groupInfo) do
			if string.find(y, "level") then
				local level = split(y, "_")
				config.cobalt.groups[k].groupLevel = level[2]
			end
			if string.find(y, "whitelisted") then
				local whitelisted = split(y, "_")
				config.cobalt.groups[k].groupWhitelisted = whitelisted[2]
			end
			if string.find(y, "muted") then
				local muted = split(y, "_")
				config.cobalt.groups[k].groupMuted = muted[2]
			end
			if string.find(y, "banned") then
				local banned = split(y, "_")
				config.cobalt.groups[k].groupBanned = banned[2]
			end
			if string.find(y, "banReason") then
				local banReason = split(y, "_")
				config.cobalt.groups[k].groupBanReason = banReason[2]
			end
			if string.find(y, "name") then
				nameCounter = nameCounter + 1
				local groupPlayerName = split(y, "_")
				config.cobalt.groups[k].groupPlayers[nameCounter] = groupPlayerName[2]
			end
		end
		config.cobalt.groups[k].groupLevelInt = im.IntPtr(tonumber(config.cobalt.groups[k].groupLevel)) or im.IntPtr(0)
		config.cobalt.groups[k].groupBanReasonInput = im.ArrayChar(128)
		config.cobalt.groups[k].newGroupPlayerInput = im.ArrayChar(128)
	end
	tempString = configData[18]
	tempData = string.sub(tempString, 2)
	local tempPermissions = split(tempData,"|")
	for k,v in pairs(tempPermissions) do
		local tempPermission = tempPermissions[k]
		local permissionData = split(tempPermission,"#")
		config.cobalt.permissions.vehicleCaps[k] = {}
		config.cobalt.permissions.vehicleCaps[k].level = permissionData[1]
		config.cobalt.permissions.vehicleCaps[k].vehicles = permissionData[2]
		config.cobalt.permissions.vehicleCaps[k].vehiclesInt = im.IntPtr(tonumber(config.cobalt.permissions.vehicleCaps[k].vehicles))
	end
	tempString = configData[19]
	tempData = string.sub(tempString, 2)
	local tempVehiclePerms = split(tempData,"|")
	for k,v in pairs(tempVehiclePerms) do
		local tempVehiclePerm = tempVehiclePerms[k]
		local tempVehiclePermData = split(tempVehiclePerm,",")
		config.cobalt.vehicles.vehiclePerms[k] = {}
		local vehiclePermData = split(tempVehiclePermData[1],"#")
		config.cobalt.vehicles.vehiclePerms[k].name = vehiclePermData[1]
		config.cobalt.vehicles.vehiclePerms[k].nameInput = im.ArrayChar(128)
		config.cobalt.vehicles.vehiclePerms[k].level = vehiclePermData[2]
		config.cobalt.vehicles.vehiclePerms[k].levelInt = im.IntPtr(tonumber(config.cobalt.vehicles.vehiclePerms[k].level))
		config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput = im.ArrayChar(128)
		if tempVehiclePermData[2] then
			local tempVehiclePartLevel = split(tempVehiclePermData[2], "@")
			config.cobalt.vehicles.vehiclePerms[k].partLevel = {}
			config.cobalt.vehicles.vehiclePerms[k].partLevel.name = tempVehiclePartLevel[1]
			config.cobalt.vehicles.vehiclePerms[k].partLevel.level = tempVehiclePartLevel[2]
			config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt = im.IntPtr(tonumber(config.cobalt.vehicles.vehiclePerms[k].partLevel.level))
		end
	end
	
	local tempFilterTable = {}
	for k,v in pairs(config.cobalt.vehicles.vehiclePerms) do
		tempFilterTable[k] = config.cobalt.vehicles.vehiclePerms[k].name
	end
	
	vehiclePermsFiltering.lines = im.ArrayCharPtrByTbl(tempFilterTable)
	
	config.cobalt.interface.defaultState = configData[20]
	
	config.nametags.settings.blockingEnabled = configData[21]
	config.nametags.settings.blockingTimeout = configData[22]
	config.nametags.settings.blockingTimeoutInt = im.IntPtr(tonumber(config.nametags.settings.blockingTimeout))
	
	if configData[23] then
		config.nametags.whitelistedPlayers = {}
		tempString = configData[23]
		tempData = string.sub(tempString, 2)
		local tempNametagsWhitelistPlayers = split(tempData,"|")
		for k,v in pairs(tempNametagsWhitelistPlayers) do
			local tempNametagsWhitelistPlayer = tempNametagsWhitelistPlayers[k]
			config.nametags.whitelistedPlayers[k] = {}
			config.nametags.whitelistedPlayers[k].name = tempNametagsWhitelistPlayer
		end
	end
	
	if configData[24] then
	config.cobalt.whitelistedPlayers = {}
	tempString = configData[24]
	tempData = string.sub(tempString, 2)
	local tempWhitelistPlayers = split(tempData,"|")
		for k,v in pairs(tempWhitelistPlayers) do
			local tempWhitelistPlayer = tempWhitelistPlayers[k]
			config.cobalt.whitelistedPlayers[k] = {}
			config.cobalt.whitelistedPlayers[k].name = tempWhitelistPlayer
		end
	end
	
end

local function rxPlayerAuth(player_name)

end

local function rxPlayerConnecting(player_id)

end

local function rxPlayersData(data)
	data = string.sub(data, 2)
	local playersData = split(data,"|")
	for index, value in pairs(playersData) do
		local tempData = split(value,",")
		local tempPlayerID = tempData[1]
		players[tempPlayerID] = {}
		players[tempPlayerID].player = {}
		players[tempPlayerID].player.playerID = tempData[1]
		players[tempPlayerID].player.playerName = tempData[2]
		players[tempPlayerID].player.connectStage = tempData[3]
		players[tempPlayerID].player.guest = tempData[4]
		players[tempPlayerID].player.joinTime = tempData[5]
		players[tempPlayerID].player.connectedTime = tempData[16]
		players[tempPlayerID].player.kickBanMuteReason = im.ArrayChar(128)
		players[tempPlayerID].player.tempBanLength = im.FloatPtr(tonumber(tempData[18]))
		players[tempPlayerID].player.vehDeleteReason = im.ArrayChar(128)
		players[tempPlayerID].player.gamemode = {}
		players[tempPlayerID].player.gamemode.mode = tempData[6]
		players[tempPlayerID].player.gamemode.source = tempData[7]
		players[tempPlayerID].player.gamemode.queue = tempData[8]
		players[tempPlayerID].player.gamemode.locked = tempData[9]
		players[tempPlayerID].player.permissions = {}
		players[tempPlayerID].player.permissions.whitelisted = tempData[10]
		players[tempPlayerID].player.permissions.muted = tempData[11]
		players[tempPlayerID].player.teleport = tempData[12]
		players[tempPlayerID].player.permissions.level = tempData[13]
		players[tempPlayerID].player.permissions.levelInt = im.IntPtr(tonumber(tempData[19]))
		players[tempPlayerID].player.permissions.banned = tempData[14]
		players[tempPlayerID].player.permissions.group = tempData[15]
		players[tempPlayerID].player.permissions.muteReason = tempData[17]
		players[tempPlayerID].player.permissions.groupInput = im.ArrayChar(128)
		players[tempPlayerID].player.includeInRace = tempData[20]
		if tempData[22] then
			players[tempPlayerID].player.vehicles = {}
			if tempData[21] == "none" then
				playersCurrentVehicle[tempPlayerID] = nil
			else
				playersCurrentVehicle[tempPlayerID] = tempData[21]
			end
			local vehString = string.sub(tempData[22], 2)
			local vehiclesData = split(vehString,"$")
			for i,v in pairs(vehiclesData) do
				local tempVehicleData = split(v,"_")
				local tempVehicleID = tempVehicleData[1]
				local tempVehicleName = tempVehicleData[2]
				players[tempPlayerID].player.vehicles[tempVehicleID] = {}
				players[tempPlayerID].player.vehicles[tempVehicleID].vehicleID = tempVehicleID
				players[tempPlayerID].player.vehicles[tempVehicleID].genericName = tempVehicleName
			end
		end
	end
end

local function drawCEOI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Owner Interface")
	
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.5, 0.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.6, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.4, 0.0, 0.999))
			if im.SmallButton("Race Countdown!") then
				for k,v in pairs(players) do
					if players[k].player.includeInRace == "true" then
						for x,y in pairs(players[k].player.vehicles) do
							TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
							log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						end
					end
				end
				
				TriggerServerEvent("CEIPreRace", "true")
				log('W', logTag, "CEIPreRace Called: true")
				
			end
			im.PopStyleColor(3)
			
			
			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]
			
			
			im.Separator()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.2, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.0, 0.0, 0.999))
			if im.SmallButton("Remote Stop All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Freeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.1, 1.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.2, 1.0, 0.2, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.0, 0.9, 0.0, 0.999))
			if im.SmallButton("Remote Start All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Unfreeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.Separator()
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("Ban##"..tostring(k)) then
						TriggerServerEvent("CEIBan",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIBan Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("TempBan##"..tostring(k)) then
						TriggerServerEvent("CEITempBan",tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEITempBan Called: " .. tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							
							im.SameLine()
							if im.SmallButton("Teleport From##" .. tostring(k)) then
								M.teleportPlayerToVeh(players[k].player.playerName,tostring(k))
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport this player's current vehicle to you.")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Reason:")
					im.SameLine()
					if im.InputTextWithHint("##"..tostring(k), "Kick or (temp)Ban or Mute Reason", players[k].player.kickBanMuteReason, 128) then
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("tempBan:")
					im.SameLine()
					im.PushItemWidth(120)
					if im.InputFloat("##tempBanLength"..tostring(k), players[k].player.tempBanLength, 0.001, 1) then
						if players[k].player.tempBanLength[0] < 0.001 then
							players[k].player.tempBanLength = im.FloatPtr(0.001)
						elseif players[k].player.tempBanLength[0] > 3650 then
							players[k].player.tempBanLength = im.FloatPtr(3650)
						end
						TriggerServerEvent("CEISetTempBan", tostring(k) .. "|" .. tostring(players[k].player.tempBanLength[0]))
						log('W', logTag, "CEISetTempBan Called: " .. tostring(k) .. "|" .. tostring(players[k].player.tempBanLength[0]))
					end
					im.SameLine()
					im.Text("days = " .. tostring(M.round(players[k].player.tempBanLength[0] * 1440,2)) .. " minutes")
					im.PopItemWidth()
					
					if vehiclesCounter > 0 then
						im.Separator()

						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							
							im.Text("		")
							im.SameLine()
							im.Text("Reason:")
							im.SameLine()
							if im.InputTextWithHint("##vehReason"..tostring(k), "Vehicle Delete Reason", players[k].player.vehDeleteReason, 128) then
							end
							
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
								for i,j in pairs(ignitionEnabled) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "true" then
											im.SameLine()
											if im.SmallButton("Remote Stop##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										elseif j == "false" then
											im.SameLine()
											if im.SmallButton("Remote Start##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										end
									end
								end
								
								for i,j in pairs(isFrozen) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "false" then
											im.SameLine()
											if im.SmallButton("Freeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										elseif j == "true" then
											im.SameLine()
											if im.SmallButton("Unfreeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										end
									end
								end
								
								im.SameLine()
								if im.SmallButton("Delete##"..tostring(x)) then
									TriggerServerEvent("CEIRemoveVehicle", tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
									log('W', logTag, "CEIRemoveVehicle Called: " .. tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
								end
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
					end
					im.Separator()
					if im.TreeNode1("info##"..tostring(k)) then
						im.Text("		playerID: " .. players[k].player.playerID)
						im.Text("		connectStage: " .. players[k].player.connectStage)
						im.Text("		guest: " .. players[k].player.guest)
						im.Text("		joinTime: " .. players[k].player.joinTime)
						im.SameLine()
						im.Text(": connectedTime: " .. players[k].player.connectedTime)
						
						im.Separator()
						if im.TreeNode1("permissions##"..tostring(k)) then
						
							if players[k].player.teleport == "false" then
								if im.SmallButton("Allow Teleport##"..tostring(k)) then
									TriggerServerEvent("CEISetTeleportPerm", tostring(k) .. "|true")
									log('W', logTag, "CEISetTeleportPerm Called: " .. tostring(k) .. "|true")
								end
							elseif players[k].player.teleport == "true" then
								if im.SmallButton("Revoke Teleport##"..tostring(k)) then
									TriggerServerEvent("CEISetTeleportPerm", tostring(k) .. "|false")
									log('W', logTag, "CEISetTeleportPerm Called: " .. tostring(k) .. "|false")
								end
							end
						
							if im.TreeNode1("level:") then
								im.SameLine()
								im.Text(players[k].player.permissions.level)
								im.Text("		")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", players[k].player.permissions.levelInt, 1) then
									TriggerServerEvent("CEISetTempPerm", tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
									log('W', logTag, "CEISetTempPerm Called: " .. tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
								end
								im.PopItemWidth()
								im.SameLine()
								if im.Button("Apply##level"..tostring(x)) then
									TriggerServerEvent("CEISetPerm", tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
									log('W', logTag, "CEISetPerm Called: " .. tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
								end
								im.TreePop()
							else
								im.SameLine()
								im.Text(players[k].player.permissions.level)
							end
							im.Text("		whitelisted: " .. players[k].player.permissions.whitelisted)
							im.Text("		muted: " .. players[k].player.permissions.muted)
							im.Text("		muteReason: " .. players[k].player.permissions.muteReason)
							im.Text("		banned: " .. players[k].player.permissions.banned)
							if im.TreeNode1("group:##"..tostring(k)) then
								im.SameLine()
								im.Text(players[k].player.permissions.group)
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##newGroup", "Group Name", players[k].player.permissions.groupInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
								end
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
								if im.SmallButton("Remove##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|none")
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|none")
								end
								im.PopStyleColor(3)
								im.SameLine()
								im.ShowHelpMarker("Remove group or enter new Group Name and press Apply")
								im.TreePop()
							else
								im.SameLine()
								im.Text(players[k].player.permissions.group)
							end
							im.TreePop()
						end
						im.Separator()
						if im.TreeNode1("gamemode##"..tostring(k)) then
							im.Text("		mode: " .. players[k].player.gamemode.mode)
							im.Text("		source: " .. players[k].player.gamemode.source)
							im.Text("		queue: " .. players[k].player.gamemode.queue)
							im.Text("		locked: " .. players[k].player.gamemode.locked)
							im.TreePop()
						end
						im.TreePop()
					end
					im.Unindent()
				else
					im.PopStyleColor(3)
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("Ban##"..tostring(k)) then
						TriggerServerEvent("CEIBan",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIBan Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("TempBan##"..tostring(k)) then
						TriggerServerEvent("CEITempBan",tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEITempBan Called: " .. tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							
							im.SameLine()
							if im.SmallButton("Teleport From##" .. tostring(k)) then
								M.teleportPlayerToVeh(players[k].player.playerName,tostring(k))
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport this player's current vehicle to you.")
						end
					end
					
					im.Unindent()
					
				end
			end
			im.EndTabItem()
		end
----------------------------------------------------------------------------------CONFIG TAB
		if im.BeginTabItem("Config") then
----------------------------------------------------------------------------------COBALT HEADER
			if im.CollapsingHeader1("Cobalt Essentials") then
				im.Indent()
			
				local vehiclePerms = config.cobalt.vehicles.vehiclePerms
				local vehiclePermsCounter = 0
				for a,b in pairs(vehiclePerms) do
					vehiclePermsCounter = vehiclePermsCounter + 1
				end
				
				if im.TreeNode1("vehiclePerms:") then
					im.SameLine()
					im.Text(tostring(vehiclePermsCounter))
					
					
					im.Text("	Add vehicle: ")
					im.SameLine()
					if im.InputTextWithHint("##newVehicle", "New Vehicle", config.cobalt.vehicles.newVehicleInput, 128) then
					end
					im.Text("	")
					im.SameLine()
					if im.SmallButton("Apply##newVehPerm") then
						TriggerServerEvent("CEISetNewVehiclePerm", ffi.string(config.cobalt.vehicles.newVehicleInput))
						log('W', logTag, "CEISetNewVehiclePerm Called: " .. ffi.string(config.cobalt.vehicles.newVehicleInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new vehicle and press Apply")
					
					im.ImGuiTextFilter_Draw(vehiclePermsFiltering.filter[0])
					
					for k,v in pairs(vehiclePerms) do
						
						for i = 0, im.GetLengthArrayCharPtr(vehiclePermsFiltering.lines) - 1 do
						
							if im.ImGuiTextFilter_PassFilter(vehiclePermsFiltering.filter[0], vehiclePermsFiltering.lines[i]) then
							
								if config.cobalt.vehicles.vehiclePerms[k].name == ffi.string(vehiclePermsFiltering.lines[i]) then
							
									if im.TreeNode1(ffi.string(vehiclePermsFiltering.lines[i]) .. ":") then
										im.SameLine()
										im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].level)
										im.Text("	")
										im.SameLine()
										im.PushItemWidth(100)
										if im.InputInt("", config.cobalt.vehicles.vehiclePerms[k].levelInt, 1) then
											TriggerServerEvent("CEISetVehiclePermLevel", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].levelInt[0]))
											log('W', logTag, "CEISetVehiclePermLevel Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].levelInt[0]))
										end
										im.PopItemWidth()
										
										im.SameLine()
										if im.SmallButton("Remove##vehPerm") then
											TriggerServerEvent("CEIRemoveVehiclePerm", config.cobalt.vehicles.vehiclePerms[k].name)
											log('W', logTag, "CEIRemoveVehiclePerm Called: " .. config.cobalt.vehicles.vehiclePerms[k].name)
										end
										im.SameLine()
										im.ShowHelpMarker("In-/Decrease vehicle permission level requirement or Remove vehicle entry")
										
										im.Text("	Add part: ")
										im.SameLine()
										if im.InputTextWithHint("##newPart", "New Part", config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput, 128) then
										end
										im.Text("	")
										im.SameLine()
										if im.SmallButton("Apply##newVehPart") then
											TriggerServerEvent("CEISetNewVehiclePart", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. ffi.string(config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput))
											log('W', logTag, "CEISetNewVehiclePart Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. ffi.string(config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput))
										end
										im.SameLine()
										im.ShowHelpMarker("Enter new part and press Apply")
										
										if config.cobalt.vehicles.vehiclePerms[k].partLevel then
										
											
											local partName = string.gsub(config.cobalt.vehicles.vehiclePerms[k].partLevel.name, "partlevel:", "")
											if im.TreeNode1(partName .. ":") then
												im.SameLine()
												im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].partLevel.level)
												im.Text("	")
												im.SameLine()
												im.PushItemWidth(100)
												if im.InputInt("", config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt, 1) then
													TriggerServerEvent("CEISetVehiclePartLevel", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt[0]))
													log('W', logTag, "CEISetVehiclePartLevel Called: " ..  config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt[0]))
												end
												im.PopItemWidth()
												
												im.SameLine()
												if im.SmallButton("Remove##vehPart") then
													TriggerServerEvent("CEIRemoveVehiclePart", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName)
													log('W', logTag, "CEIRemoveVehiclePart Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName)
												end
												im.SameLine()
												im.ShowHelpMarker("In-/Decrease vehicle part permission level requirement or Remove vehicle part entry")
												
												im.TreePop()
											else
												im.SameLine()
												im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].partLevel.level)
											end
										end
										im.TreePop()
									else
										im.SameLine()
										im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].level)
									end
								end
							end
						end
					end
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(vehiclePermsCounter))
				end
				im.Separator()
				
				local vehicleCaps = config.cobalt.permissions.vehicleCaps
				local vehicleCapsCounter = 0
				for a,b in pairs(vehicleCaps) do
					vehicleCapsCounter = vehicleCapsCounter + 1
				end
				
				if im.TreeNode1("vehicleCaps:") then
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
					for k,v in pairs(vehicleCaps) do
						if im.TreeNode1("level: " .. config.cobalt.permissions.vehicleCaps[k].level .. " =") then
							im.SameLine()
							im.Text(config.cobalt.permissions.vehicleCaps[k].vehicles .. " vehicles")
							im.Text("		")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("", config.cobalt.permissions.vehicleCaps[k].vehiclesInt, 1) then
								TriggerServerEvent("CEISetVehiclePerms", config.cobalt.permissions.vehicleCaps[k].level .. "|" .. tostring(config.cobalt.permissions.vehicleCaps[k].vehiclesInt[0]))
								log('W', logTag, "CEISetVehiclePerms Called: " .. config.cobalt.permissions.vehicleCaps[k].level .. "|" .. tostring(config.cobalt.permissions.vehicleCaps[k].vehiclesInt[0]))
							end
							im.PopItemWidth()
							im.SameLine()
							if im.SmallButton("Remove##"..tostring(k)) then
								TriggerServerEvent("CEIRemoveVehiclePermsLevel", config.cobalt.permissions.vehicleCaps[k].level)
								log('W', logTag, "CEIRemoveVehiclePermsLevel Called: " .. config.cobalt.permissions.vehicleCaps[k].level)
							end
							im.SameLine()
							im.ShowHelpMarker("In-/Decrease vehicles for level or Remove level entry")
							im.TreePop()
						else
							im.SameLine()
							im.Text(config.cobalt.permissions.vehicleCaps[k].vehicles .. " vehicles")
						end
					end
					im.Text("		Add level: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputTextWithHint("##newLevel", "New Level", config.cobalt.permissions.newLevelInput, 128) then
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetNewVehiclePermsLevel", ffi.string(config.cobalt.permissions.newLevelInput))
						log('W', logTag, "CEISetNewVehiclePermsLevel Called: " .. ffi.string(config.cobalt.permissions.newLevelInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new level and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
				end
				im.Separator()
				if im.TreeNode1("maxActivePlayers:") then
					im.SameLine()
					im.Text(config.cobalt.maxActivePlayers)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.cobalt.maxActivePlayersInt, 1) then
						log('W', logTag, "CEISetMaxActivePlayers Called: " .. tostring(config.cobalt.maxActivePlayersInt[0]))
						TriggerServerEvent("CEISetMaxActivePlayers",tostring(config.cobalt.maxActivePlayersInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.cobalt.maxActivePlayers)
				end
				im.Separator()
				local groups = config.cobalt.groups
				local groupCounter = 0
				for a,b in pairs(groups) do
					groupCounter = groupCounter + 1
				end
				if im.TreeNode1("groups:") then
					im.SameLine()
					im.Text(tostring(groupCounter))
					for k,v in pairs(groups) do
						im.Separator()
						if im.TreeNode1(config.cobalt.groups[k].groupName) then
							local groupPlayers = config.cobalt.groups[k].groupPlayers
							local groupPlayersCounter = 0
							for c,d in pairs(groupPlayers) do
								groupPlayersCounter = groupPlayersCounter + 1
							end
							if config.cobalt.groups[k].groupLevel then
								im.Text("		players: " .. tostring(groupPlayersCounter))
								for w,z in pairs(groupPlayers) do
									im.Text("		")
									im.SameLine()
									im.Text(groupPlayers[w])
									im.SameLine()
									im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
									im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
									im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
									if im.SmallButton("Remove##"..tostring(w)) then
										TriggerServerEvent("CEISetGroup", groupPlayers[w] .. "|none")
										log('W', logTag, "CEISetGroup Called: " .. groupPlayers[w] .. "|none")
									end
									im.PopStyleColor(3)
								end
								im.Text("		")
								im.Text("		level: ")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", config.cobalt.groups[k].groupLevelInt, 1) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
								end
								im.PopItemWidth()
							else
								im.Text("		level: ")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", config.cobalt.groups[k].groupLevelInt, 1) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
								end
								im.PopItemWidth()
							end
							if config.cobalt.groups[k].groupWhitelisted then
								im.Text("		whitelisted: " .. config.cobalt.groups[k].groupWhitelisted)
								im.SameLine()
								if config.cobalt.groups[k].groupWhitelisted == "false" then
									if im.SmallButton("Whitelist##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|true")
									end
								elseif config.cobalt.groups[k].groupWhitelisted == "true" then
									if im.SmallButton("Unwhitelist##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|false")
									end
									
								end
							else
								im.Text("		whitelisted: null")
								im.SameLine()
								if im.SmallButton("Whitelist##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|true")
								end
								
							end
							if config.cobalt.groups[k].groupMuted then
								im.Text("		muted: " .. config.cobalt.groups[k].groupMuted)
								im.SameLine()
								if config.cobalt.groups[k].groupMuted == "false" then
									if im.SmallButton("Mute##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|true")
									end
								elseif config.cobalt.groups[k].groupMuted == "true" then
									if im.SmallButton("Unmute##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|false")
									end
									
								end
							else
								im.Text("		muted: null")
								im.SameLine()
								if im.SmallButton("Mute##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|true")
								end
								
							end
							if config.cobalt.groups[k].groupBanned then
								im.Text("		banned: " .. config.cobalt.groups[k].groupBanned)
								im.SameLine()
								if config.cobalt.groups[k].groupBanned == "false" then
									if im.SmallButton("Ban##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
									end
									
								elseif config.cobalt.groups[k].groupBanned == "true" then
									if im.SmallButton("Unban##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
									end
									
								end
							else
								im.Text("		banned: null")
								im.SameLine()
								if im.SmallButton("Ban##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
								end
								
							end
							if config.cobalt.groups[k].groupBanReason then
								im.Text("		banReason: " .. config.cobalt.groups[k].groupBanReason)
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", config.cobalt.groups[k].groupBanReasonInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
								end
								im.SameLine()
								if im.SmallButton("Remove##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|none")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|none")
								end
								im.SameLine()
								im.ShowHelpMarker("Remove banReason or enter new banReason and press Apply")
							else
								im.Text("		banReason: null")
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", config.cobalt.groups[k].groupBanReasonInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
								end
								im.SameLine()
								im.ShowHelpMarker("Enter new banReason and press Apply")
							end
							im.Text("		")
							im.Text("		Add Player to Group: ")
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##groupPlayerName"..tostring(k), "Player Name", config.cobalt.groups[k].newGroupPlayerInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Add##groupPlayerName"..tostring(k)) then
								TriggerServerEvent("CEISetGroup", ffi.string(config.cobalt.groups[k].newGroupPlayerInput) .. "|" .. config.cobalt.groups[k].groupName)
								log('W', logTag, "CEISetGroup Called: add|" .. ffi.string(config.cobalt.groups[k].newGroupPlayerInput) .. "|" .. config.cobalt.groups[k].groupName)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter Player Name to Add to Group and press Apply")
							im.Text("		")
							im.Text("		")
							im.SameLine()
							im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
							im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
							im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
							if im.SmallButton("Remove Group##"..config.cobalt.groups[k].groupName) then
								TriggerServerEvent("CEIRemoveGroup", config.cobalt.groups[k].groupName)
								log('W', logTag, "CEIRemoveGroup Called: " .. config.cobalt.groups[k].groupName)
							end
							im.PopStyleColor(3)
							im.SameLine()
							im.ShowHelpMarker("Remove Group... CAREFUL WITH THIS")
							im.TreePop()
							im.Text("		")
						end
					end
					im.TreePop()
					im.Separator()
					im.Text("		Add Group: ")
					im.SameLine()
					if im.InputTextWithHint("##groupName", "Group Name", config.cobalt.newGroupInput, 128) then
					end
					im.Indent()
					im.Indent()
					im.Indent()
					im.Text("		")
					im.SameLine()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetNewGroup", ffi.string(config.cobalt.newGroupInput))
						log('W', logTag, "CEISetNewGroup Called: " .. ffi.string(config.cobalt.newGroupInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Group Name and press Apply")
					im.Unindent()
					im.Unindent()
					im.Unindent()
				else
					im.SameLine()
					im.Text(tostring(groupCounter))
				end
				im.Separator()
				local whitePlayers = config.cobalt.whitelistedPlayers
				local whitePlayersCounter = 0
				for a,b in pairs(whitePlayers) do
					whitePlayersCounter = whitePlayersCounter + 1
				end
				if im.TreeNode1("whitelisted players:") then
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
					for x,y in pairs(whitePlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.cobalt.whitelistedPlayers[x].name)
						im.SameLine()
						if im.SmallButton("Remove##"..tostring(x)) then
							TriggerServerEvent("CEIWhitelist", "remove|" .. config.cobalt.whitelistedPlayers[x].name)
							log('W', logTag, "CEIWhitelist Called: remove|" .. config.cobalt.whitelistedPlayers[x].name)
						end
					end
					im.Text("		Add Name to Whitelist: ")
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##whitelistName", "Player Name", config.cobalt.whitelistNameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Add##whitelistName") then
						TriggerServerEvent("CEIWhitelist", "add|" .. ffi.string(config.cobalt.whitelistNameInput))
						log('W', logTag, "CEIWhitelist Called: add|" .. ffi.string(config.cobalt.whitelistNameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter Player Name to Add to Whitelist and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
				end
				im.Text("		")
				im.SameLine()
				if config.cobalt.enableWhitelist == "false" then
					if im.SmallButton("Enable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","enable")
						log('W', logTag, "CEIWhitelist Called: enable")
					end
				elseif config.cobalt.enableWhitelist == "true" then
					if im.SmallButton("Disable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","disable")
						log('W', logTag, "CEIWhitelist Called: disable")
					end
				end
				
				im.Separator()
				im.Text('		Default CEI State:')
				im.SameLine()
				if config.cobalt.interface.defaultState == "true" then
					if im.SmallButton("Shown##") then
						TriggerServerEvent("CEISetDefaultState","false")
						log('W', logTag, "CEISetDefaultState Called: false")
					end
				elseif config.cobalt.interface.defaultState == "false" then
					if im.SmallButton("Hidden##") then
						TriggerServerEvent("CEISetDefaultState","true")
						log('W', logTag, "CEISetDefaultState Called: true")
					end
				end
				
				--[[im.Separator()
				if im.TreeNode1("miscellaneous") then
					im.Separator()
					im.Indent()
					im.Text("enableColors: "..config.cobalt.enableColors)
					im.SameLine()
					if config.cobalt.enableColors == "false" then
						if im.SmallButton("Enable Colors##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableColors|enable")
							log('W', logTag, "CEIConfig Called: enableColors|enable")
						end
					elseif config.cobalt.enableColors == "true" then
						if im.SmallButton("Disable Colors##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableColors|disable")
							log('W', logTag, "CEIConfig Called: enableColors|disable")
						end
					end
					im.Separator()
					im.Text("enableDebug: "..config.cobalt.enableDebug)
					im.SameLine()
					if config.cobalt.enableDebug == "false" then
						if im.SmallButton("Enable Debug##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableDebug|enable")
							log('W', logTag, "CEIConfig Called: enableDebug|enable")
						end
					elseif config.cobalt.enableDebug == "true" then
						if im.SmallButton("Disable Debug##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableDebug|disable")
							log('W', logTag, "CEIConfig Called: enableDebug|disable")
						end
					end
					im.Separator()
					im.Text("RCONenabled: "..config.cobalt.RCONenabled)
					im.SameLine()
					if config.cobalt.RCONenabled == "false" then
						if im.SmallButton("Enable RCON##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONenabled|enable")
							log('W', logTag, "CEIConfig Called: RCONenabled|enable")
						end
					elseif config.cobalt.RCONenabled == "true" then
						if im.SmallButton("Disable RCON##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONenabled|disable")
							log('W', logTag, "CEIConfig Called: RCONenabled|disable")
						end
					end
					im.Separator()
					im.Text("RCONkeepAliveTick: "..config.cobalt.RCONkeepAliveTick)
					im.SameLine()
					if config.cobalt.RCONkeepAliveTick == "false" then
						if im.SmallButton("Enable RCONkeepAliveTick##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONkeepAliveTick|enable")
							log('W', logTag, "CEIConfig Called: RCONkeepAliveTick|enable")
						end
					elseif config.cobalt.RCONkeepAliveTick == "true" then
						if im.SmallButton("Disable RCONkeepAliveTick##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONkeepAliveTick|disable")
							log('W', logTag, "CEIConfig Called: RCONkeepAliveTick|disable")
						end
					end
					im.Separator()
					im.Text("RCONpassword: "..config.cobalt.RCONpassword)
					if im.InputTextWithHint("##RCONpassword", "New RCON Password", config.cobalt.newRCONpassword, 128) then
					end
					if im.SmallButton("Apply##RCONpassword") then
						TriggerServerEvent("CEIConfig", "RCONpassword|" .. ffi.string(config.cobalt.newRCONpassword))
						log('W', logTag, "CEIConfig Called: RCONpassword|" .. ffi.string(config.cobalt.newRCONpassword))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new RCON Password and press Apply")
					im.Separator()
					im.Text("RCONport: "..config.cobalt.RCONport)
					if im.InputTextWithHint("##RCONport", "New RCON Port", config.cobalt.newRCONport, 128) then
					end
					if im.SmallButton("Apply##RCONport") then
						TriggerServerEvent("CEIConfig", "RCONport|" .. ffi.string(config.cobalt.newRCONport))
						log('W', logTag, "CEIConfig Called: RCONport|" .. ffi.string(config.cobalt.newRCONport))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new RCON Port and press Apply")
					im.Separator()
					im.Text("CobaltDBport: "..config.cobalt.CobaltDBport)
					if im.InputTextWithHint("##CobaltDBport", "New CobaltDB Port", config.cobalt.newCobaltDBport, 128) then
					end
					if im.SmallButton("Apply##CobaltDBport") then
						TriggerServerEvent("CEIConfig", "CobaltDBport|" .. ffi.string(config.cobalt.newCobaltDBport))
						log('W', logTag, "CEIConfig Called: CobaltDBport|" .. ffi.string(config.cobalt.newCobaltDBport))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new CobaltDB Port and press Apply")
					im.Text("		")
					im.Unindent()
					im.TreePop()
				end]]
				im.Unindent()
			end
----------------------------------------------------------------------------------SERVER HEADER
			if im.CollapsingHeader1("Server") then
				im.Indent()
				if im.TreeNode1("name:") then
					im.SameLine()
					im.Text(config.server.name)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##name", "Server Name", config.server.nameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg", "Name|" .. ffi.string(config.server.nameInput))
						log('W', logTag, "CEISetCfg Called: Name|" .. ffi.string(config.server.nameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Name and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.name)
				end
				im.Separator()
				if im.TreeNode1("maxCars:") then
					im.SameLine()
					im.Text(config.server.maxCars)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxCarsInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxCars|" .. tostring(config.server.maxCarsInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxCars|" .. tostring(config.server.maxCarsInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxCars)
				end
				im.Separator()
				if im.TreeNode1("maxPlayers:") then
					im.SameLine()
					im.Text(config.server.maxPlayers)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxPlayersInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxPlayers)
				end
				im.Separator()
				if im.TreeNode1("map:") then
					im.SameLine()
					im.Text(config.server.map)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##map", "Map Path", config.server.mapInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Map|" .. ffi.string(config.server.mapInput))
						log('W', logTag, "CEISetCfg Called: Map|" ..  ffi.string(config.server.mapInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Map and press Apply (REQUIRES REJOIN FOR EFFECT)")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.map)
				end
				im.Separator()
				if im.TreeNode1("description:") then
					im.SameLine()
					im.Text(config.server.description)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##description", "Server Description", config.server.descriptionInput, 256) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Description|" .. ffi.string(config.server.descriptionInput))
						log('W', logTag, "CEISetCfg Called: Description|" ..  ffi.string(config.server.descriptionInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Description and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.description)
				end
				im.Separator()
				im.Text("		debug: " .. config.server.debug)
				im.SameLine()
				if config.server.debug == "false" then
					if im.SmallButton("Enable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|true")
						log('W', logTag, "CEISetCfg Called: Debug|true")
					end
				elseif config.server.debug == "true" then
					if im.SmallButton("Disable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|false")
						log('W', logTag, "CEISetCfg Called: Debug|false")
					end
					
				end
				im.Separator()
				im.Text("		private: " .. config.server.private)
				im.SameLine()
				if config.server.private == "false" then
					if im.SmallButton("Set Private##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|true")
						log('W', logTag, "CEISetCfg Called: private|true")
					end
				elseif config.server.private == "true" then
					if im.SmallButton("Set Public##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|false")
						log('W', logTag, "CEISetCfg Called: Private|false")
					end
				end
				im.Text("		")
				im.Text("		")
				im.SameLine()
				im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
				if im.SmallButton("Stop/Restart##"..tostring(k)) then
					TriggerServerEvent("CEIStop","Good-bye!")
					log('W', logTag, "CEIStop Called: Goodbye!")
				end
				im.PopStyleColor(3)
				im.SameLine()
				im.ShowHelpMarker("Good-bye!")
				im.Unindent()
				
			end
----------------------------------------------------------------------------------NAMETAGS HEADER
			if im.CollapsingHeader1("Nametags") then
			
				local nametagWhitelist = config.nametags.whitelistedPlayers
				local nametagWhitelistCounter = 0
				for a,b in pairs(nametagWhitelist) do
					nametagWhitelistCounter = nametagWhitelistCounter + 1
				end
			
				im.Indent()
				if im.TreeNode1("Nametag Settings") then
					im.Text("		")
					im.SameLine()
					im.Text("Nametag Blocking: ")
					if config.nametags.settings.blockingEnabled == "true" then
						im.SameLine()
						if im.SmallButton("Enabled##NametagBlocking") then
							
							TriggerServerEvent("CEINametagSetting", "false")
							log('W', logTag, "CEINametagSetting: false")
							TriggerServerEvent("txNametagBlockerTimeout", "0")
							log('W', logTag, "txNametagBlockerTimeout: 0")
						end
					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Disabled##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Blocking Timeout: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##nametagBlockingTimeout", config.nametags.settings.blockingTimeoutInt, 1) then
						if config.nametags.settings.blockingTimeoutInt[0] < 0 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(0)
						elseif config.nametags.settings.blockingTimeoutInt[0] > 3600 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(3600)
						end
						TriggerServerEvent("CEINametagSetting", tostring(config.nametags.settings.blockingTimeoutInt[0]))
						log('W', logTag, "CEINametagSetting Called: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
					end
					im.PopItemWidth()
					
					if config.nametags.settings.blockingEnabled == "true" then

					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Start##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
							TriggerServerEvent("txNametagBlockerTimeout", tostring(config.nametags.settings.blockingTimeoutInt[0]))
							log('W', logTag, "txNametagBlockerTimeout: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
						end
					end
					
					im.TreePop()
				else
				end
				im.Separator()
				if im.TreeNode1("Nametag Whitelist: ") then
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
					
					for k,v in pairs(config.nametags.whitelistedPlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.nametags.whitelistedPlayers[k].name)
						im.SameLine()
						if im.SmallButton("Remove##"..config.nametags.whitelistedPlayers[k].name) then
							TriggerServerEvent("CEIRemoveNametagWhitelist", config.nametags.whitelistedPlayers[k].name)
							log('W', logTag, "CEIRemoveNametagWhitelist: " .. config.nametags.whitelistedPlayers[k].name)
						end
					end
					
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##whitelistName", "Whitelist Name", config.nametags.whitelistNameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##nametagWhitleist") then
						TriggerServerEvent("CEISetNametagWhitelist", ffi.string(config.nametags.whitelistNameInput))
						log('W', logTag, "CEISetNametagWhitelist Called: " .. ffi.string(config.nametags.whitelistNameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Whitelist Name and press Apply")
				
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
				end
				im.Unindent()
				
			end
			
			im.EndTabItem()
		end
		
----------------------------------------------------------------------------------ENVIRONMENT TAB
		if im.BeginTabItem("Environment") then
					
			im.Indent()

			if im.SmallButton("Reset All##ENV") then
				TriggerServerEvent("CEISetEnv", "all|default")
				log('W', logTag, "CEISetEnv Called: all|default")
			end
			
			if im.TreeNode1("Sun") then
				im.SameLine()
				if im.SmallButton("Reset##SUN") then
					TriggerServerEvent("CEISetEnv", "allSun|default")
					log('W', logTag, "CEISetEnv Called: allSun|default")
				end
				im.Indent()
					
				im.Text("Time Play: ")
				im.SameLine()
				local timePlay = environment.timePlay
				if timePlay == "false" then
					if im.SmallButton("Play") then
						TriggerServerEvent("CEISetEnv", "timePlay|true")
						log('W', logTag, "CEISetEnv Called: timePlay|true")
					end
				elseif timePlay == "true" then
					if im.SmallButton("Stop") then
						local timeOfDay = core_environment.getTimeOfDay()
						TriggerServerEvent("CEISetEnv", "ToD|" .. tostring(timeOfDay.time))
						log('W', logTag, "CEISetEnv Called: ToD|" .. tostring(timeOfDay.time))
						TriggerServerEvent("CEISetEnv", "timePlay|false")
						log('W', logTag, "CEISetEnv Called: timePlay|false")
					end
				end
				
				im.Text("Time of Day: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##ToD", environment.todVal, 0.001, 0.01) then
					if environment.todVal[0] < 0 then
						environment.todVal = im.FloatPtr(1)
					elseif environment.todVal[0] > 1 then
						environment.todVal = im.FloatPtr(0)
					end
					environment.todVal = im.FloatPtr(environment.todVal)
					TriggerServerEvent("CEISetEnv", "ToD|" .. tostring(environment.todVal[0]))
					log('W', logTag, "CEISetEnv Called: ToD|" .. tostring(environment.todVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##ToD") then
					TriggerServerEvent("CEISetEnv", "ToD|default")
					log('W', logTag, "CEISetEnv Called: ToD|default")
				end
				
				im.Text("Day Scale: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##dayScale", environment.dayScaleVal, 0.01, 0.1) then
					if environment.dayScaleVal[0] < 0.01 then
						environment.dayScaleVal = im.FloatPtr(0.01)
					elseif environment.dayScaleVal[0] > 100 then
						environment.dayScaleVal = im.FloatPtr(100)
					end
					environment.dayScaleVal = im.FloatPtr(environment.dayScaleVal)
					TriggerServerEvent("CEISetEnv", "dayScale|" .. tostring(environment.dayScaleVal[0]))
					log('W', logTag, "CEISetEnv Called: dayScale|" .. tostring(environment.dayScaleVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Realtime##DS") then
					TriggerServerEvent("CEISetEnv", "dayScale|0.020855")
					log('W', logTag, "CEISetEnv Called: dayScale|0.020855")
				end
				im.SameLine()
				if im.SmallButton("Reset##DS") then
					TriggerServerEvent("CEISetEnv", "dayScale|default")
					log('W', logTag, "CEISetEnv Called: dayScale|default")
				end
				
				im.Text("Night Scale: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##nightScale", environment.nightScaleVal, 0.01, 0.1) then
					if environment.nightScaleVal[0] < 0.01 then
						environment.nightScaleVal = im.FloatPtr(0.01)
					elseif environment.nightScaleVal[0] > 100 then
						environment.nightScaleVal = im.FloatPtr(100)
					end
					environment.nightScaleVal = im.FloatPtr(environment.nightScaleVal)
					TriggerServerEvent("CEISetEnv", "nightScale|" .. tostring(environment.nightScaleVal[0]))
					log('W', logTag, "CEISetEnv Called: nightScale|" .. tostring(environment.nightScaleVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Realtime##NS") then
					TriggerServerEvent("CEISetEnv", "nightScale|0.020855")
					log('W', logTag, "CEISetEnv Called: nightScale|0.020855")
				end
				im.SameLine()
				if im.SmallButton("Reset##NS") then
					TriggerServerEvent("CEISetEnv", "nightScale|default")
					log('W', logTag, "CEISetEnv Called: nightScale|default")
				end
				
				im.Text("Azimuth Override: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##azimuthOverride", environment.azimuthOverrideVal, 0.001, 0.01) then
					if environment.azimuthOverrideVal[0] < 0 then
						environment.azimuthOverrideVal = im.FloatPtr(6.25)
					elseif environment.azimuthOverrideVal[0] > 6.25 then
						environment.azimuthOverrideVal = im.FloatPtr(0)
					end
					environment.azimuthOverrideVal = im.FloatPtr(environment.azimuthOverrideVal)
					TriggerServerEvent("CEISetEnv", "azimuthOverride|" .. tostring(environment.azimuthOverrideVal[0]))
					log('W', logTag, "CEISetEnv Called: azimuthOverride|" .. tostring(environment.azimuthOverrideVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##AO") then
					TriggerServerEvent("CEISetEnv", "azimuthOverride|default")
					log('W', logTag, "CEISetEnv Called: azimuthOverride|default")
				end
				
				im.Text("Sun Size: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##sunSize", environment.sunSizeVal, 0.01, 0.1) then
					if environment.sunSizeVal[0] < 0 then
						environment.sunSizeVal = im.FloatPtr(0)
					elseif environment.sunSizeVal[0] > 100 then
						environment.sunSizeVal = im.FloatPtr(100)
					end
					environment.sunSizeVal = im.FloatPtr(environment.sunSizeVal)
					TriggerServerEvent("CEISetEnv", "sunSize|" .. tostring(environment.sunSizeVal[0]))
					log('W', logTag, "CEISetEnv Called: sunSize|" .. tostring(environment.sunSizeVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SS") then
					TriggerServerEvent("CEISetEnv", "sunSize|default")
					log('W', logTag, "CEISetEnv Called: sunSize|default")
				end
				
				im.Text("Sky Brightness: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##skyBrightness", environment.skyBrightnessVal, 0.1, 1.0) then
					if environment.skyBrightnessVal[0] < 0 then
						environment.skyBrightnessVal = im.FloatPtr(0)
					elseif environment.skyBrightnessVal[0] > 200 then
						environment.skyBrightnessVal = im.FloatPtr(200)
					end
					environment.skyBrightnessVal = im.FloatPtr(environment.skyBrightnessVal)
					TriggerServerEvent("CEISetEnv", "skyBrightness|" .. tostring(environment.skyBrightnessVal[0]))
					log('W', logTag, "CEISetEnv Called: skyBrightness|" .. tostring(environment.skyBrightnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SB") then
					TriggerServerEvent("CEISetEnv", "skyBrightness|default")
					log('W', logTag, "CEISetEnv Called: skyBrightness|default")
				end
				
				im.Text("Sunlight Brightness: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##sunLightBrightness", environment.sunLightBrightnessVal, 0.01, 0.1) then
					if environment.sunLightBrightnessVal[0] < 0 then
						environment.sunLightBrightnessVal = im.FloatPtr(0)
					elseif environment.sunLightBrightnessVal[0] > 10 then
						environment.sunLightBrightnessVal = im.FloatPtr(10)
					end
					environment.sunLightBrightnessVal = im.FloatPtr(environment.sunLightBrightnessVal)
					TriggerServerEvent("CEISetEnv", "sunLightBrightness|" .. tostring(environment.sunLightBrightnessVal[0]))
					log('W', logTag, "CEISetEnv Called: sunLightBrightness|" .. tostring(environment.sunLightBrightnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##GB") then
					TriggerServerEvent("CEISetEnv", "sunLightBrightness|default")
					log('W', logTag, "CEISetEnv Called: sunLightBrightness|default")
				end
				
				im.Text("Exposure: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##exposure", environment.exposureVal, 0.01, 0.1) then
					if environment.exposureVal[0] < 0 then
						environment.exposureVal = im.FloatPtr(0)
					elseif environment.exposureVal[0] > 3 then
						environment.exposureVal = im.FloatPtr(3)
					end
					environment.exposureVal = im.FloatPtr(environment.exposureVal)
					TriggerServerEvent("CEISetEnv", "exposure|" .. tostring(environment.exposureVal[0]))
					log('W', logTag, "CEISetEnv Called: exposure|" .. tostring(environment.exposureVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##EX") then
					TriggerServerEvent("CEISetEnv", "exposure|default")
					log('W', logTag, "CEISetEnv Called: exposure|default")
				end
				
				im.Text("Shadow Distance: ")
				im.SameLine()
				im.PushItemWidth(120)
				if im.InputFloat("##shadowDistance", environment.shadowDistanceVal, 0.001, 0.01) then
					if environment.shadowDistanceVal[0] < 0 then
						environment.shadowDistanceVal = im.FloatPtr(0)
					elseif environment.shadowDistanceVal[0] > 12800 then
						environment.shadowDistanceVal = im.FloatPtr(12800)
					end
					environment.shadowDistanceVal = im.FloatPtr(environment.shadowDistanceVal)
					TriggerServerEvent("CEISetEnv", "shadowDistance|" .. tostring(environment.shadowDistanceVal[0]))
					log('W', logTag, "CEISetEnv Called: shadowDistance|" .. tostring(environment.shadowDistanceVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SD") then
					TriggerServerEvent("CEISetEnv", "shadowDistance|default")
					log('W', logTag, "CEISetEnv Called: shadowDistance|default")
				end
				
				im.Text("Shadow Softness: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##shadowSoftness", environment.shadowSoftnessVal, 0.001, 0.01) then
					if environment.shadowSoftnessVal[0] < -10 then
						environment.shadowSoftnessVal = im.FloatPtr(-10)
					elseif environment.shadowSoftnessVal[0] > 10 then
						environment.shadowSoftnessVal = im.FloatPtr(10)
					end
					environment.shadowSoftnessVal = im.FloatPtr(environment.shadowSoftnessVal)
					TriggerServerEvent("CEISetEnv", "shadowSoftness|" .. tostring(environment.shadowSoftnessVal[0]))
					log('W', logTag, "CEISetEnv Called: shadowSoftness|" .. tostring(environment.shadowSoftnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SSFT") then
					TriggerServerEvent("CEISetEnv", "shadowSoftness|default")
					log('W', logTag, "CEISetEnv Called: shadowSoftness|default")
				end
				
				im.Text("Shadow Splits: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##shadowSplits", environment.shadowSplitsInt, 1) then
					if environment.shadowSplitsInt[0] < 0 then
						environment.shadowSplitsInt = im.IntPtr(0)
					elseif environment.shadowSplitsInt[0] > 4 then
						environment.shadowSplitsInt = im.IntPtr(4)
					end
					TriggerServerEvent("CEISetEnv", "shadowSplits|" .. tostring(environment.shadowSplitsInt[0]))
					log('W', logTag, "CEISetEnv Called: shadowSplits|" .. tostring(environment.shadowSplitsInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SSPL") then
					TriggerServerEvent("CEISetEnv", "shadowSplits|default")
					log('W', logTag, "CEISetEnv Called: shadowSplits|default")
				end
				
				
				
				
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##SUN") then
					TriggerServerEvent("CEISetEnv", "allSun|default")
					log('W', logTag, "CEISetEnv Called: allSun|default")
				end
			end
			
			if im.TreeNode1("Weather") then
				im.SameLine()
				if im.SmallButton("Reset##WET") then
					TriggerServerEvent("CEISetEnv", "allWeather|default")
					log('W', logTag, "CEISetEnv Called: allWeather|default")
				end
				
				im.Indent()
				
				im.Text("Fog Density: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##fogDensity", environment.fogDensityVal, 0.00001, 0.0001) then
					if environment.fogDensityVal[0] < 0.00001 then
						environment.fogDensityVal = im.FloatPtr(0.00001)
					elseif environment.fogDensityVal[0] > 0.01 then
						environment.fogDensityVal = im.FloatPtr(0.01)
					end
					TriggerServerEvent("CEISetEnv", "fogDensity|" .. tostring(environment.fogDensityVal[0]))
					log('W', logTag, "CEISetEnv Called: fogDensity|" .. tostring(environment.fogDensityVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##FD") then
					TriggerServerEvent("CEISetEnv", "fogDensity|default")
					log('W', logTag, "CEISetEnv Called: fogDensity|default")
				end
				
				im.Text("Fog Distance: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##fogDensityOffset", environment.fogDensityOffsetVal, 0.001, 0.01) then
					if environment.fogDensityOffsetVal[0] < 0 then
						environment.fogDensityOffsetVal = im.FloatPtr(0)
					elseif environment.fogDensityOffsetVal[0] > 100 then
						environment.fogDensityOffsetVal = im.FloatPtr(100)
					end
					TriggerServerEvent("CEISetEnv", "fogDensityOffset|" .. tostring(environment.fogDensityOffsetVal[0]))
					log('W', logTag, "CEISetEnv Called: fogDensityOffset|" .. tostring(environment.fogDensityOffsetVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##FDO") then
					TriggerServerEvent("CEISetEnv", "fogDensityOffset|default")
					log('W', logTag, "CEISetEnv Called: fogDensityOffset|default")
				end
				
				im.Text("Cloud Cover: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##cloudCover", environment.cloudCoverVal, 0.01, 0.1) then
					if environment.cloudCoverVal[0] < 0 then
						environment.cloudCoverVal = im.FloatPtr(0)
					elseif environment.cloudCoverVal[0] > 5 then
						environment.cloudCoverVal = im.FloatPtr(5)
					end
					TriggerServerEvent("CEISetEnv", "cloudCover|" .. tostring(environment.cloudCoverVal[0]))
					log('W', logTag, "CEISetEnv Called: cloudCover|" .. tostring(environment.cloudCoverVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##CC") then
					TriggerServerEvent("CEISetEnv", "cloudCover|default")
					log('W', logTag, "CEISetEnv Called: cloudCover|default")
				end
				
				im.Text("Cloud Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##cloudSpeed", environment.cloudSpeedVal, 0.01, 0.1) then
					if environment.cloudSpeedVal[0] < 0 then
						environment.cloudSpeedVal = im.FloatPtr(0)
					elseif environment.cloudSpeedVal[0] > 10 then
						environment.cloudSpeedVal = im.FloatPtr(10)
					end
					TriggerServerEvent("CEISetEnv", "cloudSpeed|" .. tostring(environment.cloudSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: cloudSpeed|" .. tostring(environment.cloudSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##CS") then
					TriggerServerEvent("CEISetEnv", "cloudSpeed|default")
					log('W', logTag, "CEISetEnv Called: cloudSpeed|default")
				end
				
				im.Text("Rain Drops: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##rainDrops", environment.rainDropsInt, 1, 10) then
					if environment.rainDropsInt[0] < 0 then
						environment.rainDropsInt = im.IntPtr(0)
					elseif environment.rainDropsInt[0] > 20000 then
						environment.rainDropsInt = im.IntPtr(20000)
					end
					TriggerServerEvent("CEISetEnv", "rainDrops|" .. tostring(environment.rainDropsInt[0]))
					log('W', logTag, "CEISetEnv Called: rainDrops|" .. tostring(environment.rainDropsInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##RD") then
					TriggerServerEvent("CEISetEnv", "rainDrops|default")
					log('W', logTag, "CEISetEnv Called: rainDrops|default")
				end
				
				im.Text("Drop Size: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropSize", environment.dropSizeVal, 0.001, 0.01) then
					if environment.dropSizeVal[0] < 0 then
						environment.dropSizeVal = im.FloatPtr(0)
					elseif environment.dropSizeVal[0] > 2 then
						environment.dropSizeVal = im.FloatPtr(2)
					end
					environment.dropSizeVal = im.FloatPtr(environment.dropSizeVal)
					TriggerServerEvent("CEISetEnv", "dropSize|" .. tostring(environment.dropSizeVal[0]))
					log('W', logTag, "CEISetEnv Called: dropSize|" .. tostring(environment.dropSizeVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DSZ") then
					TriggerServerEvent("CEISetEnv", "dropSize|default")
					log('W', logTag, "CEISetEnv Called: dropSize|default")
				end
				
				im.Text("Drop Min Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropMinSpeed", environment.dropMinSpeedVal, 0.001, 0.01) then
					if environment.dropMinSpeedVal[0] < 0 then
						environment.dropMinSpeedVal = im.FloatPtr(0)
					elseif environment.dropMinSpeedVal[0] > 2 then
						environment.dropMinSpeedVal = im.FloatPtr(2)
					end
					environment.dropMinSpeedVal = im.FloatPtr(environment.dropMinSpeedVal)
					TriggerServerEvent("CEISetEnv", "dropMinSpeed|" .. tostring(environment.dropMinSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: dropMinSpeed|" .. tostring(environment.dropMinSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DMNS") then
					TriggerServerEvent("CEISetEnv", "dropMinSpeed|default")
					log('W', logTag, "CEISetEnv Called: dropMinSpeed|default")
				end
				
				im.Text("Drop Max Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropMaxSpeed", environment.dropMaxSpeedVal, 0.001, 0.01) then
					if environment.dropMaxSpeedVal[0] < 0 then
						environment.dropMaxSpeedVal = im.FloatPtr(0)
					elseif environment.dropMaxSpeedVal[0] > 2 then
						environment.dropMaxSpeedVal = im.FloatPtr(2)
					end
					environment.dropMaxSpeedVal = im.FloatPtr(environment.dropMaxSpeedVal)
					TriggerServerEvent("CEISetEnv", "dropMaxSpeed|" .. tostring(environment.dropMaxSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: dropMaxSpeed|" .. tostring(environment.dropMaxSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DMXS") then
					TriggerServerEvent("CEISetEnv", "dropMaxSpeed|default")
					log('W', logTag, "CEISetEnv Called: dropMaxSpeed|default")
				end
				
				im.Text("Precipitation Type: ")
				im.SameLine()
				local precipType = environment.precipType
				if precipType == "rain_medium" then
					if im.SmallButton("Medium Rain") then
						TriggerServerEvent("CEISetEnv", "precipType|rain_drop")
						log('W', logTag, "CEISetEnv Called: precipType|rain_drop")
					end
				elseif precipType == "rain_drop" then
					if im.SmallButton("Light Rain") then
						TriggerServerEvent("CEISetEnv", "precipType|Snow_menu")
						log('W', logTag, "CEISetEnv Called: precipType|Snow_menu")
					end
				elseif precipType == "Snow_menu" then
					if im.SmallButton("Snow") then
						TriggerServerEvent("CEISetEnv", "precipType|rain_medium")
						log('W', logTag, "CEISetEnv Called: precipType|rain_medium")
					end
				end
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##WET") then
					TriggerServerEvent("CEISetEnv", "allWeather|default")
					log('W', logTag, "CEISetEnv Called: allWeather|default")
				end
			end
			
			if im.TreeNode1("Simulation") then
				im.SameLine()
				if im.SmallButton("Reset##SIM") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
			
				im.Indent()
				
				im.Text("Teleport Timeout: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##teleportTimeout", environment.teleportTimeoutInt, 1, 10) then
					if environment.teleportTimeoutInt[0] < 0 then
						environment.teleportTimeoutInt = im.IntPtr(0)
					elseif environment.teleportTimeoutInt[0] > 60 then
						environment.teleportTimeoutInt = im.IntPtr(60)
					end
					TriggerServerEvent("CEISetEnv", "teleportTimeout|" .. tostring(environment.teleportTimeoutInt[0]))
					log('W', logTag, "CEISetEnv Called: teleportTimeout|" .. tostring(environment.teleportTimeoutInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##TLPT") then
					TriggerServerEvent("CEISetEnv", "teleportTimeout|default")
					log('W', logTag, "CEISetEnv Called: teleportTimeout|default")
				end
				
				im.Text("Simulation Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##simSpeed", environment.simSpeedVal, 0.001, 0.1) then
					if environment.simSpeedVal[0] < 0.01 then
						environment.simSpeedVal = im.FloatPtr(0.01)
					elseif environment.simSpeedVal[0] > 5 then
						environment.simSpeedVal = im.FloatPtr(5)
					end
					environment.simSpeedVal = im.FloatPtr(environment.simSpeedVal)
					TriggerServerEvent("CEISetEnv", "simSpeed|" .. tostring(environment.simSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: simSpeed|" .. tostring(environment.simSpeedVal[0]))
				end
				im.PopItemWidth()

				if im.SmallButton("0.5X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|2")
					log('W', logTag, "CEISetEnv Called: simSpeed|2")
				end
				im.SameLine()
				if im.SmallButton("Real") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
				im.SameLine()
				if im.SmallButton("2X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.5")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.5")
				end
				im.SameLine()
				if im.SmallButton("4X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.25")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.25")
				end
				im.SameLine()
				if im.SmallButton("10X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.1")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.1")
				end
				im.SameLine()
				if im.SmallButton("100X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.01")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.01")
				end
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##SIM") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
			end
		
			if im.TreeNode1("Gravity") then
				im.SameLine()
				if im.SmallButton("Reset##GRV") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
				im.Indent()
				
				im.Text("		")
				im.SameLine()
				im.PushItemWidth(130)
				if im.InputFloat("##gravity", environment.gravityVal, 0.001, 0.1) then
					if environment.gravityVal[0] < -280 then
						environment.gravityVal = im.FloatPtr(-280)
					elseif environment.gravityVal[0] > 10 then
						environment.gravityVal = im.FloatPtr(10)
					end
					environment.gravityVal = im.FloatPtr(environment.gravityVal)
					TriggerServerEvent("CEISetEnv", "gravity|" .. tostring(environment.gravityVal[0]))
					log('W', logTag, "CEISetEnv Called: gravity|" .. tostring(environment.gravityVal[0]))
				end
				im.PopItemWidth()

				if im.SmallButton("Zero") then
					TriggerServerEvent("CEISetEnv", "gravity|0")
					log('W', logTag, "CEISetEnv Called: gravity|0")
				end
				im.SameLine()
				if im.SmallButton("Earth") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
				im.SameLine()
				if im.SmallButton("Moon") then
					TriggerServerEvent("CEISetEnv", "gravity|-1.62")
					log('W', logTag, "CEISetEnv Called: gravity|-1.62")
				end

				if im.SmallButton("Mars") then
					TriggerServerEvent("CEISetEnv", "gravity|-3.71")
					log('W', logTag, "CEISetEnv Called: gravity|-3.71")
				end
				im.SameLine()
				if im.SmallButton("Sun") then
					TriggerServerEvent("CEISetEnv", "gravity|-274")
					log('W', logTag, "CEISetEnv Called: gravity|-274")
				end
				im.SameLine()
				if im.SmallButton("Jupiter") then
					TriggerServerEvent("CEISetEnv", "gravity|-24.92")
					log('W', logTag, "CEISetEnv Called: gravity|-24.92")
				end
				

				if im.SmallButton("Neptune") then
					TriggerServerEvent("CEISetEnv", "gravity|-11.15")
					log('W', logTag, "CEISetEnv Called: gravity|-11.15")
				end
				im.SameLine()
				if im.SmallButton("Saturn") then
					TriggerServerEvent("CEISetEnv", "gravity|-10.44")
					log('W', logTag, "CEISetEnv Called: gravity|-10.44")
				end
				im.SameLine()
				if im.SmallButton("Uranus") then
					TriggerServerEvent("CEISetEnv", "gravity|-8.87")
					log('W', logTag, "CEISetEnv Called: gravity|-8.87")
				end
				
				if im.SmallButton("Venus") then
					TriggerServerEvent("CEISetEnv", "gravity|-8.87")
					log('W', logTag, "CEISetEnv Called: gravity|-8.87")
				end
				im.SameLine()
				if im.SmallButton("Mercury") then
					TriggerServerEvent("CEISetEnv", "gravity|-3.7")
					log('W', logTag, "CEISetEnv Called: gravity|-3.7")
				end
				im.SameLine()
				if im.SmallButton("Pluto") then
					TriggerServerEvent("CEISetEnv", "gravity|-0.58")
					log('W', logTag, "CEISetEnv Called: gravity|-0.58")
				end
				
				im.TreePop()
				im.Unindent()
				
			else
				im.SameLine()
				if im.SmallButton("Reset##GRV") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
			end
		
			if im.TreeNode1("Temperature") then
				im.SameLine()
				if im.SmallButton("Reset##TMP") then
					TriggerServerEvent("CEISetEnv", "useTempCurve|false")
					log('W', logTag, "CEISetEnv Called: useTempCurve|false")
					environment.useTempCurveSent = false
				end
				im.Indent()
				
				local useTempCurve = im.BoolPtr(environment.useTempCurveVal)
				
				if im.Checkbox("Use Custom Temperature Curve", useTempCurve) then
					if useTempCurve[0] then
						if environment.useTempCurveSent == false then
							TriggerServerEvent("CEISetEnv", "useTempCurve|true")
							log('W', logTag, "CEISetEnv Called: useTempCurve|true")
							environment.useTempCurveSent = true
						end
					else
						if environment.useTempCurveSent == true then
							log('W', logTag, "CEISetEnv Called: useTempCurve|false")
							TriggerServerEvent("CEISetEnv", "useTempCurve|false")
							environment.useTempCurveSent = false
						end
					end
				end
				environment.useTempCurveVal = useTempCurve[0]
				
				if environment.useTempCurveVal == true then
					im.Text("Custom Temperature Curve:")
					im.SameLine()
					if im.SmallButton("Reset##TCV") then
						TriggerServerEvent("CEISetEnv", "tempCurveNoon|default")
						log('W', logTag, "CEISetEnv Called: tempCurveNoon|default")
						TriggerServerEvent("CEISetEnv", "tempCurveDusk|default")
						log('W', logTag, "CEISetEnv Called: tempCurveDusk|default")
						TriggerServerEvent("CEISetEnv", "tempCurveMidnight|default")
						log('W', logTag, "CEISetEnv Called: tempCurveMidnight|default")
						TriggerServerEvent("CEISetEnv", "tempCurveDawn|default")
						log('W', logTag, "CEISetEnv Called: tempCurveDawn|default")
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Noon")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveNoon", environment.tempCurveNoonInt, 1, 2) then
						if environment.tempCurveNoonInt[0] < -50 then
							environment.tempCurveNoonInt = im.IntPtr(-50)
						elseif environment.tempCurveNoonInt[0] > 50 then
							environment.tempCurveNoonInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveNoon|" .. tostring(environment.tempCurveNoonInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveNoon|" .. tostring(environment.tempCurveNoonInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dusk")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDusk", environment.tempCurveDuskInt, 1, 2) then
						if environment.tempCurveDuskInt[0] < -50 then
							environment.tempCurveDuskInt = im.IntPtr(-50)
						elseif environment.tempCurveDuskInt[0] > 50 then
							environment.tempCurveDuskInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveDusk|" .. tostring(environment.tempCurveDuskInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveDusk|" .. tostring(environment.tempCurveDuskInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Midnight")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveMidnight", environment.tempCurveMidnightInt, 1, 2) then
						if environment.tempCurveMidnightInt[0] < -50 then
							environment.tempCurveMidnightInt = im.IntPtr(-50)
						elseif environment.tempCurveMidnightInt[0] > 50 then
							environment.tempCurveMidnightInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveMidnight|" .. tostring(environment.tempCurveMidnightInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveMidnight|" .. tostring(environment.tempCurveMidnightInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dawn")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDawn", environment.tempCurveDawnInt, 1, 2) then
						if environment.tempCurveDawnInt[0] < -50 then
							environment.tempCurveDawnInt = im.IntPtr(-50)
						elseif environment.tempCurveDawnInt[0] > 50 then
							environment.tempCurveDawnInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveDawn|" .. tostring(environment.tempCurveDawnInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveDawn|" .. tostring(environment.tempCurveDawnInt[0]))
					end
					im.PopItemWidth()
				end
				
				im.TreePop()
				im.Unindent()
				
			else
				im.SameLine()
				if im.SmallButton("Reset##TMP") then
					TriggerServerEvent("CEISetEnv", "useTempCurve|false")
					log('W', logTag, "CEISetEnv Called: useTempCurve|false")
					environment.useTempCurveSent = false
				end
			end
			
		im.EndTabItem()
		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function drawCEAI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Administrator Interface")
	
	im.SameLine()
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.5, 0.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.6, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.4, 0.0, 0.999))
			if im.SmallButton("Race Countdown!") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
				
				TriggerServerEvent("CEIPreRace", "true")
				log('W', logTag, "CEIPreRace Called: true")
				
			end
			im.PopStyleColor(3)
			
			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]
			
			im.Separator()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.2, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.0, 0.0, 0.999))
			if im.SmallButton("Remote Stop All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Freeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.1, 1.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.2, 1.0, 0.2, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.0, 0.9, 0.0, 0.999))
			if im.SmallButton("Remote Start All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Unfreeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.Separator()
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("Ban##"..tostring(k)) then
						TriggerServerEvent("CEIBan",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIBan Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("TempBan##"..tostring(k)) then
						TriggerServerEvent("CEITempBan",tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEITempBan Called: " .. tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							
							im.SameLine()
							if im.SmallButton("Teleport From##" .. tostring(k)) then
								M.teleportPlayerToVeh(players[k].player.playerName,tostring(k))
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport this player's current vehicle to you.")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Reason:")
					im.SameLine()
					if im.InputTextWithHint("##"..tostring(k), "Kick or (temp)Ban or Mute Reason", players[k].player.kickBanMuteReason, 128) then
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("tempBan:")
					im.SameLine()
					im.PushItemWidth(120)
					if im.InputFloat("##tempBanLength"..tostring(k), players[k].player.tempBanLength, 0.001, 1) then
						if players[k].player.tempBanLength[0] < 0.001 then
							players[k].player.tempBanLength = im.FloatPtr(0.001)
						elseif players[k].player.tempBanLength[0] > 3650 then
							players[k].player.tempBanLength = im.FloatPtr(3650)
						end
						TriggerServerEvent("CEISetTempBan", tostring(k) .. "|" .. tostring(players[k].player.tempBanLength[0]))
						log('W', logTag, "CEISetTempBan Called: " .. tostring(k) .. "|" .. tostring(players[k].player.tempBanLength[0]))
					end
					im.SameLine()
					im.Text("days = " .. tostring(M.round(players[k].player.tempBanLength[0] * 1440,2)) .. " minutes")
					im.PopItemWidth()
					
					if vehiclesCounter > 0 then
						im.Separator()

						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							
							im.Text("		")
							im.SameLine()
							im.Text("Reason:")
							im.SameLine()
							if im.InputTextWithHint("##vehReason"..tostring(k), "Vehicle Delete Reason", players[k].player.vehDeleteReason, 128) then
							end
							
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
								for i,j in pairs(ignitionEnabled) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "true" then
											im.SameLine()
											if im.SmallButton("Remote Stop##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										elseif j == "false" then
											im.SameLine()
											if im.SmallButton("Remote Start##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										end
									end
								end
								
								for i,j in pairs(isFrozen) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "false" then
											im.SameLine()
											if im.SmallButton("Freeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										elseif j == "true" then
											im.SameLine()
											if im.SmallButton("Unfreeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										end
									end
								end
								
								im.SameLine()
								if im.SmallButton("Delete##"..tostring(x)) then
									TriggerServerEvent("CEIRemoveVehicle", tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
									log('W', logTag, "CEIRemoveVehicle Called: " .. tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
								end
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
					end
					im.Separator()
					if im.TreeNode1("info##"..tostring(k)) then
						im.Text("		playerID: " .. players[k].player.playerID)
						im.Text("		connectStage: " .. players[k].player.connectStage)
						im.Text("		guest: " .. players[k].player.guest)
						im.Text("		joinTime: " .. players[k].player.joinTime)
						im.SameLine()
						im.Text(": connectedTime: " .. players[k].player.connectedTime)
						im.Separator()
						if im.TreeNode1("permissions##"..tostring(k)) then
						
							if players[k].player.teleport == "false" then
								if im.SmallButton("Allow Teleport##"..tostring(k)) then
									TriggerServerEvent("CEISetTeleportPerm", tostring(k) .. "|true")
									log('W', logTag, "CEISetTeleportPerm Called: " .. tostring(k) .. "|true")
								end
							elseif players[k].player.teleport == "true" then
								if im.SmallButton("Revoke Teleport##"..tostring(k)) then
									TriggerServerEvent("CEISetTeleportPerm", tostring(k) .. "|false")
									log('W', logTag, "CEISetTeleportPerm Called: " .. tostring(k) .. "|false")
								end
							end
						
							if im.TreeNode1("level:") then
								im.SameLine()
								im.Text(players[k].player.permissions.level)
								im.Text("		")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", players[k].player.permissions.levelInt, 1) then
									TriggerServerEvent("CEISetTempPerm", tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
									log('W', logTag, "CEISetTempPerm Called: " .. tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
								end
								im.PopItemWidth()
								im.SameLine()
								if im.Button("Apply##level"..tostring(x)) then
									TriggerServerEvent("CEISetPerm", tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
									log('W', logTag, "CEISetPerm Called: " .. tostring(k) .. "|" ..tostring(players[k].player.permissions.levelInt[0]))
								end
								im.TreePop()
							else
								im.SameLine()
								im.Text(players[k].player.permissions.level)
							end
							im.Text("		whitelisted: " .. players[k].player.permissions.whitelisted)
							im.Text("		muted: " .. players[k].player.permissions.muted)
							im.Text("		muteReason: " .. players[k].player.permissions.muteReason)
							im.Text("		banned: " .. players[k].player.permissions.banned)
							if im.TreeNode1("group:##"..tostring(k)) then
								im.SameLine()
								im.Text(players[k].player.permissions.group)
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##newGroup", "Group Name", players[k].player.permissions.groupInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
								end
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
								if im.SmallButton("Remove##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|none")
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|none")
								end
								im.PopStyleColor(3)
								im.SameLine()
								im.ShowHelpMarker("Remove group or enter new Group Name and press Apply")
								im.TreePop()
							else
								im.SameLine()
								im.Text(players[k].player.permissions.group)
							end
							im.TreePop()
						end
						im.Separator()
						if im.TreeNode1("gamemode##"..tostring(k)) then
							im.Text("		mode: " .. players[k].player.gamemode.mode)
							im.Text("		source: " .. players[k].player.gamemode.source)
							im.Text("		queue: " .. players[k].player.gamemode.queue)
							im.Text("		locked: " .. players[k].player.gamemode.locked)
							im.TreePop()
						end
						im.TreePop()
					end
					im.Unindent()
				else
					im.PopStyleColor(3)
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("Ban##"..tostring(k)) then
						TriggerServerEvent("CEIBan",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIBan Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if im.SmallButton("TempBan##"..tostring(k)) then
						TriggerServerEvent("CEITempBan",tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEITempBan Called: " .. tostring(k) .. "|".. players[k].player.tempBanLength[0] .."|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							
							im.SameLine()
							if im.SmallButton("Teleport From##" .. tostring(k)) then
								M.teleportPlayerToVeh(players[k].player.playerName,tostring(k))
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport this player's current vehicle to you.")
						end
					end
					
					im.Unindent()
					
				end
			end
			im.EndTabItem()
		end
----------------------------------------------------------------------------------CONFIG TAB
		if im.BeginTabItem("Config") then
----------------------------------------------------------------------------------COBALT HEADER
			if im.CollapsingHeader1("Cobalt Essentials") then
				im.Indent()
			
				local vehiclePerms = config.cobalt.vehicles.vehiclePerms
				local vehiclePermsCounter = 0
				for a,b in pairs(vehiclePerms) do
					vehiclePermsCounter = vehiclePermsCounter + 1
				end
				
				if im.TreeNode1("vehiclePerms:") then
					im.SameLine()
					im.Text(tostring(vehiclePermsCounter))
					
					
					im.Text("	Add vehicle: ")
					im.SameLine()
					if im.InputTextWithHint("##newVehicle", "New Vehicle", config.cobalt.vehicles.newVehicleInput, 128) then
					end
					im.Text("	")
					im.SameLine()
					if im.SmallButton("Apply##newVehPerm") then
						TriggerServerEvent("CEISetNewVehiclePerm", ffi.string(config.cobalt.vehicles.newVehicleInput))
						log('W', logTag, "CEISetNewVehiclePerm Called: " .. ffi.string(config.cobalt.vehicles.newVehicleInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new vehicle and press Apply")
					
					im.ImGuiTextFilter_Draw(vehiclePermsFiltering.filter[0])
					
					for k,v in pairs(vehiclePerms) do
						
						for i = 0, im.GetLengthArrayCharPtr(vehiclePermsFiltering.lines) - 1 do
						
							if im.ImGuiTextFilter_PassFilter(vehiclePermsFiltering.filter[0], vehiclePermsFiltering.lines[i]) then
							
								if config.cobalt.vehicles.vehiclePerms[k].name == ffi.string(vehiclePermsFiltering.lines[i]) then
							
									if im.TreeNode1(ffi.string(vehiclePermsFiltering.lines[i]) .. ":") then
										im.SameLine()
										im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].level)
										im.Text("	")
										im.SameLine()
										im.PushItemWidth(100)
										if im.InputInt("", config.cobalt.vehicles.vehiclePerms[k].levelInt, 1) then
											TriggerServerEvent("CEISetVehiclePermLevel", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].levelInt[0]))
											log('W', logTag, "CEISetVehiclePermLevel Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].levelInt[0]))
										end
										im.PopItemWidth()
										
										im.SameLine()
										if im.SmallButton("Remove##vehPerm") then
											TriggerServerEvent("CEIRemoveVehiclePerm", config.cobalt.vehicles.vehiclePerms[k].name)
											log('W', logTag, "CEIRemoveVehiclePerm Called: " .. config.cobalt.vehicles.vehiclePerms[k].name)
										end
										im.SameLine()
										im.ShowHelpMarker("In-/Decrease vehicle permission level requirement or Remove vehicle entry")
										
										im.Text("	Add part: ")
										im.SameLine()
										if im.InputTextWithHint("##newPart", "New Part", config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput, 128) then
										end
										im.Text("	")
										im.SameLine()
										if im.SmallButton("Apply##newVehPart") then
											TriggerServerEvent("CEISetNewVehiclePart", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. ffi.string(config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput))
											log('W', logTag, "CEISetNewVehiclePart Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. ffi.string(config.cobalt.vehicles.vehiclePerms[k].partLevelnameInput))
										end
										im.SameLine()
										im.ShowHelpMarker("Enter new part and press Apply")
										
										if config.cobalt.vehicles.vehiclePerms[k].partLevel then
										
											
											local partName = string.gsub(config.cobalt.vehicles.vehiclePerms[k].partLevel.name, "partlevel:", "")
											if im.TreeNode1(partName .. ":") then
												im.SameLine()
												im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].partLevel.level)
												im.Text("	")
												im.SameLine()
												im.PushItemWidth(100)
												if im.InputInt("", config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt, 1) then
													TriggerServerEvent("CEISetVehiclePartLevel", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt[0]))
													log('W', logTag, "CEISetVehiclePartLevel Called: " ..  config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName .. "|" .. tostring(config.cobalt.vehicles.vehiclePerms[k].partLevel.levelInt[0]))
												end
												im.PopItemWidth()
												
												im.SameLine()
												if im.SmallButton("Remove##vehPart") then
													TriggerServerEvent("CEIRemoveVehiclePart", config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName)
													log('W', logTag, "CEIRemoveVehiclePart Called: " .. config.cobalt.vehicles.vehiclePerms[k].name .. "|" .. partName)
												end
												im.SameLine()
												im.ShowHelpMarker("In-/Decrease vehicle part permission level requirement or Remove vehicle part entry")
												
												im.TreePop()
											else
												im.SameLine()
												im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].partLevel.level)
											end
										end
										im.TreePop()
									else
										im.SameLine()
										im.Text("level: " .. config.cobalt.vehicles.vehiclePerms[k].level)
									end
								end
							end
						end
					end
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(vehiclePermsCounter))
				end
				im.Separator()
				
				local vehicleCaps = config.cobalt.permissions.vehicleCaps
				local vehicleCapsCounter = 0
				for a,b in pairs(vehicleCaps) do
					vehicleCapsCounter = vehicleCapsCounter + 1
				end
				
				if im.TreeNode1("vehicleCaps:") then
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
					for k,v in pairs(vehicleCaps) do
						if im.TreeNode1("level: " .. config.cobalt.permissions.vehicleCaps[k].level .. " =") then
							im.SameLine()
							im.Text(config.cobalt.permissions.vehicleCaps[k].vehicles .. " vehicles")
							im.Text("		")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("", config.cobalt.permissions.vehicleCaps[k].vehiclesInt, 1) then
								TriggerServerEvent("CEISetVehiclePerms", config.cobalt.permissions.vehicleCaps[k].level .. "|" .. tostring(config.cobalt.permissions.vehicleCaps[k].vehiclesInt[0]))
								log('W', logTag, "CEISetVehiclePerms Called: " .. config.cobalt.permissions.vehicleCaps[k].level .. "|" .. tostring(config.cobalt.permissions.vehicleCaps[k].vehiclesInt[0]))
							end
							im.PopItemWidth()
							im.SameLine()
							if im.SmallButton("Remove##"..tostring(k)) then
								TriggerServerEvent("CEIRemoveVehiclePermsLevel", config.cobalt.permissions.vehicleCaps[k].level)
								log('W', logTag, "CEIRemoveVehiclePermsLevel Called: " .. config.cobalt.permissions.vehicleCaps[k].level)
							end
							im.SameLine()
							im.ShowHelpMarker("In-/Decrease vehicles for level or Remove level entry")
							im.TreePop()
						else
							im.SameLine()
							im.Text(config.cobalt.permissions.vehicleCaps[k].vehicles .. " vehicles")
						end
					end
					im.Text("		Add level: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputTextWithHint("##newLevel", "New Level", config.cobalt.permissions.newLevelInput, 128) then
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetNewVehiclePermsLevel", ffi.string(config.cobalt.permissions.newLevelInput))
						log('W', logTag, "CEISetNewVehiclePermsLevel Called: " .. ffi.string(config.cobalt.permissions.newLevelInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new level and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
				end
				im.Separator()
				if im.TreeNode1("maxActivePlayers:") then
					im.SameLine()
					im.Text(config.cobalt.maxActivePlayers)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.cobalt.maxActivePlayersInt, 1) then
						log('W', logTag, "CEISetMaxActivePlayers Called: " .. tostring(config.cobalt.maxActivePlayersInt[0]))
						TriggerServerEvent("CEISetMaxActivePlayers",tostring(config.cobalt.maxActivePlayersInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.cobalt.maxActivePlayers)
				end
				im.Separator()
				local groups = config.cobalt.groups
				local groupCounter = 0
				for a,b in pairs(groups) do
					groupCounter = groupCounter + 1
				end
				if im.TreeNode1("groups:") then
					im.SameLine()
					im.Text(tostring(groupCounter))
					for k,v in pairs(groups) do
						im.Separator()
						if im.TreeNode1(config.cobalt.groups[k].groupName) then
							local groupPlayers = config.cobalt.groups[k].groupPlayers
							local groupPlayersCounter = 0
							for c,d in pairs(groupPlayers) do
								groupPlayersCounter = groupPlayersCounter + 1
							end
							if config.cobalt.groups[k].groupLevel then
								im.Text("		players: " .. tostring(groupPlayersCounter))
								for w,z in pairs(groupPlayers) do
									im.Text("		")
									im.SameLine()
									im.Text(groupPlayers[w])
									im.SameLine()
									im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
									im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
									im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
									if im.SmallButton("Remove##"..tostring(w)) then
										TriggerServerEvent("CEISetGroup", groupPlayers[w] .. "|none")
										log('W', logTag, "CEISetGroup Called: " .. groupPlayers[w] .. "|none")
									end
									im.PopStyleColor(3)
								end
								im.Text("		")
								im.Text("		level: ")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", config.cobalt.groups[k].groupLevelInt, 1) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
								end
								im.PopItemWidth()
							else
								im.Text("		level: ")
								im.SameLine()
								im.PushItemWidth(100)
								if im.InputInt("", config.cobalt.groups[k].groupLevelInt, 1) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|level|" .. tostring(config.cobalt.groups[k].groupLevelInt[0]))
								end
								im.PopItemWidth()
							end
							if config.cobalt.groups[k].groupWhitelisted then
								im.Text("		whitelisted: " .. config.cobalt.groups[k].groupWhitelisted)
								im.SameLine()
								if config.cobalt.groups[k].groupWhitelisted == "false" then
									if im.SmallButton("Whitelist##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|true")
									end
								elseif config.cobalt.groups[k].groupWhitelisted == "true" then
									if im.SmallButton("Unwhitelist##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|false")
									end
									
								end
							else
								im.Text("		whitelisted: null")
								im.SameLine()
								if im.SmallButton("Whitelist##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|whitelisted|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|whitelisted|true")
								end
								
							end
							if config.cobalt.groups[k].groupMuted then
								im.Text("		muted: " .. config.cobalt.groups[k].groupMuted)
								im.SameLine()
								if config.cobalt.groups[k].groupMuted == "false" then
									if im.SmallButton("Mute##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|true")
									end
								elseif config.cobalt.groups[k].groupMuted == "true" then
									if im.SmallButton("Unmute##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|false")
									end
									
								end
							else
								im.Text("		muted: null")
								im.SameLine()
								if im.SmallButton("Mute##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|muted|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|muted|true")
								end
								
							end
							if config.cobalt.groups[k].groupBanned then
								im.Text("		banned: " .. config.cobalt.groups[k].groupBanned)
								im.SameLine()
								if config.cobalt.groups[k].groupBanned == "false" then
									if im.SmallButton("Ban##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|true")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
									end
									
								elseif config.cobalt.groups[k].groupBanned == "true" then
									if im.SmallButton("Unban##"..tostring(k)) then
										TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|false")
										log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
									end
									
								end
							else
								im.Text("		banned: null")
								im.SameLine()
								if im.SmallButton("Ban##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banned|true")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banned|true")
								end
								
							end
							if config.cobalt.groups[k].groupBanReason then
								im.Text("		banReason: " .. config.cobalt.groups[k].groupBanReason)
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", config.cobalt.groups[k].groupBanReasonInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
								end
								im.SameLine()
								if im.SmallButton("Remove##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|none")
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|none")
								end
								im.SameLine()
								im.ShowHelpMarker("Remove banReason or enter new banReason and press Apply")
							else
								im.Text("		banReason: null")
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", config.cobalt.groups[k].groupBanReasonInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroupPerms", config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
									log('W', logTag, "CEISetGroupPerms Called: " .. config.cobalt.groups[k].groupName .. "|banReason|" .. ffi.string(config.cobalt.groups[k].groupBanReasonInput))
								end
								im.SameLine()
								im.ShowHelpMarker("Enter new banReason and press Apply")
							end
							im.Text("		")
							im.Text("		Add Player to Group: ")
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##groupPlayerName"..tostring(k), "Player Name", config.cobalt.groups[k].newGroupPlayerInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Add##groupPlayerName"..tostring(k)) then
								TriggerServerEvent("CEISetGroup", ffi.string(config.cobalt.groups[k].newGroupPlayerInput) .. "|" .. config.cobalt.groups[k].groupName)
								log('W', logTag, "CEISetGroup Called: add|" .. ffi.string(config.cobalt.groups[k].newGroupPlayerInput) .. "|" .. config.cobalt.groups[k].groupName)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter Player Name to Add to Group and press Apply")
							im.Text("		")
							im.Text("		")
							im.SameLine()
							im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
							im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
							im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
							if im.SmallButton("Remove Group##"..config.cobalt.groups[k].groupName) then
								TriggerServerEvent("CEIRemoveGroup", config.cobalt.groups[k].groupName)
								log('W', logTag, "CEIRemoveGroup Called: " .. config.cobalt.groups[k].groupName)
							end
							im.PopStyleColor(3)
							im.SameLine()
							im.ShowHelpMarker("Remove Group... CAREFUL WITH THIS")
							im.TreePop()
							im.Text("		")
						end
					end
					im.TreePop()
					im.Separator()
					im.Text("		Add Group: ")
					im.SameLine()
					if im.InputTextWithHint("##groupName", "Group Name", config.cobalt.newGroupInput, 128) then
					end
					im.Indent()
					im.Indent()
					im.Indent()
					im.Text("		")
					im.SameLine()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetNewGroup", ffi.string(config.cobalt.newGroupInput))
						log('W', logTag, "CEISetNewGroup Called: " .. ffi.string(config.cobalt.newGroupInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Group Name and press Apply")
					im.Unindent()
					im.Unindent()
					im.Unindent()
				else
					im.SameLine()
					im.Text(tostring(groupCounter))
				end
				im.Separator()
				local whitePlayers = config.cobalt.whitelistedPlayers
				local whitePlayersCounter = 0
				for a,b in pairs(whitePlayers) do
					whitePlayersCounter = whitePlayersCounter + 1
				end
				if im.TreeNode1("whitelisted players:") then
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
					for x,y in pairs(whitePlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.cobalt.whitelistedPlayers[x].name)
						im.SameLine()
						if im.SmallButton("Remove##"..tostring(x)) then
							TriggerServerEvent("CEIWhitelist", "remove|" .. config.cobalt.whitelistedPlayers[x].name)
							log('W', logTag, "CEIWhitelist Called: remove|" .. config.cobalt.whitelistedPlayers[x].name)
						end
					end
					im.Text("		Add Name to Whitelist: ")
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##whitelistName", "Player Name", config.cobalt.whitelistNameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Add##whitelistName") then
						TriggerServerEvent("CEIWhitelist", "add|" .. ffi.string(config.cobalt.whitelistNameInput))
						log('W', logTag, "CEIWhitelist Called: add|" .. ffi.string(config.cobalt.whitelistNameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter Player Name to Add to Whitelist and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
				end
				im.Text("		")
				im.SameLine()
				if config.cobalt.enableWhitelist == "false" then
					if im.SmallButton("Enable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","enable")
						log('W', logTag, "CEIWhitelist Called: enable")
					end
				elseif config.cobalt.enableWhitelist == "true" then
					if im.SmallButton("Disable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","disable")
						log('W', logTag, "CEIWhitelist Called: disable")
					end
				end
				
				im.Separator()
				im.Text('		Default CEI State: ')
				im.SameLine()
				if config.cobalt.interface.defaultState == "true" then
					if im.SmallButton("Shown##") then
						TriggerServerEvent("CEISetDefaultState","false")
						log('W', logTag, "CEISetDefaultState Called: false")
					end
				elseif config.cobalt.interface.defaultState == "false" then
					if im.SmallButton("Hidden##") then
						TriggerServerEvent("CEISetDefaultState","true")
						log('W', logTag, "CEISetDefaultState Called: true")
					end
				end
				
				--[[im.Separator()
				if im.TreeNode1("miscellaneous") then
					im.Separator()
					im.Indent()
					im.Text("enableColors: "..config.cobalt.enableColors)
					im.SameLine()
					if config.cobalt.enableColors == "false" then
						if im.SmallButton("Enable Colors##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableColors|enable")
							log('W', logTag, "CEIConfig Called: enableColors|enable")
						end
					elseif config.cobalt.enableColors == "true" then
						if im.SmallButton("Disable Colors##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableColors|disable")
							log('W', logTag, "CEIConfig Called: enableColors|disable")
						end
					end
					im.Separator()
					im.Text("enableDebug: "..config.cobalt.enableDebug)
					im.SameLine()
					if config.cobalt.enableDebug == "false" then
						if im.SmallButton("Enable Debug##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableDebug|enable")
							log('W', logTag, "CEIConfig Called: enableDebug|enable")
						end
					elseif config.cobalt.enableDebug == "true" then
						if im.SmallButton("Disable Debug##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","enableDebug|disable")
							log('W', logTag, "CEIConfig Called: enableDebug|disable")
						end
					end
					im.Separator()
					im.Text("RCONenabled: "..config.cobalt.RCONenabled)
					im.SameLine()
					if config.cobalt.RCONenabled == "false" then
						if im.SmallButton("Enable RCON##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONenabled|enable")
							log('W', logTag, "CEIConfig Called: RCONenabled|enable")
						end
					elseif config.cobalt.RCONenabled == "true" then
						if im.SmallButton("Disable RCON##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONenabled|disable")
							log('W', logTag, "CEIConfig Called: RCONenabled|disable")
						end
					end
					im.Separator()
					im.Text("RCONkeepAliveTick: "..config.cobalt.RCONkeepAliveTick)
					im.SameLine()
					if config.cobalt.RCONkeepAliveTick == "false" then
						if im.SmallButton("Enable RCONkeepAliveTick##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONkeepAliveTick|enable")
							log('W', logTag, "CEIConfig Called: RCONkeepAliveTick|enable")
						end
					elseif config.cobalt.RCONkeepAliveTick == "true" then
						if im.SmallButton("Disable RCONkeepAliveTick##"..tostring(k)) then
							TriggerServerEvent("CEIConfig","RCONkeepAliveTick|disable")
							log('W', logTag, "CEIConfig Called: RCONkeepAliveTick|disable")
						end
					end
					im.Separator()
					im.Text("RCONpassword: "..config.cobalt.RCONpassword)
					if im.InputTextWithHint("##RCONpassword", "New RCON Password", config.cobalt.newRCONpassword, 128) then
					end
					if im.SmallButton("Apply##RCONpassword") then
						TriggerServerEvent("CEIConfig", "RCONpassword|" .. ffi.string(config.cobalt.newRCONpassword))
						log('W', logTag, "CEIConfig Called: RCONpassword|" .. ffi.string(config.cobalt.newRCONpassword))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new RCON Password and press Apply")
					im.Separator()
					im.Text("RCONport: "..config.cobalt.RCONport)
					if im.InputTextWithHint("##RCONport", "New RCON Port", config.cobalt.newRCONport, 128) then
					end
					if im.SmallButton("Apply##RCONport") then
						TriggerServerEvent("CEIConfig", "RCONport|" .. ffi.string(config.cobalt.newRCONport))
						log('W', logTag, "CEIConfig Called: RCONport|" .. ffi.string(config.cobalt.newRCONport))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new RCON Port and press Apply")
					im.Separator()
					im.Text("CobaltDBport: "..config.cobalt.CobaltDBport)
					if im.InputTextWithHint("##CobaltDBport", "New CobaltDB Port", config.cobalt.newCobaltDBport, 128) then
					end
					if im.SmallButton("Apply##CobaltDBport") then
						TriggerServerEvent("CEIConfig", "CobaltDBport|" .. ffi.string(config.cobalt.newCobaltDBport))
						log('W', logTag, "CEIConfig Called: CobaltDBport|" .. ffi.string(config.cobalt.newCobaltDBport))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new CobaltDB Port and press Apply")
					im.Text("		")
					im.Unindent()
					im.TreePop()
				end]]
				im.Unindent()
			end
----------------------------------------------------------------------------------SERVER HEADER
			if im.CollapsingHeader1("Server") then
				im.Indent()
				if im.TreeNode1("name:") then
					im.SameLine()
					im.Text(config.server.name)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##name", "Server Name", config.server.nameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg", "Name|" .. ffi.string(config.server.nameInput))
						log('W', logTag, "CEISetCfg Called: Name|" .. ffi.string(config.server.nameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Name and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.name)
				end
				im.Separator()
				if im.TreeNode1("maxCars:") then
					im.SameLine()
					im.Text(config.server.maxCars)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxCarsInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxCars|" .. tostring(config.server.maxCarsInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxCars|" .. tostring(config.server.maxCarsInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxCars)
				end
				im.Separator()
				if im.TreeNode1("maxPlayers:") then
					im.SameLine()
					im.Text(config.server.maxPlayers)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxPlayersInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxPlayers)
				end
				im.Separator()
				if im.TreeNode1("map:") then
					im.SameLine()
					im.Text(config.server.map)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##map", "Map Path", config.server.mapInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Map|" .. ffi.string(config.server.mapInput))
						log('W', logTag, "CEISetCfg Called: Map|" ..  ffi.string(config.server.mapInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Map and press Apply (REQUIRES REJOIN FOR EFFECT)")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.map)
				end
				im.Separator()
				if im.TreeNode1("description:") then
					im.SameLine()
					im.Text(config.server.description)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##description", "Server Description", config.server.descriptionInput, 256) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Description|" .. ffi.string(config.server.descriptionInput))
						log('W', logTag, "CEISetCfg Called: Description|" ..  ffi.string(config.server.descriptionInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Description and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.description)
				end
				im.Separator()
				im.Text("		debug: " .. config.server.debug)
				im.SameLine()
				if config.server.debug == "false" then
					if im.SmallButton("Enable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|true")
						log('W', logTag, "CEISetCfg Called: Debug|true")
					end
				elseif config.server.debug == "true" then
					if im.SmallButton("Disable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|false")
						log('W', logTag, "CEISetCfg Called: Debug|false")
					end
					
				end
				im.Separator()
				im.Text("		private: " .. config.server.private)
				im.SameLine()
				if config.server.private == "false" then
					if im.SmallButton("Set Private##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|true")
						log('W', logTag, "CEISetCfg Called: private|true")
					end
				elseif config.server.private == "true" then
					if im.SmallButton("Set Public##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|false")
						log('W', logTag, "CEISetCfg Called: Private|false")
					end
				end
				im.Text("		")
				im.Text("		")
				im.SameLine()
				im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
				if im.SmallButton("Stop/Restart##"..tostring(k)) then
					TriggerServerEvent("CEIStop","Good-bye!")
					log('W', logTag, "CEIStop Called: Goodbye!")
				end
				im.PopStyleColor(3)
				im.SameLine()
				im.ShowHelpMarker("Good-bye!")
				im.Unindent()
				
			end
----------------------------------------------------------------------------------NAMETAGS HEADER
			if im.CollapsingHeader1("Nametags") then
			
				local nametagWhitelist = config.nametags.whitelistedPlayers
				local nametagWhitelistCounter = 0
				for a,b in pairs(nametagWhitelist) do
					nametagWhitelistCounter = nametagWhitelistCounter + 1
				end
			
				im.Indent()
				if im.TreeNode1("Nametag Settings") then
					im.Text("		")
					im.SameLine()
					im.Text("Nametag Blocking: ")
					if config.nametags.settings.blockingEnabled == "true" then
						im.SameLine()
						if im.SmallButton("Enabled##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "false")
							log('W', logTag, "CEINametagSetting: false")
							TriggerServerEvent("txNametagBlockerTimeout", "0")
							log('W', logTag, "txNametagBlockerTimeout: 0")
						end
					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Disabled##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Blocking Timeout: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##nametagBlockingTimeout", config.nametags.settings.blockingTimeoutInt, 1) then
						if config.nametags.settings.blockingTimeoutInt[0] < 0 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(0)
						elseif config.nametags.settings.blockingTimeoutInt[0] > 3600 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(3600)
						end
						TriggerServerEvent("CEINametagSetting", tostring(config.nametags.settings.blockingTimeoutInt[0]))
						log('W', logTag, "CEINametagSetting Called: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
					end
					im.PopItemWidth()
					
					if config.nametags.settings.blockingEnabled == "true" then

					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Start##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
							TriggerServerEvent("txNametagBlockerTimeout", tostring(config.nametags.settings.blockingTimeoutInt[0]))
							log('W', logTag, "txNametagBlockerTimeout: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
						end
					end
					
					im.TreePop()
				else
				end
				im.Separator()
				if im.TreeNode1("Nametag Whitelist: ") then
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
					
					for k,v in pairs(config.nametags.whitelistedPlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.nametags.whitelistedPlayers[k].name)
						im.SameLine()
						if im.SmallButton("Remove##"..config.nametags.whitelistedPlayers[k].name) then
							TriggerServerEvent("CEIRemoveNametagWhitelist", config.nametags.whitelistedPlayers[k].name)
							log('W', logTag, "CEIRemoveNametagWhitelist: " .. config.nametags.whitelistedPlayers[k].name)
						end
					end
					
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##whitelistName", "Whitelist Name", config.nametags.whitelistNameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##nametagWhitleist") then
						TriggerServerEvent("CEISetNametagWhitelist", ffi.string(config.nametags.whitelistNameInput))
						log('W', logTag, "CEISetNametagWhitelist Called: " .. ffi.string(config.nametags.whitelistNameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Whitelist Name and press Apply")
				
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
				end
				im.Unindent()
				
			end
			
			im.EndTabItem()
		end
		
----------------------------------------------------------------------------------ENVIRONMENT TAB
		if im.BeginTabItem("Environment") then
					
			im.Indent()

			if im.SmallButton("Reset All##ENV") then
				TriggerServerEvent("CEISetEnv", "all|default")
				log('W', logTag, "CEISetEnv Called: all|default")
			end
			
			if im.TreeNode1("Sun") then
				im.SameLine()
				if im.SmallButton("Reset##SUN") then
					TriggerServerEvent("CEISetEnv", "allSun|default")
					log('W', logTag, "CEISetEnv Called: allSun|default")
				end
				im.Indent()
					
				im.Text("Time Play: ")
				im.SameLine()
				local timePlay = environment.timePlay
				if timePlay == "false" then
					if im.SmallButton("Play") then
						TriggerServerEvent("CEISetEnv", "timePlay|true")
						log('W', logTag, "CEISetEnv Called: timePlay|true")
					end
				elseif timePlay == "true" then
					if im.SmallButton("Stop") then
						local timeOfDay = core_environment.getTimeOfDay()
						TriggerServerEvent("CEISetEnv", "ToD|" .. tostring(timeOfDay.time))
						log('W', logTag, "CEISetEnv Called: ToD|" .. tostring(timeOfDay.time))
						TriggerServerEvent("CEISetEnv", "timePlay|false")
						log('W', logTag, "CEISetEnv Called: timePlay|false")
					end
				end
				
				im.Text("Time of Day: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##ToD", environment.todVal, 0.001, 0.01) then
					if environment.todVal[0] < 0 then
						environment.todVal = im.FloatPtr(1)
					elseif environment.todVal[0] > 1 then
						environment.todVal = im.FloatPtr(0)
					end
					environment.todVal = im.FloatPtr(environment.todVal)
					TriggerServerEvent("CEISetEnv", "ToD|" .. tostring(environment.todVal[0]))
					log('W', logTag, "CEISetEnv Called: ToD|" .. tostring(environment.todVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##ToD") then
					TriggerServerEvent("CEISetEnv", "ToD|default")
					log('W', logTag, "CEISetEnv Called: ToD|default")
				end
				
				im.Text("Day Scale: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##dayScale", environment.dayScaleVal, 0.01, 0.1) then
					if environment.dayScaleVal[0] < 0.01 then
						environment.dayScaleVal = im.FloatPtr(0.01)
					elseif environment.dayScaleVal[0] > 100 then
						environment.dayScaleVal = im.FloatPtr(100)
					end
					environment.dayScaleVal = im.FloatPtr(environment.dayScaleVal)
					TriggerServerEvent("CEISetEnv", "dayScale|" .. tostring(environment.dayScaleVal[0]))
					log('W', logTag, "CEISetEnv Called: dayScale|" .. tostring(environment.dayScaleVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Realtime##DS") then
					TriggerServerEvent("CEISetEnv", "dayScale|0.020855")
					log('W', logTag, "CEISetEnv Called: dayScale|0.020855")
				end
				im.SameLine()
				if im.SmallButton("Reset##DS") then
					TriggerServerEvent("CEISetEnv", "dayScale|default")
					log('W', logTag, "CEISetEnv Called: dayScale|default")
				end
				
				im.Text("Night Scale: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##nightScale", environment.nightScaleVal, 0.01, 0.1) then
					if environment.nightScaleVal[0] < 0.01 then
						environment.nightScaleVal = im.FloatPtr(0.01)
					elseif environment.nightScaleVal[0] > 100 then
						environment.nightScaleVal = im.FloatPtr(100)
					end
					environment.nightScaleVal = im.FloatPtr(environment.nightScaleVal)
					TriggerServerEvent("CEISetEnv", "nightScale|" .. tostring(environment.nightScaleVal[0]))
					log('W', logTag, "CEISetEnv Called: nightScale|" .. tostring(environment.nightScaleVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Realtime##NS") then
					TriggerServerEvent("CEISetEnv", "nightScale|0.020855")
					log('W', logTag, "CEISetEnv Called: nightScale|0.020855")
				end
				im.SameLine()
				if im.SmallButton("Reset##NS") then
					TriggerServerEvent("CEISetEnv", "nightScale|default")
					log('W', logTag, "CEISetEnv Called: nightScale|default")
				end
				
				im.Text("Azimuth Override: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##azimuthOverride", environment.azimuthOverrideVal, 0.001, 0.01) then
					if environment.azimuthOverrideVal[0] < 0 then
						environment.azimuthOverrideVal = im.FloatPtr(6.25)
					elseif environment.azimuthOverrideVal[0] > 6.25 then
						environment.azimuthOverrideVal = im.FloatPtr(0)
					end
					environment.azimuthOverrideVal = im.FloatPtr(environment.azimuthOverrideVal)
					TriggerServerEvent("CEISetEnv", "azimuthOverride|" .. tostring(environment.azimuthOverrideVal[0]))
					log('W', logTag, "CEISetEnv Called: azimuthOverride|" .. tostring(environment.azimuthOverrideVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##AO") then
					TriggerServerEvent("CEISetEnv", "azimuthOverride|default")
					log('W', logTag, "CEISetEnv Called: azimuthOverride|default")
				end
				
				im.Text("Sun Size: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##sunSize", environment.sunSizeVal, 0.01, 0.1) then
					if environment.sunSizeVal[0] < 0 then
						environment.sunSizeVal = im.FloatPtr(0)
					elseif environment.sunSizeVal[0] > 100 then
						environment.sunSizeVal = im.FloatPtr(100)
					end
					environment.sunSizeVal = im.FloatPtr(environment.sunSizeVal)
					TriggerServerEvent("CEISetEnv", "sunSize|" .. tostring(environment.sunSizeVal[0]))
					log('W', logTag, "CEISetEnv Called: sunSize|" .. tostring(environment.sunSizeVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SS") then
					TriggerServerEvent("CEISetEnv", "sunSize|default")
					log('W', logTag, "CEISetEnv Called: sunSize|default")
				end
				
				im.Text("Sky Brightness: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##skyBrightness", environment.skyBrightnessVal, 0.1, 1.0) then
					if environment.skyBrightnessVal[0] < 0 then
						environment.skyBrightnessVal = im.FloatPtr(0)
					elseif environment.skyBrightnessVal[0] > 200 then
						environment.skyBrightnessVal = im.FloatPtr(200)
					end
					environment.skyBrightnessVal = im.FloatPtr(environment.skyBrightnessVal)
					TriggerServerEvent("CEISetEnv", "skyBrightness|" .. tostring(environment.skyBrightnessVal[0]))
					log('W', logTag, "CEISetEnv Called: skyBrightness|" .. tostring(environment.skyBrightnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SB") then
					TriggerServerEvent("CEISetEnv", "skyBrightness|default")
					log('W', logTag, "CEISetEnv Called: skyBrightness|default")
				end
				
				im.Text("Sunlight Brightness: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##sunLightBrightness", environment.sunLightBrightnessVal, 0.01, 0.1) then
					if environment.sunLightBrightnessVal[0] < 0 then
						environment.sunLightBrightnessVal = im.FloatPtr(0)
					elseif environment.sunLightBrightnessVal[0] > 10 then
						environment.sunLightBrightnessVal = im.FloatPtr(10)
					end
					environment.sunLightBrightnessVal = im.FloatPtr(environment.sunLightBrightnessVal)
					TriggerServerEvent("CEISetEnv", "sunLightBrightness|" .. tostring(environment.sunLightBrightnessVal[0]))
					log('W', logTag, "CEISetEnv Called: sunLightBrightness|" .. tostring(environment.sunLightBrightnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##GB") then
					TriggerServerEvent("CEISetEnv", "sunLightBrightness|default")
					log('W', logTag, "CEISetEnv Called: sunLightBrightness|default")
				end
				
				im.Text("Exposure: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##exposure", environment.exposureVal, 0.01, 0.1) then
					if environment.exposureVal[0] < 0 then
						environment.exposureVal = im.FloatPtr(0)
					elseif environment.exposureVal[0] > 3 then
						environment.exposureVal = im.FloatPtr(3)
					end
					environment.exposureVal = im.FloatPtr(environment.exposureVal)
					TriggerServerEvent("CEISetEnv", "exposure|" .. tostring(environment.exposureVal[0]))
					log('W', logTag, "CEISetEnv Called: exposure|" .. tostring(environment.exposureVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##EX") then
					TriggerServerEvent("CEISetEnv", "exposure|default")
					log('W', logTag, "CEISetEnv Called: exposure|default")
				end
				
				im.Text("Shadow Distance: ")
				im.SameLine()
				im.PushItemWidth(120)
				if im.InputFloat("##shadowDistance", environment.shadowDistanceVal, 0.001, 0.01) then
					if environment.shadowDistanceVal[0] < 0 then
						environment.shadowDistanceVal = im.FloatPtr(0)
					elseif environment.shadowDistanceVal[0] > 12800 then
						environment.shadowDistanceVal = im.FloatPtr(12800)
					end
					environment.shadowDistanceVal = im.FloatPtr(environment.shadowDistanceVal)
					TriggerServerEvent("CEISetEnv", "shadowDistance|" .. tostring(environment.shadowDistanceVal[0]))
					log('W', logTag, "CEISetEnv Called: shadowDistance|" .. tostring(environment.shadowDistanceVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SD") then
					TriggerServerEvent("CEISetEnv", "shadowDistance|default")
					log('W', logTag, "CEISetEnv Called: shadowDistance|default")
				end
				
				im.Text("Shadow Softness: ")
				im.SameLine()
				im.PushItemWidth(110)
				if im.InputFloat("##shadowSoftness", environment.shadowSoftnessVal, 0.001, 0.01) then
					if environment.shadowSoftnessVal[0] < -10 then
						environment.shadowSoftnessVal = im.FloatPtr(-10)
					elseif environment.shadowSoftnessVal[0] > 10 then
						environment.shadowSoftnessVal = im.FloatPtr(10)
					end
					environment.shadowSoftnessVal = im.FloatPtr(environment.shadowSoftnessVal)
					TriggerServerEvent("CEISetEnv", "shadowSoftness|" .. tostring(environment.shadowSoftnessVal[0]))
					log('W', logTag, "CEISetEnv Called: shadowSoftness|" .. tostring(environment.shadowSoftnessVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SSFT") then
					TriggerServerEvent("CEISetEnv", "shadowSoftness|default")
					log('W', logTag, "CEISetEnv Called: shadowSoftness|default")
				end
				
				im.Text("Shadow Splits: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##shadowSplits", environment.shadowSplitsInt, 1) then
					if environment.shadowSplitsInt[0] < 0 then
						environment.shadowSplitsInt = im.IntPtr(0)
					elseif environment.shadowSplitsInt[0] > 4 then
						environment.shadowSplitsInt = im.IntPtr(4)
					end
					TriggerServerEvent("CEISetEnv", "shadowSplits|" .. tostring(environment.shadowSplitsInt[0]))
					log('W', logTag, "CEISetEnv Called: shadowSplits|" .. tostring(environment.shadowSplitsInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##SSPL") then
					TriggerServerEvent("CEISetEnv", "shadowSplits|default")
					log('W', logTag, "CEISetEnv Called: shadowSplits|default")
				end
				
				
				
				
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##SUN") then
					TriggerServerEvent("CEISetEnv", "allSun|default")
					log('W', logTag, "CEISetEnv Called: allSun|default")
				end
			end
			
			if im.TreeNode1("Weather") then
				im.SameLine()
				if im.SmallButton("Reset##WET") then
					TriggerServerEvent("CEISetEnv", "allWeather|default")
					log('W', logTag, "CEISetEnv Called: allWeather|default")
				end
				
				im.Indent()
				
				im.Text("Fog Density: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##fogDensity", environment.fogDensityVal, 0.00001, 0.0001) then
					if environment.fogDensityVal[0] < 0.00001 then
						environment.fogDensityVal = im.FloatPtr(0.00001)
					elseif environment.fogDensityVal[0] > 0.01 then
						environment.fogDensityVal = im.FloatPtr(0.01)
					end
					TriggerServerEvent("CEISetEnv", "fogDensity|" .. tostring(environment.fogDensityVal[0]))
					log('W', logTag, "CEISetEnv Called: fogDensity|" .. tostring(environment.fogDensityVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##FD") then
					TriggerServerEvent("CEISetEnv", "fogDensity|default")
					log('W', logTag, "CEISetEnv Called: fogDensity|default")
				end
				
				im.Text("Fog Distance: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##fogDensityOffset", environment.fogDensityOffsetVal, 0.001, 0.01) then
					if environment.fogDensityOffsetVal[0] < 0 then
						environment.fogDensityOffsetVal = im.FloatPtr(0)
					elseif environment.fogDensityOffsetVal[0] > 100 then
						environment.fogDensityOffsetVal = im.FloatPtr(100)
					end
					TriggerServerEvent("CEISetEnv", "fogDensityOffset|" .. tostring(environment.fogDensityOffsetVal[0]))
					log('W', logTag, "CEISetEnv Called: fogDensityOffset|" .. tostring(environment.fogDensityOffsetVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##FDO") then
					TriggerServerEvent("CEISetEnv", "fogDensityOffset|default")
					log('W', logTag, "CEISetEnv Called: fogDensityOffset|default")
				end
				
				im.Text("Cloud Cover: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##cloudCover", environment.cloudCoverVal, 0.01, 0.1) then
					if environment.cloudCoverVal[0] < 0 then
						environment.cloudCoverVal = im.FloatPtr(0)
					elseif environment.cloudCoverVal[0] > 5 then
						environment.cloudCoverVal = im.FloatPtr(5)
					end
					TriggerServerEvent("CEISetEnv", "cloudCover|" .. tostring(environment.cloudCoverVal[0]))
					log('W', logTag, "CEISetEnv Called: cloudCover|" .. tostring(environment.cloudCoverVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##CC") then
					TriggerServerEvent("CEISetEnv", "cloudCover|default")
					log('W', logTag, "CEISetEnv Called: cloudCover|default")
				end
				
				im.Text("Cloud Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##cloudSpeed", environment.cloudSpeedVal, 0.01, 0.1) then
					if environment.cloudSpeedVal[0] < 0 then
						environment.cloudSpeedVal = im.FloatPtr(0)
					elseif environment.cloudSpeedVal[0] > 10 then
						environment.cloudSpeedVal = im.FloatPtr(10)
					end
					TriggerServerEvent("CEISetEnv", "cloudSpeed|" .. tostring(environment.cloudSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: cloudSpeed|" .. tostring(environment.cloudSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##CS") then
					TriggerServerEvent("CEISetEnv", "cloudSpeed|default")
					log('W', logTag, "CEISetEnv Called: cloudSpeed|default")
				end
				
				im.Text("Rain Drops: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##rainDrops", environment.rainDropsInt, 1, 10) then
					if environment.rainDropsInt[0] < 0 then
						environment.rainDropsInt = im.IntPtr(0)
					elseif environment.rainDropsInt[0] > 20000 then
						environment.rainDropsInt = im.IntPtr(20000)
					end
					TriggerServerEvent("CEISetEnv", "rainDrops|" .. tostring(environment.rainDropsInt[0]))
					log('W', logTag, "CEISetEnv Called: rainDrops|" .. tostring(environment.rainDropsInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##RD") then
					TriggerServerEvent("CEISetEnv", "rainDrops|default")
					log('W', logTag, "CEISetEnv Called: rainDrops|default")
				end
				
				im.Text("Drop Size: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropSize", environment.dropSizeVal, 0.001, 0.01) then
					if environment.dropSizeVal[0] < 0 then
						environment.dropSizeVal = im.FloatPtr(0)
					elseif environment.dropSizeVal[0] > 2 then
						environment.dropSizeVal = im.FloatPtr(2)
					end
					environment.dropSizeVal = im.FloatPtr(environment.dropSizeVal)
					TriggerServerEvent("CEISetEnv", "dropSize|" .. tostring(environment.dropSizeVal[0]))
					log('W', logTag, "CEISetEnv Called: dropSize|" .. tostring(environment.dropSizeVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DSZ") then
					TriggerServerEvent("CEISetEnv", "dropSize|default")
					log('W', logTag, "CEISetEnv Called: dropSize|default")
				end
				
				im.Text("Drop Min Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropMinSpeed", environment.dropMinSpeedVal, 0.001, 0.01) then
					if environment.dropMinSpeedVal[0] < 0 then
						environment.dropMinSpeedVal = im.FloatPtr(0)
					elseif environment.dropMinSpeedVal[0] > 2 then
						environment.dropMinSpeedVal = im.FloatPtr(2)
					end
					environment.dropMinSpeedVal = im.FloatPtr(environment.dropMinSpeedVal)
					TriggerServerEvent("CEISetEnv", "dropMinSpeed|" .. tostring(environment.dropMinSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: dropMinSpeed|" .. tostring(environment.dropMinSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DMNS") then
					TriggerServerEvent("CEISetEnv", "dropMinSpeed|default")
					log('W', logTag, "CEISetEnv Called: dropMinSpeed|default")
				end
				
				im.Text("Drop Max Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##dropMaxSpeed", environment.dropMaxSpeedVal, 0.001, 0.01) then
					if environment.dropMaxSpeedVal[0] < 0 then
						environment.dropMaxSpeedVal = im.FloatPtr(0)
					elseif environment.dropMaxSpeedVal[0] > 2 then
						environment.dropMaxSpeedVal = im.FloatPtr(2)
					end
					environment.dropMaxSpeedVal = im.FloatPtr(environment.dropMaxSpeedVal)
					TriggerServerEvent("CEISetEnv", "dropMaxSpeed|" .. tostring(environment.dropMaxSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: dropMaxSpeed|" .. tostring(environment.dropMaxSpeedVal[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##DMXS") then
					TriggerServerEvent("CEISetEnv", "dropMaxSpeed|default")
					log('W', logTag, "CEISetEnv Called: dropMaxSpeed|default")
				end
				
				im.Text("Precipitation Type: ")
				im.SameLine()
				local precipType = environment.precipType
				if precipType == "rain_medium" then
					if im.SmallButton("Medium Rain") then
						TriggerServerEvent("CEISetEnv", "precipType|rain_drop")
						log('W', logTag, "CEISetEnv Called: precipType|rain_drop")
					end
				elseif precipType == "rain_drop" then
					if im.SmallButton("Light Rain") then
						TriggerServerEvent("CEISetEnv", "precipType|Snow_menu")
						log('W', logTag, "CEISetEnv Called: precipType|Snow_menu")
					end
				elseif precipType == "Snow_menu" then
					if im.SmallButton("Snow") then
						TriggerServerEvent("CEISetEnv", "precipType|rain_medium")
						log('W', logTag, "CEISetEnv Called: precipType|rain_medium")
					end
				end
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##WET") then
					TriggerServerEvent("CEISetEnv", "allWeather|default")
					log('W', logTag, "CEISetEnv Called: allWeather|default")
				end
			end
			
			if im.TreeNode1("Simulation") then
				im.SameLine()
				if im.SmallButton("Reset##SIM") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
			
				im.Indent()
				
				im.Text("Teleport Timeout: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputInt("##teleportTimeout", environment.teleportTimeoutInt, 1, 10) then
					if environment.teleportTimeoutInt[0] < 0 then
						environment.teleportTimeoutInt = im.IntPtr(0)
					elseif environment.teleportTimeoutInt[0] > 60 then
						environment.teleportTimeoutInt = im.IntPtr(60)
					end
					TriggerServerEvent("CEISetEnv", "teleportTimeout|" .. tostring(environment.teleportTimeoutInt[0]))
					log('W', logTag, "CEISetEnv Called: teleportTimeout|" .. tostring(environment.teleportTimeoutInt[0]))
				end
				im.PopItemWidth()
				im.SameLine()
				if im.SmallButton("Reset##TLPT") then
					TriggerServerEvent("CEISetEnv", "teleportTimeout|default")
					log('W', logTag, "CEISetEnv Called: teleportTimeout|default")
				end
				
				im.Text("Simulation Speed: ")
				im.SameLine()
				im.PushItemWidth(100)
				if im.InputFloat("##simSpeed", environment.simSpeedVal, 0.001, 0.1) then
					if environment.simSpeedVal[0] < 0.01 then
						environment.simSpeedVal = im.FloatPtr(0.01)
					elseif environment.simSpeedVal[0] > 5 then
						environment.simSpeedVal = im.FloatPtr(5)
					end
					environment.simSpeedVal = im.FloatPtr(environment.simSpeedVal)
					TriggerServerEvent("CEISetEnv", "simSpeed|" .. tostring(environment.simSpeedVal[0]))
					log('W', logTag, "CEISetEnv Called: simSpeed|" .. tostring(environment.simSpeedVal[0]))
				end
				im.PopItemWidth()

				if im.SmallButton("0.5X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|2")
					log('W', logTag, "CEISetEnv Called: simSpeed|2")
				end
				im.SameLine()
				if im.SmallButton("Real") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
				im.SameLine()
				if im.SmallButton("2X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.5")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.5")
				end
				im.SameLine()
				if im.SmallButton("4X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.25")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.25")
				end
				im.SameLine()
				if im.SmallButton("10X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.1")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.1")
				end
				im.SameLine()
				if im.SmallButton("100X") then
					TriggerServerEvent("CEISetEnv", "simSpeed|0.01")
					log('W', logTag, "CEISetEnv Called: simSpeed|0.01")
				end
				
				im.TreePop()
				im.Unindent()
			else
				im.SameLine()
				if im.SmallButton("Reset##SIM") then
					TriggerServerEvent("CEISetEnv", "simSpeed|default")
					log('W', logTag, "CEISetEnv Called: simSpeed|default")
				end
			end
		
			if im.TreeNode1("Gravity") then
				im.SameLine()
				if im.SmallButton("Reset##GRV") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
				im.Indent()
				
				im.Text("		")
				im.SameLine()
				im.PushItemWidth(130)
				if im.InputFloat("##gravity", environment.gravityVal, 0.001, 0.1) then
					if environment.gravityVal[0] < -280 then
						environment.gravityVal = im.FloatPtr(-280)
					elseif environment.gravityVal[0] > 10 then
						environment.gravityVal = im.FloatPtr(10)
					end
					environment.gravityVal = im.FloatPtr(environment.gravityVal)
					TriggerServerEvent("CEISetEnv", "gravity|" .. tostring(environment.gravityVal[0]))
					log('W', logTag, "CEISetEnv Called: gravity|" .. tostring(environment.gravityVal[0]))
				end
				im.PopItemWidth()

				if im.SmallButton("Zero") then
					TriggerServerEvent("CEISetEnv", "gravity|0")
					log('W', logTag, "CEISetEnv Called: gravity|0")
				end
				im.SameLine()
				if im.SmallButton("Earth") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
				im.SameLine()
				if im.SmallButton("Moon") then
					TriggerServerEvent("CEISetEnv", "gravity|-1.62")
					log('W', logTag, "CEISetEnv Called: gravity|-1.62")
				end

				if im.SmallButton("Mars") then
					TriggerServerEvent("CEISetEnv", "gravity|-3.71")
					log('W', logTag, "CEISetEnv Called: gravity|-3.71")
				end
				im.SameLine()
				if im.SmallButton("Sun") then
					TriggerServerEvent("CEISetEnv", "gravity|-274")
					log('W', logTag, "CEISetEnv Called: gravity|-274")
				end
				im.SameLine()
				if im.SmallButton("Jupiter") then
					TriggerServerEvent("CEISetEnv", "gravity|-24.92")
					log('W', logTag, "CEISetEnv Called: gravity|-24.92")
				end
				

				if im.SmallButton("Neptune") then
					TriggerServerEvent("CEISetEnv", "gravity|-11.15")
					log('W', logTag, "CEISetEnv Called: gravity|-11.15")
				end
				im.SameLine()
				if im.SmallButton("Saturn") then
					TriggerServerEvent("CEISetEnv", "gravity|-10.44")
					log('W', logTag, "CEISetEnv Called: gravity|-10.44")
				end
				im.SameLine()
				if im.SmallButton("Uranus") then
					TriggerServerEvent("CEISetEnv", "gravity|-8.87")
					log('W', logTag, "CEISetEnv Called: gravity|-8.87")
				end
				
				if im.SmallButton("Venus") then
					TriggerServerEvent("CEISetEnv", "gravity|-8.87")
					log('W', logTag, "CEISetEnv Called: gravity|-8.87")
				end
				im.SameLine()
				if im.SmallButton("Mercury") then
					TriggerServerEvent("CEISetEnv", "gravity|-3.7")
					log('W', logTag, "CEISetEnv Called: gravity|-3.7")
				end
				im.SameLine()
				if im.SmallButton("Pluto") then
					TriggerServerEvent("CEISetEnv", "gravity|-0.58")
					log('W', logTag, "CEISetEnv Called: gravity|-0.58")
				end
				
				im.TreePop()
				im.Unindent()
				
			else
				im.SameLine()
				if im.SmallButton("Reset##GRV") then
					TriggerServerEvent("CEISetEnv", "gravity|default")
					log('W', logTag, "CEISetEnv Called: gravity|default")
				end
			end
		
			if im.TreeNode1("Temperature") then
				im.SameLine()
				if im.SmallButton("Reset##TMP") then
					TriggerServerEvent("CEISetEnv", "useTempCurve|false")
					log('W', logTag, "CEISetEnv Called: useTempCurve|false")
					environment.useTempCurveSent = false
				end
				im.Indent()
				
				local useTempCurve = im.BoolPtr(environment.useTempCurveVal)
				
				if im.Checkbox("Use Custom Temperature Curve", useTempCurve) then
					if useTempCurve[0] then
						if environment.useTempCurveSent == false then
							TriggerServerEvent("CEISetEnv", "useTempCurve|true")
							log('W', logTag, "CEISetEnv Called: useTempCurve|true")
							environment.useTempCurveSent = true
						end
					else
						if environment.useTempCurveSent == true then
							log('W', logTag, "CEISetEnv Called: useTempCurve|false")
							TriggerServerEvent("CEISetEnv", "useTempCurve|false")
							environment.useTempCurveSent = false
						end
					end
				end
				environment.useTempCurveVal = useTempCurve[0]
				
				if environment.useTempCurveVal == true then
					im.Text("Custom Temperature Curve:")
					im.SameLine()
					if im.SmallButton("Reset##TCV") then
						TriggerServerEvent("CEISetEnv", "tempCurveNoon|default")
						log('W', logTag, "CEISetEnv Called: tempCurveNoon|default")
						TriggerServerEvent("CEISetEnv", "tempCurveDusk|default")
						log('W', logTag, "CEISetEnv Called: tempCurveDusk|default")
						TriggerServerEvent("CEISetEnv", "tempCurveMidnight|default")
						log('W', logTag, "CEISetEnv Called: tempCurveMidnight|default")
						TriggerServerEvent("CEISetEnv", "tempCurveDawn|default")
						log('W', logTag, "CEISetEnv Called: tempCurveDawn|default")
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Noon")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveNoon", environment.tempCurveNoonInt, 1, 2) then
						if environment.tempCurveNoonInt[0] < -50 then
							environment.tempCurveNoonInt = im.IntPtr(-50)
						elseif environment.tempCurveNoonInt[0] > 50 then
							environment.tempCurveNoonInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveNoon|" .. tostring(environment.tempCurveNoonInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveNoon|" .. tostring(environment.tempCurveNoonInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dusk")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDusk", environment.tempCurveDuskInt, 1, 2) then
						if environment.tempCurveDuskInt[0] < -50 then
							environment.tempCurveDuskInt = im.IntPtr(-50)
						elseif environment.tempCurveDuskInt[0] > 50 then
							environment.tempCurveDuskInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveDusk|" .. tostring(environment.tempCurveDuskInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveDusk|" .. tostring(environment.tempCurveDuskInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Midnight")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveMidnight", environment.tempCurveMidnightInt, 1, 2) then
						if environment.tempCurveMidnightInt[0] < -50 then
							environment.tempCurveMidnightInt = im.IntPtr(-50)
						elseif environment.tempCurveMidnightInt[0] > 50 then
							environment.tempCurveMidnightInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveMidnight|" .. tostring(environment.tempCurveMidnightInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveMidnight|" .. tostring(environment.tempCurveMidnightInt[0]))
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dawn")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDawn", environment.tempCurveDawnInt, 1, 2) then
						if environment.tempCurveDawnInt[0] < -50 then
							environment.tempCurveDawnInt = im.IntPtr(-50)
						elseif environment.tempCurveDawnInt[0] > 50 then
							environment.tempCurveDawnInt = im.IntPtr(50)
						end
						TriggerServerEvent("CEISetEnv", "tempCurveDawn|" .. tostring(environment.tempCurveDawnInt[0]))
						log('W', logTag, "CEISetEnv Called: tempCurveDawn|" .. tostring(environment.tempCurveDawnInt[0]))
					end
					im.PopItemWidth()
				end
				
				im.TreePop()
				im.Unindent()
				
			else
				im.SameLine()
				if im.SmallButton("Reset##TMP") then
					TriggerServerEvent("CEISetEnv", "useTempCurve|false")
					log('W', logTag, "CEISetEnv Called: useTempCurve|false")
					environment.useTempCurveSent = false
				end
			end
			
		im.EndTabItem()
		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function drawCEMI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Moderator Interface")
	
	im.SameLine()
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.5, 0.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.6, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.4, 0.0, 0.999))
			if im.SmallButton("Race Countdown!") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
				
				TriggerServerEvent("CEIPreRace", "true")
				log('W', logTag, "CEIPreRace Called: true")
				
			end
			im.PopStyleColor(3)

			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]

			im.Separator()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.2, 0.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.0, 0.0, 0.999))
			if im.SmallButton("Remote Stop All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Freeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.1, 1.0, 0.1, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.2, 1.0, 0.2, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.0, 0.9, 0.0, 0.999))
			if im.SmallButton("Remote Start All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
						log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
					end
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			im.PushStyleColor2(im.Col_Button, im.ImVec4(0.6, 0.6, 1.0, 0.333))
			im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.7, 0.7, 1.0, 0.5))
			im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.5, 0.5, 0.9, 0.999))
			if im.SmallButton("Unfreeze All") then
				for k,v in pairs(players) do
					for x,y in pairs(players[k].player.vehicles) do
						TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
						log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
					end
				end
			end
			im.PopStyleColor(3)
			im.Separator()
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								if lastTeleport + dt >= tonumber(environment.teleportTimeout) then
									lastTeleport = 0
									MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
								else
									lastTeleport = lastTeleport + dt
								end
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Reason:")
					im.SameLine()
					if im.InputTextWithHint("##"..tostring(k), "Kick or Mute Reason", players[k].player.kickBanMuteReason, 128) then
					end
					
					im.Text("		playerID: " .. players[k].player.playerID)
					im.Text("		connectStage: " .. players[k].player.connectStage)
					im.Text("		guest: " .. players[k].player.guest)
					im.Text("		joinTime: " .. players[k].player.joinTime)
					im.SameLine()
					im.Text(": connectedTime: " .. players[k].player.connectedTime)

					if vehiclesCounter > 0 then
						im.Separator()

						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							
							im.Text("		")
							im.SameLine()
							im.Text("Reason:")
							im.SameLine()
							if im.InputTextWithHint("##vehReason"..tostring(k), "Vehicle Delete Reason", players[k].player.vehDeleteReason, 128) then
							end
							
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
								for i,j in pairs(ignitionEnabled) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "true" then
											im.SameLine()
											if im.SmallButton("Remote Stop##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										elseif j == "false" then
											im.SameLine()
											if im.SmallButton("Remote Start##"..tostring(x)) then
												TriggerServerEvent("CEIToggleIgnition", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleIgnition Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										end
									end
								end
								
								for i,j in pairs(isFrozen) do
									if i == MPVehicleGE.getGameVehicleID(k .. "-" .. players[k].player.vehicles[x].vehicleID) then
										if j == "false" then
											im.SameLine()
											if im.SmallButton("Freeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|true")
											end
										elseif j == "true" then
											im.SameLine()
											if im.SmallButton("Unfreeze##"..tostring(x)) then
												TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
												log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
											end
										end
									end
								end
								
								im.SameLine()
								if im.SmallButton("Delete##"..tostring(x)) then
									TriggerServerEvent("CEIRemoveVehicle", tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
									log('W', logTag, "CEIRemoveVehicle Called: " .. tostring(k) .. "|" .. players[k].player.vehicles[x].vehicleID .. "|" .. ffi.string(players[k].player.vehDeleteReason))
								end
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
					end
					im.Separator()
					if im.TreeNode1("info##"..tostring(k)) then
						im.Text("		playerID: " .. players[k].player.playerID)
						im.Text("		connectStage: " .. players[k].player.connectStage)
						im.Text("		guest: " .. players[k].player.guest)
						im.Text("		joinTime: " .. players[k].player.joinTime)
						im.SameLine()
						im.Text(": connectedTime: " .. players[k].player.connectedTime)
						im.Separator()
						if im.TreeNode1("permissions##"..tostring(k)) then
							im.Text("		level:")
							im.SameLine()
							im.Text(players[k].player.permissions.level)
							im.Text("		whitelisted: " .. players[k].player.permissions.whitelisted)
							im.Text("		muted: " .. players[k].player.permissions.muted)
							im.Text("		muteReason: " .. players[k].player.permissions.muteReason)
							im.Text("		banned: " .. players[k].player.permissions.banned)
							if im.TreeNode1("group:##"..tostring(k)) then
								im.SameLine()
								im.Text(players[k].player.permissions.group)
								im.Text("		")
								im.SameLine()
								if im.InputTextWithHint("##newGroup", "Group Name", players[k].player.permissions.groupInput, 128) then
								end
								im.Text("		")
								im.SameLine()
								if im.SmallButton("Apply##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|" .. ffi.string(players[k].player.permissions.groupInput))
								end
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
								if im.SmallButton("Remove##"..tostring(k)) then
									TriggerServerEvent("CEISetGroup", players[k].player.playerID .. "|none")
									log('W', logTag, "CEISetGroup Called: " .. players[k].player.playerID .. "|none")
								end
								im.PopStyleColor(3)
								im.SameLine()
								im.ShowHelpMarker("Remove group or enter new Group Name and press Apply")
								im.TreePop()
							else
								im.SameLine()
								im.Text(players[k].player.permissions.group)
							end
							im.TreePop()
						end
						im.Separator()
						if im.TreeNode1("gamemode##"..tostring(k)) then
							im.Text("		mode: " .. players[k].player.gamemode.mode)
							im.Text("		source: " .. players[k].player.gamemode.source)
							im.Text("		queue: " .. players[k].player.gamemode.queue)
							im.Text("		locked: " .. players[k].player.gamemode.locked)
							im.TreePop()
						end
						im.TreePop()
					end
					im.Unindent()
				else
					im.PopStyleColor(3)
					im.Indent()
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Kick##"..tostring(k)) then
						TriggerServerEvent("CEIKick",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						log('W', logTag, "CEIKick Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
					end
					im.SameLine()
					if players[k].player.permissions.muted == "false" then
						if im.SmallButton("Mute##"..tostring(k)) then
							TriggerServerEvent("CEIMute",tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
							log('W', logTag, "CEIMute Called: " .. tostring(k) .. "|".. ffi.string(players[k].player.kickBanMuteReason))
						end
					elseif players[k].player.permissions.muted == "true" then
						if im.SmallButton("Unmute##"..tostring(k)) then
							TriggerServerEvent("CEIUnmute",tostring(k))
							log('W', logTag, "CEIUnmute Called: " .. tostring(k))
						end
					end
					im.SameLine()
					if players[k].player.permissions.whitelisted == "false" then
						if im.SmallButton("Whitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","add|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: add|" .. tostring(k))
						end
					elseif players[k].player.permissions.whitelisted == "true" then
						if im.SmallButton("Unwhitelist##" .. tostring(k)) then
							TriggerServerEvent("CEIWhitelist","remove|" .. tostring(k))
							log('W', logTag, "CEIWhitelist Called: remove|" .. tostring(k))
						end
					end
					
					if vehiclesCounter > 0 then
						if canTeleport then
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								if lastTeleport + dt >= tonumber(environment.teleportTimeout) then
									lastTeleport = 0
									MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
								else
									lastTeleport = lastTeleport + dt
								end
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
						end
					end
					
					im.Unindent()
					
				end
			end
			im.EndTabItem()
		end
----------------------------------------------------------------------------------CONFIG TAB
		if im.BeginTabItem("Config") then
----------------------------------------------------------------------------------COBALT HEADER
			if im.CollapsingHeader1("Cobalt Essentials") then
				local vehicleCaps = config.cobalt.permissions.vehicleCaps
				local vehicleCapsCounter = 0
				for a,b in pairs(vehicleCaps) do
					vehicleCapsCounter = vehicleCapsCounter + 1
				end
				im.Indent()
				if im.TreeNode1("vehicleCaps:") then
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
					for k,v in pairs(vehicleCaps) do
						im.Text("level: " .. config.cobalt.permissions.vehicleCaps[k].level .. " =")
						im.SameLine()
						im.Text(config.cobalt.permissions.vehicleCaps[k].vehicles .. " vehicles")
					end
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(vehicleCapsCounter))
				end
				im.Separator()
				im.Text("		maxActivePlayers:")
				im.SameLine()
				im.Text(config.cobalt.maxActivePlayers)
				im.Separator()
				local groups = config.cobalt.groups
				local groupCounter = 0
				for a,b in pairs(groups) do
					groupCounter = groupCounter + 1
				end
				if im.TreeNode1("groups:") then
					im.SameLine()
					im.Text(tostring(groupCounter))
					for k,v in pairs(groups) do
						im.Separator()
						if im.TreeNode1(config.cobalt.groups[k].groupName) then
							local groupPlayers = config.cobalt.groups[k].groupPlayers
							local groupPlayersCounter = 0
							for c,d in pairs(groupPlayers) do
								groupPlayersCounter = groupPlayersCounter + 1
							end
							if config.cobalt.groups[k].groupLevel then
								im.Text("		players: " .. tostring(groupPlayersCounter))
								for w,z in pairs(groupPlayers) do
									im.Text("		")
									im.SameLine()
									im.Text(groupPlayers[w])
								end
								im.Text("		")
								im.Text("		level: ")
							else
								im.Text("		")
								im.Text("		level: ")
							end
							if config.cobalt.groups[k].groupWhitelisted then
								im.Text("		whitelisted: " .. config.cobalt.groups[k].groupWhitelisted)
							else
								im.Text("		whitelisted: null")
							end
							if config.cobalt.groups[k].groupMuted then
								im.Text("		muted: " .. config.cobalt.groups[k].groupMuted)
							else
								im.Text("		muted: null")
							end
							if config.cobalt.groups[k].groupBanned then
								im.Text("		banned: " .. config.cobalt.groups[k].groupBanned)
							else
								im.Text("		banned: null")
							end
							if config.cobalt.groups[k].groupBanReason then
								im.Text("		banReason: " .. config.cobalt.groups[k].groupBanReason)
							else
								im.Text("		banReason: null")
							end
							im.TreePop()
							im.Text("		")
						end
					end
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(groupCounter))
				end
				im.Separator()
				local whitePlayers = config.cobalt.whitelistedPlayers
				local whitePlayersCounter = 0
				for a,b in pairs(whitePlayers) do
					whitePlayersCounter = whitePlayersCounter + 1
				end
				if im.TreeNode1("whitelisted players:") then
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
					for x,y in pairs(whitePlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.cobalt.whitelistedPlayers[x].name)
						im.SameLine()
						if im.SmallButton("Remove##"..tostring(x)) then
							TriggerServerEvent("CEIWhitelist", "remove|" .. config.cobalt.whitelistedPlayers[x].name)
							log('W', logTag, "CEIWhitelist Called: remove|" .. config.cobalt.whitelistedPlayers[x].name)
						end
					end
					im.Text("		Add Name to Whitelist: ")
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##whitelistName", "Player Name", config.cobalt.whitelistNameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Add##whitelistName") then
						TriggerServerEvent("CEIWhitelist", "add|" .. ffi.string(config.cobalt.whitelistNameInput))
						log('W', logTag, "CEIWhitelist Called: add|" .. ffi.string(config.cobalt.whitelistNameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter Player Name to Add to Whitelist and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(whitePlayersCounter))
				end
				im.Text("		")
				im.SameLine()
				if config.cobalt.enableWhitelist == "false" then
					if im.SmallButton("Enable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","enable")
						log('W', logTag, "CEIWhitelist Called: enable")
					end
				elseif config.cobalt.enableWhitelist == "true" then
					if im.SmallButton("Disable Whitelist##"..tostring(k)) then
						TriggerServerEvent("CEIWhitelist","disable")
						log('W', logTag, "CEIWhitelist Called: disable")
					end
				end
				im.Unindent()
			end
----------------------------------------------------------------------------------SERVER HEADER
			if im.CollapsingHeader1("Server") then
				im.Indent()
				if im.TreeNode1("name:") then
					im.SameLine()
					im.Text(config.server.name)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##name", "Server Name", config.server.nameInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg", "Name|" .. ffi.string(config.server.nameInput))
						log('W', logTag, "CEISetCfg Called: Name|" .. ffi.string(config.server.nameInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Name and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.name)
				end
				im.Separator()
				if im.TreeNode1("maxCars:") then
					im.SameLine()
					im.Text(config.server.maxCars)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxCarsInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxCars|" .. tostring(config.server.maxCarsInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxCars|" .. tostring(config.server.maxCarsInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxCars)
				end
				im.Separator()
				if im.TreeNode1("maxPlayers:") then
					im.SameLine()
					im.Text(config.server.maxPlayers)
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("", config.server.maxPlayersInt, 1) then
						TriggerServerEvent("CEISetCfg","MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
						log('W', logTag, "CEISetCfg Called: MaxPlayers|" .. tostring(config.server.maxPlayersInt[0]))
					end
					im.PopItemWidth()
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.maxPlayers)
				end
				im.Separator()
				if im.TreeNode1("map:") then
					im.SameLine()
					im.Text(config.server.map)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##map", "Map Path", config.server.mapInput, 128) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Map|" .. ffi.string(config.server.mapInput))
						log('W', logTag, "CEISetCfg Called: Map|" ..  ffi.string(config.server.mapInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Map and press Apply (REQUIRES REJOIN FOR EFFECT)")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.map)
				end
				im.Separator()
				if im.TreeNode1("description:") then
					im.SameLine()
					im.Text(config.server.description)
					im.Text("		")
					im.SameLine()
					if im.InputTextWithHint("##description", "Server Description", config.server.descriptionInput, 256) then
					end
					im.Text("		")
					im.SameLine()
					if im.SmallButton("Apply##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Description|" .. ffi.string(config.server.descriptionInput))
						log('W', logTag, "CEISetCfg Called: Description|" ..  ffi.string(config.server.descriptionInput))
					end
					im.SameLine()
					im.ShowHelpMarker("Enter new Server Description and press Apply")
					im.TreePop()
				else
					im.SameLine()
					im.Text(config.server.description)
				end
				im.Separator()
				im.Text("		debug: " .. config.server.debug)
				im.SameLine()
				if config.server.debug == "false" then
					if im.SmallButton("Enable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|true")
						log('W', logTag, "CEISetCfg Called: Debug|true")
					end
				elseif config.server.debug == "true" then
					if im.SmallButton("Disable Debug##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Debug|false")
						log('W', logTag, "CEISetCfg Called: Debug|false")
					end
					
				end
				im.Separator()
				im.Text("		private: " .. config.server.private)
				im.SameLine()
				if config.server.private == "false" then
					if im.SmallButton("Set Private##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|true")
						log('W', logTag, "CEISetCfg Called: private|true")
					end
				elseif config.server.private == "true" then
					if im.SmallButton("Set Public##"..tostring(k)) then
						TriggerServerEvent("CEISetCfg","Private|false")
						log('W', logTag, "CEISetCfg Called: Private|false")
					end
				end
				im.Text("		")
			end
----------------------------------------------------------------------------------NAMETAGS HEADER
			if im.CollapsingHeader1("Nametags") then
			
				local nametagWhitelist = config.nametags.whitelistedPlayers
				local nametagWhitelistCounter = 0
				for a,b in pairs(nametagWhitelist) do
					nametagWhitelistCounter = nametagWhitelistCounter + 1
				end
			
				im.Indent()
				if im.TreeNode1("Nametag Settings") then
					im.Text("		")
					im.SameLine()
					im.Text("Nametag Blocking: ")
					if config.nametags.settings.blockingEnabled == "true" then
						im.SameLine()
						if im.SmallButton("Enabled##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "false")
							log('W', logTag, "CEINametagSetting: false")
							TriggerServerEvent("txNametagBlockerTimeout", "0")
							log('W', logTag, "txNametagBlockerTimeout: 0")
						end
					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Disabled##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
						end
					end
					
					im.Text("		")
					im.SameLine()
					im.Text("Blocking Timeout: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##nametagBlockingTimeout", config.nametags.settings.blockingTimeoutInt, 1) then
						if config.nametags.settings.blockingTimeoutInt[0] < 0 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(0)
						elseif config.nametags.settings.blockingTimeoutInt[0] > 3600 then
							config.nametags.settings.blockingTimeoutInt = im.IntPtr(3600)
						end
						TriggerServerEvent("CEINametagSetting", tostring(config.nametags.settings.blockingTimeoutInt[0]))
						log('W', logTag, "CEINametagSetting Called: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
					end
					im.PopItemWidth()
					
					if config.nametags.settings.blockingEnabled == "true" then

					elseif config.nametags.settings.blockingEnabled == "false" then
						im.SameLine()
						if im.SmallButton("Start##NametagBlocking") then
							TriggerServerEvent("CEINametagSetting", "true")
							log('W', logTag, "CEINametagSetting: true")
							TriggerServerEvent("txNametagBlockerTimeout", tostring(config.nametags.settings.blockingTimeoutInt[0]))
							log('W', logTag, "txNametagBlockerTimeout: " .. tostring(config.nametags.settings.blockingTimeoutInt[0]))
						end
					end
					
					im.TreePop()
				else
				end
				im.Separator()
				if im.TreeNode1("Nametag Whitelist: ") then
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
					
					for k,v in pairs(config.nametags.whitelistedPlayers) do
						im.Text("		")
						im.SameLine()
						im.Text(config.nametags.whitelistedPlayers[k].name)
					end
					
					im.TreePop()
				else
					im.SameLine()
					im.Text(tostring(nametagWhitelistCounter))
				end
				im.Unindent()
				
			end
			im.Unindent()
			im.EndTabItem()

		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function drawCEPI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Player Interface")
	
	im.SameLine()
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					if vehiclesCounter > 0 then
						im.Indent()
						if canTeleport then
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								if lastTeleport + dt >= tonumber(environment.teleportTimeout) then
									lastTeleport = 0
									MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
								else
									lastTeleport = lastTeleport + dt
								end
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
						end
						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
						im.Unindent()
					end

				else
					im.PopStyleColor(3)
					
					if vehiclesCounter > 0 then
						im.Indent()
						if im.SmallButton("Focus##" .. tostring(k)) then
							MPVehicleGE.focusCameraOnPlayer(players[k].player.playerName)
						end
						im.SameLine()
						im.ShowHelpMarker("Cycle camera through this player's vehicles.")
						
						im.SameLine()
						if im.SmallButton("Teleport To##" .. tostring(k)) then
							if lastTeleport + dt >= tonumber(environment.teleportTimeout) then
								lastTeleport = 0
								MPVehicleGE.teleportVehToPlayer(players[k].player.playerName)
							else
								lastTeleport = lastTeleport + dt
							end
						end
						im.SameLine()
						im.ShowHelpMarker("Teleport to this player's current vehicle.")
						im.Unindent()
					end
				end
			end
			im.EndTabItem()
		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function drawCEGI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Guest Interface")
	
	im.SameLine()
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					if vehiclesCounter > 0 then
						im.Indent()
						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
						im.Unindent()
					end
				else
					im.PopStyleColor(3)
					
				end
			end
			im.EndTabItem()
		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function drawCESI(dt)
	if tableIsEmpty(players) then
		return
	end
	gui.setupWindow("CEI")
----------------------------------------------------------------------------------STYLE
	im.PushStyleColor2(im.Col_Border, im.ImVec4(0.25, 0.25, 1.0, 0.5))
	im.PushStyleColor2(im.Col_ResizeGrip, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripHovered, im.ImVec4(0.15, 0.15, 0.66, 0.5))
	im.PushStyleColor2(im.Col_ResizeGripActive, im.ImVec4(0.15, 0.15, 0.95, 0.5))
	im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.75, 0.5))
	im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.05, 0.05, 0.5, 0.5))
	im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_Tab, im.ImVec4(0.33, 0.33, 1, 0.5))
	im.PushStyleColor2(im.Col_TabHovered, im.ImVec4(0.50, 0.50, 1, 0.5))
	im.PushStyleColor2(im.Col_TabActive, im.ImVec4(0.125, 0.125, 1, 0.5))
	im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0.33, 0.5))
	im.PushStyleColor2(im.Col_FrameBgHovered, im.ImVec4(0, 0, 0.44, 0.5))
	im.PushStyleColor2(im.Col_FrameBgActive, im.ImVec4(0, 0, 0.22, 0.5))
	im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
	im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
	im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
	im.PushStyleColor2(im.Col_Separator, im.ImVec4(0.66, 0.66, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorHovered, im.ImVec4(0.77, 0.85, 0.95, 0.75))
	im.PushStyleColor2(im.Col_SeparatorActive, im.ImVec4(0.95, 0.4, 0.95, 0.5))
	im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
	im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
	im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
	im.SetNextWindowBgAlpha(0.666)
	
	im.Begin("Cobalt Essentials Spectator Interface")
	
	im.SameLine()
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD.time >= 0 and tempToD.time < 0.5 then
		curSecs = tempToD.time * 86400 + 43200
	elseif tempToD.time >= 0.5 and tempToD.time <= 1 then
		curSecs = tempToD.time * 86400 - 43200
	end
	local curHours = math.floor(curSecs / 3600 )
	curSecs = curSecs - curHours * 3600
	local curMins = math.floor(curSecs / 60) 
	curSecs = curSecs - curMins * 60
	local currentTime = string.format("%02d:%02d:%02d",curHours,curMins,curSecs)
	im.Text("Current time: " .. currentTime)
	im.SameLine()
	local currentTempC = core_environment.getTemperatureK() - 273.15
	local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
	local currentTempF = currentTempC * 9/5 + 32
	local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
	im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	
	if nametagBlockerTimeout ~= nil then
		im.Text("Nametags Blocked for:")
		im.SameLine()
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), string.format("%.2f",nametagBlockerTimeout))
		im.SameLine()
		im.Text("seconds")
	elseif nametagBlockerActive == true then
		im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "Nametags Blocked")
	end
	
----------------------------------------------------------------------------------TAB BAR
	if im.BeginTabBar("CobaltTabBar") then
----------------------------------------------------------------------------------PLAYERS TAB
		local playersCounter = 0
		for k,v in pairs(players) do
			playersCounter = playersCounter + 1
		end
		if im.BeginTabItem("Players") then
			im.Text("Current Players:")
			im.SameLine()
			im.Text(tostring(playersCounter))
			
			local includeMe = im.BoolPtr(includeForRace)
			
			im.SameLine()
			if im.Checkbox("Include Me In Race", includeMe) then
				if includeMe[0] then
					if includeForRaceSent == false then
						TriggerServerEvent("CEIRaceInclude", "true")
						log('W', logTag, "CEIRaceInclude Called: true")
						includeForRaceSent = true
					end
				else
					if includeForRaceSent == true then
						TriggerServerEvent("CEIRaceInclude", "false")
						log('W', logTag, "CEIRaceInclude Called: false")
						includeForRaceSent = false
					end
				end
			end
			includeForRace = includeMe[0]
			
			for k,v in pairs(players) do
----------------------------------------------------------------------------------PLAYER HEADER
				
				local vehiclesCounter = 0
				for x,y in pairs(players[k].player.vehicles) do
					vehiclesCounter = vehiclesCounter + 1
				end
				
				if roles.owner[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif roles.admin[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif roles.mod[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif roles.player[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif roles.guest[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif roles.spectator[k] == players[k].player.playerName then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				if im.CollapsingHeader1(players[k].player.playerName) then
					im.PopStyleColor(3)
					
					if vehiclesCounter > 0 then
						im.Indent()
						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							for x,y in pairs(players[k].player.vehicles) do
								if playersCurrentVehicle[k] == k .. "-" .. players[k].player.vehicles[x].vehicleID then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(players[k].player.vehicles[x].vehicleID .. ":")
								im.SameLine()
								im.Text(players[k].player.vehicles[x].genericName)
								
							end
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
						end
						im.Unindent()
					end

				else
					im.PopStyleColor(3)
					
				end
			end
			im.EndTabItem()
		end
		im.EndTabBar()
	end
	im.PopStyleColor(22)
	im.End()
end

local function showUI()
	gui.showWindow("CEI")
end

local function hideUI()
	gui.hideWindow("CEI")
end

local function CEIToggleIgnition(data)
	local tempData = split(data,"|")
	local gameVehicleID = MPVehicleGE.getGameVehicleID(tempData[1].."-"..tempData[2])
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if tempData[3] == "false" then
			if ignitionEnabled[gameVehicleID] == "true" or ignitionEnabled[gameVehicleID] == nil then
				veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
				veh:queueLuaCommand('electrics.set_warn_signal(0)')
				veh:queueLuaCommand('electrics.setLightsState(0)')
				veh:queueLuaCommand('electrics.set_lightbar_signal(0)')
				veh:queueLuaCommand('electrics.horn(false)')
				veh:queueLuaCommand('electrics.set_fog_lights(0)')
				veh:queueLuaCommand('electrics.update(0)')
				ignitionEnabled[gameVehicleID] = "false"
			end
		elseif tempData[3] == "true" then
			if ignitionEnabled[gameVehicleID] == "false" then
				veh:queueLuaCommand('controller.mainController.setStarter(true)')
				veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
				veh:queueLuaCommand('controller.mainController.setStarter(false)')
				ignitionEnabled[gameVehicleID] = "true"
			end
		end
	end
end

local function CEIToggleLock(data)
	local tempData = split(data,"|")
	local gameVehicleID = MPVehicleGE.getGameVehicleID(tempData[1].."-"..tempData[2])
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if tempData[3] == "true" then
			if isFrozen[gameVehicleID] == "false" or isFrozen[gameVehicleID] == nil then
				veh:queueLuaCommand('controller.setFreeze(1)')
				isFrozen[gameVehicleID] = "true"
			end
		elseif tempData[3] == "false" then
			if isFrozen[gameVehicleID] == "true" then
				veh:queueLuaCommand('controller.setFreeze(0)')
				isFrozen[gameVehicleID] = "false"
			end
		end
	end
end

local function checkVehicleState(gameVehicleID, argument)
	for k,v in pairs(ignitionEnabled) do
		if v == "false" then
			local veh = be:getObjectByID(k)
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
	for k,v in pairs(isFrozen) do
		if v == "true" then
			local veh = be:getObjectByID(k)
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
	end
end

local function onUpdate(dt)
	if worldReadyState == 2 then
		if currentRole == "owner" then
			if windowOpen[0] == true then
				drawCEOI(dt)
			end
		elseif currentRole == "admin" then
			if windowOpen[0] == true then
				drawCEAI(dt)
			end
		elseif currentRole == "mod" then
			if windowOpen[0] == true then
				drawCEMI(dt)
			end
		elseif currentRole == "player" then
			if windowOpen[0] == true then
				drawCEPI(dt)
			end
		elseif currentRole == "guest" then
			if windowOpen[0] == true then
				drawCEGI(dt)
			end
		elseif currentRole == "spectator" then
			if windowOpen[0] == true then
				drawCESI(dt)
			end
		end
		checkVehicleState()
		
		M.onTimePlay(environment.timePlay)
		
		if environment.timePlay == "false" then
			M.onTime(environment.ToD)
		elseif firstReport == false then
			M.onTime(environment.ToD)
			firstReport = true
		end
		
		if lastEnvReport + dt > envReportRate then
			lastEnvReport = 0
			core_environment.reset()
			local timeOfDay = core_environment.getTimeOfDay()
			if currentRole == "owner" or currentRole == "admin" or currentRole == "mod" then
				TriggerServerEvent("CEISetEnv", "ToD|" .. tostring(timeOfDay.time))
			end
		else
			lastEnvReport = lastEnvReport + dt
		end
		
		lastTeleport = lastTeleport + dt
		
		M.onDayScale(environment.dayScale)
		M.onNightScale(environment.nightScale)
		M.onAzimuthOverride(environment.azimuthOverride)
		M.onSunSize(environment.sunSize)
		M.onSkyBrightness(environment.skyBrightness)
		M.onSunLightBrightness(environment.sunLightBrightness)
		M.onExposure(environment.exposure)
		M.onShadowDistance(environment.shadowDistance)
		M.onShadowSoftness(environment.shadowSoftness)
		M.onShadowSplits(environment.shadowSplits)
		M.onFogDensity(environment.fogDensity)
		M.onFogDensityOffset(environment.fogDensityOffset)
		M.onCloudCover(environment.cloudCover)
		M.onCloudSpeed(environment.cloudSpeed)
		M.onRainDrops(environment.rainDrops)
		M.onDropSize(environment.dropSize)
		M.onDropMinSpeed(environment.dropMinSpeed)
		M.onDropMaxSpeed(environment.dropMaxSpeed)
		M.onSimSpeed(environment.simSpeed)
		M.onTempCurve()
		M.onGravity(environment.gravity)
	end
end

local function onVehicleSpawned(gameVehicleID)
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if isFrozen[gameVehicleID] == "false" then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[gameVehicleID] == "true" then
			veh:queueLuaCommand('controller.setFreeze(1)')
		else
			isFrozen[gameVehicleID] = "false"
		end
		if ignitionEnabled[gameVehicleID] == "true" then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[gameVehicleID] == "false"
		then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		else
			ignitionEnabled[gameVehicleID] = "true"
		end
	end
end

local function onVehicleDestroyed(gameVehicleID)
	ignitionEnabled[gameVehicleID] = nil
	isFrozen[gameVehicleID] = nil
end

local function onVehicleResetted(gameVehicleID)
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if isFrozen[gameVehicleID] == "false" then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[gameVehicleID] == "true" then
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
		if ignitionEnabled[gameVehicleID] == "true" then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[gameVehicleID] == "false" then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
end

local function onVehicleSwitched(oldGameVehicleID, newGameVehicleID)
	local veh = be:getObjectByID(newGameVehicleID)
	if veh then
		if isFrozen[newGameVehicleID] == "false" then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[newGameVehicleID] == "true" then
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
		if ignitionEnabled[newGameVehicleID] == "true" then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[newGameVehicleID] == "false" then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
	
	if newGameVehicleID and newGameVehicleID > -1 then
		local oldVehicle = be:getObjectByID(oldGameVehicleID or -1)
		local newVehicle = be:getObjectByID(newGameVehicleID or -1)
		local newVehObj = MPVehicleGE.getVehicleByGameID(newGameVehicleID) or {}
		local newServerVehicleID = newVehObj.serverVehicleString
		if newServerVehicleID then
			TriggerServerEvent("CEISetCurVeh", newServerVehicleID)
			log('W', logTag, "CEISetCurVeh (CLIENT) Called: " .. newServerVehicleID)
		end
	end
end

local function CEISetCurVeh(data)
	log('W', logTag, "CEISetCurVeh (SERVER) Called: " .. data)
	
	local tempData = split(data,"|")
	
	playersCurrentVehicle[tempData[1]] = tempData[2]
end

local function CEIRaceCountdown(data)
	log('W', logTag, "CEIRaceCountdown Called: " .. data)
	tempData = split(data,"|")
	msg = tempData[1]
	ttl = tempData[2]
	big = tempData[3]
	guihooks.trigger('ScenarioFlashMessage', {{msg, ttl, 0, big}} )
end

local function CEIRaceCountSound(data)
	log('W', logTag, "CEIRaceCountSound Called: " .. data)
	Engine.Audio.playOnce('AudioGui', '/art/sound/' .. data)
end

local function CEIRaceStart(data)
	log('W', logTag, "CEIRaceStart Called: " .. data)
	for k,v in pairs(players) do
		for x,y in pairs(players[k].player.vehicles) do
			TriggerServerEvent("CEIToggleLock", players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
			log('W', logTag, "CEIToggleLock Called: " .. players[k].player.playerID .. "|" .. players[k].player.vehicles[x].vehicleID .. "|false")
		end
	end
end

local function onTime(value)
	local timeOfDay = core_environment.getTimeOfDay()
	timeOfDay.time = value
	core_environment.setTimeOfDay(timeOfDay)
end

local function onTimePlay(value)
	if value == "true" or value == "True" then
		value = true
	elseif value == "false" or value == "False" then
		value = false
	end
	local timeOfDay = core_environment.getTimeOfDay()
	timeOfDay.play = value
	core_environment.setTimeOfDay(timeOfDay)
end

local function onDayScale(value)
	local timeOfDay = core_environment.getTimeOfDay()
	timeOfDay.dayScale = value
	core_environment.setTimeOfDay(timeOfDay)
end

local function onNightScale(value)
	local timeOfDay = core_environment.getTimeOfDay()
	timeOfDay.nightScale = value
	core_environment.setTimeOfDay(timeOfDay)
end

local function onAzimuthOverride(value)
	local timeOfDay = core_environment.getTimeOfDay()
	timeOfDay.azimuthOverride = value
	core_environment.setTimeOfDay(timeOfDay)
end

local function onSunSize(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.sunSize = value
	end
end

local function onSkyBrightness(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.skyBrightness = value
	end
end

local function onSunLightBrightness(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.brightness = value
	end
end

local function onExposure(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.exposure = value
	end
end

local function onShadowDistance(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.shadowDistance = value
	end
end

local function onShadowSoftness(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.shadowSoftness = value
	end
end

local function onShadowSplits(value)
	local scatterSkyObj = M.getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.numSplits = value
	end
end

local function onFogDensity(value)
	core_environment.setFogDensity(value)
end

local function onFogDensityOffset(value)
	core_environment.setFogDensityOffset(value)
end

local function onCloudCover(value)
	core_environment.setCloudCover(value)
end

local function onCloudSpeed(value)
	core_environment.setWindSpeed(value)
end

local function onRainDrops(value)
	local rainObj = M.getObject("Precipitation")
	if rainObj and value then
		rainObj.numDrops = value
		if environment.precipType == "rain_medium" then
			rainObj.dataBlock = scenetree.findObject("rain_medium")
		elseif environment.precipType == "rain_drop" then
			rainObj.dataBlock = scenetree.findObject("rain_drop")
		elseif environment.precipType == "Snow_menu" then
			rainObj.dataBlock = scenetree.findObject("Snow_menu")
		end
	end
end

local function onRainDrops(value)
	local rainObj = M.getObject("Precipitation")
	if rainObj and value then
		rainObj.numDrops = value
		if environment.precipType == "rain_medium" then
			rainObj.dataBlock = scenetree.findObject("rain_medium")
		elseif environment.precipType == "rain_drop" then
			rainObj.dataBlock = scenetree.findObject("rain_drop")
		elseif environment.precipType == "Snow_menu" then
			rainObj.dataBlock = scenetree.findObject("Snow_menu")
		end
	end
end

local function onDropSize(value)
	local rainObj = M.getObject("Precipitation")
	if rainObj and value then
		rainObj.dropSize = value
	end
end

local function onDropMinSpeed(value)
	local rainObj = M.getObject("Precipitation")
	if rainObj and value then
		rainObj.minSpeed = value
	end
end

local function onDropMaxSpeed(value)
	local rainObj = M.getObject("Precipitation")
	if rainObj and value then
		rainObj.maxSpeed = value
	end
end

local function onTempCurve()

	local tempCurve
	
	if environment.useTempCurveVal == false then
		local levelInfo = M.getObject("LevelInfo")
		if not levelInfo then
			return
		elseif defaultTempCurveSet == false then
			defaultTempCurve = levelInfo:getTemperatureCurveC()
			if type(defaultTempCurve) == "table" then
				print("GOT TEMP CURVE TABLE!")
				defaultTempCurveSet = true
			end
		elseif defaultTempCurveSet == true then
			levelInfo:setTemperatureCurveC(defaultTempCurve)
		end
		return
	elseif defaultTempCurveSet == true then
		local levelInfo = M.getObject("LevelInfo")
		if not levelInfo then
			return
		end
	
		tempCurve = { 
			{ 0, environment.tempCurveNoonInt[0] },
			{ 0.25, environment.tempCurveDuskInt[0] },
			{ 0.5, environment.tempCurveMidnightInt[0] },
			{ 0.75, environment.tempCurveDawnInt[0] },
			{ 1, environment.tempCurveNoonInt[0] } 
		}
	
		levelInfo:setTemperatureCurveC(tempCurve)
		
	end
	
end

local function onSimSpeed(value)
	if value == nil then
		value = 1
	end
	if worldReadyState == 2 then
		be:setSimulationTimeScale(value)
	end
end

local function onGravity(value)
	core_environment.setGravity(value)
end

local function onWorldReadyState(state)
	worldReadyState = state
end

local function rxTeleportFrom(data)
	MPVehicleGE.teleportVehToPlayer(data)
end

local function onPreRender(dt)
	if nametagBlockerActive then
		if nametagBlockerTimeout ~= nil then
			nametagBlockerTimeout = nametagBlockerTimeout - dt
			if nametagBlockerTimeout > 0 then
				if not nametagWhitelisted then
					MPVehicleGE.hideNicknames(true)
				else
					MPVehicleGE.hideNicknames(false)
				end
			else
				nametagBlockerTimeout = nil
				TriggerServerEvent("CEINametagSetting", "false")
				log('W', logTag, "CEINametagSetting: false")
			end
		else
			if not nametagWhitelisted then
				MPVehicleGE.hideNicknames(true)
			else
				MPVehicleGE.hideNicknames(false)
			end
		end
	else
		MPVehicleGE.hideNicknames(false)
	end
end

local function onExtensionLoaded()
	local currentMpLayout = jsonReadFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json")
	originalMpLayout = currentMpLayout
	local found
	if currentMpLayout then 
		for k,v in pairs(currentMpLayout.apps) do
			if v.appName == "raceCountdown" then
				found = true
			end
		end
		if not found then
			local raceCountdown = {}
			raceCountdown.appName = "raceCountdown"
			raceCountdown.placement = {}
			raceCountdown.placement.bottom = ""
			raceCountdown.placement.height = "160px"
			raceCountdown.placement.left = 0
			raceCountdown.placement.margin = "auto"
			raceCountdown.placement.position = "absolute"
			raceCountdown.placement.right = 0
			raceCountdown.placement.top = "40px"
			raceCountdown.placement.width = "690px"
			table.insert(currentMpLayout.apps, raceCountdown)
			jsonWriteFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json",currentMpLayout)
			reloadUI()
		end
	end
	
	AddEventHandler("rxPlayerRole", rxPlayerRole)
	AddEventHandler("rxPlayersRoles", rxPlayersRoles)
	AddEventHandler("rxPlayersData", rxPlayersData)
	AddEventHandler("rxPlayerAuth", rxPlayerAuth)
	AddEventHandler("rxPlayerConnecting", rxPlayerConnecting)
	AddEventHandler("rxConfigData", rxConfigData)
	AddEventHandler("rxPlayerLeave", rxPlayerLeave)
	AddEventHandler("rxStats", rxStats)
	AddEventHandler("rxEnvironment", rxEnvironment)
	AddEventHandler("rxPreferences", rxPreferences)
	AddEventHandler("rxCEIstate", rxCEIstate)
	AddEventHandler("rxCEItp", rxCEItp)
	AddEventHandler("rxTeleportFrom", rxTeleportFrom)
	AddEventHandler("rxNametagWhitelisted", rxNametagWhitelisted)
	AddEventHandler("rxNametagBlockerActive", rxNametagBlockerActive)
	AddEventHandler("rxNametagBlockerTimeout", rxNametagBlockerTimeout)
	AddEventHandler("CEIToggleIgnition", CEIToggleIgnition)
	AddEventHandler("CEIToggleLock", CEIToggleLock)
	AddEventHandler("CEISetCurVeh", CEISetCurVeh)
	AddEventHandler("CEIRaceCountdown", CEIRaceCountdown)
	AddEventHandler("CEIRaceCountSound", CEIRaceCountSound)
	AddEventHandler("CEIRaceStart", CEIRaceStart)
	
	gui_module.initialize(gui)
	gui.registerWindow("CEI", im.ImVec2(512, 256))
	gui.showWindow("CEI")
	log('W', logTag, "-=$=- CEI LOADED -=$=-")
end

local function onExtensionUnloaded()
	jsonWriteFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json",originalMpLayout)
	Lua:requestReload()
	log('W', logTag, "-=$=- CEI UNLOADED -=$=-")
end

local function teleportPlayerToVeh(targetName, player_id)
	TriggerServerEvent("CEITeleportFrom", player_id)
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function split(s, sep)
	local fields = {}
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	return fields
end

local function getObject(className, preferredObjName)
	if envObjectIdCache[className] then
		return scenetree.findObjectById(envObjectIdCache[className])
	end
	envObjectIdCache[className] = 0
	local objNames = scenetree.findClassObjects(className)
	if objNames and tableSize(objNames) > 0 then
		for _,name in pairs(objNames) do
			local obj = scenetree.findObject(name)
			if obj and (name == preferredObjName or not preferredObjName) then
				envObjectIdCache[className] = obj:getID()
				return obj
			end
		end
	end
	return nil
end

M.dependencies = {"ui_imgui"}
M.onUpdate = onUpdate
M.onPreRender = onPreRender
M.onWorldReadyState = onWorldReadyState

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.teleportPlayerToVeh = teleportPlayerToVeh

M.round = round

M.getObject = getObject

M.onVehicleSpawned = onVehicleSpawned
M.onVehicleDestroyed = onVehicleDestroyed
M.onVehicleSwitched = onVehicleSwitched
M.onVehicleResetted = onVehicleResetted

M.onTime = onTime
M.onTimePlay = onTimePlay
M.onDayScale = onDayScale
M.onNightScale = onNightScale
M.onAzimuthOverride = onAzimuthOverride
M.onSunSize = onSunSize
M.onSkyBrightness = onSkyBrightness
M.onSunLightBrightness = onSunLightBrightness
M.onExposure = onExposure
M.onShadowDistance = onShadowDistance
M.onShadowSoftness = onShadowSoftness
M.onShadowSplits = onShadowSplits
M.onFogDensity = onFogDensity
M.onFogDensityOffset = onFogDensityOffset
M.onCloudCover = onCloudCover
M.onCloudSpeed = onCloudSpeed
M.onRainDrops = onRainDrops
M.onDropSize = onDropSize
M.onDropMinSpeed = onDropMinSpeed
M.onDropMaxSpeed = onDropMaxSpeed

M.onTempCurve = onTempCurve

M.onSimSpeed = onSimSpeed
M.onGravity = onGravity

return M
