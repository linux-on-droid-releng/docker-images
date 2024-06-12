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
elif [ "${CIRCLECI}" == "true" ]; then
	# CircleCI

	BRANCH="${CIRCLE_BRANCH}"
	COMMIT="${CIRCLE_SHA1}"
	PROJECT_SLUG="${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}"
	if [ -n "${CIRCLE_TAG}" ]; then
		TAG="${CIRCLE_TAG}"
	fi
else
	# Sorry
	echo "This script runs only on Travis CI or Drone CI!"
	exit 1
fi

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
       -regex "/tmp/buildd-results/.*\.deb$" \
       -print0 \
       | xargs -0 -I {} curl -v -u "${NEXUS_USER}:${NEXUS_PASSWORD}" -H "Content-Type: multipart/form-data" --data-binary "@{}" "https://repo.lindroid.org/repository/lindroid/"

