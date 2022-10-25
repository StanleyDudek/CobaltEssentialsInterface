--CEI (CLIENT) by Dudekahedron, 2022

local M = {}

local logTag = "CEI"
local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local windowOpen = im.BoolPtr(true)
local ffi = require('ffi')
local originalMpLayout = jsonReadFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json")
local currentGroup
local canTeleport
local includeInRace = false
local nametagWhitelisted = false
local nametagBlockerActive = false
local nametagBlockerTimeout
local nametagsValsSet = {}
local ignitionEnabled = {}
local isFrozen = {}

local firstReset = false
local firstTeleport = false

local resetsBlockedInputActions = {}
local allResetsBlockedInputActions = {
	"loadHome",
	"recover_vehicle",
	"recover_vehicle_alt",
	"reload_all_vehicles",
	"reload_vehicle",
	"reset_all_physics",
	"reset_physics"
}

local environmentValsSet = false
local environmentVals = {}
local environment = {}
local playersValsSet = {}
local playersVals = {}
local players = {}
local playersDatabaseValsSet = false
local playersDatabaseVals = {}
local playersDatabase = {}
local playersDatabaseFiltering = {}
playersDatabaseFiltering.filter = ffi.new('ImGuiTextFilter[1]')

local configValsSet = false
local configVals = {}
local config = {}

resetsPlayerNotified = true
resetsTimerElapsedReset = 0

local vehiclePermsFiltering = {}
vehiclePermsFiltering.filter = ffi.new('ImGuiTextFilter[1]')

local physics = {}
physics.physmult = 1

local timeUpdateQueued = false
local timeUpdateTimer = 0
local timeUpdateTimeout = 0.05
local defaultTempCurve
local defaultTempCurveSet = false
local defaultSimSpeedSet = false
local defaultGravitySet = false
local defaultWeatherSet = false
local defaultSunSet = false
local envReportRate = 1
local lastEnvReport = 0
local firstReport = false
local lastTeleport = 0
local worldReadyState = 0
local envObjectIdCache = {}

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

local function rxCEIstate(data)
	data = jsonDecode(data)
	windowOpen[0] = data[1]
	if windowOpen[0] then
		gui.showWindow("CEI")
	else
		gui.hideWindow("CEI")
	end
end

local function rxCEItp(data)
	data = jsonDecode(data)
	canTeleport = data[1]
end

local function rxInputUpdate(data)
	if data == "config" then
		configValsSet = false
	elseif data == "environment" then
		environmentValsSet = false
	elseif data == "nametags" then
		nametagsValsSet = false
	elseif data == "players" then
		playersValsSet = {}
	elseif data == "playersDatabase" then
		playersDatabaseValsSet = false
	end
end

local function rxEnvironment(data)
	environment = jsonDecode(data)
	if environmentValsSet == false then
		environmentVals.ToDVal = im.FloatPtr(tonumber(environment.ToD))
		environmentVals.dayLengthInt = im.IntPtr(tonumber(environment.dayLength))
		environmentVals.dayScaleVal = im.FloatPtr(tonumber(environment.dayScale))
		environmentVals.nightScaleVal = im.FloatPtr(tonumber(environment.nightScale))
		environmentVals.sunAzimuthVal = im.FloatPtr(tonumber(environment.sunAzimuth))
		environmentVals.skyBrightnessVal = im.FloatPtr(tonumber(environment.skyBrightness))
		environmentVals.sunSizeVal = im.FloatPtr(tonumber(environment.sunSize))
		environmentVals.rayleighScatteringVal = im.FloatPtr(tonumber(environment.rayleighScattering))
		environmentVals.sunLightBrightnessVal = im.FloatPtr(tonumber(environment.sunLightBrightness))
		environmentVals.flareScaleVal = im.FloatPtr(tonumber(environment.flareScale))
		environmentVals.occlusionScaleVal = im.FloatPtr(tonumber(environment.occlusionScale))
		environmentVals.exposureVal = im.FloatPtr(tonumber(environment.exposure))
		environmentVals.shadowDistanceInt = im.IntPtr(tonumber(environment.shadowDistance))
		environmentVals.shadowSoftnessVal = im.FloatPtr(tonumber(environment.shadowSoftness))
		environmentVals.shadowSplitsInt = im.IntPtr(tonumber(environment.shadowSplits))
		environmentVals.shadowTexSizeInt = im.IntPtr(tonumber(environment.shadowTexSize))
		environmentVals.shadowLogWeightVal = im.FloatPtr(tonumber(environment.shadowLogWeight))
		environmentVals.visibleDistanceInt = im.IntPtr(tonumber(environment.visibleDistance))
		environmentVals.moonAzimuthVal = im.FloatPtr(tonumber(environment.moonAzimuth))
		environmentVals.moonElevationVal = im.FloatPtr(tonumber(environment.moonElevation))
		environmentVals.moonScaleVal = im.FloatPtr(tonumber(environment.moonScale))
		environmentVals.fogDensityVal = im.FloatPtr(tonumber(environment.fogDensity))
		environmentVals.fogDensityOffsetVal = im.FloatPtr(tonumber(environment.fogDensityOffset))
		environmentVals.fogAtmosphereHeightVal = im.FloatPtr(tonumber(environment.fogAtmosphereHeight))
		environmentVals.cloudHeightVal = im.FloatPtr(tonumber(environment.cloudHeight))
		environmentVals.cloudCoverVal = im.FloatPtr(tonumber(environment.cloudCover))
		environmentVals.cloudSpeedVal = im.FloatPtr(tonumber(environment.cloudSpeed))
		environmentVals.cloudExposureVal = im.FloatPtr(tonumber(environment.cloudExposure))
		environmentVals.rainDropsInt = im.IntPtr(tonumber(environment.rainDrops))
		environmentVals.dropSizeVal = im.FloatPtr(tonumber(environment.dropSize))
		environmentVals.dropMinSpeedVal = im.FloatPtr(tonumber(environment.dropMinSpeed))
		environmentVals.dropMaxSpeedVal = im.FloatPtr(tonumber(environment.dropMaxSpeed))
		environmentVals.teleportTimeoutInt = im.IntPtr(tonumber(environment.teleportTimeout))
		environmentVals.simSpeedVal = im.FloatPtr(tonumber(environment.simSpeed))
		environmentVals.gravityVal = im.FloatPtr(tonumber(environment.gravity))
		environmentVals.tempCurveNoonInt = im.IntPtr(tonumber(environment.tempCurveNoon))
		environmentVals.tempCurveDuskInt = im.IntPtr(tonumber(environment.tempCurveDusk))
		environmentVals.tempCurveMidnightInt = im.IntPtr(tonumber(environment.tempCurveMidnight))
		environmentVals.tempCurveDawnInt = im.IntPtr(tonumber(environment.tempCurveDawn))
		environmentValsSet = true
	end
end

local function rxConfigData(data)
	config = jsonDecode(data)
	if tonumber(config.resets.timeout) > 0 then
		resetsBlockedInputActions = allResetsBlockedInputActions
	else
		resetsBlockedInputActions = {}
	end
	if configValsSet == false then
		configVals.server = {}
		configVals.cobalt = {}
		configVals.resets = {}
		configVals.resets.messageDuration = im.IntPtr(tonumber(config.resets.messageDuration))
		configVals.resets.timeout = im.IntPtr(tonumber(config.resets.timeout))
		configVals.resets.title = im.ArrayChar(128)
		configVals.resets.elapsedMessage = im.ArrayChar(256)
		configVals.resets.message = im.ArrayChar(256)
		configVals.resets.disabledMessage = im.ArrayChar(256)
		configVals.cobalt.groups = {}
		configVals.cobalt.permissions = {}
		configVals.cobalt.permissions.vehicleCap = {}
		configVals.cobalt.permissions.vehiclePerm = {}
		configVals.nametags = {}
		configVals.nametags.settings = {}
		configVals.server.nameInput = im.ArrayChar(128)
		configVals.server.mapInput = im.ArrayChar(128)
		configVals.server.descriptionInput = im.ArrayChar(256)
		configVals.server.maxCarsInt = im.IntPtr(tonumber(config.server.maxCars))
		configVals.server.maxPlayersInt = im.IntPtr(tonumber(config.server.maxPlayers))
		configVals.cobalt.newRCONpassword = im.ArrayChar(128)
		configVals.cobalt.newRCONport = im.ArrayChar(128)
		configVals.cobalt.newCobaltDBport = im.ArrayChar(128)
		configVals.cobalt.newGroupInput = im.ArrayChar(128)
		configVals.cobalt.whitelistNameInput = im.ArrayChar(128)
		configVals.cobalt.maxActivePlayersInt = im.IntPtr(tonumber(config.cobalt.maxActivePlayers))
		configVals.cobalt.permissions.newLevelInput = im.ArrayChar(128)
		configVals.cobalt.permissions.newVehicleInput = im.ArrayChar(128)
		local tempFilterTable = {}
		for k,v in pairs(config.cobalt.permissions.vehiclePerm) do
			tempFilterTable[k] = config.cobalt.permissions.vehiclePerm[k].name
		end
		vehiclePermsFiltering.lines = im.ArrayCharPtrByTbl(tempFilterTable)
		configVals.nametags.whitelistNameInput = im.ArrayChar(128)
		configVals.nametags.settings.blockingTimeoutInt = im.IntPtr(tonumber(config.nametags.settings.blockingTimeout))
		for k,v in pairs(config.cobalt.groups) do
			configVals.cobalt.groups[k] = {}
			configVals.cobalt.groups[k].groupPerms = {}
			configVals.cobalt.groups[k].groupPerms.groupLevelInt = im.IntPtr(tonumber(config.cobalt.groups[k].groupPerms.level)) or im.IntPtr(0)
			configVals.cobalt.groups[k].groupPerms.groupBanReasonInput = im.ArrayChar(128)
			configVals.cobalt.groups[k].groupPerms.newGroupPlayerInput = im.ArrayChar(128)
			configVals.cobalt.groups[k].groupPerms.newGroupPermissionInput = im.ArrayChar(128)
		end
		for k,v in pairs(config.cobalt.permissions.vehicleCap) do
			configVals.cobalt.permissions.vehicleCap[k] = {}
			configVals.cobalt.permissions.vehicleCap[k].vehiclesInt = im.IntPtr(tonumber(config.cobalt.permissions.vehicleCap[k].vehicles))
		end
		for k,v in pairs(config.cobalt.permissions.vehiclePerm) do
		configVals.cobalt.permissions.vehiclePerm[k] = {}
			configVals.cobalt.permissions.vehiclePerm[k].nameInput = im.ArrayChar(128)
			configVals.cobalt.permissions.vehiclePerm[k].levelInt = im.IntPtr(tonumber(config.cobalt.permissions.vehiclePerm[k].level))
			configVals.cobalt.permissions.vehiclePerm[k].partLevelnameInput = im.ArrayChar(128)
			if config.cobalt.permissions.vehiclePerm[k].partLevel then
				configVals.cobalt.permissions.vehiclePerm[k].partLevel = {}
				for i,j in pairs(config.cobalt.permissions.vehiclePerm[k].partLevel) do
					configVals.cobalt.permissions.vehiclePerm[k].partLevel[i] = {}
					configVals.cobalt.permissions.vehiclePerm[k].partLevel[i].levelInt = im.IntPtr(tonumber(config.cobalt.permissions.vehiclePerm[k].partLevel[i].level))
				end
			end
		end
		configValsSet = true
	end
end

local function rxPlayerGroup(data)
	currentGroup = data
end

local function rxPlayersDatabase(data)
	playersDatabase = jsonDecode(data)
	if playersDatabaseValsSet == false then
		for k,v in pairs(playersDatabase) do
			playersDatabaseVals[k] = {}
			playersDatabaseVals[k].permissions = {}
			if playersDatabase[k].permissions then
				if tonumber(playersDatabase[k].permissions.level) then
					playersDatabaseVals[k].permissions.levelInt = im.IntPtr(playersDatabase[k].permissions.level)
				else
					playersDatabaseVals[k].permissions.levelInt = im.IntPtr(1)
				end
			end
			playersDatabaseVals[k].permissions.groupInput = im.ArrayChar(128)
		end
		playersDatabaseVals.kickBanMuteReason = im.ArrayChar(128)
		playersDatabaseVals.tempBanLength = im.FloatPtr(1)
		playersDatabaseValsSet = true
	end
	local tempFilterTable = {}
	for k,v in pairs(playersDatabase) do
		local i = playersDatabase[k].playerName
		tempFilterTable[k] = i
	end
	playersDatabaseVals.lines = im.ArrayCharPtrByTbl(tempFilterTable)
end

local function rxPlayersData(data)
	players = jsonDecode(data)
	for playerID, data in pairs(players) do
		if playersValsSet[playerID] == false or playersValsSet[playerID] == nil then
			playersVals[playerID] = {}
			playersVals[playerID].permissions = {}
			playersVals[playerID].kickBanMuteReason = im.ArrayChar(128)
			playersVals[playerID].tempBanLength = im.FloatPtr(tonumber(players[playerID].tempBanLength))
			playersVals[playerID].vehDeleteReason = im.ArrayChar(128)
			playersVals[playerID].permissions.levelInt = im.IntPtr(tonumber(players[playerID].tempPermLevel))
			playersVals[playerID].permissions.groupInput = im.ArrayChar(128)
			playersValsSet[playerID] = true
		end
	end
end

local function rxNametagWhitelisted(data)
	data = jsonDecode(data)
	nametagWhitelisted = data[1]
end

local function rxNametagBlockerActive(data)
	data = jsonDecode(data)
	nametagBlockerActive = data[1]
end

local function rxNametagBlockerTimeout(data)
	if tonumber(data) == 0 then
		nametagBlockerTimeout = nil
	else
		nametagBlockerTimeout = tonumber(data)
	end
end

local function teleportPlayerToVeh(targetName, player_id)
	TriggerServerEvent("CEITeleportFrom", player_id)
end

local function CEIRaceCountdown(data)
	log('W', logTag, "CEIRaceCountdown Called: " .. data)
	data = jsonDecode(data)
	local msg = data[1]
	local ttl = data[2]
	local big = data[3]
	guihooks.trigger('ScenarioFlashMessage', {{msg, ttl, 0, big}} )
end

local function CEIRaceCountSound(data)
	log('W', logTag, "CEIRaceCountSound Called: " .. data)
	Engine.Audio.playOnce('AudioGui', '/art/sound/' .. data)
end

local function drawCEI(dt)
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
	im.Begin("Cobalt Essentials Interface")
	if config.resets then
		if firstReset then
			if not config.resets.enabled then
				if config.resets.control then
					im.Text("Vehicle resetting")
					im.SameLine()
					im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "DISABLED")
				else
					im.Text("Vehicle reset")
					im.SameLine()
					im.TextColored(im.ImVec4(0.0, 1.0, 0.0, 1.0), "AVAILABLE")
				end
				
			elseif config.resets.timeout - resetsTimerElapsedReset > 0 then
				im.Text("Vehicle reset")
				im.SameLine()
				im.TextColored(im.ImVec4(1.0, 0.9, 0.0, 1.0), "TIMEOUT")
				im.SameLine()
				im.Text(string.format("%.2f",config.resets.timeout - resetsTimerElapsedReset) .. "s")
			else
				im.Text("Vehicle reset")
				im.SameLine()
				im.TextColored(im.ImVec4(0.0, 1.0, 0.0, 1.0), "AVAILABLE")
			end
		else
			im.Text("Vehicle reset")
			im.SameLine()
			im.TextColored(im.ImVec4(0.0, 1.0, 0.0, 1.0), "AVAILABLE")
		end
	end
	if environment.teleportTimeout then
		if firstTeleport then
			if not canTeleport then
				im.SameLine()
				im.Text("| Teleport")
				im.SameLine()
				im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "DISABLED")
			elseif tonumber(environment.teleportTimeout) - lastTeleport > 0 then
				im.SameLine()
				im.Text("| Teleport")
				im.SameLine()
				im.TextColored(im.ImVec4(1.0, 0.9, 0.0, 1.0), "TIMEOUT")
				im.SameLine()
				im.Text(string.format("%.2f",tonumber(environment.teleportTimeout) - lastTeleport) .. "s")
			else
				im.SameLine()
				im.Text("| Teleport")
				im.SameLine()
				im.TextColored(im.ImVec4(0.0, 1.0, 0.0, 1.0), "AVAILABLE")
			end
		else
			im.SameLine()
			im.Text("| Teleport")
			im.SameLine()
			im.TextColored(im.ImVec4(0.0, 1.0, 0.0, 1.0), "AVAILABLE")
		end
	end
	local tempToD = core_environment.getTimeOfDay()
	local curSecs
	if tempToD then
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
		local currentTempC = core_environment.getTemperatureK() - 273.15
		local currentTempCString = string.format("%.2f",core_environment.getTemperatureK() - 273.15)
		local currentTempF = currentTempC * 9/5 + 32
		local currentTempFString = string.format("%.2f",currentTempC * 9/5 + 32)
		im.SameLine()
		im.Text("Current temp: " .. currentTempCString .. " °C / " .. currentTempFString .. " °F")
	end
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
			if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" or currentGroup == "default" then
				if im.SmallButton("Race Countdown!") then
					for k,v in pairs(players) do
						if players[k].includeInRace == true then
							if players[k].vehicles then
								for x,y in pairs(players[k].vehicles) do
									local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), true } )
									TriggerServerEvent("CEIToggleRaceLock", data)
									log('W', logTag, "CEIToggleRaceLock Called: " .. data)
								end
							end
						end
					end
					local data = jsonEncode( { true } )
					TriggerServerEvent("CEIPreRace", data)
					log('W', logTag, "CEIPreRace Called: " .. data)
				end
			end
			im.PopStyleColor(3)
			im.SameLine()
			if includeInRace == false then
				im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.55, 0.05, 0.333))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.55, 0.09, 0.5))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.55, 0.05, 0.999))
				if im.SmallButton("Join Race") then
					local data = jsonEncode( { true } )
					TriggerServerEvent("CEIRaceInclude", data)
					log('W', logTag, "CEIRaceInclude Called: " .. data)
					includeInRace = true
				end
				im.PopStyleColor(3)
			else
				im.PushStyleColor2(im.Col_Button, im.ImVec4(0.77, 0.15, 0.05, 0.333))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.77, 0.1, 0.09, 0.5))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.77, 0.05, 0.05, 0.999))
				if im.SmallButton("Leave Race") then
					local data = jsonEncode( { false } )
					TriggerServerEvent("CEIRaceInclude", data)
					log('W', logTag, "CEIRaceInclude Called: " .. data)
					includeInRace = false
				end
				im.PopStyleColor(3)
			end
			im.Separator()
			if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
				im.PushStyleColor2(im.Col_Button, im.ImVec4(1.0, 0.0, 0.1, 0.333))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(1.0, 0.2, 0.0, 0.5))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.9, 0.0, 0.0, 0.999))
				if im.SmallButton("Remote Stop All") then
					for k,v in pairs(players) do
						for x,y in pairs(players[k].vehicles) do
							local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), false } )
							TriggerServerEvent("CEIToggleIgnition", data)
							log('W', logTag, "CEIToggleIgnition Called: " .. data)
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
						for x,y in pairs(players[k].vehicles) do
							local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), true } )
							TriggerServerEvent("CEIToggleLock", data)
							log('W', logTag, "CEIToggleLock Called: " .. data)
						end
					end
				end
				im.PopStyleColor(3)
				im.PushStyleColor2(im.Col_Button, im.ImVec4(0.1, 1.0, 0.1, 0.333))
				im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.2, 1.0, 0.2, 0.5))
				im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.0, 0.9, 0.0, 0.999))
				if im.SmallButton("Remote Start All") then
					for k,v in pairs(players) do
						for x,y in pairs(players[k].vehicles) do
							local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), true } )
							TriggerServerEvent("CEIToggleIgnition", data)
							log('W', logTag, "CEIToggleIgnition Called: " .. data)
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
						for x,y in pairs(players[k].vehicles) do
							local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), false } )
							TriggerServerEvent("CEIToggleLock", data)
							log('W', logTag, "CEIToggleLock Called: " .. data)
						end
					end
				end
				im.PopStyleColor(3)
				im.Separator()
			end
----------------------------------------------------------------------------------PLAYER HEADER
			for k,v in pairs(players) do
				local vehiclesCounter = 0
				if players[k].vehicles then
					for x,y in pairs(players[k].vehicles) do
						vehiclesCounter = vehiclesCounter + 1
					end
				end
				if players[k].permissions.group == "owner" then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.6, 0.00, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.7, 0.0, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.8, 0.0, 0.0, 0.5))
				elseif players[k].permissions.group == "admin" then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.2, 0.00, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.3, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.4, 0.0, 0.5))
				elseif  players[k].permissions.group == "mod" then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(1, 0.6, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(1, 0.7, 0.0, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(1, 0.8, 0.0, 0.5))
				elseif  players[k].permissions.group == "default"  then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.77, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.88, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.66))
				elseif  players[k].permissions.group == "guest" then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.1, 0.1, 0.1, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.1, 0.1, 0.1, 0.5))
				elseif  players[k].permissions.group == "inactive" then
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.4, 0.4, 0.4, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.4, 0.5))
				else
					im.PushStyleColor2(im.Col_Header, im.ImVec4(0.25, 0.25, 0.5, 0.5))
					im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(0.33, 0.33, 0.66, 0.5))
					im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(0.4, 0.4, 0.77, 0.5))
				end
				if players[k].includeInRace == true then
					im.PushStyleColor2(im.Col_Text, im.ImVec4(0.1, 1, 0.1, 1))
				else
					im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 1, 1, 1))
				end
				if im.CollapsingHeader1(players[k].playerName) then
					im.PopStyleColor(4)
					im.Indent()
					if im.SmallButton("Vote Kick##"..tostring(k)) then
					local data = jsonEncode( { players[k].playerName } )
						TriggerServerEvent("CEIVoteKick", data)
						log('W', logTag, "CEIVoteKick Called: " .. data)
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						im.SameLine()
						if im.SmallButton("Kick##"..tostring(k)) then
						local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEIKick", data)
							log('W', logTag, "CEIKick Called: " .. data)
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" then
						im.SameLine()
						if im.SmallButton("Ban##"..tostring(k)) then
							local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEIBan", data)
							log('W', logTag, "CEIBan Called: " .. data)
						end
						im.SameLine()
						if im.SmallButton("TempBan##"..tostring(k)) then
							local data = jsonEncode( { players[k].playerName, playersVals[k].tempBanLength[0], ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEITempBan", data)
							log('W', logTag, "CEITempBan Called: " .. data)
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						im.SameLine()
						if players[k].permissions.muted == false then
							if im.SmallButton("Mute##"..tostring(k)) then
								local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
								TriggerServerEvent("CEIMute", data)
								log('W', logTag, "CEIMute Called: " .. data)
							end
						elseif players[k].permissions.muted == true then
							if im.SmallButton("Unmute##"..tostring(k)) then
								local data = jsonEncode( { players[k].playerName } )
								TriggerServerEvent("CEIUnmute", data)
								log('W', logTag, "CEIUnmute Called: " .. data)
							end
						end
						im.SameLine()
						if players[k].permissions.whitelisted == false then
							if im.SmallButton("Whitelist##" .. tostring(k)) then
								local data = jsonEncode( { "add", players[k].playerName } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						elseif players[k].permissions.whitelisted == true then
							if im.SmallButton("Unwhitelist##" .. tostring(k)) then
								local data = jsonEncode( { "remove", players[k].playerName } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						end
					end
					if vehiclesCounter > 0 then
						if canTeleport then
							if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
							else
								im.SameLine()
							end
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								if lastTeleport >= tonumber(environment.teleportTimeout) then
									lastTeleport = 0
									MPVehicleGE.teleportVehToPlayer(players[k].playerName)
								end
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
								im.SameLine()
								if im.SmallButton("Teleport From##" .. tostring(k)) then
									if lastTeleport >= tonumber(environment.teleportTimeout) then
										lastTeleport = 0
										teleportPlayerToVeh(players[k].playerName,players[k].playerID)
									end
								end
								im.SameLine()
								im.ShowHelpMarker("Teleport this player's current vehicle to you.")
							end
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						im.Text("		")
						im.SameLine()
						im.Text("Reason:")
						im.SameLine()
						if im.InputTextWithHint("##"..tostring(k), "Kick or (temp)Ban or Mute Reason", playersVals[k].kickBanMuteReason, 128) then
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" then
						im.Text("		")
						im.SameLine()
						im.Text("tempBan:")
						im.SameLine()
						im.PushItemWidth(120)
						if im.InputFloat("##tempBanLength"..tostring(k), playersVals[k].tempBanLength, 0.001, 1) then
							if playersVals[k].tempBanLength[0] < 0.001 then
								playersVals[k].tempBanLength = im.FloatPtr(0.001)
							elseif playersVals[k].tempBanLength[0] > 3650 then
								playersVals[k].tempBanLength = im.FloatPtr(3650)
							end
							local data = jsonEncode( { players[k].playerName, tostring(playersVals[k].tempBanLength[0]) } )
							TriggerServerEvent("CEISetTempBan", data)
							log('W', logTag, "CEISetTempBan Called: " .. data)
						end
						im.SameLine()
						im.Text("days = " .. string.format("%.2f", (playersVals[k].tempBanLength[0] * 1440)) .. " minutes")
						im.PopItemWidth()
					end
					if vehiclesCounter > 0 then
						im.Separator()
						if im.TreeNode1("vehicles:##"..tostring(k)) then
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
								im.Text("		")
								im.SameLine()
								im.Text("Reason:")
								im.SameLine()
								if im.InputTextWithHint("##vehReason"..tostring(k), "Vehicle Delete Reason", playersVals[k].vehDeleteReason, 128) then
								end
							end
							for x,y in pairs(players[k].vehicles) do
								if players[k].currentVehicle == tostring(players[k].playerID) .. "-" .. tostring(players[k].vehicles[x].vehicleID) then
									im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "	@")
									im.SameLine()
								else
									im.Text("		")
									im.SameLine()
								end
								im.Text(tostring(players[k].vehicles[x].vehicleID) .. ":")
								im.SameLine()
								im.Text(players[k].vehicles[x].jbm)
								if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
									for i,j in pairs(ignitionEnabled) do
										if i == MPVehicleGE.getGameVehicleID(tostring(players[k].playerID) .. "-" .. tostring(players[k].vehicles[x].vehicleID)) then
											if j == true then
												im.SameLine()
												if im.SmallButton("Remote Stop##"..tostring(x)) then
													local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), false } )
													TriggerServerEvent("CEIToggleIgnition", data)
													log('W', logTag, "CEIToggleIgnition Called: " .. data)
												end
											elseif j == false then
												im.SameLine()
												if im.SmallButton("Remote Start##"..tostring(x)) then
													local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), true } )
													TriggerServerEvent("CEIToggleIgnition", data)
													log('W', logTag, "CEIToggleIgnition Called: " .. data)
												end
											end
										end
									end
								end
								if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
									for i,j in pairs(isFrozen) do
										if i == MPVehicleGE.getGameVehicleID(tostring(players[k].playerID) .. "-" .. tostring(players[k].vehicles[x].vehicleID)) then
											if j == false then
												im.SameLine()
												if im.SmallButton("Freeze##"..tostring(x)) then
													local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), true } )
													TriggerServerEvent("CEIToggleLock", data)
													log('W', logTag, "CEIToggleLock Called: " .. data)
												end
											elseif j == true then
												im.SameLine()
												if im.SmallButton("Unfreeze##"..tostring(x)) then
													local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), false } )
													TriggerServerEvent("CEIToggleLock", data)
													log('W', logTag, "CEIToggleLock Called: " .. data)
												end
											end
										end
									end
									im.SameLine()
									if im.SmallButton("Delete##"..tostring(x)) then
										local data = jsonEncode( { players[k].playerID, tostring(players[k].vehicles[x].vehicleID), ffi.string(playersVals[k].vehDeleteReason) } )
										TriggerServerEvent("CEIRemoveVehicle", data)
										log('W', logTag, "CEIRemoveVehicle Called: " .. data)
									end
								end
							end
							im.TreePop()
							im.Separator()
						else
							im.SameLine()
							im.Text(tostring(vehiclesCounter))
							im.Separator()
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						if im.TreeNode1("info##"..tostring(k)) then
							im.Text("		playerID: " .. players[k].playerID)
							im.Text("		connectStage: " .. players[k].connectStage)
							im.Text("		guest: " .. tostring(players[k].guest))
							im.Text("		joinTime: " .. string.format("%.2f",players[k].joinTime))
							im.SameLine()
							im.Text("| connectedTime: " .. string.format("%.2f",players[k].connectedTime))
							im.Separator()
							if im.TreeNode1("permissions##"..tostring(k)) then
								if currentGroup == "owner" or currentGroup == "admin" then
									if players[k].teleport == false then
										if im.SmallButton("Allow Teleport##"..tostring(k)) then
											local data = jsonEncode( { players[k].playerName, true } )
											TriggerServerEvent("CEISetTeleportPerm", data)
											log('W', logTag, "CEISetTeleportPerm Called: " .. data)
										end
									elseif players[k].teleport == true then
										if im.SmallButton("Revoke Teleport##"..tostring(k)) then
											local data = jsonEncode( { players[k].playerName, false } )
											TriggerServerEvent("CEISetTeleportPerm", data)
											log('W', logTag, "CEISetTeleportPerm Called: " .. data)
										end
									end
								end
								if im.TreeNode1("level:") then
									im.SameLine()
									im.Text(tostring(players[k].permissions.level))
									if currentGroup == "owner" or currentGroup == "admin" then
										im.Text("		")
										im.SameLine()
										im.PushItemWidth(100)
										if im.InputInt("", playersVals[k].permissions.levelInt, 1) then
											local data = jsonEncode( { players[k].playerName, tostring(playersVals[k].permissions.levelInt[0]) } )
											TriggerServerEvent("CEISetTempPerm", data)
											log('W', logTag, "CEISetTempPerm Called: " .. data)
										end
										im.PopItemWidth()
										im.SameLine()
										if im.Button("Apply##level"..tostring(x)) then
											local data = jsonEncode( { players[k].playerName, tostring(playersVals[k].permissions.levelInt[0]) } )
											TriggerServerEvent("CEISetPerm", data)
											log('W', logTag, "CEISetPerm Called: " .. data)
										end
									end
									im.TreePop()
								else
									im.SameLine()
									im.Text(tostring(players[k].permissions.level))
								end
								im.Text("		whitelisted: " .. tostring(players[k].permissions.whitelisted))
								im.Text("		muted: " .. tostring(players[k].permissions.muted))
								im.Text("		muteReason: " .. players[k].permissions.muteReason)
								im.Text("		banned: " .. tostring(players[k].permissions.banned))
								if im.TreeNode1("group:##"..tostring(k)) then
									im.SameLine()
									im.Text(players[k].permissions.group)
									if currentGroup == "owner" or currentGroup == "admin" then
										im.Text("		")
										im.SameLine()
										if im.InputTextWithHint("##newGroup", "Group Name", playersVals[k].permissions.groupInput, 128) then
										end
										im.Text("		")
										im.SameLine()
										if im.SmallButton("Apply##"..tostring(k)) then
											local data = jsonEncode( { players[k].playerID, "group:" .. ffi.string(playersVals[k].permissions.groupInput) } )
											TriggerServerEvent("CEISetGroup", data)
											log('W', logTag, "CEISetGroup Called: " .. data)
										end
										im.SameLine()
										im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
										im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
										im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
										if im.SmallButton("Remove##"..tostring(k)) then
											local data = jsonEncode( { players[k].playerID, "none" } )
											TriggerServerEvent("CEISetGroup", data)
											log('W', logTag, "CEISetGroup Called: " .. data)
										end
										im.PopStyleColor(3)
										im.SameLine()
										im.ShowHelpMarker("Remove group or enter new Group Name and press Apply")
									end
									im.TreePop()
								else
									im.SameLine()
									im.Text(players[k].permissions.group)
								end
								im.TreePop()
							end
							im.Separator()
							if im.TreeNode1("gamemode##"..tostring(k)) then
								im.Text("		mode: " .. players[k].gamemode.mode)
								im.Text("		source: " .. players[k].gamemode.source)
								im.Text("		queue: " .. players[k].gamemode.queue)
								im.Text("		locked: " .. tostring(players[k].gamemode.locked))
								im.TreePop()
							end
							im.TreePop()
						end
					end
					im.Unindent()
				else
					im.PopStyleColor(4)
					im.Indent()
					if im.SmallButton("Vote Kick##"..tostring(k)) then
					local data = jsonEncode( { players[k].playerName } )
						TriggerServerEvent("CEIVoteKick", data)
						log('W', logTag, "CEIVoteKick Called: " .. data)
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						im.SameLine()
						if im.SmallButton("Kick##"..tostring(k)) then
						local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEIKick", data)
							log('W', logTag, "CEIKick Called: " .. data)
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" then
						im.SameLine()
						if im.SmallButton("Ban##"..tostring(k)) then
							local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEIBan", data)
							log('W', logTag, "CEIBan Called: " .. data)
						end
						im.SameLine()
						if im.SmallButton("TempBan##"..tostring(k)) then
							local data = jsonEncode( { players[k].playerName, playersVals[k].tempBanLength[0], ffi.string(playersVals[k].kickBanMuteReason) } )
							TriggerServerEvent("CEITempBan", data)
							log('W', logTag, "CEITempBan Called: " .. data)
						end
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						im.SameLine()
						if players[k].permissions.muted == false then
							if im.SmallButton("Mute##"..tostring(k)) then
								local data = jsonEncode( { players[k].playerName, ffi.string(playersVals[k].kickBanMuteReason) } )
								TriggerServerEvent("CEIMute", data)
								log('W', logTag, "CEIMute Called: " .. data)
							end
						elseif players[k].permissions.muted == true then
							if im.SmallButton("Unmute##"..tostring(k)) then
								local data = jsonEncode( { players[k].playerName } )
								TriggerServerEvent("CEIUnmute", data)
								log('W', logTag, "CEIUnmute Called: " .. data)
							end
						end
						im.SameLine()
						if players[k].permissions.whitelisted == false then
							if im.SmallButton("Whitelist##" .. tostring(k)) then
								local data = jsonEncode( { "add", players[k].playerName } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						elseif players[k].permissions.whitelisted == true then
							if im.SmallButton("Unwhitelist##" .. tostring(k)) then
								local data = jsonEncode( { "remove", players[k].playerName } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						end
					end
					if vehiclesCounter > 0 then
						if canTeleport then
							if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
							else
								im.SameLine()
							end
							if im.SmallButton("Focus##" .. tostring(k)) then
								MPVehicleGE.focusCameraOnPlayer(players[k].playerName)
							end
							im.SameLine()
							im.ShowHelpMarker("Cycle camera through this player's vehicles.")
							im.SameLine()
							if im.SmallButton("Teleport To##" .. tostring(k)) then
								if lastTeleport >= tonumber(environment.teleportTimeout) then
									lastTeleport = 0
									MPVehicleGE.teleportVehToPlayer(players[k].playerName)
								end
							end
							im.SameLine()
							im.ShowHelpMarker("Teleport to this player's current vehicle.")
							if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
								im.SameLine()
								if im.SmallButton("Teleport From##" .. tostring(k)) then
									if lastTeleport >= tonumber(environment.teleportTimeout) then
										lastTeleport = 0
										teleportPlayerToVeh(players[k].playerName,players[k].playerID)
									end
								end
								im.SameLine()
								im.ShowHelpMarker("Teleport this player's current vehicle to you.")
							end
						end
					end
					im.Unindent()
				end
			end
			im.EndTabItem()
		end
----------------------------------------------------------------------------------CONFIG TAB
		if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
			if im.BeginTabItem("Config") then
----------------------------------------------------------------------------------COBALT HEADER
				if im.CollapsingHeader1("Cobalt Essentials") then
					im.Indent()
					local vehiclePerms = config.cobalt.permissions.vehiclePerm
					local vehiclePermsCounter = 0
					for a,b in pairs(vehiclePerms) do
						vehiclePermsCounter = vehiclePermsCounter + 1
					end
					if currentGroup == "owner" or currentGroup == "admin" then
						if im.TreeNode1("vehiclePerms:") then
							im.SameLine()
							im.Text(tostring(vehiclePermsCounter))
							im.Text("	Add vehicle: ")
							im.SameLine()
							if im.InputTextWithHint("##newVehicle", "New Vehicle", configVals.cobalt.permissions.newVehicleInput, 128) then
							end
							im.Text("	")
							im.SameLine()
							if im.SmallButton("Apply##newVehPerm") then
								local data = jsonEncode( { ffi.string(configVals.cobalt.permissions.newVehicleInput) } )
								TriggerServerEvent("CEISetNewVehiclePerm", data)
								log('W', logTag, "CEISetNewVehiclePerm Called: " .. data)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter new vehicle and press Apply")
							im.ImGuiTextFilter_Draw(vehiclePermsFiltering.filter[0])
							for k,v in pairs(vehiclePerms) do
								local vehiclePermsPartLevels = config.cobalt.permissions.vehiclePerm[k].partLevel
								for i = 0, im.GetLengthArrayCharPtr(vehiclePermsFiltering.lines) - 1 do
									if im.ImGuiTextFilter_PassFilter(vehiclePermsFiltering.filter[0], vehiclePermsFiltering.lines[i]) then
										if config.cobalt.permissions.vehiclePerm[k].name == ffi.string(vehiclePermsFiltering.lines[i]) then
											if im.TreeNode1(ffi.string(vehiclePermsFiltering.lines[i]) .. ":") then
												im.SameLine()
												im.Text("level: " .. config.cobalt.permissions.vehiclePerm[k].level)
												im.Text("	")
												im.SameLine()
												im.PushItemWidth(100)
												if im.InputInt("", configVals.cobalt.permissions.vehiclePerm[k].levelInt, 1) then
													local data = jsonEncode( { config.cobalt.permissions.vehiclePerm[k].name, tostring(configVals.cobalt.permissions.vehiclePerm[k].levelInt[0]) } )
													TriggerServerEvent("CEISetVehiclePermLevel", data)
													log('W', logTag, "CEISetVehiclePermLevel Called: " .. data)
												end
												im.PopItemWidth()
												im.SameLine()
												if im.SmallButton("Remove##vehPerm") then
													local data = jsonEncode( { config.cobalt.permissions.vehiclePerm[k].name } )
													TriggerServerEvent("CEIRemoveVehiclePerm", data)
													log('W', logTag, "CEIRemoveVehiclePerm Called: " .. data)
												end
												im.SameLine()
												im.ShowHelpMarker("In-/Decrease vehicle permission level requirement or Remove vehicle entry")
												im.Text("	Add part: ")
												im.SameLine()
												if im.InputTextWithHint("##newPart", "New Part", configVals.cobalt.permissions.vehiclePerm[k].partLevelnameInput, 128) then
												end
												im.Text("	")
												im.SameLine()
												if im.SmallButton("Apply##newVehPart") then
													local data = jsonEncode( { config.cobalt.permissions.vehiclePerm[k].name, ffi.string(configVals.cobalt.permissions.vehiclePerm[k].partLevelnameInput) } )
													TriggerServerEvent("CEISetNewVehiclePart", data)
													log('W', logTag, "CEISetNewVehiclePart Called: " .. data)
												end
												im.SameLine()
												im.ShowHelpMarker("Enter new part and press Apply")
												if vehiclePermsPartLevels then
													for a,b in pairs(vehiclePermsPartLevels) do
														local partName = string.gsub(config.cobalt.permissions.vehiclePerm[k].partLevel[a].name, "partlevel:", "")
														if im.TreeNode1(partName .. ":") then
															im.SameLine()
															im.Text("level: " .. config.cobalt.permissions.vehiclePerm[k].partLevel[a].level)
															im.Text("	")
															im.SameLine()
															im.PushItemWidth(100)
															if im.InputInt("", configVals.cobalt.permissions.vehiclePerm[k].partLevel[a].levelInt, 1) then
																local data = jsonEncode( { config.cobalt.permissions.vehiclePerm[k].name, partName, tostring(configVals.cobalt.permissions.vehiclePerm[k].partLevel[a].levelInt[0]) } )
																TriggerServerEvent("CEISetVehiclePartLevel", data)
																log('W', logTag, "CEISetVehiclePartLevel Called: " .. data)
															end
															im.PopItemWidth()
															im.SameLine()
															if im.SmallButton("Remove##vehPart") then
																local data = jsonEncode( { config.cobalt.permissions.vehiclePerm[k].name, partName } )
																TriggerServerEvent("CEIRemoveVehiclePart", data)
																log('W', logTag, "CEIRemoveVehiclePart Called: " .. data)
															end
															im.SameLine()
															im.ShowHelpMarker("In-/Decrease vehicle part permission level requirement or Remove vehicle part entry")
															im.TreePop()
														else
															im.SameLine()
															im.Text("level: " .. config.cobalt.permissions.vehiclePerm[k].partLevel[a].level)
														end
													end
												end
												im.TreePop()
											else
												im.SameLine()
												im.Text("level: " .. config.cobalt.permissions.vehiclePerm[k].level)
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
						local vehicleCaps = config.cobalt.permissions.vehicleCap
						local vehicleCapsCounter = 0
						for a,b in pairs(vehicleCaps) do
							vehicleCapsCounter = vehicleCapsCounter + 1
						end
						if im.TreeNode1("vehicleCaps:") then
							im.SameLine()
							im.Text(tostring(vehicleCapsCounter))
							for k,v in pairs(vehicleCaps) do
								if im.TreeNode1("level: " .. config.cobalt.permissions.vehicleCap[k].level .. " =") then
									im.SameLine()
									im.Text(config.cobalt.permissions.vehicleCap[k].vehicles .. " vehicles")
									im.Text("		")
									im.SameLine()
									im.PushItemWidth(100)
									if im.InputInt("", configVals.cobalt.permissions.vehicleCap[k].vehiclesInt, 1) then
										local data = jsonEncode( { config.cobalt.permissions.vehicleCap[k].level, tostring(configVals.cobalt.permissions.vehicleCap[k].vehiclesInt[0]) } )
										TriggerServerEvent("CEISetVehiclePerms", data)
										log('W', logTag, "CEISetVehiclePerms Called: " .. data)
									end
									im.PopItemWidth()
									im.SameLine()
									if im.SmallButton("Remove##"..tostring(k)) then
										local data = jsonEncode( { config.cobalt.permissions.vehicleCap[k].level } )
										TriggerServerEvent("CEIRemoveVehiclePermsLevel", data)
										log('W', logTag, "CEIRemoveVehiclePermsLevel Called: " .. data)
									end
									im.SameLine()
									im.ShowHelpMarker("In-/Decrease vehicles for level or Remove level entry")
									im.TreePop()
								else
									im.SameLine()
									im.Text(config.cobalt.permissions.vehicleCap[k].vehicles .. " vehicles")
								end
							end
							im.Text("		Add level: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputTextWithHint("##newLevel", "New Level", configVals.cobalt.permissions.newLevelInput, 128) then
							end
							im.PopItemWidth()
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##"..tostring(k)) then
								local data = jsonEncode( { ffi.string(configVals.cobalt.permissions.newLevelInput) } )
								TriggerServerEvent("CEISetNewVehiclePermsLevel", data)
								log('W', logTag, "CEISetNewVehiclePermsLevel Called: " .. data)
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
							if im.InputInt("", configVals.cobalt.maxActivePlayersInt, 1) then
								local data = jsonEncode( { tostring(configVals.cobalt.maxActivePlayersInt[0]) } )
								TriggerServerEvent("CEISetMaxActivePlayers", data)
								log('W', logTag, "CEISetMaxActivePlayers Called: " .. data)
							end
							im.PopItemWidth()
							im.TreePop()
						else
							im.SameLine()
							im.Text(config.cobalt.maxActivePlayers)
						end
						im.Separator()
						local groupCounter = 0
						for a,b in pairs(config.cobalt.groups) do
							groupCounter = groupCounter + 1
						end
						if im.TreeNode1("groups:") then
							im.SameLine()
							im.Text(tostring(groupCounter))
							for k,v in pairs(config.cobalt.groups) do
								im.Separator()
								local groupName = ( string.gsub(config.cobalt.groups[k].groupName, "group:", "") .. ":")
								if im.TreeNode1(groupName) then
									local groupPlayers = config.cobalt.groups[k].groupPlayers
									local groupPlayersCounter = 0
									if groupPlayers then
										for c,d in pairs(groupPlayers) do
											groupPlayersCounter = groupPlayersCounter + 1
										end
									end
									im.SameLine()
									im.Text(tostring(groupPlayersCounter))
									if config.cobalt.groups[k].groupPerms.level then
										if im.TreeNode1("group players:") then
											im.Separator()
											if groupPlayers then
												for w,z in pairs(groupPlayers) do
													im.Text("		")
													im.SameLine()
													im.Text(tostring(groupPlayers[w]))
													im.SameLine()
													im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
													im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
													im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
													if im.SmallButton("Remove##"..tostring(w)) then
														local data = jsonEncode( { groupPlayers[w], "none" } )
														TriggerServerEvent("CEISetGroup", data)
														log('W', logTag, "CEISetGroup Called: " .. data)
													end
													im.PopStyleColor(3)
												end
											end
											im.Text("		Add Player to Group: ")
											im.Text("		")
											im.SameLine()
											if im.InputTextWithHint("##groupPlayerName"..tostring(k), "Player Name", configVals.cobalt.groups[k].groupPerms.newGroupPlayerInput, 128) then
											end
											im.Text("		")
											im.SameLine()
											if im.SmallButton("Add##groupPlayerName"..tostring(k)) then
												local data = jsonEncode( { ffi.string(configVals.cobalt.groups[k].groupPerms.newGroupPlayerInput), config.cobalt.groups[k].groupName } )
												TriggerServerEvent("CEISetGroup", data)
												log('W', logTag, "CEISetGroup Called: " .. data)
											end
											im.SameLine()
											im.ShowHelpMarker("Enter Player Name to Add to Group and press Apply")
											im.Separator()
											im.TreePop()
										end
										im.Text("		level: ")
										im.SameLine()
										im.PushItemWidth(100)
										if im.InputInt("", configVals.cobalt.groups[k].groupPerms.groupLevelInt, 1) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "level", tostring(configVals.cobalt.groups[k].groupPerms.groupLevelInt[0]) } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										im.PopItemWidth()
									else
										im.Text("		level: ")
										im.SameLine()
										im.PushItemWidth(100)
										if im.InputInt("", configVals.cobalt.groups[k].groupPerms.groupLevelInt, 1) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "level", tostring(configVals.cobalt.groups[k].groupPerms.groupLevelInt[0]) } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										im.PopItemWidth()
									end
									for a,b in pairs(config.cobalt.groups[k].groupPerms) do
										if a ~= "level"
										and a ~= "whitelisted"
										and a ~= "muted"
										and a ~= "banned"
										and a ~= "banReason" then
											im.Text("		" .. a .. ": " .. tostring(b))
											im.SameLine()
											if config.cobalt.groups[k].groupPerms[a] == false then
												if im.SmallButton("Toggle##" .. a) then
													local data = jsonEncode( { config.cobalt.groups[k].groupName, a, true } )
													TriggerServerEvent("CEISetGroupPerms", data)
													log('W', logTag, "CEISetGroupPerms Called: " .. data)
												end
											else
												if im.SmallButton("Toggle##" .. a) then
													local data = jsonEncode( { config.cobalt.groups[k].groupName, a, false } )
													TriggerServerEvent("CEISetGroupPerms", data)
													log('W', logTag, "CEISetGroupPerms Called: " .. data)
												end
											end
											im.SameLine()
											im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
											im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
											im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
											if im.SmallButton("Remove Permission##" .. config.cobalt.groups[k].groupName) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, a, "null" } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
											im.PopStyleColor(3)
										end
									end
											
									if config.cobalt.groups[k].groupPerms.whitelisted then
										im.Text("		whitelisted: " .. tostring(config.cobalt.groups[k].groupPerms.whitelisted))
										im.SameLine()
										if config.cobalt.groups[k].groupPerms.whitelisted == false then
											if im.SmallButton("Whitelist##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "whitelisted", true } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
										elseif config.cobalt.groups[k].groupPerms.whitelisted == true then
											if im.SmallButton("Unwhitelist##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "whitelisted", false } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
											
										end
									else
										im.Text("		whitelisted: false")
										im.SameLine()
										if im.SmallButton("Whitelist##"..tostring(k)) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "whitelisted", true } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										
									end
									if config.cobalt.groups[k].groupPerms.muted  then
										im.Text("		muted: " .. tostring(config.cobalt.groups[k].groupPerms.muted))
										im.SameLine()
										if config.cobalt.groups[k].groupPerms.muted  == false then
											if im.SmallButton("Mute##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "muted", true } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
										elseif config.cobalt.groups[k].groupPerms.muted  == true then
											if im.SmallButton("Unmute##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "muted", false } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
											
										end
									else
										im.Text("		muted: false")
										im.SameLine()
										if im.SmallButton("Mute##"..tostring(k)) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "muted", true } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										
									end
									if config.cobalt.groups[k].groupPerms.banned then
										im.Text("		banned: " .. tostring(config.cobalt.groups[k].groupPerms.banned))
										im.SameLine()
										if config.cobalt.groups[k].groupPerms.banned == false then
											if im.SmallButton("Ban##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "banned", true } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
											
										elseif config.cobalt.groups[k].groupPerms.banned == true then
											if im.SmallButton("Unban##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "banned", false } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
											end
											
										end
									else
										im.Text("		banned: false")
										im.SameLine()
										if im.SmallButton("Ban##"..tostring(k)) then
												local data = jsonEncode( { config.cobalt.groups[k].groupName, "banned", true } )
												TriggerServerEvent("CEISetGroupPerms", data)
												log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
									end
									if config.cobalt.groups[k].groupPerms.banReason then
										im.Text("		banReason: " .. config.cobalt.groups[k].groupPerms.banReason)
										im.Text("		")
										im.SameLine()
										if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", configVals.cobalt.groups[k].groupPerms.groupBanReasonInput, 128) then
										end
										im.Text("		")
										im.SameLine()
										if im.SmallButton("Apply##"..tostring(k)) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "banReason", ffi.string(configVals.cobalt.groups[k].groupPerms.groupBanReasonInput) } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										im.SameLine()
										if im.SmallButton("Remove##"..tostring(k)) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "banReason" } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										im.SameLine()
										im.ShowHelpMarker("Remove banReason or enter new banReason and press Apply")
									else
										im.Text("		banReason: null")
										im.Text("		")
										im.SameLine()
										if im.InputTextWithHint("##banReason"..tostring(k), "Ban Reason", configVals.cobalt.groups[k].groupPerms.groupBanReasonInput, 128) then
										end
										im.Text("		")
										im.SameLine()
										if im.SmallButton("Apply##"..tostring(k)) then
											local data = jsonEncode( { config.cobalt.groups[k].groupName, "banReason", ffi.string(configVals.cobalt.groups[k].groupPerms.groupBanReasonInput) } )
											TriggerServerEvent("CEISetGroupPerms", data)
											log('W', logTag, "CEISetGroupPerms Called: " .. data)
										end
										im.SameLine()
										im.ShowHelpMarker("Enter new banReason and press Apply")
									end
									
									im.Text("		")
									im.Text("		Add New Permission to Group: ")
									im.Text("		")
									im.SameLine()
									if im.InputTextWithHint("##groupPermission"..tostring(k), "Permission Name", configVals.cobalt.groups[k].groupPerms.newGroupPermissionInput, 128) then
									end
									im.Text("		")
									im.SameLine()
									if im.SmallButton("Add##groupPermission"..tostring(k)) then
										local data = jsonEncode( { config.cobalt.groups[k].groupName, ffi.string(configVals.cobalt.groups[k].groupPerms.newGroupPermissionInput), true } )
										TriggerServerEvent("CEISetGroupPerms", data)
										log('W', logTag, "CEISetGroupPerms Called: " .. data)
									end
									im.SameLine()
									im.ShowHelpMarker("Enter Permission Name to Add to Group and press Apply")
									im.Text("		")
									
									im.Text("		")
									im.SameLine()
									im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
									im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
									im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
									if im.SmallButton("Remove Group##"..config.cobalt.groups[k].groupName) then
										local data = jsonEncode( { config.cobalt.groups[k].groupName } )
										TriggerServerEvent("CEIRemoveGroup", data)
										log('W', logTag, "CEIRemoveGroup Called: " .. data)
									end
									im.PopStyleColor(3)
									im.SameLine()
									im.ShowHelpMarker("Remove Group... CAREFUL WITH THIS")
									im.Text("		")
									im.TreePop()
								else
									local groupPlayers = config.cobalt.groups[k].groupPlayers
									local groupPlayersCounter = 0
									if groupPlayers then
										for c,d in pairs(groupPlayers) do
											groupPlayersCounter = groupPlayersCounter + 1
										end
									end
									im.SameLine()
									im.Text(tostring(groupPlayersCounter))
								end
							end
							im.Separator()
							im.Text("		Add Group: ")
							im.SameLine()
							if im.InputTextWithHint("##groupName", "Group Name", configVals.cobalt.newGroupInput, 128) then
							end
							im.Indent()
							im.Indent()
							im.Indent()
							im.Text("		")
							im.SameLine()
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##"..tostring(k)) then
								local data = jsonEncode( { ffi.string(configVals.cobalt.newGroupInput) } )
								TriggerServerEvent("CEISetNewGroup", data)
								log('W', logTag, "CEISetNewGroup Called: " .. data)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter new Group Name and press Apply")
							im.Unindent()
							im.Unindent()
							im.Unindent()
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(groupCounter))
						end
						im.Separator()
					end
					if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
						local whitelistPlayersCounter = 0
						if config.cobalt.whitelistedPlayers then
							for a,b in pairs(config.cobalt.whitelistedPlayers) do
								whitelistPlayersCounter = whitelistPlayersCounter + 1
							end
							for k,v in pairs(config.cobalt.groups) do
								if config.cobalt.groups[k].whitelisted then
									if config.cobalt.groups[k].groupPlayers then
										for c,d in pairs(config.cobalt.groups[k].groupPlayers) do
											whitelistPlayersCounter = whitelistPlayersCounter + 1
										end
									end
								end
							end
						end
						if im.TreeNode1("whitelisted players:") then
							im.SameLine()
							im.Text(tostring(whitelistPlayersCounter))
							if config.cobalt.whitelistedPlayers then
								for x,y in pairs(config.cobalt.whitelistedPlayers) do
									im.Text("		")
									im.SameLine()
									im.Text(config.cobalt.whitelistedPlayers[x])
									im.SameLine()
									if im.SmallButton("Remove##"..tostring(x)) then
										local data = jsonEncode( { "remove", config.cobalt.whitelistedPlayers[x] } )
										TriggerServerEvent("CEIWhitelist", data)
										log('W', logTag, "CEIWhitelist Called: " .. data)
									end
								end
							end
							im.Text("		Add Name to Whitelist: ")
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##whitelistName", "Player Name", configVals.cobalt.whitelistNameInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Add##whitelistName") then
									local data = jsonEncode( { "add", ffi.string(configVals.cobalt.whitelistNameInput) } )
									TriggerServerEvent("CEIWhitelist", data)
									log('W', logTag, "CEIWhitelist Called: " .. data)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter Player Name to Add to Whitelist and press Apply")
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(whitelistPlayersCounter))
						end
						im.Text("		")
						im.SameLine()
						if config.cobalt.enableWhitelist == false then
							if im.SmallButton("Enable Whitelist##"..tostring(k)) then
								local data = jsonEncode( { "enable" } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						elseif config.cobalt.enableWhitelist == true then
							if im.SmallButton("Disable Whitelist##"..tostring(k)) then
								local data = jsonEncode( { "disable" } )
								TriggerServerEvent("CEIWhitelist", data)
								log('W', logTag, "CEIWhitelist Called: " .. data)
							end
						end
						im.Separator()
					end
					if currentGroup == "owner" or currentGroup == "admin" then
						im.Text('		Default CEI State:')
						im.SameLine()
						if config.cobalt.interface.defaultState == true then
							if im.SmallButton("Shown##") then
								local data = jsonEncode( { false } )
								TriggerServerEvent("CEISetDefaultState", data)
								log('W', logTag, "CEISetDefaultState Called: " .. data)
							end
						elseif config.cobalt.interface.defaultState == false then
							if im.SmallButton("Hidden##") then
								local data = jsonEncode( { true } )
								TriggerServerEvent("CEISetDefaultState", data)
								log('W', logTag, "CEISetDefaultState Called: " .. data)
							end
						end
					end
					im.Unindent()
				end
----------------------------------------------------------------------------------SERVER HEADER
				if currentGroup == "owner" or currentGroup == "admin" then
					if im.CollapsingHeader1("Server") then
						im.Indent()
						if im.TreeNode1("name:") then
							im.SameLine()
							im.Text(config.server.name)
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##name", "Server Name", configVals.server.nameInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##"..tostring(k)) then
								local data = jsonEncode( { "Name", ffi.string(configVals.server.nameInput) } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
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
							im.Text(tostring(config.server.maxCars))
							im.Text("		")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("", configVals.server.maxCarsInt, 1) then
								local data = jsonEncode( { "MaxCars", tostring(configVals.server.maxCarsInt[0]) } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
							im.PopItemWidth()
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(config.server.maxCars))
						end
						im.Separator()
						if im.TreeNode1("maxPlayers:") then
							im.SameLine()
							im.Text(tostring(config.server.maxPlayers))
							im.Text("		")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("", configVals.server.maxPlayersInt, 1) then
								local data = jsonEncode( { "MaxPlayers", tostring(configVals.server.maxPlayersInt[0]) } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
							im.PopItemWidth()
							im.TreePop()
						else
							im.SameLine()
							im.Text(tostring(config.server.maxPlayers))
						end
						im.Separator()
						if im.TreeNode1("map:") then
							im.SameLine()
							im.Text(config.server.map)
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##map", "Map Path", configVals.server.mapInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##"..tostring(k)) then
								local data = jsonEncode( { "Map", ffi.string(configVals.server.mapInput) } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
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
							if im.InputTextWithHint("##description", "Server Description", configVals.server.descriptionInput, 256) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##"..tostring(k)) then
								local data = jsonEncode( { "Description", ffi.string(configVals.server.descriptionInput) } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
							im.SameLine()
							im.ShowHelpMarker("Enter new Server Description and press Apply")
							im.TreePop()
						else
							im.SameLine()
							im.Text(config.server.description)
						end
						im.Separator()
						im.Text("		debug: " .. tostring(config.server.debug))
						im.SameLine()
						if config.server.debug == false then
							if im.SmallButton("Enable Debug##"..tostring(k)) then
								local data = jsonEncode( { "Debug", true } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
						elseif config.server.debug == true then
							if im.SmallButton("Disable Debug##"..tostring(k)) then
								local data = jsonEncode( { "Debug", false } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
						end
						im.Separator()
						im.Text("		private: " .. tostring(config.server.private))
						im.SameLine()
						if config.server.private == false then
							if im.SmallButton("Set Private##"..tostring(k)) then
								local data = jsonEncode( { "Private", true } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
						elseif config.server.private == true then
							if im.SmallButton("Set Public##"..tostring(k)) then
								local data = jsonEncode( { "Private", false } )
								TriggerServerEvent("CEISetCfg", data)
								log('W', logTag, "CEISetCfg Called: " .. data)
							end
						end
						im.Text("		")
						im.Text("		")
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
						if im.SmallButton("Stop/Restart##"..tostring(k)) then
							local data = jsonEncode( { "Good-bye!" } )
							TriggerServerEvent("CEIStop", data)
							log('W', logTag, "CEIStop Called: " .. data)
						end
						im.PopStyleColor(3)
						im.SameLine()
						im.ShowHelpMarker("Good-bye!")
						im.Unindent()
					end
				end
----------------------------------------------------------------------------------NAMETAGS HEADER
				if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
					if im.CollapsingHeader1("Nametags") then
						local nametagWhitelist = config.nametags.whitelist
						local nametagWhitelistCounter = 0
						for a,b in pairs(nametagWhitelist) do
							nametagWhitelistCounter = nametagWhitelistCounter + 1
						end
						im.Indent()
						if im.TreeNode1("Nametag Settings") then
							im.Text("		")
							im.SameLine()
							im.Text("Nametag Blocking: ")
							if config.nametags.settings.blockingEnabled then
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
								if im.SmallButton("Enabled##NametagBlocking") then
									local data = jsonEncode( { false } )
									TriggerServerEvent("CEINametagSetting", data)
									log('W', logTag, "CEINametagSetting Called: " .. data)
									data = jsonEncode( { 0 } )
									TriggerServerEvent("txNametagBlockerTimeout", data)
									log('W', logTag, "txNametagBlockerTimeout Called: " .. data)
								end
								im.PopStyleColor(3)
							else
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
								if im.SmallButton("Disabled##NametagBlocking") then
								local data = jsonEncode( { true } )
									TriggerServerEvent("CEINametagSetting", data)
									log('W', logTag, "CEINametagSetting Called: " .. data)
								end
								im.PopStyleColor(3)
							end
							im.Text("		")
							im.SameLine()
							im.Text("Blocking Timeout: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("##nametagBlockingTimeout", configVals.nametags.settings.blockingTimeoutInt, 1) then
								if configVals.nametags.settings.blockingTimeoutInt[0] < 0 then
									configVals.nametags.settings.blockingTimeoutInt = im.IntPtr(0)
								elseif configVals.nametags.settings.blockingTimeoutInt[0] > 3600 then
									configVals.nametags.settings.blockingTimeoutInt = im.IntPtr(3600)
								end
								local data = jsonEncode( { tostring(configVals.nametags.settings.blockingTimeoutInt[0]) } )
								TriggerServerEvent("CEINametagSetting", data)
								log('W', logTag, "CEINametagSetting Called: " .. data)
							end
							im.PopItemWidth()
							if config.nametags.settings.blockingEnabled == true then
							elseif config.nametags.settings.blockingEnabled == false then
								im.SameLine()
								if im.SmallButton("Start##NametagBlocking") then
									local data = jsonEncode( { true } )
									TriggerServerEvent("CEINametagSetting", data)
									log('W', logTag, "CEINametagSetting Called: " .. data)
									data = jsonEncode( { configVals.nametags.settings.blockingTimeoutInt[0] } )
									TriggerServerEvent("txNametagBlockerTimeout", data)
									log('W', logTag, "txNametagBlockerTimeout Called: " .. data)
								end
							end
							im.TreePop()
						else
						end
						im.Separator()
						if im.TreeNode1("Nametag Whitelist: ") then
							im.SameLine()
							im.Text(tostring(nametagWhitelistCounter))
							for k,v in pairs(config.nametags.whitelist) do
								im.Text("		")
								im.SameLine()
								im.Text(config.nametags.whitelist[k])
								im.SameLine()
								if im.SmallButton("Remove##"..config.nametags.whitelist[k]) then
									local data = jsonEncode( { config.nametags.whitelist[k] } )
									TriggerServerEvent("CEIRemoveNametagWhitelist", data)
									log('W', logTag, "CEIRemoveNametagWhitelist Called: " .. data)
								end
							end
							im.Text("		")
							im.SameLine()
							if im.InputTextWithHint("##whitelistName", "Whitelist Name", configVals.nametags.whitelistNameInput, 128) then
							end
							im.Text("		")
							im.SameLine()
							if im.SmallButton("Apply##nametagWhitelist") then
								local data = jsonEncode( { ffi.string(configVals.nametags.whitelistNameInput) } )
								TriggerServerEvent("CEISetNametagWhitelist", data)
								log('W', logTag, "CEISetNametagWhitelist Called: " .. data)
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
				end
----------------------------------------------------------------------------------GLOBAL RESTRICTIONS HEADER
					if im.CollapsingHeader1("Global Restrictions") then
						im.Indent()
						if im.TreeNode1("Resets") then
							im.SameLine()
							if im.SmallButton("Reset##RST") then
								local data = jsonEncode( { "all", "default" } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.Indent()
							im.Text("Reset Control: ")
							if config.resets.control then
								im.SameLine()
								if im.SmallButton("Enabled##control") then
									local data = jsonEncode( { "control", false } )
									TriggerServerEvent("CEISetRestrictions", data)
									log('W', logTag, "CEISetRestrictions Called: " .. data)
								end
							else
								im.SameLine()
								if im.SmallButton("Disabled##control") then
									local data = jsonEncode( { "control", true } )
									TriggerServerEvent("CEISetRestrictions", data)
									log('W', logTag, "CEISetRestrictions Called: " .. data)
								end
							end
							im.Text("Notification Message Duration: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("##messageDuration", configVals.resets.messageDuration, 1, 1) then
								if configVals.resets.messageDuration[0] < 0 then
									configVals.resets.messageDuration = im.IntPtr(0)
								elseif configVals.resets.messageDuration[0] > 60 then
									configVals.resets.messageDuration = im.IntPtr(60)
								end
								local data = jsonEncode( { "messageDuration", tostring(configVals.resets.messageDuration[0]) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.PopItemWidth()
							im.Text("Reset Timeout: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("##timeout", configVals.resets.timeout, 1, 1) then
								if configVals.resets.timeout[0] < 0 then
									configVals.resets.timeout = im.IntPtr(0)
								elseif configVals.resets.timeout[0] > 600 then
									configVals.resets.timeout = im.IntPtr(600)
								end
								local data = jsonEncode( { "timeout", tostring(configVals.resets.timeout[0]) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.PopItemWidth()
							im.Text("Vehicle Resets: ")
							if config.resets.enabled then
								im.SameLine()
								if im.SmallButton("Enabled##RST") then
									local data = jsonEncode( { "enabled", false } )
									TriggerServerEvent("CEISetRestrictions", data)
									log('W', logTag, "CEISetRestrictions Called: " .. data)
								end
							else
								im.SameLine()
								if im.SmallButton("Disabled##RST") then
									local data = jsonEncode( { "enabled", true } )
									TriggerServerEvent("CEISetRestrictions", data)
									log('W', logTag, "CEISetRestrictions Called: " .. data)
								end
							end
							im.Text("Notification Title: " .. config.resets.title)
							if im.InputTextWithHint("##title", "Toast notification title", configVals.resets.title, 128) then
							end
							if im.SmallButton("Apply##title") then
								local data = jsonEncode( { "title", ffi.string(configVals.resets.title) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.Text("Timeout Elapsed Message: " .. config.resets.elapsedMessage)
							if im.InputTextWithHint("##elapsedMessage", "Elapsed Message", configVals.resets.elapsedMessage, 256) then
							end
							if im.SmallButton("Apply##elapsedMessage") then
								local data = jsonEncode( { "elapsedMessage", ffi.string(configVals.resets.elapsedMessage) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.Text("Timeout Started Message: " .. config.resets.message)
							if im.InputTextWithHint("##message", "Message", configVals.resets.message, 256) then
							end
							if im.SmallButton("Apply##message") then
								local data = jsonEncode( { "message", ffi.string(configVals.resets.message) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
							im.Text("Resets Disabled Message: " .. config.resets.disabledMessage)
							if im.InputTextWithHint("##disabledMessage", "Disabled Message", configVals.resets.disabledMessage, 256) then
							end
							if im.SmallButton("Apply##disabledMessage") then
								local data = jsonEncode( { "disabledMessage", ffi.string(configVals.resets.disabledMessage) } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end

							im.TreePop()
							im.Unindent()
						else
							im.SameLine()
							if im.SmallButton("Reset##RST") then
								local data = jsonEncode( { "all", "default" } )
								TriggerServerEvent("CEISetRestrictions", data)
								log('W', logTag, "CEISetRestrictions Called: " .. data)
							end
						end
						im.Unindent()
					end
----------------------------------------------------------------------------------EXTRAS HEADER
				if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
					if im.CollapsingHeader1("Extras") then
						im.Indent()
						if im.TreeNode1("Simulation Speed") then
							im.SameLine()
							if im.SmallButton("Reset##SIM") then
								local data = jsonEncode( { "simSpeed", "default" } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
								data = jsonEncode( { "controlSimSpeed", false } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.Indent()
							im.Text("Sim Speed Control: ")
							if environment.controlSimSpeed then
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
								if im.SmallButton("Enabled") then
									local data = jsonEncode( { "controlSimSpeed", false } )
									TriggerServerEvent("CEISetEnv", data)
									log('W', logTag, "CEISetEnv Called: " .. data)
								end
								im.PopStyleColor(3)
							else
								im.SameLine()
								im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
								im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
								im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
								if im.SmallButton("Disabled") then
									local data = jsonEncode( { "controlSimSpeed", true } )
									TriggerServerEvent("CEISetEnv", data)
									log('W', logTag, "CEISetEnv Called: " .. data)
								end
								im.PopStyleColor(3)
							end
							im.Text("Simulation: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputFloat("##simSpeed", environmentVals.simSpeedVal, 0.001, 0.1) then
								if environmentVals.simSpeedVal[0] < 0.01 then
									environmentVals.simSpeedVal = im.FloatPtr(0.01)
								elseif environmentVals.simSpeedVal[0] > 5 then
									environmentVals.simSpeedVal = im.FloatPtr(5)
								end
								local data = jsonEncode( { "simSpeed", tostring(environmentVals.simSpeedVal[0]) } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.PopItemWidth()
							if im.SmallButton("0.5X") then
								local data = jsonEncode( { "simSpeed", 2 } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.SameLine()
							if im.SmallButton("Real") then
								local data = jsonEncode( { "simSpeed", "default" } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.SameLine()
							if im.SmallButton("2X") then
								local data = jsonEncode( { "simSpeed", 0.5 } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.SameLine()
							if im.SmallButton("4X") then
								local data = jsonEncode( { "simSpeed", 0.25 } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.SameLine()
							if im.SmallButton("10X") then
								local data = jsonEncode( { "simSpeed", 0.1 } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.SameLine()
							if im.SmallButton("100X") then
								local data = jsonEncode( { "simSpeed", 0.01 } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.TreePop()
							im.Unindent()
						else
							im.SameLine()
							if im.SmallButton("Reset##SIM") then
								local data = jsonEncode( { "simSpeed", "default" } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
								data = jsonEncode( { "controlSimSpeed", false } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
						end
						im.Separator()
						if im.TreeNode1("Teleportation") then
							im.SameLine()
							if im.SmallButton("Reset##TLPT") then
								local data = jsonEncode( { "teleportTimeout", "default" } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.Indent()
							im.Text("Teleport Timeout: ")
							im.SameLine()
							im.PushItemWidth(100)
							if im.InputInt("##teleportTimeout", environmentVals.teleportTimeoutInt, 1, 10) then
								if environmentVals.teleportTimeoutInt[0] < 0 then
									environmentVals.teleportTimeoutInt = im.IntPtr(0)
								elseif environmentVals.teleportTimeoutInt[0] > 60 then
									environmentVals.teleportTimeoutInt = im.IntPtr(60)
								end
								local data = jsonEncode( { "teleportTimeout", tostring(environmentVals.teleportTimeoutInt[0]) } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
							im.PopItemWidth()
							im.TreePop()
						else
							im.SameLine()
							if im.SmallButton("Reset##TLPT") then
								local data = jsonEncode( { "teleportTimeout", "default" } )
								TriggerServerEvent("CEISetEnv", data)
								log('W', logTag, "CEISetEnv Called: " .. data)
							end
						end
						im.Unindent()
					end
					im.EndTabItem()
				end
			end
		end
----------------------------------------------------------------------------------ENVIRONMENT TAB
		if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
			if im.BeginTabItem("Environment") then
				im.Indent()
				if im.SmallButton("Reset All##ENV") then
					local data = jsonEncode( { "all", "default" } )
					TriggerServerEvent("CEISetEnv", data)
					log('W', logTag, "CEISetEnv Called: " .. data)
				end
				if im.TreeNode1("Sun") then
					im.SameLine()
					if im.SmallButton("Reset##SUN") then
						local data = jsonEncode( { "allSun", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Indent()
					im.Text("Sun Control: ")
					if environment.controlSun then
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
						if im.SmallButton("Enabled") then
							local data = jsonEncode( { "controlSun", false } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					else
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
						if im.SmallButton("Disabled") then
							local data = jsonEncode( { "controlSun", true } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					end
					im.Text("Time Play: ")
					im.SameLine()
					local timePlay = environment.timePlay
					if timePlay == false then
						if im.SmallButton("Play") then
							local data = jsonEncode( { "timePlay", true } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
					elseif timePlay == true then
						if im.SmallButton("Stop") then
							local timeOfDay = core_environment.getTimeOfDay()
							local data = jsonEncode( { "timePlay", false } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
							data = jsonEncode( { "ToD", tostring(timeOfDay.time) } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
					end
					im.Text("Time of Day: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##ToD", environmentVals.ToDVal, 0.001, 0.01) then
						if environmentVals.ToDVal[0] < 0 then
							environmentVals.ToDVal = im.FloatPtr(1)
						elseif environmentVals.ToDVal[0] > 1 then
							environmentVals.ToDVal = im.FloatPtr(0)
						end
						local data = jsonEncode( { "ToD", tostring(environmentVals.ToDVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						timeUpdateQueued = true
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##ToD") then
						local data = jsonEncode( { "ToD", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						timeUpdateQueued = true
					end
					im.Text("Day Length: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputInt("##dayLength", environmentVals.dayLengthInt, 1, 10) then
						if environmentVals.dayLengthInt[0] < 1 then
							environmentVals.dayLengthInt = im.IntPtr(1)
						elseif environmentVals.dayLengthInt[0] > 14400 then
							environmentVals.dayLengthInt = im.IntPtr(14400)
						end
						local data = jsonEncode( { "dayLength", tostring(environmentVals.dayLengthInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##DL") then
						local data = jsonEncode( { "dayLength", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.SameLine()
					if im.SmallButton("Realtime##DS") then
						local data = jsonEncode( { "dayLength", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "dayScale", 0.0208333333 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "nightScale", 0.0208333333 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Day Scale: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##dayScale", environmentVals.dayScaleVal, 0.01, 0.1) then
						if environmentVals.dayScaleVal[0] < 0.01 then
							environmentVals.dayScaleVal = im.FloatPtr(0.01)
						elseif environmentVals.dayScaleVal[0] > 100 then
							environmentVals.dayScaleVal = im.FloatPtr(100)
						end
						local data = jsonEncode( { "dayScale", tostring(environmentVals.dayScaleVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##DS") then
						local data = jsonEncode( { "dayScale", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Night Scale: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##nightScale", environmentVals.nightScaleVal, 0.01, 0.1) then
						if environmentVals.nightScaleVal[0] < 0.01 then
							environmentVals.nightScaleVal = im.FloatPtr(0.01)
						elseif environmentVals.nightScaleVal[0] > 100 then
							environmentVals.nightScaleVal = im.FloatPtr(100)
						end
						local data = jsonEncode( { "nightScale", tostring(environmentVals.nightScaleVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##NS") then
						local data = jsonEncode( { "nightScale", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Sun Azimuth: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##sunAzimuth", environmentVals.sunAzimuthVal,  0.1, 1) then
						if environmentVals.sunAzimuthVal[0] < 0 then
							environmentVals.sunAzimuthVal = im.FloatPtr(360)
						elseif environmentVals.sunAzimuthVal[0] > 360 then
							environmentVals.sunAzimuthVal = im.FloatPtr(0)
						end
						local data = jsonEncode( { "sunAzimuth", tostring(environmentVals.sunAzimuthVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SA") then
						local data = jsonEncode( { "sunAzimuth", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Sun Size: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##sunSize", environmentVals.sunSizeVal, 0.01, 0.1) then
						if environmentVals.sunSizeVal[0] < 0 then
							environmentVals.sunSizeVal = im.FloatPtr(0)
						elseif environmentVals.sunSizeVal[0] > 100 then
							environmentVals.sunSizeVal = im.FloatPtr(100)
						end
						local data = jsonEncode( { "sunSize", tostring(environmentVals.sunSizeVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SS") then
						local data = jsonEncode( { "sunSize", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Sky Brightness: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##skyBrightness", environmentVals.skyBrightnessVal, 0.1, 1.0) then
						if environmentVals.skyBrightnessVal[0] < 0 then
							environmentVals.skyBrightnessVal = im.FloatPtr(0)
						elseif environmentVals.skyBrightnessVal[0] > 200 then
							environmentVals.skyBrightnessVal = im.FloatPtr(200)
						end
						local data = jsonEncode( { "skyBrightness", tostring(environmentVals.skyBrightnessVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SB") then
						local data = jsonEncode( { "skyBrightness", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Sunlight Brightness: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##sunLightBrightness", environmentVals.sunLightBrightnessVal, 0.01, 0.1) then
						if environmentVals.sunLightBrightnessVal[0] < 0 then
							environmentVals.sunLightBrightnessVal = im.FloatPtr(0)
						elseif environmentVals.sunLightBrightnessVal[0] > 10 then
							environmentVals.sunLightBrightnessVal = im.FloatPtr(10)
						end
						local data = jsonEncode( { "sunLightBrightness", tostring(environmentVals.sunLightBrightnessVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##GB") then
						local data = jsonEncode( { "sunLightBrightness", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Rayleigh Scattering: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##rayleighScattering", environmentVals.rayleighScatteringVal, 0.0001, 0.001) then
						if environmentVals.rayleighScatteringVal[0] < 0.0001 then
							environmentVals.rayleighScatteringVal = im.FloatPtr(0.0001)
						elseif environmentVals.rayleighScatteringVal[0] > 0.15 then
							environmentVals.rayleighScatteringVal = im.FloatPtr(0.15)
						end
						local data = jsonEncode( { "rayleighScattering", tostring(environmentVals.rayleighScatteringVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##RS") then
						local data = jsonEncode( { "rayleighScattering", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Flare Scale: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##flareScale", environmentVals.flareScaleVal, 0.01, 0.1) then
						if environmentVals.flareScaleVal[0] < 0 then
							environmentVals.flareScaleVal = im.FloatPtr(0)
						elseif environmentVals.flareScaleVal[0] > 25 then
							environmentVals.flareScaleVal = im.FloatPtr(25)
						end
						local data = jsonEncode( { "flareScale", tostring(environmentVals.flareScaleVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##FS") then
						local data = jsonEncode( { "flareScale", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Occlusion Scale: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##occlusionScale", environmentVals.occlusionScaleVal, 0.001, 0.01) then
						if environmentVals.occlusionScaleVal[0] < 0 then
							environmentVals.occlusionScaleVal = im.FloatPtr(0)
						elseif environmentVals.occlusionScaleVal[0] > 1 then
							environmentVals.occlusionScaleVal = im.FloatPtr(1)
						end
						local data = jsonEncode( { "occlusionScale", tostring(environmentVals.occlusionScaleVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##OS") then
						local data = jsonEncode( { "occlusionScale", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Exposure: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##exposure", environmentVals.exposureVal, 0.01, 0.1) then
						if environmentVals.exposureVal[0] < 0 then
							environmentVals.exposureVal = im.FloatPtr(0)
						elseif environmentVals.exposureVal[0] > 3 then
							environmentVals.exposureVal = im.FloatPtr(3)
						end
						local data = jsonEncode( { "exposure", tostring(environmentVals.exposureVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##EX") then
						local data = jsonEncode( { "exposure", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Shadow Distance: ")
					im.SameLine()
					im.PushItemWidth(120)
					if im.InputInt("##shadowDistance", environmentVals.shadowDistanceInt, 1) then
						if environmentVals.shadowDistanceInt[0] < 0 then
							environmentVals.shadowDistanceInt = im.FloatPtr(0)
						elseif environmentVals.shadowDistanceInt[0] > 12800 then
							environmentVals.shadowDistanceInt = im.FloatPtr(12800)
						end
						local data = jsonEncode( { "shadowDistance", tostring(environmentVals.shadowDistanceInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SD") then
						local data = jsonEncode( { "shadowDistance", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Shadow Softness: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##shadowSoftness", environmentVals.shadowSoftnessVal, 0.001, 0.01) then
						if environmentVals.shadowSoftnessVal[0] < -10 then
							environmentVals.shadowSoftnessVal = im.FloatPtr(-10)
						elseif environmentVals.shadowSoftnessVal[0] > 10 then
							environmentVals.shadowSoftnessVal = im.FloatPtr(10)
						end
						local data = jsonEncode( { "shadowSoftness", tostring(environmentVals.shadowSoftnessVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SSFT") then
						local data = jsonEncode( { "shadowSoftness", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Shadow Splits: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##shadowSplits", environmentVals.shadowSplitsInt, 1) then
						if environmentVals.shadowSplitsInt[0] < 0 then
							environmentVals.shadowSplitsInt = im.IntPtr(0)
						elseif environmentVals.shadowSplitsInt[0] > 4 then
							environmentVals.shadowSplitsInt = im.IntPtr(4)
						end
						local data = jsonEncode( { "shadowSplits", tostring(environmentVals.shadowSplitsInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SSPL") then
						local data = jsonEncode( { "shadowSplits", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Shadow Tex Size: ")
					im.SameLine()
					im.PushItemWidth(120)
					if im.InputInt("##shadowTexSize", environmentVals.shadowTexSizeInt, 1) then
						if environmentVals.shadowTexSizeInt[0] < 32 then
							environmentVals.shadowTexSizeInt = im.IntPtr(32)
						elseif environmentVals.shadowTexSizeInt[0] > 2048 then
							environmentVals.shadowTexSizeInt = im.IntPtr(2048)
						elseif environmentVals.shadowTexSizeInt[0] < environment.shadowTexSize then
							environmentVals.shadowTexSizeInt = im.IntPtr(environment.shadowTexSize / 2)
						elseif environmentVals.shadowTexSizeInt[0] > environment.shadowTexSize then
							environmentVals.shadowTexSizeInt = im.IntPtr(environment.shadowTexSize * 2)
						end
						local data = jsonEncode( { "shadowTexSize", tostring(environmentVals.shadowTexSizeInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##STS") then
						local data = jsonEncode( { "shadowTexSize", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Shadow Log Weight: ")
					im.SameLine()
					im.PushItemWidth(110)
					if im.InputFloat("##shadowLogWeight", environmentVals.shadowLogWeightVal, 0.001, 0.01) then
						if environmentVals.shadowLogWeightVal[0] < 0.001 then
							environmentVals.shadowLogWeightVal = im.FloatPtr(0.001)
						elseif environmentVals.shadowLogWeightVal[0] > 0.999 then
							environmentVals.shadowLogWeightVal = im.FloatPtr(0.999)
						end
						local data = jsonEncode( { "shadowLogWeight", tostring(environmentVals.shadowLogWeightVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##SLW") then
						local data = jsonEncode( { "shadowLogWeight", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Visibile Distance: ")
					im.SameLine()
					im.PushItemWidth(120)
					if im.InputInt("##visibleDistance", environmentVals.visibleDistanceInt, 1) then
						if environmentVals.visibleDistanceInt[0] < 1000 then
							environmentVals.visibleDistanceInt = im.IntPtr(1000)
						elseif environmentVals.visibleDistanceInt[0] > 32000 then
							environmentVals.visibleDistanceInt = im.IntPtr(32000)
						end
						local data = jsonEncode( { "visibleDistance", tostring(environmentVals.visibleDistanceInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##VD") then
						local data = jsonEncode( { "visibleDistance", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Moon Azimuth: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##moonAzimuth", environmentVals.moonAzimuthVal, 0.1, 1) then
						if environmentVals.moonAzimuthVal[0] < 0 then
							environmentVals.moonAzimuthVal = im.FloatPtr(360)
						elseif environmentVals.moonAzimuthVal[0] > 360 then
							environmentVals.moonAzimuthVal = im.FloatPtr(0)
						end
						local data = jsonEncode( { "moonAzimuth", tostring(environmentVals.moonAzimuthVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##MA") then
						local data = jsonEncode( { "moonAzimuth", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Moon Elevation: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##moonElevation", environmentVals.moonElevationVal, 0.1, 1) then
						if environmentVals.moonElevationVal[0] < 0 then
							environmentVals.moonElevationVal = im.FloatPtr(360)
						elseif environmentVals.moonElevationVal[0] > 360 then
							environmentVals.moonElevationVal = im.FloatPtr(0)
						end
						local data = jsonEncode( { "moonElevation", tostring(environmentVals.moonElevationVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##ME") then
						local data = jsonEncode( { "moonElevation", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Moon Scale: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##moonScale", environmentVals.moonScaleVal, 0.001, 0.01) then
						if environmentVals.moonScaleVal[0] < 0.005 then
							environmentVals.moonScaleVal = im.FloatPtr(0.005)
						elseif environmentVals.moonScaleVal[0] > 1 then
							environmentVals.moonScaleVal = im.FloatPtr(1)
						end
						local data = jsonEncode( { "moonScale", tostring(environmentVals.moonScaleVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##MS") then
						local data = jsonEncode( { "moonScale", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.TreePop()
					im.Unindent()
				else
					im.SameLine()
					if im.SmallButton("Reset##SUN") then
						local data = jsonEncode( { "allSun", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
				end
				im.Separator()
				if im.TreeNode1("Weather") then
					im.SameLine()
					if im.SmallButton("Reset##WET") then
						local data = jsonEncode( { "allWeather", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Indent()
					im.Text("Weather Control: ")
					im.SameLine()
					if environment.controlWeather then
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
						if im.SmallButton("Enabled") then
							local data = jsonEncode( { "controlWeather", false } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					else
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
						if im.SmallButton("Disabled") then
							local data = jsonEncode( { "controlWeather", true } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					end
					im.Text("Fog Density: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##fogDensity", environmentVals.fogDensityVal, 0.00001, 0.0001) then
						if environmentVals.fogDensityVal[0] < 0.00001 then
							environmentVals.fogDensityVal = im.FloatPtr(0.00001)
						elseif environmentVals.fogDensityVal[0] > 0.2 then
							environmentVals.fogDensityVal = im.FloatPtr(0.2)
						end
						local data = jsonEncode( { "fogDensity", tostring(environmentVals.fogDensityVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##FD") then
						local data = jsonEncode( { "fogDensity", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Fog Distance: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##fogDensityOffset", environmentVals.fogDensityOffsetVal, 0.001, 0.1) then
						if environmentVals.fogDensityOffsetVal[0] < 0 then
							environmentVals.fogDensityOffsetVal = im.FloatPtr(0)
						elseif environmentVals.fogDensityOffsetVal[0] > 100 then
							environmentVals.fogDensityOffsetVal = im.FloatPtr(100)
						end
						local data = jsonEncode( { "fogDensityOffset", tostring(environmentVals.fogDensityOffsetVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##FDO") then
						local data = jsonEncode( { "fogDensityOffset", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Cloud Cover: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##cloudCover", environmentVals.cloudCoverVal, 0.01, 0.1) then
						if environmentVals.cloudCoverVal[0] < 0 then
							environmentVals.cloudCoverVal = im.FloatPtr(0)
						elseif environmentVals.cloudCoverVal[0] > 5 then
							environmentVals.cloudCoverVal = im.FloatPtr(5)
						end
						local data = jsonEncode( { "cloudCover", tostring(environmentVals.cloudCoverVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##CC") then
						local data = jsonEncode( { "cloudCover", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Cloud Speed: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##cloudSpeed", environmentVals.cloudSpeedVal, 0.01, 0.1) then
						if environmentVals.cloudSpeedVal[0] < 0 then
							environmentVals.cloudSpeedVal = im.FloatPtr(0)
						elseif environmentVals.cloudSpeedVal[0] > 10 then
							environmentVals.cloudSpeedVal = im.FloatPtr(10)
						end
						local data = jsonEncode( { "cloudSpeed", tostring(environmentVals.cloudSpeedVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##CS") then
						local data = jsonEncode( { "cloudSpeed", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Rain Drops: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##rainDrops", environmentVals.rainDropsInt, 1, 10) then
						if environmentVals.rainDropsInt[0] < 0 then
							environmentVals.rainDropsInt = im.IntPtr(0)
						elseif environmentVals.rainDropsInt[0] > 20000 then
							environmentVals.rainDropsInt = im.IntPtr(20000)
						end
						local data = jsonEncode( { "rainDrops", tostring(environmentVals.rainDropsInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##RD") then
						local data = jsonEncode( { "rainDrops", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Drop Size: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##dropSize", environmentVals.dropSizeVal, 0.001, 0.01) then
						if environmentVals.dropSizeVal[0] < 0 then
							environmentVals.dropSizeVal = im.FloatPtr(0)
						elseif environmentVals.dropSizeVal[0] > 2 then
							environmentVals.dropSizeVal = im.FloatPtr(2)
						end
						local data = jsonEncode( { "dropSize", tostring(environmentVals.dropSizeVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##DSZ") then
						local data = jsonEncode( { "dropSize", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Drop Min Speed: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##dropMinSpeed", environmentVals.dropMinSpeedVal, 0.001, 0.01) then
						if environmentVals.dropMinSpeedVal[0] < 0 then
							environmentVals.dropMinSpeedVal = im.FloatPtr(0)
						elseif environmentVals.dropMinSpeedVal[0] > 2 then
							environmentVals.dropMinSpeedVal = im.FloatPtr(2)
						end
						local data = jsonEncode( { "dropMinSpeed", tostring(environmentVals.dropMinSpeedVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##DMNS") then
						local data = jsonEncode( { "dropMinSpeed", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Drop Max Speed: ")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputFloat("##dropMaxSpeed", environmentVals.dropMaxSpeedVal, 0.001, 0.01) then
						if environmentVals.dropMaxSpeedVal[0] < 0 then
							environmentVals.dropMaxSpeedVal = im.FloatPtr(0)
						elseif environmentVals.dropMaxSpeedVal[0] > 2 then
							environmentVals.dropMaxSpeedVal = im.FloatPtr(2)
						end
						local data = jsonEncode( { "dropMaxSpeed", tostring(environmentVals.dropMaxSpeedVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.SameLine()
					if im.SmallButton("Reset##DMXS") then
						local data = jsonEncode( { "dropMaxSpeed", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("Precipitation Type: ")
					im.SameLine()
					local precipType = environment.precipType
					if precipType == "rain_medium" then
						if im.SmallButton("Medium Rain") then
							local data = jsonEncode( { "precipType", "rain_drop" } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
					elseif precipType == "rain_drop" then
						if im.SmallButton("Light Rain") then
							local data = jsonEncode( { "precipType", "Snow_menu" } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
					elseif precipType == "Snow_menu" then
						if im.SmallButton("Snow") then
							local data = jsonEncode( { "precipType", "rain_medium" } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
					end
					im.TreePop()
					im.Unindent()
				else
					im.SameLine()
					if im.SmallButton("Reset##WET") then
						local data = jsonEncode( { "allWeather", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
				end
				im.Separator()
				if im.TreeNode1("Gravity") then
					im.SameLine()
					if im.SmallButton("Reset##GRV") then
						local data = jsonEncode( { "gravity", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "gravityControl", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Indent()
					im.Text("Gravity Control: ")
					if environment.controlGravity then
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
						if im.SmallButton("Enabled") then
							local data = jsonEncode( { "controlGravity", false } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					else
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
						if im.SmallButton("Disabled") then
							local data = jsonEncode( { "controlGravity", true } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					end
					im.Text("		")
					im.SameLine()
					im.PushItemWidth(130)
					if im.InputFloat("##gravity", environmentVals.gravityVal, 0.001, 0.1) then
						if environmentVals.gravityVal[0] < -280 then
							environmentVals.gravityVal = im.FloatPtr(-280)
						elseif environmentVals.gravityVal[0] > 10 then
							environmentVals.gravityVal = im.FloatPtr(10)
						end
						local data = jsonEncode( { "gravity", tostring(environmentVals.gravityVal[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.05, 0.05, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.05, 0.05, 0.05, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.05, 0.999))
					if im.SmallButton("Zero") then
						local data = jsonEncode( { "gravity", 0 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
					if im.SmallButton("Earth") then
						local data = jsonEncode( { "gravity", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.05, 0.05, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.05, 0.05, 0.05, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.05, 0.999))
					if im.SmallButton("Moon") then
						local data = jsonEncode( { "gravity", -1.62 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
					if im.SmallButton("Mars") then
						local data = jsonEncode( { "gravity", -3.71 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.68, 0.69, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.75, 0.78, 0.05, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.85, 0.84, 0.05, 0.999))
					if im.SmallButton("Sun") then
						local data = jsonEncode( { "gravity", -274 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.50, 0.21, 0.15, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.55, 0.22, 0.15, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.60, 0.23, 0.15, 0.999))
					if im.SmallButton("Jupiter") then
						local data = jsonEncode( { "gravity", -24.92 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					if im.SmallButton("Neptune") then
						local data = jsonEncode( { "gravity", -11.15 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.50, 0.21, 0.15, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.55, 0.22, 0.15, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.60, 0.23, 0.15, 0.999))
					if im.SmallButton("Saturn") then
						local data = jsonEncode( { "gravity", -10.44 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					if im.SmallButton("Uranus") then
						local data = jsonEncode( { "gravity", -8.87 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.55, 0.50, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.66, 0.64, 0.05, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.77, 0.74, 0.05, 0.999))
					if im.SmallButton("Venus") then
						local data = jsonEncode( { "gravity", -8.87 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.SameLine()
					im.PushStyleColor2(im.Col_Button, im.ImVec4(0.05, 0.05, 0.05, 0.333))
					im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.05, 0.05, 0.05, 0.5))
					im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.05, 0.999))
					if im.SmallButton("Mercury") then
						local data = jsonEncode( { "gravity", -3.7 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.SameLine()
					if im.SmallButton("Pluto") then
						local data = jsonEncode( { "gravity", -0.58 } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopStyleColor(3)
					im.TreePop()
					im.Unindent()
				else
					im.SameLine()
					if im.SmallButton("Reset##GRV") then
						local data = jsonEncode( { "gravity", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "gravityControl", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
				end
				im.Separator()
				if im.TreeNode1("Temperature") then
					im.SameLine()
					if im.SmallButton("Reset##TMP") then
						local data = jsonEncode( { "useTempCurve", false } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveNoon", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDusk", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveMidnight", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDawn", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Indent()
					im.Text("Temperature Curve Control: ")
					if environment.useTempCurve then
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.69, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.69, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.69, 0.05, 0.999))
						if im.SmallButton("Enabled") then
							local data = jsonEncode( { "useTempCurve", false } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					else
						im.SameLine()
						im.PushStyleColor2(im.Col_Button, im.ImVec4(0.69, 0.15, 0.05, 0.333))
						im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.69, 0.1, 0.09, 0.5))
						im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.69, 0.05, 0.05, 0.999))
						if im.SmallButton("Disabled") then
							local data = jsonEncode( { "useTempCurve", true } )
							TriggerServerEvent("CEISetEnv", data)
							log('W', logTag, "CEISetEnv Called: " .. data)
						end
						im.PopStyleColor(3)
					end
					im.Text("Custom Temperature Curve:")
					im.SameLine()
					if im.SmallButton("Reset##TCV") then
						local data = jsonEncode( { "tempCurveNoon", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDusk", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveMidnight", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDawn", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.Text("		")
					im.SameLine()
					im.Text("Noon")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveNoon", environmentVals.tempCurveNoonInt, 1, 2) then
						if environmentVals.tempCurveNoonInt[0] < -50 then
							environmentVals.tempCurveNoonInt = im.IntPtr(-50)
						elseif environmentVals.tempCurveNoonInt[0] > 50 then
							environmentVals.tempCurveNoonInt = im.IntPtr(50)
						end
						local data = jsonEncode( { "tempCurveNoon", tostring(environmentVals.tempCurveNoonInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dusk")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDusk", environmentVals.tempCurveDuskInt, 1, 2) then
						if environmentVals.tempCurveDuskInt[0] < -50 then
							environmentVals.tempCurveDuskInt = im.IntPtr(-50)
						elseif environmentVals.tempCurveDuskInt[0] > 50 then
							environmentVals.tempCurveDuskInt = im.IntPtr(50)
						end
						local data = jsonEncode( { "tempCurveDusk", tostring(environmentVals.tempCurveDuskInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Midnight")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveMidnight", environmentVals.tempCurveMidnightInt, 1, 2) then
						if environmentVals.tempCurveMidnightInt[0] < -50 then
							environmentVals.tempCurveMidnightInt = im.IntPtr(-50)
						elseif environmentVals.tempCurveMidnightInt[0] > 50 then
							environmentVals.tempCurveMidnightInt = im.IntPtr(50)
						end
						local data = jsonEncode( { "tempCurveMidnight", tostring(environmentVals.tempCurveMidnightInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.Text("		")
					im.SameLine()
					im.Text("Dawn")
					im.SameLine()
					im.PushItemWidth(100)
					if im.InputInt("##tempCurveDawn", environmentVals.tempCurveDawnInt, 1, 2) then
						if environmentVals.tempCurveDawnInt[0] < -50 then
							environmentVals.tempCurveDawnInt = im.IntPtr(-50)
						elseif environmentVals.tempCurveDawnInt[0] > 50 then
							environmentVals.tempCurveDawnInt = im.IntPtr(50)
						end
						local data = jsonEncode( { "tempCurveDawn", tostring(environmentVals.tempCurveDawnInt[0]) } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
					im.PopItemWidth()
					im.TreePop()
					im.Unindent()
				else
					im.SameLine()
					if im.SmallButton("Reset##TMP") then
						local data = jsonEncode( { "useTempCurve", false } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveNoon", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDusk", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveMidnight", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
						data = jsonEncode( { "tempCurveDawn", "default" } )
						TriggerServerEvent("CEISetEnv", data)
						log('W', logTag, "CEISetEnv Called: " .. data)
					end
				end
				im.EndTabItem()
			end
		end
----------------------------------------------------------------------------------DATABASE TAB
		if currentGroup == "owner" or currentGroup == "admin" or currentGroup == "mod" then
			if im.BeginTabItem("Database") then
				im.Indent()
		
				im.Text("Reason:")
				im.SameLine()
				if im.InputTextWithHint("##", "Kick or (temp)Ban or Mute Reason", playersDatabaseVals.kickBanMuteReason, 128) then
				end
				im.Text("tempBan:")
				im.SameLine()
				im.PushItemWidth(120)
				if im.InputFloat("##tempBanLength", playersDatabaseVals.tempBanLength, 0.001, 1) then
					if playersDatabaseVals.tempBanLength[0] < 0.001 then
						playersDatabaseVals.tempBanLength = im.FloatPtr(0.001)
					elseif playersDatabaseVals.tempBanLength[0] > 3650 then
						playersDatabaseVals.tempBanLength = im.FloatPtr(3650)
					end
				end
				im.SameLine()
				im.Text("days = " .. string.format("%.2f", (playersDatabaseVals.tempBanLength[0] * 1440)) .. " minutes")
				im.PopItemWidth()
				im.ImGuiTextFilter_Draw(playersDatabaseFiltering.filter[0])
				for k,v in pairs(playersDatabase) do
					for i = 0, im.GetLengthArrayCharPtr(playersDatabaseVals.lines) - 1 do
						if im.ImGuiTextFilter_PassFilter(playersDatabaseFiltering.filter[0], playersDatabaseVals.lines[i]) then
							if type(k) == "number" then
								local playerName = playersDatabase[k].playerName
								local playerBeammp = playersDatabase[k].beammp
								if playerName ~= playerBeammp then
									if playerName == ffi.string(playersDatabaseVals.lines[i]) then
										if im.TreeNode1("##"..playerName) then
											im.SameLine()
											if playerBeammp then
												if tonumber(playerBeammp) < 10 then
													im.Text(playerBeammp .. "			  | " .. playerName)
												elseif tonumber(playerBeammp) < 100 then
													im.Text(playerBeammp .. "			| " .. playerName)
												elseif tonumber(playerBeammp) < 1000 then
													im.Text(playerBeammp .. "		  | " .. playerName)
												elseif tonumber(playerBeammp) < 10000 then
													im.Text(playerBeammp .. "		| " .. playerName)
												elseif tonumber(playerBeammp) < 100000 then
													im.Text(playerBeammp .. "	  | " .. playerName)
												elseif tonumber(playerBeammp) < 1000000 then
													im.Text(playerBeammp .. "	| " .. playerName)
												else
													im.Text(playerBeammp .. "  | " .. playerName)
												end
											else
												im.Text(tostring(playerBeammp) .. "			| " .. playerName)
											end
											if playersDatabase[k].tempBanRemaining then
												im.SameLine()
												im.TextColored(im.ImVec4(1.0, 0.66, 0.0, 1.0), "> TempBanned")
											end
											if playersDatabase[k].banned then
												im.SameLine()
												im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "> BANNED")
											end
											if playersDatabase[k].banned then
												im.Text("				  ")
												im.SameLine()
												im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
												im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
												im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
												if im.SmallButton("Unban##" .. playerName) then
													local data = jsonEncode( { playerName } )
													TriggerServerEvent("CEIUnban", data)
													log('W', logTag, "CEIUnban Called: " .. data)
												end
												im.PopStyleColor(3)
											else
												im.Text("				  ")
												im.SameLine()
												im.PushStyleColor2(im.Col_Button, im.ImVec4(0.80, 0.25, 0.1, 0.333))
												im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.88, 0.25, 0.11, 0.5))
												im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.25, 0.2, 0.999))
												if im.SmallButton("Ban##" .. playerName) then
													local data = jsonEncode( { playerName, ffi.string(playersDatabaseVals.kickBanMuteReason) } )
													TriggerServerEvent("CEIBan", data)
													log('W', logTag, "CEIBan Called: " .. data)
													data = jsonEncode( { playerName, "null", ffi.string(playersDatabaseVals.kickBanMuteReason) } )
													TriggerServerEvent("CEITempBan", data)
													log('W', logTag, "CEITempBan Called: " .. data)
												end
												im.PopStyleColor(3)
												if playersDatabase[k].tempBanRemaining then
													im.SameLine()
													im.PushStyleColor2(im.Col_Button, im.ImVec4(0.15, 0.15, 0.75, 0.333))
													im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.1, 0.1, 0.69, 0.5))
													im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.05, 0.05, 0.55, 0.999))
													if im.SmallButton("UnTempBan##"..tostring(playerName)) then
														local data = jsonEncode( { playerName, 0, "" } )
														TriggerServerEvent("CEITempBan", data)
														log('W', logTag, "CEITempBan Called: " .. data)
													end
													im.PopStyleColor(3)
												else
													im.SameLine()
													im.PushStyleColor2(im.Col_Button, im.ImVec4(0.75, 0.5, 0.1, 0.333))
													im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.77, 0.55, 0.11, 0.5))
													im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.80, 0.6, 0.2, 0.999))
													if im.SmallButton("TempBan##"..tostring(playerName)) then
														local data = jsonEncode( { playerName, playersDatabaseVals.tempBanLength[0], ffi.string(playersDatabaseVals.kickBanMuteReason) } )
														TriggerServerEvent("CEITempBan", data)
														log('W', logTag, "CEITempBan Called: " .. data)
													end
													im.PopStyleColor(3)
												end
												if playersDatabase[k].tempBanRemaining then
													im.Text("	")
													im.SameLine()
													im.Text("tempBan: " .. tostring(string.format("%.0f",playersDatabase[k].tempBanRemaining)) .. " seconds left")
													if not playersDatabase[k].banReason then
														im.Text("	")
														im.SameLine()
														im.Text("banReason: No reason specified")
													end
												end
											end
											if playersDatabase[k].banReason then
												im.Text("	")
												im.SameLine()
												im.Text("banReason: " .. playersDatabase[k].banReason)
											end
											if playersDatabase[k].permissions then
												im.Text("				  ")
												im.SameLine()
												if playersDatabase[k].permissions.muted == false or playersDatabase[k].permissions.muted == nil then
													if im.SmallButton("Mute##"..playerName) then
														local data = jsonEncode( { playerName, ffi.string(playersDatabaseVals.kickBanMuteReason) } )
														TriggerServerEvent("CEIMute", data)
														log('W', logTag, "CEIMute Called: " .. data)
													end
												else
													if im.SmallButton("Unmute##"..playerName) then
														local data = jsonEncode( { playerName } )
														TriggerServerEvent("CEIUnmute", data)
														log('W', logTag, "CEIUnmute Called: " .. data)
													end
												end
												if playersDatabase[k].permissions.whitelisted == false or playersDatabase[k].permissions.whitelisted == nil then
													im.SameLine()
													if im.SmallButton("Whitelist##" .. playerName) then
														local data = jsonEncode( { "add", playerName } )
														TriggerServerEvent("CEIWhitelist", data)
														log('W', logTag, "CEIWhitelist Called: " .. data)
													end
												else
													im.SameLine()
													if im.SmallButton("Unwhitelist##" .. playerName) then
														local data = jsonEncode( { "remove", playerName } )
														TriggerServerEvent("CEIWhitelist", data)
														log('W', logTag, "CEIWhitelist Called: " .. data)
													end
												end
												if im.TreeNode1("permissions##"..playerName) then
														if playersDatabase[k].permissions.teleport == false or playersDatabase[k].permissions.teleport == nil or playersDatabase[k].permissions.teleport == "nil" then
															if im.SmallButton("Allow Teleport##"..playerName) then
																local data = jsonEncode( { playerName, true } )
																TriggerServerEvent("CEISetTeleportPerm", data)
																log('W', logTag, "CEISetTeleportPerm Called: " .. data)
															end
														elseif playersDatabase[k].permissions.teleport == true then
															if im.SmallButton("Revoke Teleport##"..playerName) then
																local data = jsonEncode( { playerName, false } )
																TriggerServerEvent("CEISetTeleportPerm", data)
																log('W', logTag, "CEISetTeleportPerm Called: " .. data)
															end
														end
													if im.TreeNode1("level:") then
														im.SameLine()
														im.Text(tostring(playersDatabase[k].permissions.level))
														im.Text("		")
														im.SameLine()
														im.PushItemWidth(100)
														if im.InputInt("", playersDatabaseVals[k].permissions.levelInt, 1) then
															local data = jsonEncode( { playersDatabase[k].playerName, tostring(playersDatabaseVals[k].permissions.levelInt[0]) } )
															TriggerServerEvent("CEISetTempPerm", data)
															log('W', logTag, "CEISetTempPerm Called: " .. data)
														end
														im.PopItemWidth()
														im.SameLine()
														if im.Button("Apply##level" .. playerName) then
															local data = jsonEncode( { playersDatabase[k].playerName, tostring(playersDatabaseVals[k].permissions.levelInt[0]) } )
															TriggerServerEvent("CEISetPerm", data)
															log('W', logTag, "CEISetPerm Called: " .. data)
														end
														im.TreePop()
													else
														im.SameLine()
														im.Text(tostring(playersDatabase[k].permissions.level))
													end
													im.Text("		whitelisted: " .. tostring(playersDatabase[k].permissions.whitelisted))
													im.Text("		muted: " .. tostring(playersDatabase[k].permissions.muted))
													im.Text("		muteReason: " .. tostring(playersDatabase[k].permissions.muteReason))
													if im.TreeNode1("group:##" .. playerName) then
														if playersDatabase[k].permissions.group then
															im.SameLine()
															im.Text(playersDatabase[k].permissions.group)
														else
															im.SameLine()
															im.Text("none")
														end
														im.Text("		")
														im.SameLine()
														if im.InputTextWithHint("##newGroup", "Group Name", playersDatabaseVals[k].permissions.groupInput, 128) then
														end
														im.Text("		")
														im.SameLine()
														if im.SmallButton("Apply##"..tostring(k)) then
															local data = jsonEncode( { playersDatabase[k].playerName, "group:" .. ffi.string(playersDatabaseVals[k].permissions.groupInput) } )
															TriggerServerEvent("CEISetGroup", data)
															log('W', logTag, "CEISetGroup Called: " .. data)
														end
														im.SameLine()
														im.PushStyleColor2(im.Col_Button, im.ImVec4(0.95, 0.15, 0.15, 0.666))
														im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(0.95, 0.15, 0.15, 0.777))
														im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(0.95, 0.15, 0.15, 0.888))
														if im.SmallButton("Remove##"..tostring(k)) then
															local data = jsonEncode( { playersDatabase[k].playerName, "none" } )
															TriggerServerEvent("CEISetGroup", data)
															log('W', logTag, "CEISetGroup Called: " .. data)
														end
														im.PopStyleColor(3)
														im.SameLine()
														im.ShowHelpMarker("Remove group or enter new Group Name and press Apply")
														im.TreePop()
													else
														if playersDatabase[k].permissions.group then
															im.SameLine()
															im.Text(playersDatabase[k].permissions.group)
														else
															im.SameLine()
															im.Text("none")
														end
													end
												end
											
											end
											im.Separator()
											im.TreePop()
										else
											im.SameLine()
											if playerBeammp then
												if tonumber(playerBeammp) < 10 then
													im.Text(playerBeammp .. "			  | " .. playerName)
												elseif tonumber(playerBeammp) < 100 then
													im.Text(playerBeammp .. "			| " .. playerName)
												elseif tonumber(playerBeammp) < 1000 then
													im.Text(playerBeammp .. "		  | " .. playerName)
												elseif tonumber(playerBeammp) < 10000 then
													im.Text(playerBeammp .. "		| " .. playerName)
												elseif tonumber(playerBeammp) < 100000 then
													im.Text(playerBeammp .. "	  | " .. playerName)
												elseif tonumber(playerBeammp) < 1000000 then
													im.Text(playerBeammp .. "	| " .. playerName)
												else
													im.Text(playerBeammp .. "  | " .. playerName)
												end
											else
												im.Text(tostring(playerBeammp) .. "			| " .. playerName)
											end
											if playersDatabase[k].tempBanRemaining then
												im.SameLine()
												im.TextColored(im.ImVec4(1.0, 0.66, 0.0, 1.0), "> TempBanned")
											end
											if playersDatabase[k].banned then
												im.SameLine()
												im.TextColored(im.ImVec4(1.0, 0.0, 0.0, 1.0), "> BANNED")
											end
											im.Separator()
										end
									end
								end
							end
						end
					end
				end
				im.Unindent()
				im.EndTabItem()
			end
			im.EndTabBar()
		end
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
	data = jsonDecode(data)
	local gameVehicleID = MPVehicleGE.getGameVehicleID(data[1] .. "-" .. data[2])
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if data[3] == false then
			if ignitionEnabled[gameVehicleID] == true or ignitionEnabled[gameVehicleID] == nil then
				veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
				veh:queueLuaCommand('electrics.set_warn_signal(0)')
				veh:queueLuaCommand('electrics.setLightsState(0)')
				veh:queueLuaCommand('electrics.set_lightbar_signal(0)')
				veh:queueLuaCommand('electrics.horn(false)')
				veh:queueLuaCommand('electrics.set_fog_lights(0)')
				ignitionEnabled[gameVehicleID] = false
			end
		elseif data[3] == true then
			if ignitionEnabled[gameVehicleID] == false then
				veh:queueLuaCommand('controller.mainController.setStarter(true)')
				veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
				veh:queueLuaCommand('controller.mainController.setStarter(false)')
				ignitionEnabled[gameVehicleID] = true
			end
		end
	end
end

local function CEIToggleLock(data)
	data = jsonDecode(data)
	local gameVehicleID = MPVehicleGE.getGameVehicleID(data[1] .. "-" .. data[2])
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if data[3] == true then
			if isFrozen[gameVehicleID] == false or isFrozen[gameVehicleID] == nil then
				veh:queueLuaCommand('controller.setFreeze(1)')
				isFrozen[gameVehicleID] = true
			end
		elseif data[3] == false then
			if isFrozen[gameVehicleID] == true then
				veh:queueLuaCommand('controller.setFreeze(0)')
				isFrozen[gameVehicleID] = false
			end
		end
	end
end

local function checkVehicleState(gameVehicleID, argument)
	for k,v in pairs(ignitionEnabled) do
		if v == false then
			local veh = be:getObjectByID(k)
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
	for k,v in pairs(isFrozen) do
		if v == true then
			local veh = be:getObjectByID(k)
			local veh = be:getObjectByID(k)
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
	end
end

local function setPhysicsSpeed(physmult)
	physics.physmult = physmult
end

local function resetsNotify(vehicleID)
	if MPVehicleGE.isOwn(vehicleID) then
		if not config.resets.enabled then
			guihooks.trigger('toastrMsg', {type="error", title = config.resets.title, msg = config.resets.disabledMessage, config = {timeOut = config.resets.messageDuration * 1000}})
			return
		else
			if #resetsBlockedInputActions > 0 then
				resetsPlayerNotified = false
				resetsTimerElapsedReset = 0
				local message = config.resets.message:gsub("{secondsLeft}", math.floor(config.resets.timeout - resetsTimerElapsedReset))
				guihooks.trigger('toastrMsg', {type="warning", title = config.resets.title, msg = message, config = {timeOut = config.resets.messageDuration * 1000}})
			end
		end
	end
end

local function onTime(timeValue, dayLengthValue)
	local timeOfDay = core_environment.getTimeOfDay()
	if timeOfDay then
		timeOfDay.time = timeValue
		timeOfDay.dayLength = dayLengthValue
		core_environment.setTimeOfDay(timeOfDay)
	end
end

local function onTimePlay(value, dt)
	local timeOfDay = core_environment.getTimeOfDay()
	if timeOfDay then
		if dt then
			if lastEnvReport + dt > envReportRate then
				timeOfDay.play = false
				core_environment.setTimeOfDay(timeOfDay)
				if timeOfDay.time > environment.ToD + 0.00625 or timeOfDay.time < environment.ToD - 0.00625 then
					onTime(environment.ToD, environment.dayLength)
				end
			end
		end
		timeOfDay.play = value
		core_environment.setTimeOfDay(timeOfDay)
	end
end

local function onDayScale(value)
	if value == nil then
	else
		local value2 = value / physics.physmult
		local timeOfDay = core_environment.getTimeOfDay()
		if timeOfDay then
			timeOfDay.dayScale = value2
			core_environment.setTimeOfDay(timeOfDay)
		end
	end
end

local function onDayLength(value)
	if value == nil then
	else
		local timeOfDay = core_environment.getTimeOfDay()
		if timeOfDay then
			timeOfDay.dayLength = value
			core_environment.setTimeOfDay(timeOfDay)
		end
	end
end

local function onNightScale(value)
	if value == nil then
	else
		local value2 = value / physics.physmult
		local timeOfDay = core_environment.getTimeOfDay()
		if timeOfDay then
			timeOfDay.nightScale = value2
			core_environment.setTimeOfDay(timeOfDay)
		end
	end
end

local function onSunAzimuth(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.azimuth = value
		scatterSkyObj:postApply()
	end
end

local function onSunSize(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.sunSize = value
	end
end

local function onSkyBrightness(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.skyBrightness = value
	end
end

local function onRayleighScattering(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.rayleighScattering = value
	end
end

local function onFlareScale(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.flareScale = value
	end
end

local function onOcclusionScale(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.occlusionScale = value
	end
end

local function onSunLightBrightness(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.brightness = value
	end
end

local function onExposure(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.exposure = value
	end
end

local function onShadowDistance(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.shadowDistance = value
	end
end

local function onShadowSoftness(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.shadowSoftness = value
	end
end

local function onShadowSplits(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.numSplits = value
	end
end

local function onShadowTexSize(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.texSize = value
		scatterSkyObj:postApply()
	end
end

local function onShadowLogWeight(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.logWeight = value
	end
end

local function onVisibleDistance(value)
	if value == nil then
	else
		local levelInfo = getObject("LevelInfo")
		if not levelInfo then
			return
		end
		levelInfo.visibleDistance = value
		levelInfo:postApply()
	end
end

local function onMoonAzimuth(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.moonAzimuth = value
		scatterSkyObj:postApply()
	end
end

local function onMoonElevation(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.moonElevation = value
		scatterSkyObj:postApply()
	end
end

local function onMoonScale(value)
	local scatterSkyObj = getObject("ScatterSky")
	if scatterSkyObj and value then
		scatterSkyObj.moonScale = value
		scatterSkyObj:postApply()
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
	local rainObj = getObject("Precipitation")
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
	local rainObj = getObject("Precipitation")
	if rainObj and value then
		rainObj.dropSize = value
	end
end

local function onDropMinSpeed(value)
	local rainObj = getObject("Precipitation")
	if rainObj and value then
		rainObj.minSpeed = value
	end
end

local function onDropMaxSpeed(value)
	local rainObj = getObject("Precipitation")
	if rainObj and value then
		rainObj.maxSpeed = value
	end
end

local function onTempCurve()
	local tempCurve
	if environment.useTempCurve == true and defaultTempCurveSet == false then
		local levelInfo = getObject("LevelInfo")
		if not levelInfo then
			return
		end
		defaultTempCurve = levelInfo:getTemperatureCurveC()
		if type(defaultTempCurve) == "table" then
			defaultTempCurveSet = true
		end
	elseif environment.useTempCurve == false or environment.useTempCurve == nil then
		local levelInfo = getObject("LevelInfo")
		if not levelInfo then
			return
		elseif defaultTempCurveSet == false then
			defaultTempCurve = levelInfo:getTemperatureCurveC()
			if type(defaultTempCurve) == "table" then
				defaultTempCurveSet = true
			end
		elseif defaultTempCurveSet == true then
			levelInfo:setTemperatureCurveC(defaultTempCurve)
		end
		return
	elseif defaultTempCurveSet == true then
		local levelInfo = getObject("LevelInfo")
		if not levelInfo then
			return
		end
		tempCurve = { 
			{ 0, environmentVals.tempCurveNoonInt[0] },
			{ 0.25, environmentVals.tempCurveDuskInt[0] },
			{ 0.5, environmentVals.tempCurveMidnightInt[0] },
			{ 0.75, environmentVals.tempCurveDawnInt[0] },
			{ 1, environmentVals.tempCurveNoonInt[0] } 
		}
		levelInfo:setTemperatureCurveC(tempCurve)
	end
end

local function onSimSpeed(value)
	if environment.controlSimSpeed == true and defaultSimSpeedSet == true then
		defaultSimSpeedSet = false
	elseif environment.controlSimSpeed == true and defaultSimSpeedSet == false then
		be:setSimulationTimeScale(value)
	elseif environment.controlSimSpeed == false and defaultSimSpeedSet == false then
		be:setSimulationTimeScale(1)
		defaultSimSpeedSet = true
	end
end

local function onGravity(value)
	if environment.controlGravity == true and defaultGravitySet == true then
		defaultGravitySet = false
	elseif environment.controlGravity == true and defaultGravitySet == false then
		core_environment.setGravity(value)
	elseif environment.controlGravity == false and defaultGravitySet == false then
		core_environment.setGravity(-9.81)
		defaultGravitySet = true
	end
end

local function onWorldReadyState(state)
	worldReadyState = state
end

local function rxTeleportFrom(data)
	MPVehicleGE.teleportVehToPlayer(data)
end

local function runEnvironment(dt)
	local levelInfo = getObject("LevelInfo")
	if not levelInfo then
		return
	end
	if environment then
		if environment.controlSun == true and defaultSunSet == true then
			defaultSunSet = false
		elseif environment.controlSun == true and defaultSunSet == false then
			onTimePlay(environment.timePlay, dt)
			if environment.ToD then
				if firstReport == true then
					if environment.timePlay == false or environment.timePlay == nil then
						onTime(environment.ToD, environment.dayLength)
					elseif timeUpdateQueued == true then
						if timeUpdateTimer + dt > timeUpdateTimeout then
							onTime(environment.ToD, environment.dayLength)
							timeUpdateQueued = false
							timeUpdateTimer = 0
							core_environment.reset()
						else
							timeUpdateTimer = timeUpdateTimer + dt
						end
					end
				else
					onTime(environment.ToD, environment.dayLength)
					firstReport = true
				end
			end
			onDayLength(environment.dayLength)
			onDayScale(environment.dayScale)
			onNightScale(environment.nightScale)
			onSunAzimuth(environment.sunAzimuth)
			onSunSize(environment.sunSize)
			onSkyBrightness(environment.skyBrightness)
			onRayleighScattering(environment.rayleighScattering)
			onSunLightBrightness(environment.sunLightBrightness)
			onFlareScale(environment.flareScale)
			onOcclusionScale(environment.occlusionScale)
			onExposure(environment.exposure)
			onShadowDistance(environment.shadowDistance)
			onShadowSoftness(environment.shadowSoftness)
			onShadowSplits(environment.shadowSplits)
			onShadowTexSize(environment.shadowTexSize)
			onShadowLogWeight(environment.shadowLogWeight)
			onVisibleDistance(environment.visibleDistance)
			onMoonAzimuth(environment.moonAzimuth)
			onMoonElevation(environment.moonElevation)
			onMoonScale(environment.moonScale)
		elseif environment.controlSun == false and defaultSunSet == false then
			onTimePlay(environment.timePlay_default)
			onTime(environment.ToD_default, environment.dayLength_default)
			onDayLength(environment.dayLength_default)
			onDayScale(environment.dayScale_default)
			onNightScale(environment.nightScale_default)
			onSunAzimuth(environment.sunAzimuth_default)
			onSunSize(environment.sunSize_default)
			onSkyBrightness(environment.skyBrightness_default)
			onRayleighScattering(environment.rayleighScattering_default)
			onSunLightBrightness(environment.sunLightBrightness_default)
			onFlareScale(environment.flareScale_default)
			onOcclusionScale(environment.occlusionScale_default)
			onExposure(environment.exposure_default)
			onShadowDistance(environment.shadowDistance_default)
			onShadowSoftness(environment.shadowSoftness_default)
			onShadowSplits(environment.shadowSplits_default)
			onShadowTexSize(environment.shadowTexSize_default)
			onShadowLogWeight(environment.shadowLogWeight_default)
			onVisibleDistance(environment.visibleDistance_default)
			onMoonAzimuth(environment.moonAzimuth_default)
			onMoonElevation(environment.moonElevation_default)
			onMoonScale(environment.moonScale_default)
			defaultSunSet = true
		end
		if environment.controlWeather == true and defaultWeatherSet == true then
			defaultWeatherSet = false
		elseif environment.controlWeather == true and defaultWeatherSet == false then
			onFogDensity(environment.fogDensity)
			onFogDensityOffset(environment.fogDensityOffset)
			onCloudCover(environment.cloudCover)
			onCloudSpeed(environment.cloudSpeed)
			onRainDrops(environment.rainDrops)
			onDropSize(environment.dropSize)
			onDropMinSpeed(environment.dropMinSpeed)
			onDropMaxSpeed(environment.dropMaxSpeed)
		elseif environment.controlWeather == false and defaultWeatherSet == false then
			onFogDensity(environment.fogDensity_default)
			onFogDensityOffset(environment.fogDensityOffset_default)
			onCloudCover(environment.cloudCover_default)
			onCloudSpeed(environment.cloudSpeed_default)
			onRainDrops(environment.rainDrops_default)
			onDropSize(environment.dropSize_default)
			onDropMinSpeed(environment.dropMinSpeed_default)
			onDropMaxSpeed(environment.dropMaxSpeed_default)
			defaultWeatherSet = true
		end
		onSimSpeed(environment.simSpeed)
		onTempCurve()
		onGravity(environment.gravity)
		if lastEnvReport + dt > envReportRate then
			lastEnvReport = 0
			core_environment.reset()
		else
			lastEnvReport = lastEnvReport + dt
		end
	end
end

local function checkResetState(dt)
	resetsTimerElapsedReset = resetsTimerElapsedReset + dt
	if config then
		if config.resets then
			if config.resets.control then
				if not config.resets.enabled then
					extensions.core_input_actionFilter.setGroup('cei', allResetsBlockedInputActions)
					extensions.core_input_actionFilter.addAction(0, 'cei', true)
				else
					if resetsTimerElapsedReset <= tonumber(config.resets.timeout) then
						extensions.core_input_actionFilter.setGroup('cei', resetsBlockedInputActions)
						extensions.core_input_actionFilter.addAction(0, 'cei', true)
					else
						if resetsPlayerNotified == true then
							extensions.core_input_actionFilter.setGroup('cei', resetsBlockedInputActions)
							extensions.core_input_actionFilter.addAction(0, 'cei', false)
						elseif resetsPlayerNotified == false then
							guihooks.trigger('toastrMsg', {type="info", title = config.resets.title, msg = config.resets.elapsedMessage, config = {timeOut = config.resets.messageDuration * 1000 }})
							resetsPlayerNotified = true
						end
					end
				end
			end
		end
	end
end

local function onUpdate(dt)
	if worldReadyState == 2 then
		if windowOpen[0] == true then
			drawCEI(dt)
		end
		checkVehicleState()
		checkResetState(dt)
		runEnvironment(dt)
		lastTeleport = lastTeleport + dt
	end
end

local function onVehicleSpawned(gameVehicleID)
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		veh:queueLuaCommand('extensions.CEI_CEIPhysics.update()')
		if isFrozen[gameVehicleID] == false then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[gameVehicleID] == true then
			veh:queueLuaCommand('controller.setFreeze(1)')
		else
			isFrozen[gameVehicleID] = false
		end
		if ignitionEnabled[gameVehicleID] == true then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[gameVehicleID] == false
		then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		else
			ignitionEnabled[gameVehicleID] = true
		end
	end
end

local function onVehicleDestroyed(gameVehicleID)
	ignitionEnabled[gameVehicleID] = nil
	isFrozen[gameVehicleID] = nil
end

local function onVehicleResetted(gameVehicleID)
	if MPVehicleGE.isOwn(gameVehicleID) then
		if not firstReset then
			firstReset = true
		end
		if not firstTeleport then
			firstTeleport = true
		end
	end
	if config.resets then
		if config.resets.control then
			resetsNotify(gameVehicleID)
		end
	end
	local veh = be:getObjectByID(gameVehicleID)
	if veh then
		if isFrozen[gameVehicleID] == false then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[gameVehicleID] == true then
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
		if ignitionEnabled[gameVehicleID] == true then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[gameVehicleID] == false then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
end

local function onVehicleSwitched(oldGameVehicleID, newGameVehicleID)
	local veh = be:getObjectByID(newGameVehicleID)
	if veh then
		if isFrozen[newGameVehicleID] == false then
			veh:queueLuaCommand('controller.setFreeze(0)')
		elseif isFrozen[newGameVehicleID] == true then
			veh:queueLuaCommand('controller.setFreeze(1)')
		end
		if ignitionEnabled[newGameVehicleID] == true then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(true) end')
		elseif ignitionEnabled[newGameVehicleID] == false then
			veh:queueLuaCommand('if controller.mainController.setEngineIgnition then controller.mainController.setEngineIgnition(false) end')
		end
	end
	if newGameVehicleID and newGameVehicleID > -1 then
		local oldVehicle = be:getObjectByID(oldGameVehicleID or -1)
		local newVehicle = be:getObjectByID(newGameVehicleID or -1)
		local newVehObj = MPVehicleGE.getVehicleByGameID(newGameVehicleID) or {}
		local newServerVehicleID = newVehObj.serverVehicleString
		if newServerVehicleID then
			local data = jsonEncode( { newServerVehicleID } )
			TriggerServerEvent("CEISetCurVeh", data)
			log('W', logTag, "CEISetCurVeh Called: " .. data)
		end
	end
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
				local data = jsonEncode( { false } )
				TriggerServerEvent("CEINametagSetting", data)
				log('W', logTag, "CEINametagSetting: " .. data)
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
	log('W', logTag, "-=$=- INJECTING UI APPS -=$=-")
	local currentMpLayout = jsonReadFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json")
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
			jsonWriteFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json", currentMpLayout, 1)
			currentMpLayout = nil
		end
	end
	AddEventHandler("rxPlayersData", rxPlayersData)
	AddEventHandler("rxPlayersDatabase", rxPlayersDatabase)
	AddEventHandler("rxPlayerGroup", rxPlayerGroup)
	AddEventHandler("rxConfigData", rxConfigData)
	AddEventHandler("rxInputUpdate", rxInputUpdate)
	AddEventHandler("rxEnvironment", rxEnvironment)
	AddEventHandler("rxCEIstate", rxCEIstate)
	AddEventHandler("rxCEItp", rxCEItp)
	AddEventHandler("rxTeleportFrom", rxTeleportFrom)
	AddEventHandler("rxNametagWhitelisted", rxNametagWhitelisted)
	AddEventHandler("rxNametagBlockerActive", rxNametagBlockerActive)
	AddEventHandler("rxNametagBlockerTimeout", rxNametagBlockerTimeout)
	AddEventHandler("CEIToggleIgnition", CEIToggleIgnition)
	AddEventHandler("CEIToggleLock", CEIToggleLock)
	AddEventHandler("CEIRaceCountdown", CEIRaceCountdown)
	AddEventHandler("CEIRaceCountSound", CEIRaceCountSound)
	gui_module.initialize(gui)
	gui.registerWindow("CEI", im.ImVec2(512, 256))
	gui.showWindow("CEI")
	log('W', logTag, "-=$=- CEI LOADED -=$=-")
end

local function onExtensionUnloaded()
	log('W', logTag, "-=$=- RESETTING UI APPS -=$=-")
	jsonWriteFile("settings/ui_apps/layouts/default/multiplayer.uilayout.json", originalMpLayout, 1)
	log('W', logTag, "-=$=- CEI UNLOADED -=$=-")
end

M.dependencies = {"ui_imgui"}
M.onUpdate = onUpdate
M.onPreRender = onPreRender
M.onWorldReadyState = onWorldReadyState

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

M.onVehicleSpawned = onVehicleSpawned
M.onVehicleDestroyed = onVehicleDestroyed
M.onVehicleSwitched = onVehicleSwitched
M.onVehicleResetted = onVehicleResetted

M.setPhysicsSpeed = setPhysicsSpeed

return M
