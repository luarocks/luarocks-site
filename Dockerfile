FROM ghcr.io/leafo/lapis-archlinux-itchio:2026-04-23
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/luarocks.org
ADD . .
RUN ./ci.sh
ENTRYPOINT ./entrypoint.sh
