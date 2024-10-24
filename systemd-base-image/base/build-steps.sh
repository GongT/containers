buildah_cache_start "quay.io/fedora/fedora-minimal"
dnf_use_environment
dnf_install_step "systemd" scripts/dependencies.lst

setup_systemd "systemd" basic
