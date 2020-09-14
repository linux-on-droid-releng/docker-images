#!/bin/bash

set -e

info() {
	echo "I: $@"
}

warning() {
	echo "W: $@" >&2
}

error() {
	echo "E: $@" >&2
	exit 1
}

IMAGE="${1}"
[ -n "${IMAGE}" ] || error "No image specified"

info "Building ${IMAGE}"

_sanitized=${IMAGE//-/_}
_sanitized=${_sanitized//./_}
_sanitized=${_sanitized//:/_}
_sanitized=${_sanitized////_}

ARCH=$(echo "${IMAGE}" | cut -d"/" -f1)

docker build -f "./Dockerfile.${_sanitized}" -t "${IMAGE}" .
