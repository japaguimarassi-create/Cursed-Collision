# Collision Battlestar mobile publishing

This repository can be built and published from a phone using GitHub Actions. A local Roblox Studio installation is not required for the automated build/upload path.

## Roblox API key

In Creator Dashboard, create a dedicated API key for this game. For place publishing, grant universe-places Write access to the selected experience. Store the key only in GitHub Actions secrets.

The repository workflow uses the fixed Collision Battlestar Universe and Place identifiers already configured in `.github/workflows/roblox-publish.yml`.

## Publish path

The publication workflow first runs the structural validator and Rojo build. Only a successful build is sent to Roblox through the Place Publishing API.

A successful API upload proves that Roblox accepted the place version. It does not prove live multiplayer gameplay, moderation review, animation coverage, audio mix, asset-loading availability or sustained mobile performance.

## External asset loading

The default Battle Line world is procedural and remains playable when AssetService third-party loading is unavailable. Approved public Creator Store props are an optional decoration pass.

## Mobile testing

Roblox's documented device emulation and live-device testing remain necessary for final UI and performance verification.
