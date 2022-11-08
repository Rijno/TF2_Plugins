#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// ----------------------------------------------------------------------------

#define PLUGIN_VERSION      			"0.1"
#define CHAT_TAG        				"\x05[SM]\x01 "
#define CONSOLE_TAG        				"[SM] "
#define DEFAULT_SIZE    				"1.0"
#define DEFAULT_MIN_SIZE    			"0.3"
#define DEFAULT_SHRINK_STEP	    		"0.05"

new bool:g_bEnabled;
new String:g_szDefault[16];
new Float:g_fDefaultSize;
new Float:g_fMinSize;
new Float:g_fShrinkStep;

KeyValues kvScale;

// ----------------------------------------------------------------------------

// Requirements:
// - ResizePlayer plugin
public Plugin myinfo =
{
	name = "TimeSplitters Shrink Mode",
	author = "Rijno",
	description = "Inspired by the TimeSplitters Shrink gamemode. https://timesplitters.fandom.com/wiki/Shrink_(Mode)",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rijno/TF2_Plugins"
};

// ----------------------------------------------------------------------------
// Plugin functions

public void OnPluginStart()
{	
	kvScale = new KeyValues("ShrinkScale");

	// ConVars
	CreateConVar("sm_shrink_version", PLUGIN_VERSION, "\"Shrink Mode\" version.", FCVAR_SPONLY|FCVAR_NOTIFY);

	new Handle:hEnabled = CreateConVar("sm_shrink_enabled", "1", "0 = Disable plugin, 1 = Enable plugin.");
	HookConVarChange(hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(hEnabled);

	new Handle:hDefaultSize = CreateConVar("sm_shrink_defaultsize", DEFAULT_SIZE, "Default scale of players.", _, true, 0.1, true, 3.0);
  	HookConVarChange(hDefaultSize, ConVarDefaultSizeChanged);
  	GetConVarString(hDefaultSize, g_szDefault, sizeof(g_szDefault));
  	g_fDefaultSize = StringToFloat(g_szDefault);

	new Handle:hMinSize = CreateConVar("sm_shrink_minsize", DEFAULT_MIN_SIZE, "Minimum scale the players will shrink to.", _, true, 0.1, true, 1.0);
  	HookConVarChange(hMinSize, ConVarMinSizeChanged);
  	GetConVarString(hMinSize, g_szDefault, sizeof(g_szDefault));
  	g_fMinSize = StringToFloat(g_szDefault);

	new Handle:hShrinkStep = CreateConVar("sm_shrink_shrinkstep", DEFAULT_SHRINK_STEP, "The stepsize the players will shrink each death.", _, true, 0.01, true, 0.5);
  	HookConVarChange(hShrinkStep, ConVarShrinkStepChanged);
  	GetConVarString(hShrinkStep, g_szDefault, sizeof(g_szDefault));
  	g_fShrinkStep = StringToFloat(g_szDefault);

	// List of TF2 events: https://wiki.alliedmods.net/Team_Fortress_2_Events#player_damaged
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre); 
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Pre); 
}

public void OnAllPluginsLoaded()
{
	// ResizePlayer Plugin settings
	ServerCommand("sm_resize_logging %d", 0); // No logging, spams server console	
	ServerCommand("sm_resize_notify %d", 0); // No notifications
	ServerCommand("sm_resize_damage %d", 0); // Damage doesn't scales with size
	ServerCommand("sm_resize_voices %d", 1); // Voice pitch scales with size
}

public void OnEventShutDown()
{	
	UnhookEvent("teamplay_round_start", OnRoundStart); 
	UnhookEvent("player_spawn", OnPlayerSpawn);
	delete kvScale;
}

// ----------------------------------------------------------------------------
// ConVar events

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
  	g_bEnabled = (StringToInt(newvalue) != 0);
	// TODO 
}

public ConVarDefaultSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fDefaultSize = StringToFloat(newvalue); }
public ConVarMinSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fMinSize = StringToFloat(newvalue); }
public ConVarShrinkStepChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fShrinkStep = StringToFloat(newvalue); }

// ----------------------------------------------------------------------------
// Game events
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnRoundStart");
	ResetSize();	
	return Plugin_Continue;
}


public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnPlayerSpawn");

	int userId = GetEventInt(event, "userid");

	// Skip shrinking if round is not active
	RoundState state = GameRules_GetRoundState();
	PrintToServer("SHRINK - RoundState: %d", state);
	if (state == RoundState:RoundState_Preround) 
	{
		PrintToServer("SHRINK - PreRound: #%d", userId);
		ServerCommand("sm_resize #%d %f", userId, g_fDefaultSize);
		return Plugin_Continue;
	}
	if (state != RoundState:RoundState_RoundRunning) return Plugin_Continue;

	// Skip if no class is selected (likely that player has joined but not actually spawned)
	if (GetEventInt(event, "class") == 0) return Plugin_Continue;

	decl String:UserId[16];
	decl String:SteamId[16];
	decl String:PlayerName[64];
	decl String:Key[32];

	// Get player info and create unique Key.
	int client = GetClientOfUserId(userId);
	IntToString(userId, UserId, sizeof(UserId));
	GetClientAuthId(client, AuthIdType:AuthId_Engine, SteamId, sizeof(SteamId));
	GetClientName(client, PlayerName, sizeof(PlayerName));
	Format(Key, sizeof(Key), "<%s><%s>", UserId, SteamId);
	PrintToServer("SHRINK - UserID: %s, SteamID: %s, PlayerName: %s", UserId, SteamId, PlayerName);

	// Size stuff
	float size = kvScale.GetFloat(Key, g_fDefaultSize);
	if (size <= g_fMinSize)  // Size limit
	{
		size = g_fMinSize;
	}
	else // Shrink
	{
		size = size - g_fShrinkStep;
		PrintToChat(client, "%sYou are becoming tiny baby! Scale: %d%%", CHAT_TAG, RoundToNearest(size * 100.0));
	}

	PrintToServer("SHRINK - Player: %s, Scale: %d%%", Key, RoundToNearest(size * 100.0));

	// Set size
	ServerCommand("sm_resize #%d %f", userId, size)
	kvScale.SetFloat(Key, size);

	// Save to file for debug
	//kv.ExportToFile("H:\\TF2\\SurfServer\\Shrink_sizes.txt");

	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

void ResetSize()
{
	// Clear kv list
	delete kvScale;
	kvScale = new KeyValues("Shrink");

	// Resets all targets' sizes to DefaultSize ConVar.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)) && IsPlayerAlive(i))
		{
			ServerCommand("sm_resize #%d %f", i, g_fDefaultSize);
		}
	} 
	PrintToChatAll("%sYou are normal size! Scale: %d%%", CHAT_TAG, RoundToNearest(g_fDefaultSize * 100.0))
}

// ----------------------------------------------------------------------------