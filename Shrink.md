# TimeSplitters Shrink game mode for TF2

This is a [SourceMod](http://www.sourcemod.net) plugin for TF2 Dedicated Servers.

Inspired by the [TimeSplitters Shrink gamemode](https://timesplitters.fandom.com/wiki/Shrink_(Mode)). Each time a player dies, they will become a little smaller. In theory the smaller players will have a little advantage as they would be harder to hit.

## Requirements
Requires Metamod:Soure & SourceMod to be installed on your Dedicated Server.
- https://www.metamodsource.net/
- http://www.sourcemod.net

Required SourceMod plugins:
- [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255)

## Compilation & Installation
Copy the Shrink.sp file to your servers `\tf\addons\sourcemod\scripting` and run the `compile.exe`. The compiled plugin (Shrink.smx) can then be found in `\tf\addons\sourcemod\scripting\compiled` folder. Copy this file to `\tf\addons\sourcemod\plugins` folder.

Make sure you also download the [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255) plugin and copy this to 'tf\addons\sourcemod\plugins'

## Configuring the plugin (ConVars)
- **sm_shrink_version** | Plugin version. Do not edit.
- **sm_shrink_enabled** | 0 = Disable plugin, 1 = Enable plugin. | **Default Value:** 1
- **sm_shrink_defaultsize** | Default scale of players. | **Default Value:** 1.0
- **sm_shrink_minsize** | Minimum scale the players will shrink to. | **Default Value:** 0.3
- **sm_shrink_shrinkstep** | The stepsize the players will shrink each death. | **Default Value:** 0.05

## Admin commands
- **sm_shrink [0/1]** | 0 = Disable plugin, 1 = Enable plugin | **Default Flag:** GENERIC (B)

## Progress
### Done
- [x] Keep track of players, shrink in increments.
- [x] Resize to default at each round.
- [x] Separate Injector idea to separate file.
- [x] Check if player is killed by someone other than itself.
- [x] Ignore shrink on cases like joining class, joining team, kill or explode client commands.
- [x] ConVars to configure the plugin.
- [x] Add chat colors for plugin messages to players.
- [x] Display scale as percentile.
- [x] Enable/Disable doesn't resize bots to 100%, removed IsFakeClient (is client a bot) check.
- [x] Checking KilledByOther state is enough, cleanup jointeam/joinclass states.  
- [x] Cleanup gamestate check.
- [x] Uniform chat and server messages.
- [x] Add message when enabling/disabling the plugin.

### TODOs
...

### Ideas
- [ ] PrintToChat random Baby related quotes from the Heavy?
  - [ ] Play relevant audio voice lines.

## Useful references
- [SourceMod API](sourcemod.net/new-api)
- [SourceMod ConVars](https://wiki.alliedmods.net/ConVars_(SourceMod_Scripting))
- [SourceMod Hooking Commands](https://wiki.alliedmods.net/Commands_(SourceMod_Scripting)#Hooking_Commands)
- [List of TF2 Events](https://wiki.alliedmods.net/Team_Fortress_2_Events)
- [Another list of TF2 Events](https://github.com/TF2CutContentWiki/SourceEventRESFiles/blob/master/tf/gameevents.res)
- [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255)
- [Heavy quotes](https://wiki.teamfortress.com/wiki/Heavy_responses)