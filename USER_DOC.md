# Inception User Guide

## What the stack provides

The stack provides a WordPress website at `https://abougati.42.fr`. NGINX terminates TLS on host port 443, PHP-FPM runs WordPress, and MariaDB stores its database. MariaDB and PHP-FPM are not exposed on host ports.

The TLS certificate is self-signed. A certificate warning is normal in a browser; accepting it locally does not enable plain HTTP.

## First start

From the repository root, run:

```sh
make
```

On the first run, the Makefile:

1. creates `/home/abougati/data/mariadb` and `/home/abougati/data/wordpress` (it may ask for `sudo`);
2. validates the four manually created, non-empty password files in `secrets/` and sets mode `0600`;
3. builds and starts the three containers;
4. installs WordPress automatically with the configured administrator and normal user.

Configure the client machine to resolve `abougati.42.fr` to the VM IP. For example, add this to the client's `/etc/hosts` using the real VM address:

```text
<VM_IP> abougati.42.fr
```

## Access

- Website: `https://abougati.42.fr/`
- Administration panel: `https://abougati.42.fr/wp-admin/`

The usernames are stored as non-secret settings in `srcs/.env`:

- administrator: `WP_ADMIN_USER` (`siteowner` by default; it deliberately contains no `admin` substring)
- normal user: `WP_USER` (`siteuser` by default)

Their passwords are local secrets:

- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

Read a password locally when needed; never paste it into documentation, `.env`, YAML, a Dockerfile, or Git. Keep each file mode at `0600`.

## Start and stop

```sh
make stop      # stop containers without removing them
make start     # start the same containers
make down      # remove containers and network; keep all data
make up        # build if required and launch/recreate the stack
```

Normal stop, down, clean, and rebuild operations preserve both named volumes and the data below `/home/abougati/data`.

## Check service status

```sh
make ps
docker compose -f srcs/docker-compose.yml logs --tail=100
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

All three containers should be running, and WordPress should become healthy. Only NGINX should show a host mapping, `0.0.0.0:443->443/tcp` (and possibly its IPv6 equivalent).

Basic endpoint checks:

```sh
curl -kI --resolve abougati.42.fr:443:127.0.0.1 https://abougati.42.fr/
curl -I --max-time 3 http://abougati.42.fr/   # expected to fail
```

## Manage credentials

Manually create these four files before first startup: `db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`, and `wp_user_password.txt`, all below `secrets/`. They establish the credentials during initial MariaDB and WordPress setup. `make secrets` only rejects missing/empty files and sets mode `0600`; it never generates or replaces their contents.

Replacing a secret file later does not automatically rotate the corresponding credential stored in MariaDB or WordPress. In particular, changing `db_password.txt` alone is insufficient: MariaDB retains the existing database credential, and the persistent WordPress `wp-config.php` still uses it.

For normal use, keep the same secret files together with the persistent installation. Automatic password rotation is intentionally not implemented.

The MariaDB root password is stored in `secrets/db_root_password.txt`. To log in as the MariaDB root user:

```sh
docker exec -it mariadb mariadb -u root -p
```

Enter the local root-secret value at the prompt. Do not put it directly on the command line.
