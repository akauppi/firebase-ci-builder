# firebase-ci-builder

Docker image for projects needing to run Firebase CLI or Firebase emulation (which requires Java).

Contains instructions on building locally, and pushing to Google Cloud Registry that you control.

**Provides**

- `firebase-tools` & emulators, some prefetched
- OpenJDK JRE 11
- node.js 18
- `npm`

In addition to [BusyBox](https://en.wikipedia.org/wiki/BusyBox), the image has some command line comfort:

||version|
|---|---|
|`bash`|v.5.1.16+|
|`curl`|7.80.0+|

Naturally, you may add more by deriving the Dockerfile or just forking it and editing to your liking.

**Publishing / customization approach**

Publishing Docker images may be costly (you are charged by the downloads, and images are big), so the approach taken here is that you build the image on your own (maybe tuning it, eg. changing the set of pre-fetched emulators), and push it to a private registry that *your* projects use.

## Requirements

- Docker
- `gcloud` CLI (optional; for pushing to Cloud Registry)

   --- 
   
   <details><summary>*Installing `gcloud` on macOS...*</summary>
      
   1. Download the package from [official installation page](https://cloud.google.com/sdk/docs/install)
   2. Extract in the downloads folder, but then..
   3. Move `google-cloud-sdk` to a location where you'd like it to remain (e.g. `~/bin`).
   
      When you run the install script, the software is installed *in place*. You cannot move it around any more.
      
   4. From here, you can follow the official instructions:
   
      `./google-cloud-sdk/install.sh`
   
      `./google-cloud-sdk/bin/gcloud init`
   
   To update: `gcloud components update`
   </details>

   <details><summary>*Installing `gcloud` on Windows 10 + WSL2...*</summary>

   ```
   $ apt-get install google-cloud-sdk
   ```
   
   >Note: This version may lack a bit behind, and doesn't have support for `gcloud components`, but should be enough.
   
   To update: `sudo apt-get upgrade google-cloud-sdk`
	</details>      

   ---

The repo gives guidance on pushing to Google Cloud Registry. You can obviously use any Docker registry, just as well.

### Configure Docker for Container Registry

Configure Docker to use the `gcloud` command-line tool to authenticate requests to Container Registry.<sub>[source](https://cloud.google.com/container-registry/docs/quickstart)</sub>

```
$ gcloud auth configure-docker
```

## Build the image

You can do this simply to see that the build succeeds.

```
$ ./build
[+] Building 66.3s (11/11) FINISHED                        
...
 => => naming to docker.io/library/firebase-ci-builder:10.6.0-node16-npm8
```

It should result in an image of ~490 <!-- was: ~448, ~443, ~461, ~473, ~482, ~496, ~533, ~557, ~706, ~679--> MB in size, containing:

- JDK
- `firebase` CLI
- `node`, `npm` <font color=lightgray><sub><sub><sup>and `yarn`</sup></sub></sub></font>
- Root as the user
- Home directory `/root`
- Emulator images in `.cache/firebase/emulators/`

You can check the size by:

```
$ docker image ls firebase-ci-builder
REPOSITORY            TAG                  IMAGE ID       CREATED          SIZE
firebase-ci-builder   11.0.1-node18-npm8   8f394d6a604f   17 seconds ago   490MB
```

*The image size depends on which emulators are cached into the image. You can tune that pretty easily by commenting/uncommenting blocks in `Dockerfile`, to match your needs.*

*Pumping to Node.js 18 caused a +42MB increase (over Node.js 16), but we want to keep to the latest stable tools.*


## Push to the Container Registry

---

>NOTE: Do NOT think of uploading to a regional Container Registry, if you plan to use Cloud Build. Cloud Build runs in the US region and it would fetch your custom builder image separately for each *build*. Egress costs for inter-region transport of 500MB is about 0.10 eur.
>
>Instead, push the image once to the US Container Registry. Cloud Build gets it fast, does its job and can deploy to any region. Since your code is involved, not data, this should be outside of GDPR domain (no guarantees, author's opinion). 
>
>If you set up a [worker pool](https://cloud.google.com/sdk/gcloud/reference/alpha/builds/worker-pools/create), you can run Cloud Build within the region. You probably know the drill if you're doing such.
>
>You can follow the discussion here: [FR: Select build region](https://issuetracker.google.com/issues/63480105) (Google IssueTracker)

---

Check that there is a suitable GCP project:

```
$ gcloud config get-value project 2>/dev/null
some-230321
```

>The author recommends dedicating a certain GCP project just for the build images and non-deployment Cloud Build tasks.

Push the built image to Container Registry:

```
$ ./push-to-gcr
```

### Maybe... you don't want to push a `latest` tag

If you want, you can also push with the tag `latest`. This allows your users to get a default version, but the author thinks this is not needed.

>Why? The use is in CI/CD pipelines, and there it's best to explicitly state the versions of the tools needed.


### [Container Registry Pricing](https://cloud.google.com/container-registry/pricing)

The price for Standard buckets in a multi-region is about \$0.026 per GB per month.
i.e. for keeping a single 500MB image, it's ~0,01 € / month.

It is good to occasionally remove unneeded files from the Container Registry. The author would simply delete the whole contents of the bucket and re-push the images required.

>Note: Firebase GitHub Issues somewhere states that images should be removed in the Container Registry, not the Cloud Storage bucket.


## Using the image

You can now use the image eg. in Cloud Build as:

```
gcr.io/$PROJECT_ID/firebase-ci-builder:10.6.0-node16-npm8
```

>Note: If you are using the image within the same project, you can leave `$PROJECT_ID` in the `cloudbuild.yaml`. Cloud Build knows to replace it with the current GCP project.

### Using from another GCP project

To use the same image from other Google Cloud projects, e.g. for deployment CI/CD runs: 

1. Get a service account name for the project needing the images
   e.g. `PROJECT-NUMBER@cloudbuild.gserviceaccount.com`
   <sub>[source](https://cloud.google.com/container-registry/docs/access-control#gcp-permissions)</sub>
   
2. Follow [Configuring access control](https://cloud.google.com/container-registry/docs/access-control#granting_users_and_other_projects_access_to_a_registry) (Container Registry docs)

	"Storage Object Viewer" looks right

>**References**
>
>- [Using Images from Other Projects](https://cloud.google.com/deployment-manager/docs/configuration/using-images-from-other-projects-for-vm-instances)
>- [Setting up a shared Container Registry](https://cloud.google.com/ai-hub/docs/registry-setup)

<!-- tbd. If the instructions themselves are enough, disable the 'references'
-->


## Notes on Cloud Build 

Emulator images are left in the `/root/.cache` folder, and the emulators find them via an environment variable. This is needed, because Cloud Build replaces the home directory with `/builder/home` and *does not keep* existing contents in such a folder. This is not good manners; we'd rather it would respect the image's premade home.

If Cloud Build becomes more home (and user) friendly, at some point, we could build the image differently.

>Where a Docker image is being used *should not affect* its building in this way. What this means is that we're currently building a Firebase Emulators image **optimized for Cloud Build** instead of use in any CI/CD system supporting Docker images as build steps.


## Alternatives

- Community [Firebase image](https://github.com/GoogleCloudPlatform/cloud-builders-community/tree/master/firebase)

  The info that there's emulation (that requires Java) has not reached it, yet (Jun 2021). There is an [issue](https://github.com/GoogleCloudPlatform/cloud-builders-community/issues/441) raised but no PR. Pushing this code to the community repo would be the right thing to do but feels like too much friction for the author.

- [`timbru31/docker-java-node`](https://github.com/timbru31/docker-java-node)
 
  This repo is mentioned as a foundation having both Java and Node. However, the author faced problems building it (Mar-21). Being based on "Azul" OpenJDK image wasn't reaffirming for general use, either. 

  The repo takes a JDK/JRE base image and installs Node on top of it. This repo does the opposite.

---

Obviously, some consolidation of these efforts would be Good For All.

It is unfortunate this support is not arising from the Firebase team itself. The author thinks it should - but it can also be a community endeavour, where we show Firebase that a better Emulator Experience (EX?) can be reached.

One crucial part of this would be speeding up the emulators. The aim should be much higher than the official package - let's say 5x faster, 5x easier, and sandboxed.


## References

- `nodejs/docker-node` > [Node.js > How to use this image](https://github.com/nodejs/docker-node/blob/master/README.md#how-to-use-this-image) (node docs)
- Cloud Build > ... > [Creating a custom builder](https://cloud.google.com/build/docs/configuring-builds/use-community-and-custom-builders#creating_a_custom_builder) (Cloud Build docs)

