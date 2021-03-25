# Developer notes

## What versions does image `X` contain?

```
$ docker image inspect node:lts-alpine
...
                "NODE_VERSION=14.16.0",
                "YARN_VERSION=1.22.5"
...
```

