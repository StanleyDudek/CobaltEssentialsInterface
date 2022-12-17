--CEI (SERVER) by Dudekahedron, 2022

local M = {}

M.COBALT_VERSION = "1.7.2"

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
config.cobalt.interface.defaultState_description = "The state of the interface for new players."
config.cobalt.interface.playerPermissions_description = "The level required to access playerPermissions."
config.cobalt.interface.playerPermissionsPlus_description = "The level required to access more advanced playerPermissions."
config.cobalt.interface.config_description = "The level required to access config."
config.cobalt.interface.cobaltEssentials_description = "The level required to access CE settings."
config.cobalt.interface.server_description = "The level required to access server settings."
config.cobalt.interface.interface_description = "The level required to access interface settings."
config.cobalt.interface.nametags_description = "The level required to access nametags settings."
config.cobalt.interface.restrictions_description = "The level required to access restrictions settings."
config.cobalt.interface.extras_description = "The level required to access extras settings."
config.cobalt.interface.environmentAdmin_description = "The level required to access environment reset all."
config.cobalt.interface.environment_description = "The level required to access environment settings."
config.cobalt.interface.sun_description = "The level required to access sun settings."
config.cobalt.interface.weather_description = "The level required to access weather settings."
config.cobalt.interface.gravity_description = "The level required to access gravity settings."
config.cobalt.interface.temperature_description = "The level required to access temperature settings."
config.cobalt.interface.database_description = "The level required to access database settings."
config.cobalt.interface.race_description = "The level required to access race countdown."
config.cobalt.interface.defaultState = ""
config.cobalt.interface.playerPermissions = ""
config.cobalt.interface.playerPermissionsPlus = ""
config.cobalt.interface.config = ""
config.cobalt.interface.cobaltEssentials = ""
config.cobalt.interface.server = ""
config.cobalt.interface.interface = ""
config.cobalt.interface.nametags = ""
config.cobalt.interface.restrictions = ""
config.cobalt.interface.extras = ""
config.cobalt.interface.environmentAdmin = ""
config.cobalt.interface.environment = ""
config.cobalt.interface.sun = ""
config.cobalt.interface.weather = ""
config.cobalt.interface.gravity = ""
config.cobalt.interface.temperature = ""
config.cobalt.interface.database = ""
config.cobalt.interface.race = ""
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
config.resets.control_description = "Are resets controlled?"
config.resets.messageDuration_description = "How long does the toast show?"
config.resets.enabled_description = "Are resets allowed?"
config.resets.timeout_description = "How often can a vehicle be reset (in seconds)?"
config.resets.title_description = "Title shown when resetting is limited or disabled."
config.resets.elapsedMessage_description = "Message shown when reset timeout has elapsed."
config.resets.message_description = "Message shown when resetting is limited."
config.resets.disabledMessage_description = "Message shown when resetting is completely disabled."
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
environment.controlSun_description = "Do we control everyone's sun?"
environment.ToD_description = "What is the Time of Day?"
environment.timePlay_description = "Does time progress?"
environment.dayLength_description = "How long is the day?"
environment.dayScale_description = "At what rate does daytime progress?"
environment.nightScale_description = "At what rate does nighttime progress?"
environment.sunAzimuthOverride_description = "At what position on the horizon does the sun rise and set?"
environment.skyBrightness_description = "How bright is the sky?"
environment.sunSize_description = "How big is the sun?"
environment.rayleighScattering_description = "How much rayleigh scattering?"
environment.sunLightBrightness_description = "How bright is the sunlight?"
environment.flareScale_description = "How big is the sun lens flare?"
environment.occlusionScale_description = "How occluded is the sun lens flare?"
environment.exposure_description = "How exposed is the environment?"
environment.shadowDistance_description = "How far are the shadows?"
environment.shadowSoftness_description = "How soft are the shadows?"
environment.shadowSplits_description = "How many splits are there for shadows?"
environment.shadowTexSize_description = "What is the texture resolution for shadows?"
environment.shadowLogWeight_description = "How much does the log weigh?"
environment.visibleDistance_description = "How far can we see?"
environment.moonAzimuth_description = "Horizontal position of moon."
environment.moonElevation_description = "Vertical position of moon."
environment.moonScale_description = "How big is the moon?"
environment.controlWeather_description = "Do we control everyone's weather?"
environment.fogDensity_description = "How thicc is the fog?"
environment.fogDensityOffset_description = "How far away is the fog?"
environment.fogAtmosphereHeight_description = "How high is the fog?"
environment.cloudHeight_description = "How high are the clouds?"
environment.cloudHeightOne_description = "How high are the clouds?"
environment.cloudCover_description = "How thicc are the clouds?"
environment.cloudCoverOne_description = "How thicc are the clouds?"
environment.cloudSpeed_description = "How fast are the clouds?"
environment.cloudSpeedOne_description = "How fast are the clouds?"
environment.cloudExposure_description = "How exposed are the clouds?"
environment.cloudExposureOne_description = "How exposed are the clouds?"
environment.rainDrops_description = "How many rain drops are there?"
environment.dropSize_description = "What size are the drops of precipitation?"
environment.dropMinSpeed_description = "What is the minimum speed of precipitation?"
environment.dropMaxSpeed_description = "What is the maximum speed of precipitation?"
environment.precipType_description = "What type of precipitation do we use?"
environment.teleportTimeout_description = "How long between telports?"
environment.simSpeed_description = "At what rate does the simulation run?"
environment.controlSimSpeed_description = "Do we control everyone's sim speed?"
environment.gravity_description = "At what rate do objects fall towards the ground?"
environment.controlGravity_description = "Do we control everyone's gravity?"
environment.tempCurveNoon_description = "What is the custom temperature in C at noon?"
environment.tempCurveDusk_description = "What is the custom temperature in C at dusk?"
environment.tempCurveMidnight_description = "What is the custom temperature in C at midnight?"
environment.tempCurveDawn_description = "What is the custom temperature in C at dawn?"
environment.useTempCurve_description = "Do we use a custom temperature curve?"
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
	controlSun = 			{value = environment.controlSun_default, 			description = environment.controlSun_description},
	ToD = 					{value = environment.ToD_default, 					description = environment.ToD_description},
	timePlay = 				{value = environment.timePlay_default, 				description = environment.timePlay_description},
	dayLength = 			{value = environment.dayLength_default, 			description = environment.dayLength_description},
	dayScale = 				{value = environment.dayScale_default, 				description = environment.dayScale_description},
	nightScale = 			{value = environment.nightScale_default, 			description = environment.nightScale_description},
	sunAzimuthOverride = 	{value = environment.sunAzimuthOverride_default, 	description = environment.sunAzimuthOverride_description},
	skyBrightness = 		{value = environment.skyBrightness_default, 		description = environment.skyBrightness_description},
	sunSize = 				{value = environment.sunSize_default, 				description = environment.sunSize_description},
	rayleighScattering = 	{value = environment.rayleighScattering_default, 	description = environment.rayleighScattering_description},
	sunLightBrightness = 	{value = environment.sunLightBrightness_default, 	description = environment.sunLightBrightness_description},
	flareScale = 			{value = environment.flareScale_default, 			description = environment.flareScale_description},
	occlusionScale = 		{value = environment.occlusionScale_default, 		description = environment.occlusionScale_description},
	exposure = 				{value = environment.exposure_default, 				description = environment.exposure_description},
	shadowDistance = 		{value = environment.shadowDistance_default, 		description = environment.shadowDistance_description},
	shadowSoftness = 		{value = environment.shadowSoftness_default, 		description = environment.shadowSoftness_description},
	shadowSplits = 			{value = environment.shadowSplits_default, 			description = environment.shadowSplits_description},
	shadowTexSize = 		{value = environment.shadowTexSize_default, 		description = environment.shadowTexSize_description},
	shadowLogWeight = 		{value = environment.shadowLogWeight_default, 		description = environment.shadowLogWeight_description},
	visibleDistance = 		{value = environment.visibleDistance_default, 		description = environment.visibleDistance_description},
	moonAzimuth = 			{value = environment.moonAzimuth_default, 			description = environment.moonAzimuth_description},
	moonElevation = 		{value = environment.moonElevation_default, 		description = environment.moonElevation_description},
	moonScale = 			{value = environment.moonScale_default, 			description = environment.moonScale_description},
	controlWeather = 		{value = environment.controlWeather_default, 		description = environment.controlWeather_description},
	fogDensity = 			{value = environment.fogDensity_default, 			description = environment.fogDensity_description},
	fogDensityOffset = 		{value = environment.fogDensityOffset_default, 		description = environment.fogDensityOffset_description},
	fogAtmosphereHeight = 	{value = environment.fogAtmosphereHeight_default, 	description = environment.fogAtmosphereHeight_description},
	cloudHeight = 			{value = environment.cloudHeight_default, 			description = environment.cloudHeight_description},
	cloudHeightOne = 		{value = environment.cloudHeightOne_default, 		description = environment.cloudHeightOne_description},
	cloudCover = 			{value = environment.cloudCover_default, 			description = environment.cloudCover_description},
	cloudCoverOne = 		{value = environment.cloudCoverOne_default, 		description = environment.cloudCoverOne_description},
	cloudSpeed = 			{value = environment.cloudSpeed_default, 			description = environment.cloudSpeed_description},
	cloudSpeedOne = 		{value = environment.cloudSpeedOne_default, 		description = environment.cloudSpeedOne_description},
	cloudExposure = 		{value = environment.cloudExposure_default, 		description = environment.cloudExposure_description},
	cloudExposureOne = 		{value = environment.cloudExposureOne_default, 		description = environment.cloudExposureOne_description},
	rainDrops = 			{value = environment.rainDrops_default, 			description = environment.rainDrops_description},
	dropSize = 				{value = environment.dropSize_default, 				description = environment.dropSize_description},
	dropMinSpeed = 			{value = environment.dropMinSpeed_default, 			description = environment.dropMinSpeed_description},
	dropMaxSpeed = 			{value = environment.dropMaxSpeed_default, 			description = environment.dropMaxSpeed_description},
	precipType = 			{value = environment.precipType_default, 			description = environment.precipType_description},
	teleportTimeout = 		{value = environment.teleportTimeout_default, 		description = environment.teleportTimeout_description},
	simSpeed = 				{value = environment.simSpeed_default, 				description = environment.simSpeed_description},
	controlSimSpeed = 		{value = environment.controlSimSpeed_default, 		description = environment.controlSimSpeed_description},
	gravity = 				{value = environment.gravity_default, 				description = environment.gravity_description},
	controlGravity = 		{value = environment.controlGravity_default, 		description = environment.controlGravity_description},
	tempCurveNoon = 		{value = environment.tempCurveNoon_default, 		description = environment.tempCurveNoon_description},
	tempCurveDusk = 		{value = environment.tempCurveDusk_default, 		description = environment.tempCurveDusk_description},
	tempCurveMidnight = 	{value = environment.tempCurveMidnight_default, 	description = environment.tempCurveMidnight_description},
	tempCurveDawn = 		{value = environment.tempCurveDawn_default, 		description = environment.tempCurveDawn_description},
	useTempCurve = 			{value = environment.useTempCurve_default, 			description = environment.useTempCurve_description}
}

local restrictionsJson = CobaltDB.new("restrictions")
local defaultRestrictions = {
	control = 			{value = config.resets.control_default, 		description = config.resets.control_description},
	messageDuration = 	{value = config.resets.messageDuration_default, description = config.resets.messageDuration_description},
	enabled = 			{value = config.resets.enabled_default, 		description = config.resets.enabled_description},
	timeout = 			{value = config.resets.timeout_default, 		description = config.resets.timeout_description},
	title = 			{value = config.resets.title_default, 			description = config.resets.title_description},
	elapsedMessage = 	{value = config.resets.elapsedMessage_default, 	description = config.resets.elapsedMessage_description},
	message = 			{value = config.resets.message_default, 		description = config.resets.message_description},
	disabledMessage = 	{value = config.resets.disabledMessage_default, description = config.resets.disabledMessage_description}
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
	citybus = { level = 1, ["partlevel:citybus_ramplow"] = 1 },
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
	blockingEnabled = 	{value = defaultNametagsBlockingEnabled, 			description = "Are nametags blocked?"},
	blockingTimeout = 	{value = defaultNametagsBlockingTimeout, 			description = "For how long are nametags blocked?"},
	nametagsWhitelist = {exampleName = defaultNametagsBlockingWhitelist, 	description = "Who is immune to nametag blocking?"}
}

local interfaceJson = CobaltDB.new("interface")
local defaultInterfaceSettings = {
	defaultState = 			{value = config.cobalt.interface.defaultState_default, 					description = config.cobalt.interface.defaultState_description},
	playerPermissions = 	{value = config.cobalt.interface.playerPermissions_default, 	description = config.cobalt.interface.playerPermissions_description},
	playerPermissionsPlus = {value = config.cobalt.interface.playerPermissionsPlus_default, description = config.cobalt.interface.playerPermissionsPlus_description},
	config = 				{value = config.cobalt.interface.config_default, 				description = config.cobalt.interface.config_description},
	cobaltEssentials = 		{value = config.cobalt.interface.cobaltEssentials_default, 		description = config.cobalt.interface.cobaltEssentials_description},
	server = 				{value = config.cobalt.interface.server_default, 				description = config.cobalt.interface.server_description},
	interface = 			{value = config.cobalt.interface.interface_default, 			description = config.cobalt.interface.interface_description},
	nametags = 				{value = config.cobalt.interface.nametags_default, 				description = config.cobalt.interface.nametags_description},
	restrictions = 			{value = config.cobalt.interface.restrictions_default, 			description = config.cobalt.interface.restrictions_description},
	extras = 				{value = config.cobalt.interface.extras_default, 				description = config.cobalt.interface.extras_description},
	environmentAdmin = 		{value = config.cobalt.interface.environmentAdmin_default, 		description = config.cobalt.interface.environmentAdmin_description},
	environment = 			{value = config.cobalt.interface.environment_default, 			description = config.cobalt.interface.environment_description},
	sun = 					{value = config.cobalt.interface.sun_default, 					description = config.cobalt.interface.sun_description},
	weather = 				{value = config.cobalt.interface.weather_default, 				description = config.cobalt.interface.weather_description},
	gravity = 				{value = config.cobalt.interface.gravity_default, 				description = config.cobalt.interface.gravity_description},
	temperature = 			{value = config.cobalt.interface.temperature_default, 			description = config.cobalt.interface.temperature_description},
	database = 				{value = config.cobalt.interface.database_default, 				description = config.cobalt.interface.database_description},
	race = 					{value = config.cobalt.interface.race_default, 					description = config.cobalt.interface.race_description}
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
	
	applyStuff(environmentJson, defaultEnvironment)
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
		
	CElog("CEI Loaded!", "CEI")
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

local function txPlayersResetExempt()
	for playerID, player in pairs(players) do
		if player.connectStage == "connected" then
			MP.TriggerClientEventJson(player.playerID, "rxPlayersResetExempt", { resetExempt[player.name] } )
		end
	end
end

local function txPlayersGroup()
	for playerID, player in pairs(players) do
		if player.connectStage == "connected" then
			MP.TriggerClientEvent(player.playerID, "rxPlayerGroup", player.permissions.group)
		end
	end
end

local function txPlayersUIPerm()
	for playerID, player in pairs(players) do
		if player.connectStage == "connected" then
			MP.TriggerClientEvent(player.playerID, "rxPlayersUIPerm", tostring(player.permissions.UI))
		end
	end
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
						MP.TriggerClientEventJson(player.playerID, "rxPlayersDatabase", playersDatabase[k])
					end
					playersDatabaseCount[player.name] = playersDatabaseCompare
				end
			end
		end
	end
end

local function txEnvironment(player)
	MP.TriggerClientEventJson(player.playerID, "rxEnvironment", environment)
end

local function txPlayersData(player)
	for playerID, player in pairs(players) do
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
						ip = player.permissions.ip,
						beammp = player.permissions.beammp,
						UI = player.permissions.UI
						},
					teleport = teleport[player.name],
					resetExempt = resetExempt[player.name],
					currentVehicle = tempPCV[player.name],
					vehicles = (player.vehicles or {})
					}
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
	MP.TriggerClientEventJson(player.playerID, "rxPlayersData", playersTable)
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

local function txConfigData(player)
	if player.connectStage == "connected" then
		MP.TriggerClientEventJson(player.playerID, "rxConfigData", config)
	end
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
		if player.connectStage == "connected" then
			txPlayersData(player)
			txPlayersGroup(player)
			txEnvironment(player)
			txNametagWhitelisted(player)
			txNametagBlockerActive(player)
			txConfigData(player)
			txPlayersUIPerm(player)
			txPlayersResetExempt(player)
		end
	end
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
			for k in pairs(config.resets) do
				config.resets[k] = config.resets[k .. "_default"]
				CobaltDB.set("restrictions", k, "value", config.resets[k .. "_default"])
			end
		elseif value == "default" then
			config.resets[key] = config.resets[key .. "_default"]
			CobaltDB.set("restrictions", key, "value", config.resets[key .. "_default"])
		else
			config.resets[key] = value
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
				environment.controlWeather = environment.controlWeather_default
			end
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
			if players[senderID].permissions.UI >= config.cobalt.interface.environmentAdmin then
				environment.controlSun = environment.controlSun_default
			end
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
			for k in pairs(environment) do
				if not string.find(k, "default") and not string.find(k, "description") then
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
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", true)
		end
		if action == "remove" then
			config.cobalt.whitelistedPlayers = {}
			CobaltDB.set("playersDB/" .. targetName, "whitelisted", "value", false)
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		txPlayersDatabase(true)
	end
end

function CEIRaceInclude(senderID, data)
	local playerName = players[senderID].name
	data = Util.JsonDecode(data)
	tempPlayers[playerName].includeInRace = data[1]
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
			MP.TriggerClientEventJson(player.playerID, "rxPlayersResetExempt", { data[2] } )
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
	theConfigData()
	txData()
	logTimer = logTimer + 1
	if logTimer >= logInterval then
		CobaltDB.set("environment", "ToD", "value", environment.ToD)
		logEnvironment()
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
	if player.connectStage == "connected" then
		MP.SendChatMessage(player.playerID, message)
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
	if identifiers.beammp then
		CobaltDB.new("playersDB/" .. identifiers.beammp)
		CobaltDB.set("playersDB/" .. player_name, "beammp", "value", identifiers.beammp)
		CobaltDB.set("playersDB/" .. player_name, "ip", "value", identifiers.ip)
		CobaltDB.set("playersDB/" .. identifiers.beammp, "beammp", "value", identifiers.beammp)
		CobaltDB.set("playersDB/" .. identifiers.beammp, "ip", "value", identifiers.ip)
		if CobaltDB.query("playersDB/" .. player_name, "banned", "value") == true then
			local reason = CobaltDB.query("playersDB/" .. player_name, "banReason", "value") or "You are banned from this server!"
			return reason
		end
		if CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == nil then
			CobaltDB.set("playersDB/" .. identifiers.beammp, "banned", "value", false)
		elseif CobaltDB.query("playersDB/" .. identifiers.beammp, "banned", "value") == true then
			local reason = CobaltDB.query("playersDB/" .. identifiers.beammp, "banReason", "value") or "You are banned from this server!"
			CobaltDB.set("playersDB/" .. player_name, "banned", "value", true)
			CobaltDB.set("playersDB/" .. player_name, "banReason", "value", reason)
			players.database[player_name].banned = true
			players.database[player_name].banReason = reason
			return reason
		end
		MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
		MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
	end
end

local function onPlayerJoining(player)
	tempPlayers[player.name].tempPermLevel = player.permissions.level
	if player.permissions.UI then
		tempPlayers[player.name].tempUIPermLevel = player.permissions.UI
	else
		CobaltDB.set("playersDB/" .. player.name, "UI", "value", 1)
	end
	tempPlayers[player.name].player_id = player.playerID
	MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
end

local function onPlayerJoin(player)
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
	MP.TriggerClientEventJson(player.playerID, "rxCEItp", { teleport[player.name] } )
	MP.TriggerClientEventJson(player.playerID, "rxCEIstate", { showCEI[player.name] } )
	CE.delayExec( 5000 , sendDelayedMessage , { player , "This server uses Cobalt Essentials Interface." } )
	CE.delayExec( 6000 , sendDelayedMessage , { player , "Use /CEI or /cei in chat to toggle." } )
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

local function onPlayerDisconnect(player)
	playersTable[player.playerID] = nil
	tempPlayers[player.name] = nil
	tempPCV[player.name] = nil
	MP.TriggerClientEvent(-1, "rxInputUpdate", "config")
	MP.TriggerClientEvent(-1, "rxInputUpdate", "players")
	MP.TriggerClientEvent(-1, "rxInputUpdate", "playersDatabase")
end

local function onVehicleSpawn(player, vehID,  data)
	tempPCV[player.name] = player.playerID .. "-" .. vehID
end

M.applyStuff = applyStuff

M.onInit = onInit
M.onTick = onTick
M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect
M.onVehicleSpawn = onVehicleSpawn

M.CEI = CEI
M.cei = CEI

return M
