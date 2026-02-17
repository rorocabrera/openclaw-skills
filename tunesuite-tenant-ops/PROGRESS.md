# TuneSuite Tenant Ops Skill - Progress

## Consolidation Status

- Unified `tunesuite-orders` and `tunesuite-users` into one skill: `tunesuite-tenant-ops`
- Kept tested endpoints and examples from both modules
- Removed inter-skill dependency links so all docs resolve locally

## Verified Areas

- Orders module: list/search/detail/status update/technician assignment/file workflows
- Users module: list/filter/get/update/delete and role filtering
- Tenant bootstrap flow: tenant code resolution + login + auth verification

## Remaining Validation

- Group-specific user workflows (`client-groups` across tenants with groups configured)
- User status/reset password endpoints where unavailable in current tenants
- RBAC edge cases for non-admin/non-manager roles in additional tenants

## Notes

- Do not store real credentials in skill docs or progress notes.
- Keep this file as operational status only.
