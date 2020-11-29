#!/bin/bash
#
# Quick and dirty signer
#

set -e

echo "${GPG_STAGINGPRODUCTION_SIGNING_KEY}" | gpg --import
exec debsign -kC14B92A04D37C9FF *.changes
