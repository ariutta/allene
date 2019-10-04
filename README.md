# allene

The [alle](https://github.com/boennemann/alle) structure allows for editing
multiple related projects in sync. Allene is a tool that makes it easy to:

- set up your projects in the alle structure
- update dependencies
- find unused dependencies

## Install

1. Install dependencies: bash, sed, jq, Node.js, NPM or Yarn
2. `git clone https://github.com/ariutta/allene.git`
3. `export PATH="allene:$PATH"`

## Usage

1. Login: `npm login` or `yarn login`
2. Create project directory: `mkdir <your-package-name>-alle; cd <your-package-name>-alle`
3. Create alle-inspired project structure for your package:
   `allene init '<your-package-name>'`
4. Update dependencies: `allene update`
5. Find unused dependencies: `allene depcheck`

Run `allene --help` to see all available commands.

If you have `yarn` installed, `allene` will use it instead of `npm`.
You can override this by setting the `ALLENE_PACMAN_CLI` env var:
`export ALLENE_PACMAN_CLI="npm"`

Example: setup an alle project structure for package `@wikipathways/pvjs` as a
member of the Pvjs team, using `npm` as package manager tool:

1. Login: `npm login`
2. Create project directory: `mkdir pvjs-alle; cd pvjs-alle`
3. Create alle-inspired project structure for package `@wikipathways/pvjs`:
   `ALLENE_PACMAN_CLI="npm"; ../../allene/allene init '@wikipathways/pvjs'`
4. Update: `ALLENE_PACMAN_CLI="npm"; ../../allene/allene update`
5. Find unused dependencies: `../../allene/allene depcheck`

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
