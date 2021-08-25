#
# Dockerfile for Firebase CI testing
#
# Provides:
#   - 'firebase' CLI, with some emulators pre-installed
#   - node.js and npm >=7.7.0
#   - bash, curl
#   - a user 'user' created (can be activated manually)
#
# Note:
#   Cloud Build requires that the builder image has 'root' rights; not a dedicated user.
#   Otherwise, one gets all kinds of access right errors with '/builders/home/.npm' and related files.
#
#   This is fine. There is no damage or risk, leaving the builder image with root. Some lines are left permanently
#   disabled, marked as '#|'.
#
# Manual user land:
#   It's sometimes good to debug things as a user, a 'user' is added. Jump there with 'passwd user' and 'login user'.
#
#     ^-- tbd. We'd rather have no pw; why doesn't 'adduser --disabled-password' do that?  #help
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
# As of Jul'21:
#   "current-alpine": 16.5.0
#   "16-alpine": 16.5.0 (npm 7.19.1)
#
# As of May'21:
#   "current-alpine": 16.2.0
#   "16-alpine": 16.2.0 (npm 7.13.0)
#
# As of Mar'21:
#   "current-alpine": 15.12.0
#   "lts-alpine": 14.16.0 (npm 6.14.11)

# Note: IF YOU CHANGE THIS, change the '-nodeXX' suffix within 'build' script.
FROM node:16-alpine

# Version of 'firebase-tools' is also our version
#
ARG FIREBASE_VERSION

#|# It should not matter where the home is, but based on an error received with Cloud Build (beta 2021.03.19),
#|# the commands it excercises seem to expect to be able to 'mkdir' a folder within '/builder/home'.
#|#
#|ENV HOME /builder/home
ENV USER user

# Updating 'npm' was needed with Node 14. KEEP
#RUN npm install -g npm

# Suppress npm update announcements
RUN npm config set update-notifier false

RUN apk --no-cache add openjdk11-jre-headless

# Auxiliary tools; The '-alpine' base image is based on 'busybox' and doesn't have these.
#
RUN apk --no-cache add bash curl

RUN yarn global add firebase-tools@${FIREBASE_VERSION} \
  && yarn cache clean

# Alternative:
#
# Note: With this approach (from Firebase docs), we are not in charge of the version (which we.. like to be :).
#
#RUN curl -sL https://firebase.tools | bash

# Products that have 'setup:emulators:...' (only some of these are cached into the image, but you can tune the set):
#
#   - Realtime database
#   - Firestore
#   - Storage
#   - Pub/Sub
#   - Emulator UI   (not needed in CI; include this for Docker-based development)
#
# NOTE: Even if you don't cache the simulator, you can use the image for those products. They'll just download a
#   necessary binary, on each run.
#
# NOTE: The caching goes to '/root/.cache/firebase/emulators', under the home of this image.
#   Cloud Build (as of 27-Mar-21) does NOT respect the image's home, but places one in '/builder/home', instead.
#   More importantly, it seems to overwrite existing '/builder/home' contents, not allowing us to prepopulate.
#
# Note: Adding as separate layers, with least changing first.
#
RUN firebase setup:emulators:database
RUN firebase setup:emulators:firestore
#RUN firebase setup:emulators:storage
#RUN firebase setup:emulators:pubsub \
#  && rm /root/.cache/firebase/emulators/pubsub-emulator*.zip

# Bring in also the emulator UI, though it's not needed in CI. Helps in using the same image also in dev.
#
RUN firebase setup:emulators:ui \
  && rm -rf /root/.cache/firebase/emulators/ui-v*.zip

  # $ ls .cache/firebase/emulators/
  #   cloud-firestore-emulator-v1.13.1.jar    (57.7 MB)
  #   cloud-storage-rules-runtime-v1.0.1.jar  (31.2 MB)   ; NOT PRE-FETCHED (people can use it; will get downloaded if they do)
  #   firebase-database-emulator-v4.7.2.jar   (27.6 MB)
  #   pubsub-emulator-0.1.0                   (37.9 MB)   ; NOT PRE-FETCHED (-''-)
  #   ui-v1.6.0                               (13.8 MB)

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

# Allow manual user invocation.
#
#ENV USER_HOME /home/${USER}

RUN adduser --disabled-password ${USER}

  # Note: npm needs the user to have a home directory ('/home/user')
  #mkdir -p ${USER_HOME} && \
  #chown -R ${USER} ${USER_HOME}

#|WORKDIR ${HOME}

#|# Now changing to user (no more root)
#|USER ${USER}
#|   # $ whoami
#|   # user

# Don't define an 'ENTRYPOINT' since we provide multiple ('firebase', 'npm'). Cloud Build scripts can choose one.
