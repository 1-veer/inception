FROM debian:12.15-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mariadb-server \
    && rm -rf /var/lib/mysql/*

COPY conf/60-inception.cnf /etc/mysql/mariadb.conf.d/60-inception.cnf
COPY tools/entrypoint.sh /usr/local/bin/mariadb-entrypoint

RUN chmod 0755 /usr/local/bin/mariadb-entrypoint

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint"]
