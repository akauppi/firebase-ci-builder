# firebase-ci-builder

Docker image for projects needing to run Firebase CLI, `npm` and Firebase emulation (which requires Java).

**Provides**

- `firebase-tools` & emulators (*)
- OpenJDK 11
- node.js 16
- `npm` 7.13.x

   <small>(*) pre-fetched, except `ui`</small>

The image is based on [BusyBox](https://en.wikipedia.org/wiki/BusyBox). 

We add some command line comfort:

||version|
|---|---|
|`bash`|v.5.1.0+|
|`curl`|7.76.1+|

Naturally, you may add more by deriving the Dockerfile or just forking it and editing to your liking.

**Other images**

- Community [Firebase image](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/firebase)

  Is left behind. 
  
  The info that there's emulation (that requires Java) has not reached it, yet. There is an [issue](https://github.com/GoogleCloudPlatform/cloud-builders-community/issues/441) raised but no PR. Pushing this code to the community repo would be the right thing to do but feels like too much friction for the author.

- [`timbru31/docker-java-node`](https://github.com/timbru31/docker-java-node)
 
  This repo is mentioned as a foundation having both Java and Node. However, the author faced problems building it (23-Mar-21). Being based on "Azul" OpenJDK image wasn't reaffirming for general use, either. 

  The repo takes a JDK/JRE base image and installs Node on top of it.

**Approach**

Publishing Docker images may be costly (you are charged by the downloads, and images are big), so the approach taken here is that you build the image on your own, and push it to a private repo that *your* projects use.

This certainly works for the author.

## Requirements

- Docker
- GNU `make`
- `gcloud` CLI

---

- <details><summary>*Installing `gcloud` on macOS...*</summary>
   
   1. Download the package from [official installation page](https://cloud.google.com/sdk/docs/install)
   2. Extract in the downloads folder, but then..
   3. Move `google-cloud-sdk` to a location where you'd like it to remain (e.g. `~/bin`).
   
      When you run the install script, the software is installed *in place*. You cannot move it around any more.
      
   4. From here, you can follow the official instructions:

      `./google-cloud-sdk/install.sh`

      `./google-cloud-sdk/bin/gcloud init`
   </details>

   To update: `gcloud components update`

---

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

It should result in an image of ~533 <!--was:~557, ~706, ~679--> MB in size, containing:

- JDK
- `firebase` CLI
- `node`, `npm` <font color=lightgray><sub><sub><sup>and `yarn`</sup></sub></sub></font>
- Root as the user
- Home directory `/root`
- Emulator images in `.cache/firebase/emulators/`

You can check the size by:

```
$ docker image ls firebase-ci-builder:9.6.1-node16
REPOSITORY            TAG                  IMAGE ID       CREATED         SIZE
firebase-ci-builder   9.11.0-node16-npm7   90e213f2a93d   6 minutes ago   533MB
```


## Push to the cloud

---

>NOTE: Do NOT think of uploading to a regional Container Registry, if you plan to use Cloud Build. Cloud Build runs in the US region and it would fetch your custom builder image separately for each *build*. Egress costs for inter-region transport of 500MB is about 0.10 eur.
>
>Instead, push the image once to the US Container Registry. Cloud Build gets it fast, does its job and can deploy to any region. Since your code is involved, not data, this should be outside of GDPR domain (no guarantees, author's opinion). 
>
>Counter note: If you set up a [worker pool](https://cloud.google.com/sdk/gcloud/reference/alpha/builds/worker-pools/create), you can run Cloud Build within the region. You probably know the drill if you're doing such.
>
>You can follow the discussion here: [FR: Select build region](https://issuetracker.google.com/issues/63480105) (Google IssueTracker)

---

Check that there is a suitable GCP project:

```
$ gcloud config get-value project 2>/dev/null
some-230321
```

Push the built image to Container Registry:

>This pushes to `gcr.io`. If you know you want another registry, see the `Makefile`.

```
$ make push
docker build --pull --build-arg FIREBASE_VERSION=9.11.0 . -t firebase-ci-builder:9.11.0-node16-npm7
[+] Building 0.8s (9/9) FINISHED                                                                                                                                                                                                                          
...

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
/Library/Developer/CommandLineTools/usr/bin/make _realPush
docker tag firebase-ci-builder:9.11.0-node16-npm7 gcr.io/groundlevel-160221/firebase-ci-builder:9.11.0-node16-npm7
docker push gcr.io/groundlevel-160221/firebase-ci-builder:9.11.0-node16-npm7
The push refers to repository [gcr.io/groundlevel-160221/firebase-ci-builder]
efd4b6737905: Pushed 
b82e4a3f1bb0: Pushed 
43fcfe48be7e: Pushed 
59b893fe3d1a: Pushed 
10240d23865e: Layer already exists 
51b98edbb053: Layer already exists 
01853fbda02d: Layer already exists 
b2d5eeeaba3a: Layer already exists 
9.11.0-node16-npm7: digest: sha256:e59a64f5a7809024530a11482cdf25bb70d8d8db0cb8647be8f8cb62e343d4d7 size: 2005
```

### Pushing `latest` (optional)

The above instructions (and the `Makefile`) only push a *tagged* image. 

If you want, you can also push one with tag `latest`. This allows your users to get a default version, but the author thinks this is not needed / recommended practise.

>Why? The use is in CI/CD pipelines, and there it's best to explicitly state the versions of the tools needed, i.e. use a tagged image.

```
$ make push-latest
...
PUSH_TAG=latest /Library/Developer/CommandLineTools/usr/bin/make _realPush
docker tag firebase-custom-builder:9.6.1-node14-npm7 gcr.io/groundlevel-160221/firebase-custom-builder:latest
docker push gcr.io/groundlevel-160221/firebase-custom-builder:latest
...
```

>Note: We might remove the `push-latest` target since the use case for `latest` is shaky.


### [Container Registry Pricing](https://cloud.google.com/container-registry/pricing)

The price for Standard buckets in a multi-region is about $0.026 per GB per month.
i.e. for keeping a single 557MB image, it's ~0,01 € / month.

It is good to occasionally remove unneeded files from the Container Registry. The author would simply delete the whole contents of the bucket and re-push the images required.


## Using the image

You can now use the image eg. in Cloud Build as:

```
gcr.io/$PROJECT_ID/firebase-ci-builder:9.11.0-node16-npm7
```

>If you pushed the `latest` tag, you can leave out the tag at the end.

<p></p>

>Note: You can leave `$PROJECT_ID` in the `cloudbuild.yaml`. Cloud Build knows to replace it with the current GCP project.

---
>###❗️IMPORTANT NOTE:
>
>Emulator images are left in the `/root/.cache` folder. In order for you to benefit from them (so that running emulators won't refetch the packages, for each build), you must do this step before running the emulators.
>
>```
>- name: gcr.io/$PROJECT_ID/firebase-custom-builder:{$_TAG}
  entrypoint: bash
  args: ['-c', 'mv /root/.cache ~/.cache']
>```
>Cloud Build replaces the home directory with `/builder/home` and *does not keep* existing contents in such a folder. This is not good manners; we'd rather it would respect the image's premade home.
>
>Also, `ONBUILD` commands don't seem to be run by Cloud Build, leaving this our only way further...

---

## References

- `nodejs/docker-node` > [Node.js > How to use this image](https://github.com/nodejs/docker-node/blob/master/README.md#how-to-use-this-image) (node docs)
- Cloud Build > ... > [Creating a custom builder](https://cloud.google.com/build/docs/configuring-builds/use-community-and-custom-builders#creating_a_custom_builder) (Cloud Build docs)

