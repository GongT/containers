UIPORT="${RANDOM}"

exportenv UIPORT "${UIPORT}"

mkdir -p /var/log/nginx/

FILES=(
	/opt/base-config.jsonc
	/etc/nginx/nginx.conf
	/etc/nginx/pass.conf
	/opt/nginx-attach.conf
)

for F in "${FILES[@]}"; do
	sed -i "s#__PROFILE__#$PROFILE#g; s#__UIPORT__#$UIPORT#g; s#__PORT__#$PORT#g; s#__SERVER_NAME__#$SERVER_NAME#g" "${F}"
done
