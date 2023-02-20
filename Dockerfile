# Dockerfile for RosarioSIS
# https://www.rosariosis.org/
# Best Dockerfile practices: http://crosbymichael.com/dockerfile-best-practices.html

# https://hub.docker.com/_/php?tab=tags&page=1&name=apache
# TODO When moving to PHP8.0, remove xmlrpc extension!
FROM php:7.4-apache

LABEL maintainer="François Jacquet <francoisjacquet@users.noreply.github.com>"

ENV DBTYPE=postgresql \
    PGHOST=db \
    PGUSER=rosario \
    PGPASSWORD=rosariopwd \
    PGDATABASE=rosariosis \
    PGPORT=5432 \
    ROSARIOSIS_YEAR=2022 \
    ROSARIOSIS_LANG='en_US'

# Upgrade packages.
# Install git, Apache2 + PHP + PostgreSQL client, sendmail, wkhtmltopdf & others utilities.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install postgresql-client wkhtmltopdf libpq-dev libjpeg-dev libpng-dev libxml2-dev libzip-dev libcurl4-gnutls-dev libonig-dev sendmail nano locales  -y;

# Install PHP extensions.
RUN docker-php-ext-configure gd --with-jpeg; \
    docker-php-ext-install -j$(nproc) gd mbstring xml pgsql gettext intl xmlrpc zip curl

# Download and extract rosariosis
ENV ROSARIOSIS_VERSION 'v10.8'
RUN mkdir /usr/src/rosariosis && \
    curl -L https://gitlab.com/francoisjacquet/rosariosis/-/archive/${ROSARIOSIS_VERSION}/rosariosis-${ROSARIOSIS_VERSION}.tar.gz \
    | tar xz --strip-components=1 -C /usr/src/rosariosis && \
    rm -rf /var/www/html && mkdir -p /var/www && \
    ln -s /usr/src/rosariosis/ /var/www/html && chmod 777 /var/www/html &&\
    chown -R www-data:www-data /usr/src/rosariosis

# Copy our configuration files.
COPY conf/config.inc.php /usr/src/rosariosis/config.inc.php
COPY conf/.htaccess /usr/src/rosariosis/.htaccess
COPY bin/init /init

EXPOSE 80

ENTRYPOINT ["/init"]
CMD ["apache2-foreground"]
