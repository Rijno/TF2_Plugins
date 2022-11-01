#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
//#include <ResizePlayers.sp>

public Plugin myinfo =
{
	name = "Shrink",
	author = "Mui",
	description = "Shrink",
	version = "1.0a",
	url = "http://www.sourcemod.net/"
};

KeyValues kv;

public void OnPluginStart()
{
	PrintToServer("SHRINK");
	kv = new KeyValues("Shrink_sizes");

	//HookEvent("player_death", OnDeath);
	HookEvent("player_spawn", OnPlayerSpawn); 
	HookEvent("teamplay_round_start", OnRoundStart); 
	
}

public void OnAllPluginsLoaded()
{
	// ResizePlayer Plugin settings
	ServerCommand("sm_resize_notify %d", 0) // No notifications
}

public void OnEventShutDown()
{
	UnhookEvent("teamplay_round_start", OnRoundStart); 
	UnhookEvent("player_spawn", OnPlayerSpawn);
	//UnhookEvent("player_death", OnDeath);

	delete kv;
}

void ResetSize()
{
	// Clear kv list
	delete kv;
	kv = new KeyValues("Shrink_sizes");

	// Reset all sizes
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
		{
			ServerCommand("sm_resize #%d %f", i, 1.0)
			//SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
		}
	} 
	PrintToChatAll("\x01\x0B You are normal size! Scale: 1.0")

}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnRoundStart");
	ResetSize();	
}

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
	float size = kv.GetFloat(Key, 1.0);
	if (size <= 0.3)  // Size limit
	{
		size = 0.3;
	}
	else if (size <= 0.15) // Print message when you're as small as can be
	{
		size = 0.1;
		PrintToChat(client, "\x01\x0BNext time, pick on someone your own tiny-baby size! Scale: %.3f", size)
	}
	else // Shrink
	{
		size = size - 0.05;
		PrintToChat(client, "\x01\x0BYou are becoming tiny baby! Scale: %.3f", size);
	}

	PrintToServer("SHRINK - Player: %s, new size: %.3f", Key, size);

	// Set size
	ServerCommand("sm_resize #%d %f", userId, size)
	//SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
	kv.SetFloat(Key, size);

	// Save to file for debug
	//kv.ExportToFile("H:\\TF2\\SurfServer\\Shrink_sizes.txt");

	return Plugin_Continue;
}