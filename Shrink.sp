#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

// ----------------------------------------------------------------------------

#define PLUGIN_VERSION      "0.1"
#define CHAT_TAG            "\x05[SM]\x01 "
#define CONSOLE_TAG         "[SM] "
#define DEFAULT_SIZE        "1.0"
#define DEFAULT_MIN_SIZE    "0.3"
#define DEFAULT_SHRINK_STEP "0.05"

new bool:g_bEnabled;
new String:g_szDefault[16];
new Float:g_fDefaultSize;
new Float:g_fMinSize;
new Float:g_fShrinkStep;

// Arrays use client as index
new Float:Scale[MAXPLAYERS+1] = 1.0;
new bool:KilledByOther[MAXPLAYERS+1] = false;
new bool:KilledSelf[MAXPLAYERS+1] = false;
new bool:MoveToSpec[MAXPLAYERS+1] = false;
new bool:JoinTeam[MAXPLAYERS+1] = false;
new bool:JoinClass[MAXPLAYERS+1] = false;

// ----------------------------------------------------------------------------

// Requirements:
// - ResizePlayer plugin
public Plugin myinfo =
{
	name        = "TimeSplitters Shrink Mode",
	author      = "Rijno",
	description = "Inspired by the TimeSplitters Shrink gamemode. https://timesplitters.fandom.com/wiki/Shrink_(Mode)",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/Rijno/TF2_Plugins"
};

// ----------------------------------------------------------------------------
// Plugin functions
public void OnPluginStart()
{
	// ConVars
	CreateConVar("sm_shrink_version", PLUGIN_VERSION, "\"Shrink Mode\" version.", FCVAR_SPONLY | FCVAR_NOTIFY);

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

	ResetAllClients(g_fDefaultSize);
	AttachHandlers();

	RegAdminCmd("sm_shrink_enabled", OnShrinkEnabled, ADMFLAG_GENERIC, "Toggles Shrink plugin.");	
}

public void OnAllPluginsLoaded()
{
	// ResizePlayer Plugin settings
	ServerCommand("sm_resize_logging %d", 0);    // No logging, spams server console
	ServerCommand("sm_resize_notify %d", 0);     // No notifications
	ServerCommand("sm_resize_damage %d", 0);     // Damage doesn't scales with size
	ServerCommand("sm_resize_voices %d", 1);     // Voice pitch scales with size
}

public void OnEventShutDown()
{
	DetachHandlers();
}

// ----------------------------------------------------------------------------

public Action:OnPlayerCommand(client, const String:command[], args)
{
	PrintToServer("Shrink command intercepted: %s", command);
	
	if(StrEqual(command, "kill", false) || StrEqual(command, "explode", false))
		KilledSelf[client] = true;
	else if(StrEqual(command, "spectate", false))
		MoveToSpec[client] = true;
	else if(StrEqual(command, "jointeam", false))
		JoinTeam[client] = true;
	else if(StrEqual(command, "joinclass", false))
		JoinClass[client] = true;
}

void AttachHandlers()
{
	// Add command listeners
	AddCommandListener(OnPlayerCommand, "kill");
	AddCommandListener(OnPlayerCommand, "explode");
	AddCommandListener(OnPlayerCommand, "spectate");
	AddCommandListener(OnPlayerCommand, "jointeam");
	AddCommandListener(OnPlayerCommand, "joinclass");

	// Hook game events
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode:EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode:EventHookMode_Pre);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode:EventHookMode_Pre);
}

void DetachHandlers()
{
	// Remove command listeners
	RemoveCommandListener(OnPlayerCommand, "kill");
	RemoveCommandListener(OnPlayerCommand, "explode");
	RemoveCommandListener(OnPlayerCommand, "spectate");
	RemoveCommandListener(OnPlayerCommand, "jointeam");
	RemoveCommandListener(OnPlayerCommand, "joinclass");

	// Unhook game events
	UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode:EventHookMode_Pre);
	UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode:EventHookMode_Pre);
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode:EventHookMode_Pre);
}

public Action:OnShrinkEnabled(client, args)
{
	PrintToServer("SHRINK ENABLED: %d", g_bEnabled);
	if (g_bEnabled)
	{
		ResetAllClients(g_fDefaultSize); // Set all players to default plugin size
		AttachHandlers();
	}
	else
	{
		DetachHandlers();		
		ResetAllClients(1.0); // Set all players to default TF2 size
	}
	return Plugin_Handled;
}

// ----------------------------------------------------------------------------
// ConVar events

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_bEnabled = (StringToInt(newvalue) != 0); OnShrinkEnabled(-1, 0); }
public ConVarDefaultSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fDefaultSize = StringToFloat(newvalue); }
public ConVarMinSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fMinSize = StringToFloat(newvalue); }
public ConVarShrinkStepChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fShrinkStep = StringToFloat(newvalue); }

// ----------------------------------------------------------------------------
// Game events

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnRoundStart");
	ResetAllClients(g_fDefaultSize);
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnPlayerDeath");

	// Get attacker
	int attackerId = GetEventInt(event, "attacker");	

	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	if (userId == attackerId) return Plugin_Continue;
	KilledByOther[client] = true;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToServer("SHRINK - OnPlayerSpawn");

	// Get player info
	int userId = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userId);

	PrintToServer("SHRINK - UID: #%d, Client: %d, KilledByOther: %d, Suicide: %d, Spec: %d, TeamSwitch: %d, ClassSwitch: %d", userId, client, KilledByOther[client], KilledSelf[client], MoveToSpec[client], JoinTeam[client], JoinClass[client]);
	if(	!KilledByOther[client] // Ignore suicide
		|| KilledSelf[client] // Ignore suicide by kill or explode commands
		|| MoveToSpec[client] // Ignore moved to spec
		|| JoinTeam[client] // Ignore team switch
		|| JoinClass[client]) // Ignore class switch
		{
			ResetClientState(client);
			return Plugin_Continue;
		}

	// Skip shrinking if round is not active
	RoundState state = GameRules_GetRoundState();
	PrintToServer("SHRINK - RoundState: %d", state);
	if (state == RoundState:RoundState_Preround)
	{
		PrintToServer("SHRINK - PreRound: #%d", userId);
		ServerCommand("sm_resize #%d %f", userId, g_fDefaultSize);
		ResetClientState(client);
		return Plugin_Continue;
	}
	if (state != RoundState:RoundState_RoundRunning) 
	{ 
		ResetClientState(client); 
		return Plugin_Continue; 
	}

	// Skip if no class is selected (likely that player has joined but not actually spawned)
	if (GetEventInt(event, "class") == 0) 
	{ 
		ResetClientState(client); 
		return Plugin_Continue; 
	}

	// Size stuff
	float size = Scale[client];
	if (size <= g_fMinSize)    // Size limit
	{
		size = g_fMinSize;
	}
	else // Shrink
	{
		size = size - g_fShrinkStep;
		PrintToChat(client, "%sYou are becoming tiny baby! Scale: %d%%", CHAT_TAG, RoundToNearest(size * 100.0));
	}

	PrintToServer("SHRINK - Player: %s, Scale: %d%%", userId, RoundToNearest(size * 100.0));

	// Set size
	ServerCommand("sm_resize #%d %f", userId, size);
	Scale[client] = size;

	ResetClientState(client);
	return Plugin_Continue;
}

// ----------------------------------------------------------------------------

void ResetClientState(int client)
{
	KilledByOther[client] = false;
	KilledSelf[client] = false;
	MoveToSpec[client] = false;
	JoinTeam[client] = false;
	JoinClass[client] = false;
}

// ----------------------------------------------------------------------------

void ResetAllClients(float size)
{
	// Resets all targets' sizes to DefaultSize ConVar and reset client state. 
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && (!IsFakeClient(client)) && IsPlayerAlive(client))
		{
			int userId = GetClientUserId(client);
			Scale[client] = size;			
			ResetClientState(client);
			ServerCommand("sm_resize #%d %f", userId, size);
		}
	}
	PrintToChatAll("%sYou are normal size! Scale: %d%%", CHAT_TAG, RoundToNearest(g_fDefaultSize * 100.0))
}

// ----------------------------------------------------------------------------