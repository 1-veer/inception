#!/bin/sh
set -e

install -d -o www-data -g www-data /run/php
install -d -o www-data -g www-data /var/www/html

if [ ! -f /var/www/html/wp-load.php ]; then
    cp -a /usr/src/wordpress/. /var/www/html/
fi

chown -R www-data:www-data /var/www/html

if [ ! -f /var/www/html/wp-config.php ]; then
    db_password=$(cat /run/secrets/db_password)

    runuser -u www-data -- wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$db_password" \
        --dbhost="${MYSQL_HOST}:${MYSQL_PORT}" \
        --skip-check
fi

runuser -u www-data -- wp config set DB_HOST \
    "${MYSQL_HOST}:${MYSQL_PORT}" \
    --path=/var/www/html \
    --quiet

attempt=1
while ! runuser -u www-data -- wp db check \
    --path=/var/www/html --quiet >/dev/null 2>&1
do
    [ "$attempt" -ge 60 ] && exit 1
    sleep 2
    attempt=$((attempt + 1))
done

if ! runuser -u www-data -- wp core is-installed \
    --path=/var/www/html --quiet
then
    wp_admin_password=$(cat /run/secrets/wp_admin_password)
    wp_user_password=$(cat /run/secrets/wp_user_password)

    runuser -u www-data -- wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$wp_admin_password" \
        --admin_email="$WP_ADMIN_EMAIL"

    runuser -u www-data -- wp user create \
        "$WP_USER" "$WP_USER_EMAIL" \
        --path=/var/www/html \
        --role=subscriber \
        --user_pass="$wp_user_password"
fi

exec php-fpm8.2 -F