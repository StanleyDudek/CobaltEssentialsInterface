--CEI (SERVER) by Dudekahedron, 2022

local M = {}

M.COBALT_VERSION = "1.6.0"

utils.setLogType("CEI",93)

local CobaltDBport = 58933

local tomlParser = require("toml")

local loadedDatabases = {}

local showCEI = {}
local teleport = {}

local tempPlayers = {}
local tempPCV = {}

local serverConfig = {}
local cobaltConfig = {}
cobaltConfig.whitelistedPlayers = {}
cobaltConfig.groups = {}
cobaltConfig.permissions = {}
cobaltConfig.permissions.vehicleCap = {}
cobaltConfig.permissions.vehiclePerm = {}
local nametagsConfig = {}
nametagsConfig.whitelist = {}
nametagsConfig.settings = {}

local defaultInterfaceState = false

local defaultNametagsBlockingEnabled = "false"
local defaultNametagsBlockingTimeout = 300
local defaultNametagsBlockingWhitelist = "exampleName"

local environmentLogTimer = 0
local environmentLogInterval = 60

local environmentTable = {}
environmentTable.defaultToD = 0.1
environmentTable.defaultTimePlay = "false"
environmentTable.defaultDayScale = 1
environmentTable.defaultNightScale = 2
environmentTable.defaultAzimuthOverride = 0
environmentTable.defaultSunSize = 1
environmentTable.defaultSkyBrightness = 40
environmentTable.defaultSunLightBrightness = 1
environmentTable.defaultExposure = 1
environmentTable.defaultShadowDistance = 1600
environmentTable.defaultShadowSoftness = 0.2
environmentTable.defaultShadowSplits = 4
environmentTable.defaultFogDensity = 0.0001
environmentTable.defaultFogDensityOffset = 8
environmentTable.defaultCloudCover = 0.08
environmentTable.defaultCloudSpeed = 0.2
environmentTable.defaultRainDrops = 0
environmentTable.defaultDropSize = 1
environmentTable.defaultDropMinSpeed = 0.1
environmentTable.defaultDropMaxSpeed = 0.2
environmentTable.defaultPrecipType = "rain_medium"
environmentTable.defaultTeleportTimeout = 5
environmentTable.defaultSimSpeed = 1
environmentTable.defaultGravity = -9.81
environmentTable.defaultTempCurveNoon = 38
environmentTable.defaultTempCurveDusk = 12
environmentTable.defaultTempCurveMidnight = -15
environmentTable.defaultTempCurveDawn = 12
environmentTable.defaultUseTempCurve = "false"
environmentTable.ToD = ""
environmentTable.timePlay = ""
environmentTable.dayScale = ""
environmentTable.nightScale = ""
environmentTable.azimuthOverride = ""
environmentTable.sunSize = ""
environmentTable.skyBrightness = ""
environmentTable.sunLightBrightness = ""
environmentTable.exposure = ""
environmentTable.shadowDistance = ""
environmentTable.shadowSoftness = ""
environmentTable.shadowSplits = ""
environmentTable.fogDensity = ""
environmentTable.fogDensityOffset = ""
environmentTable.cloudCover = ""
environmentTable.cloudSpeed = ""
environmentTable.rainDrops = ""
environmentTable.dropSize = ""
environmentTable.dropMinSpeed = ""
environmentTable.dropMaxSpeed = ""
environmentTable.precipType = ""
environmentTable.teleportTimeout = ""
environmentTable.simSpeed = ""
environmentTable.gravity = ""
environmentTable.tempCurveNoon = ""
environmentTable.tempCurveDusk = ""
environmentTable.tempCurveMidnight = ""
environmentTable.tempCurveDawn = ""
environmentTable.useTempCurve = ""

local environment = CobaltDB.new("environment")
local defaultEnvironment = {
	ToD = {value = environmentTable.defaultToD, description = "What is the Time of Day?"},
	timePlay = {value = environmentTable.defaultTimePlay, description = "Does time progress?"},
	dayScale = {value = environmentTable.defaultDayScale, description = "At what rate does daytime progress?"},
	nightScale = {value = environmentTable.defaultNightScale, description = "At what rate does nighttime progress?"},
	azimuthOverride = {value = environmentTable.defaultAzimuthOverride, description = "At what position on the horizon does the sun rise and set?"},
	sunSize = {value = environmentTable.defaultSunSize, description = "How big is the sun?"},
	skyBrightness = {value = environmentTable.defaultSkyBrightness, description = "How bright is the sky?"},
	sunLightBrightness = {value = environmentTable.defaultSunLightBrightness, description = "How bright is the sunlight?"},
	exposure = {value = environmentTable.defaultExposure, description = "How exposed is the environment?"},
	shadowDistance = {value = environmentTable.defaultShadowDistance, description = "How far are the shadows?"},
	shadowSoftness = {value = environmentTable.defaultShadowSoftness, description = "How soft are the shadows?"},
	shadowSplits = {value = environmentTable.defaultShadowSplits, description = "How many splits are there for shadows?"},
	fogDensity = {value = environmentTable.defaultFogDensity, description = "How thicc is the fog?"},
	fogDensityOffset = {value = environmentTable.defaultFogDensityOffset, description = "How far away is the fog?"},
	cloudCover = {value = environmentTable.defaultCloudCover, description = "How thicc are the clouds?"},
	cloudSpeed = {value = environmentTable.defaultCloudSpeed, description = "How fast are the clouds?"},
	rainDrops = {value = environmentTable.defaultRainDrops, description = "How many rain drops are there?"},
	dropSize = {value = environmentTable.defaultDropSize, description = "What size are the drops of precipitation?"},
	dropMinSpeed = {value = environmentTable.defaultDropMinSpeed, description = "What is the minimum speed of precipitation?"},
	dropMaxSpeed = {value = environmentTable.defaultDropMaxSpeed, description = "What is the maximum speed of precipitation?"},
	precipType = {value = environmentTable.defaultPrecipType, description = "What type of precipitation do we use?"},
	teleportTimeout = {value = environmentTable.defaultTeleportTimeout, description = "How long between telports?"},
	simSpeed = {value = environmentTable.defaultSimSpeed, description = "At what rate does the simulation run?"},
	gravity = {value = environmentTable.defaultGravity, description = "At what rate do objects fall towards the ground?"},
	tempCurveNoon = {value = environmentTable.defaultTempCurveNoon, description = "What is the custom temperature in C at noon?"},
	tempCurveDusk = {value = environmentTable.defaultTempCurveDusk, description = "What is the custom temperature in C at dusk?"},
	tempCurveMidnight = {value = environmentTable.defaultTempCurveMidnight, description = "What is the custom temperature in C at midnight?"},
	tempCurveDawn = {value = environmentTable.defaultTempCurveDawn, description = "What is the custom temperature in C at dawn?"},
	useTempCurve = {value = environmentTable.defaultUseTempCurve, description = "Do we use a custom temperature curve?"},
}

local vehicles = CobaltDB.new("vehicles")
local defaultVehicles = {
	autobello = { level = 1 },
	ball = { level = 1 },
	barrels = { level = 1 },
	barrier = { level = 1 },
	barstow = { level = 1 },
	bastion = { level = 1 },
	blockwall = { level = 1 },
	bluebuck = { level = 1 },
	bolide = { level = 1 },
	bollard = { level = 1 },
	boxutility = { level = 1 },
	boxutility_large = { level = 1 },
	burnside = { level = 1 },
	cannon = { level = 1 },
	caravan = { level = 1 },
	cardboard_box = { level = 1 },
	chair = { level = 1 },
	christmas_tree = { level = 1 },
	citybus = { level = 1, ["partlevel:citybus_ramplow"] = 1 },
	cones = { level = 1 },
	couch = { level = 1 },
	coupe = { level = 1 },
	default = { level = 1 },
	dryvan = { level = 1 },
	etk800 = { level = 1 },
	etkc = { level = 1 },
	etki = { level = 1 },
	flail = { level = 1 },
	flatbed = { level = 1 },
	flipramp = { level = 1 },
	fridge = { level = 1 },
	fullsize = { level = 1 },
	gate = { level = 1 },
	hatch = { level = 1 },
	haybale = { level = 1 },
	hopper = { level = 1 },
	inflated_mat = { level = 1 },
	kickplate = { level = 1 },
	large_angletester = { level = 1 },
	large_bridge = { level = 1 },
	large_cannon = { level = 1 },
	large_crusher = { level = 1 },
	large_hamster_wheel = { level = 1 },
	large_roller = { level = 1 },
	large_spinner = { level = 1 },
	large_tilt = { level = 1 },
	legran = { level = 1 },
	mattress = { level = 1 },
	metal_box = { level = 1 },
	metal_ramp = { level = 1 },
	midsize = { level = 1 },
	miramar = { level = 1 },
	moonhawk = { level = 1 },
	pessima = { level = 1 },
	piano = { level = 1 },
	pickup = { level = 1 },
	pigeon = { level = 1 },
	roadsigns = { level = 1 },
	roamer = { level = 1 },
	rocks = { level = 1 },
	rollover = { level = 1 },
	sawhorse = { level = 1 },
	sbr = { level = 1 },
	semi = { level = 1, ["partlevel:semi_ramplow"] = 1},
	shipping_container = { level = 1 },
	streetlight = { level = 1 },
	sunburst = { level = 1 },
	suspensionbridge = { level = 1 },
	tanker = { level = 1 },
	testroller = { level = 1 },
	tirestacks = { level = 1 },
	tirewall = { level = 1 },
	trafficbarrel = { level = 1 },
	tsfb = { level = 1 },
	tube = { level = 1 },
	tv = { level = 1 },
	unicycle = { level = 1 },
	van = { level = 1 },
	vivace = { level = 1 },
	wall = { level = 1 },
	weightpad = { level = 1 },
	wendover = { level = 1 },
	wigeon = { level = 1 },
	woodcrate = { level = 1 },
	woodplanks = { level = 1 }
}

local nametags = CobaltDB.new("nametags")
local defaultNametagsSettings = {
	blockingEnabled = {value = defaultNametagsBlockingEnabled, description = "Are nametags blocked?"},
	blockingTimeout = {value = defaultNametagsBlockingTimeout, description = "For how long are nametags blocked?"},
	nametagsWhitelist = {exampleName = defaultNametagsBlockingWhitelist, description = "Who is immune to nametag blocking?"}
}

local interface = CobaltDB.new("interface")
local defaultInterfaceSettings = {
	defaultCEIState = {value = defaultInterfaceState, description = "The state of the interface for new players."}
}


local raceCountdown
local raceCountdownStarted

local function onInit()
	MP.RegisterEvent("onPlayerAuth", "onPlayerAuthHandler")
	MP.RegisterEvent("CEISetDefaultState","CEISetDefaultState")
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
	MP.RegisterEvent("CEIRemoveVehiclePerm","CEIRemoveVehiclePerm")
	MP.RegisterEvent("CEIRemoveVehiclePart","CEIRemoveVehiclePart")
	MP.RegisterEvent("CEISetNewVehiclePerm","CEISetNewVehiclePerm")
	MP.RegisterEvent("CEISetNewVehiclePart","CEISetNewVehiclePart")
	MP.RegisterEvent("CEISetVehiclePermLevel","CEISetVehiclePermLevel")
	MP.RegisterEvent("CEISetVehiclePartLevel","CEISetVehiclePartLevel")
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
	MP.RegisterEvent("CEISetNametagWhitelist","CEISetNametagWhitelist")
	MP.RegisterEvent("CEIRemoveNametagWhitelist","CEIRemoveNametagWhitelist")
	MP.RegisterEvent("CEINametagSetting","CEINametagSetting")
	MP.RegisterEvent("CEINametagBlockingTimer","CEINametagBlockingTimer")
	MP.RegisterEvent("CEIConfig","CEIConfig")
	MP.RegisterEvent("CEIStop","CEIStop")
	MP.RegisterEvent("CEISetEnv","CEISetEnv")
	MP.RegisterEvent("CEISetTempBan","CEISetTempBan")
	MP.RegisterEvent("CEISetTeleportPerm","CEISetTeleportPerm")
	MP.RegisterEvent("CEITeleportFrom","CEITeleportFrom")
	MP.RegisterEvent("CEIRaceInclude","CEIRaceInclude")
	MP.RegisterEvent("txNametagBlockerTimeout","txNametagBlockerTimeout")
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
	M.applyStuff(vehicles, defaultVehicles)
	M.applyStuff(nametags, defaultNametagsSettings)
	M.applyStuff(interface, defaultInterfaceSettings)
	
	nametagsConfig.settings.blockingEnabled = CobaltDB.query("nametags", "blockingEnabled", "value")
	nametagsConfig.settings.blockingTimeout = CobaltDB.query("nametags", "blockingTimeout", "value")
	
	environmentTable.ToD = CobaltDB.query("environment", "ToD", "value")
	environmentTable.timePlay = CobaltDB.query("environment", "timePlay", "value")
	environmentTable.dayScale = CobaltDB.query("environment", "dayScale", "value")
	environmentTable.nightScale = CobaltDB.query("environment", "nightScale", "value")
	environmentTable.azimuthOverride = CobaltDB.query("environment", "azimuthOverride", "value")
	environmentTable.sunSize = CobaltDB.query("environment", "sunSize", "value")
	environmentTable.skyBrightness = CobaltDB.query("environment", "skyBrightness", "value")
	environmentTable.sunLightBrightness = CobaltDB.query("environment", "sunLightBrightness", "value")
	environmentTable.exposure = CobaltDB.query("environment", "exposure", "value")
	environmentTable.shadowDistance = CobaltDB.query("environment", "shadowDistance", "value")
	environmentTable.shadowSoftness = CobaltDB.query("environment", "shadowSoftness", "value")
	environmentTable.shadowSplits = CobaltDB.query("environment", "shadowSplits", "value")
	environmentTable.fogDensity = CobaltDB.query("environment", "fogDensity", "value")
	environmentTable.fogDensityOffset = CobaltDB.query("environment", "fogDensityOffset", "value")
	environmentTable.cloudCover = CobaltDB.query("environment", "cloudCover", "value")
	environmentTable.cloudSpeed = CobaltDB.query("environment", "cloudSpeed", "value")
	environmentTable.rainDrops = CobaltDB.query("environment", "rainDrops", "value")
	environmentTable.dropSize = CobaltDB.query("environment", "dropSize", "value")
	environmentTable.dropMinSpeed = CobaltDB.query("environment", "dropMinSpeed", "value")
	environmentTable.dropMaxSpeed = CobaltDB.query("environment", "dropMaxSpeed", "value")
	environmentTable.precipType = CobaltDB.query("environment", "precipType", "value")
	environmentTable.teleportTimeout = CobaltDB.query("environment", "teleportTimeout", "value")
	environmentTable.simSpeed = CobaltDB.query("environment", "simSpeed", "value")
	environmentTable.gravity = CobaltDB.query("environment", "gravity", "value")
	environmentTable.tempCurveNoon = CobaltDB.query("environment", "tempCurveNoon", "value")
	environmentTable.tempCurveDusk = CobaltDB.query("environment", "tempCurveDusk", "value")
	environmentTable.tempCurveMidnight = CobaltDB.query("environment", "tempCurveMidnight", "value")
	environmentTable.tempCurveDawn = CobaltDB.query("environment", "tempCurveDawn", "value")
	environmentTable.useTempCurve = CobaltDB.query("environment", "useTempCurve", "value")
	
	defaultInterfaceState = CobaltDB.query("interface", "defaultCEIState", "value")
	
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
		CEI = {orginModule = "CEI", level = 0, arguments = 0, sourceLimited = 1, description = "Toggles Cobalt Essentials Interface"},
		cei = {orginModule = "CEI", level = 0, arguments = 0, sourceLimited = 1, description = "Alias for CEI"}
	}

applyStuff(commands, CEICommands)

local function CEI(player)
	--CElog("CEI Called by: " .. player.name, "CEI")
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

function CEISetDefaultState(senderID, data)
	--CElog("CEISetDefaultState Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		if data == "true" then
			CobaltDB.set("interface", "defaultCEIState", "value", true)
			defaultInterfaceState = true
		elseif data == "false" then
			CobaltDB.set("interface", "defaultCEIState", "value", false)
			defaultInterfaceState = false
		end
	end
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
	data = data .. "|" .. environmentTable.ToD
				.. "$" .. environmentTable.timePlay
				.. "$" .. environmentTable.dayScale
				.. "$" .. environmentTable.nightScale
				.. "$" .. environmentTable.azimuthOverride
				.. "$" .. environmentTable.sunSize
				.. "$" .. environmentTable.skyBrightness
				.. "$" .. environmentTable.sunLightBrightness
				.. "$" .. environmentTable.exposure
				.. "$" .. environmentTable.shadowDistance
				.. "$" .. environmentTable.shadowSoftness
				.. "$" .. environmentTable.shadowSplits
				.. "$" .. environmentTable.fogDensity
				.. "$" .. environmentTable.fogDensityOffset
				.. "$" .. environmentTable.cloudCover
				.. "$" .. environmentTable.cloudSpeed
				.. "$" .. environmentTable.rainDrops
				.. "$" .. environmentTable.dropSize
				.. "$" .. environmentTable.dropMinSpeed
				.. "$" .. environmentTable.dropMaxSpeed
				.. "$" .. environmentTable.precipType
				.. "$" .. environmentTable.teleportTimeout
				.. "$" .. environmentTable.simSpeed
				.. "$" .. environmentTable.gravity
				.. "$" .. environmentTable.tempCurveNoon
				.. "$" .. environmentTable.tempCurveDusk
				.. "$" .. environmentTable.tempCurveMidnight
				.. "$" .. environmentTable.tempCurveDawn
				.. "$" .. environmentTable.useTempCurve
				
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
			local tp
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
			
			if CobaltDB.query("playersDB/" .. playerName, "teleport", "value") == false or CobaltDB.query("playersDB/" .. playerName, "teleport", "value") == nil then
				tp = "false"
			elseif CobaltDB.query("playersDB/" .. playerName, "teleport", "value") == true then
				tp = "true"
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
						.. "," .. tp
						.. "," .. player.permissions.level
						.. "," .. banned
						.. "," .. player.permissions.group
						.. "," .. connectedTime
						.. "," .. muteReason
						.. "," .. tempPlayers[playerName].tempBanLength
						.. "," .. tempPlayers[playerName].tempPermLevel
						.. "," .. tempPlayers[playerName].includeInRace
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
	local vehiclePerms = CobaltDB.getTables("vehicles")
	local vehiclePermsLength = 0
	local vehiclePermsPartLevelsLength = 0
	for k,v in pairsByKeys(vehiclePerms) do
		vehiclePermsLength = vehiclePermsLength + 1
		cobaltConfig.permissions.vehiclePerm[vehiclePermsLength] = {}
		cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].partLevel = {}
		cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].name = v
		local vehiclePerm = CobaltDB.getTable("vehicles",v)
		for i,j in pairsByKeys(vehiclePerm) do
			if i == "level" then
				cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].level = j
			end
			if string.find(i,"partlevel") then
				vehiclePermsPartLevelsLength = vehiclePermsPartLevelsLength + 1
				cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength] = {}
				cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength].name = i
				cobaltConfig.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength].level = j
			end
		end
	end
	for i = 1, vehiclePermsLength do
		data = data .. "|" .. cobaltConfig.permissions.vehiclePerm[i].name
					.. "#" .. cobaltConfig.permissions.vehiclePerm[i].level
		for p = 1, vehiclePermsPartLevelsLength do
			if cobaltConfig.permissions.vehiclePerm[i].partLevel[p] then
				data = data .. "," .. cobaltConfig.permissions.vehiclePerm[i].partLevel[p].name
							.. "@" .. cobaltConfig.permissions.vehiclePerm[i].partLevel[p].level
			end
		end
	end
	if defaultInterfaceState == true then
		data = data .. "$" .. "true"
	elseif defaultInterfaceState == false then
		data = data .. "$" .. "false"
	end
	data = data .. "$" .. nametagsConfig.settings.blockingEnabled
	data = data .. "$" .. nametagsConfig.settings.blockingTimeout
	local nametagWhitelistLength = 0
	for k,v in pairs(nametagsConfig.whitelist) do
		nametagWhitelistLength = nametagWhitelistLength + 1
	end
	data = data .. "$"
	for i = 1, nametagWhitelistLength do
		data = data .. "|" .. nametagsConfig.whitelist[i]
	end
	data = data .. "$"
	for i = 1, whitelistLength do
		data = data .. "|" .. cobaltConfig.whitelistedPlayers[i].name
	end
	MP.TriggerClientEvent(player.playerID,"rxConfigData",data)
end

function txNametagWhitelisted(player)
	local isWhitelisted
	if CobaltDB.query("nametags","nametagsWhitelist",player.name) then
		nametagsConfig.whitelist[player.name] = CobaltDB.query("nametags","nametagsWhitelist",player.name)
		isWhitelisted = "true"
	else
		isWhitelisted = "false"
	end
	local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
	local nametagWhitelistIterator = 0
	nametagsConfig.whitelist = {}
	for k,v in pairs(nametagsBlockingWhitelist) do
		if k ~= "description" then
			nametagWhitelistIterator = nametagWhitelistIterator + 1
			nametagsConfig.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
		end
	end
	MP.TriggerClientEvent(player.playerID,"rxNametagWhitelisted",isWhitelisted)
end

function txNametagBlockerActive(player)
	MP.TriggerClientEvent(player.playerID,"rxNametagBlockerActive",CobaltDB.query("nametags","blockingEnabled","value"))
end

function txNametagBlockerTimeout(player_id, data)
	MP.TriggerClientEvent(-1,"rxNametagBlockerTimeout",data)
end

function CEIPreRace(senderID, data)
	--CElog("CEIStartRace Called by: " .. senderID .. ": " .. data, "CEI")
	if not raceCountdownStarted then
		raceCountdownStarted = true
		raceCountdown = 15
	end
end

function CEISetNewVehiclePerm(senderID, data)
	--CElog("CEISetNewVehiclePerm Called by: " .. senderID .. ": " .. data, "CEI")
	local vehicleName = data
	local vehiclePermLevel = 1
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("vehicles", vehicleName, "level", vehiclePermLevel)
	end
end

function CEISetVehiclePermLevel(senderID, data)
	--CElog("CEISetVehiclePermLevel Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local vehicleName = tempData[1]
	local vehiclePermLevel = tonumber(tempData[2])
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("vehicles", vehicleName, "level", vehiclePermLevel)
	end
end

function CEIRemoveVehiclePerm(senderID, data)
	--CElog("CEIRemoveVehiclePerm Called by: " .. senderID .. ": " .. data, "CEI")
	local vehicleName = data
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local removeVehicle = vehicleName
		loadedDatabases["vehicles"] = {}
		local currentVehiclesList = CobaltDB.getTables("vehicles")
		for k,v in pairs(currentVehiclesList) do
			if k == removeVehicle then
			else
				local vehiclePerms = CobaltDB.getTable("vehicles",v)
				loadedDatabases["vehicles"][k] = vehiclePerms
			end
		end
		M.updateCobaltDatabase("vehicles")
		vehicles = CobaltDB.new("vehicles")
	end
end

function CEISetNewVehiclePart(senderID, data)
	--CElog("CEISetNewVehiclePartname Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local vehicleName = tempData[1]
	local partName = "partlevel:" .. tempData[2]
	local partLevel = 1
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("vehicles", vehicleName, partName, partLevel)
	end
end

function CEISetVehiclePartLevel(senderID, data)
	--CElog("CEISetVehiclePartnameLevel Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local vehicleName = tempData[1]
	local partLevel = tonumber(tempData[2])
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("vehicles", vehicleName, partName, partLevel)
	end
end

function CEIRemoveVehiclePart(senderID, data)
	--CElog("CEIRemoveVehiclePart Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local vehicleName = tempData[1]
	local partName = "partlevel:" .. tempData[2]
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then

		local targetLevel = data
		if CobaltDB.query("vehicles", vehicleName, partName) then
			CobaltDB.set("vehicles", vehicleName, partName, nil)
		else
			return
		end
	end
end

function CEISetVehiclePartLevel(senderID, data)
	--CElog("CEISetVehiclePartLevel Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	local vehicleName = tempData[1]
	local vehiclePartName = "partlevel:" .. tempData[2]
	local vehiclePartLevel = tonumber(tempData[3])
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("vehicles", vehicleName, vehiclePartName, vehiclePartLevel)
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

function logEnvironment()
	local environmentTables = CobaltDB.getTables("environment")
	for k,v in pairs(environmentTables) do
		local currentEnvironmentTable = CobaltDB.getTable("environment",v)
		for x,y in pairs(currentEnvironmentTable) do
			if x == "value" then
				if environmentTable[k] ~= y then
					CobaltDB.set("environment", k, "value", environmentTable[k])
				end
			end
		end
	end
end

function CEISetEnv(senderID, data)
	--CElog("CEISetEnv Called by: " .. senderID .. ": " .. data, "CEI")
	local tempData = split(data,"|")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local key = tempData[1]
		local value = tempData[2]
		if key == "allWeather" then
			environmentTable.fogDensity = environmentTable.defaultFogDensity
			environmentTable.fogDensityOffset = environmentTable.defaultFogDensityOffset
			environmentTable.cloudCover = environmentTable.defaultCloudCover
			environmentTable.cloudSpeed = environmentTable.defaultCloudSpeed
			environmentTable.rainDrops = environmentTable.defaultRainDrops
			environmentTable.dropSize = environmentTable.defaultDropSize
			environmentTable.dropMinSpeed = environmentTable.defaultDropMinSpeed
			environmentTable.dropMaxSpeed = environmentTable.defaultDropMaxSpeed
			environmentTable.precipType = environmentTable.defaultPrecipType
		elseif key == "allSun" then
			environmentTable.ToD = environmentTable.defaultToD
			environmentTable.timePlay = environmentTable.defaultTimePlay
			environmentTable.dayScale = environmentTable.defaultDayScale
			environmentTable.nightScale = environmentTable.defaultNightScale
			environmentTable.azimuthOverride = environmentTable.defaultAzimuthOverride
			environmentTable.sunSize = environmentTable.defaultSunSize
			environmentTable.skyBrightness = environmentTable.defaultSkyBrightness
			environmentTable.sunLightBrightness = environmentTable.defaultSunLightBrightness
			environmentTable.environment = environmentTable.defaultEnvironment
			environmentTable.shadowDistance = environmentTable.defaultShadowDistance
			environmentTable.shadowSoftness = environmentTable.defaultShadowSoftness
			environmentTable.shadowSplits = environmentTable.defaultShadowSplits
		elseif key == "all" then
			environmentTable.ToD = environmentTable.defaultToD
			environmentTable.timePlay = environmentTable.defaultTimePlay
			environmentTable.dayScale = environmentTable.defaultDayScale
			environmentTable.nightScale = environmentTable.defaultNightScale
			environmentTable.azimuthOverride = environmentTable.defaultAzimuthOverride
			environmentTable.sunSize = environmentTable.defaultSunSize
			environmentTable.skyBrightness = environmentTable.defaultSkyBrightness
			environmentTable.sunLightBrightness = environmentTable.defaultSunLightBrightness
			environmentTable.environment = environmentTable.defaultEnvironment
			environmentTable.shadowDistance = environmentTable.defaultShadowDistance
			environmentTable.shadowSoftness = environmentTable.defaultShadowSoftness
			environmentTable.shadowSplits = environmentTable.defaultShadowSplits
			environmentTable.fogDensity = environmentTable.defaultFogDensity
			environmentTable.fogDensityOffset = environmentTable.defaultFogDensityOffset
			environmentTable.cloudCover = environmentTable.defaultCloudCover
			environmentTable.cloudSpeed = environmentTable.defaultCloudSpeed
			environmentTable.rainDrops = environmentTable.defaultRainDrops
			environmentTable.dropSize = environmentTable.defaultDropSize
			environmentTable.dropMinSpeed = environmentTable.defaultDropMinSpeed
			environmentTable.dropMaxSpeed = environmentTable.defaultDropMaxSpeed
			environmentTable.precipType = environmentTable.defaultPrecipType
			environmentTable.teleportTimeout = environmentTable.defaultTeleportTimeout
			environmentTable.simSpeed = environmentTable.defaultSimSpeed
			environmentTable.gravity = environmentTable.defaultGravity
			environmentTable.tempCurveNoon = environmentTable.defaultTempCurveNoon
			environmentTable.tempCurveDusk = environmentTable.defaultTempCurveDusk
			environmentTable.tempCurveMidnight = environmentTable.defaultTempCurveMidnight
			environmentTable.tempCurveDawn = environmentTable.defaultTempCurveDawn
			environmentTable.useTempCurve = environmentTable.defaultUseTempCurve
			
		elseif key == "ToD" then
			if value == "default" then
				environmentTable.ToD = environmentTable.defaultToD
			else
				environmentTable.ToD = tonumber(value)
			end
		elseif key == "timePlay" then
			environmentTable.timePlay = value
		elseif key == "dayScale" then
			if value == "default" then
				environmentTable.dayScale = environmentTable.defaultDayScale
			else
				environmentTable.dayScale = tonumber(value)
			end
		elseif key == "nightScale" then
			if value == "default" then
				environmentTable.nightScale = environmentTable.defaultNightScale
			else
				environmentTable.nightScale = tonumber(value)
			end
		elseif key == "azimuthOverride" then
			if value == "default" then
				environmentTable.azimuthOverride = environmentTable.defaultAzimuthOverride
			else
				environmentTable.azimuthOverride = tonumber(value)
			end
		elseif key == "sunSize" then
			if value == "default" then
				environmentTable.sunSize = environmentTable.defaultSunSize
			else
				environmentTable.sunSize = tonumber(value)
			end
		elseif key == "skyBrightness" then
			if value == "default" then
				environmentTable.skyBrightness = environmentTable.defaultSkyBrightness
			else
				environmentTable.skyBrightness = tonumber(value)
			end
		elseif key == "sunLightBrightness" then
			if value == "default" then
				environmentTable.sunLightBrightness = environmentTable.defaultSunLightBrightness
			else
				environmentTable.sunLightBrightness = tonumber(value)
			end
		elseif key == "exposure" then
			if value == "default" then
				environmentTable.exposure = environmentTable.defaultExposure
			else
				environmentTable.exposure = tonumber(value)
			end
		elseif key == "shadowDistance" then
			if value == "default" then
				environmentTable.shadowDistance = environmentTable.defaultShadowDistance
			else
				environmentTable.shadowDistance = tonumber(value)
			end
		elseif key == "shadowSoftness" then
			if value == "default" then
				environmentTable.shadowSoftness = environmentTable.defaultShadowSoftness
			else
				environmentTable.shadowSoftness = tonumber(value)
			end
		elseif key == "shadowSplits" then
			if value == "default" then
				environmentTable.shadowSplits = environmentTable.defaultShadowSplits
			else
				environmentTable.shadowSplits = tonumber(value)
			end
		elseif key == "fogDensity" then
			if value == "default" then
				environmentTable.fogDensity = environmentTable.defaultFogDensity
			else
				environmentTable.fogDensity = tonumber(value)
			end
		elseif key == "fogDensityOffset" then
			if value == "default" then
				environmentTable.fogDensityOffset = environmentTable.defaultFogDensityOffset
			else
				environmentTable.fogDensityOffset = tonumber(value)
			end
		elseif key == "cloudCover" then
			if value == "default" then
				environmentTable.cloudCover = environmentTable.defaultCloudCover
			else
				environmentTable.cloudCover = tonumber(value)
			end
		elseif key == "cloudSpeed" then
			if value == "default" then
				environmentTable.cloudSpeed = environmentTable.defaultCloudSpeed
			else
				environmentTable.cloudSpeed = tonumber(value)
			end
		elseif key == "rainDrops" then
			if value == "default" then
				environmentTable.rainDrops = environmentTable.defaultRainDrops
			else
				environmentTable.rainDrops = tonumber(value)
			end
		elseif key == "dropSize" then
			if value == "default" then
				environmentTable.dropSize = environmentTable.defaultDayScale
			else
				environmentTable.dropSize = tonumber(value)
			end
		elseif key == "dropMinSpeed" then
			if value == "default" then
				environmentTable.dropMinSpeed = environmentTable.defaultDropMinSpeed
			else
				environmentTable.dropMinSpeed = tonumber(value)
			end
		elseif key == "dropMaxSpeed" then
			if value == "default" then
				environmentTable.dropMaxSpeed = environmentTable.defaultDropMaxSpeed
			else
				environmentTable.dropMaxSpeed = tonumber(value)
			end
		elseif key == "precipType" then
			precipType = value
		elseif key == "teleportTimeout" then
			if value == "default" then
				environmentTable.teleportTimeout = environmentTable.defaultTeleportTimeout
			else
				environmentTable.teleportTimeout = tonumber(value)
			end
		elseif key == "simSpeed" then
			if value == "default" then
				environmentTable.simSpeed = environmentTable.defaultSimSpeed
			else
				environmentTable.simSpeed = tonumber(value)
			end
		elseif key == "gravity" then
			if value == "default" then
				environmentTable.gravity = environmentTable.defaultGravity
			else
				environmentTable.gravity = tonumber(value)
			end
		elseif key == "tempCurveNoon" then
			if value == "default" then
				environmentTable.tempCurveNoon = environmentTable.defaultTempCurveNoon
			else
				environmentTable.tempCurveNoon = tonumber(value)
			end
		elseif key == "tempCurveDusk" then
			if value == "default" then
				environmentTable.tempCurveDusk = environmentTable.defaultTempCurveDusk
			else
				environmentTable.tempCurveDusk = tonumber(value)
			end
		elseif key == "tempCurveMidnight" then
			if value == "default" then
				environmentTable.tempCurveMidnight = environmentTable.defaultTempCurveMidnight
			else
				environmentTable.tempCurveMidnight = tonumber(value)
			end
		elseif key == "tempCurveDawn" then
			if value == "default" then
				environmentTable.tempCurveDawn = environmentTable.defaultTempCurveDawn
			else
				environmentTable.tempCurveDawn = tonumber(value)
			end
		elseif key == "useTempCurve" then
			environmentTable.useTempCurve = value
		end
	end
end

function CEIToggleIgnition(senderID, data)
	--CElog("CEIToggleIgnition Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEIToggleLock Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetCurVeh Called by: " .. senderID .. ": " .. data, "CEI")
	MP.TriggerClientEvent(-1, "CEISetCurVeh", senderID .. "|" .. data)
	tempPCV[players[senderID].name] = data
end

function CEIStop(senderID, data)
	--CElog("CEIStop Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		MP.SendChatMessage(-1, "Good-bye!")
		exit()
	end
end

function CEISetNewGroup(senderID, data)
	--CElog("CEISetNewGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local group = data
		local newGroup = "group:" .. group
		local applyGroup = { [newGroup] = { level = 1 } }
		applyStuff(players.database, applyGroup)
	end
end

function CEIRemoveGroup(senderID, data)
	--CElog("CEIRemoveGroup Called by: " .. senderID .. ": " .. data, "CEI")
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
		M.updateCobaltDatabase("playerPermissions")
		playerPermissions = CobaltDB.new("playerPermissions")
	end
end

function CEISetNewVehiclePermsLevel(senderID, data)
	--CElog("CEISetNewVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEIRemoveVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetVehiclePerms Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local targetLevel = tempData[1]
		local targetVehicles = tonumber(tempData[2])
		CobaltDB.set("permissions", "vehicleCap", targetLevel, targetVehicles)
	end
end

function CEISetGroup(senderID, data)
	--CElog("CEISetGroup Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetGroupPerms Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetPerm Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetTempPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local targetID = tonumber(tempData[1])
		local name = players[targetID].name
		local permLvl = tonumber(tempData[2])
		tempPlayers[name].tempPermLevel = permLvl
	end
end

function CEISetCfg(senderID, data)
	--CElog("CEISetCfg Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEISetMaxActivePlayers Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = tonumber(data)
		CobaltDB.set("config", "maxActivePlayers", "value", data)
	end
end

function CEIRemoveVehicle(senderID, data)
	--CElog("CEIRemoveVehicle Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEIKick Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.kick(players[senderID], targetName, reason)
	end
end

function CEIBan(senderID, data)
	--CElog("CEIBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.ban(players[senderID], targetName, reason)
	end
end

function CEITempBan(senderID, data)
	--CElog("CEITempBan Called by: " .. senderID .. ": " .. data, "CEI")
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
	--CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		local playerID = tonumber(tempData[1])
		local reason = tempData[2]
		local targetName = players[playerID].name
		CC.mute(players[senderID], targetName, reason)
	end
end

function CEIUnmute(senderID, data)
	--CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = tonumber(data)
		local targetName = players[data].name
		CC.unmute(players[senderID], targetName)
	end
end

function CEIWhitelist(senderID, data)
	--CElog("CEIWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
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

function CEIRaceInclude(senderID, data)
	--CElog("CEIRaceInclude Called by: " .. senderID .. ": " .. data, "CEI")
		playerName = players[senderID].name
	if data == "true" then
		tempPlayers[playerName].includeInRace = "true"
	elseif data == "false" then
		tempPlayers[playerName].includeInRace = "false"
	end
end

function CEISetNametagWhitelist(senderID, data)
	--CElog("CEISetNametagWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("nametags", "nametagsWhitelist", data, data)
		local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
		local nametagWhitelistIterator = 0
		nametagsConfig.whitelist = {}
		for k,v in pairs(nametagsBlockingWhitelist) do
			if k ~= "description" then
				nametagWhitelistIterator = nametagWhitelistIterator + 1
				nametagsConfig.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
			end
		end
	end
end

function CEIRemoveNametagWhitelist(senderID, data)
	--CElog("CEIRemoveNametagWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		CobaltDB.set("nametags", "nametagsWhitelist", data, nil)
		local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
		local nametagWhitelistIterator = 0
		nametagsConfig.whitelist = {}
		for k,v in pairs(nametagsBlockingWhitelist) do
			if k ~= "description" then
				nametagWhitelistIterator = nametagWhitelistIterator + 1
				nametagsConfig.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
			end
		end
	end
end

function CEINametagSetting(senderID, data)
	--CElog("CEINametagSetting Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or player.permissions.group == "mod" then
		if tonumber(data) then
			CobaltDB.set("nametags", "blockingTimeout", "value", tonumber(data))
			nametagsConfig.settings.blockingTimeout = data
		else
			CobaltDB.set("nametags", "blockingEnabled", "value", data)
			nametagsConfig.settings.blockingEnabled = data
		end
	end
end

function CEINametagBlockingTimer(senderID, data)
	--CElog("CEINametagBlockingTimer Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or player.permissions.group == "mod" then
		MP.TriggerClientEvent("","")
	end
end

function CEIConfig(senderID, data)
	--CElog("CEIConfig Called by: " .. senderID .. ": " .. data, "CEI")
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

function CEITeleportFrom(senderID, data)
	--CElog("CEITeleportFrom Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local targetID = tonumber(data)
		MP.TriggerClientEvent(targetID, "rxTeleportFrom", players[senderID].name)
	end
end

function CEISetTeleportPerm(senderID, data)
	--CElog("CEISetTeleportPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = split(data,"|")
		playerID = tonumber(tempData[1])
		playerName = players[playerID].name
		if tempData[2] == "false" then
			teleport[playerName] = false
			CobaltDB.set("playersDB/" .. playerName, "teleport", "value", false)
			MP.TriggerClientEvent(playerID, "rxCEItp", "false")
		elseif tempData[2] == "true" then
			teleport[playerName] = true
			CobaltDB.set("playersDB/" .. playerName, "teleport", "value", true)
			MP.TriggerClientEvent(playerID, "rxCEItp", "true")
		end
	end
end

local function onTick(age)

	local playerCount = MP.GetPlayerCount()

	if playerCount == 0 then
		if environmentTable.timePlay == "true" then
			if environmentTable.ToD >= 0.25 and environmentTable.ToD <= 0.75 then
				environmentTable.ToD = environmentTable.ToD + (environmentTable.nightScale * 0.000555)
			else
				environmentTable.ToD = environmentTable.ToD + (environmentTable.dayScale * 0.000555)
			end
			if environmentTable.ToD > 1 then
				environmentTable.ToD = environmentTable.ToD % 1
			end
		end
	end
	
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if MP.IsPlayerConnected(player.playerID) then
				if player.permissions.group == "owner"  or player.permissions.group == "admin" or player.permissions.group == "mod" then
					txPlayersData(player)
					txConfigData(player)
					txStats(player)
					txPlayersRoles(player)
					txEnvironment(player)
					txNametagWhitelisted(player)
					txNametagBlockerActive(player)
				else
					txPlayersData(player)
					txPlayersRoles(player)
					txEnvironment(player)
					txNametagWhitelisted(player)
					txNametagBlockerActive(player)
				end
			end
		end
	end
	
	environmentLogTimer = environmentLogTimer + 1
	
	if environmentLogTimer >= environmentLogInterval then
		logEnvironment()
		environmentLogTimer = 0
	end
	
	if raceCountdown ~= nil then
		if raceCountdown == 15 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "3ping")
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "You have been locked in place, prepare to start!|5")
					MP.SendChatMessage(v.player_id, "🚦 You have been locked in place, prepare to start! 🚦")
				end
			end
		elseif raceCountdown == 11 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "countTenHorn")
				end
			end
		elseif raceCountdown == 10 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "10...|1|true")
					MP.SendChatMessage(v.player_id, "🟥🔟🟥")
				end
			end
		elseif raceCountdown == 9 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "9...|1|true")
					MP.SendChatMessage(v.player_id, "🟥9️⃣🟥")
				end
			end
		elseif raceCountdown == 8 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "8...|1|true")
					MP.SendChatMessage(v.player_id, "🟥8️⃣🟥")
				end
			end
		elseif raceCountdown == 7 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "7...|1|true")
					MP.SendChatMessage(v.player_id, "🟥7️⃣🟥")
				end
			end
		elseif raceCountdown == 6 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "6...|1|true")
					MP.SendChatMessage(v.player_id, "🟥6️⃣🟥")
				end
			end
		elseif raceCountdown == 5 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "5...|1|true")
					MP.SendChatMessage(v.player_id, "🟥5️⃣🟥")
				end
			end
		elseif raceCountdown == 4 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "4...|1|true")
					MP.SendChatMessage(v.player_id, "🟥4️⃣🟥")
				end
			end
		elseif raceCountdown == 3 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "3...|1|true")
					MP.SendChatMessage(v.player_id, "🟨3️⃣🟨")
				end
			end
		elseif raceCountdown == 2 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "2...|1|true")
					MP.SendChatMessage(v.player_id, "🟨2️⃣🟨")
				end
			end
		elseif raceCountdown == 1 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "1...|1|true")
					MP.SendChatMessage(v.player_id, "🟨1️⃣🟨")
				end
			end
		elseif raceCountdown == 0 then
			for k,v in pairs(tempPlayers) do
				if v.includeInRace == "true" then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountdown", "❇️GO!!!❇️|3|true")
					MP.TriggerClientEvent(-1, "CEIRaceStart", "true")
					MP.SendChatMessage(v.player_id, "🟩🟩🟩")
					MP.SendChatMessage(v.player_id, "🟩❇️🟩")
					MP.SendChatMessage(v.player_id, "🟩🟩🟩")
				end
			end
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
	tempPlayers[player_name].includeInRace = "false"
	tempPCV[player_name] = "none"
end

local function onPlayerJoining(player)
	tempPlayers[player.name].tempPermLevel = player.permissions.level
	tempPlayers[player.name].player_id = player.playerID
end

local function onPlayerJoin(player)
	local state
	local tp
	
	if CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == nil then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", defaultInterfaceState)
		showCEI[player.name] = defaultInterfaceState
		if defaultInterfaceState == true then
			state = "show"
		elseif defaultInterfaceState == false then
			state = "hide"
		end
	elseif CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == true then
		showCEI[player.name] = true
		state = "show"
	elseif CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == false then
		showCEI[player.name] = false
		state = "hide"
	end
	
	if CobaltDB.query("playersDB/" .. player.name, "teleport", "value") == nil then
		CobaltDB.set("playersDB/" .. player.name, "teleport", "value", false)
		teleport[player.name] = false
		tp = "false"
	elseif CobaltDB.query("playersDB/" .. player.name, "teleport", "value") == true then
		teleport[player.name] = true
		tp = "true"
	elseif CobaltDB.query("playersDB/" .. player.name, "teleport", "value") == false then
		teleport[player.name] = false
		tp = "false"
	end
	
	MP.TriggerClientEvent(player.playerID, "rxCEIstate", state)
	MP.TriggerClientEvent(player.playerID, "rxCEItp", tp)
	
	CE.delayExec( 2000 , MP.SendChatMessage , { player.playerID , "This server uses Cobalt Essentials Interface." } )
	CE.delayExec( 2500 , MP.SendChatMessage , { player.playerID , "Use /CEI or /cei in chat to toggle." } )
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

local function updateCobaltDatabase(DBname)
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

function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0
	local iter = function ()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

M.applyStuff = applyStuff

M.onInit = onInit
M.onTick = onTick
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect
M.onVehicleSpawn = onVehicleSpawn

M.updateCobaltDatabase = updateCobaltDatabase

M.CEI = CEI
M.cei = CEI

return M
