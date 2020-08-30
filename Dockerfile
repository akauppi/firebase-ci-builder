#
# Dockerfile for Firebase CI testing
#
# Provides:
#   - 'firebase' CLI tools
#   - emulators
#   - node.js and npm
#
# References:
#   - Best practices for writing Dockerfiles
#       -> https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
# Want node 14. Once it's gotten to LTS, can change to:
#FROM node:lts-alpine
FROM node:14-alpine

# Version of 'firebase-tools' is also our version
ENV FIREBASE_VERSION 8.8.1

ENV HOME /project
ENV USER user

RUN apk --no-cache add openjdk11-jre bash && \
  yarn global add firebase-tools@${FIREBASE_VERSION} && \
  yarn cache clean

RUN firebase setup:emulators:database && \
  firebase setup:emulators:firestore && \
  firebase setup:emulators:pubsub

# ls .cache/firebase/emulators/
#cloud-firestore-emulator-v1.11.7.jar   firebase-database-emulator-v4.5.0.jar  pubsub-emulator-0.1.0                  pubsub-emulator-0.1.0.zip
#
# = note that Firestore, Firebase emulators don't uncompress but PubSub does (and is distributed as a zip).
#   To see whether we can reduce the image size, one could uncompress those and remove the '.jar' files. #later????

RUN firebase --version && \
  java -version && \
  node --version

# Be eventually a user rather than root
#
RUN addgroup -S mygroup && adduser -S ${USER} -G mygroup && \
  mkdir -p ${HOME} && \
  chown -R ${USER} ${HOME}

WORKDIR ${HOME}

# Now changing to user (no more root)
USER ${USER}
    # $ whoami
    # user
    # $ pwd
    # /project

#ENTRYPOINT ["npm"]



#---
#STASH: # lulichn/firebase-tools had this:
#
#RUN apk add --no-cache --virtual .gyp python make g++ \
#	&& apk del .gyp
