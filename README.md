# Syncdb - WordPress Database Synchronization Tool

A bash script for synchronizing WordPress databases between environments (production, staging, local) using WP-CLI and SSH.

## Features

- **Interactive menu system** for selecting source and destination databases
- **Automatic URL replacement** using WP-CLI search-replace
- **SSH-based remote database operations** via WP-CLI
- **Lando support** for local development environments
- **Automatic cleanup** of temporary database dumps
- **Test connections** before syncing
- **Compatible with**:
  - Vanilla WordPress installations
  - Bedrock-based WordPress projects
  - Flywheel, SpinupWP, and other hosting providers

## Requirements

- **WP-CLI** installed on all remote servers
- **SSH access** configured with key-based authentication
- **Lando** (for local development)
- **rsync** for file transfers

## Installation

1. Add syncdb as a git submodule to your project:
   ```bash
   git submodule add git@github.com:campaignupgrade/syncdb.git dev/syncdb
   ```

2. Create a configuration file at `dev/config/syncdb.sh`:
   ```bash
   cp dev/syncdb/options.sh.example dev/config/syncdb.sh
   ```

3. Edit `dev/config/syncdb.sh` with your project settings:
   ```bash
   # SSH host names from ~/.ssh/config
   _production=mysite_prod
   _remotes=( mysite_stage mysite_dev )

   # Database dump paths (no trailing slash)
   _local_path="dev/db"      # Local path relative to project root
   _remote_path="db"         # Remote path (usually relative to SSH login dir)
   ```

## Configuration

### SSH Configuration

Add your remote servers to `~/.ssh/config`:

```ssh
Host mysite_prod
  HostName ssh.example.com
  User username+sitename
  Port 22
  IdentityFile ~/.ssh/mysite_rsa
```

### Syncdb Configuration

The script looks for configuration in this order:
1. `dev/config/syncdb.sh` (recommended, version-controlled)
2. `dev/syncdb/options.sh` (legacy, local copy)

**Configuration variables:**

- `_production`: SSH host name for production server
- `_remotes`: Array of SSH host names for remote environments
- `_local_path`: Path to store database dumps locally
- `_remote_path`: Path to store database dumps on remote servers

## Usage

Run the script from your project root:

```bash
./dev/syncdb/syncdb.sh
```

### Main Menu Options

1. **Sync database** - Synchronize database from source to destination
2. **Test connections** - Verify SSH and WP-CLI connectivity to all remotes
3. **Quit** - Exit the script

### Workflow

When syncing a database:

1. Select source (production or remote environment)
2. Select destination (local or remote environment)
3. Confirm the sync operation
4. Script performs:
   - Export database from source
   - Download to local machine
   - Upload to destination (if not local)
   - Get URLs from source and destination
   - Import database to destination
   - Search-replace URLs
   - Cleanup operations
   - Delete temporary files

## How It Works

### Database Sync Process

1. **Export**: Uses `wp db export` on source server to create SQL dump
2. **Download**: Uses `rsync` to download dump to local machine
3. **Upload**: Uses `rsync` to upload dump to destination (if remote)
4. **URL Detection**: Retrieves home URLs from both source and destination
5. **Import**: Imports SQL dump using:
   - `lando db-import` for local
   - `wp db import` for remote destinations
6. **Search-Replace**: Updates all URLs in database using `wp search-replace`
7. **Cleanup**:
   - Activates all plugins
   - Flushes cache and rewrites
   - Purges SpinupWP cache (if available)
   - Clears Acorn views (if Bedrock/Sage)
   - Removes all temporary SQL dumps

### Automatic Cleanup

The script automatically deletes temporary database dumps:
- Local dump: `dev/db/syncdb.sql`
- Source dump: `{remote_path}/syncdb.sql` on source server
- Destination dump: `{remote_path}/syncdb.sql` on destination server (if remote)

### Framework Detection

The script intelligently detects available features:

**SpinupWP Cache Purging:**
```bash
if wp cli has-command "spinupwp cache purge-site"; then
  wp spinupwp cache purge-site
fi
```

**Acorn (Bedrock/Sage) Views:**
```bash
if wp cli has-command "acorn view:clear"; then
  wp acorn view:clear
  wp acorn view:cache
fi
```

## Remote Path Configuration

The `_remote_path` setting depends on where you land when SSH'ing into the server:

### Example: Flywheel
```bash
# When you SSH in, you land in /www
ssh mysite_prod
# Output: user@sitename:/www>

# Configuration:
_remote_path="db"  # Creates /www/db/
```

### Example: SpinupWP
```bash
# When you SSH in, you might land in /home/user
ssh mysite_prod
# Output: user@hostname:~$

# Configuration:
_remote_path="public/db"  # Creates ~/public/db/
```

**Test your path:**
```bash
ssh mysite_prod "pwd && mkdir -p db && ls -ld db"
```

## Testing Connections

Before syncing, test your connections:

```bash
./dev/syncdb/syncdb.sh
# Select: 2) Test connections
```

This verifies:
- SSH connectivity
- WP-CLI availability
- WordPress installation detection
- Remote directory creation permissions

## Troubleshooting

### "Cannot connect over SSH"
- Verify SSH config in `~/.ssh/config`
- Test manual SSH: `ssh mysite_prod`
- Check SSH key permissions: `chmod 600 ~/.ssh/mysite_rsa`

### "Command not found: wp"
- WP-CLI not installed on remote server
- Check path: `ssh mysite_prod "which wp"`

### "Can't create/write to file"
- Remote path doesn't exist or lacks permissions
- Verify: `ssh mysite_prod "pwd && mkdir -p db"`

### "Database import failed"
- Check local Lando is running: `lando info`
- Verify database credentials
- Check disk space

## Version Compatibility

This version includes improvements for:
- ✅ Vanilla WordPress installations
- ✅ Bedrock-based projects
- ✅ Flywheel hosting
- ✅ SpinupWP hosting
- ✅ Conditional framework-specific commands

## Security Notes

- Uses SSH key-based authentication (no passwords)
- Database dumps are temporary and automatically deleted
- Add `dev/db/*.sql` to `.gitignore` to prevent accidental commits
- Never commit SSH keys or credentials

## Contributing

This is a submodule shared across projects. To contribute:

1. Make changes in the submodule directory
2. Commit within the submodule
3. Push to the syncdb repository
4. Update parent projects to use new version

## Authors

- **Takahiro Noguchi** - takahiro@campaignupgrade.org
- **Scott LaMorte** - scott@campaignupgrade.org

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Campaign Upgrade
