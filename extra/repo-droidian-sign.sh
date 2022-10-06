#!/bin/bash
#
# Quick and dirty signer
#

set -e

echo "${GPG_STAGINGPRODUCTION_SIGNING_KEY}" | gpg --import
exec debsign -k9EE10B5D42CBD658C43BB6FA2447CDDE0C1F1CD1 *.changes
