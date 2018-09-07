# alpine-tf
alpine dockerfile to build tensorflow using python3

Note that this checks out a git commit and builds from there inside of an alpine container. To update this, you can change the git commit hash. This was necessary as the release 1.10.1 would not build (bug fixes on the repo were not ported to the latest release).
