FROM ghcr.io/leafo/lapis-archlinux-itchio:2022-3-21
MAINTAINER leaf corcoran <leafot@gmail.com21

WORKDIR /site/luarocks.org
ADD . .
RUN ./ci.sh
ENTRYPOINT ./entrypoint.sh
