#include <sourcemod>

#define PLUGIN_VERSION "0.0.1"

#pragma newdecls required;

public Plugin myinfo =
{
    name = "Group based map configs",
    author = "faketuna",
    description = "The simple plugin to enforce setting per map group.",
    version = PLUGIN_VERSION,
    url = "https://short.f2a.dev/s/github"
};

// Use struct for future extension
enum struct GroupConfig {
    char mapGroup[128];
}

enum struct MapData {
    char mapName[128];
    char mapGroup[128];
}

enum struct ConVarData {
    char conVarName[128];
    char conVarValue[128];
}

ConVar g_hGroupConfigFile;

ArrayList g_hMapData;
ArrayList g_hGroupConfigs;

char g_hCurrentMapGroup[128];
bool g_hMapInList;

public void OnPluginStart() {
    RegAdminCmd("gbmc_reload", commandReloadCfg, ADMFLAG_RCON, "");
    g_hGroupConfigFile = CreateConVar("gbmc_config_file", "gbmc-config.txt", "File to read the group settings from.");

    g_hMapData = new ArrayList(sizeof(MapData))
    g_hGroupConfigs = new ArrayList(sizeof(GroupConfig));

    HookEvent("round_start", onRoundStart, EventHookMode_PostNoCopy);
    AutoExecConfig(true, "group-based-map-configs");
}

public Action commandReloadCfg(int client, int args) {
    ReplyToCommand(client, "[GBMC] Reloading config...");
    OnConfigsExecuted();
    ReplyToCommand(client, "[GBMC] Reloaded!");
    return Plugin_Handled;
}

void onRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    if (strlen(g_hCurrentMapGroup) < 1) {
        char buff[128];
        GetCurrentMap(buff, sizeof(buff));
        for (int i = 0; i < GetArraySize(g_hMapData); i++) {
            MapData md;
            g_hMapData.GetArray(i, md);
            if (StrEqual(md.mapName, buff)) {
                strcopy(g_hCurrentMapGroup, sizeof(g_hCurrentMapGroup), md.mapGroup);
                g_hMapInList = true;
                break;
            }
        }
    }

    if (!g_hMapInList) {
        return;
    }

    char config[255];
    Format(config, sizeof(config), "sourcemod/GroupBasedMapConfig/%s.cfg", g_hCurrentMapGroup);
    char buff[255];
    Format(buff, sizeof(buff), "cfg/%s", config);

    if (!FileExists(buff)) {
        PrintToServer("Skipping execute map group config file.");
        PrintToServer("File not found: %s", buff);
        return;
    }

    ServerCommand("exec %s", config);
}

public void OnMapStart() {
    g_hMapInList = false;
    char buff[128];
    GetCurrentMap(buff, sizeof(buff));
    for (int i = 0; i < GetArraySize(g_hMapData); i++) {
        MapData md;
        g_hMapData.GetArray(i, md);
        if (StrEqual(md.mapName, buff)) {
            strcopy(g_hCurrentMapGroup, sizeof(g_hCurrentMapGroup), md.mapGroup);
            g_hMapInList = true;
            break;
        }
    }
}


public void OnConfigsExecuted() {
    parseGroupConfig()

    if (1 < GetArraySize(g_hMapData)) {
        g_hMapData.Clear();
    }

    for (int i = 0; i < GetArraySize(g_hGroupConfigs); i++) {
        GroupConfig gconf;
        g_hGroupConfigs.GetArray(i, gconf);
        char buff[128];
        strcopy(buff, sizeof(buff), gconf.mapGroup)
        parseMapGroupData(buff);
    }
}

/*
MAP CONFIG EXAMPLE
"groups"
{
    "multigames"{}
    "course"{}
}
*/
void parseGroupConfig() {
    if (1 < GetArraySize(g_hGroupConfigs)) {
        g_hGroupConfigs.Clear();
    }

    char cFile[64], cPath[PLATFORM_MAX_PATH];
    g_hGroupConfigFile.GetString(cFile, sizeof(cFile));
    BuildPath(Path_SM, cPath, sizeof(cPath), "configs/GroupBasedMapConfig/%s", cFile);

    if (!FileExists(cPath)) {
        SetFailState("Group config file not found: %s", cPath);
    }

    KeyValues hConfig = new KeyValues("groups");
    hConfig.SetEscapeSequences(true);
    hConfig.ImportFromFile(cPath);
    hConfig.GotoFirstSubKey();

    GroupConfig gconf;

    do {
        hConfig.GetSectionName(gconf.mapGroup, sizeof(GroupConfig::mapGroup));
        g_hGroupConfigs.PushArray(gconf)
    } while (hConfig.GotoNextKey())

    delete hConfig;
}

void parseMapGroupData(const char[] mapGroup) {

    char cPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, cPath, sizeof(cPath), "configs/GroupBasedMapConfig/%s_maps.txt", mapGroup);

    if (!FileExists(cPath)) {
        SetFailState("Map list file not found: %s", cPath);
    }

    MapData md;
    
    Handle hFile = OpenFile(cPath, "r");
    char buff[128];
    while(!IsEndOfFile(hFile)) {
        //ReadFileLine(hFile, md.mapName, sizeof(MapData::mapName));
        ReadFileLine(hFile, buff, sizeof(buff));
        ReplaceString(buff, sizeof(buff), "\n", "");
        strcopy(md.mapName, sizeof(MapData::mapName), buff);
        strcopy(md.mapGroup, sizeof(MapData::mapGroup), mapGroup);
        g_hMapData.PushArray(md);
    }

    CloseHandle(hFile);
}