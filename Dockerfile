#
# Dockerfile for Firebase CI testing
#
# Provides:
#   - 'firebase' CLI tools
#   - emulators
#   - node.js and npm
#   - bash
#   - sed, curl
#
# Note:
#   Cloud Build requires that the builder image has 'root' rights; not a dedicated user.
#   Otherwise, one gets all kinds of access right errors with '/builders/home/.npm' and related files.
#
#   This is fine. There is no damage or risk, leaving the builder image with root, so the user/home related lines have
#   been permanently disabled by '#|' prefix.
#
# References:
#   - Best practices for writing Dockerfiles
#       -> https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#

# Node images
#   -> https://hub.docker.com/_/node
#
# As of Mar'21:
#   "current-alpine": 15.12.0
#   "lts-alpine": 14.16.0 (npm 6.14.11)
#
# Note: IF YOU CHANGE THIS, change the '-nodeXX' suffix within 'Makefile'.
#
FROM node:lts-alpine

# Version of 'firebase-tools' is also our version
#
# tbd. Is there a benefit placing it also in 'env'? eg. seeing the build parameters of an image, later?
#
ARG FIREBASE_VERSION
ENV _FIREBASE_VERSION ${FIREBASE_VERSION}

#|# It should not matter where the home is, but based on an error received with Cloud Build (beta 2021.03.19),
#|# the commands it excercises seem to expect to be able to 'mkdir' a folder within '/builder/home'.
#|#
#|ENV HOME /builder/home
#|ENV USER user
#|ENV GROUP mygroup

# Add 'npm' 7. It's needed by the first customer of this image and seems stable. (you don't want it - remove the lines?)
#
RUN npm install -g npm

RUN apk --no-cache add openjdk11-jre bash && \
  yarn global add firebase-tools@${FIREBASE_VERSION} && \
  yarn cache clean

RUN firebase setup:emulators:database && \
  firebase setup:emulators:firestore && \
  firebase setup:emulators:pubsub

# ls -1 .cache/firebase/emulators/
#   cloud-firestore-emulator-v1.11.12.jar
#   firebase-database-emulator-v4.7.2.jar
#   pubsub-emulator-0.1.0
#   pubsub-emulator-0.1.0.zip
#
# = note that Firestore, Firebase emulators don't uncompress but PubSub does (and is distributed as a zip).
#   To see whether we can reduce the image size, one could uncompress those and remove the '.jar' files. #later????

# Auxiliary tools; The '-alpine' base image is based on 'busybox' and doesn't have these.
#
RUN apk --no-cache add \
  sed \
  curl

#|# Be eventually a user rather than root
#|#
#|RUN addgroup -S ${GROUP} && adduser -S ${USER} -G mygroup && \
#|  mkdir -p ${HOME} && \
#|  chown -R ${USER}:${GROUP} ${HOME}

#|WORKDIR ${HOME}

#|# Now changing to user (no more root)
#|USER ${USER}
#|   # $ whoami
#|   # user

#|# Create '${HOME}/.npm' (as a user); trying to avoid access errors with Cloud Build.
#|#
#|RUN mkdir ${HOME}/.npm

# Don't define an 'ENTRYPOINT' since we provide multiple ('firebase', 'npm'). Cloud Build scripts can choose one.

#---
#STASH: # lulichn/firebase-tools had this:
#
#RUN apk add --no-cache --virtual .gyp python make g++ \
#	&& apk del .gyp
