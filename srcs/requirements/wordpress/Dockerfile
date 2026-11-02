FROM debian:12.15-slim

ARG WORDPRESS_VERSION=7.1
ARG WP_CLI_VERSION=2.12.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        mariadb-client \
        php8.2-cli \
        php8.2-curl \
        php8.2-fpm \
        php8.2-gd \
        php8.2-intl \
        php8.2-mbstring \
        php8.2-mysql \
        php8.2-xml \
        php8.2-zip \
        tar \
    && curl -fsSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz" -o /tmp/wordpress.tar.gz \
    && mkdir -p /usr/src/wordpress \
    && tar -xzf /tmp/wordpress.tar.gz -C /usr/src/wordpress --strip-components=1 \
    && rm /tmp/wordpress.tar.gz \
    && curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" -o /usr/local/bin/wp \
    && chmod 0755 /usr/local/bin/wp

COPY conf/zz-inception.conf /etc/php/8.2/fpm/pool.d/zz-inception.conf
COPY tools/entrypoint.sh /usr/local/bin/wordpress-entrypoint

RUN chmod 0755 /usr/local/bin/wordpress-entrypoint

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint"]