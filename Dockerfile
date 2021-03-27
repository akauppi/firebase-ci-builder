#
# Dockerfile for Firebase CI testing
#
# Provides:
#   - 'firebase CLI, with emulators pre-installed
#   - node.js and npm >=7.7.0
#   - bash, curl
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

RUN apk --no-cache add openjdk11-jre bash

RUN yarn global add firebase-tools@${FIREBASE_VERSION} \
  && yarn cache clean

# Include all products that have a 'firebase setup:emulators:...' step (except 'ui' since we don't need interactive UI).
#
# Realtime database   v4.7.2.jar
# Firestore           v1.11.12.jar
# Pub/Sub             0.1.0 (folder and .zip; which matters for caching?)
#
# NOTE: The caching goes to '/root/.cache', under the home of this image.
#   Cloud Build (as of 27-Mar-21) does NOT respect the image's home, but places one in '/builder/home', instead.
#   More importantly, it seems to overwrite existing '/builder/home' contents, leaving us little option other than
#   have the _consuming build script_ do 'RUN ln -s /root/.cache ~/' or similar, to move the cache where it must be.
#
#   We could work with the Cloud Build team(?) to make this less arduous.
#
# @Firebase:
#   - what is the best caching policy in a prefabricated image like this (we wish to not need to load and install
#     emulators *ever* in running the container; can that be restricted?); would rather fail a build and need to
#     update the builder image.
#   - [ ] can we remove either the 'pubsub' folder, or the zip file? Why are both cached (isn't that wasteful; 37.9MB
#         for the folder; 34.9MB for the .zip).
#   - ![ ]! How to place files so that Cloud Build would not override those (and they would "just work" for the application
#         build).
#
RUN firebase setup:emulators:database \
  && firebase setup:emulators:firestore \
  && firebase setup:emulators:pubsub
  #
  # $ ls .cache/firebase/emulators/
  #   firebase-database-emulator-v4.7.2.jar
  #   cloud-firestore-emulator-v1.11.12.jar
  #   pubsub-emulator-0.1.0
  #   pubsub-emulator-0.1.0.zip

# Auxiliary tools; The '-alpine' base image is based on 'busybox' and doesn't have these.
#
RUN apk --no-cache add \
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
