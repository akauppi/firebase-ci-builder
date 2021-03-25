#
# Makefile
#
# Requires:
#	- gcloud
#	- docker
#
FIREBASE_VERSION=9.6.0

_IMAGE_NAME=firebase-custom-builder

# Note: '-node14' is NOT connected with what the base image in 'Dockerfile' provides. MAINTAIN MANUALLY!!!
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

# Lazy evaluation trick
#FOO = $(eval FOO := expensive-to-evaluate)$(FOO)
# from -> https://blog.jgc.org/2016/07/lazy-gnu-make-variables.html
#
_PROJECT_ID=$(eval _PROJECT_ID := $(shell gcloud config get-value project 2>/dev/null))$(_PROJECT_ID)

# Overrides
PUSH_TAG?=${_TAG}

_GCR_NAME_TAGGED=${_GCR_IO}/${_PROJECT_ID}/${_IMAGE_NAME}:${PUSH_TAG}

#---
all:

# Note: '--pull' for not getting stale base images
build:
	docker build --pull --build-arg FIREBASE_VERSION=${FIREBASE_VERSION} . -t ${_LOCAL_NAME}

# Force a rebuild each time. Makes it simpler/safer and Docker is rather fast if things are already cached.
#
# Note: We only push the _tagged_ name. If you want, you can push ':latest' manually.
#
push: build
	${MAKE} _realPush
_realPush:
	docker tag ${_LOCAL_NAME} ${_GCR_NAME_TAGGED}
	docker push ${_GCR_NAME_TAGGED}

push-latest: build
	PUSH_TAG=latest ${MAKE} _realPush

.PHONY: all build push _realPush

#---
echo:
	@echo ${PROJECT_ID}
