--CEI (SERVER) by Dudekahedron, 2022

local M = {}

M.COBALT_VERSION = "1.6.0"

utils.setLogType("CEI",93)

local CobaltDBport = 58933

local tomlParser = require("toml")

local loadedDatabases = {}

local showCEI = {}

local tempPlayers = {}
local tempPCV = {}

local serverConfig = {}
local cobaltConfig = {}
cobaltConfig.whitelistedPlayers = {}
cobaltConfig.groups = {}
cobaltConfig.permissions = {}
cobaltConfig.permissions.vehicleCap = {}

local environment = CobaltDB.new("environment")
local defaultToD = 0.1
local defaultTimePlay = "false"
local defaultDayScale = 1
local defaultNightScale = 2
local defaultAzimuthOverride = 0
local defaultSunSize = 1
local defaultSkyBrightness = 40
local defaultSunLightBrightness = 1
local defaultExposure = 1
local defaultShadowDistance = 1600
local defaultShadowSoftness = 0.2
local defaultShadowSplits = 4
local defaultFogDensity = 0.0001
local defaultFogDensityOffset = 8
local defaultCloudCover = 0.08
local defaultCloudSpeed = 0.2
local defaultRainDrops = 0
local defaultDropSize = 1
local defaultDropMinSpeed = 0.1
local defaultDropMaxSpeed = 0.2
local defaultPrecipType = "rain_medium"
local defaultTeleportTimeout = 5
local defaultSimSpeed = 1
local defaultGravity = -9.81
local ToD
local timePlay
local dayScale
local nightScale
local azimuthOverride
local sunSize
local skyBrightness
local sunLightBrightness
local exposure
local shadowDistance
local shadowSoftness
local shadowSplits
local fogDensity
local fogDensityOffset
local cloudCover
local cloudSpeed
local rainDrops
local dropSize
local dropMinSpeed
local dropMaxSpeed
local precipType
local teleportTimeout
local simSpeed
local gravity

local defaultEnvironment = {
	ToD = {value = defaultToD, description = "What is the Time of Day?"},
	timePlay = {value = defaultTimePlay, description = "Does time progress?"},
	dayScale = {value = defaultDayScale, description = "At what rate does daytime progress?"},
	nightScale = {value = defaultNightScale, description = "At what rate does nighttime progress?"},
	azimuthOverride = {value = defaultAzimuthOverride, description = "At what position on the horizon does the sun rise and set?"},
	sunSize = {value = defaultSunSize, description = "How big is the sun?"},
	skyBrightness = {value = defaultSkyBrightness, description = "How bright is the sky?"},
	sunLightBrightness = {value = defaultSunLightBrightness, description = "How bright is the sunlight?"},
	exposure = {value = defaultExposure, description = "How exposed is the environment?"},
	shadowDistance = {value = defaultShadowDistance, description = "How far are the shadows?"},
	shadowSoftness = {value = defaultShadowSoftness, description = "How soft are the shadows?"},
	shadowSplits = {value = defaultShadowSplits, description = "How many splits are there for shadows?"},
	fogDensity = {value = defaultFogDensity, description = "How thicc is the fog?"},
	fogDensityOffset = {value = defaultFogDensityOffset, description = "How far away is the fog?"},
	cloudCover = {value = defaultCloudCover, description = "How thicc are the clouds?"},
	cloudSpeed = {value = defaultCloudSpeed, description = "How fast are the clouds?"},
	rainDrops = {value = defaultRainDrops, description = "How many rain drops are there?"},
	dropSize = {value = defaultDropSize, description = "What size are the drops of precipitation?"},
	dropMinSpeed = {value = defaultDropMinSpeed, description = "What is the minimum speed of precipitation?"},
	dropMaxSpeed = {value = defaultDropMaxSpeed, description = "What is the maximum speed of precipitation?"},
	precipType = {value = defaultPrecipType, description = "What type of precipitation do we use?"},
	teleportTimeout = {value = defaultTeleportTimeout, description = "How long between telports?"},
	simSpeed = {value = defaultSimSpeed, description = "At what rate does the simulation run?"},
	gravity = {value = defaultGravity, description = "At what rate do objects fall towards the ground?"},
}

local raceCountdown
local raceCountdownStarted

local function onInit()
	MP.RegisterEvent("onPlayerAuth", "onPlayerAuthHandler")
	MP.RegisterEvent("CEISetCurVeh","CEISetCurVeh")
	MP.RegisterEvent("CEIPreRace","CEIPreRace")
	MP.RegisterEvent("CEIToggleIgnition","CEIToggleIgnition")
	MP.RegisterEvent("CEIToggleLock","CEIToggleLock")
	MP.RegisterEvent("CEISetNewGroup","CEISetNewGroup")
	MP.RegisterEvent("CEIRemoveGroup","CEIRemoveGroup")
	MP.RegisterEvent("CEISetGroupLevel","CEISetGroupLevel")
	MP.RegisterEvent("CEISetGroupPerms","CEISetGroupPerms")
	MP.RegisterEvent("CEISetPerm","CEISetPerm")
	MP.RegisterEvent("CEISetTempPerm","CEISetTempPerm")
	MP.RegisterEvent("CEISetVehiclePerms","CEISetVehiclePerms")
	MP.RegisterEvent("CEISetNewVehiclePermsLevel","CEISetNewVehiclePermsLevel")
	MP.RegisterEvent("CEIRemoveVehiclePermsLevel","CEIRemoveVehiclePermsLevel")
	MP.RegisterEvent("CEISetGroup","CEISetGroup")
	MP.RegisterEvent("CEISetCfg","CEISetCfg")
	MP.RegisterEvent("CEISetMaxActivePlayers","CEISetMaxActivePlayers")
	MP.RegisterEvent("CEISetServerName","CEISetServerName")
	MP.RegisterEvent("CEIRemoveVehicle","CEIRemoveVehicle")
	MP.RegisterEvent("CEIKick","CEIKick")
	MP.RegisterEvent("CEIBan","CEIBan")
	MP.RegisterEvent("CEITempBan","CEITempBan")
	MP.RegisterEvent("CEIMute","CEIMute")
	MP.RegisterEvent("CEIUnmute","CEIUnmute")
	MP.RegisterEvent("CEIWhitelist","CEIWhitelist")
	MP.RegisterEvent("CEIConfig","CEIConfig")
	MP.RegisterEvent("CEIStop","CEIStop")
	MP.RegisterEvent("CEISetEnv","CEISetEnv")
	MP.RegisterEvent("CEISetTempBan","CEISetTempBan")
	serverConfig.name = utils.readCfg("ServerConfig.toml").General.Name
	if not utils.readCfg("ServerConfig.toml").General.Debug then
		serverConfig.debug = "false"
	else
		serverConfig.debug = "true"
	end
	if not utils.readCfg("ServerConfig.toml").General.Private then
		serverConfig.private = "false"
	else
		serverConfig.private = "true"
	end
	serverConfig.maxCars = utils.readCfg("ServerConfig.toml").General.MaxCars
	serverConfig.maxPlayers = utils.readCfg("ServerConfig.toml").General.MaxPlayers
	serverConfig.map = utils.readCfg("ServerConfig.toml").General.Map
	serverConfig.description = utils.readCfg("ServerConfig.toml").General.Description
	
	M.applyStuff(environment, defaultEnvironment)
	
	ToD = CobaltDB.query("environment", "ToD", "value")
	timePlay = CobaltDB.query("environment", "timePlay", "value")
	dayScale = CobaltDB.query("environment", "dayScale", "value")
	nightScale = CobaltDB.query("environment", "nightScale", "value")
	azimuthOverride = CobaltDB.query("environment", "azimuthOverride", "value")
	sunSize = CobaltDB.query("environment", "sunSize", "value")
	skyBrightness = CobaltDB.query("environment", "skyBrightness", "value")
	sunLightBrightness = CobaltDB.query("environment", "sunLightBrightness", "value")
	exposure = CobaltDB.query("environment", "exposure", "value")
	shadowDistance = CobaltDB.query("environment", "shadowDistance", "value")
	shadowSoftness = CobaltDB.query("environment", "shadowSoftness", "value")
	shadowSplits = CobaltDB.query("environment", "shadowSplits", "value")
	fogDensity = CobaltDB.query("environment", "fogDensity", "value")
	fogDensityOffset = CobaltDB.query("environment", "fogDensityOffset", "value")
	cloudCover = CobaltDB.query("environment", "cloudCover", "value")
	cloudSpeed = CobaltDB.query("environment", "cloudSpeed", "value")
	rainDrops = CobaltDB.query("environment", "rainDrops", "value")
	dropSize = CobaltDB.query("environment", "dropSize", "value")
	dropMinSpeed = CobaltDB.query("environment", "dropMinSpeed", "value")
	dropMaxSpeed = CobaltDB.query("environment", "dropMaxSpeed", "value")
	precipType = CobaltDB.query("environment", "precipType", "value")
	teleportTimeout = CobaltDB.query("environment", "teleportTimeout", "value")
	simSpeed = CobaltDB.query("environment", "simSpeed", "value")
	gravity = CobaltDB.query("environment", "gravity", "value")
	
	CElog("CEI Loaded!", "CEI")
end

local function applyStuff(targetDatabase, tables)
	local appliedTables = {}
	for tableName, table in pairs(tables) do
		if targetDatabase[tableName]:exists() == false then
			for key, value in pairs(table) do
				targetDatabase[tableName][key] = value
			end
			appliedTables[tableName] = tableName
		end
	end
	return appliedTables
end

local CEICommands = {
		CEI = {orginModule = "CEI", level = 0, arguments = 0, sourceLimited = 1, description = "Toggles Cobalt Essentials Interface"}
	}

applyStuff(commands, CEICommands)

local function CEI(player)
	CElog("CEI Called by: " .. player.name, "CEI")
	local state 
	if showCEI[player.name] == false then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", true)
		showCEI[player.name] = true
		state = "show"
	elseif showCEI[player.name] == true then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", false)
		showCEI[player.name] = false
		state = "hide"
	end
	MP.TriggerClientEvent(player.playerID, "rxCEIstate", state)
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function txPlayersRoles(player)
	local data = ""
	for ID, player in pairs(players) do
		if type(ID) == "number" then
			if MP.IsPlayerConnected(player.playerID) then
				if player.permissions.group == "owner" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","owner")
					data = data .. "|owner_" .. player.playerID .. "_" .. player.name
				end
				if player.permissions.group == "admin" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","admin")
					data = data .. "|admin_" .. player.playerID .. "_" .. player.name
				end
				if player.permissions.group == "mod" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","mod")
					data = data .. "|mod_" .. player.playerID .. "_" .. player.name
				end
				if player.permissions.group == "default" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","player")
					data = data .. "|player_" .. player.playerID .. "_" .. player.name
				end
				if player.permissions.group == "guest" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","guest")
					data = data .. "|guest_" .. player.playerID .. "_" .. player.name
				end
				if player.permissions.group == "inactive" then
					MP.TriggerClientEvent(player.playerID,"rxPlayerRole","spectator")
					data = data .. "|spectator_" .. player.playerID .. "_" .. player.name
				end
			end
		end
	end
	MP.TriggerClientEvent(player.playerID,"rxPlayersRoles",data)
end

local function txStats(player)
	local data = ""

end

local function txEnvironment(player)
	local data = ""
	data = data .. "|" .. ToD
				.. "$" .. timePlay
				.. "$" .. dayScale
				.. "$" .. nightScale
				.. "$" .. azimuthOverride
				.. "$" .. sunSize
				.. "$" .. skyBrightness
				.. "$" .. sunLightBrightness
				.. "$" .. exposure
				.. "$" .. shadowDistance
				.. "$" .. shadowSoftness
				.. "$" .. shadowSplits
				.. "$" .. fogDensity
				.. "$" .. fogDensityOffset
				.. "$" .. cloudCover
				.. "$" .. cloudSpeed
				.. "$" .. rainDrops
				.. "$" .. dropSize
				.. "$" .. dropMinSpeed
				.. "$" .. dropMaxSpeed
				.. "$" .. precipType
				.. "$" .. teleportTimeout
				.. "$" .. simSpeed
				.. "$" .. gravity
				
	if MP.IsPlayerConnected(player.playerID) then
		MP.TriggerClientEvent(player.playerID,"rxEnvironment",data)
	end
end

local function txPlayersData(player)
	local data = ""
	for ID, player in pairs(players) do
		if type(ID) == "number" then
			local playerName = player.name
			local guest
			local locked
			local whitelisted
			local muted
			local muteReason
			local banned
			if player.guest then
				guest = "true"
			else
				guest = "false"
			end
			if player.gamemode.locked then
				locked = "true"
			else
				locked = "false"
			end
			if player.permissions.whitelisted then
				whitelisted = "true"
			else
				whitelisted = "false"
			end
			if player.permissions.muted then
				muted = "true"
			else
				muted = "false"
			end
			if player.permissions.muteReason then
				muteReason = player.permissions.muteReason
			else
				muteReason = ""
			end
			if player.permissions.banned then
				banned = "true"
			else
				banned = "false"
			end
			local connectedTime = round(os.clock()*1000 - player.joinTime)
			connectedTime = round(connectedTime / 1000)
			data = data .. "|" .. player.playerID
						.. "," .. player.name
						.. "," .. player.connectStage
						.. "," .. guest
						.. "," .. round(player.joinTime / 1000)
						.. "," .. player.gamemode.mode
						.. "," .. player.gamemode.source
						.. "," .. player.gamemode.queue
						.. "," .. locked
						.. "," .. whitelisted
						.. "," .. muted
						.. "," .. player.permissions.level
						.. "," .. banned
						.. "," .. player.permissions.group
						.. "," .. connectedTime
						.. "," .. muteReason
						.. "," .. tempPlayers[playerName].tempBanLength
						.. "," .. tempPlayers[playerName].tempPermLevel
						.. "," .. tempPCV[playerName]
			if player.vehicles then
				data = data .. ","
				for vehicleID, vehicleData in pairs(player.vehicles) do
					data = data .. "$" .. vehicleID .. "_" .. vehicleData.name
				end
			end
		end
	end
	if data == "" then
	else
		MP.TriggerClientEvent(player.playerID,"rxPlayersData",data)
	end
end

local function txConfigData(player)
	local data = ""
	cobaltConfig.maxActivePlayers = tostring(CobaltDB.query("config", "maxActivePlayers", "value"))
	if CobaltDB.query("config", "enableColors", "value") then
		cobaltConfig.enableColors = "true"
	else
		cobaltConfig.enableColors = "false"
	end
	if CobaltDB.query("config", "enableDebug", "value") then
		cobaltConfig.enableDebug = "true"
	else
		cobaltConfig.enableDebug = "false"
	end
	if CobaltDB.query("config", "RCONenabled", "value") then
		cobaltConfig.RCONenabled = "true"
	else
		cobaltConfig.RCONenabled = "false"
	end
	if CobaltDB.query("config", "RCONkeepAliveTick", "value") then
		cobaltConfig.RCONkeepAliveTick = "true"
	else
		cobaltConfig.RCONkeepAliveTick = "false"
	end
	cobaltConfig.RCONpassword = tostring(CobaltDB.query("config", "RCONpassword", "value"))
	cobaltConfig.RCONport = tostring(CobaltDB.query("config", "RCONport", "value"))
	cobaltConfig.CobaltDBport = tostring(CobaltDB.query("config", "CobaltDBport", "value"))
	if CobaltDB.query("config", "enableWhitelist", "value") then
		cobaltConfig.enableWhitelist = "true"
	else
		cobaltConfig.enableWhitelist = "false"
	end
	data = data .. "|" .. serverConfig.name
				.. "$" .. serverConfig.debug
				.. "$" .. serverConfig.private
				.. "$" .. serverConfig.maxCars
				.. "$" .. serverConfig.maxPlayers
				.. "$" .. serverConfig.map
				.. "$" .. serverConfig.description
				.. "$" .. cobaltConfig.maxActivePlayers
				.. "$" .. cobaltConfig.enableWhitelist
				.. "$" .. cobaltConfig.enableColors
				.. "$" .. cobaltConfig.enableDebug
				.. "$" .. cobaltConfig.RCONenabled
				.. "$" .. cobaltConfig.RCONkeepAliveTick
				.. "$" .. cobaltConfig.RCONpassword
				.. "$" .. cobaltConfig.RCONport
				.. "$" .. cobaltConfig.CobaltDBport
				.. "$"
	local playerGroupsLength = 0
	local whitelistLength = 0
	local groupPlayerLength = 0
	for k,v in pairs(players.database) do
		if string.find(k, "group") then
			playerGroupsLength = playerGroupsLength + 1
			cobaltConfig.groups[playerGroupsLength] = {}
			cobaltConfig.groups[playerGroupsLength].groupName = k
			cobaltConfig.groups[playerGroupsLength].groupPerms = {}
			cobaltConfig.groups[playerGroupsLength].groupPerms.level = CobaltDB.query("playerPermissions",k,"level")
			cobaltConfig.groups[playerGroupsLength].groupPerms.whitelisted = CobaltDB.query("playerPermissions",k,"whitelisted")
			cobaltConfig.groups[playerGroupsLength].groupPerms.muted = CobaltDB.query("playerPermissions",k,"muted")
			cobaltConfig.groups[playerGroupsLength].groupPerms.banned = CobaltDB.query("playerPermissions",k,"banned")
			cobaltConfig.groups[playerGroupsLength].groupPerms.banReason = CobaltDB.query("playerPermissions",k,"banReason")
			cobaltConfig.groups[playerGroupsLength].groupPlayers = {}
			for w,z in pairs(players.database) do
				for a,b in pairs(z) do
					if a == "group" then
						if "group:"..b == k then
							groupPlayerLength = groupPlayerLength + 1
							cobaltConfig.groups[playerGroupsLength].groupPlayers[groupPlayerLength] = {}
							cobaltConfig.groups[playerGroupsLength].groupPlayers[groupPlayerLength].name = w
						end
					end
				end
			end
		else
			local playerGroup = players.database[k].group
			for x,y in pairs(v) do
				if x == "whitelisted" then
					if y == true then
						whitelistLength = whitelistLength + 1
						cobaltConfig.whitelistedPlayers[whitelistLength] = {}
						cobaltConfig.whitelistedPlayers[whitelistLength].name = k
					end
				end
			end
			if playerGroup then
				if players.database["group:"..playerGroup].whitelisted == true then
					whitelistLength = whitelistLength + 1
					cobaltConfig.whitelistedPlayers[whitelistLength] = {}
					cobaltConfig.whitelistedPlayers[whitelistLength].name = k
				end
			end
			
		end
	end
	for i = 1, playerGroupsLength do
		data = data .. "|" .. cobaltConfig.groups[i].groupName
		if cobaltConfig.groups[i].groupPerms.level then
			cobaltConfig.groups[i].groupPerms.level = "level_"..cobaltConfig.groups[i].groupPerms.level
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.level
		end
		if cobaltConfig.groups[i].groupPerms.whitelisted == true then
			cobaltConfig.groups[i].groupPerms.whitelisted = "whitelisted_true"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.whitelisted
		elseif cobaltConfig.groups[i].groupPerms.whitelisted == false then
			cobaltConfig.groups[i].groupPerms.whitelisted = "whitelisted_false"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.whitelisted
		end
		if cobaltConfig.groups[i].groupPerms.muted == true then
			cobaltConfig.groups[i].groupPerms.muted = "muted_true"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.muted
		elseif cobaltConfig.groups[i].groupPerms.muted == false then
			cobaltConfig.groups[i].groupPerms.muted = "muted_false"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.muted
		end
		if cobaltConfig.groups[i].groupPerms.banned == true then
			cobaltConfig.groups[i].groupPerms.banned = "banned_true"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.banned
		elseif cobaltConfig.groups[i].groupPerms.banned == false then
			cobaltConfig.groups[i].groupPerms.banned = "banned_false"
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.banned
		end
		if cobaltConfig.groups[i].groupPerms.banReason then
			cobaltConfig.groups[i].groupPerms.banReason = "banReason_"..cobaltConfig.groups[i].groupPerms.banReason
			data = data .. "@" .. cobaltConfig.groups[i].groupPerms.banReason
		end
		for j = 1, groupPlayerLength do
			if cobaltConfig.groups[i].groupPlayers[j] then
				data = data .. "@" .. "name_" .. cobaltConfig.groups[i].groupPlayers[j].name
			end
		end
	end
	data = data .. "$"
	local vehicleCaps = CobaltDB.getTable("permissions","vehicleCap")
	local vehicleCapsLength = 0
	for k,v in pairs(vehicleCaps) do
		if string.find(k, "%d+") then
			vehicleCapsLength = vehicleCapsLength + 1
			cobaltConfig.permissions.vehicleCap[vehicleCapsLength] = {}
			cobaltConfig.permissions.vehicleCap[vehicleCapsLength].level = k
			cobaltConfig.permissions.vehicleCap[vehicleCapsLength].vehicles = CobaltDB.query("permissions","vehicleCap",k)
		end
	end
	for i = 1, vehicleCapsLength do
		data = data .. "|" .. cobaltConfig.permissions.vehicleCap[i].level
					.. "#" .. cobaltConfig.permissions.vehicleCap[i].vehicles
	end
	data = data .. "$"
	for i = 1, whitelistLength do
		data = data .. "|" .. cobaltConfig.whitelistedPlayers[i].name
	end
	MP.TriggerClientEvent(player.playerID,"rxConfigData",data)
end

function CEIPreRace(senderID, data)
	CElog("CEIStartRace Called by: " .. senderID .. ": " .. data, "CEI")
	if not raceCountdownStarted then
		raceCountdownStarted = true
		raceCountdown = 15
	end
end

function CEISetTempBan(senderID, data)
	--CElog("CEISetTempBan Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local targetID = tonumber(tempData[1])
	local name = players[targetID].name
	local playerTempBanLength = tonumber(tempData[2])
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		tempPlayers[name].tempBanLength = playerTempBanLength
	end
end

function CEISetEnv(senderID, data)
	--CElog("CEISetEnv Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local key = tempData[1]
		local value = tempData[2]
		
		if key == "allWeather" then
			CobaltDB.set("environment", "fogDensity", "value", defaultFogDensity)
			fogDensity = defaultFogDensity
			CobaltDB.set("environment", "fogDensityOffset", "value", defaultFogDensityOffset)
			fogDensityOffset = defaultFogDensityOffset
			CobaltDB.set("environment", "cloudCover", "value", defaultCloudCover)
			cloudCover = defaultCloudCover
			CobaltDB.set("environment", "cloudSpeed", "value", defaultCloudSpeed)
			cloudSpeed = defaultCloudSpeed
			CobaltDB.set("environment", "rainDrops", "value", defaultRainDrops)
			rainDrops = defaultRainDrops
			CobaltDB.set("environment", "dropSize", "value", defaultDropSize)
			dropSize = defaultDropSize
			CobaltDB.set("environment", "dropMinSpeed", "value", defaultDropMinSpeed)
			dropMinSpeed = defaultDropMinSpeed
			CobaltDB.set("environment", "dropMaxSpeed", "value", defaultDropMaxSpeed)
			dropMaxSpeed = defaultDropMaxSpeed
			CobaltDB.set("environment", "precipType", "value", defaultPrecipType)
			precipType = defaultPrecipType
		elseif key == "allSun" then
			CobaltDB.set("environment", "ToD", "value", defaultToD)
			ToD = defaultToD
			CobaltDB.set("environment", "timePlay", "value", defaultTimePlay)
			timePlay = defaultTimePlay
			CobaltDB.set("environment", "dayScale", "value", defaultDayScale)
			dayScale = defaultDayScale
			CobaltDB.set("environment", "nightScale", "value", defaultNightScale)
			nightScale = defaultNightScale
			CobaltDB.set("environment", "azimuthOverride", "value", defaultAzimuthOverride)
			azimuthOverride = defaultAzimuthOverride
			CobaltDB.set("environment", "sunSize", "value", defaultSunSize)
			sunSize = defaultSunSize
			CobaltDB.set("environment", "skyBrightness", "value", defaultSkyBrightness)
			skyBrightness = defaultSkyBrightness
			CobaltDB.set("environment", "sunLightBrightness", "value", defaultSunLightBrightness)
			sunLightBrightness = defaultSunLightBrightness
			CobaltDB.set("environment", "exposure", "value", defaultExposure)
			environment = defaultEnvironment
			CobaltDB.set("environment", "shadowDistance", "value", defaultShadowDistance)
			shadowDistance = defaultShadowDistance
			CobaltDB.set("environment", "shadowSoftness", "value", defaultShadowSoftness)
			shadowSoftness = defaultShadowSoftness
			CobaltDB.set("environment", "shadowSplits", "value", defaultShadowSplits)
			shadowSplits = defaultShadowSplits
		elseif key == "all" then
			CobaltDB.set("environment", "ToD", "value", defaultToD)
			ToD = defaultToD
			CobaltDB.set("environment", "timePlay", "value", defaultTimePlay)
			timePlay = defaultTimePlay
			CobaltDB.set("environment", "dayScale", "value", defaultDayScale)
			dayScale = defaultDayScale
			CobaltDB.set("environment", "nightScale", "value", defaultNightScale)
			nightScale = defaultNightScale
			CobaltDB.set("environment", "azimuthOverride", "value", defaultAzimuthOverride)
			azimuthOverride = defaultAzimuthOverride
			CobaltDB.set("environment", "sunSize", "value", defaultSunSize)
			sunSize = defaultSunSize
			CobaltDB.set("environment", "skyBrightness", "value", defaultSkyBrightness)
			skyBrightness = defaultSkyBrightness
			CobaltDB.set("environment", "sunLightBrightness", "value", defaultSunLightBrightness)
			sunLightBrightness = defaultSunLightBrightness
			CobaltDB.set("environment", "exposure", "value", defaultExposure)
			environment = defaultEnvironment
			CobaltDB.set("environment", "shadowDistance", "value", defaultShadowDistance)
			shadowDistance = defaultShadowDistance
			CobaltDB.set("environment", "shadowSoftness", "value", defaultShadowSoftness)
			shadowSoftness = defaultShadowSoftness
			CobaltDB.set("environment", "shadowSplits", "value", defaultShadowSplits)
			shadowSplits = defaultShadowSplits
			CobaltDB.set("environment", "fogDensity", "value", defaultFogDensity)
			fogDensity = defaultFogDensity
			CobaltDB.set("environment", "fogDensityOffset", "value", defaultFogDensityOffset)
			fogDensityOffset = defaultFogDensityOffset
			CobaltDB.set("environment", "cloudCover", "value", defaultCloudCover)
			cloudCover = defaultCloudCover
			CobaltDB.set("environment", "cloudSpeed", "value", defaultCloudSpeed)
			cloudSpeed = defaultCloudSpeed
			CobaltDB.set("environment", "rainDrops", "value", defaultRainDrops)
			rainDrops = defaultRainDrops
			CobaltDB.set("environment", "dropSize", "value", defaultDropSize)
			dropSize = defaultDropSize
			CobaltDB.set("environment", "dropMinSpeed", "value", defaultDropMinSpeed)
			dropMinSpeed = defaultDropMinSpeed
			CobaltDB.set("environment", "dropMaxSpeed", "value", defaultDropMaxSpeed)
			dropMaxSpeed = defaultDropMaxSpeed
			CobaltDB.set("environment", "precipType", "value", defaultPrecipType)
			precipType = defaultPrecipType
		
		elseif key == "ToD" then
			if value == "default" then
				ToD = defaultToD
				value = defaultToD
				CobaltDB.set("environment", "ToD", "value", defaultToD)
			else
				ToD = tonumber(value)
				CobaltDB.set("environment", "ToD", "value", ToD)
			end
		elseif key == "timePlay" then
			timePlay = value
		elseif key == "dayScale" then
			if value == "default" then
				dayScale = defaultDayScale
				value = defaultDayScale
				CobaltDB.set("environment", "dayScale", "value", defaultDayScale)
			else
				dayScale = tonumber(value)
				CobaltDB.set("environment", "dayScale", "value", dayScale)
			end
		elseif key == "nightScale" then
			if value == "default" then
				nightScale = defaultNightScale
				value = defaultNightScale
				CobaltDB.set("environment", "nightScale", "value", defaultNightScale)
			else
				nightScale = tonumber(value)
				CobaltDB.set("environment", "nightScale", "value", nightScale)
			end
		elseif key == "azimuthOverride" then
			if value == "default" then
				azimuthOverride = defaultAzimuthOverride
				value = defaultAzimuthOverride
				CobaltDB.set("environment", "azimuthOverride", "value", defaultAzimuthOverride)
			else
				azimuthOverride = tonumber(value)
				CobaltDB.set("environment", "azimuthOverride", "value", azimuthOverride)
			end
		elseif key == "sunSize" then
			if value == "default" then
				sunSize = defaultSunSize
				value = defaultSunSize
				CobaltDB.set("environment", "sunSize", "value", defaultSunSize)
			else
				sunSize = tonumber(value)
				CobaltDB.set("environment", "sunSize", "value", sunSize)
			end
		elseif key == "skyBrightness" then
			if value == "default" then
				skyBrightness = defaultSkyBrightness
				value = defaultSkyBrightness
				CobaltDB.set("environment", "skyBrightness", "value", defaultSkyBrightness)
			else
				skyBrightness = tonumber(value)
				CobaltDB.set("environment", "skyBrightness", "value", skyBrightness)
			end
		elseif key == "sunLightBrightness" then
			if value == "default" then
				sunLightBrightness = defaultSunLightBrightness
				value = defaultSunLightBrightness
				CobaltDB.set("environment", "sunLightBrightness", "value", defaultSunLightBrightness)
			else
				sunLightBrightness = tonumber(value)
				CobaltDB.set("environment", "sunLightBrightness", "value", sunLightBrightness)
			end
		elseif key == "exposure" then
			if value == "default" then
				exposure = defaultExposure
				value = defaultExposure
				CobaltDB.set("environment", "exposure", "value", defaultExposure)
			else
				exposure = tonumber(value)
				CobaltDB.set("environment", "exposure", "value", exposure)
			end
		elseif key == "shadowDistance" then
			if value == "default" then
				shadowDistance = defaultShadowDistance
				value = defaultShadowDistance
				CobaltDB.set("environment", "shadowDistance", "value", defaultShadowDistance)
			else
				shadowDistance = tonumber(value)
				CobaltDB.set("environment", "shadowDistance", "value", shadowDistance)
			end
		elseif key == "shadowSoftness" then
			if value == "default" then
				shadowSoftness = defaultShadowSoftness
				value = defaultShadowSoftness
				CobaltDB.set("environment", "shadowSoftness", "value", defaultShadowSoftness)
			else
				shadowSoftness = tonumber(value)
				CobaltDB.set("environment", "shadowSoftness", "value", shadowSoftness)
			end
		elseif key == "shadowSplits" then
			if value == "default" then
				shadowSplits = defaultShadowSplits
				value = defaultShadowSplits
				CobaltDB.set("environment", "shadowSplits", "value", defaultShadowSplits)
			else
				shadowSplits = tonumber(value)
				CobaltDB.set("environment", "shadowSplits", "value", shadowSplits)
			end
		elseif key == "fogDensity" then
			if value == "default" then
				fogDensity = defaultFogDensity
				value = defaultFogDensity
				CobaltDB.set("environment", "fogDensity", "value", defaultFogDensity)
			else
				fogDensity = tonumber(value)
				CobaltDB.set("environment", "fogDensity", "value", fogDensity)
			end
		elseif key == "fogDensityOffset" then
			if value == "default" then
				fogDensityOffset = defaultFogDensityOffset
				value = defaultFogDensityOffset
				CobaltDB.set("environment", "fogDensityOffset", "value", defaultFogDensityOffset)
			else
				fogDensityOffset = tonumber(value)
				CobaltDB.set("environment", "fogDensityOffset", "value", fogDensityOffset)
			end
		elseif key == "cloudCover" then
			if value == "default" then
				cloudCover = defaultCloudCover
				value = defaultCloudCover
				CobaltDB.set("environment", "cloudCover", "value", defaultCloudCover)
			else
				cloudCover = tonumber(value)
				CobaltDB.set("environment", "cloudCover", "value", cloudCover)
			end
		elseif key == "cloudSpeed" then
			if value == "default" then
				cloudSpeed = defaultCloudSpeed
				value = defaultCloudSpeed
				CobaltDB.set("environment", "cloudSpeed", "value", defaultCloudSpeed)
			else
				cloudSpeed = tonumber(value)
				CobaltDB.set("environment", "cloudSpeed", "value", cloudSpeed)
			end
		elseif key == "rainDrops" then
			if value == "default" then
				rainDrops = defaultRainDrops
				value = defaultRainDrops
				CobaltDB.set("environment", "rainDrops", "value", defaultRainDrops)
			else
				rainDrops = tonumber(value)
				CobaltDB.set("environment", "rainDrops", "value", rainDrops)
			end
		elseif key == "dropSize" then
			if value == "default" then
				dropSize = defaultDayScale
				value = defaultDayScale
				CobaltDB.set("environment", "dropSize", "value", defaultDropSize)
			else
				dropSize = tonumber(value)
				CobaltDB.set("environment", "dropSize", "value", dropSize)
			end
		elseif key == "dropMinSpeed" then
			if value == "default" then
				dropMinSpeed = defaultDropMinSpeed
				value = defaultDropMinSpeed
				CobaltDB.set("environment", "dropMinSpeed", "value", defaultDropMinSpeed)
			else
				dropMinSpeed = tonumber(value)
				CobaltDB.set("environment", "dropMinSpeed", "value", dropMinSpeed)
			end
		elseif key == "dropMaxSpeed" then
			if value == "default" then
				dropMaxSpeed = defaultDropMaxSpeed
				value = defaultDropMaxSpeed
				CobaltDB.set("environment", "dropMaxSpeed", "value", defaultDropMaxSpeed)
			else
				dropMaxSpeed = tonumber(value)
				CobaltDB.set("environment", "dropMaxSpeed", "value", dropMaxSpeed)
			end
		elseif key == "precipType" then
			precipType = value
		elseif key == "teleportTimeout" then
			if value == "default" then
				teleportTimeout = defaultTeleportTimeout
				value = defaultTeleportTimeout
				CobaltDB.set("environment", "teleportTimeout", "value", defaultTeleportTimeout)
			else
				teleportTimeout = tonumber(value)
				CobaltDB.set("environment", "teleportTimeout", "value", teleportTimeout)
			end
		elseif key == "simSpeed" then
			if value == "default" then
				simSpeed = defaultSimSpeed
				value = defaultSimSpeed
				CobaltDB.set("environment", "simSpeed", "value", simSpeed)
			else
				simSpeed = tonumber(value)
				CobaltDB.set("environment", "simSpeed", "value", simSpeed)
			end
		elseif key == "gravity" then
			if value == "default" then
				gravity = defaultGravity
				value = defaultGravity
				CobaltDB.set("environment", "gravity", "value", gravity)
			else
				gravity = tonumber(value)
				CobaltDB.set("environment", "gravity", "value", gravity)
			end
		end
	end
end

function CEIToggleIgnition(senderID, data)
	CElog("CEIToggleIgnition Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect that player!")
		else
			MP.TriggerClientEvent(-1, "CEIToggleIgnition", tempData[1] .. "|" .. tempData[2] .. "|" .. tempData[3])
		end
	end
end

function CEIToggleLock(senderID, data)
	CElog("CEIToggleLock Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect that player!")
		else		
			MP.TriggerClientEvent(-1, "CEIToggleLock", tempData[1] .. "|" .. tempData[2] .. "|" .. tempData[3])
		end
	end
end

function CEISetCurVeh(senderID, data)
	CElog("CEISetCurVeh Called by: " .. senderID .. ": " .. data, "CEI")
	MP.TriggerClientEvent(-1, "CEISetCurVeh", senderID .. "|" .. data)
	tempPCV[players[senderID].name] = data
end

function CEIStop(senderID, data)
	CElog("CEIStop Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		MP.SendChatMessage(-1, "Good-bye!")
		exit()
	end
end

function CEISetNewGroup(senderID, data)
	CElog("CEISetNewGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local group = data
		local newGroup = "group:" .. group
		local applyGroup = { [newGroup] = { level = 1 } }
		applyStuff(players.database, applyGroup)
	end
end

function CEIRemoveGroup(senderID, data)
	CElog("CEIRemoveGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local group = data
		local removeGroup = "group:" .. group
		loadedDatabases["playerPermissions"] = {}
		for k,v in pairs(players.database) do
			if k == removeGroup then
			else
				loadedDatabases["playerPermissions"][k] = v
			end
		end
		updateDatabase("playerPermissions")
		playerPermissions = CobaltDB.new("playerPermissions")
	end
end

function CEISetNewVehiclePermsLevel(senderID, data)
	CElog("CEISetNewVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local targetLevel = data
		if CobaltDB.query("permissions", "vehicleCap", targetLevel) then
			return
		else
			CobaltDB.set("permissions", "vehicleCap", targetLevel, 1)
		end
	end
end

function CEIRemoveVehiclePermsLevel(senderID, data)
	CElog("CEIRemoveVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local targetLevel = data
		if CobaltDB.query("permissions", "vehicleCap", targetLevel) then
			CobaltDB.set("permissions", "vehicleCap", targetLevel, nil)
		else
			return
		end
	end
end

function CEISetVehiclePerms(senderID, data)
	CElog("CEISetVehiclePerms Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local targetLevel = tempData[1]
		local targetVehicles = tonumber(tempData[2])
		CobaltDB.set("permissions", "vehicleCap", targetLevel, targetVehicles)
	end
end

function CEISetGroup(senderID, data)
	CElog("CEISetGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local name
		if tonumber(tempData[1]) then
			local targetID = tonumber(tempData[1])
			name = players[targetID].name
		else
			name = tempData[1]
		end
		local group = tempData[2]
		local player = players.getPlayerByName(name)
		local theGroupName = CobaltDB.query("playerPermissions",name,"group")
		if player then
			if group == "none" then
				players.database[name].group = nil
			elseif players.database["group:".. group]:exists() then
				if players[senderID].permissions.level >= (players.database["group:".. group].level or 0) then
					players.database[name].group = group
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. group .. " because it exceeds your own!")
				end
			end
		else
			if group == "none" then
				players.database[name].group = nil
			elseif players.database["group:".. group]:exists() then
				if players[senderID].permissions.level >= (players.database["group:".. group].level or 0) then
					players.database[name].group = group
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. group .. " because it exceeds your own!")
				end
			end
		end
	end
end

function CEISetGroupPerms(senderID, data)
	CElog("CEISetGroupPerms Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local group = tempData[1]
		local key = tempData[2]
		local value = tempData[3]
		if tonumber(value) then
			if tonumber(value) >= 0 then
				players.database["group:"..group][key] = tonumber(value)
			elseif tonumber(value) < 0 then
				return
			end
		elseif value == "true" then
			players.database["group:"..group][key] =  true
		elseif value == "false" then
			players.database["group:"..group][key] =  false
		elseif value == "none" then
			players.database["group:"..group][key] =  nil
		elseif value == nil then
			return
		else
			players.database["group:"..group][key] =  value
		end
	end
end

function CEISetPerm(senderID, data)
	CElog("CEISetPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local targetID = tonumber(tempData[1])
		local name = players[targetID].name
		local permLvl = tonumber(tempData[2])
		if players[senderID].permissions.level <= permLvl then
			MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s level to " .. permLvl .. " because it exceeds your own!")
		else
			CC.setperm(players[senderID], name, permLvl)
			tempPlayers[name].tempPermLevel = players[targetID].permissions.level
		end
	end
end

function CEISetTempPerm(senderID, data)
	CElog("CEISetTempPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local targetID = tonumber(tempData[1])
		local name = players[targetID].name
		local permLvl = tonumber(tempData[2])
		tempPlayers[name].tempPermLevel = permLvl
	end
end

function CEISetCfg(senderID, data)
	CElog("CEISetCfg Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local key = tempData[1]
		local value = tempData[2]
		if tonumber(value) then
			value = tonumber(value)
		end
		if key == "Debug" then
			if value == "true" then
				MP.Set(0, true)
				serverConfig.debug = "true"
				writeCfg("ServerConfig.toml", key, true)
			elseif value == "false" then
				MP.Set(0, false)
				serverConfig.debug = "false"
				writeCfg("ServerConfig.toml", key, false)
			end
		elseif key == "Private" then
			if value == "true" then 
				MP.Set(1, true)
				serverConfig.private = "true"
				writeCfg("ServerConfig.toml", key, true)
			elseif value == "false" then
				MP.Set(1, false)
				serverConfig.private = "false"
				writeCfg("ServerConfig.toml", key, false)
			end
		elseif key == "MaxCars" then
			if value < 0 then
				return
			end
			MP.Set(2, value)
			serverConfig.maxCars = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "MaxPlayers" then
			if value < 0 then
				return
			end
			MP.Set(3, value)
			serverConfig.maxPlayers = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Map" then
			if value == nil then
				return
			end
			MP.Set(4, value)
			serverConfig.map = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Name" then
			if value == nil then
				return
			end
			MP.Set(5, value)
			serverConfig.name = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Description" then
			if value == nil then
				return
			end
			MP.Set(6, value)
			serverConfig.description = value
			writeCfg("ServerConfig.toml", key, value)
		else
			return nil
		end
	end
end

function CEISetMaxActivePlayers(senderID, data)
	CElog("CEISetMaxActivePlayers Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = tonumber(data)
		CobaltDB.set("config", "maxActivePlayers", "value", data)
	end
end

function CEIRemoveVehicle(senderID, data)
	CElog("CEIRemoveVehicle Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local tempPlayerID = tonumber(tempData[1])
		local tempVehicleID = tonumber(tempData[2])
		local reason = tempData[3] or "No reason specified"
		MP.RemoveVehicle(tempPlayerID, tempVehicleID)
		MP.SendChatMessage(tempPlayerID, "Your vehicle was deleted for: " .. reason)
	end
end

function CEIKick(senderID, data)
	CElog("CEIKick Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.kick(players[senderID], targetName, reason)
	end
end

function CEIBan(senderID, data)
	CElog("CEIBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.ban(players[senderID], targetName, reason)
	end
end

function CEITempBan(senderID, data)
	CElog("CEIBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local length = tempData[2]
		local reason = tempData[3] or "No reason specified"
		local targetName = players[playerID].name
		CobaltDB.set("playersDB/" .. targetName, "tempBan", "value", length*86400 + os.time())
		CC.kick(players[senderID], targetName, "tempBan for: " .. reason .. " for " .. length .. " days.")
	end
end

function CEIMute(senderID, data)
	CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.mute(players[senderID], targetName, reason)
	end
end

function CEIUnmute(senderID, data)
	CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = tonumber(data)
		local targetName = players[data].name
		CC.unmute(players[senderID], targetName)
	end
end

function CEIWhitelist(senderID, data)
	CElog("CEIWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local arguments
		local tempPlayerID
		local targetName
		local action = tempData[1]
		if tempData[2] then
			if tonumber(tempData[2]) then
				tempPlayerID = tonumber(tempData[2])
				targetName = players[tempPlayerID].name
			else
				targetName = tempData[2]
			end
			arguments = action .. " " .. targetName
		else
			arguments = action
		end
		CC.whitelist(players[senderID], arguments)
	end
end

function CEIConfig(senderID, data)
	CElog("CEIConfig Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local key = tempData[1]
		local value = tempData[2]
		if value == "enable" then
			CobaltDB.set("config", key, "value", true)
		elseif value == "disable" then
			CobaltDB.set("config", key, "value", false)
		else
			CobaltDB.set("config", key, "value", value)
		end
		loadedDatabases["config"] = {}
		for k,v in pairs(config) do
			loadedDatabases["config"][k] = v
		end
		applyStuff(config,loadedDatabases["config"])
		updateDatabase("config")
		config = CobaltDB.new("config")
		MP.TriggerLocalEvent("onCobaltDBhandshake",CobaltDBport)
	elseif players[senderID].permissions.group == "mod" then
		MP.SendChatMessage(senderID, "You cannot edit this Admin-level setting!")
	end
end

local function onTick(age)
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if MP.IsPlayerConnected(player.playerID) then
				if player.permissions.group == "owner"  or player.permissions.group == "admin" or player.permissions.group == "mod" then
					txPlayersData(player)
					txConfigData(player)
					txStats(player)
					txPlayersRoles(player)
					txEnvironment(player)
				else
					txPlayersData(player)
					txPlayersRoles(player)
					txEnvironment(player)
				end
			end
		end
	end
	if raceCountdown ~= nil then
		if raceCountdown == 15 then
			MP.TriggerClientEvent(-1, "CEIRaceCountSound", "3ping")
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "You have been locked in place, prepare to start!|5")
			MP.SendChatMessage(-1, "🚦 You have been locked in place, prepare to start! 🚦")
		elseif raceCountdown == 11 then
			MP.TriggerClientEvent(-1, "CEIRaceCountSound", "countTenHorn")
		elseif raceCountdown == 10 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "10...|1|true")
			MP.SendChatMessage(-1, "🟥🔟🟥")
		elseif raceCountdown == 9 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "9...|1|true")
			MP.SendChatMessage(-1, "🟥9️⃣🟥")
		elseif raceCountdown == 8 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "8...|1|true")
			MP.SendChatMessage(-1, "🟥8️⃣🟥")
		elseif raceCountdown == 7 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "7...|1|true")
			MP.SendChatMessage(-1, "🟥7️⃣🟥")
		elseif raceCountdown == 6 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "6...|1|true")
			MP.SendChatMessage(-1, "🟥6️⃣🟥")
		elseif raceCountdown == 5 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "5...|1|true")
			MP.SendChatMessage(-1, "🟥5️⃣🟥")
		elseif raceCountdown == 4 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "4...|1|true")
			MP.SendChatMessage(-1, "🟥4️⃣🟥")
		elseif raceCountdown == 3 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "3...|1|true")
			MP.SendChatMessage(-1, "🟨3️⃣🟨")
		elseif raceCountdown == 2 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "2...|1|true")
			MP.SendChatMessage(-1, "🟨2️⃣🟨")
		elseif raceCountdown == 1 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "1...|1|true")
			MP.SendChatMessage(-1, "🟨1️⃣🟨")
		elseif raceCountdown == 0 then
			MP.TriggerClientEvent(-1, "CEIRaceCountdown", "❇️GO!!!❇️|3|true")
			MP.TriggerClientEvent(-1, "CEIRaceStart", "true")
			MP.SendChatMessage(-1, "🟩🟩🟩")
			MP.SendChatMessage(-1, "🟩❇️🟩")
			MP.SendChatMessage(-1, "🟩🟩🟩")
		end
		raceCountdown = raceCountdown - 1
		if raceCountdown == -1 then
			raceCountdown = nil
			raceCountdownStarted = nil
		end
	end
end

function onPlayerAuthHandler(player_name, player_role, is_guest)
	if CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") == nil or CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") == 0 then
	elseif CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") > os.time() then
		return 1
	end
	tempPlayers[player_name] = {}
	tempPlayers[player_name].tempPermLevel = 0
	tempPlayers[player_name].tempBanLength = 1
	tempPCV[player_name] = "none"
end

local function onPlayerJoining(player)
	tempPlayers[player.name].tempPermLevel = player.permissions.level
end

local function onPlayerJoin(player)
	local state
	if CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == nil then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", true)
		showCEI[player.name] = true
		state = "show"
	elseif CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == true then
		showCEI[player.name] = true
		state = "show"
	elseif CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == false then
		showCEI[player.name] = false
		state = "hide"
	end
	MP.TriggerClientEvent(player.playerID, "rxCEIstate", state)
	CE.delayExec( 2000 , MP.SendChatMessage , { player.playerID , "This server uses Cobalt Essentials Interface." } )
	CE.delayExec( 2500 , MP.SendChatMessage , { player.playerID , "Use /CEI in chat to toggle." } )
end

local function onPlayerDisconnect(player)
	local data = tostring(player.playerID)
	MP.TriggerClientEvent(-1,"rxPlayerLeave",data)
	tempPlayers[player.name] = nil
	tempPCV[player.name] = nil
end

local function onVehicleSpawn(player, vehID,  data)
	tempPCV[player.name] = player.playerID .. "-" .. vehID
end

local function split(s, sep)
	local fields = {}
	local sep = sep or " "
	local pattern = string.format("([^%s]+)", sep)
	string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
	return fields
end

local function updateDatabase(DBname)
	local filePath = dbpath .. DBname
	local success, error = utils.writeJson(filePath..".temp", loadedDatabases[DBname])
	if success then
		success, error = FS.Remove(filePath .. ".json")
		if success then
			success, error = FS.Rename(filePath .. ".temp", filePath .. ".json")
		end
	end
	if not success then
		CElog('Failed to update database "'..DBname..'"on disk: '..tostring(error), "WARN")
	end
end

function writeCfg(path, key, value)
	local tomlFile, error = io.open(path, 'r')
	if error then return nil, error end
	local tomlText = tomlFile:read("*a")
	local cfg = tomlParser.parse(tomlText)
	if cfg.General then
		cfg.General[key] = value
		tomlText = tomlParser.encode(cfg)
		tomlText = tomlText:gsub( '\\', '')
		tomlFile, error = io.open(path, 'w')
		if error then return nil, error end
		tomlFile:write(tomlText)
	end
	tomlFile:close()
end

M.applyStuff = applyStuff

M.onInit = onInit
M.onTick = onTick
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect
M.onVehicleSpawn = onVehicleSpawn
M.CEI = CEI

return M
