# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://hyperf.wiki
# @contact  group@hyperf.io
# @license  https://github.com/hyperf/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:8.1-alpine-v3.16-swow
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT" app.name="Hyperf"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    APP_ENV=prod \
    SCAN_CACHEABLE=(true)

# update
RUN set -ex \
    # Install Micro
    && wget https://alpine-apk-repository.knowyourself.cc/micro/v0.1.0/micro.8.1.arm64.sfx \
    && wget https://alpine-apk-repository.knowyourself.cc/micro/v0.1.0/micro.8.1.x86_64.sfx \
    # show php version and extensions
    && php -v \
    && php -m \
    && php --ri swow \
    #  ---------- some config ----------
    && cd /etc/php* \
    # - config PHP
    && { \
        echo "upload_max_filesize=128M"; \
        echo "post_max_size=128M"; \
        echo "memory_limit=1G"; \
        echo "date.timezone=${TIMEZONE}"; \
        echo "phar.readonly=Off"; \
    } | tee conf.d/99_overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"

WORKDIR /opt/www

# Composer Cache
# COPY ./composer.* /opt/www/
# RUN composer install --no-dev --no-scripts

COPY . /opt/www
RUN composer install --no-dev -o && php bin/hyperf.php && php bin/hyperf.php phar:build --name box.phar \
    && cat /micro.8.1.arm64.sfx box.phar > box.macos.arm64 && chmod u+x box.macos.arm64 \
    && cat /micro.8.1.x86_64.sfx box.phar > box.macos.x86_64 && chmod u+x box.macos.x86_64

EXPOSE 9764
