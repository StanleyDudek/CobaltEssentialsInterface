--CEI (SERVER) by Dudekahedron, 2022

local M = {}

M.COBALT_VERSION = "1.6.0"

utils.setLogType("CEI",93)

local tomlParser = require("toml")

local loadedDatabases = {}

local showCEI = {}
local teleport = {}

local playersTable = {}

local tempPlayers = {}
local tempPCV = {}

local kickThresh

local config = {}
config.server = {}
config.cobalt = {}
config.cobalt.whitelistedPlayers = {}
config.cobalt.permissions = {}
config.cobalt.permissions.vehiclePerm = {}
config.cobalt.interface = {}
config.cobalt.interface.defaultState = true
config.cobalt.groups = {}
config.nametags = {}
config.nametags.whitelist = {}
config.nametags.settings = {}
config.resets = {}
config.resets.control_default = false
config.resets.messageDuration_default = 5
config.resets.enabled_default = true
config.resets.timeout_default = 10
config.resets.title_default = "Vehicle Reset Limiter"
config.resets.elapsedMessage_default = "You can now reset your vehicle."
config.resets.message_default = "You can reset your vehicle in {secondsLeft} seconds."
config.resets.disabledMessage_default = "Vehicle resetting is disabled on this server."
config.resets.control = ""
config.resets.messageDuration = ""
config.resets.enabled = ""
config.resets.timeout = ""
config.resets.title = ""
config.resets.elapsedMessage = ""
config.resets.message = ""
config.resets.disabledMessage = ""

local defaultNametagsBlockingEnabled = false
local defaultNametagsBlockingTimeout = 300
local defaultNametagsBlockingWhitelist = "exampleName"

local logTimer = 0
local logInterval = 30

local environment = {}
environment.controlSun_default = false
environment.ToD_default = 0.125
environment.timePlay_default = false
environment.dayLength_default = 1800
environment.dayScale_default = 1
environment.nightScale_default = 2
environment.sunAzimuthOverride_default = 0.0
environment.skyBrightness_default = 40
environment.sunSize_default = 1
environment.rayleighScattering_default = 0.003
environment.sunLightBrightness_default = 1
environment.flareScale_default = 5
environment.occlusionScale_default = 0.025
environment.exposure_default = 1
environment.shadowDistance_default = 1600
environment.shadowSoftness_default = 0.2
environment.shadowSplits_default = 4
environment.shadowTexSize_default = 1024
environment.shadowLogWeight_default = 0.98
environment.visibleDistance_default = 4000
environment.moonAzimuth_default = 0.0
environment.moonElevation_default = 45
environment.moonScale_default = 0.03
environment.controlWeather_default = false
environment.fogDensity_default = 0.001
environment.fogDensityOffset_default = 8.0
environment.fogAtmosphereHeight_default = 400
environment.cloudHeight_default = 2.5
environment.cloudHeightOne_default = 5
environment.cloudCover_default = 0.2
environment.cloudCoverOne_default = 0.2
environment.cloudSpeed_default = 0.2
environment.cloudSpeedOne_default = 0.2
environment.cloudExposure_default = 1.4
environment.cloudExposureOne_default = 1.6
environment.rainDrops_default = 0
environment.dropSize_default = 1
environment.dropMinSpeed_default = 0.1
environment.dropMaxSpeed_default = 0.2
environment.precipType_default = "rain_medium"
environment.teleportTimeout_default = 5
environment.simSpeed_default = 1
environment.controlSimSpeed_default = false
environment.gravity_default = -9.81
environment.controlGravity_default = false
environment.tempCurveNoon_default = 38
environment.tempCurveDusk_default = 12
environment.tempCurveMidnight_default = -15
environment.tempCurveDawn_default = 12
environment.useTempCurve_default = false
environment.controlSun = ""
environment.ToD = ""
environment.timePlay = ""
environment.dayLength = ""
environment.dayScale = ""
environment.nightScale = ""
environment.sunAzimuthOverride = ""
environment.skyBrightness = ""
environment.sunSize = ""
environment.rayleighScattering = ""
environment.sunLightBrightness = ""
environment.flareScale = ""
environment.occlusionScale = ""
environment.exposure = ""
environment.shadowDistance = ""
environment.shadowSoftness = ""
environment.shadowSplits = ""
environment.shadowTexSize = ""
environment.shadowLogWeight = ""
environment.visibleDistance = ""
environment.moonAzimuth = ""
environment.moonElevation = ""
environment.moonScale = ""
environment.controlWeather = ""
environment.fogDensity = ""
environment.fogDensityOffset = ""
environment.fogAtmosphereHeight = ""
environment.cloudHeight = ""
environment.cloudHeightOne = ""
environment.cloudCover = ""
environment.cloudCoverOne = ""
environment.cloudSpeed = ""
environment.cloudSpeedOne = ""
environment.cloudExposure = ""
environment.cloudExposureOne = ""
environment.rainDrops = ""
environment.dropSize = ""
environment.dropMinSpeed = ""
environment.dropMaxSpeed = ""
environment.precipType = ""
environment.teleportTimeout = ""
environment.simSpeed = ""
environment.controlSimSpeed = ""
environment.gravity = ""
environment.controlGravity = ""
environment.tempCurveNoon = ""
environment.tempCurveDusk = ""
environment.tempCurveMidnight = ""
environment.tempCurveDawn = ""
environment.useTempCurve = ""

local environmentJson = CobaltDB.new("environment")
local defaultEnvironment = {
	controlSun = {value = environment.controlSun_default, description = "Do we control everyone's sun?"},
	ToD = {value = environment.ToD_default, description = "What is the Time of Day?"},
	timePlay = {value = environment.timePlay_default, description = "Does time progress?"},
	dayLength = {value = environment.dayLength_default, description = "How long is the day?"},
	dayScale = {value = environment.dayScale_default, description = "At what rate does daytime progress?"},
	nightScale = {value = environment.nightScale_default, description = "At what rate does nighttime progress?"},
	sunAzimuthOverride = {value = environment.sunAzimuthOverride_default, description = "At what position on the horizon does the sun rise and set?"},
	skyBrightness = {value = environment.skyBrightness_default, description = "How bright is the sky?"},
	sunSize = {value = environment.sunSize_default, description = "How big is the sun?"},
	rayleighScattering = {value = environment.rayleighScattering_default, description = "How much rayleigh scattering"},
	sunLightBrightness = {value = environment.sunLightBrightness_default, description = "How bright is the sunlight?"},
	flareScale = {value = environment.flareScale_default, description = "How big is the sun lens flare?"},
	occlusionScale = {value = environment.occlusionScale_default, description = "How occluded is the sun lens flare?"},
	exposure = {value = environment.exposure_default, description = "How exposed is the environment?"},
	shadowDistance = {value = environment.shadowDistance_default, description = "How far are the shadows?"},
	shadowSoftness = {value = environment.shadowSoftness_default, description = "How soft are the shadows?"},
	shadowSplits = {value = environment.shadowSplits_default, description = "How many splits are there for shadows?"},
	shadowTexSize = {value = environment.shadowTexSize_default, description = "What is the texture resolution for shadows?"},
	shadowLogWeight = {value = environment.shadowLogWeight_default, description = "How much does the log weigh?"},
	visibleDistance = {value = environment.visibleDistance_default, description = "How far can we see?"},
	moonAzimuth = {value = environment.moonAzimuth_default, description = "Horizontal position of moon."},
	moonElevation = {value = environment.moonElevation_default, description = "Vertical position of moon."},
	moonScale = {value = environment.moonScale_default, description = "How big is the moon?"},
	controlWeather = {value = environment.controlWeather_default, description = "Do we control everyone's weather?"},
	fogDensity = {value = environment.fogDensity_default, description = "How thicc is the fog?"},
	fogDensityOffset = {value = environment.fogDensityOffset_default, description = "How far away is the fog?"},
	fogAtmosphereHeight = {value = environment.fogAtmosphereHeight_default, description = "How high is the fog?"},
	cloudHeight = {value = environment.cloudHeight_default, description = "How high are the clouds?"},
	cloudHeightOne = {value = environment.cloudHeightOne_default, description = "How high are the clouds?"},
	cloudCover = {value = environment.cloudCover_default, description = "How thicc are the clouds?"},
	cloudCoverOne = {value = environment.cloudCoverOne_default, description = "How thicc are the clouds?"},
	cloudSpeed = {value = environment.cloudSpeed_default, description = "How fast are the clouds?"},
	cloudSpeedOne = {value = environment.cloudSpeedOne_default, description = "How fast are the clouds?"},
	cloudExposure = {value = environment.cloudExposure_default, description = "How exposed are the clouds?"},
	cloudExposureOne = {value = environment.cloudExposureOne_default, description = "How exposed are the clouds?"},
	rainDrops = {value = environment.rainDrops_default, description = "How many rain drops are there?"},
	dropSize = {value = environment.dropSize_default, description = "What size are the drops of precipitation?"},
	dropMinSpeed = {value = environment.dropMinSpeed_default, description = "What is the minimum speed of precipitation?"},
	dropMaxSpeed = {value = environment.dropMaxSpeed_default, description = "What is the maximum speed of precipitation?"},
	precipType = {value = environment.precipType_default, description = "What type of precipitation do we use?"},
	teleportTimeout = {value = environment.teleportTimeout_default, description = "How long between telports?"},
	simSpeed = {value = environment.simSpeed_default, description = "At what rate does the simulation run?"},
	controlSimSpeed = {value = environment.controlSimSpeed_default, description = "Do we control everyone's sim speed?"},
	gravity = {value = environment.gravity_default, description = "At what rate do objects fall towards the ground?"},
	controlGravity = {value = environment.controlGravity_default, description = "Do we control everyone's gravity?"},
	tempCurveNoon = {value = environment.tempCurveNoon_default, description = "What is the custom temperature in C at noon?"},
	tempCurveDusk = {value = environment.tempCurveDusk_default, description = "What is the custom temperature in C at dusk?"},
	tempCurveMidnight = {value = environment.tempCurveMidnight_default, description = "What is the custom temperature in C at midnight?"},
	tempCurveDawn = {value = environment.tempCurveDawn_default, description = "What is the custom temperature in C at dawn?"},
	useTempCurve = {value = environment.useTempCurve_default, description = "Do we use a custom temperature curve?"}
}

local restrictionsJson = CobaltDB.new("restrictions")
local defaultRestrictions = {
	control = {value = config.resets.control_default, description = "Are resets controlled?"},
	messageDuration = {value = config.resets.messageDuration_default, description = "How long does the toast show?"},
	enabled = {value = config.resets.enabled_default, description = "Are resets allowed?"},
	timeout = {value = config.resets.timeout_default, description = "How often can a vehicle be reset (in seconds)?"},
	title = {value = config.resets.title_default, description = "Title shown when resetting is limited or disabled."},
	elapsedMessage = {value = config.resets.elapsedMessage_default, description = "Message shown when reset timeout has elapsed."},
	message = {value = config.resets.message_default, description = "Message shown when resetting is limited."},
	disabledMessage = {value = config.resets.disabledMessage_default, description = "Message shown when resetting is completely disabled."},
}

local vehiclesJson = CobaltDB.new("vehicles")
local defaultVehicles = {
	autobello = { level = 1 },
	ball = { level = 1 },
	barrels = { level = 1 },
	barrier = { level = 1 },
	barrier_plastic = { level = 1 },
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
	covet = { level = 1 },
	delineator = { level = 1 },
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
	large_tire = { level = 1 },
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
	scintilla = { level = 1 },
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

local nametagsJson = CobaltDB.new("nametags")
local defaultNametagsSettings = {
	blockingEnabled = {value = defaultNametagsBlockingEnabled, description = "Are nametags blocked?"},
	blockingTimeout = {value = defaultNametagsBlockingTimeout, description = "For how long are nametags blocked?"},
	nametagsWhitelist = {exampleName = defaultNametagsBlockingWhitelist, description = "Who is immune to nametag blocking?"}
}

local interfaceJson = CobaltDB.new("interface")
local defaultInterfaceSettings = {
	defaultCEIState = {value = config.cobalt.interface.defaultState, description = "The state of the interface for new players."}
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
	MP.RegisterEvent("CEIToggleRaceLock","CEIToggleRaceLock")
	MP.RegisterEvent("CEISetNewGroup","CEISetNewGroup")
	MP.RegisterEvent("CEIRemoveGroup","CEIRemoveGroup")
	MP.RegisterEvent("CEISetGroupLevel","CEISetGroupLevel")
	MP.RegisterEvent("CEISetGroupPerms","CEISetGroupPerms")
	MP.RegisterEvent("CEISetPerm","CEISetPerm")
	MP.RegisterEvent("CEISetUIPerm","CEISetUIPerm")
	MP.RegisterEvent("CEISetTempPerm","CEISetTempPerm")
	MP.RegisterEvent("CEISetTempUIPerm","CEISetTempUIPerm")
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
	MP.RegisterEvent("CEIVoteKick","CEIVoteKick")
	MP.RegisterEvent("CEIKick","CEIKick")
	MP.RegisterEvent("CEIBan","CEIBan")
	MP.RegisterEvent("CEIUnban","CEIUnban")
	MP.RegisterEvent("CEITempBan","CEITempBan")
	MP.RegisterEvent("CEIMute","CEIMute")
	MP.RegisterEvent("CEIUnmute","CEIUnmute")
	MP.RegisterEvent("CEIWhitelist","CEIWhitelist")
	MP.RegisterEvent("CEISetNametagWhitelist","CEISetNametagWhitelist")
	MP.RegisterEvent("CEIRemoveNametagWhitelist","CEIRemoveNametagWhitelist")
	MP.RegisterEvent("CEINametagSetting","CEINametagSetting")
	MP.RegisterEvent("CEIStop","CEIStop")
	MP.RegisterEvent("CEISetRestrictions","CEISetRestrictions")
	MP.RegisterEvent("CEISetEnv","CEISetEnv")
	MP.RegisterEvent("CEISetTempBan","CEISetTempBan")
	MP.RegisterEvent("CEISetTeleportPerm","CEISetTeleportPerm")
	MP.RegisterEvent("CEITeleportFrom","CEITeleportFrom")
	MP.RegisterEvent("CEIRaceInclude","CEIRaceInclude")
	MP.RegisterEvent("txNametagBlockerTimeout","txNametagBlockerTimeout")
	config.server.name = utils.readCfg("ServerConfig.toml").General.Name
	if not utils.readCfg("ServerConfig.toml").General.Debug then
		config.server.debug = false
	else
		config.server.debug = true
	end
	if not utils.readCfg("ServerConfig.toml").General.Private then
		config.server.private = false
	else
		config.server.private = true
	end
	config.server.maxCars = utils.readCfg("ServerConfig.toml").General.MaxCars
	config.server.maxPlayers = utils.readCfg("ServerConfig.toml").General.MaxPlayers
	config.server.map = utils.readCfg("ServerConfig.toml").General.Map
	config.server.description = utils.readCfg("ServerConfig.toml").General.Description
	
	M.applyStuff(environmentJson, defaultEnvironment)
	M.applyStuff(vehiclesJson, defaultVehicles)
	M.applyStuff(nametagsJson, defaultNametagsSettings)
	M.applyStuff(interfaceJson, defaultInterfaceSettings)
	M.applyStuff(restrictionsJson, defaultRestrictions)
	
	config.resets.control = CobaltDB.query("restrictions", "control", "value")
	config.resets.messageDuration = CobaltDB.query("restrictions", "messageDuration", "value")
	config.resets.enabled = CobaltDB.query("restrictions", "enabled", "value")
	config.resets.timeout = CobaltDB.query("restrictions", "timeout", "value")
	config.resets.title = CobaltDB.query("restrictions", "title", "value")
	config.resets.elapsedMessage = CobaltDB.query("restrictions", "elapsedMessage", "value")
	config.resets.message = CobaltDB.query("restrictions", "message", "value")
	config.resets.disabledMessage = CobaltDB.query("restrictions", "disabledMessage", "value")
	
	config.nametags.settings.blockingEnabled = CobaltDB.query("nametags", "blockingEnabled", "value")
	config.nametags.settings.blockingTimeout = CobaltDB.query("nametags", "blockingTimeout", "value")
	config.nametags.settings.blockingTimeout = CobaltDB.query("nametags", "blockingTimeout", "value")
	
	environment.controlSun = CobaltDB.query("environment", "controlSun", "value")
	environment.ToD = CobaltDB.query("environment", "ToD", "value")
	environment.timePlay = CobaltDB.query("environment", "timePlay", "value")
	environment.dayLength = CobaltDB.query("environment", "dayLength", "value")
	environment.dayScale = CobaltDB.query("environment", "dayScale", "value")
	environment.nightScale = CobaltDB.query("environment", "nightScale", "value")
	environment.sunAzimuthOverride = CobaltDB.query("environment", "sunAzimuthOverride", "value")
	environment.skyBrightness = CobaltDB.query("environment", "skyBrightness", "value")
	environment.sunSize = CobaltDB.query("environment", "sunSize", "value")
	environment.rayleighScattering = CobaltDB.query("environment", "rayleighScattering", "value")
	environment.sunLightBrightness = CobaltDB.query("environment", "sunLightBrightness", "value")
	environment.flareScale = CobaltDB.query("environment", "flareScale", "value")
	environment.occlusionScale = CobaltDB.query("environment", "occlusionScale", "value")
	environment.exposure = CobaltDB.query("environment", "exposure", "value")
	environment.shadowDistance = CobaltDB.query("environment", "shadowDistance", "value")
	environment.shadowSoftness = CobaltDB.query("environment", "shadowSoftness", "value")
	environment.shadowSplits = CobaltDB.query("environment", "shadowSplits", "value")
	environment.shadowTexSize = CobaltDB.query("environment", "shadowTexSize", "value")
	environment.shadowLogWeight = CobaltDB.query("environment", "shadowLogWeight", "value")
	environment.visibleDistance = CobaltDB.query("environment", "visibleDistance", "value")
	environment.moonAzimuth = CobaltDB.query("environment", "moonAzimuth", "value")
	environment.moonElevation = CobaltDB.query("environment", "moonElevation", "value")
	environment.moonScale = CobaltDB.query("environment", "moonScale", "value")
	environment.controlWeather = CobaltDB.query("environment", "controlWeather", "value")
	environment.fogDensity = CobaltDB.query("environment", "fogDensity", "value")
	environment.fogDensityOffset = CobaltDB.query("environment", "fogDensityOffset", "value")
	environment.fogAtmosphereHeight = CobaltDB.query("environment", "fogAtmosphereHeight", "value")
	environment.cloudHeight = CobaltDB.query("environment", "cloudHeight", "value")
	environment.cloudHeightOne = CobaltDB.query("environment", "cloudHeightOne", "value")
	environment.cloudCover = CobaltDB.query("environment", "cloudCover", "value")
	environment.cloudCoverOne = CobaltDB.query("environment", "cloudCoverOne", "value")
	environment.cloudSpeed = CobaltDB.query("environment", "cloudSpeed", "value")
	environment.cloudSpeedOne = CobaltDB.query("environment", "cloudSpeedOne", "value")
	environment.cloudExposure = CobaltDB.query("environment", "cloudExposure", "value")
	environment.cloudExposureOne = CobaltDB.query("environment", "cloudExposureOne", "value")
	environment.rainDrops = CobaltDB.query("environment", "rainDrops", "value")
	environment.dropSize = CobaltDB.query("environment", "dropSize", "value")
	environment.dropMinSpeed = CobaltDB.query("environment", "dropMinSpeed", "value")
	environment.dropMaxSpeed = CobaltDB.query("environment", "dropMaxSpeed", "value")
	environment.precipType = CobaltDB.query("environment", "precipType", "value")
	environment.teleportTimeout = CobaltDB.query("environment", "teleportTimeout", "value")
	environment.simSpeed = CobaltDB.query("environment", "simSpeed", "value")
	environment.controlSimSpeed = CobaltDB.query("environment", "controlSimSpeed", "value")
	environment.gravity = CobaltDB.query("environment", "gravity", "value")
	environment.controlGravity = CobaltDB.query("environment", "controlGravity", "value")
	environment.tempCurveNoon = CobaltDB.query("environment", "tempCurveNoon", "value")
	environment.tempCurveDusk = CobaltDB.query("environment", "tempCurveDusk", "value")
	environment.tempCurveMidnight = CobaltDB.query("environment", "tempCurveMidnight", "value")
	environment.tempCurveDawn = CobaltDB.query("environment", "tempCurveDawn", "value")
	environment.useTempCurve = CobaltDB.query("environment", "useTempCurve", "value")
	
	config.cobalt.interface.defaultState = CobaltDB.query("interface", "defaultCEIState", "value")
	
	local playersDatabase
	if FS.Exists("Resources/Server/CobaltEssentials/CobaltDB/playersDB") then
		playersDatabase = FS.ListFiles("Resources/Server/CobaltEssentials/CobaltDB/playersDB")
	else
		playersDatabase = {}
	end
	
	for k,v in pairs(playersDatabase) do
		local playerName = string.gsub(v, ".json", "")
		CobaltDB.new("playersDB/" .. playerName)
		tempPlayers[playerName] = {}
	end
		
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
	if showCEI[player.name] == false then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", true)
		showCEI[player.name] = true
	elseif showCEI[player.name] == true then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", false)
		showCEI[player.name] = false
	end
	MP.TriggerClientEventJson(player.playerID, "rxCEIstate", { showCEI[player.name] } )
end

local function txPlayersGroup(player)
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if player.connectStage == "connected" then
				MP.TriggerClientEvent(player.playerID, "rxPlayerGroup", player.permissions.group)
			end
		end
	end
end

local function txPlayersUIPerm(player)
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if player.connectStage == "connected" then
				MP.TriggerClientEvent(player.playerID, "rxPlayersUIPerm", tostring(player.permissions.UI))
			end
		end
	end
end

local function txPlayersDatabase(player)
	local playersDatabase = FS.ListFiles("Resources/Server/CobaltEssentials/CobaltDB/playersDB")
	for k,v in pairs(playersDatabase) do
		local playerName = string.gsub(v, ".json", "")
		playersDatabase[k] = {}
		local playerPermissions = CobaltDB.getTables("playersDB/" .. playerName)
		playersDatabase[k].permissions = {}
		for a,b in pairs(playerPermissions) do
			playersDatabase[k].permissions[a] = CobaltDB.query("playersDB/" .. playerName, a, "value")
		end
		playersDatabase[k].permissions.group = players.database[playerName].group
		playersDatabase[k].playerName = playerName
		playersDatabase[k].beammp = CobaltDB.query("playersDB/" .. playerName, "beammp", "value")
		playersDatabase[k].ip = CobaltDB.query("playersDB/" .. playerName, "ip", "value")
		if CobaltDB.query("playersDB/" .. playerName, "UI", "value") then
			playersDatabase[k].UI = CobaltDB.query("playersDB/" .. playerName, "UI", "value")
		end
		playersDatabase[k].banned = CobaltDB.query("playersDB/" .. playerName, "banned", "value")
		if CobaltDB.query("playersDB/" .. playerName, "banReason", "value") then
			playersDatabase[k].banReason = players.database[playerName].banReason
		else
			CobaltDB.query("playersDB/" .. playerName, "banReason", "value", "No reason specified")
		end
		if CobaltDB.query("playersDB/" .. playerName, "tempBan", "value") then
			playersDatabase[k].tempBanRemaining = CobaltDB.query("playersDB/" .. playerName, "tempBan", "value") - os.time()
			if playersDatabase[k].tempBanRemaining < 0 then
				playersDatabase[k].tempBanRemaining = nil
			end
		end
	end
	MP.TriggerClientEventJson(player.playerID, "rxPlayersDatabase", playersDatabase)
end

local function txEnvironment(player)
	MP.TriggerClientEventJson(player.playerID, "rxEnvironment", environment)
end

local function txPlayersData(player)
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			local connectedTime
			connectedTime = ageTimer:GetCurrent()*1000 - player.joinTime
			connectedTime = connectedTime / 1000
			playersTable[player.playerID] = {
					playerID = player.playerID,
					playerName = player.name,
					connectStage = player.connectStage,
					guest = player.guest,
					joinTime = player.joinTime / 1000,
					connectedTime = connectedTime,
					gamemode = {
						mode = player.gamemode.mode,
						source = player.gamemode.source,
						queue = player.gamemode.queue,
						locked = player.gamemode.locked
						},
					permissions = {
						whitelisted = player.permissions.whitelisted,
						level = player.permissions.level,
						group = player.permissions.group,
						muted = player.permissions.muted,
						muteReason = (player.permissions.muteReason or ""),
						banned = player.permissions.banned,
						ip = player.permissions.ip,
						beammp = player.permissions.beammp,
						UI = player.permissions.UI
						},
					teleport = teleport[player.name],
					tempBanLength = tempPlayers[player.name].tempBanLength,
					tempPermLevel = tempPlayers[player.name].tempPermLevel,
					tempUIPermLevel = tempPlayers[player.name].tempUIPermLevel,
					includeInRace = tempPlayers[player.name].includeInRace,
					currentVehicle = tempPCV[player.name],
					vehicles = (player.vehicles or {})
					}
			for k,v in pairs(playersTable[player.playerID].vehicles) do
				playersTable[player.playerID].vehicles[k].vehicleID = k
				playersTable[player.playerID].vehicles[k].rot = nil
				playersTable[player.playerID].vehicles[k].pos = nil
				playersTable[player.playerID].vehicles[k].vcf = nil
				playersTable[player.playerID].vehicles[k].cfg = nil
				playersTable[player.playerID].vehicles[k].cpz = nil
				playersTable[player.playerID].vehicles[k].cpo = nil
				playersTable[player.playerID].vehicles[k].col = nil
			end
		end
	end
	MP.TriggerClientEventJson(player.playerID, "rxPlayersData", playersTable)
end

local function txConfigData(player)
	config.cobalt.maxActivePlayers = tostring(CobaltDB.query("config", "maxActivePlayers", "value"))
	config.cobalt.enableWhitelist = CobaltDB.query("config", "enableWhitelist", "value")
	local playerGroupsLength = 0
	local whitelistLength = 0
	local groupPlayerLength = 0
	for k,v in pairs(players.database) do
		if string.find(k, "group") then
			playerGroupsLength = playerGroupsLength + 1
			config.cobalt.groups[playerGroupsLength] = {}
			config.cobalt.groups[playerGroupsLength].groupName = k
			config.cobalt.groups[playerGroupsLength].groupPerms = CobaltDB.getTable("playerPermissions",k)
			config.cobalt.groups[playerGroupsLength].groupPlayers = {}
			for w,z in pairs(players.database) do
				for a,b in pairs(z) do
					if a == "group" then
						if "group:"..b == k then
							groupPlayerLength = groupPlayerLength + 1
							config.cobalt.groups[playerGroupsLength].groupPlayers[groupPlayerLength] = w
						end
					end
				end
			end
		else
			if players.database[k].whitelisted then
				whitelistLength = whitelistLength + 1
				config.cobalt.whitelistedPlayers[whitelistLength] = k
			end
		end
	end
	local vehicleCaps = CobaltDB.getTable("permissions","vehicleCap")
	local vehicleCapsLength = 0
	config.cobalt.permissions.vehicleCap = {}
	for k,v in pairs(vehicleCaps) do
		if string.find(k, "%d+") then
			vehicleCapsLength = vehicleCapsLength + 1
			config.cobalt.permissions.vehicleCap[vehicleCapsLength] = {}
			config.cobalt.permissions.vehicleCap[vehicleCapsLength].level = k
			config.cobalt.permissions.vehicleCap[vehicleCapsLength].vehicles = CobaltDB.query("permissions","vehicleCap",k)
		end
	end
	local vehiclePerms = CobaltDB.getTables("vehicles")
	local vehiclePermsLength = 0
	local vehiclePermsPartLevelsLength = 0
	for k,v in pairsByKeys(vehiclePerms) do
		vehiclePermsLength = vehiclePermsLength + 1
		config.cobalt.permissions.vehiclePerm[vehiclePermsLength] = {}
		config.cobalt.permissions.vehiclePerm[vehiclePermsLength].partLevel = {}
		config.cobalt.permissions.vehiclePerm[vehiclePermsLength].name = v
		local vehiclePerm = CobaltDB.getTable("vehicles",v)
		for i,j in pairsByKeys(vehiclePerm) do
			if i == "level" then
				config.cobalt.permissions.vehiclePerm[vehiclePermsLength].level = j
			end
			if string.find(i,"partlevel") then
				vehiclePermsPartLevelsLength = vehiclePermsPartLevelsLength + 1
				config.cobalt.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength] = {}
				config.cobalt.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength].name = i
				config.cobalt.permissions.vehiclePerm[vehiclePermsLength].partLevel[vehiclePermsPartLevelsLength].level = j
			end
		end
	end
	MP.TriggerClientEventJson(player.playerID, "rxConfigData", config)
end

function txNametagWhitelisted(player)
	local isWhitelisted
	if CobaltDB.query("nametags","nametagsWhitelist",player.name) then
		config.nametags.whitelist[player.name] = CobaltDB.query("nametags","nametagsWhitelist",player.name)
		isWhitelisted = true
	else
		isWhitelisted = false
	end
	local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
	local nametagWhitelistIterator = 0
	config.nametags.whitelist = {}
	for k,v in pairs(nametagsBlockingWhitelist) do
		if k ~= "description" then
			nametagWhitelistIterator = nametagWhitelistIterator + 1
			config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
		end
	end
	MP.TriggerClientEventJson(player.playerID, "rxNametagWhitelisted", { isWhitelisted } )
end

function txNametagBlockerActive(player)
	local data = CobaltDB.query("nametags","blockingEnabled","value")
	MP.TriggerClientEventJson(player.playerID, "rxNametagBlockerActive", { data } )
end

function txNametagBlockerTimeout(senderID, data)
	data = Util.JsonDecode(data)
	MP.TriggerClientEvent(-1, "rxNametagBlockerTimeout", tostring(data[1]))
end

local function txData()
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if player.connectStage == "connected" then
				txPlayersData(player)
				txPlayersGroup(player)
				txEnvironment(player)
				txNametagWhitelisted(player)
				txNametagBlockerActive(player)
				txConfigData(player)
				txPlayersUIPerm(player)
				if player.permissions.UI then
					if player.permissions.UI > 1 then
						txPlayersDatabase(player)
					end
				end
			end
		end
	end
end

function CEIPreRace(senderID, data)
	--CElog("CEIStartRace Called by: " .. senderID .. ": " .. data, "CEI")
	if not raceCountdownStarted then
		raceCountdownStarted = true
		raceCountdown = 15
	end
end

function CEISetDefaultState(senderID, data)
	--CElog("CEISetDefaultState Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		CobaltDB.set("interface", "defaultCEIState", "value", data[1])
		config.cobalt.interface.defaultState = data[1]
	end
end

function CEISetNewVehiclePerm(senderID, data)
	--CElog("CEISetNewVehiclePerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local vehiclePermLevel = 1
		if vehicleName == nil or vehicleName == "" then
			MP.SendChatMessage(senderID, "Vehicle name cannot be blank!")
		else
			CobaltDB.set("vehicles", vehicleName, "level", vehiclePermLevel)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetVehiclePermLevel(senderID, data)
	--CElog("CEISetVehiclePermLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local vehiclePermLevel = tonumber(data[2])
		CobaltDB.set("vehicles", vehicleName, "level", vehiclePermLevel)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveVehiclePerm(senderID, data)
	--CElog("CEIRemoveVehiclePerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
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
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetNewVehiclePart(senderID, data)
	--CElog("CEISetNewVehiclePartname Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local partName = data[2]
		if partName == nil or partName == "" then
			MP.SendChatMessage(senderID, "Part name cannot be blank!")
		else
			local partName = "partlevel:" .. data[2]
			local partLevel = 1
			CobaltDB.set("vehicles", vehicleName, partName, partLevel)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetVehiclePartLevel(senderID, data)
	--CElog("CEISetVehiclePartnameLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local partName = "partlevel:" .. data[2]
		local partLevel = tonumber(data[3])
		CobaltDB.set("vehicles", vehicleName, partName, partLevel)
	end
end

function CEIRemoveVehiclePart(senderID, data)
	--CElog("CEIRemoveVehiclePart Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local partName = "partlevel:" .. data[2]
		local targetLevel = data
		if CobaltDB.query("vehicles", vehicleName, partName) then
			CobaltDB.set("vehicles", vehicleName, partName, nil)
		else
			return
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetVehiclePartLevel(senderID, data)
	--CElog("CEISetVehiclePartLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local vehiclePartName = "partlevel:" .. data[2]
		local vehiclePartLevel = tonumber(data[3])
		CobaltDB.set("vehicles", vehicleName, vehiclePartName, vehiclePartLevel)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetTempBan(senderID, data)
	--CElog("CEISetTempBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetID = tonumber(data[1])
		local name = players[targetID].name
		local playerTempBanLength = tonumber(data[2])
		tempPlayers[name].tempBanLength = playerTempBanLength
	end
end

function logEnvironment()
	local environmentTables = CobaltDB.getTables("environment")
	for k,v in pairs(environmentTables) do
		local currentEnvironmentTable = CobaltDB.getTable("environment",v)
		for x,y in pairs(currentEnvironmentTable) do
			if x == "value" then
				if environment[k] ~= y then
					CobaltDB.set("environment", k, "value", environment[k])
				end
			end
		end
	end
end

function logRestrictions()
	local restrictionsTables = CobaltDB.getTables("restrictions")
	for k,v in pairs(restrictionsTables) do
		local currentRestrictionTable = CobaltDB.getTable("restrictions",v)
		for x,y in pairs(currentRestrictionTable) do
			if x == "value" then
				if config.resets[k] ~= y then
					CobaltDB.set("restrictions", k, "value", config.resets[k])
				end
			end
		end
	end
end

function CEISetRestrictions(senderID, data)
	--CElog("CEISetEnv Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = data[2]
		if key == "all" then
			config.resets.control = config.resets.control_default
			config.resets.messageDuration = config.resets.messageDuration_default
			config.resets.enabled = config.resets.enabled_default
			config.resets.timeout = config.resets.timeout_default
			config.resets.title = config.resets.title_default
			config.resets.elapsedMessage = config.resets.elapsedMessage_default
			config.resets.message = config.resets.message_default
			config.resets.disabledMessage = config.resets.disabledMessage_default
		elseif value == "default" then
			config.resets[key] = config.resets[key .. "_default"]
		else
			config.resets[key] = value
		end
		for playerID, player in pairs(players) do
			if type(playerID) == "number" then
				if player.connectStage == "connected" then
					txConfigData(player)
				end
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetEnv(senderID, data)
	--CElog("CEISetEnv Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = data[2]
		if key == "allWeather" then
			environment.controlWeather = environment.controlWeather_default
			environment.fogDensity = environment.fogDensity_default
			environment.fogDensityOffset = environment.fogDensityOffset_default
			environment.fogAtmosphereHeight = environment.fogAtmosphereHeight_default
			environment.cloudHeight = environment.cloudHeight_default
			environment.cloudHeightOne = environment.cloudHeightOne_default
			environment.cloudCover = environment.cloudCover_default
			environment.cloudCoverOne = environment.cloudCoverOne_default
			environment.cloudSpeed = environment.cloudSpeed_default
			environment.cloudSpeedOne = environment.cloudSpeedOne_default
			environment.cloudExposure = environment.cloudExposure_default
			environment.cloudExposureOne = environment.cloudExposureOne_default
			environment.rainDrops = environment.rainDrops_default
			environment.dropSize = environment.dropSize_default
			environment.dropMinSpeed = environment.dropMinSpeed_default
			environment.dropMaxSpeed = environment.dropMaxSpeed_default
			environment.precipType = environment.precipType_default
		elseif key == "allSun" then
			environment.controlSun = environment.controlSun_default
			environment.ToD = environment.ToD_default
			environment.timePlay = environment.timePlay_default
			environment.dayScale = environment.dayScale_default
			environment.dayLength = environment.dayLength_default
			environment.nightScale = environment.nightScale_default
			environment.sunAzimuthOverride = environment.sunAzimuthOverride_default
			environment.skyBrightness = environment.skyBrightness_default
			environment.sunSize = environment.sunSize_default
			environment.rayleighScattering = environment.rayleighScattering_default
			environment.sunLightBrightness = environment.sunLightBrightness_default
			environment.flareScale = environment.flareScale_default
			environment.occlusionScale = environment.occlusionScale_default
			environment.exposure = environment.exposure_default
			environment.shadowDistance = environment.shadowDistance_default
			environment.shadowSoftness = environment.shadowSoftness_default
			environment.shadowSplits = environment.shadowSplits_default
			environment.shadowTexSize = environment.shadowTexSize_default
			environment.shadowLogWeight = environment.shadowLogWeight_default
			environment.visibleDistance = environment.visibleDistance_default
			environment.moonAzimuth = environment.moonAzimuth_default
			environment.moonElevation = environment.moonElevation_default
			environment.moonScale = environment.moonScale_default
		elseif key == "all" then
			for k,v in pairs(environment) do
				if not string.find(k, "default") then
					environment[k] = environment[k .. "_default"]
				end
			end
		elseif value == "default" then
			environment[key] = environment[key .. "_default"]
		elseif tonumber(value) then
			environment[key] = tonumber(value)
		else
			environment[key] = value
		end
		for playerID, player in pairs(players) do
			if type(playerID) == "number" then
				if player.connectStage == "connected" then
					txEnvironment(player)
				end
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "environment")
	end
end

function CEIToggleIgnition(senderID, data)
	--CElog("CEIToggleIgnition Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = Util.JsonDecode(data)
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(tempData[1])].name .. "!")
		else
			MP.TriggerClientEvent(-1, "CEIToggleIgnition", data)
		end
	end
end

function CEIToggleLock(senderID, data)
	--CElog("CEIToggleLock Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		local tempData = Util.JsonDecode(data)
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(tempData[1])].name .. "!")
		else
			MP.TriggerClientEvent(-1, "CEIToggleLock", data)
		end
	end
end

function CEIToggleRaceLock(senderID, data)
	--CElog("CEIToggleLock Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.group == "default" then
		MP.TriggerClientEvent(-1, "CEIToggleLock", data)
	end
end

function CEISetCurVeh(senderID, data)
	--CElog("CEISetCurVeh Called by: " .. senderID .. ": " .. data, "CEI")
	data = Util.JsonDecode(data)
	tempPCV[players[senderID].name] = data[1]
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
		data = Util.JsonDecode(data)
		local group = data[1]
		if group == nil or group == "" then
			MP.SendChatMessage(senderID, "Group name cannot be blank!")
		else
			local newGroup = "group:" .. group
			local applyGroup = { [newGroup] = { level = 1 } }
			applyStuff(players.database, applyGroup)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveGroup(senderID, data)
	--CElog("CEIRemoveGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local group = data[1]
		loadedDatabases["playerPermissions"] = {}
		for k,v in pairs(players.database) do
			if k == group then
			else
				loadedDatabases["playerPermissions"][k] = v
			end
		end
		M.updateCobaltDatabase("playerPermissions")
		playerPermissions = CobaltDB.new("playerPermissions")
		config.cobalt.groups = {}
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetNewVehiclePermsLevel(senderID, data)
	--CElog("CEISetNewVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetLevel = data[1]
		if targetLevel == nil or targetLevel == "" then
			MP.SendChatMessage(senderID, "Level cannot be blank!")
		else
			if CobaltDB.query("permissions", "vehicleCap", targetLevel) then
				return
			else
				CobaltDB.set("permissions", "vehicleCap", targetLevel, 1)
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveVehiclePermsLevel(senderID, data)
	--CElog("CEIRemoveVehiclePermsLevel Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetLevel = tostring(data[1])
		if CobaltDB.query("permissions", "vehicleCap", targetLevel) then
			CobaltDB.set("permissions", "vehicleCap", targetLevel, nil)
		else
			return
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetVehiclePerms(senderID, data)
	--CElog("CEISetVehiclePerms Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetLevel = data[1]
		local targetVehicles = tonumber(data[2])
		CobaltDB.set("permissions", "vehicleCap", targetLevel, targetVehicles)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetGroup(senderID, data)
	--CElog("CEISetGroup Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local name
		if tonumber(data[1]) then
			local targetID = tonumber(data[1])
			name = players[targetID].name
		else
			name = data[1]
		end
		local group = data[2]
		local player = players.getPlayerByName(name)
		if player then
			if group == "none" then
				players.database[name].group = nil
			elseif players.database[group]:exists() then
				if players[senderID].permissions.level >= (players.database[group].level or 0) then
					players.database[name].group = string.gsub(group, "group:", "")
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. string.gsub(group, "group:", "") .. " because it exceeds your own!")
				end
			end
		else
			if group == "none" then
				players.database[name].group = nil
			elseif players.database[group]:exists() then
				if players[senderID].permissions.level >= (players.database[group].level or 0) then
					players.database[name].group = string.gsub(group, "group:", "")
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. string.gsub(group, "group:", "") .. " because it exceeds your own!")
				end
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

function CEISetGroupPerms(senderID, data)
	--CElog("CEISetGroupPerms Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local group = data[1]
		local permission = data[2]
		local value = data[3]
		if permission == "level" then
			if players[senderID].permissions.level <= tonumber(value) then
				MP.SendChatMessage(senderID, "Cannot set " .. group .. "'s level to " .. value .. " because it exceeds your own!")
			else
				players.database[group].level = tonumber(value)
			end
		elseif permission == "UI" then
			if players[senderID].permissions.UI <= tonumber(value) then
				MP.SendChatMessage(senderID, "Cannot set " .. group .. "'s UI Level to " .. value .. " because it exceeds your own!")
			else
				players.database[group].UI = tonumber(value)
			end
		elseif tonumber(value) then
			if tonumber(value) >= 0 then
				players.database[group][permission] = tonumber(value)
			elseif tonumber(value) < 0 then
				return
			end
		elseif value == "null" then
			players.database[group][permission] = nil
		else
			players.database[group][permission] = value
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetUIPerm(senderID, data)
	--CElog("CEISetUIPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "admin" or players[senderID].permissions.UI > 2 then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local player = players.getPlayerByName(targetName)
		local UIPermLvl = tonumber(data[2])
		if player then
			if players[senderID].permissions.UI <= UIPermLvl then
				MP.SendChatMessage(senderID, "Cannot set " .. targetName .. "'s UI Level to " .. UIPermLvl .. " because it exceeds your own!")
			else
				players.database[targetName].UI = UIPermLvl
				tempPlayers[targetName].tempUIPermLevel = players[player.playerID].permissions.UI
				CobaltDB.set("playersDB/" .. targetName, "UI", "value", UIPermLvl)
			end
		else
			if players[senderID].permissions.UI <= UIPermLvl then
				MP.SendChatMessage(senderID, "Cannot set " .. targetName .. "'s UI Level to " .. UIPermLvl .. " because it exceeds your own!")
			else
				CobaltDB.set("playersDB/" .. targetName, "UI", "value", UIPermLvl)
				players.database[targetName].UI = UIPermLvl
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

function CEISetPerm(senderID, data)
	--CElog("CEISetPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local player = players.getPlayerByName(targetName)
		local permLvl = tonumber(data[2])
		if player then
			if players[senderID].permissions.level <= permLvl then
				MP.SendChatMessage(senderID, "Cannot set " .. targetName .. "'s level to " .. permLvl .. " because it exceeds your own!")
			else
				CC.setperm(players[senderID], targetName, permLvl)
				tempPlayers[targetName].tempPermLevel = players[player.playerID].permissions.level
				CobaltDB.set("playersDB/" .. targetName, "level", "value", permLvl)
			end
		else
			if players[senderID].permissions.level <= permLvl then
				MP.SendChatMessage(senderID, "Cannot set " .. targetName .. "'s level to " .. permLvl .. " because it exceeds your own!")
			else
				CobaltDB.set("playersDB/" .. targetName, "level", "value", permLvl)
				players.database[targetName].level = permLvl
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

function CEISetTempUIPerm(senderID, data)
	--CElog("CEISetTempUIPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "admin" or players[senderID].permissions.UI > 2 then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local UIPermLvl = tonumber(data[2])
		tempPlayers[targetName].tempUIPermLevel = UIPermLvl
	end
end


function CEISetTempPerm(senderID, data)
	--CElog("CEISetTempPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local permLvl = tonumber(data[2])
		tempPlayers[targetName].tempPermLevel = permLvl
	end
end

function CEISetCfg(senderID, data)
	--CElog("CEISetCfg Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = data[2]
		if tonumber(value) then
			value = tonumber(value)
		end
		if key == "Debug" then
			if value == true then
				MP.Set(0, true)
				config.server.debug = true
				writeCfg("ServerConfig.toml", key, true)
			elseif value == false then
				MP.Set(0, false)
				config.server.debug = false
				writeCfg("ServerConfig.toml", key, false)
			end
		elseif key == "Private" then
			if value == true then 
				MP.Set(1, true)
				config.server.private = true
				writeCfg("ServerConfig.toml", key, true)
			elseif value == false then
				MP.Set(1, false)
				config.server.private = false
				writeCfg("ServerConfig.toml", key, false)
			end
		elseif key == "MaxCars" then
			if value < 0 then
				return
			end
			MP.Set(2, value)
			config.server.maxCars = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "MaxPlayers" then
			if value < 0 then
				return
			end
			MP.Set(3, value)
			config.server.maxPlayers = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Map" then
			if value == nil then
				return
			end
			MP.Set(4, value)
			config.server.map = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Name" then
			if value == nil then
				return
			end
			MP.Set(5, value)
			config.server.name = value
			writeCfg("ServerConfig.toml", key, value)
		elseif key == "Description" then
			if value == nil then
				return
			end
			MP.Set(6, value)
			config.server.description = value
			writeCfg("ServerConfig.toml", key, value)
		else
			return nil
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetMaxActivePlayers(senderID, data)
	--CElog("CEISetMaxActivePlayers Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		data = tonumber(data[1])
		CobaltDB.set("config", "maxActivePlayers", "value", data)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveVehicle(senderID, data)
	--CElog("CEIRemoveVehicle Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local tempPlayerID = tonumber(data[1])
		local tempVehicleID = tonumber(data[2])
		local reason = data[3]
		if reason == "" or reason == nil then
			reason = "No reason specified"
		end
		if players[tonumber(senderID)].permissions.level < players[tonumber(data[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(data[1])].name .. "!")
		else
			MP.RemoveVehicle(tempPlayerID, tempVehicleID)
			MP.SendChatMessage(tempPlayerID, "Your vehicle was deleted for: " .. reason)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIVoteKick(senderID, data)
	--CElog("CEIVoteKick Called by: " .. senderID .. ": " .. data, "CEI")
	data = Util.JsonDecode(data)
	local targetName = data[1]
	local player = players.getPlayerByName(targetName)
	local voter = players[tonumber(senderID)].name
	if players[tonumber(senderID)].permissions.level < players[player.playerID].permissions.level then
		MP.SendChatMessage(senderID, "You cannot vote for " ..  targetName .. "!")
	else
		if tempPlayers[voter].votedFor[targetName] == false or tempPlayers[voter].votedFor[targetName] == nil then
			if tempPlayers[targetName].kickVotes == nil then
				tempPlayers[targetName].kickVotes = 1
			else
				tempPlayers[targetName].kickVotes = tempPlayers[targetName].kickVotes + 1
			end
			tempPlayers[voter].votedFor[targetName] = true
			MP.SendChatMessage(-1, voter .. " voted to kick " .. targetName)
		else
			MP.SendChatMessage(senderID, "You cannot vote for " ..  targetName .. " more than once!")
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIKick(senderID, data)
	--CElog("CEIKick Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local target = players.getPlayerByName(data[1])
		local reason = data[2]
		if reason == "" or reason == nil then
			reason = "No reason specified"
		end
		if players[tonumber(senderID)].permissions.level < target.permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  target.name .. "!")
		else
			target:kick(reason)
			MP.SendChatMessage(-1, target.name .. " was kicked for: " .. reason)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIUnban(senderID, data)
	--CElog("CEIUnban Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		MP.SendChatMessage(-1, targetName .. " was unbanned")
		players.database[targetName].banned = false
		players.database[targetName].banReason = nil
		local beammp = CobaltDB.query("playersDB/" .. targetName, "beammp", "value")
		CobaltDB.set("playersDB/" .. targetName, "banned", "value", false)
		if beammp then
			CobaltDB.set("playersDB/" .. beammp, "banned", "value", false)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIBan(senderID, data)
	--CElog("CEIBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local reason = data[2]
		if reason == "" or reason == nil then
			reason = "No reason specified"
		end
		
		
		local player = players.getPlayerByName(targetName)
		if player then
			if players[tonumber(senderID)].permissions.level < players[player.playerID].permissions.level then
				MP.SendChatMessage(senderID, "You cannot affect " ..  targetName .. "!")
			else
				CC.ban(players[senderID], targetName, reason)
				MP.SendChatMessage(-1, targetName .. " was banned for: " .. reason)
			end
		else
			players.database[targetName].banned = true
			players.database[targetName].banReason = reason
			MP.SendChatMessage(-1, targetName .. " was banned for: " .. reason)
		end
		local beammp = CobaltDB.query("playersDB/" .. targetName, "beammp", "value")
		CobaltDB.set("playersDB/" .. targetName, "banned", "value", true)
		CobaltDB.set("playersDB/" .. targetName, "banReason", "value", reason)
		if beammp then
			CobaltDB.set("playersDB/" .. beammp, "banned", "value", true)
			CobaltDB.set("playersDB/" .. beammp, "banReason", "value", reason)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEITempBan(senderID, data)
	--CElog("CEITempBan Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local length = data[2]
		local reason = data[3]
		if tonumber(length) then
			if reason == "" or reason == nil then
				reason = "No reason specified"
			end
			local player = players.getPlayerByName(targetName)
			if player then
				if players[tonumber(senderID)].permissions.level < players[player.playerID].permissions.level then
					MP.SendChatMessage(senderID, "You cannot affect " ..  targetName .. "!")
				else
					CobaltDB.set("playersDB/" .. targetName, "tempBan", "value", length * 86400 + os.time())
					CC.kick(players[senderID], targetName, "tempBan for " .. string.format("%.3f", length) .. " days for: " .. reason)
					MP.SendChatMessage(-1, targetName .. " was tempBanned for " .. string.format("%.3f", length) .. " days for: " .. reason)
				end
			else
				CobaltDB.new("playersDB/" .. targetName)
				CobaltDB.set("playersDB/" .. targetName, "tempBan", "value", length * 86400 + os.time())
				if length > 0 then
					players.database[targetName].banReason = reason
					MP.SendChatMessage(-1, targetName .. " was tempBanned for " .. string.format("%.3f", length) .. " days for: " .. reason)
				else
					players.database[targetName].banReason = nil
					MP.SendChatMessage(-1, targetName .. " was unTempBanned")
				end
			end
		else
			CobaltDB.set("playersDB/" .. targetName, "tempBan", "value", os.time())
			MP.SendChatMessage(-1, targetName .. " was unTempBanned")
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIMute(senderID, data)
	--CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local player = players.getPlayerByName(targetName)
		local reason = data[2]
		if reason == "" or reason == nil then
			reason = "No reason specified"
		end
		if player then
			if players[tonumber(senderID)].permissions.level < players[player.playerID].permissions.level then
				MP.SendChatMessage(senderID, "You cannot affect " ..  targetName .. "!")
			else
				CC.mute(players[senderID], targetName, reason)
				CobaltDB.set("playersDB/" .. targetName, "muted", "value", true)
				CobaltDB.set("playersDB/" .. targetName, "muteReason", "value", reason)
				MP.SendChatMessage(-1, targetName .. " was muted for: " .. reason)
			end
		else
			CobaltDB.set("playersDB/" .. targetName, "muted", "value", true)
			CobaltDB.set("playersDB/" .. targetName, "muteReason", "value", reason)
			players.database[targetName].muted = true
			players.database[targetName].muteReason = reason
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIUnmute(senderID, data)
	--CElog("CEIMute Called by: " .. senderID, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local player = players.getPlayerByName(targetName)
		if player then
			CC.unmute(players[senderID], targetName)
			CobaltDB.set("playersDB/" .. targetName, "muted", "value", false)
			CobaltDB.set("playersDB/" .. targetName, "muteReason", "value", nil)
			MP.SendChatMessage(-1, targetName .. " was unmuted")
		else
			CobaltDB.set("playersDB/" .. targetName, "muted", "value", false)
			CobaltDB.set("playersDB/" .. targetName, "muteReason", "value", nil)
			players.database[targetName].muted = false
			players.database[targetName].muteReason = nil
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIWhitelist(senderID, data)
	--CElog("CEIWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local arguments
		local tempPlayerID
		local targetName
		local action = data[1]
		if data[2] then
			if tonumber(data[2]) then
				tempPlayerID = tonumber(data[2])
				targetName = players[tempPlayerID].name
			else
				targetName = data[2]
			end
			arguments = action .. " " .. targetName
		else
			arguments = action
		end
		local player = players.getPlayerByName(targetName)
		if player then
			CC.whitelist(players[senderID], arguments)
		end
		if action == "add" then
			players.database[targetName].whitelisted = true
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", true)
		end
		if action == "remove" then
			config.cobalt.whitelistedPlayers = {}
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", false)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	end
end

function CEIRaceInclude(senderID, data)
	--CElog("CEIRaceInclude Called by: " .. senderID .. ": " .. data, "CEI")
	playerName = players[senderID].name
	data = Util.JsonDecode(data)
	tempPlayers[playerName].includeInRace = data[1]
end

function CEISetNametagWhitelist(senderID, data)
	--CElog("CEISetNametagWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		if targetName == nil or targetName == "" then
			MP.SendChatMessage(senderID, "Whitelist Name cannot be blank!")
		else
			CobaltDB.set("nametags", "nametagsWhitelist", targetName, targetName)
			local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
			local nametagWhitelistIterator = 0
			config.nametags.whitelist = {}
			for k,v in pairs(nametagsBlockingWhitelist) do
				if k ~= "description" then
					nametagWhitelistIterator = nametagWhitelistIterator + 1
					config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
				end
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "nametags")
	end
end

function CEIRemoveNametagWhitelist(senderID, data)
	--CElog("CEIRemoveNametagWhitelist Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		CobaltDB.set("nametags", "nametagsWhitelist", targetName, nil)
		local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
		local nametagWhitelistIterator = 0
		config.nametags.whitelist = {}
		for k,v in pairs(nametagsBlockingWhitelist) do
			if k ~= "description" then
				nametagWhitelistIterator = nametagWhitelistIterator + 1
				config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "nametags")
	end
end

function CEINametagSetting(senderID, data)
	--CElog("CEINametagSetting Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		if tonumber(data[1]) then
			CobaltDB.set("nametags", "blockingTimeout", "value", tonumber(data[1]))
			config.nametags.settings.blockingTimeout = data[1]
		else
			CobaltDB.set("nametags", "blockingEnabled", "value", data[1])
			config.nametags.settings.blockingEnabled = data[1]
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "nametags")
	end
end

function CEITeleportFrom(senderID, data)
	--CElog("CEITeleportFrom Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		if players[tonumber(senderID)].permissions.level < players[tonumber(data)].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(data)].name .. "!")
		else
			local targetID = tonumber(data)
			MP.TriggerClientEvent(targetID, "rxTeleportFrom", players[senderID].name)
		end
	end
end

function CEISetTeleportPerm(senderID, data)
	--CElog("CEISetTeleportPerm Called by: " .. senderID .. ": " .. data, "CEI")
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" then
		data = Util.JsonDecode(data)
		playerName = data[1]
		teleport[playerName] = data[2]
		CobaltDB.set("playersDB/" .. playerName, "teleport", "value", data[2])
		local player = players.getPlayerByName(playerName)
		if player then
			MP.TriggerClientEventJson(player.playerID, "rxCEItp", { data[2] } )
		end
	end
end

local function onTick(age)
	if environment.controlSun then
		if environment.timePlay == true then
			if environment.ToD >= 0.25 and environment.ToD <= 0.75 then
				environment.ToD = environment.ToD + (environment.nightScale * (1 / environment.dayLength))
			else
				environment.ToD = environment.ToD + (environment.dayScale * (1 / environment.dayLength))
			end
			if environment.ToD > 1 then
				environment.ToD = environment.ToD % 1
			end
		end
	end
	txData()
	logTimer = logTimer + 1
	if logTimer >= logInterval then
		CobaltDB.set("environment", "ToD", "value", environment.ToD)
		logEnvironment()
		logRestrictions()
		logTimer = 0
	end
	if raceCountdown ~= nil then
		raceTimer()
		raceCountdown = raceCountdown - 1
		if raceCountdown == -1 then
			raceCountdown = nil
			raceCountdownStarted = nil
		end
	end
	kickThresh = (MP.GetPlayerCount() - MP.GetPlayerCount() / 3)
	for playerID, player in pairs(players) do 
		if type(playerID) == "number" then
			if playersTable[tonumber(player.playerID)] then
				if tempPlayers[player.name].kickVotes then
					if tempPlayers[player.name].kickVotes > kickThresh then
						MP.SendChatMessage(-1, player.name .. " was VoteKicked with " .. tempPlayers[player.name].kickVotes .. " votes")
						for k,v in pairs(tempPlayers) do
							if tempPlayers[k].votedFor then
								tempPlayers[k].votedFor[player.name] = false
							end
						end
						player:kick("VoteKicked with " .. tempPlayers[player.name].kickVotes .. " votes")
						for k,v in pairs(tempPlayers) do
							tempPlayers[k].kickVotes = 0
						end
					end
				end
			end
		end
	end
end

function raceTimer()
	if raceCountdown == 15 then
		for k,v in pairs(tempPlayers) do
			if v.includeInRace == true then
				MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "3ping")
				local data = { "You have been frozen, prepare to race!", 5 }
				MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
			end
		end
	elseif raceCountdown == 11 then
		for k,v in pairs(tempPlayers) do
			if v.includeInRace == true then
				MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "countTenHorn")
			end
		end
	elseif raceCountdown < 11 and raceCountdown > 0 then
		for k,v in pairs(tempPlayers) do
			if v.includeInRace == true then
				local data = { raceCountdown .. "...", 1, true }
				MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
			end
		end
	elseif raceCountdown == 0 then
		for k,v in pairs(tempPlayers) do
			if v.includeInRace == true then
				local data = { "GO!!!", 3, true }
				MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
				raceStart()
			end
		end
	end
end

function raceStart()
	for k,v in pairs(playersTable) do
		for x,y in pairs(playersTable[k].vehicles) do
			local data = { playersTable[k].playerID, tostring(playersTable[k].vehicles[x].vehicleID), false }
			MP.TriggerClientEventJson(-1, "CEIToggleLock", data)
		end
	end
end

local function sendDelayedMessage(player_id, message)
	for playerID, player in pairs(players) do
		if type(playerID) == "number" then
			if player.connectStage == "connected" then
				MP.SendChatMessage(player_id, message)
			end
		end
	end
end

function onPlayerAuthHandler(player_name, player_role, is_guest, identifiers)
	if CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") == nil or CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") == 0 then
	elseif CobaltDB.query("playersDB/" .. player_name, "tempBan", "value") > os.time() then
		return 1
	end
	tempPlayers[player_name] = {}
	tempPlayers[player_name].tempPermLevel = 0
	tempPlayers[player_name].tempUIPermLevel = 1
	tempPlayers[player_name].tempBanLength = 1
	tempPlayers[player_name].includeInRace = false
	tempPlayers[player_name].votedFor = {}
	tempPCV[player_name] = "none"
end

local function onPlayerConnecting(player)
	CobaltDB.new("playersDB/" .. identifiers.beammp)
	if players.database[player.name].beammp == nil then
		players.database[player.name].beammp = identifiers.beammp
		CobaltDB.set("playersDB/" .. player.name, "beammp", "value", identifiers.beammp)
		CobaltDB.set("playersDB/" .. identifiers.beammp, "beammp", "value", identifiers.beammp)
	end
	if players.database[player.name].ip == nil then
		players.database[player.name].ip = identifiers.ip
		CobaltDB.set("playersDB/" .. player.name, "ip", "value", identifiers.ip)
		CobaltDB.set("playersDB/" .. identifiers.beammp, "ip", "value", identifiers.ip)
	else
		players.database[player.name].ip = identifiers.ip
		CobaltDB.set("playersDB/" .. player.name, "ip", "value", identifiers.ip)
	end
	if players.database[player.name].UI == nil then
		players.database[player.name].UI = 1
		CobaltDB.set("playersDB/" .. player.name, "UI", "value", 1)
	end
	if CobaltDB.query("playersDB/" .. player.name, "banned", "value") == true then
		local reason = CobaltDB.query("playersDB/" .. player.name, "banReason", "value") or "You are banned from this server!"
		MP.DropPlayer(MP.GetPlayerIDByName(player.name), reason)
	end
	if CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == nil then
		CobaltDB.set("playersDB/" .. identifiers.beammp, "banned", "value", false)
	elseif CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == false then
	elseif CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == true then
		local reason = CobaltDB.query("playersDB/" .. identifiers.beammp, "banReason", "value") or "You are banned from this server!"
		CobaltDB.set("playersDB/" .. player.name, "banned", "value", true)
		CobaltDB.set("playersDB/" .. player.name, "banReason", "value", reason)
		players.database[player.name].banned = true
		players.database[player.name].banReason = reason
		MP.DropPlayer(MP.GetPlayerIDByName(player.name), reason)
	end
end

local function onPlayerJoining(player)
	tempPlayers[player.name].tempPermLevel = player.permissions.level
	tempPlayers[player.name].tempPermLevel = player.permissions.UI
	tempPlayers[player.name].player_id = player.playerID
end

local function onPlayerJoin(player)
	if player.permissions.group == "default" then
		players.database[player.name].group = "default"
	end
	if CobaltDB.query("playersDB/" .. player.name, "showCEI", "value") == nil then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", config.cobalt.interface.defaultState)
		showCEI[player.name] = config.cobalt.interface.defaultState
	else
		showCEI[player.name] = CobaltDB.query("playersDB/" .. player.name, "showCEI", "value")
	end
	if CobaltDB.query("playersDB/" .. player.name, "teleport", "value") == nil then
		CobaltDB.set("playersDB/" .. player.name, "teleport", "value", false)
		teleport[player.name] = false
	else
		teleport[player.name] = CobaltDB.query("playersDB/" .. player.name, "teleport", "value")
	end
	MP.TriggerClientEventJson(player.playerID, "rxCEItp", { teleport[player.name] } )
	MP.TriggerClientEventJson(player.playerID, "rxCEIstate", { showCEI[player.name] } )
	CE.delayExec( 3000 , sendDelayedMessage , { player.playerID , "This server uses Cobalt Essentials Interface." } )
	CE.delayExec( 6000 , sendDelayedMessage , { player.playerID , "Use /CEI or /cei in chat to toggle." } )
	for k,v in pairs(player.permissions) do
		CobaltDB.set("playersDB/" .. player.name, k, "value", v)
	end
end

local function onPlayerDisconnect(player)
	local data = tostring(player.playerID)
	playersTable[player.playerID] = nil
	tempPlayers[player.name] = nil
	tempPCV[player.name] = nil
end

local function onVehicleSpawn(player, vehID,  data)
	tempPCV[player.name] = player.playerID .. "-" .. vehID
end

local function onVehicleReset(player, vehID,  data)

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
M.onVehicleReset = onVehicleReset

M.updateCobaltDatabase = updateCobaltDatabase

M.CEI = CEI
M.cei = CEI

return M
