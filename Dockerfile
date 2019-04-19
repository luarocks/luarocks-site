FROM leafo/lapis-archlinux-itchio:latest
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/luarocks.org
ADD . .
RUN ./ci.sh
ENTRYPOINT ./entrypoint.sh
