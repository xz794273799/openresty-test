# Dockerfile - centos 7

FROM centos:7

LABEL maintainer="朱回 <zhuhui@fosafer.com>"

# Docker Build Arguments
ARG RESTY_VERSION="1.13.6.2"
ARG RESTY_NGINX_VERSION="1.13.6"
ARG RESTY_LUAROCKS_VERSION="2.4.3"
ARG RESTY_OPENSSL_VERSION="1.0.2k"
ARG RESTY_PCRE_VERSION="8.43"

ARG RESTY_NGX_CACHE_PURGE_VERSION="2.3"
ARG RESTY_NGX_UPSTREAM_CHECK_VERSION="master"
ARG RESTY_CHECK_PATCH_VERSION="1.12.1+"
ARG CURL_USER="kaifa:kaifafosafer.com"

ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
	--with-stream_ssl_preread_module \
    --with-threads \
	--with-dtrace-probes \
	--with-http_iconv_module \
	--user=www \
    --group=www \
    "
ARG RESTY_CONFIG_OPTIONS_MORE="--add-module=/tmp/ngx_cache_purge-${RESTY_NGX_CACHE_PURGE_VERSION}/ --add-module=/tmp/nginx_upstream_check_module-${RESTY_NGX_UPSTREAM_CHECK_VERSION}/"

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"


# 1) Install apt dependencies
# 2) Download and untar OpenSSL, PCRE, and OpenResty
# 3) Build OpenResty
# 4) Cleanup

RUN yum install -y \
		gcc \
        gcc-c++ \
        gd-devel \
        gettext \
        GeoIP-devel \
        libxslt-devel \
        make \
        perl \
        perl-ExtUtils-Embed \
        readline-devel \
        unzip \
        zlib-devel \
		patch \	
    && cd /tmp \
    && curl -fSL ftp://10.10.11.40/public/nginx/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -u ${CURL_USER} -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL ftp://10.10.11.40/public/nginx/pcre-${RESTY_PCRE_VERSION}.tar.gz -u ${CURL_USER} -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
	&& curl -fSL ftp://10.10.11.40/public/nginx/ngx_cache_purge-${RESTY_NGX_CACHE_PURGE_VERSION}.tar.gz -u ${CURL_USER} -o ngx_cache_purge-${RESTY_NGX_CACHE_PURGE_VERSION}.tar.gz \
    && tar xzf ngx_cache_purge-${RESTY_NGX_CACHE_PURGE_VERSION}.tar.gz \
	&& curl -fSL ftp://10.10.11.40/public/nginx/nginx_upstream_check_module-${RESTY_NGX_UPSTREAM_CHECK_VERSION}.zip -u ${CURL_USER} -o nginx_upstream_check_module-${RESTY_NGX_UPSTREAM_CHECK_VERSION}.zip \
    && unzip nginx_upstream_check_module-${RESTY_NGX_UPSTREAM_CHECK_VERSION}.zip \
    && curl -fSL ftp://10.10.11.40/public/nginx/openresty-${RESTY_VERSION}.tar.gz -u ${CURL_USER} -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
	&& cd /tmp/openresty-${RESTY_VERSION}/bundle/nginx-${RESTY_NGINX_VERSION} \
	&& patch -p1 < /tmp/nginx_upstream_check_module-${RESTY_NGX_UPSTREAM_CHECK_VERSION}/check_${RESTY_CHECK_PATCH_VERSION}.patch \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && curl -fSL ftp://10.10.11.40/public/nginx/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz  -u ${CURL_USER} -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && cd luarocks-${RESTY_LUAROCKS_VERSION} \
    && ./configure \
        --prefix=/usr/local/openresty/luajit \
        --with-lua=/usr/local/openresty/luajit \
        --lua-suffix=jit-2.1.0-beta3 \
        --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make build \
    && make install \
    && cd /tmp \
    && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
    && yum remove -y make \
    && yum clean all \
    && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT