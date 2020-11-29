#!/bin/bash
#
# Quick and dirty deployer
#

if [ "${HAS_JOSH_K_SEAL_OF_APPROVAL}" == "true" ]; then
	# Travis CI

	BRANCH="${TRAVIS_BRANCH}"
	COMMIT="${TRAVIS_COMMIT}"
	if [ -n "${TRAVIS_TAG}" ]; then
		TAG="${TRAVIS_TAG}"
	fi
elif [ "${DRONE}" == "true" ]; then
	# Drone CI

	BRANCH="${DRONE_BRANCH}"
	COMMIT="${DRONE_COMMIT}"
	if [ -n "${DRONE_TAG}" ]; then
		TAG="${DRONE_TAG}"
	fi
else
	# Sorry
	echo "This script runs only on Travis CI or Drone CI!"
	exit 1
fi

# Load SSH KEY
echo "Loading SSH key"
mkdir -p ~/.ssh

eval $(ssh-agent -s)
ssh-add <(echo "${INTAKE_SSH_KEY}")

# Push fingerprint (this must be changed manually)
cat > ~/.ssh/known_hosts <<EOF
# repo.hybris-mobian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.hybris-mobian.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRI1DlHPFiRCrQCLXGRN7nuIBN9Wzp4/ugfpd915icurvaahGYXN3WbfFDMIQLfMal3grqxGaJpzLGaLC1th9Pkz3sdeeGAjdcR+kvm1lwgkIbu80MXj7bb4QB0vqTn2IhKviw4f+l+Y0jKH1A0Y8bnwyzIeMcVXbhK9QYvbux+QTGqCbPmEPs0ednfyfHDQ/bodlL8w2CG72WLXbCetS8eO1rtg0m2WKWmUxKkAx6TD9ZSEHBrgAimwQ2KZQfUeo2rx+DKogFpQq1LC65flWYY2jasOr6x9hwn1OpwAg1Et7IceOOATUrMQ7WXuegnntVWD0F6rtFziBxuwNB0LoR
# repo.hybris-mobian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.hybris-mobian.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDJZLUaeRRuUPXGgsl95wnXQbS/U60yy6/25flr9tyR0mMHjDaImAOGCoHxfLYzS9gs6uueJTm2RSvMRGNniVko=
# repo.hybris-mobian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.hybris-mobian.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC8mPJgrtCjshSoo0XOwbrbLrn08nOme7tdQ3rcvwNYD
EOF

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${TRAVIS_REPO_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${TRAVIS_BRANCH/feature\//}
	_branch=${_branch//./-}
	_branch=${_branch//_/-}
	_branch=${_branch//\//-}
	TARGET=$(echo ${_project}-${_branch} | tr '[:upper:]' '[:lower:]')
else
	# Staging
	TARGET="staging"
fi

echo "Chosen target is ${TARGET}"

echo "Uploading data"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.(u?deb|tar\..*|dsc|buildinfo)$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.hybris-mobian.org:./${TARGET}/

echo "Uploading .changes"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.changes$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.hybris-mobian.org:./${TARGET}/
