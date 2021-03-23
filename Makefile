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
_GCR_NAME=gcr.io/${PROJECT_ID}/${_IMAGE_NAME}:${_TAG}

#PROJECT_ID=

all:

build:
	docker build --build-arg FIREBASE_VERSION=${FIREBASE_VERSION} . -t ${_LOCAL_NAME}

# Force a rebuild each time. Makes it simpler/safer and Docker is rather fast if things are already cached.
#
push: build _evalProject
	docker tag ${_LOCAL_NAME} ${_GCR_NAME}
	docker push ${_GCR_NAME}

_evalProject:
	$(eval PROJECT_ID:=$(shell gcloud config get-value project 2>/dev/null))

.PHONY: _evalProject

#---
echo:
	@echo ${PROJECT_ID}
