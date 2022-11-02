#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// ----------------------------------------------------------------------------


#define PLUGIN_VERSION      			"0.1"
#define DEFAULT_SIZE    				1.0
#define DEFAULT_MIN_SIZE    			0.3
#define DEFAULT_SIZE_REDUCTION    		0.05
#define DEFAULT_HEAD_SIZE    			1.0
#define DEFAULT_HEAD_SIZE_INCREMENT     0.25

KeyValues kvScale;
KeyValues kvHeadScale;

new g_Explode[MAXPLAYERS+1]

// ----------------------------------------------------------------------------

// Requirements:
// - ResizePlayer plugin
public Plugin myinfo =
{
	name = "Shrink",
	author = "Mui",
	description = "Shrink",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// ----------------------------------------------------------------------------

public void OnPluginStart()
{	
	PrintToServer("Loaded Sourcemod plugin: Shrink v%d", PLUGIN_VERSION);
	kvScale = new KeyValues("ShrinkScale");
	kvHeadScale = new KeyValues("ShrinkHeadScale");

	// List of TF2 events: https://wiki.alliedmods.net/Team_Fortress_2_Events#player_damaged
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre); 
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre); 
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);

}

public void OnAllPluginsLoaded()
{
	// ResizePlayer Plugin settings
	ServerCommand("sm_resize_logging %d", 0) // No logging, spams server console	
	ServerCommand("sm_resize_notify %d", 0) // No notifications
}

public void OnEventShutDown()
{	
	UnhookEvent("player_death", OnPlayerDeath);
	UnhookEvent("player_hurt", OnPlayerHurt);
	UnhookEvent("teamplay_round_start", OnRoundStart); 
	UnhookEvent("player_spawn", OnPlayerSpawn);

	delete kvScale;
	delete kvHeadScale;
}

// ----------------------------------------------------------------------------

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnRoundStart");
	ResetSize();	

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnPlayerSpawn");

	// Skip if round is not active
	RoundState state = GameRules_GetRoundState();
	PrintToServer("SHRINK - RoundState: %d", state);
	if (state != RoundState:RoundState_RoundRunning) return Plugin_Continue;

	// Skip if no class is selected (likely that player has joined but not actually spawned)
	if (GetEventInt(event, "class") == 0) return Plugin_Continue;

	decl String:UserId[16];
	decl String:SteamId[16];
	decl String:PlayerName[64];
	decl String:Key[32];

	// Get player info and create unique Key.
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);
	IntToString(userId, UserId, sizeof(UserId));
	GetClientAuthId(client, AuthIdType:AuthId_Engine, SteamId, sizeof(SteamId));
	GetClientName(client, PlayerName, sizeof(PlayerName));
	Format(Key, sizeof(Key), "<%s><%s>", UserId, SteamId);
	PrintToServer("SHRINK - UserID: %s, SteamID: %s, PlayerName: %s", UserId, SteamId, PlayerName);

	// Size stuff
	float size = kvScale.GetFloat(Key, DEFAULT_SIZE);
	if (size <= DEFAULT_MIN_SIZE)  // Size limit
	{
		size = DEFAULT_MIN_SIZE;
	}
	else // Shrink
	{
		size = size - DEFAULT_SIZE_REDUCTION;
		PrintToChat(client, "\x01\x0BYou are becoming tiny baby! Scale: %.3f", size);
	}

	PrintToServer("SHRINK - Player: %s, new size: %.3f", Key, size);

	// Set size
	ServerCommand("sm_resize #%d %f", userId, size)
	kvScale.SetFloat(Key, size);

	// Always spawn with normal sized head
	ServerCommand("sm_resizehead #%d %f", userId, DEFAULT_HEAD_SIZE) 
	kvHeadScale.SetFloat(Key, DEFAULT_HEAD_SIZE);

	// Save to file for debug
	//kv.ExportToFile("H:\\TF2\\SurfServer\\Shrink_sizes.txt");

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If using Syringe gun, increase head size of victim.
	int weaponId = GetEventInt(event, "weaponid");
	if (weaponId != 20) return Plugin_Continue; // Syringe gun is ID 20

	decl String:UserId[16];
	decl String:SteamId[16];
	decl String:PlayerName[64];
	decl String:Key[32];

	// Get player info and create unique Key.
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);
	IntToString(userId, UserId, sizeof(UserId));
	GetClientAuthId(client, AuthIdType:AuthId_Engine, SteamId, sizeof(SteamId));
	GetClientName(client, PlayerName, sizeof(PlayerName));
	Format(Key, sizeof(Key), "<%s><%s>", UserId, SteamId);

	// Size stuff
	float size = kvHeadScale.GetFloat(Key, DEFAULT_HEAD_SIZE);
	kvHeadScale.SetFloat(Key, size + DEFAULT_HEAD_SIZE_INCREMENT);

	ServerCommand("sm_resizehead #%d %f", userId, size)

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If using Syringe gun, increase head size of victim.
	int weaponId = GetEventInt(event, "weaponid");
	if (weaponId != 20) return Plugin_Continue; // Syringe gun is ID 20

	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	//Explode(client, userId);

	// Explode into gibs: https://forums.alliedmods.net/showthread.php?t=81874
	// TODO clean up
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
	
	g_Explode[client] = 0
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

void ResetSize()
{
	// Clear kv list
	delete kvScale;
	kvScale = new KeyValues("Shrink");

	// Reset all sizes
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
		{
			ServerCommand("sm_resizereset #%d", i) // Resets all targets' sizes to 1.0.
		}
	} 
	PrintToChatAll("\x01\x0B You are normal size! Scale: 1.0")

}
