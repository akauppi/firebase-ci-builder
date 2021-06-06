# Developer notes

## What versions does image `X` contain?

```
$ docker image inspect node:lts-alpine
...
                "NODE_VERSION=14.16.0",
                "YARN_VERSION=1.22.5"
...
```

## Environment variables while Cloud Build runs the container

```
Step #1: HOSTNAME=5fb2....1a4e
Step #1: _FIREBASE_VERSION=9.6.1  <-- set by us
Step #1: YARN_VERSION=1.22.5
Step #1: PWD=/workspace
Step #1: HOME=/builder/home
Step #1: BUILDER_OUTPUT=/builder/outputs
Step #1: SHLVL=0
Step #1: PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Step #1: NODE_VERSION=14.16.0
Step #1: _=/usr/bin/env
```

## Dive 🤿

- [dive](https://github.com/wagoodman/dive) 

   "A tool for exploring each layer in a docker image"

The author found `dive` useful, at one stage. Has *completely* forgotten how to use it, though - luckily its `README` has the key map!

