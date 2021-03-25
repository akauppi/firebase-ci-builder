#
# Makefile
#
# Requires:
#	- gcloud
#	- docker
#

# Possible tags:
#	'lts-alpine' (14.16.0 as of 23-Mar-21)
#
NODE_IMAGE_TAG=lts-alpine

FIREBASE_VERSION=9.6.0

_IMAGE_NAME=firebase-custom-builder
_TAG=${FIREBASE_VERSION}-node14

_LOCAL_NAME=${_IMAGE_NAME}:${_TAG}

# Container Registry images are in one of:
#	asia.gcr.io
#	eu.gcr.io
#	us.gcr.io (same as plain gcr.io)
#
# Source: https://cloud.google.com/container-registry/docs/pushing-and-pulling
#
_GCR_IO=eu.gcr.io

_GCR_NAME_TAGGED=${_GCR_IO}/${PROJECT_ID}/${_IMAGE_NAME}:${_TAG}
	# PROJECT_ID defined by 'make push', as a recursive call.

#---
all:

build:
	docker build --build-arg FIREBASE_VERSION=${FIREBASE_VERSION} . -t ${_LOCAL_NAME}

# Force a rebuild each time. Makes it simpler/safer and Docker is rather fast if things are already cached.
#
# Note: We only push the _tagged_ name. If you want, you can push ':latest' manually.
#
push: build
	PROJECT_ID=$(shell gcloud config get-value project 2>/dev/null) ${MAKE} _realPush
_realPush:
	docker tag ${_LOCAL_NAME} ${_GCR_NAME_TAGGED}
	docker push ${_GCR_NAME_TAGGED}

.PHONY: all build push _realPush

#---
echo:
	@echo ${PROJECT_ID}

