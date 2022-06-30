# Munki Self Service Manifest Editor

This tool is designed to let an admin script easy changes to Munki's SelfService manifest.


## Rationale

Let's say your team has deployed FooSoft 8 via `optional_installs` with the package name `FooSoftEight`. When FooSoft 9 comes out - it's not _quite_ backwards compatible with everything your 8 users were using - you deploy it with the name `FooSoftNine` and add it to `optional_installs`.  8 is eventually no longer supported, so you need to flip your customers over to 9, but since each install automatically activates a license, you don't want to spray it everywhere.

`munki-ssm-editor replace FooSoftEight FooSoftNine` will do this for you: if the Mac got 8 via self-service, it will remove 8 and add 9 to the install list, triggering Munki to install 9.

## Modes

| Command | Description |
| --- | --- |
| `munki-ssm-editor add PackageName` | Adds the title as though the user chose to install it in Managed Software Center |
| `munki-ssm-editor remove PackageName` | Remove the title from the install list |
| `munki-ssm-editor remove --uninstall PackageName` | Remove from the install list _and_, if it was in the install list, add it to the uninstall list |
| `munki-ssm-editor replace OldName NewName` | If `OldName` was in the install list, swap it with `NewName` |
| `munki-ssm-editor replace --uninstall OldName NewName` | If `OldName` was in the install list, swap it with `NewName`, and add `OldName` to the uninstall list |

This tool requires `root` to run so you'll need some way to actually deploy and run it. We use a Jamf policy, but you could use a Munki `nopkg` "package" as well. It's designed to be (somewhat) idempotent, so you could have one script that just gets re-ran every week, and you add all your deprecations / bumps to it.

This was written in Swift to reduce client-side dependencies.

