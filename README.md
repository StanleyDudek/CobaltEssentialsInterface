# CobaltEssentialsInterface
A Dear ImGui based interface for BeamMP Servers running CobaltEssentials

![image](https://user-images.githubusercontent.com/49531350/155204810-f3db38e7-42b9-45a4-981d-f3df916f38be.png)

## Features:

* Owner / Administrator / Moderator / Player / Guest / Spectator interfaces based on roles!
* Manipulation of player permissions, vehicles, CE and base server configuration, and environment (Sun, Weather, Simulation), via the interface!
* Kick, Ban, TempBan, Mute, Whitelist
* A handy `Race Countdown!` button to freeze all players in place, notify and countdown, and then release everyone for perfect race starts!

## Pre-requisites:

1. BeamMP Server 3.0.0.
2. [CobaltEssentials](https://github.com/prestonelam2003/CobaltEssentials) 1.6.0 [BETA5] installed.
3. You must have set up roles in `...\Resources\Server\CobaltEssentials\CobaltDB\playerPermissions.json` if you want any control.

## Installation:

**UNTIL FURTHER NOTICE, THIS COMES WITH PATCHED FILES FOR CE 1.6.0 [BETA5] TO MAKE INSTALLATION EASIER**

1. Grab the latest release from [releases](https://github.com/StanleyDudek/CobaltEssentialsInterface/releases).
2. Unpack it somewhere.
3. Drag the folder `Resources` into the directory where your server is installed, accept the overwrites.
4. Edit LoadExtensions.cfg in `...\Resources\Server\CobaltEssentials\` to add the following line: `CEI = "CEI"`.
5. Start the server, and join.
6. Once joined, the interface should be active by default. In the chat, enter the command /CEI to toggle the interface

## How it looks:

![image](https://user-images.githubusercontent.com/49531350/155205263-c93be992-7aa5-4f02-93a0-ad9332513dab.png)
![image](https://user-images.githubusercontent.com/49531350/155205362-88ca41c0-125e-4c75-bfa1-f49ac5b97e15.png)
![image](https://user-images.githubusercontent.com/49531350/155205446-eee99b86-d767-4c95-aa1e-88c49a5341c5.png)
![image](https://user-images.githubusercontent.com/49531350/155205510-17560041-90c2-47f2-a4be-3e80803cc0da.png)
![image](https://user-images.githubusercontent.com/49531350/155205566-7aba0f35-452e-4870-aef7-ace892b1802c.png)

![image](https://user-images.githubusercontent.com/49531350/155206227-60f029a9-b26f-4717-8850-29a4284284cb.png)
![image](https://user-images.githubusercontent.com/49531350/155206270-b2b01437-8eb8-42f1-a01d-6a52cab361e1.png)
