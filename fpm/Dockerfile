FROM php:7.1-fpm

LABEL vendor="Mautic"
LABEL maintainer="Luiz Eduardo Oliveira Fonseca <luiz@powertic.com>"

# Install PHP extensions
RUN set -ex; \
    apt-get update && apt-get install --no-install-recommends -y \
        cron \
        git \
        wget \
        sudo \
        libc-client-dev \
        libicu-dev \
        libkrb5-dev \
        libmcrypt-dev \
        libssl-dev \
        libz-dev \
        unzip \
        zip \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    rm /etc/cron.daily/*; \
    docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos; \
    docker-php-ext-configure opcache --enable-opcache; \
    docker-php-ext-install \
        imap \
        intl \
        mbstring \
        mcrypt \
        mysqli \
        pdo_mysql \
        zip \
        opcache \
        bcmath \
    ; \
    docker-php-ext-enable \
        imap \
        intl \
        mbstring \
        mcrypt \
        mysqli \
        pdo_mysql \
        zip \
        opcache \
        bcmath \
    ;

# Define Mautic volume to persist data
VOLUME /var/www/html

# Define Mautic version and expected SHA1 signature
ENV MAUTIC_VERSION=2.15.3 \
    MAUTIC_SHA1=d6ec21376ceacd8bbb8d9ee58e81d8050a79c0b8 \
    MAUTIC_SRC_SHA1=e9d64733c55122a454ebe402ccb00d599b72b341 \
    MAUTIC_RUN_CRON_JOBS=true \
    MAUTIC_DB_USER=root \
    MAUTIC_DB_NAME=mautic \
    PHP_INI_DATE_TIMEZONE='UTC' \
    PHP_MEMORY_LIMIT=512M \
    PHP_MAX_UPLOAD=128M \
    PHP_MAX_EXECUTION_TIME=300

# Install composer and download sources
RUN set -ex; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer; \
    curl -o mautic-src.zip -SL https://github.com/mautic/mautic/archive/${MAUTIC_VERSION}.zip; \
    echo "$MAUTIC_SRC_SHA1 *mautic-src.zip" | sha1sum -c -; \
    mkdir -p /usr/src/mautic-src; \
    unzip mautic-src.zip -d /usr/src/mautic-src; \
    rm mautic-src.zip; \
    chown -R www-data:www-data /usr/src/mautic-src;

# Download package and extract to web volume
RUN set -ex; \
    curl -o mautic.zip -SL https://github.com/mautic/mautic/releases/download/${MAUTIC_VERSION}/${MAUTIC_VERSION}.zip; \
    echo "$MAUTIC_SHA1 *mautic.zip" | sha1sum -c -; \
    mkdir /usr/src/mautic; \
    unzip mautic.zip -d /usr/src/mautic; \
    rm mautic.zip; \
    chown -R www-data:www-data /usr/src/mautic;

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makeconfig.php makedb.php /
COPY mautic.crontab /etc/cron.d/mautic
RUN chmod 644 /etc/cron.d/mautic

# Apply necessary permissions
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
