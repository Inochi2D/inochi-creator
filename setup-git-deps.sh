#!/bin/bash

# Run this script from the directory you want all of these repos to be
# cloned into.

# Clone a git repo, then add it to dub as a specific version.
clone_add () {
	DIR=$1
	VERSION=$2
	GIT_URL=$3
	if [ ! -d "$DIR" ]; then
		echo "Cloning $DIR"
		git clone $GIT_URL $DIR
	fi
	dub add-local $DIR "$VERSION"
	echo "" # For a nice newline
}

clone_add i18n-d "1.0.1" https://github.com/KitsunebiGames/i18n.git
clone_add psd-d "0.6.1" https://github.com/Inochi2D/psd-d.git
clone_add bindbc-imgui "0.7.0" "--recurse-submodules https://github.com/Inochi2D/bindbc-imgui.git"
clone_add facetrack-d "0.6.2" https://github.com/Inochi2D/facetrack-d.git
clone_add inmath "1.0.5" https://github.com/Inochi2D/inmath.git
clone_add inochi2d "0.8.0" https://github.com/Inochi2D/inochi2d.git
