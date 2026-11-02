# Inception Developer Guide

## Prerequisites

- A Linux VM (the project target is Ubuntu Desktop 24.04 LTS)
- Docker Engine with Compose v2 (`docker compose`)
- GNU Make
- `sudo` rights when `/home/abougati` cannot be created by the current Linux user

Confirm the tools before setup:

```sh
docker --version
docker compose version
make --version
```

## Repository configuration

All infrastructure files are in `srcs/`. The safe, non-confidential settings are in `srcs/.env`:

- `COMPOSE_PROJECT_NAME`
- `DOMAIN_NAME`
- `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_HOST`, and `MYSQL_PORT`
- WordPress title, usernames, and email addresses

Do not add passwords to `.env`. Compose reads four password files from `secrets/`; `.gitignore` excludes every `secrets/*.txt` file while retaining `secrets/.gitkeep`.

The default administrator name is `siteowner`. Any replacement must not contain `admin` in any letter case. Keep the administrator and normal usernames distinct.

## Setup from scratch

Run this from the repository root:

```sh
make setup
make secrets
make up
```

`make setup` creates these exact host directories:

```text
/home/abougati/data/mariadb
/home/abougati/data/wordpress
```

They begin with mode `0750`. The containers assign service ownership inside their mounts (`mysql` for the database and `www-data` for WordPress); the project never uses mode `0777`.

Before running these targets, manually create the following four non-empty files:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Run `chmod 0600 secrets/*.txt` after creating them. `make secrets` only validates that every file exists and is non-empty, then enforces mode `0600`; it never generates or replaces a password.

These files are runtime inputs and must remain untracked. Keep them alongside the persistent installation: replacing a file does not automatically rotate an account that was created on the first run. Verify that they are ignored without printing their contents:

```sh
git check-ignore secrets/db_password.txt secrets/db_root_password.txt \
  secrets/wp_admin_password.txt secrets/wp_user_password.txt
git ls-files secrets
```

## Build and lifecycle commands

```sh
make            # setup, validate local secrets, build, launch
make build      # build all local images
make up         # build and launch/recreate in detached mode
make ps         # Compose service status
make logs       # follow logs
make stop       # stop without removal
make start      # start stopped containers
make down       # remove containers/network; preserve data
make clean      # remove containers/network/local images; preserve data
make re         # clean build and relaunch; preserve data
```

Equivalent Compose commands use the explicit file:

```sh
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml build
docker compose -f srcs/docker-compose.yml up -d
docker compose -f srcs/docker-compose.yml down
```

## Architecture and initialization

All images start from `debian:12.15-slim`, the current Bookworm point release. Debian 13 is stable, making Debian 12 the subject-required penultimate stable release.

- `mariadb-entrypoint` initializes system tables, the WordPress database, and its accounts only when `/var/lib/mysql` is fresh. MariaDB executes the first-run SQL through `--init-file` and remains the foreground process throughout; later starts leave the database untouched.
- `wordpress-entrypoint` copies core files only into an empty website volume, generates `wp-config.php` with WP-CLI, performs a bounded database readiness check, and creates the site and its two users only when WordPress is not installed. It also updates `DB_HOST` on existing volumes so an internal MariaDB port change is applied. Later starts preserve the accounts and execute `php-fpm8.2 -F`.
- The NGINX image creates its self-signed certificate during the image build with the requested subject and `DNS:abougati.42.fr` SAN. It starts `nginx -g 'daemon off;'` directly, without an entrypoint script.

No entrypoint uses a keepalive shell, background daemon, or unbounded wait. WordPress's 120-second database check handles MariaDB readiness. Compose checks PHP-FPM's local TCP listener with PHP itself and starts NGINX only after WordPress is healthy.

## Inspect containers, images, network, and ports

```sh
docker compose -f srcs/docker-compose.yml ps
docker images mariadb wordpress nginx
docker inspect mariadb wordpress nginx
docker top mariadb
docker top wordpress
docker top nginx
docker logs mariadb
docker logs wordpress
docker logs nginx
docker network ls
docker network inspect inception
docker port nginx
docker port wordpress   # no published ports expected
docker port mariadb     # no published ports expected
```

The service processes should be PID 1 in their containers. Docker DNS provides the configured `MYSQL_HOST:MYSQL_PORT` (by default `mariadb:3306`) to WordPress and `wordpress:9000` to NGINX.

## Database inspection

Interactive root login (type the value from the ignored root-secret file at the prompt):

```sh
docker exec -it mariadb mariadb -u root -p
```

Useful SQL for database inspection:

```sql
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT User, Host FROM mysql.user;
SHOW GRANTS FOR 'wpuser'@'%';
```

WordPress inspection:

```sh
docker exec wordpress wp --allow-root --path=/var/www/html core is-installed
docker exec wordpress wp --allow-root --path=/var/www/html user list
docker exec wordpress wp --allow-root --path=/var/www/html core version
```

## Named volumes and persistence

Compose creates exactly two application volumes:

```sh
docker volume ls
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

Their local-driver `device` values are `/home/abougati/data/mariadb` and `/home/abougati/data/wordpress`. Services mount the named volume objects, not direct host-path mounts. Database tables persist at `/var/lib/mysql`; WordPress files persist at `/var/www/html`.

Container, network, and image recreation does not remove those named volumes or their host data. To verify persistence, edit a WordPress page, run `make clean && make`, and confirm the edit and database tables remain. A VM reboot should have the same result after `make up`.

This repository intentionally provides no automatic data-destruction target. A full reset must be a deliberate manual operation: first stop the project, explicitly remove only the two `inception_*_data` volumes, and then empty only the two documented `/home/abougati/data` subdirectories after confirming their exact paths.

## TLS checks

```sh
openssl s_client -connect 127.0.0.1:443 -servername abougati.42.fr -tls1_2 </dev/null
openssl s_client -connect 127.0.0.1:443 -servername abougati.42.fr -tls1_3 </dev/null
openssl s_client -connect 127.0.0.1:443 -servername abougati.42.fr -tls1_1 </dev/null
openssl s_client -connect 127.0.0.1:443 -servername abougati.42.fr </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -ext subjectAltName
```

TLS 1.2 and 1.3 should negotiate. TLS 1.1 should be rejected.
