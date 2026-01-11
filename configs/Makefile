.PHONY: all

all: nginx.conf crontab

nginx.conf::
	scp luarocks.org:~/nginx.conf nginx.conf

crontab::
	ssh luarocks.org crontab -l > crontab

