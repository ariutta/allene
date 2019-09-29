# allene

The [alle](https://github.com/boennemann/alle) structure allows for editing
multiple related projects in sync. Allene is a tool that makes it easy to:

- set up your projects in the alle structure
- update dependencies
- find unused dependencies

## Usage

Run `allene --help` to see available commands.

## Sync mynixpkgs

You probably don't need to worry about this. But if for some reason you want to sync the `mynixpkgs` subtree repo:

```
git subtree pull --prefix mynixpkgs mynixpkgs master --squash
git subtree push --prefix mynixpkgs mynixpkgs master
```

## TODO

### all namespaced or all not

handle the case where all deps are namespaced or all are not

### tsc --rootDirs

Do we want to specify `rootDirs` for the top-level alle package.json?

### npm package version formats

`"^1.9 || ^2 || ^2.1.0-beta || ^2.2.0-rc || ^3.0.0"`

## Useful JQ queries

Get the path to any `peerDependencies` keys:
`cat npm-ls-out.json | jq 'path(..|.peerDependencies? | select(. != null))'`
