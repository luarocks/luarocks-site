FROM ghcr.io/leafo/lapis-archlinux-itchio:2022-3-21
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/luarocks.org
ADD . .
RUN ./ci.sh
ENTRYPOINT ./entrypoint.sh
