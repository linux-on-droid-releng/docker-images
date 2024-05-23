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

info "Pushing ${IMAGE}"

# Extract arch
ARCH=$(echo "${IMAGE}" | cut -d"/" -f1)
TARGET_TAG=registry.lindroid.org/${IMAGE/"${ARCH}/"/""}-"${ARCH}"

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin registry.lindroid.org
docker tag "${IMAGE}" "${TARGET_TAG}"
docker push "${TARGET_TAG}"
