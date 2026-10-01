FROM nginx:1.31.6 AS dav-ext-builder

ARG NGINX_VERSION=1.31.6
ARG DAV_EXT_MODULE_COMMIT=f5e30888a256136d9c550bf1ada77d6ea78a48af

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential ca-certificates curl libpcre2-dev libssl-dev libxml2-dev libxslt1-dev zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" | tar -xz -C /tmp && \
    curl -fsSL "https://github.com/arut/nginx-dav-ext-module/archive/${DAV_EXT_MODULE_COMMIT}.tar.gz" | tar -xz -C /tmp && \
    cd "/tmp/nginx-${NGINX_VERSION}" && \
    ./configure --with-compat --add-dynamic-module="/tmp/nginx-dav-ext-module-${DAV_EXT_MODULE_COMMIT}" && \
    make modules && \
    mkdir -p /out && \
    cp objs/ngx_http_dav_ext_module.so /out/

FROM nginx:1.31.6

LABEL maintainer="BaksiLi"

RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends apache2-utils certbot && \
    rm -rf /var/lib/apt/lists/*

COPY --from=dav-ext-builder /out/ngx_http_dav_ext_module.so /usr/lib/nginx/modules/ngx_http_dav_ext_module.so
RUN sed -i '1i load_module /usr/lib/nginx/modules/ngx_http_dav_ext_module.so;' /etc/nginx/nginx.conf

COPY webdav.conf /etc/nginx/conf.d/default.conf
RUN rm -f /etc/nginx/sites-enabled/*


RUN mkdir -p "/media/data"
RUN chown -R www-data:www-data "/media/data"
VOLUME /media/data


COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]