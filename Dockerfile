FROM php:7.4-apache

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libicu-dev libxml2-dev libonig-dev unzip curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) mysqli pdo_mysql gd zip intl soap bcmath calendar mbstring

# 获取构建平台架构
ARG TARGETARCH

# 动态下载对应架构的 ionCube
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        IONCUBE_LINK="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz"; \
    else \
        IONCUBE_LINK="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"; \
    fi \
    && curl -fsSL $IONCUBE_LINK -o ioncube.tar.gz \
    && tar -xzf ioncube.tar.gz \
    && cp ioncube/ioncube_loader_lin_7.4.so $(php -r "echo ini_get('extension_dir');") \
    && rm -rf ioncube.tar.gz ioncube \
    && echo "zend_extension=ioncube_loader_lin_7.4.so" > /usr/local/etc/php/conf.d/00-ioncube.ini

# 写入 PHP 关键配置
RUN { \
    echo 'memory_limit=512M'; \
    echo 'max_execution_time=300'; \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'date.timezone=Asia/Shanghai'; \
    echo 'display_errors=Off'; \
    } > /usr/local/etc/php/conf.d/whmcs-custom.ini

RUN a2enmod rewrite
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html
