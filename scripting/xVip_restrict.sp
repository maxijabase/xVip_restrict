#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <xVip>

#define PLUGIN_VERSION "1.0"

Database g_Database = null;
ArrayList g_RestrictedCommands = null;

public Plugin myinfo = {
  name = "xVip - Restrict Commands", 
  author = "ampere", 
  description = "Restricts commands to xVip users", 
  version = PLUGIN_VERSION, 
  url = "https://github.com/maxijabase"
};

public void OnPluginStart() {
  g_RestrictedCommands = new ArrayList(ByteCountToCells(32));
  
  // Connect to database
  Database.Connect(OnDatabaseConnect, "xVip");
  
  // Register admin command to add/remove restricted commands
  RegAdminCmd("sm_vip_restrict", Command_RestrictCommand, ADMFLAG_ROOT, "Restrict a command to VIP users");
  RegAdminCmd("sm_vip_unrestrict", Command_UnrestrictCommand, ADMFLAG_ROOT, "Remove VIP restriction from a command");
  RegAdminCmd("sm_vip_restricted", Command_ListRestrictedCommands, ADMFLAG_ROOT, "List restricted commands");
}

public void OnDatabaseConnect(Database db, const char[] error, any data) {
  if (db == null) {
    LogError("Database connection failed: %s", error);
    return;
  }
  
  g_Database = db;
  
  // Create table if it doesn't exist
  char query[] = "CREATE TABLE IF NOT EXISTS xVip_restrictedcommands (\
                    id INT AUTO_INCREMENT PRIMARY KEY,\
                    command VARCHAR(64) NOT NULL UNIQUE)";
  
  g_Database.Query(OnTableCreated, query);
}

public void OnTableCreated(Database db, DBResultSet results, const char[] error, any data) {
  if (results == null) {
    LogError("Table creation failed: %s", error);
    return;
  }
  
  // Load restricted commands into memory
  LoadRestrictedCommands();
}

void LoadRestrictedCommands() {
  if (g_Database == null)
  {
    return;
  }
  
  char query[] = "SELECT command FROM xVip_restrictedcommands";
  g_Database.Query(OnCommandsLoaded, query);
}

public void OnCommandsLoaded(Database db, DBResultSet results, const char[] error, any data) {
  if (results == null) {
    LogError("Failed to load commands: %s", error);
    return;
  }
  
  g_RestrictedCommands.Clear();
  
  char command[64];
  while (results.FetchRow()) {
    results.FetchString(0, command, sizeof(command));
    g_RestrictedCommands.PushString(command);
    
    // Hook each command
    AddCommandListener(Command_Restricted, command);
  }
}

public Action Command_RestrictCommand(int client, int args) {
  if (args < 1) {
    xVip_Reply(client, "Usage: sm_vip_restrict <command>");
    return Plugin_Handled;
  }
  
  char command[64];
  GetCmdArg(1, command, sizeof(command));
  
  // Remove ! or / prefix if present
  if (command[0] == '!' || command[0] == '/') {
    strcopy(command, sizeof(command), command[1]);
  }
  
  DataPack pack = new DataPack();
  pack.WriteCell(client ? GetClientUserId(client) : 0);
  pack.WriteString(command);

  // Add to database
  char query[256];
  g_Database.Format(query, sizeof(query), "INSERT IGNORE INTO xVip_restrictedcommands (command) VALUES ('%s')", command);
  g_Database.Query(OnCommandRestricted, query, pack);
  
  // Hook the command immediately
  
  return Plugin_Handled;
}

public void OnCommandRestricted(Database db, DBResultSet results, const char[] error, DataPack pack) {
  pack.Reset();
  int userid = pack.ReadCell();
  char command[32];
  pack.ReadString(command, sizeof(command));
  delete pack;
  
  int client = GetClientOfUserId(userid);
  if (results == null) {
    xVip_Reply(client, "Failed to restrict command %s: %s", command, error);
    return;
  }
  
  g_RestrictedCommands.PushString(command);
  xVip_Reply(client, "Command restricted to VIP users");
  AddCommandListener(Command_Restricted, command);
}

public Action Command_UnrestrictCommand(int client, int args) {
  if (args < 1) {
    xVip_Reply(client, "Usage: sm_vip_unrestrict <command>");
    return Plugin_Handled;
  }
  
  char command[64];
  GetCmdArg(1, command, sizeof(command));
  
  // Remove ! or / prefix if present
  if (command[0] == '!' || command[0] == '/') {
    strcopy(command, sizeof(command), command[1]);
  }

  DataPack pack = new DataPack();
  pack.WriteCell(client ? GetClientUserId(client) : 0);
  pack.WriteString(command);
  
  // Remove from database
  char query[256];
  g_Database.Format(query, sizeof(query), "DELETE FROM xVip_restrictedcommands WHERE command = '%s'", command);
  g_Database.Query(OnCommandUnrestricted, query, pack);
  
  return Plugin_Handled;
}

public void OnCommandUnrestricted(Database db, DBResultSet results, const char[] error, DataPack pack) {
  pack.Reset();
  int userid = pack.ReadCell();
  char command[32];
  pack.ReadString(command, sizeof(command));
  delete pack;

  int client = GetClientOfUserId(userid);
  if (results == null) {
    xVip_Reply(client, "Failed to unrestrict command %s: %s", command, error);
    return;
  }
  
  xVip_Reply(client, "Command restriction removed");
  RemoveCommandListener(Command_Restricted, command);
}

public Action Command_Restricted(int client, const char[] command, int argc) {
  // Allow console and RCON to bypass restrictions
  if (client == 0) {
    return Plugin_Continue;
  }
  
  // Check if the client is VIP
  if (!xVip_IsVip(client)) {
    xVip_Reply(client, "This command is restricted to VIP users only");
    return Plugin_Stop;
  }
  
  return Plugin_Continue;
}

public Action Command_ListRestrictedCommands(int client, int args) {
  if (g_RestrictedCommands.Length == 0) {
    xVip_Reply(client, "No commands are restricted");
    return Plugin_Handled;
  }
  
  char command[64];
  for (int i = 0; i < g_RestrictedCommands.Length; i++) {
    g_RestrictedCommands.GetString(i, command, sizeof(command));
    xVip_Reply(client, "%s", command);
  }
  
  return Plugin_Handled;
}

public void OnPluginEnd() {
  // Remove all command listeners
  char command[64];
  for (int i = 0; i < g_RestrictedCommands.Length; i++) {
    g_RestrictedCommands.GetString(i, command, sizeof(command));
    RemoveCommandListener(Command_Restricted, command);
  }
  
  delete g_RestrictedCommands;
} 