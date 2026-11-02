*This project has been created as part of the 42 curriculum by abougati.*

# Description

Inception builds a small WordPress infrastructure with Docker Compose. Each mandatory service is built from its own Dockerfile on the penultimate stable Debian release (`debian:12.15-slim`, Bookworm), and each service has one responsibility:

- **NGINX** is the only host entrypoint. It accepts TLS 1.2/1.3 traffic on port 443 and forwards PHP requests to PHP-FPM.
- **WordPress + PHP-FPM** serves the application on the internal Docker network at port 9000 and initializes WordPress automatically with two users.
- **MariaDB** stores the WordPress database and listens only on the configured internal `MYSQL_PORT` (3306 by default).

The services communicate over the user-defined `inception` bridge network. Docker DNS resolves the service names `mariadb` and `wordpress`; no container IP addresses, host networking, or legacy links are used. The database and website files persist in two Docker named volumes backed by `/home/abougati/data/mariadb` and `/home/abougati/data/wordpress`.

## Design choices

| Topic | Difference and choice in this project |
| --- | --- |
| Virtual machines vs Docker | A VM virtualizes hardware and runs a complete guest OS. A container shares the host kernel and isolates processes and filesystems, so it starts faster and uses fewer resources. The required Ubuntu VM provides the host boundary; Docker provides one lightweight container per service inside it. |
| Secrets vs environment variables | Environment variables are convenient for non-confidential settings but are visible in container configuration. This project keeps the domain, database name, and usernames in `srcs/.env`; passwords are created manually in ignored files and mounted only into the containers that need them as Compose secrets. |
| Docker network vs host network | A bridge network gives the stack isolated addressing and service-name DNS. Host networking removes that isolation and can create host port conflicts. This project uses the explicit `inception` bridge and publishes only NGINX port 443. |
| Docker volumes vs bind mounts | A direct bind mount is declared on a service and couples it directly to an arbitrary host path. A named volume is a Docker-managed object that can be listed and inspected. The subject requires named volumes and host storage under `/home/abougati/data`, so top-level named volumes use the local driver's bind options while services mount only the volume names. |

The images install NGINX, PHP-FPM, MariaDB, WordPress, and WP-CLI themselves; no ready-made service image is used. On fresh volumes, the MariaDB and WordPress entrypoints initialize the database and site from the local secrets. On later starts they preserve that state and execute the real foreground service; NGINX starts directly in the foreground.

# Instructions

## Prerequisites

- Ubuntu VM with Docker Engine and the `docker compose` plugin
- GNU Make
- permission to create `/home/abougati/data` (the first run may invoke `sudo`)
- local name resolution for `abougati.42.fr`

Add the VM IP and domain to the machine from which the site will be opened:

```text
<VM_IP> abougati.42.fr
```

Do not commit this machine-specific address to the repository.

## Build and run

From the repository root:

```sh
make
```

Before the first run, manually create the four non-empty password files listed in [USER_DOC.md](USER_DOC.md) and keep them local. `make` creates the host data directories, validates those files and sets mode `0600`, builds all images, and launches the stack. Then open:

- Website: `https://abougati.42.fr`
- Dashboard: `https://abougati.42.fr/wp-admin/`

The certificate is self-signed, so a browser warning is expected. HTTP is intentionally unavailable.

Useful commands:

```sh
make ps
make logs
make stop
make start
make down      # removes containers/network, preserves persistent data
make clean     # also removes project-built images, preserves persistent data
make re        # clean rebuild and relaunch
```

See [USER_DOC.md](USER_DOC.md) for administration and [DEV_DOC.md](DEV_DOC.md) for setup and inspection.

# Resources

- [Inception subject v5.3](https://projects.intra.42.fr/)
- [Debian releases](https://www.debian.org/releases/) — identifies Debian 13 as stable and Debian 12 as oldstable/penultimate stable
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker named volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker Compose volume configuration](https://docs.docker.com/reference/compose-file/volumes/)
- [MariaDB server documentation](https://mariadb.com/kb/en/mariadbd-options/)
- [NGINX HTTPS configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [WordPress requirements](https://wordpress.org/about/requirements/)
- [WordPress release archive](https://wordpress.org/download/releases/)
- [WP-CLI installation guide](https://make.wordpress.org/cli/handbook/guides/installing/)

AI was used to help cross-check the subject, verify current official release information, clarify technical concepts, improve documentation, and suggest validation commands and testing approaches. The learner integrated, reviewed, tested, and understands the final implementation, and remains responsible for defending and independently validating the project.