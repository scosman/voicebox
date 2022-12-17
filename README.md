<h1 align="center"><img alt="Voicebox Logo" src="https://user-images.githubusercontent.com/848343/207228601-d8e6d5eb-d8a2-40ce-a83b-6355f22022c7.png" width="300"></h1>

[![Build and Test](https://github.com/scosman/voicebox/actions/workflows/test.yml/badge.svg)](https://github.com/scosman/voicebox/actions/workflows/test.yml)

`say 'a little bit louder now'`

## iOS Build instructions

To build this project you must have an OpenAPI key, which isn't included in the repo. Make a copy of `/ios/voicebox/Utils/AppSecrets.h.TEMPLATE` in the location `/ios/voicebox/Utils/AppSecrets.h`, then paste in your real API key. 

## iOS submission instructions

Any commits should be formatted with clang-format. Run `ios/format-code.sh` to format to project standards. The script `check-format.sh` checks for compliance with formatting standards. Copy the git hook in `ios/voicebox/Git Hooks` to your `.git/hooks` directory to ensure it's not missed.

