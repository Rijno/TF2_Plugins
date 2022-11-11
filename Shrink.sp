#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

// ----------------------------------------------------------------------------

#define PLUGIN_VERSION      "1.0"
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

// ----------------------------------------------------------------------------

// Requirements:
// - ResizePlayer plugin
public Plugin myinfo =
{
    name        = "Shrink",
    author      = "Rijno",
    description = "Game mode inspired by the TimeSplitters Shrink game mode. https://timesplitters.fandom.com/wiki/Shrink_(Mode)",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/Rijno/TF2_Plugins"
};

// ----------------------------------------------------------------------------
// Plugin functions

public void OnPluginStart()
{
    // ConVars
    CreateConVar("sm_shrink_version", PLUGIN_VERSION, "Plugin version. Do not edit.", FCVAR_SPONLY | FCVAR_NOTIFY);

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

    // Admin commands
    RegAdminCmd("sm_shrink", OnShrinkEnabled, ADMFLAG_GENERIC, "0 = Disable plugin, 1 = Enable plugin.");    
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

void AttachHandlers()
{
    // Hook game events
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode:EventHookMode_Pre);
    HookEvent("player_death", OnPlayerDeath, EventHookMode:EventHookMode_Pre);
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode:EventHookMode_Pre);
}

void DetachHandlers()
{
    // Unhook game events
    UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode:EventHookMode_Pre);
    UnhookEvent("player_death", OnPlayerDeath, EventHookMode:EventHookMode_Pre);
    UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode:EventHookMode_Pre);
}

// ----------------------------------------------------------------------------

void SetShrinkEnabled(bool enabled)
{
    if (enabled == g_bEnabled) return;
    g_bEnabled = enabled;

    if (g_bEnabled)
    {
        ResetAllClients(g_fDefaultSize); // Set all players to default plugin size
        AttachHandlers();
        PrintToServer("%sShrink mode enabled", CONSOLE_TAG);
        PrintToChatAll("%sShrink mode enabled", CHAT_TAG);
    }
    else
    {
        DetachHandlers();        
        ResetAllClients(1.0); // Set all players to default TF2 size
        PrintToServer("%sShrink mode disabled", CONSOLE_TAG);
        PrintToChatAll("%sShrink mode disabled", CHAT_TAG);
    }
}

// ----------------------------------------------------------------------------
// Admin command events

public Action:OnShrinkEnabled(client, args)
{
    if (args != 1) { PrintToServer("sm_shrink requres 1 parameter"); return Plugin_Handled; }
    new enabled = GetCmdArgInt(1);
    SetShrinkEnabled(enabled != 0);    
    return Plugin_Continue;
}

// ----------------------------------------------------------------------------
// ConVar events

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) 
{
    new enabled = StringToInt(newvalue);
    SetShrinkEnabled(enabled != 0);    
}
public ConVarDefaultSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fDefaultSize = StringToFloat(newvalue); }
public ConVarMinSizeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fMinSize = StringToFloat(newvalue); }
public ConVarShrinkStepChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) { g_fShrinkStep = StringToFloat(newvalue); }

// ----------------------------------------------------------------------------
// Game events

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    ResetAllClients(g_fDefaultSize);
    return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
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
    // Get player info
    int userId = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userId);

    if(!KilledByOther[client]) // Ignore suicide by death event
    {
        ResetClientState(client);
        return Plugin_Continue;
    }

    // Skip shrinking if round is not active
    RoundState state = GameRules_GetRoundState();
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

    PrintToServer("%sShrinking player #%d to %d%%", CONSOLE_TAG, userId, RoundToNearest(size * 100.0));

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
}

// ----------------------------------------------------------------------------

void ResetAllClients(float size)
{
    // Resets all targets' sizes to DefaultSize ConVar and reset client state. 
    for (new client = 1; client < MaxClients; client++)
    {
        Scale[client] = size;            
        ResetClientState(client);

        if (IsClientConnected(client) && IsPlayerAlive(client))
        {
            int userId = GetClientUserId(client);
            ServerCommand("sm_resize #%d %f", userId, size);
        }
    }
    PrintToServer("%sReset scale of all players to %d%%", CONSOLE_TAG, RoundToNearest(size * 100.0));
    PrintToChatAll("%sYou are normal size! Scale: %d%%", CHAT_TAG, RoundToNearest(size * 100.0))
}

// ----------------------------------------------------------------------------