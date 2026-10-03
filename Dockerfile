FROM php:8.2-apache-bookworm
ARG LODEL_VERSION=1.1.0
ENV APACHE_DOCUMENT_ROOT=/var/www/html LODEL_VERSION=${LODEL_VERSION}
RUN apt-get update && apt-get install -y --no-install-recommends libfreetype6-dev libjpeg62-turbo-dev libpng-dev libicu-dev libzip-dev libxml2-dev libcurl4-openssl-dev libmemcached-dev zlib1g-dev libssl-dev libsasl2-dev curl unzip git ca-certificates rsync \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" curl gd intl mbstring mysqli opcache readline xml zip \
 && pecl install memcache-8.2 memcached-3.3.0 \
 && docker-php-ext-enable memcache memcached \
 && a2enmod rewrite headers access_compat expires \
 && rm -rf /var/lib/apt/lists/* /tmp/pear
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /opt/lodel
COPY . /opt/lodel/
RUN test -f /opt/lodel/lodel/scripts/composer.json && cd /opt/lodel/lodel/scripts && composer install --no-dev --prefer-dist --no-interaction --no-progress --optimize-autoloader
COPY docker/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/zz-ceredis-lodel.ini
COPY docker/entrypoint.sh /usr/local/bin/ceredis-lodel-entrypoint
RUN chmod +x /usr/local/bin/ceredis-lodel-entrypoint && mkdir -p /var/www/html && chown -R www-data:www-data /opt/lodel
WORKDIR /var/www/html
ENTRYPOINT ["ceredis-lodel-entrypoint"]
CMD ["apache2-foreground"]
