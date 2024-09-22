if [[ -e /config/dhparam.pem ]]; then
	echo "good, found dhparam.pem"
	if ! grep -q '^ssl_dhparam ' /etc/nginx/params/ssl_params; then
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params
		echo "ssl_dhparam /config/dhparam.pem;" >>/etc/nginx/params/ssl_params_stream
	fi
elif ! [[ $DISABLE_SSL ]]; then
	echo 'Not using DH parameters file!
download one using: 
	curl https://ssl-config.mozilla.org/ffdhe2048.txt > /XXX/config/nginx/dhparam.pem

' >&2
fi
