
*The initial version of this repo pushed to GitHub Packages. This text was moved away from `README` since we now target Cloud Registry (Google Cloud Platform), instead.*

It may be useful to you, but no guarantees!

---

## Requirements

For publishing to GitHub Packages, you need an access token with `write:packages` scope.

1. Go to your GitHub profile > Settings
2. Developer Settings 
3. Personal Access Tokens > [Generate new token](https://github.com/settings/tokens/new)
4. Tick `write:packages` (also ticks `read:packages` and `repo`)
5. `Generate token`

Pick the token value; it will be used as `$TOKEN`, later.


## Pushing to GitHub Packages

With:

- `$IMAGE_ID` being the id of a built image
- `$USERNAME` your GitHub username (`akauppi`)
- `$REPOSITORY` = name of one's repo: `firebase-jest-testing`
- `$IMAGE_NAME` = `firebase-node-builder`
- `$VERSION` e.g. `8.8.1-node14-300820a`
- `$TOKEN_TXT` being a file that contains your GitHub token

Here, we use `firebase-jest-testing` as the repo name since the images really are for that project. This allows us to later move these source there, if we want to.

First, let's log in with the token you have created:

```
$ echo $TOKEN | docker login https://docker.pkg.github.com -u $USERNAME --password-stdin
Login Succeeded
```

Then, tag the built image:

```
$ docker tag $IMAGE_ID docker.pkg.github.com/$USERNAME/$REPOSITORY/$IMAGE_NAME:$VERSION
```

Push to GitHub Packages:

```
$ docker push docker.pkg.github.com/$USERNAME/$REPOSITORY/$IMAGE_NAME:$VERSION
```

>Note: If you get problems about the validity of the token here, it may be that the token you fed to `docker login` had newlines. Unfortunately, though it says "Login Succeeded" it likely checks the login only when pushing.


## Using the image

You can refer to the image as:

```
docker.pkg.github.com/akauppi/firebase-jest-testing/firebase-node-builder:8.8.1-node14
```

## References

- [Configuring Docker for use with GitHub Packages](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages) (GitHub docs)
