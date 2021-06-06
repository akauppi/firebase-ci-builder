#
# Dockerfile for Firebase CI testing
#
# Provides:
#   - 'firebase' CLI, with emulators pre-installed
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
# Note:
#   Use of 'FIREBASE_EMULATORS_PATH' env.var. seems legit, but it's not mentioned in 'firebase-tools' documentation.
#
# References:
#   - Best practices for writing Dockerfiles
#       -> https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#

# Node images
#   -> https://hub.docker.com/_/node
#
# As of May'21:
#   "current-alpine": 16.2.0
#   "16-alpine": 16.2.0 (npm 7.13.0)
#
# As of Mar'21:
#   "current-alpine": 15.12.0
#   "lts-alpine": 14.16.0 (npm 6.14.11)
#
# Note: IF YOU CHANGE THIS, change the '-nodeXX' suffix within 'Makefile'.
#
FROM node:16-alpine

# Version of 'firebase-tools' is also our version
#
# #later: Is there a benefit placing it also in 'env'? eg. seeing the build parameters of an image?
ARG FIREBASE_VERSION
#ENV FIREBASE_VERSION ${FIREBASE_VERSION}

#|# It should not matter where the home is, but based on an error received with Cloud Build (beta 2021.03.19),
#|# the commands it excercises seem to expect to be able to 'mkdir' a folder within '/builder/home'.
#|#
#|ENV HOME /builder/home
#|ENV USER user
#|ENV GROUP mygroup

# Add 'npm' 7 (was needed with node 14). KEEP?
#RUN npm install -g npm

RUN apk --no-cache add openjdk11-jre bash

RUN yarn global add firebase-tools@${FIREBASE_VERSION} \
  && yarn cache clean

# Products that have 'setup:emulators:...' (only some of these are cached into the image, but you can tune the set):
#
#   - Realtime database
#   - Firestore
#   - Storage
#   - Pub/Sub
#   - Emulator UI   (not needed in CI; include this for Docker-based development)
#
# NOTE: The caching goes to '/root/.cache', under the home of this image.
#   Cloud Build (as of 27-Mar-21) does NOT respect the image's home, but places one in '/builder/home', instead.
#   More importantly, it seems to overwrite existing '/builder/home' contents, not allowing us to prepopulate.
#
# @Firebase:
#   - what is the best caching policy in a pre-fabricated image like this (we wish to not need to load and install
#     emulators *ever* in running the container; can that be restricted?); would rather fail a build and need to
#     update the builder image.
#   - [x] can we remove either the 'pubsub' folder, or the zip file? Why are both cached (isn't that wasteful; 37.9MB
#         for the folder; 34.9MB for the .zip). [Removing the .zip]
#   - ![x]! How to place files so that Cloud Build would not override those (and they would "just work" for the application
#         build). [Using the 'FIREBASE_EMULATORS_PATH' env.var.]
#
# Note: Adding as separate layers, with the least changing mentioned first.
#
RUN firebase setup:emulators:database
RUN firebase setup:emulators:firestore
#RUN firebase setup:emulators:storage
#RUN firebase setup:emulators:pubsub \
#  && rm /root/.cache/firebase/emulators/pubsub-emulator*.zip

# Note: We also bring in the emulator UI, though it's not needed in CI. This helps in using the same image also in dev.
#
RUN firebase setup:emulators:ui \
  && rm -rf /root/.cache/firebase/emulators/ui-v*.zip

  # $ ls .cache/firebase/emulators/
  #   firebase-database-emulator-v4.7.2.jar   (27,6 MB)
  #   cloud-firestore-emulator-v1.11.15.jar   (57,4 MB)
  #   cloud-storage-rules-runtime-v1.0.0.jar  (31,7 MB)   ; NOT INCLUDED (people can use it; will get downloaded if they do)
  #   pubsub-emulator-0.1.0                   (37,9 MB)   ; NOT INCLUDED (-''-)
  #   pubsub-emulator-0.1.0.zip               (34,9 MB)   ; removed
  #   ui-v1.5.0                               (24 MB)
  #   ui-v1.5.0.zip                           (6 MB)      ; removed

# Setting the env.var so 'firebase-tools' finds the images.
#
# Without this, the using CI script would first need to do a 'mv /root/.cache ~/' command. It's weird; the other approaches
# considered were:
#   - use our user and home                   (Cloud Build doesn't resepect them)
#   - place the files under '/builder/home'   (Cloud Build wipes that folder, before announcing it the new home)
#   - have an 'ONBUILD' step handle the move  (Cloud Build doesn't call the triggers)
#
# Note: 'FIREBASE_EMULATORS_PATH' looks legit (from the sources), but is not mentioned in Firebase documentation (May 2021)
#   so it might seize to work, one day... #good-enough
#
ENV FIREBASE_EMULATORS_PATH '/root/.cache/firebase/emulators'

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
