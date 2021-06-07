#!/bin/bash
set -eu -o pipefail

#
# Push to Container Registry
#
# Usage:
#   <<
#     $ VERSION=9.12.1 ./push-to-gcr.io
#   <<
#
# Requires:
#	- docker
# - gcloud
#
GCP_PROJECT=$(gcloud config get-value project 2>/dev/null)
LOCAL_TAG=firebase-ci-builder:${VERSION}-node16-npm7
GCR_TAG=gcr.io/$GCP_PROJECT/firebase-ci-builder:${VERSION}-node16-npm7

docker tag $LOCAL_TAG $GCR_TAG
docker push $GCR_TAG
