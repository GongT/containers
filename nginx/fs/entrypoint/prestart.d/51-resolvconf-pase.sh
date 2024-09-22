
if [[ -e /etc/resolv.conf ]]; then
	SYSTEM_RESOLVERS="$(
		cat /etc/resolv.conf | grep -v '^#' | grep -v '127.0.0.1' | grep nameserver | sed -E 's/^nameserver\s+//g'
	)" || true
else
	SYSTEM_RESOLVERS=""
fi
mapfile -t SYSTEM_RESOLVERS_ARR < <(echo "$SYSTEM_RESOLVERS")
(
	RES=()
	for I in "${SYSTEM_RESOLVERS_ARR[@]}"; do
		if [[ ! $I ]]; then
			continue
		fi
		if [[ $I == *:*:* ]]; then
			RES+=("[$I]")
		else
			RES+=("$I")
		fi
	done

	if [[ ${#RES[@]} -eq 0 ]]; then
		RES=(1.1.1.1 119.29.29.29)
	fi
	echo "resolver ${RES[*]};"
) >/config/conf.d/resolver.conf
