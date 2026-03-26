FROM php:8.2-apache

# Install dependencies for Git and SQLite
RUN apt-get update && apt-get install -y git unzip libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required (PDO SQLite)
RUN docker-php-ext-install pdo pdo_sqlite

# Clone the actual repository into the webroot
RUN rm -rf /var/www/html/* \
    && git clone https://github.com/azlux/Simple-URL-Shortener.git /tmp/shortener \
    && cp -r /tmp/shortener/* /var/www/html/ \
    && rm -rf /tmp/shortener \
    && cp /var/www/html/inc/config.example.php /var/www/html/inc/config.php

# Configure permissions
RUN chown -R www-data:www-data /var/www/html

# The application uses a "data" folder for the database/config that we must ensure exists and has permissions
RUN mkdir -p /var/www/html/data && chown -R www-data:www-data /var/www/html/data
