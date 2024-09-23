if [[ -n "${PROXY-}" ]]; then
	git config --global http.proxy "${PROXY}"
	git config --global https.proxy "${PROXY}"
fi
