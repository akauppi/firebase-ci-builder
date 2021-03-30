# firebase-custom-builder

Docker image for projects needing to run Firebase CLI, `npm` and Firebase emulation (which requires Java).

**Provides**

- `firebase-tools` & emulators (*)
  - OpenJDK 11
- node.js 14 (LTS)
- `npm` 7.7.x

(*) Emulator packages are pre-fetched (except `ui`).

The image is based on [BusyBox](https://en.wikipedia.org/wiki/BusyBox). 

We add some command line comfort:

||version|
|---|---|
|`bash`|v.5.0.11+|
|`curl`|7.67.0+|

Naturally, you may add more by deriving the Dockerfile or just forking it and editing to your liking.

**Other images**

There are [many images](https://hub.docker.com/search?q=firebase&type=image) for Firebase in Docker Hub but they seem to be made for personal use, and don't e.g. track tooling upgrades. They may also sport some project specific libraries which makes them unsuitable as a base image. The idea is to gather that momentum together so if you have your own, please consider using this instead for a stronger Firebase testing community.

- Community [Firebase image](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/firebase)

  Is left behind. 
  
  The info that there's emulation (that requires Java) has not reached it, yet. There is an [issue](https://github.com/GoogleCloudPlatform/cloud-builders-community/issues/441) raised but no PR. Pushing this code to the community repo would be the right thing to do but feels like too much friction for the author.

- [`timbru31/docker-java-node`](https://github.com/timbru31/docker-java-node)
 
  This repo is mentioned as a foundation having both Java and Node. However, the author faced problems building it (23-Mar-21). Being based on "Azul" OpenJDK image wasn't reaffirming for general use, either. 

  The repo takes a JDK/JRE base image and installs Node on top of it. This repo does the opposite: takes a Node base image and installs Java on top of that.


---

Publishing Docker images may be costly (you are charged by the downloads, and images are big), so the approach taken here is that you build the image on your own, and push it to a private repo that *your* projects use.

This certainly works for the author.


## Requirements

- Docker
- GNU `make`
- `gcloud` CLI

Recommended (optional):

- [dive](https://github.com/wagoodman/dive) - "A tool for exploring each layer in a docker image"

### Configure Docker

>Before you can push or pull images, you must configure Docker to use the gcloud command-line tool to authenticate requests to Container Registry.<sub>[source](https://cloud.google.com/container-registry/docs/quickstart)</sub>

```
$ gcloud auth configure-docker
```

## Build the image locally

You can do this simply to see that the build succeeds.

```
$ make build
...
Successfully built 29a6e8655e16
```

It should result in an image of ~557 <!--was:~706, ~679--> MB in size, containing:

- JDK
- `firebase` CLI
- `node`, `npm` and `yarn`
- Root as the user
- Home directory `/root`
- Emulator images in `.cache/firebase/emulators/`

You can check the size by:

```
$ docker image ls firebase-custom-builder:9.6.0-node14
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
firebase-custom-builder                                                     9.6.1-node14-npm7     b7e912f71ea3   2 days ago     557MB
```


## Push to...

### Container Registry (Google Cloud)

---

>NOTE: Do NOT think of uploading to a regional Container Registry, if you plan to use Cloud Build. Cloud Build runs in the US region and it would fetch your custom builder image separately for each *build*. Egress costs for inter-region transport of 500MB is about 0.10 eur (if the author calculated right).
>
>Instead, push the image once to the US Container Registry. Cloud Build gets it fast, does its job and can deploy to any region. Since your code is involved, not data, this should be outside of GDPR domain (no guarantees, author's opinion). 
>
>Counter note: If you set up a [worker pool](https://cloud.google.com/sdk/gcloud/reference/alpha/builds/worker-pools/create), you can run Cloud Build within the region. You probably know the drills if you're doing such.
>
>You can follow the discussion here: [FR: Select build region](https://issuetracker.google.com/issues/63480105) (Google IssueTracker)

---

Check that there is a suitable GCP project:

```
$ gcloud config get-value project 2>/dev/null
some-230321
```

Push the built image to Container Registry:

<!-- NOT true - see above
This should ideally be close to where your builds happen. See GCR > [Pushing and pulling](https://cloud.google.com/container-registry/docs/pushing-and-pulling).

Prefix the command then with `_GCR_IO=[asia|eu|us].gcr.io`, according to your needs.
-->

```
$ make push
docker build --build-arg FIREBASE_VERSION=9.6.0 . -t firebase-custom-builder:9.6.0-node14
...
Successfully built 6e84ee9f7a74
Successfully tagged firebase-custom-builder:9.6.0-node14
docker tag firebase-custom-builder:9.6.0-node14 gcr.io/groundlevel-160221/firebase-custom-builder:9.6.0-node14
docker push gcr.io/groundlevel-160221/firebase-custom-builder:9.6.0-node14
The push refers to repository [gcr.io/groundlevel-160221/firebase-custom-builder]
7d5805f5a13c: Pushed 
493987b335c5: Pushed 
09bb4df3245b: Pushed 
a9f0fd5d0c5e: Pushed 
aedafbecb0b3: Layer already exists 
db809908a198: Layer already exists 
1b235e8e7bda: Layer already exists 
3e207b409db3: Layer already exists 
9.6.0-node14: digest: sha256:97f17c562507799c6b52786147d70aa56c848ee2d67eff590aa567d7a9b1c019 size: 2003
```

### Pushing `latest`

The above instructions (and the `Makefile`) only push a *tagged* image. 

If you want, you can also push one with tag `latest`. This allows your users to get a default version.

```
$ make push-latest
...
PUSH_TAG=latest /Library/Developer/CommandLineTools/usr/bin/make _realPush
docker tag firebase-custom-builder:9.6.1-node14-npm7 gcr.io/groundlevel-160221/firebase-custom-builder:latest
docker push gcr.io/groundlevel-160221/firebase-custom-builder:latest
The push refers to repository [gcr.io/groundlevel-160221/firebase-custom-builder]
0395faaea2c5: Pushed 
fb5c236daec5: Pushed 
f5ec0d381d42: Pushed 
5e2059ad91ce: Pushed 
a845e457894d: Pushed 
d733bd4967fd: Layer already exists 
d6c10d5ad47a: Layer already exists 
50643cb11b15: Layer already exists 
b3e46aac4e11: Layer already exists 
latest: digest: sha256:deb3ec11c0ef7763b21b3546f14d76f08db95de7313b3337875c55e0e4645028 size: 2216
```

### Container Registry Pricing

See -> [Container Registry pricing](https://cloud.google.com/container-registry/pricing)

The price for Standard buckets in a multi-region is about $0.026 per GB per month.
i.e. for keeping a single 557MB image, it's ~0,01 € / month.

It is good to occasionally remove unneeded files from the Container Registry. The author would simply delete the whole contents of the bucket and re-push the images required.


## Using the image

You can now use the image eg. in Cloud Build as:

```
gcr.io/$PROJECT_ID/firebase-custom-builder:9.6.0-node14
```

If you pushed the `latest` tag, you can leave out the tag at the end:

```
gcr.io/$PROJECT_ID/firebase-custom-builder
```

>Note: You can leave `$PROJECT_ID` in the `cloudbuild.yaml`. Cloud Build knows to replace it with the current GCP project.

---

>**❗️IMPORTANT NOTE:**
>
>Emulator images are left in the `/root/.cache` folder. In order for you to benefit from them (so that running emulators won't refetch the packages, for each build), you must do this step before running the emulators.
>
>```
>- name: gcr.io/$PROJECT_ID/firebase-custom-builder
  entrypoint: bash
  args: ['-c', 'mv /root/.cache ~/.cache']
>```
>Cloud Build replaces the home directory with `/builder/home` and *does not keep* existing contents in such a folder. This is not good manners; we'd rather it would respect the image's premade home.

---


## References

- `nodejs/docker-node` > [Node.js > How to use this image](https://github.com/nodejs/docker-node/blob/master/README.md#how-to-use-this-image) (node docs)
- Cloud Build > ... > [Creating a custom builder](https://cloud.google.com/build/docs/configuring-builds/use-community-and-custom-builders#creating_a_custom_builder) (Cloud Build docs)

