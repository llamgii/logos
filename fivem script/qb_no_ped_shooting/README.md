# qb_no_ped_shooting

Stops ambient peds from firing guns at citizens by removing their weapons and neutralizing combat behaviour. Ships as a light client-only QB resource.

## Install
1. Drop `qb_no_ped_shooting` into your resources folder.
2. Add `ensure qb_no_ped_shooting` to your `server.cfg` after qb-core.

## Notes
- Cops, SWAT and army peds are skipped by default (see `skipPedTypes` in `client.lua`).
- If you need to allow specific models, add them to `skipModels` in `client.lua`.
- Relationship groups are set to `Respect` so peds stay friendly to each other. Adjust the list in `relationshipGroups` if you have custom gangs/roles.

