# Injector: The TimeSplitters Injector weapon turned into a a game mode for TF2

This is a [SourceMod](http://www.sourcemod.net) plugin for TF2 Dedicated Servers.

Inspired by the [TimeSplitters Injector weapon](https://timesplitters.fandom.com/wiki/Injector). Each time a player is hit by the *Injector* they inflate a little bit, untill the player explodes into gibs.

## Requirements
Requires Metamod:Soure & SourceMod to be installed on your Dedicated Server.
- https://www.metamodsource.net/
- http://www.sourcemod.net

Required SourceMod plugins:
- [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255)

## Compilation & Installation
Copy the Injector.sp file to your servers `\tf\addons\sourcemod\scripting` and run the `compile.exe`. The compiled plugin (Injector.smx) can then be found in `\tf\addons\sourcemod\scripting\compiled` folder. Copy this file to `\tf\addons\sourcemod\plugins` folder.

Make sure you also download the [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255) plugin and copy this to 'tf\addons\sourcemod\plugins'

## Configuring the plugin (ConVars)
- **sm_injector_version** | Plugin version. Do not edit.
- **sm_injector_enabled** | 0 = Disable plugin, 1 = Enable plugin. | **Default Value:** 1
- **sm_injector_defaultsize** | Default scale of players' heads. | **Default Value:** 1.0
- **sm_injector_forcemedic** | 0 = Allow all classes, 1 = Force players to the Medic class. | **Default Value:** 1
- **sm_injector_forceprimary** | 0 = Allow all weapon slots, 1 = Force players to use their primary weapon. | **Default Value:** 1

## Admin commands
- **sm_injector [0/1]** | 0 = Disable plugin, 1 = Enable plugin | **Default Flag:** GENERIC (B)

## Progress
### Done
- [x] Basic concept, increment player head size on hit.
- [x] Separate Injector idea to separate file. 
- [x] Remove all Shrink code from the plugin. 
- [x] Force all players to be Medic. **NOTE:** Forcing weapons can be done with the [TF2Items.GiveWeapons plugin](https://forums.alliedmods.net/showthread.php?p=1337899), but I prefer to keep it simple. Increment headsize based on damage should compensate for the different primary weapons of the Medic. Additionally it can also be played without the Medic restriction.
  - [x] Somehow ends up with weapon of other class, even if class is forced.
  - [x] Used code from [Set Class plugin](https://forums.alliedmods.net/showthread.php?p=1333506?p=1333506)
  - [x] Configurable with ConVars.
- [x] Remove all weaponslots except the primary.
  - [x] Healing Cabinets gives all weaponslots back.
  - [x] Configurable with ConVars.

### TODOs
- [ ] Weapons that have a *negative health on wearer* slowly reduces max health.
- [ ] Can stil use secondary weapons like Demo's shield charge. Even if you can't switch weaponsat all.
- [x] Scale inflation on hit based on damage.
  - [ ] Configurable with ConVars.
- [ ] Explode the player on a specific scale.
  - [ ] Take different max health per class in account
  - [ ] Allow player to be at max size for X seconds before exploding.
    - [ ] Some indiciation that the player is about to explode?
  - [ ] Configurable with ConVars.
- [ ] Head scale to a lower value is not instant, still decreasing head size on respawn.

### Ideas
- [ ] ...

## Useful references
- [SourceMod API](sourcemod.net/new-api)
- [SourceMod ConVars](https://wiki.alliedmods.net/ConVars_(SourceMod_Scripting))
- [SourceMod Hooking Commands](https://wiki.alliedmods.net/Commands_(SourceMod_Scripting)#Hooking_Commands)
- [List of TF2 Events](https://wiki.alliedmods.net/Team_Fortress_2_Events)
- [Another list of TF2 Events](https://github.com/TF2CutContentWiki/SourceEventRESFiles/blob/master/tf/gameevents.res)
- [ResizePlayers](https://forums.alliedmods.net/showthread.php?t=193255)
