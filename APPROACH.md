# Approach

## Node base image, JRE on top of it

There are two ways people go:

- Java base image, install Node.js
- Node base image, install JRE

We chose the latter, because there were good (Alpine) Node base images available, and installing `openjdk11-jre` is a one-liner.

It works, and the resulting image is within reasonable bounds.

