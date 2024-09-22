if [[ -e /config/selfsigned.key ]] && [[ -e /config/selfsigned.crt ]]; then
	echo "use exists openssl cert..."
else
	echo "create openssl cert..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -batch \
		-keyout "/config/selfsigned.key" \
		-out "/config/selfsigned.crt"
	echo "done..."
fi
