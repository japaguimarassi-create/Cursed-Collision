# Cursed Collision mobile publishing

This repository can be built and published from a phone using GitHub Actions. A local Roblox Studio installation is not required for the automated build/upload path.

## Roblox container

The Place Publishing API updates an existing place. It does not create the first experience/place. Create a small placeholder experience from the Roblox mobile Build feature, then use its Universe ID and Place ID as the target.

## Roblox API key

In Creator Dashboard, open API Keys and create a dedicated key for this game. For place publishing, grant the universe-places API system and Write access to the selected experience. Store the key securely; never commit it.

## GitHub secrets

In the repository's Settings -> Secrets and variables -> Actions, add:

- ROBLOX_API_KEY
- ROBLOX_UNIVERSE_ID
- ROBLOX_PLACE_ID

The workflow never prints the key.

## Publish

Open Actions -> Cursed Collision Publish -> Run workflow, enter the Universe ID and Place ID, set the publish confirmation to true, and run it.

The workflow first runs the same structural validator and Rojo build used by CI. Only a successful build is sent to Roblox through the Place Publishing API.

## Public release

Uploading a place and making its experience publicly discoverable are separate Roblox eligibility steps. Account age-check status, 2FA, maturity/compliance questionnaire, audience settings, and any required publishing/review requirements are handled by Roblox Creator Dashboard.

## Important

A successful API upload proves that Roblox accepted the place version. It does not prove that live multiplayer gameplay, moderation review, animations, assets, exploit resistance, or mobile performance were fully tested.