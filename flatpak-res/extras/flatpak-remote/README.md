# flatpak-remote
flatpak-remote is a template for creating Flatpak remotes for single projects using GitHub Workflow. It is based on [gasinvein/proton-flatpak](https://github.com/gasinvein/proton-flatpak/blob/master/.github/workflows/flatpak.yml). No additional hardware or money is required.

**Disclaimer!** This project is extremely hacky! We have done our best to make the setup as easy as possible. However, this project is new and can be easily disrupted. It's also a lot more complex and time consuming to setup than publishing it on Flathub. Updating to a newer version/commit of the template may require manual intervention on the workflow.

## Features
- Additional branches: this is useful for projects that do not comply with Flathub's guidelines, e.g. if your project has no tagged releases, icons, etc. Sometimes developers want more than two branches. Flathub only allows `stable` and `beta` branches, so a third branch in Flathub would be literally impossible unless Flathub lets us create additional branches. This project helps the developers who want to have a third branch, be it `nightly` or other, while keeping the same App ID.
- f-e-d-c support: [flatpak-external-data-checker](https://github.com/flathub/flatpak-external-data-checker/) (f-e-d-c) can be used in the template. However, you will still have to manually [make changes](https://github.com/flathub/flatpak-external-data-checker/#changes-to-flatpak-manifests) to the manifest so it can automatically update dependencies and the project itself.
- Extensible: since this is only a template, it can be extended to do a lot more things, like make [flatpak-builder-tools](https://github.com/flatpak/flatpak-builder-tools) automatically update itself, which is unsupported on Flathub.

### What doesn't work
At the moment, we've found two things that do not work:
- `extra-data`, see [flatpak/flatpak#3790](https://github.com/flatpak/flatpak/issues/3790).
- History log, running `flatpak remote-info --log $REMOTE $APP_ID` will give an error.

## Setting up
As written previously, this setup is more complex than publishing on Flathub.

### Requirements
- Full access to the repository and probably organization too.
- Understanding with Flatpak (or not, if you want to learn).

### Preparing
Before starting, create a new personal access token (PAT). [Generate a new token](https://github.com/settings/tokens/new), and copy the token in a safe space. The token should start with `ghp`. **Do not share the token with anyone!**

1. Since this is a template, you can press on the green `Use this template` button at the top of the page. It will ask you to type in a repository name. You are free to choose the name of the repository.
2. Before you create the repository from the template, check `Include all branches` box. This template sets up a GitHub page that is located in the `gh-pages` branch. This is required to have a successful Flatpak remote.
   - If you forgot to check that branch, create a new branch called `gh-pages`, then create a new `index` directory and an empty file called `static` inside the directory.
3. Press on the green `Create repository from template` button to create your new repository.
   - Optional: as soon as you create the repository, a new action will start running. You can manually turn it off in the `Actions` tab.
4. Go to the settings of the repository, press on the `Secrets` tab. 
5. Press on the `New repository secret`
6. Type `PAT` inside `Name`, and paste your PAT inside `Value`.

For the steps below, I advise to clone the repository and work locally, or press the dot (`.`) button to open GitHub's IDE.

### Adding/Creating manifest and dependencies
If you want to use already existing manifest and dependencies in Flathub, you can copy and paste its content to your repository.

If you have to create a manifest, refer to the Flatpak [documentation](https://docs.flatpak.org/en/latest/index.html) or to the [Flatpak Building Guide (video)](https://www.youtube.com/watch?v=xnnJRP4t9gM).

### Editing workflows
Editing workflows may require repetition. `flatpak.yml` is used to build and push Flatpak packages to the remote.

In the `env:` list, these are the variables that will need to be changed. The comments explain what they are/do. You can edit them accordingly.

Once done, push the changes to the repository and it should start building.

### Allowing access to your container image
Finally, in order to allow users the ability to download packages from your Flatpak repository you must allow everyone read access to your container image.

You accomplish this by doing the following:

1. On GitHub, navigate to the main page of your user account.
2. In the top right corner of GitHub, click your profile photo, then click `Your profile`. 
3. On your profile page, in the top right, click `Packages`. 
4. From here you could change the visibility of your container to allow everyone to read your container.