#!/bin/bash
#
# Quick and dirty deployer
#

if [ "${HAS_JOSH_K_SEAL_OF_APPROVAL}" == "true" ]; then
	# Travis CI

	BRANCH="${TRAVIS_BRANCH}"
	COMMIT="${TRAVIS_COMMIT}"
	PROJECT_SLUG="${TRAVIS_REPO_SLUG}"
	if [ -n "${TRAVIS_TAG}" ]; then
		TAG="${TRAVIS_TAG}"
	fi
elif [ "${DRONE}" == "true" ]; then
	# Drone CI

	BRANCH="${DRONE_BRANCH}"
	COMMIT="${DRONE_COMMIT}"
	PROJECT_SLUG="${DRONE_REPO}"
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
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCm8IY+RFwQNIKlQDr2vRBg9zxOzGrSFiHHekwd3zdgW3k3UgW016ArFJgeS8pQ//WqJoxMnQLh42CoWqmrVSbwxyUBAPLagulIpB5vuYDSVMm8O1MWkS7+oZHD5nujQAy4zIxnN7cMSrseUzbt/vyV0dHW+WBxlPnODMDOze/vmhVUDxvsUFi+DzCn9HvSSuViLW3dEKE8po5UP2Ttalq94luru5ZxpfAeCfJ9m4dVw+VRB66c74qtKFR7UfAQVUnOLzIlUtKnG9wrZEYilCFuPFrZVFQ92sSWdPrMjWYaeC+RzwKAscgAjTQhjUeTlb+YaAO8l94zAtE5RjjOdH1t
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBv8R4sZtZlwV+SPHn6hQklcWAKxQu55ESjGxSmLTqqe2DSSF6zP8x0n6dd6RyA20t6Ia8s8A/gH4W7vcpKkpDs=
# repo.droidian.org:22 SSH-2.0-OpenSSH_7.9p1 Debian-10+deb10u2
repo.droidian.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPqtpEaUXN6HAi+FSbIWSywaPwTfgcXnDA4AKpNV+H+t
EOF

# Determine target.
echo "Determining target"
if [ -n "${TAG}" ]; then
	# Tag, should go to production
	TARGET="production"
elif [[ ${BRANCH} = feature/* ]]; then
	# Feature branch
	_project=${PROJECT_SLUG//\//-}
	_project=${_project//_/-}
	_branch=${BRANCH/feature\//}
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
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.droidian.org:./${TARGET}/

echo "Uploading .changes"
find /tmp/buildd-results/ \
	-maxdepth 1 \
	-regextype posix-egrep \
	-regex "/tmp/buildd-results/.*\.changes$" \
	-print0 \
	| xargs -0 -i rsync --perms --chmod=D770,F770 --progress {} ${INTAKE_SSH_USER}@repo.droidian.org:./${TARGET}/
