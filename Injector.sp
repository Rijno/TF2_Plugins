#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// ----------------------------------------------------------------------------

#define PLUGIN_VERSION				"1.0"
#define CHAT_TAG					"\x05[SM]\x01 "
#define CONSOLE_TAG					"[SM] "
#define DEFAULT_HEAD_SIZE			"1.0"
#define DEFAULT_FORCE_MEDIC			"1"
#define DEFAULT_FORCE_PRIMARY		"1"

#define DEFAULT_HEAD_SIZE_INCREMENT	"0.25"

new bool:g_bEnabled;
new String:g_szDefault[16];
new Float:g_fDefaultHeadSize;
new bool:g_bForceMedic;
new bool:g_bForcePrimary;

new Float:g_HeadSizefIncrement;

// Arrays use client as index
new Float:HeadScale[MAXPLAYERS+1] = 1.0;
new bool:Explode[MAXPLAYERS+1] = false;

// ----------------------------------------------------------------------------

// Requirements:
// - ResizePlayer plugin
public Plugin myinfo =
{
	name        = "TimeSplitters Injector gamemode",
	author      = "Rijno",
	description = "Inspired by the TimeSplitters Injector weapon. https://timesplitters.fandom.com/wiki/Injector",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/Rijno/TF2_Plugins"
};

// ----------------------------------------------------------------------------

public void OnPluginStart()
{	
	// ConVars
	CreateConVar("sm_injector_version", PLUGIN_VERSION, "Plugin version. Do not edit.", FCVAR_SPONLY | FCVAR_NOTIFY);

	new Handle:hEnabled = CreateConVar("sm_injector_enabled", "1", "0 = Disable plugin, 1 = Enable plugin.");
	HookConVarChange(hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(hEnabled);

	new Handle:hDefaultHeadSize = CreateConVar("sm_injector_defaultheadsize", DEFAULT_HEAD_SIZE, "Default scale of players heads.", _, true, 0.1, true, 3.0);
	HookConVarChange(hDefaultHeadSize, ConVarDefaultHeadSizeChanged);
	GetConVarString(hDefaultHeadSize, g_szDefault, sizeof(g_szDefault));
	g_fDefaultHeadSize = StringToFloat(g_szDefault);

	new Handle:hForceMedic = CreateConVar("sm_injector_forcemedic", DEFAULT_FORCE_MEDIC, "0 = Allow all classes, 1 = Force players to the Medic class.");
	HookConVarChange(hForceMedic, ConVarForceMedicChanged);
	g_bForceMedic = GetConVarBool(hForceMedic);

	new Handle:hForcePrimary = CreateConVar("sm_injector_forceprimary", DEFAULT_FORCE_PRIMARY, "0 = Allow all weapon slots, 1 = Force players to use their primary weapon.");
	HookConVarChange(hForcePrimary, ConVarForcePrimaryChanged);
	g_bForcePrimary = GetConVarBool(hForcePrimary);

	// TODO ConVars
	// new Handle:hDefaultSize = CreateConVar("sm_injector_defaultheadsize", DEFAULT_HEAD_SIZE, "Default scale of players heads.", _, true, 0.1, true, 3.0);
	// HookConVarChange(g_fDefaultHeadSize, ConVarDefaultSizeChanged);
	// GetConVarString(g_fDefaultHeadSize, g_szDefault, sizeof(g_szDefault));
	// g_fDefaultHeadSize = StringToFloat(g_szDefault);
	// g_HeadSizefIncrement = StringToFloat(DEFAULT_HEAD_SIZE_INCREMENT)

	ResetAllClients(g_fDefaultHeadSize);
	AttachHandlers();

	// Admin commands
	RegAdminCmd("sm_injector", OnInjectorEnabled, ADMFLAG_GENERIC, "0 = Disable plugin, 1 = Enable plugin.");	
}

public void OnAllPluginsLoaded()
{
	// ResizePlayer Plugin settings
	ServerCommand("sm_resize_logging %d", 0) // No logging, spams server console	
	ServerCommand("sm_resize_notify %d", 0) // No notifications
	ServerCommand("sm_resize_damage %d", 0) // Scales with size
}

public void OnEventShutDown()
{	
	DetachHandlers();
}

// ----------------------------------------------------------------------------

void AttachHandlers()
{
	// Hook game events
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre); 
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);


	HookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Pre);

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre); 
}

void DetachHandlers()
{
	// Unhook game events
	UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre); 

	UnhookEvent("post_inventory_application", OnInventoryApplication, EventHookMode_Pre);

	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
}

void SetInjectorEnabled(bool enabled)
{
	if (enabled == g_bEnabled) return;
	g_bEnabled = enabled;

	if (g_bEnabled)
	{
		ResetAllClients(g_fDefaultHeadSize); // Set all players to default plugin size
		AttachHandlers();
		PrintToServer("%sInjector mode enabled", CONSOLE_TAG);
		PrintToChatAll("%sInjector mode enabled", CHAT_TAG);
	}
	else
	{
		DetachHandlers();		
		ResetAllClients(1.0); // Set all players to default TF2 size
		PrintToServer("%sInjector mode disabled", CONSOLE_TAG);
		PrintToChatAll("%sInjector mode disabled", CHAT_TAG);
	}
}

// ----------------------------------------------------------------------------
// Admin command events

public Action:OnInjectorEnabled(client, args)
{
	if (args != 1) { PrintToServer("sm_injector requres 1 parameter"); return Plugin_Handled; }
	new enabled = GetCmdArgInt(1);
	SetInjectorEnabled(enabled != 0);	
	return Plugin_Continue;
}

// ----------------------------------------------------------------------------
// ConVar events

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { new enabled = StringToInt(newvalue); SetInjectorEnabled(enabled != 0); }
public ConVarDefaultHeadSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fDefaultHeadSize = StringToFloat(newvalue); }
public ConVarForceMedicChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_bForceMedic = StringToInt(newvalue) != 0; }
public ConVarForcePrimaryChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_bForcePrimary = StringToInt(newvalue) != 0; }

// ----------------------------------------------------------------------------

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("INJECTOR - OnRoundStart");
	ResetAllClients(g_fDefaultHeadSize);
	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Note: sent when a player gets a whole new set of items, aka touches a resupply locker / respawn cabinet or spawns in.
	PrintToServer("INJECTOR - OnInventoryApplication");
	
	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	// Force primary weapon by removing all weapon slots except the primary weapon slot
	if (g_bForcePrimary) RemoveAllExceptPrimaryWeapon(client);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("INJECTOR - OnPlayerSpawn");

	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	// Force class medic, doesn't work on bots based on server settings. They kill themselves to balance teams
	if (g_bForceMedic && !IsFakeClient(client)) ForceClientToMedic(client);

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	// TODO explode player on specific scale size, with delay
	// 0.01 per point of damage
	int damageAmount = GetEventInt(event, "damageamount");
	
	// TODO scale increment based on damage done
	// Increment head size of victim.
	//HeadScale[client] = (size + g_HeadSizefIncrement);
	HeadScale[client] = (HeadScale[client] + (float(damageAmount) / 50));
	// TODO configurable with ConVars, 100 is 0.01 per hit, 50 is 0.02 per hit.

	PrintToServer("Client %d new size: %f", client, HeadScale[client]);

	ServerCommand("sm_resizehead #%d %f", userId, HeadScale[client]);

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// When killed, explode into gibs

	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	// Reset head size
	HeadScale[client] = g_fDefaultHeadSize;
	ServerCommand("sm_resizehead #%d %f", userId, HeadScale[client]);

	// Explode into gibs: https://forums.alliedmods.net/showthread.php?t=81874
	CreateTimer(0.1, DeleteRagdoll, client)
		
	decl Ent
	decl Float:ClientOrigin[3]

	//Initialize:
	Ent = CreateEntityByName("tf_ragdoll")
	GetClientAbsOrigin(client, ClientOrigin)

	//Write:
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin)
	SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client)
	SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR)
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR)
	SetEntProp(Ent, Prop_Send, "m_bGib", 1)

	//Send:
	DispatchSpawn(Ent)
	
	CreateTimer(8.0, DeleteGibs, Ent)
	
	Explode[client] = false
}

// ----------------------------------------------------------------------------

public Action:DeleteRagdoll(Handle:timer, any:client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll")
	
	if (IsValidEdict(ragdoll))
    {
        RemoveEdict(ragdoll)
    }
}

// ----------------------------------------------------------------------------

public Action:DeleteGibs(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
    {
        new String:classname[256]
        GetEdictClassname(ent, classname, sizeof(classname))
        if (StrEqual(classname, "tf_ragdoll", false))
        {
            RemoveEdict(ent)
        }
    }
}

// ----------------------------------------------------------------------------

void ResetClientState(int client)
{
	Explode[client] = false;
}

// ----------------------------------------------------------------------------

void ResetAllClients(float headSize)
{
	// Resets all targets' sizes to DefaultSize ConVar and reset client state. 
	for (new client = 1; client < MaxClients; client++)
	{
		HeadScale[client] = headSize;			
		ResetClientState(client);

		if (IsClientConnected(client) && IsPlayerAlive(client))
		{
			int userId = GetClientUserId(client);
			ServerCommand("sm_resizehead #%d %f", userId, headSize);
		}
	}
	PrintToServer("%sReset head scale of all players to %d%%", CONSOLE_TAG, RoundToNearest(headSize * 100.0));
}

// ----------------------------------------------------------------------------

void ForceClientToMedic(client)
{
	TF2_SetPlayerClass(client, TFClass_Medic);
	if(IsPlayerAlive(client))
	{
		SetEntityHealth(client, 25);
		TF2_RegeneratePlayer(client);
		new weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
}

// ----------------------------------------------------------------------------

void RemoveAllExceptPrimaryWeapon(client)
{
	// Remove all weapon slots except the primary weapon slot
	new weapon = -1;
	for (new i = 1; i <= 5; i++)
	{
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weapon);
		}
	}

	// Force a player to select primary weapon
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

// ----------------------------------------------------------------------------