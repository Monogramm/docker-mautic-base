FROM php:7.3-fpm

LABEL vendor="Mautic"
LABEL maintainer="Luiz Eduardo Oliveira Fonseca <luiz@powertic.com>"

# Install PHP extensions
# Install composer
RUN set -ex; \
    apt-get update && apt-get install --no-install-recommends -y \
        ca-certificates \
        build-essential  \
        software-properties-common \
        cron \
        git \
        htop \
        wget \
        dos2unix \
        curl \
        libcurl4-gnutls-dev \
        sudo \
        libc-client-dev \
        libkrb5-dev \
        libmcrypt-dev \
        libssl-dev \
        libxml2-dev \
        libzip-dev \
        libjpeg-dev \
        libmagickwand-dev \
        libpng-dev \
        libgif-dev \
        libtiff-dev \
        libz-dev \
        libpq-dev \
        imagemagick \
        graphicsmagick \
        libwebp-dev \
        libjpeg62-turbo-dev \
        libxpm-dev \
        libaprutil1-dev \
        libicu-dev \
        libfreetype6-dev \
        unzip \
        zip \
        mariadb-client \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*; \
    rm /etc/cron.daily/*; \
    docker-php-ext-configure gd --with-freetype-dir=/usr/lib --with-png-dir=/usr/lib --with-jpeg-dir=/usr/lib; \
    docker-php-ext-install gd; \
    docker-php-ext-configure opcache --enable-opcache; \
    docker-php-ext-configure imap --with-imap --with-imap-ssl --with-kerberos; \
    docker-php-ext-install \
        imap \
        intl \
        mbstring \
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
        mysqli \
        pdo_mysql \
        zip \
        opcache \
        bcmath \
    ; \
    curl -sS 'https://getcomposer.org/installer' | php -- --install-dir=/usr/bin --filename=composer

# Define Mautic volume to persist data
VOLUME /var/www/html

# Define Mautic version and expected SHA1 signature
ENV MAUTIC_VERSION=2.16.2 \
    MAUTIC_SHA1=df6735df8d7d31cc6bc505c38ee8147b40b8311b \
    MAUTIC_SRC_SHA1=3dbd45ba8ebfadf5511ddde9d175753505b850eb \
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


# Apply necessary permissions
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
