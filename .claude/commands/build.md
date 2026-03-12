Build, install, and optionally release PomoDaddy.

1. Run `bash scripts/build-install.sh` — builds a Release .app, installs to /Applications, and produces `build/PomoDaddy.zip`
2. Report the result. If the build fails, investigate and fix the issue.
3. If the user says "release" or provides a tag, upload the zip to a GitHub Release:
   `gh release create <tag> build/PomoDaddy.zip --title "<tag>" --generate-notes`
   If the release already exists, use `gh release upload <tag> build/PomoDaddy.zip --clobber`
4. Clean up: `rm -rf build/`
