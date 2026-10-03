# CEREDIS Lodel deployment

This branch packages OpenEdition Lodel v1.1.0 for Docker Compose and Coolify.

## Versions

- Lodel v1.1.0
- PHP 8.2
- MariaDB 11.4
- Composer dependencies installed from the repository lock file

## Coolify secrets

Set:
- LODEL_DB_PASSWORD
- LODEL_DB_ROOT_PASSWORD

Optional:
- LODEL_DB_NAME (default: lodel)
- LODEL_DB_USER (default: lodel)
- LODEL_TIMEZONE (default: Africa/Brazzaville)
- LODEL_LOCALE (default: fr_FR.UTF-8)

Do not commit passwords or lodelconfig.php.

## First installation

1. Deploy the Compose stack.
2. Configure the domain as https://publications.ceredis.net.
3. Open https://publications.ceredis.net/lodeladmin/install.php.
4. Verify the PHP extension and database checks.
5. Run the Lodel installer.
6. Create a permanent Lodel administrator.
7. Delete the temporary SuperAdmin account.
8. Delete the installation-key file generated in the document root.
9. Back up the database and lodel-data volume.

## Persistence

The full Lodel document root is persisted because Lodel creates site-specific files, symlinks, uploads, annexes, sources, icons and templates below the document root.

MariaDB data is persisted separately.

Do not remove either volume.

## Upgrade policy

Do not upgrade Lodel blindly after production data exists. The current image initializes the persistent document root only when it is empty. Any future upgrade must be handled as an explicit migration with backup and rollback.

## Security

MariaDB is not published by this Compose file. It is reachable only by the Lodel container on the Compose network.

After installation, remove the temporary installation key. Cloudflare/Traefik should terminate HTTPS; Apache listens only on the internal network.
