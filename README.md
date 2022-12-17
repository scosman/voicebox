<h1 align="center"><img alt="Voicebox Logo" src="https://user-images.githubusercontent.com/848343/207228601-d8e6d5eb-d8a2-40ce-a83b-6355f22022c7.png" width="300"></h1>

[![Build and Test](https://github.com/scosman/voicebox/actions/workflows/test.yml/badge.svg)](https://github.com/scosman/voicebox/actions/workflows/test.yml)

# Mission

Explore using technology to aid people who lack both the ability to speak and fine motor control. This is common with cerebral palsy. 

Our goal is to find systems which make a significant impact to some part of their life, and can be scaled to help many people. If explorations are successful, we will ship apps and/or tools to make this work widely accessible.

Success for this mission is a solution **many** people use **often** which is **much better than prior methods**. To achieve that, we ensure broadly useful, easily available (eg: App Store), easy to learn (consumer grade usability, in-app coaching), free, and marketed to reach the people who need it. For this project, we’d rather fail at this ambitious mission, than compromise and ship something incremental or inaccessible. 

# Areas of Exploration

### 1) Realtime conversation 

- Allow people with cerebral palsy to participate in conversation in real time. Precision of wording is flexible, speed of communicating their ideas is critical. We want them to be involved at the pace of a typical conversation, with full expressiveness.
- Explorations include: ML-LLM autocomplete, ML-LLM prediction/synthesis, ML grammar and expression tools, speech to text, text to speech, and novel combinations of the above.
   
### 2) Novel UIs for text entry and system control

- Build novel UIs that better accommodate lack of fine motor control. Leverage the dynamic screens of mobile devices, to allow typing and system control without moving your hands. Make accessible switch systems more powerful and learnable with consumer grade design.
- Explorations include: 2-switch UIs, 1-switch UIs, modal UIs, tree-based selection, ML predictions, consumer-grade onboarding.

# Development

### iOS Build instructions

To build this project you must have an OpenAPI key, which isn't included in the repo. Make a copy of `/ios/voicebox/Utils/AppSecrets.h.TEMPLATE` in the location `/ios/voicebox/Utils/AppSecrets.h`, then paste in your real API key. 

### iOS Formatting Requirements

Any commits should be formatted with clang-format. Run `ios/format-code.sh` to format to project standards. The script `check-format.sh` checks for compliance with formatting standards. Copy the git hook in `ios/voicebox/Git Hooks` to your `.git/hooks` directory to ensure it's not missed.

