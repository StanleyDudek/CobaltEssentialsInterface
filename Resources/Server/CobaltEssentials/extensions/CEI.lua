--CEI (SERVER) by Dudekahedron, 2023

local M = {}

M.COBALT_VERSION = "1.7.3"

utils.setLogType("CEI",93)

local tomlParser = require("toml")

local loadedDatabases = {}

local playersDatabase
local playersDatabaseCount = {}

local raceCountdown
local raceCountdownStarted

local showCEI = {}
local teleport = {}
local resetExempt = {}

local playersTable = {}

local tempPlayers = {}
local tempPCV = {}

local kickThresh

local logTimer = 0
local logInterval = 30

local config = {}

config.server = {}

config.cobalt = {}

config.cobalt.whitelistedPlayers = {}

config.cobalt.permissions = {}
config.cobalt.permissions.vehiclePerm = {}

config.cobalt.interface = {}
config.cobalt.interface.defaultState_default = true
config.cobalt.interface.playerPermissions_default = 2
config.cobalt.interface.playerPermissionsPlus_default = 3
config.cobalt.interface.config_default = 2
config.cobalt.interface.cobaltEssentials_default = 3
config.cobalt.interface.server_default = 3
config.cobalt.interface.interface_default = 3
config.cobalt.interface.nametags_default = 2
config.cobalt.interface.restrictions_default = 3
config.cobalt.interface.extras_default = 3
config.cobalt.interface.environmentAdmin_default = 3
config.cobalt.interface.environment_default = 2
config.cobalt.interface.sun_default = 2
config.cobalt.interface.weather_default = 2
config.cobalt.interface.gravity_default = 2
config.cobalt.interface.temperature_default = 2
config.cobalt.interface.database_default = 3
config.cobalt.interface.race_default = 2

config.cobalt.groups = {}

config.nametags = {}
config.nametags.whitelist = {}
config.nametags.settings = {}
config.nametags.settings.blockingEnabled_default = false
config.nametags.settings.blockingTimeout_default = 300
config.nametags.settings.whitelist_default = "exampleName"

config.restrictions = {}
config.restrictions.control_default = false
config.restrictions.messageDuration_default = 5
config.restrictions.enabled_default = true
config.restrictions.timeout_default = 10
config.restrictions.title_default = "Vehicle Reset Limiter"
config.restrictions.elapsedMessage_default = "You can now reset your vehicle."
config.restrictions.message_default = "You can reset your vehicle in {secondsLeft} seconds."
config.restrictions.disabledMessage_default = "Vehicle resetting is disabled on this server."

local environmentDefaults = {
	controlSun = false,
	ToD = 0.125,
	timePlay = false,
	dayLength = 1800,
	dayScale = 1,
	nightScale = 2,
	sunAzimuthOverride = 0.0,
	skyBrightness = 40,
	sunSize = 1,
	rayleighScattering = 0.003,
	sunLightBrightness = 1,
	flareScale = 5,
	occlusionScale = 0.025,
	exposure = 1,
	shadowDistance = 1600,
	shadowSoftness = 0.2,
	shadowSplits = 4,
	shadowTexSize = 1024,
	shadowLogWeight = 0.98,
	visibleDistance = 8000,
	moonAzimuth = 0.0,
	moonElevation = 45,
	moonScale = 0.03,
	controlWeather = false,
	fogDensity = 0.001,
	fogDensityOffset = 8.0,
	fogAtmosphereHeight = 400,
	cloudHeight = 2.5,
	cloudHeightOne = 5,
	cloudCover = 0.2,
	cloudCoverOne = 0.2,
	cloudSpeed = 0.2,
	cloudSpeedOne = 0.2,
	cloudExposure = 1.4,
	cloudExposureOne = 1.6,
	rainDrops = 0,
	dropSize = 1,
	dropMinSpeed = 0.1,
	dropMaxSpeed = 0.2,
	precipType = "rain_medium",
	teleportTimeout = 5,
	simSpeed = 1,
	controlSimSpeed = false,
	gravity = -9.81,
	controlGravity = false,
	tempCurveNoon = 38,
	tempCurveDusk = 12,
	tempCurveMidnight = -15,
	tempCurveDawn = 12,
	useTempCurve = false
}

local environment = {}


local descriptions = {
	interface = {
		defaultState = "The state of the interface for new players.",
		playerPermissions = "The level required to access playerPermissions.",
		playerPermissionsPlus = "The level required to access more advanced playerPermissions.",
		config = "The level required to access config.",
		cobaltEssentials = "The level required to access CE settings.",
		server = "The level required to access server settings.",
		interface = "The level required to access interface settings.",
		nametags = "The level required to access nametags settings.",
		restrictions = "The level required to access restrictions settings.",
		extras = "The level required to access extras settings.",
		environmentAdmin = "The level required to access environment reset all.",
		environment = "The level required to access environment settings.",
		sun = "The level required to access sun settings.",
		weather = "The level required to access weather settings.",
		gravity = "The level required to access gravity settings.",
		temperature = "The level required to access temperature settings.",
		database = "The level required to access database settings.",
		race = "The level required to access race countdown."
	},
	restrictions = {
		control = "Are resets controlled?",
		messageDuration = "How long does the toast show?",
		enabled = "Are resets allowed?",
		timeout = "How often can a vehicle be reset (in seconds)?",
		title = "Title shown when resetting is limited or disabled.",
		elapsedMessage = "Message shown when reset timeout has elapsed.",
		message = "Message shown when resetting is limited.",
		disabledMessage = "Message shown when resetting is completely disabled."
	},
	environment = {
		controlSun = "Do we control everyone's sun?",
		ToD = "What is the Time of Day?",
		timePlay = "Does time progress?",
		dayLength = "How long is the day?",
		dayScale = "At what rate does daytime progress?",
		nightScale = "At what rate does nighttime progress?",
		sunAzimuthOverride = "At what position on the horizon does the sun rise and set?",
		skyBrightness = "How bright is the sky?",
		sunSize = "How big is the sun?",
		rayleighScattering = "How much rayleigh scattering?",
		sunLightBrightness = "How bright is the sunlight?",
		flareScale = "How big is the sun lens flare?",
		occlusionScale = "How occluded is the sun lens flare?",
		exposure = "How exposed is the environment?",
		shadowDistance = "How far are the shadows?",
		shadowSoftness = "How soft are the shadows?",
		shadowSplits = "How many splits are there for shadows?",
		shadowTexSize = "What is the texture resolution for shadows?",
		shadowLogWeight = "How much does the log weigh?",
		visibleDistance = "How far can we see?",
		moonAzimuth = "Horizontal position of moon.",
		moonElevation = "Vertical position of moon.",
		moonScale = "How big is the moon?",
		controlWeather = "Do we control everyone's weather?",
		fogDensity = "How thicc is the fog?",
		fogDensityOffset = "How far away is the fog?",
		fogAtmosphereHeight = "How high is the fog?",
		cloudHeight = "How high are the clouds?",
		cloudHeightOne = "How high are the clouds?",
		cloudCover = "How thicc are the clouds?",
		cloudCoverOne = "How thicc are the clouds?",
		cloudSpeed = "How fast are the clouds?",
		cloudSpeedOne = "How fast are the clouds?",
		cloudExposure = "How exposed are the clouds?",
		cloudExposureOne = "How exposed are the clouds?",
		rainDrops = "How many rain drops are there?",
		dropSize = "What size are the drops of precipitation?",
		dropMinSpeed = "What is the minimum speed of precipitation?",
		dropMaxSpeed = "What is the maximum speed of precipitation?",
		precipType = "What type of precipitation do we use?",
		teleportTimeout = "How long between telports?",
		simSpeed = "At what rate does the simulation run?",
		controlSimSpeed = "Do we control everyone's sim speed?",
		gravity = "At what rate do objects fall towards the ground?",
		controlGravity = "Do we control everyone's gravity?",
		tempCurveNoon = "What is the custom temperature in C at noon?",
		tempCurveDusk = "What is the custom temperature in C at dusk?",
		tempCurveMidnight = "What is the custom temperature in C at midnight?",
		tempCurveDawn = "What is the custom temperature in C at dawn?",
		useTempCurve = "Do we use a custom temperature curve?"
	},
	nametags = {
		blockingEnabled = "Are nametags blocked?",
		blockingTimeout = "For how long are nametags blocked?",
		nametagsWhitelist = "Who is immune to nametag blocking?"
	}
}

local environmentJson = CobaltDB.new("environment")
local defaultEnvironmentValues = {
	controlSun = 			{value = environmentDefaults.controlSun},
	ToD = 					{value = environmentDefaults.ToD},
	timePlay = 				{value = environmentDefaults.timePlay},
	dayLength = 			{value = environmentDefaults.dayLength},
	dayScale = 				{value = environmentDefaults.dayScale},
	nightScale = 			{value = environmentDefaults.nightScale},
	sunAzimuthOverride = 	{value = environmentDefaults.sunAzimuthOverride},
	skyBrightness = 		{value = environmentDefaults.skyBrightness},
	sunSize = 				{value = environmentDefaults.sunSize},
	rayleighScattering = 	{value = environmentDefaults.rayleighScattering},
	sunLightBrightness = 	{value = environmentDefaults.sunLightBrightness},
	flareScale = 			{value = environmentDefaults.flareScale},
	occlusionScale = 		{value = environmentDefaults.occlusionScale},
	exposure = 				{value = environmentDefaults.exposure},
	shadowDistance = 		{value = environmentDefaults.shadowDistance},
	shadowSoftness = 		{value = environmentDefaults.shadowSoftness},
	shadowSplits = 			{value = environmentDefaults.shadowSplits},
	shadowTexSize = 		{value = environmentDefaults.shadowTexSize},
	shadowLogWeight = 		{value = environmentDefaults.shadowLogWeight},
	visibleDistance = 		{value = environmentDefaults.visibleDistance},
	moonAzimuth = 			{value = environmentDefaults.moonAzimuth},
	moonElevation = 		{value = environmentDefaults.moonElevation},
	moonScale = 			{value = environmentDefaults.moonScale},
	controlWeather = 		{value = environmentDefaults.controlWeather},
	fogDensity = 			{value = environmentDefaults.fogDensity},
	fogDensityOffset = 		{value = environmentDefaults.fogDensityOffset},
	fogAtmosphereHeight = 	{value = environmentDefaults.fogAtmosphereHeight},
	cloudHeight = 			{value = environmentDefaults.cloudHeight},
	cloudHeightOne = 		{value = environmentDefaults.cloudHeightOne},
	cloudCover = 			{value = environmentDefaults.cloudCover},
	cloudCoverOne = 		{value = environmentDefaults.cloudCoverOne},
	cloudSpeed = 			{value = environmentDefaults.cloudSpeed},
	cloudSpeedOne = 		{value = environmentDefaults.cloudSpeedOne},
	cloudExposure = 		{value = environmentDefaults.cloudExposure},
	cloudExposureOne = 		{value = environmentDefaults.cloudExposureOne},
	rainDrops = 			{value = environmentDefaults.rainDrops},
	dropSize = 				{value = environmentDefaults.dropSize},
	dropMinSpeed = 			{value = environmentDefaults.dropMinSpeed},
	dropMaxSpeed = 			{value = environmentDefaults.dropMaxSpeed},
	precipType = 			{value = environmentDefaults.precipType},
	teleportTimeout = 		{value = environmentDefaults.teleportTimeout},
	simSpeed = 				{value = environmentDefaults.simSpeed},
	controlSimSpeed = 		{value = environmentDefaults.controlSimSpeed},
	gravity = 				{value = environmentDefaults.gravity},
	controlGravity = 		{value = environmentDefaults.controlGravity},
	tempCurveNoon = 		{value = environmentDefaults.tempCurveNoon},
	tempCurveDusk = 		{value = environmentDefaults.tempCurveDusk},
	tempCurveMidnight = 	{value = environmentDefaults.tempCurveMidnight},
	tempCurveDawn = 		{value = environmentDefaults.tempCurveDawn},
	useTempCurve = 			{value = environmentDefaults.useTempCurve}
}

local descriptionsJson = CobaltDB.new("descriptions")
local defaultDescriptions = {

	controlSun =			{description = descriptions.environment.controlSun},
	ToD =					{description = descriptions.environment.ToD},
	timePlay =				{description = descriptions.environment.timePlay},
	dayLength =				{description = descriptions.environment.dayLength},
	dayScale =				{description = descriptions.environment.dayScale},
	nightScale =			{description = descriptions.environment.nightScale},
	sunAzimuthOverride =	{description = descriptions.environment.sunAzimuthOverride},
	skyBrightness =			{description = descriptions.environment.skyBrightness},
	sunSize =				{description = descriptions.environment.sunSize},
	rayleighScattering =	{description = descriptions.environment.rayleighScattering},
	sunLightBrightness =	{description = descriptions.environment.sunLightBrightness},
	flareScale =			{description = descriptions.environment.flareScale},
	occlusionScale =		{description = descriptions.environment.occlusionScale},
	exposure =				{description = descriptions.environment.exposure},
	shadowDistance =		{description = descriptions.environment.shadowDistance},
	shadowSoftness =		{description = descriptions.environment.shadowSoftness},
	shadowSplits =			{description = descriptions.environment.shadowSplits},
	shadowTexSize =			{description = descriptions.environment.shadowTexSize},
	shadowLogWeight =		{description = descriptions.environment.shadowLogWeight},
	visibleDistance =		{description = descriptions.environment.visibleDistance},
	moonAzimuth =			{description = descriptions.environment.moonAzimuth},
	moonElevation =			{description = descriptions.environment.moonElevation},
	moonScale =				{description = descriptions.environment.moonScale},
	controlWeather =		{description = descriptions.environment.controlWeather},
	fogDensity =			{description = descriptions.environment.fogDensity},
	fogDensityOffset =		{description = descriptions.environment.fogDensityOffset},
	fogAtmosphereHeight =	{description = descriptions.environment.fogAtmosphereHeight},
	cloudHeight =			{description = descriptions.environment.cloudHeight},
	cloudHeightOne =		{description = descriptions.environment.cloudHeightOne},
	cloudCover =			{description = descriptions.environment.cloudCover},
	cloudCoverOne =			{description = descriptions.environment.cloudCoverOne},
	cloudSpeed =			{description = descriptions.environment.cloudSpeed},
	cloudSpeedOne =			{description = descriptions.environment.cloudSpeedOne},
	cloudExposure =			{description = descriptions.environment.cloudExposure},
	cloudExposureOne =		{description = descriptions.environment.cloudExposureOne},
	rainDrops =				{description = descriptions.environment.rainDrops},
	dropSize =				{description = descriptions.environment.dropSize},
	dropMinSpeed =			{description = descriptions.environment.dropMinSpeed},
	dropMaxSpeed =			{description = descriptions.environment.dropMaxSpeed},
	precipType =			{description = descriptions.environment.precipType},
	teleportTimeout =		{description = descriptions.environment.teleportTimeout},
	simSpeed =				{description = descriptions.environment.simSpeed},
	controlSimSpeed =		{description = descriptions.environment.controlSimSpeed},
	gravity =				{description = descriptions.environment.gravity},
	controlGravity =		{description = descriptions.environment.controlGravity},
	tempCurveNoon =			{description = descriptions.environment.tempCurveNoon},
	tempCurveDusk =			{description = descriptions.environment.tempCurveDusk},
	tempCurveMidnight =		{description = descriptions.environment.tempCurveMidnight},
	tempCurveDawn =			{description = descriptions.environment.tempCurveDawn},
	useTempCurve =			{description = descriptions.environment.useTempCurve},
	
	control = 				{description = descriptions.restrictions.control},
	messageDuration = 		{description = descriptions.restrictions.messageDuration},
	enabled = 				{description = descriptions.restrictions.enabled},
	timeout = 				{description = descriptions.restrictions.timeout},
	title = 				{description = descriptions.restrictions.title},
	elapsedMessage = 		{description = descriptions.restrictions.elapsedMessage},
	message = 				{description = descriptions.restrictions.message},
	disabledMessage = 		{description = descriptions.restrictions.disabledMessage},
	
	defaultState = 			{description = descriptions.interface.defaultState},
	playerPermissions = 	{description = descriptions.interface.playerPermissions},
	playerPermissionsPlus = {description = descriptions.interface.playerPermissionsPlus},
	config = 				{description = descriptions.interface.config},
	cobaltEssentials = 		{description = descriptions.interface.cobaltEssentials},
	server = 				{description = descriptions.interface.server},
	interface = 			{description = descriptions.interface.interface},
	nametags = 				{description = descriptions.interface.nametags},
	restrictions = 			{description = descriptions.interface.restrictions},
	extras = 				{description = descriptions.interface.extras},
	environmentAdmin = 		{description = descriptions.interface.environmentAdmin},
	environment = 			{description = descriptions.interface.environment},
	sun = 					{description = descriptions.interface.sun},
	weather = 				{description = descriptions.interface.weather},
	gravity = 				{description = descriptions.interface.gravity},
	temperature = 			{description = descriptions.interface.temperature},
	database = 				{description = descriptions.interface.database},
	race = 					{description = descriptions.interface.race}
	
}

local restrictionsJson = CobaltDB.new("restrictions")
local defaultRestrictions = {
	control = 			{value = config.restrictions.control_default},
	messageDuration = 	{value = config.restrictions.messageDuration_default},
	enabled = 			{value = config.restrictions.enabled_default},
	timeout = 			{value = config.restrictions.timeout_default},
	title = 			{value = config.restrictions.title_default},
	elapsedMessage = 	{value = config.restrictions.elapsedMessage_default},
	message = 			{value = config.restrictions.message_default},
	disabledMessage = 	{value = config.restrictions.disabledMessage_default}
}

local vehiclesJson = CobaltDB.new("vehicles")
local defaultVehicles = {
	atv = { level = 1 },
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
	citybus = { level = 1, ["partlevel:citybus_ramplow"] = 1, ["partlevel:citybus_jato_R"] = 1 },
	cones = { level = 1 },
	couch = { level = 1 },
	coupe = { level = 1 },
	covet = { level = 1 },
	delineator = { level = 1 },
	default = { level = 1 },
	drag_tree = { level = 1 },
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
	midtruck = { level = 1 },
	miramar = { level = 1 },
	moonhawk = { level = 1 },
	pessima = { level = 1 },
	piano = { level = 1 },
	pickup = { level = 1 },
	pigeon = { level = 1 },
	racetruck = { level = 1 },
	roadsigns = { level = 1 },
	roamer = { level = 1 },
	rockbouncer = { level = 1 },
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
	blockingEnabled = 	{value = config.nametags.settings.blockingEnabled_default},
	blockingTimeout = 	{value = config.nametags.settings.blockingTimeout_default},
	nametagsWhitelist = {exampleName = config.nametags.settings.whitelist_default}
}

local interfaceJson = CobaltDB.new("interface")
local defaultInterfaceSettings = {
	defaultState = 			{value = config.cobalt.interface.defaultState_default},
	playerPermissions = 	{value = config.cobalt.interface.playerPermissions_default},
	playerPermissionsPlus = {value = config.cobalt.interface.playerPermissionsPlus_default},
	config = 				{value = config.cobalt.interface.config_default},
	cobaltEssentials = 		{value = config.cobalt.interface.cobaltEssentials_default},
	server = 				{value = config.cobalt.interface.server_default},
	interface = 			{value = config.cobalt.interface.interface_default},
	nametags = 				{value = config.cobalt.interface.nametags_default},
	restrictions = 			{value = config.cobalt.interface.restrictions_default},
	extras = 				{value = config.cobalt.interface.extras_default},
	environmentAdmin = 		{value = config.cobalt.interface.environmentAdmin_default},
	environment = 			{value = config.cobalt.interface.environment_default},
	sun = 					{value = config.cobalt.interface.sun_default},
	weather = 				{value = config.cobalt.interface.weather_default},
	gravity = 				{value = config.cobalt.interface.gravity_default},
	temperature = 			{value = config.cobalt.interface.temperature_default},
	database = 				{value = config.cobalt.interface.database_default},
	race = 					{value = config.cobalt.interface.race_default}
}

local CEICommands = {
	CEI = {orginModule = "CEI", level = 0, arguments = 0, sourceLimited = 1, description = "Toggles Cobalt Essentials Interface"},
	cei = {orginModule = "CEI", level = 0, arguments = 0, sourceLimited = 1, description = "Alias for CEI"}
}

local function writeCfg(path, key, value)
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

local function pairsByKeys(t, f)
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

local function updateCobaltDatabase(DBname)
	local filePath = pluginPath .. "/CobaltDB/" .. DBname
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

local function onInit()

	MP.RegisterEvent("requestCEISync","requestCEISync")
	
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
	MP.RegisterEvent("CEISetInterface","CEISetInterface")
	MP.RegisterEvent("CEISetRestrictions","CEISetRestrictions")
	MP.RegisterEvent("CEISetEnv","CEISetEnv")
	MP.RegisterEvent("CEISetTempBan","CEISetTempBan")
	MP.RegisterEvent("CEISetTeleportPerm","CEISetTeleportPerm")
	MP.RegisterEvent("CEISetResetPerm","CEISetResetPerm")
	MP.RegisterEvent("CEITeleportFrom","CEITeleportFrom")
	MP.RegisterEvent("CEIRaceInclude","CEIRaceInclude")
	
	MP.RegisterEvent("txNametagBlockerTimeout","txNametagBlockerTimeout")
	
	MP.RegisterEvent("txPlayersDatabase","txPlayersDatabase")
	MP.CreateEventTimer("txPlayersDatabase", 2000)
	
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
	
	applyStuff(descriptionsJson, defaultDescriptions)
	applyStuff(environmentJson, defaultEnvironmentValues)
	applyStuff(vehiclesJson, defaultVehicles)
	applyStuff(nametagsJson, defaultNametagsSettings)
	applyStuff(interfaceJson, defaultInterfaceSettings)
	applyStuff(restrictionsJson, defaultRestrictions)
	applyStuff(commands, CEICommands)

	for k,v in pairs(players.database) do
		if k == "group:inactive" then
			if not players.database[k].UI then
				players.database[k].UI = 0
			end
		elseif k == "group:guest" then
			if not players.database[k].UI then
				players.database[k].UI = 0
			end
		elseif k == "group:default" then
			if not players.database[k].UI then
				players.database[k].UI = 1
			end
		elseif k == "group:mod" then
			if not players.database[k].UI then
				players.database[k].UI = 2
			end
		elseif k == "group:admin" then
			if not players.database[k].UI then
				players.database[k].UI = 3
			end
		elseif k == "group:owner" then
			if not players.database[k].UI then
				players.database[k].UI = 4
			end
		end
	end
	
	config.cobalt.interface.defaultState = CobaltDB.query("interface", "defaultState", "value")
	config.cobalt.interface.config = CobaltDB.query("interface", "config", "value")
	config.cobalt.interface.playerPermissions = CobaltDB.query("interface", "playerPermissions", "value")
	config.cobalt.interface.playerPermissionsPlus = CobaltDB.query("interface", "playerPermissionsPlus", "value")
	config.cobalt.interface.cobaltEssentials = CobaltDB.query("interface", "cobaltEssentials", "value")
	config.cobalt.interface.server = CobaltDB.query("interface", "server", "value")
	config.cobalt.interface.interface = CobaltDB.query("interface", "interface", "value")
	config.cobalt.interface.nametags = CobaltDB.query("interface", "nametags", "value")
	config.cobalt.interface.restrictions = CobaltDB.query("interface", "restrictions", "value")
	config.cobalt.interface.extras = CobaltDB.query("interface", "extras", "value")
	config.cobalt.interface.environmentAdmin = CobaltDB.query("interface", "environmentAdmin", "value")
	config.cobalt.interface.environment = CobaltDB.query("interface", "environment", "value")
	config.cobalt.interface.sun = CobaltDB.query("interface", "sun", "value")
	config.cobalt.interface.weather = CobaltDB.query("interface", "weather", "value")
	config.cobalt.interface.gravity = CobaltDB.query("interface", "gravity", "value")
	config.cobalt.interface.temperature = CobaltDB.query("interface", "temperature", "value")
	config.cobalt.interface.database = CobaltDB.query("interface", "database", "value")
	config.cobalt.interface.race = CobaltDB.query("interface", "race", "value")
	
	config.restrictions.control = CobaltDB.query("restrictions", "control", "value")
	config.restrictions.messageDuration = CobaltDB.query("restrictions", "messageDuration", "value")
	config.restrictions.enabled = CobaltDB.query("restrictions", "enabled", "value")
	config.restrictions.timeout = CobaltDB.query("restrictions", "timeout", "value")
	config.restrictions.title = CobaltDB.query("restrictions", "title", "value")
	config.restrictions.elapsedMessage = CobaltDB.query("restrictions", "elapsedMessage", "value")
	config.restrictions.message = CobaltDB.query("restrictions", "message", "value")
	config.restrictions.disabledMessage = CobaltDB.query("restrictions", "disabledMessage", "value")
	
	config.nametags.settings.blockingEnabled = CobaltDB.query("nametags", "blockingEnabled", "value")
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
	
	if FS.Exists("Resources/Server/CobaltEssentials/CobaltDB/playersDB") then
		playersDatabase = FS.ListFiles("Resources/Server/CobaltEssentials/CobaltDB/playersDB")
	else
		playersDatabase = {}
	end
	
	for _, v in pairs(playersDatabase) do
		local playerName = string.gsub(v, ".json", "")
		CobaltDB.new("playersDB/" .. playerName)
		tempPlayers[playerName] = {}
	end
end

local function CEI(player)
	if showCEI[player.name] == false then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", true)
		showCEI[player.name] = true
	elseif showCEI[player.name] == true then
		CobaltDB.set("playersDB/" .. player.name, "showCEI", "value", false)
		showCEI[player.name] = false
	end
	MP.TriggerClientEventJson(player.playerID, "rxCEIstate", { showCEI[player.name] } )
end

local function txPlayersResetExempt(player)
	MP.TriggerClientEventJson(player.playerID, "rxPlayersResetExempt", { resetExempt[player.name] } )
end

local function txPlayersGroup(player)
	MP.TriggerClientEvent(player.playerID, "rxPlayerGroup", player.permissions.group)
end

local function txPlayersUIPerm(player)
	MP.TriggerClientEvent(player.playerID, "rxPlayersUIPerm", tostring(player.permissions.UI))
end

function txPlayersDatabase(now)
	for playerID, player in pairs(players) do
		if player.connectStage == "connected" then
			if player.permissions.group == "owner" or player.permissions.group == "admin" or player.permissions.UI >= config.cobalt.interface.database then
				local playersDatabase = FS.ListFiles("Resources/Server/CobaltEssentials/CobaltDB/playersDB")
				local playersDatabaseCompare = 0
				for k,v in pairs(playersDatabase) do
					playersDatabaseCompare = playersDatabaseCompare + 1
				end
				if playersDatabaseCompare ~= playersDatabaseCount[player.name] or now then
					for k,v in pairs(playersDatabase) do
						local playerName = string.gsub(v, ".json", "")
						playersDatabase[k] = {}
						playersDatabase[k].index = k
						local playerPermissions = CobaltDB.getTables("playersDB/" .. playerName)
						playersDatabase[k].permissions = {}
						for a in pairs(playerPermissions) do
							playersDatabase[k].permissions[a] = CobaltDB.query("playersDB/" .. playerName, a, "value")
						end
						if players.database[k].group then
							playersDatabase[k].permissions.group = players.database[k].group
						elseif CobaltDB.query("playersDB/" .. playerName, "group", "value") then
							playersDatabase[k].permissions.group = CobaltDB.query("playersDB/" .. playerName, "group", "value")
						end
						playersDatabase[k].playerName = playerName
						playersDatabase[k].beammp = CobaltDB.query("playersDB/" .. playerName, "beammp", "value")
						playersDatabase[k].ip = CobaltDB.query("playersDB/" .. playerName, "ip", "value")
						if CobaltDB.query("playersDB/" .. playerName, "UI", "value") then
							playersDatabase[k].UI = tonumber(CobaltDB.query("playersDB/" .. playerName, "UI", "value"))
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
						MP.TriggerClientEventJson(playerID, "rxPlayersDatabase", playersDatabase[k])
					end
					playersDatabaseCount[player.name] = playersDatabaseCompare
				end
			end
		end
	end
end

local function txEnvironment(player)
	MP.TriggerClientEventJson(-1, "rxEnvironment", environment)
end

local function txDescriptions(player)
	MP.TriggerClientEventJson(player.playerID, "rxDescriptions", descriptions)
end

local function txPlayersData()
	for playerID, player in pairs(players) do
		local identifiers = MP.GetPlayerIdentifiers(playerID)
		if player.connectStage and player.connectStage ~= 0 then
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
						UI = player.permissions.UI
						},
					teleport = teleport[player.name],
					resetExempt = resetExempt[player.name],
					currentVehicle = tempPCV[player.name],
					vehicles = (player.vehicles or {})
					}
			if identifiers.beammp then
				playersTable[player.playerID].ip = identifiers.ip
				playersTable[player.playerID].beammp = identifiers.beammp
			end
			if tempPlayers[player.name] then
				playersTable[player.playerID].tempBanLength = tempPlayers[player.name].tempBanLength
				playersTable[player.playerID].tempPermLevel = tempPlayers[player.name].tempPermLevel
				playersTable[player.playerID].tempUIPermLevel = tempPlayers[player.name].tempUIPermLevel
				playersTable[player.playerID].includeInRace = tempPlayers[player.name].includeInRace
			else
				playersTable[player.playerID].tempBanLength = 0
				playersTable[player.playerID].tempPermLevel = 1
				playersTable[player.playerID].tempUIPermLevel = 1
				playersTable[player.playerID].includeInRace = false
			end
			for k in pairs(playersTable[player.playerID].vehicles) do
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
	MP.TriggerClientEventJson(-1, "rxPlayersData", playersTable)
end

local function theConfigData()
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
	for k in pairs(vehicleCaps) do
		if string.find(k, "%d+") then
			vehicleCapsLength = vehicleCapsLength + 1
			config.cobalt.permissions.vehicleCap[vehicleCapsLength] = {}
			config.cobalt.permissions.vehicleCap[vehicleCapsLength].level = k
			config.cobalt.permissions.vehicleCap[vehicleCapsLength].vehicles = CobaltDB.query("permissions","vehicleCap",k)
			if not config.cobalt.permissions.vehicleCap[vehicleCapsLength].vehicles then
				config.cobalt.permissions.vehicleCap[vehicleCapsLength].vehicles = 0
			end
		end
		if vehicleCapsLength == 0 then
			vehicles = CobaltDB.new("vehicles")
		end
	end
	local vehiclePerms = CobaltDB.getTables("vehicles")
	local vehiclePermsLength = 0
	local vehiclePermsPartLevelsLength = 0
	for _, v in pairsByKeys(vehiclePerms) do
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
end

local function txConfigData()
	MP.TriggerClientEventJson(-1, "rxConfigData", config)
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
	for k in pairs(nametagsBlockingWhitelist) do
		if k ~= "description" then
			nametagWhitelistIterator = nametagWhitelistIterator + 1
			config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
		end
	end
	MP.TriggerClientEventJson(player.playerID, "rxNametagWhitelisted", { isWhitelisted } )
end

function txNametagBlockerActive()
	local data = CobaltDB.query("nametags","blockingEnabled","value")
	MP.TriggerClientEventJson(-1, "rxNametagBlockerActive", { data } )
end

function txNametagBlockerTimeout(senderID, data)
	data = Util.JsonDecode(data)
	MP.TriggerClientEvent(-1, "rxNametagBlockerTimeout", tostring(data[1]))
end

local function txData()
	txPlayersData()
	txEnvironment()
	txConfigData()
	txNametagBlockerActive()
end

function CEIPreRace(senderID, data)
	if not raceCountdownStarted then
		raceCountdownStarted = true
		raceCountdown = 15
	end
end

function CEISetDefaultState(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		CobaltDB.set("interface", "defaultState", "value", data[1])
		config.cobalt.interface.defaultState = data[1]
	end
end

function CEISetNewVehiclePerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local vehiclePermLevel = tonumber(data[2])
		CobaltDB.set("vehicles", vehicleName, "level", vehiclePermLevel)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveVehiclePerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
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
		updateCobaltDatabase("vehicles")
		vehicles = CobaltDB.new("vehicles")
		config.cobalt.permissions.vehiclePerm = {}
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetNewVehiclePart(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local partName = "partlevel:" .. data[2]
		local partLevel = tonumber(data[3])
		CobaltDB.set("vehicles", vehicleName, partName, partLevel)
	end
end

function CEIRemoveVehiclePart(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local partName = "partlevel:" .. data[2]
		if CobaltDB.query("vehicles", vehicleName, partName) then
			CobaltDB.set("vehicles", vehicleName, partName, nil)
		else
			return
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetVehiclePartLevel(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local vehicleName = data[1]
		local vehiclePartName = "partlevel:" .. data[2]
		local vehiclePartLevel = tonumber(data[3])
		CobaltDB.set("vehicles", vehicleName, vehiclePartName, vehiclePartLevel)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetTempBan(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		data = Util.JsonDecode(data)
		local targetID = tonumber(data[1])
		local name = players[targetID].name
		local playerTempBanLength = tonumber(data[2])
		tempPlayers[name].tempBanLength = playerTempBanLength
	end
end

function CEISetInterface(senderID, data)
	if players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.interface then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = tonumber(data[2])
		if key == "all" then
			for k in pairs(config.cobalt.interface) do
				if k ~= config.cobalt.interface.defaultState then
					config.cobalt.interface[k] = config.cobalt.interface[k .. "_default"]
					CobaltDB.set("interface", k, "value", config.cobalt.interface[k .. "_default"])
				end
			end
		elseif value == "default" then
			config.cobalt.interface[key] = config.cobalt.interface[key .. "_default"]
			CobaltDB.set("interface", key, "value", config.cobalt.interface[key .. "_default"])
		else
			config.cobalt.interface[key] = value
			CobaltDB.set("interface", key, "value", value)
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

function CEISetRestrictions(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.restrictions then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = data[2]
		if key == "all" then
			for k in pairs(config.restrictions) do
				config.restrictions[k] = config.restrictions[k .. "_default"]
				CobaltDB.set("restrictions", k, "value", config.restrictions[k .. "_default"])
			end
		elseif value == "default" then
			config.restrictions[key] = config.restrictions[key .. "_default"]
			CobaltDB.set("restrictions", key, "value", config.restrictions[key .. "_default"])
		else
			config.restrictions[key] = value
			CobaltDB.set("restrictions", key, "value", value)
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.environment then
		data = Util.JsonDecode(data)
		local key = data[1]
		local value = data[2]
		if key == "allWeather" then
			if players[senderID].permissions.UI >= config.cobalt.interface.environmentAdmin then
				environment.controlWeather = environmentDefaults.controlWeather
			end
			environment.fogDensity = environmentDefaults.fogDensity
			environment.fogDensityOffset = environmentDefaults.fogDensityOffset
			environment.fogAtmosphereHeight = environmentDefaults.fogAtmosphereHeight
			environment.cloudHeight = environmentDefaults.cloudHeight
			environment.cloudHeightOne = environmentDefaults.cloudHeightOne
			environment.cloudCover = environmentDefaults.cloudCover
			environment.cloudCoverOne = environmentDefaults.cloudCoverOne
			environment.cloudSpeed = environmentDefaults.cloudSpeed
			environment.cloudSpeedOne = environmentDefaults.cloudSpeedOne
			environment.cloudExposure = environmentDefaults.cloudExposure
			environment.cloudExposureOne = environmentDefaults.cloudExposureOne
			environment.rainDrops = environmentDefaults.rainDrops
			environment.dropSize = environmentDefaults.dropSize
			environment.dropMinSpeed = environmentDefaults.dropMinSpeed
			environment.dropMaxSpeed = environmentDefaults.dropMaxSpeed
			environment.precipType = environmentDefaults.precipType
		elseif key == "allSun" then
			if players[senderID].permissions.UI >= config.cobalt.interface.environmentAdmin then
				environment.controlSun = environmentDefaults.controlSun
			end
			environment.ToD = environmentDefaults.ToD
			environment.timePlay = environmentDefaults.timePlay
			environment.dayScale = environmentDefaults.dayScale
			environment.dayLength = environmentDefaults.dayLength
			environment.nightScale = environmentDefaults.nightScale
			environment.sunAzimuthOverride = environmentDefaults.sunAzimuthOverride
			environment.skyBrightness = environmentDefaults.skyBrightness
			environment.sunSize = environmentDefaults.sunSize
			environment.rayleighScattering = environmentDefaults.rayleighScattering
			environment.sunLightBrightness = environmentDefaults.sunLightBrightness
			environment.flareScale = environmentDefaults.flareScale
			environment.occlusionScale = environmentDefaults.occlusionScale
			environment.exposure = environmentDefaults.exposure
			environment.shadowDistance = environmentDefaults.shadowDistance
			environment.shadowSoftness = environmentDefaults.shadowSoftness
			environment.shadowSplits = environmentDefaults.shadowSplits
			environment.shadowTexSize = environmentDefaults.shadowTexSize
			environment.shadowLogWeight = environmentDefaults.shadowLogWeight
			environment.visibleDistance = environmentDefaults.visibleDistance
			environment.moonAzimuth = environmentDefaults.moonAzimuth
			environment.moonElevation = environmentDefaults.moonElevation
			environment.moonScale = environmentDefaults.moonScale
		elseif key == "all" then
			for k in pairs(environment) do
				if not string.find(k, "default") and not string.find(k, "description") then
					environment[k] = environmentDefaults[k]
				end
			end
		elseif value == "default" then
			environment[key] = environmentDefaults[key]
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		local tempData = Util.JsonDecode(data)
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(tempData[1])].name .. "!")
		else
			MP.TriggerClientEvent(-1, "CEIToggleIgnition", data)
		end
	end
end

function CEIToggleLock(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		local tempData = Util.JsonDecode(data)
		if players[tonumber(senderID)].permissions.level < players[tonumber(tempData[1])].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(tempData[1])].name .. "!")
		else
			MP.TriggerClientEvent(-1, "CEIToggleLock", data)
		end
	end
end

function CEIToggleRaceLock(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		MP.TriggerClientEvent(-1, "CEIToggleLock", data)
	end
end

function CEISetCurVeh(senderID, data)
	data = Util.JsonDecode(data)
	tempPCV[players[senderID].name] = data[1]
end

function CEIStop(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner"  or players[senderID].permissions.UI >= config.cobalt.interface.server then
		MP.SendChatMessage(-1, "Good-bye!")
		exit()
	end
end

function CEISetNewGroup(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local group = data[1]
		loadedDatabases["playerPermissions"] = {}
		for k,v in pairs(players.database) do
			if k == group then
			else
				loadedDatabases["playerPermissions"][k] = v
			end
		end
		updateCobaltDatabase("playerPermissions")
		playerPermissions = CobaltDB.new("playerPermissions")
		config.cobalt.groups = {}
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetNewVehiclePermsLevel(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		local targetLevel = data[1]
		local targetVehicles = tonumber(data[2])
		CobaltDB.set("permissions", "vehicleCap", targetLevel, targetVehicles)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEISetGroup(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
				players.database[player.name].group = nil
				CobaltDB.set("playersDB/" .. player.name, "group", "value", nil)
			elseif players.database[group]:exists() then
				if players[senderID].permissions.level >= (players.database[group].level or 0) then
					players.database[player.name].group = string.gsub(group, "group:", "")
					CobaltDB.set("playersDB/" .. player.name, "group", "value", string.gsub(group, "group:", ""))
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. string.gsub(group, "group:", "") .. " because it exceeds your own!")
				end
			end
			txPlayersGroup(player)
		else
			if group == "none" then
				players.database[name].group = nil
				CobaltDB.set("playersDB/" .. name, "group", "value", nil)
				CobaltDB.set("playersDB/" .. name, "UI", "value", 1)
				CobaltDB.set("playersDB/" .. name, "level", "value", 1)
			elseif players.database[group]:exists() then
				if players[senderID].permissions.level >= (players.database[group].level or 0) then
					CobaltDB.new("playersDB/" .. name)
					players.database[name].group = string.gsub(group, "group:", "")
					CobaltDB.set("playersDB/" .. name, "group", "value", string.gsub(group, "group:", ""))
				else
					MP.SendChatMessage(senderID, "Cannot set " .. name .. "'s group to " .. string.gsub(group, "group:", "") .. " because it exceeds your own!")
				end
			end
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		txPlayersDatabase(true)
	end
end

function CEISetGroupPerms(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		data = Util.JsonDecode(data)
		local group = data[1]
		local permission = data[2]
		local value = data[3]
		if permission == "level" then
			if players[senderID].permissions.level <= tonumber(value) then
				MP.SendChatMessage(senderID, "Cannot set " .. group .. "'s level to " .. value .. " because it exceeds your own!")
			else
				players.database[group].level = tonumber(value)
				for k, v in pairs(players.database) do
					if not string.find(k, "group:") then
						if tempPlayers[k] then
							tempPlayers[k].tempPermLevel = players.database[group].level
						end
					end
				end
			end
		elseif permission == "UI" then
			if players[senderID].permissions.UI <= tonumber(value) then
				MP.SendChatMessage(senderID, "Cannot set " .. group .. "'s UI Level to " .. value .. " because it exceeds your own!")
			else
				players.database[group].UI = tonumber(value)
				for k, v in pairs(players.database) do
					if not string.find(k, "group:") then
						if tempPlayers[k] then
							tempPlayers[k].tempUIPermLevel = players.database[group].UI
						end
					end
				end
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
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		txPlayersDatabase(true)
	end
end

function CEISetUIPerm(senderID, data)
	if players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "admin" or players[senderID].permissions.UI >= config.cobalt.interface.interface then
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
			txPlayersUIPerm(player)
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
		txPlayersDatabase(true)
	end
end

function CEISetPerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
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
		txPlayersDatabase(true)
	end
end

function CEISetTempUIPerm(senderID, data)
	if players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "admin" or players[senderID].permissions.UI >= config.cobalt.interface.interface then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local UIPermLvl = tonumber(data[2])
		tempPlayers[targetName].tempUIPermLevel = UIPermLvl
		txPlayersDatabase(true)
	end
end

function CEISetTempPerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		local permLvl = tonumber(data[2])
		tempPlayers[targetName].tempPermLevel = permLvl
	end
end

function CEISetCfg(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.server then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.UI >= config.cobalt.interface.cobaltEssentials then
		data = Util.JsonDecode(data)
		data = tonumber(data[1])
		CobaltDB.set("config", "maxActivePlayers", "value", data)
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	end
end

function CEIRemoveVehicle(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
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
		txPlayersDatabase(true)
	end
end

function CEIBan(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
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
		txPlayersDatabase(true)
	end
end

function CEITempBan(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
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
		txPlayersDatabase(true)
	end
end

function CEIMute(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		txPlayersDatabase(true)
	end
end

function CEIUnmute(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		txPlayersDatabase(true)
	end
end

function CEIWhitelist(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
			CobaltDB.new("playersDB/" .. targetName)
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", true)
		elseif action == "remove" then
			config.cobalt.whitelistedPlayers = {}
			players.database[targetName].whitelisted = false
			CobaltDB.new("playersDB/" .. targetName)
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", false)
		else
			CC.whitelist(players[senderID], arguments)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		txPlayersDatabase(true)
	end
end

function CEIRaceInclude(senderID, data)
	data = Util.JsonDecode(data)
	local playerName = players[senderID].name
	if data[2] then
		tempPlayers[data[2]].includeInRace = data[1]
		MP.TriggerClientEventJson(MP.GetPlayerIDByName(data[2]), "rxCEIrace", { data[1] } )
	else
		tempPlayers[playerName].includeInRace = data[1]
	end
end

function CEISetNametagWhitelist(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		if targetName == nil or targetName == "" then
			MP.SendChatMessage(senderID, "Whitelist Name cannot be blank!")
		else
			CobaltDB.set("nametags", "nametagsWhitelist", targetName, targetName)
			local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
			local nametagWhitelistIterator = 0
			config.nametags.whitelist = {}
			for k in pairs(nametagsBlockingWhitelist) do
				if k ~= "description" then
					nametagWhitelistIterator = nametagWhitelistIterator + 1
					config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
				end
			end
		end
		local player = players.getPlayerByName(targetName)
		if player then
			txNametagWhitelisted(player)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "nametags")
	end
end

function CEIRemoveNametagWhitelist(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
		data = Util.JsonDecode(data)
		local targetName = data[1]
		CobaltDB.set("nametags", "nametagsWhitelist", targetName, nil)
		local nametagsBlockingWhitelist = CobaltDB.getTable("nametags", "nametagsWhitelist")
		local nametagWhitelistIterator = 0
		config.nametags.whitelist = {}
		for k in pairs(nametagsBlockingWhitelist) do
			if k ~= "description" then
				nametagWhitelistIterator = nametagWhitelistIterator + 1
				config.nametags.whitelist[nametagWhitelistIterator] = nametagsBlockingWhitelist[k]
			end
		end
		local player = players.getPlayerByName(targetName)
		if player then
			txNametagWhitelisted(player)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "nametags")
	end
end

function CEINametagSetting(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
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
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod"  or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissions then
		if players[tonumber(senderID)].permissions.level < players[tonumber(data)].permissions.level then
			MP.SendChatMessage(senderID, "You cannot affect " ..  players[tonumber(data)].name .. "!")
		else
			local targetID = tonumber(data)
			MP.TriggerClientEvent(targetID, "rxTeleportFrom", players[senderID].name)
		end
	end
end

function CEISetResetPerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		data = Util.JsonDecode(data)
		playerName = data[1]
		resetExempt[playerName] = data[2]
		CobaltDB.set("playersDB/" .. playerName, "resetExempt", "value", data[2])
		txPlayersDatabase(true)
		local player = players.getPlayerByName(playerName)
		if player then
			txPlayersResetExempt(player)
		end
	end
end

function CEISetTeleportPerm(senderID, data)
	if players[senderID].permissions.group == "admin" or players[senderID].permissions.group == "owner" or players[senderID].permissions.group == "mod" or players[senderID].permissions.UI >= config.cobalt.interface.playerPermissionsPlus then
		data = Util.JsonDecode(data)
		playerName = data[1]
		teleport[playerName] = data[2]
		CobaltDB.set("playersDB/" .. playerName, "teleport", "value", data[2])
		txPlayersDatabase(true)
		local player = players.getPlayerByName(playerName)
		if player then
			MP.TriggerClientEventJson(player.playerID, "rxCEItp", { data[2] } )
		end
	end
end

local function onTick(age)
	playTime()
	logEnvironment()
	raceTimer()
	checkVoteKick()
	theConfigData()
	txData()
end

function logEnvironment()
	logTimer = logTimer + 1
	if logTimer >= logInterval then
		CobaltDB.set("environment", "ToD", "value", environment.ToD)
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
		logTimer = 0
	end
end

function playTime()
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
end

function checkVoteKick()
	kickThresh = (MP.GetPlayerCount() - MP.GetPlayerCount() / 3)
	for playerID, player in pairs(players) do 
		if player.connectStage == "connected" then
			if playersTable[tonumber(player.playerID)] then
				if tempPlayers[player.name].kickVotes then
					if tempPlayers[player.name].kickVotes > kickThresh then
						MP.SendChatMessage(-1, player.name .. " was VoteKicked with " .. tempPlayers[player.name].kickVotes .. " votes")
						for k in pairs(tempPlayers) do
							if tempPlayers[k].votedFor then
								tempPlayers[k].votedFor[player.name] = false
							end
						end
						player:kick("VoteKicked with " .. tempPlayers[player.name].kickVotes .. " votes")
						for k in pairs(tempPlayers) do
							tempPlayers[k].kickVotes = 0
						end
					end
				end
			end
		end
	end
end

function raceTimer()
	if raceCountdown ~= nil then
		if raceCountdown == 15 then
			for _, v in pairs(tempPlayers) do
				if v.includeInRace == true then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "3ping")
					local data = { "You have been frozen, prepare to race!", 5 }
					MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
				end
			end
		elseif raceCountdown == 11 then
			for _, v in pairs(tempPlayers) do
				if v.includeInRace == true then
					MP.TriggerClientEvent(v.player_id, "CEIRaceCountSound", "countTenHorn")
				end
			end
		elseif raceCountdown < 11 and raceCountdown > 0 then
			for _, v in pairs(tempPlayers) do
				if v.includeInRace == true then
					local data = { raceCountdown .. "...", 1, true }
					MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
				end
			end
		elseif raceCountdown == 0 then
			for _, v in pairs(tempPlayers) do
				if v.includeInRace == true then
					local data = { "GO!!!", 3, true }
					MP.TriggerClientEventJson(v.player_id, "CEIRaceCountdown", data)
					raceStart()
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

function raceStart()
	for k in pairs(playersTable) do
		for x in pairs(playersTable[k].vehicles) do
			local data = { playersTable[k].playerID, tostring(playersTable[k].vehicles[x].vehicleID), false }
			MP.TriggerClientEventJson(-1, "CEIToggleLock", data)
		end
	end
	for k, v in pairs(tempPlayers) do
		tempPlayers[k].includeInRace = false
	end
	MP.TriggerClientEventJson(-1, "rxCEIrace", { false } )
end

local function sendDelayedMessage(player, message)
	if player then
		if player.connectStage == "connected" then
			MP.SendChatMessage(player.playerID, message)
		end
	end
end

local function onPlayerJoining(player)
	if player then
	
		local identifiers = MP.GetPlayerIdentifiers(player.playerID)
	
		if CobaltDB.query("playersDB/" .. player.name, "tempBan", "value") == nil or CobaltDB.query("playersDB/" .. player.name, "tempBan", "value") == 0 then
		elseif CobaltDB.query("playersDB/" .. player.name, "tempBan", "value") > os.time() then
			return false
		end
		tempPlayers[player.name] = {}
		tempPlayers[player.name].tempPermLevel = 0
		tempPlayers[player.name].tempUIPermLevel = 1
		tempPlayers[player.name].tempBanLength = 1
		tempPlayers[player.name].includeInRace = false
		tempPlayers[player.name].votedFor = {}
		tempPCV[player.name] = "none"
		if isGuest then
			identifiers.beammp = tonumber(player.name:sub(6)) * -1
		end
		if identifiers.beammp then
			CobaltDB.new("playersDB/" .. identifiers.beammp)
			CobaltDB.set("playersDB/" .. identifiers.beammp, "beammp", "value", identifiers.beammp)
			CobaltDB.set("playersDB/" .. identifiers.beammp, "ip", "value", identifiers.ip)

			CobaltDB.set("playersDB/" .. player.name, "beammp", "value", identifiers.beammp)
			CobaltDB.set("playersDB/" .. player.name, "ip", "value", identifiers.ip)
			if CobaltDB.query("playersDB/" .. player.name, "banned", "value") == true then
				local reason = CobaltDB.query("playersDB/" .. player.name, "banReason", "value") or "You are banned from this server!"
				return reason
			end
			if CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == nil then
				CobaltDB.set("playersDB/" .. identifiers.beammp, "banned", "value", false)
			elseif CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == true then
				local reason = CobaltDB.query("playersDB/" .. identifiers.beammp, "banReason", "value") or "You are banned from this server!"
				CobaltDB.set("playersDB/" .. player.name, "banned", "value", true)
				CobaltDB.set("playersDB/" .. player.name, "banReason", "value", reason)
				players.database[player.name].banned = true
				players.database[player.name].banReason = reason
				return reason
			end
		end
		tempPlayers[player.name].tempPermLevel = player.permissions.level
		if player.permissions.UI then
			tempPlayers[player.name].tempUIPermLevel = player.permissions.UI
		else
			CobaltDB.set("playersDB/" .. player.name, "UI", "value", 1)
		end
		tempPlayers[player.name].player_id = player.playerID
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
		if CobaltDB.query("playersDB/" .. player.name, "resetExempt", "value") == nil then
			CobaltDB.set("playersDB/" ..  player.name, "resetExempt", "value", false)
			resetExempt[player.name] = false
		else
			resetExempt[player.name] = CobaltDB.query("playersDB/" .. player.name, "resetExempt", "value")
		end
		for k,v in pairs(player.permissions) do
			CobaltDB.set("playersDB/" .. player.name, k, "value", v)
		end
		playersDatabase = FS.ListFiles("Resources/Server/CobaltEssentials/CobaltDB/playersDB")
		if player.permissions.group == "owner" or player.permissions.group == "admin" or player.permissions.UI >= config.cobalt.interface.database then
			playersDatabaseCount[player.name] = 0
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

function requestCEISync(player_id)
	local name = MP.GetPlayerName(player_id)
	local player = players.getPlayerByName(name)
	if player then
		txDescriptions(player)
		txPlayersGroup(player)
		txPlayersResetExempt(player)
		txPlayersUIPerm(player)
		txNametagWhitelisted(player)
		MP.TriggerClientEventJson(player.playerID, "rxCEItp", { teleport[player.name] } )
		MP.TriggerClientEventJson(player.playerID, "rxCEIstate", { showCEI[player.name] } )
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		CE.delayExec( 5000 , sendDelayedMessage , { player , "This server uses Cobalt Essentials Interface." } )
		CE.delayExec( 6000 , sendDelayedMessage , { player , "Use /CEI or /cei in chat to toggle." } )
	end
end

local function onPlayerDisconnect(player)
	if player then
		playersTable[player.playerID] = nil
		tempPlayers[player.name] = nil
		tempPCV[player.name] = nil
		showCEI[player.name] = nil
		teleport[player.name] = nil
		resetExempt[player.name] = nil
		playersDatabaseCount[player.name] = nil
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

local function onVehicleSpawn(player, vehID,  data)
	if player then
		tempPCV[player.name] = player.playerID .. "-" .. vehID
	end
end

M.applyStuff = applyStuff

M.onInit = onInit
M.onTick = onTick

M.onPlayerJoining = onPlayerJoining

M.onPlayerDisconnect = onPlayerDisconnect
M.onVehicleSpawn = onVehicleSpawn

M.CEI = CEI
M.cei = CEI

return M
