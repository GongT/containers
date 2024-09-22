if [[ -e /config/conf.d/default_server.conf ]]; then
	echo "using provided default server."
	cat /config/conf.d/default_server.conf >/etc/nginx/conf.d/90-default_server.conf
else
	echo "use builtin default server."
	if ! [[ -e /config/conf.d/default_server.conf.example ]]; then
		echo "create default server example file."
		cat /etc/nginx/conf.d/90-default_server.conf >/config/conf.d/default_server.conf.example
	fi
fi
