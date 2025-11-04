# https://hub.docker.com/orgs/cmooreio/hardened-images/catalog/dhi/alpine-base/images
FROM alpine:3.22

# https://nginx.org/en/download.html
# https://github.com/PCRE2Project/pcre2/releases
# https://github.com/cloudflare/zlib/commits/gcc.amd64/
# https://www.openssl.org/source/

ARG VERSION SHA256 PCRE2_VERSION PCRE2_SHA256 ZLIB_COMMIT_SHA ZLIB_SHA256 OPENSSL_VERSION OPENSSL_SHA256
ARG BROTLI_COMMIT_SHA HEADERS_MORE_COMMIT_SHA FANCYINDEX_COMMIT_SHA NJS_COMMIT_SHA BUILD_DATE VCS_REF

LABEL org.opencontainers.image.title="nginx" \
      org.opencontainers.image.description="Security-hardened nginx with OpenSSL 3.x and additional modules on Alpine Linux" \
      org.opencontainers.image.vendor="cmooreio" \
      org.opencontainers.image.source="https://github.com/cmooreio/nginx" \
      org.opencontainers.image.url="https://github.com/cmooreio/nginx" \
      org.opencontainers.image.documentation="https://github.com/cmooreio/nginx/blob/master/README.md" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.authors="cmooreio" \
      io.cmooreio.nginx.version="${VERSION}" \
      io.cmooreio.openssl.version="${OPENSSL_VERSION}" \
      io.cmooreio.pcre2.version="${PCRE2_VERSION}"

# Security: Set compiler hardening flags
ENV CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
    CXXFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security" \
    LDFLAGS="-Wl,-z,relro -Wl,-z,now"

# Set shell options for better error handling
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN : \
  && apk update \
  && apk upgrade \
  && apk add --no-cache \
      alpine-sdk \
      curl \
      gd-dev \
      geoip \
      geoip-dev \
      git \
      gzip \
      libgd \
      libxml2 \
      libxml2-dev \
      libxslt \
      libxslt-dev \
      linux-headers \
      perl \
      perl-dev \
      unzip \
      wget \
      zlib-dev \
  && mkdir -p /usr/local/src \
  && mkdir -p /usr/share/man/man8 \
  && cd /usr/local/src \
  && curl -L https://nginx.org/download/nginx-${VERSION}.tar.gz -o nginx-${VERSION}.tar.gz \
  && echo "${SHA256}  nginx-${VERSION}.tar.gz" | sha256sum -c - \
  && tar -xf nginx-${VERSION}.tar.gz \
  && curl -L https://github.com/PhilipHazel/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz -o pcre2-${PCRE2_VERSION}.tar.gz \
  && echo "${PCRE2_SHA256}  pcre2-${PCRE2_VERSION}.tar.gz" | sha256sum -c - \
  && mkdir -p /build/pcre \
  && tar -xf pcre2-${PCRE2_VERSION}.tar.gz --strip-components=1 -C /build/pcre \
  && curl -L https://api.github.com/repos/cloudflare/zlib/tarball/${ZLIB_COMMIT_SHA} -o zlib.tar.gz \
  && echo "${ZLIB_SHA256}  zlib.tar.gz" | sha256sum -c - \
  && mkdir -p /build/zlib \
  && tar -xf zlib.tar.gz --strip-components=1 -C /build/zlib \
  && cd /build/zlib \
  && ./configure \
  && cd /usr/local/src \
  && curl -L https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz -o openssl-${OPENSSL_VERSION}.tar.gz \
  && echo "${OPENSSL_SHA256}  openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && mkdir -p /build/openssl \
  && tar -xf openssl-${OPENSSL_VERSION}.tar.gz --strip-components=1 -C /build/openssl \
  && git clone --depth 1 --single-branch --recursive https://github.com/google/ngx_brotli.git /build/ngx_brotli \
  && cd /build/ngx_brotli \
  && git checkout "${BROTLI_COMMIT_SHA}" \
  && git submodule update --init --recursive \
  && git clone --depth 1 --single-branch --recursive https://github.com/openresty/headers-more-nginx-module.git /build/headers-more \
  && cd /build/headers-more \
  && git checkout "${HEADERS_MORE_COMMIT_SHA}" \
  && git clone --depth 1 --single-branch --recursive https://github.com/aperezdc/ngx-fancyindex.git /build/ngx-fancyindex \
  && cd /build/ngx-fancyindex \
  && git checkout "${FANCYINDEX_COMMIT_SHA}" \
  && git clone --depth 1 --single-branch --recursive https://github.com/nginx/njs.git /build/njs \
  && cd /build/njs \
  && git checkout "${NJS_COMMIT_SHA}" \
  && cd /usr/local/src/nginx-${VERSION} \
  && cp ./man/nginx.8 /usr/share/man/man8 \
  && gzip /usr/share/man/man8/nginx.8 \
  && mkdir -p /var/cache/nginx \
  && ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-select_module \
    --with-poll_module \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-http_perl_module=dynamic \
    --with-perl_modules_path=/usr/share/perl/5.26.1 \
    --with-perl=/usr/bin/perl \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-mail=dynamic \
    --with-mail_ssl_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_preread_module \
    --with-compat \
    --with-pcre=/build/pcre \
    --with-zlib=/build/zlib \
    --with-openssl=/build/openssl \
    --with-openssl-opt="no-nextprotoneg no-shared" \
    --add-dynamic-module=/build/ngx_brotli \
    --add-dynamic-module=/build/headers-more \
    --add-dynamic-module=/build/ngx-fancyindex \
    --add-dynamic-module=/build/njs/nginx \
  && make -j$(nproc) \
  && make install \
  && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx \
  && find /usr/lib/nginx/modules -name "*.so" -exec strip {} \; \
  && apk del --no-network \
      alpine-sdk \
      curl \
      gd-dev \
      geoip-dev \
      git \
      gzip \
      libxml2-dev \
      libxslt-dev \
      linux-headers \
      perl-dev \
      zlib-dev \
  && cd / \
  && rm -rf /var/cache/apk/* \
  && rm -f /usr/local/src/*.tar.gz \
  && rm -rf /usr/local/src/* \
  && rm -rf /build \
  && rm -rf /tmp/* \
  && rm -rf /root/.cache \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && addgroup -g 101 -S nginx \
  && adduser -D -u 101 -S -G nginx nginx \
  && mkdir -p \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/scgi_temp \
    /var/cache/nginx/uwsgi_temp \
  && chmod 700 /var/cache/nginx/* \
  && chown -R nginx:nginx /var/cache/nginx \
  && touch /var/run/nginx.pid \
  && chown nginx:nginx /var/run/nginx.pid \
  && chmod 755 /etc/nginx \
  && chmod 644 /etc/nginx/nginx.conf \
  && find /etc/nginx -type d -exec chmod 755 {} \; \
  && find /etc/nginx -type f -exec chmod 644 {} \;

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

STOPSIGNAL SIGTERM

USER nginx

CMD ["nginx", "-g", "daemon off;"]
