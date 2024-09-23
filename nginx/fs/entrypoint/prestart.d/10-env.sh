exportenv "CONFIG_ROOT" "/run/nginx/config"
exportenv "TESTING_DIR" "/tmp/testing"
exportenv "STORE_ROOT" "/run/nginx/contributed"
exportenv "CONFIG_FILE_LOCK" "/tmp/config-file.lock"

# SHARED_SOCKET_PATH

mkdir -p "/run/nginx/contributed" "/run/nginx/config" "/tmp/testing"
