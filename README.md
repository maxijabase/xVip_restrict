# xVip - Restrict Commands

A SourceMod plugin that allows server administrators to restrict specific commands to VIP users only. This plugin integrates with the xVip system to manage command access control.

## Features

- Restrict any command to VIP users only
- Commands are stored in a MySQL/SQLite database
- Automatic command listener management
- Integration with xVip system

## Requirements

- SourceMod 1.11 or higher
- xVip core plugin
- MySQL or SQLite database

Example database configuration:
```
"xVip"
{
    "driver"      "mysql"
    "host"        "localhost"
    "database"    "your_database"
    "user"        "your_username"
    "pass"        "your_password"
}
```

## Commands

### Admin Commands
- `sm_vip_restrict <command>` - Restrict a command to VIP users only
- `sm_vip_unrestrict <command>` - Remove VIP restriction from a command
- `sm_vip_restricted` - List all currently restricted commands

All admin commands require ADMFLAG_ROOT (z) flag.

### Usage Examples
```
sm_vip_restrict rtv         // Restricts the !rtv command to VIP users
sm_vip_restrict !kill      // Restricts the !kill command to VIP users
sm_vip_unrestrict rtv      // Removes VIP restriction from the rtv command
sm_vip_restricted          // Shows list of all restricted commands
```

Note: When specifying commands, you can include or omit the `!` or `/` prefix - the plugin handles both cases.