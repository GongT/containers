function use_volume() {
	podman volume inspect $1 --format "{{.Mountpoint}}" || {
		podman volume create $1
		podman volume inspect $1 --format "{{.Mountpoint}}"
	}
}
