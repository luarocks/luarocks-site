.PHONY: all install-mtail

all: nginx.conf crontab

nginx.conf::
	scp luarocks.org:~/nginx.conf nginx.conf

crontab::
	ssh luarocks.org crontab -l > crontab

install-mtail:
	sudo cp mtail-prod.service /etc/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl enable --now mtail-prod

