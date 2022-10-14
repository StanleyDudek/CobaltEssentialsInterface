# CobaltEssentialsInterface
A Dear ImGui based interface for BeamMP Servers running CobaltEssentials

![image](https://user-images.githubusercontent.com/49531350/158417299-c2b3168d-e3b9-47d4-9c22-068679853464.png)

## Features:

* Owner / Administrator / Moderator / Default interfaces based on groups!
* Manipulation of player permissions, vehicle and parts permissions, CE and base server configuration, sun control and sync, weather control and sync, simulation speed control and sync, gravity control and sync, custom temperature curve control and sync, teleportation control and timeout, nametag whitelisting and timer based nametag hiding, all via the interface!
* voteKick, Kick, Ban, TempBan, Mute, Whitelist
* Handy `Join Race` and `Race Countdown!` buttons to freeze all players in place, notify and countdown, and then release everyone for perfect race starts!
* And more!

## Pre-requisites:

1. BeamMP Server 3.1.0 (as of CEI v0.6)
2. [CobaltEssentials](https://github.com/prestonelam2003/CobaltEssentials) 1.6.0 [BETA5] installed.
3. As owner, have yourself set as owner group in CobaltEssentials (i.e. `ce setgroup yourName owner` in server console)

## Installation:

1. Grab the latest release from [releases](https://github.com/StanleyDudek/CobaltEssentialsInterface/releases).
2. Unpack it somewhere.
3. Drag the folder `Resources` into the directory where your server is installed.
4. Edit LoadExtensions.cfg in `...\Resources\Server\CobaltEssentials\` to add the following line: `CEI = "CEI"`.
5. Start the server, and join.
6. The interface should be enabled by default. In the chat, enter the command /CEI to toggle the interface. You may set the default interface state in the Cobalt Essentials section of the interface's Config tab.

## Updating from pre-v0.6 to v0.6:

1. Grab the latest release from [releases](https://github.com/StanleyDudek/CobaltEssentialsInterface/releases).
2. Unpack it somewhere.
3. Drag the folder `Resources` into the directory where your server is installed, accept the overwrites.
4. HIGHLY RECCOMMENDED that you delete `environment.json`, `interface.json`, and `nametags.json` from the CobaltDB folder, YMMV if you do not.

## How it looks:

![image](https://user-images.githubusercontent.com/49531350/158418129-5e165ad8-b11a-4596-8e8e-002ead2b027b.png)
![image](https://user-images.githubusercontent.com/49531350/158417770-439511b4-d382-4343-a334-39037a81f051.png)

![image](https://user-images.githubusercontent.com/49531350/158418623-af96cd8e-87d7-43ce-8cf3-d70659699f48.png)

![image](https://user-images.githubusercontent.com/49531350/158418747-62afe261-af52-476e-802d-d5d7143d648d.png)
![image](https://user-images.githubusercontent.com/49531350/158418876-f8e3e10e-0895-447f-aa09-b18d0209a9f2.png)

![image](https://user-images.githubusercontent.com/49531350/158419418-8dbba6e4-4b18-49dd-9979-47f2cd1d42ba.png)
![image](https://user-images.githubusercontent.com/49531350/158420977-c2947fba-cc36-40a7-a968-c8d8f90fdd89.png)
