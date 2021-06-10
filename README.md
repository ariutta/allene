# Allene: keep interdependent JS packages in sync

Working on multiple related packages? Dependency tree look something like this?

```
******MyPackageA******
 ^      ^         ^
 |      |         |
 | MyPackageB MyPackageC
 |      ^
 |      |
MyPackageD
```

Allene can help. It keeps your packages in sync across your whole project:

- always use latest versions of your packages
- uniformly update third-party dependencies
- find unused dependencies

This is an alternative to using a monorepo with lerna and yarn workspaces. You
get many of the same benefits, but you can continue using a separate repo for
each package.

## Install

1. Install dependencies: `bash`, `parallel`, `sed`, `jq`, `Node.js` and `NPM`/`Yarn`
2. Get repo: `git clone https://github.com/ariutta/allene.git`
3. Add `allene` to PATH: `export PATH="allene:$PATH"`

## Usage

1. Login: `npm login` or `yarn login` (to let Allene know which packages belong to you)
2. In an empty directory of your choosing, initialize for your package:
   `allene init '<your-package-name>'`

   Your specified package and any of its dependencies that are also yours will be
   organized like this:

   ```
   |--node_modules (third-party)
   |--packages (yours)
   |  |--MyPackageA
   |  |  |--package.json
   |  |  |--...
   |  |--MyPackageB
   |  |  |--package.json
   |  |  |--...
   |  |--MyPackageC
   |  |  |--package.json
   |  |  |--...
   |  |--MyPackageD
   |  |  |--package.json
   |  |  |--...
   |--...
   ```

   You can `cd` into your packages, edit files and git push/pull just like normal.

3. Update dependencies: `allene update`
4. Find unused dependencies: `allene depcheck`

Run `allene --help` to see all available commands.

If you have `yarn` installed, `allene` will use it instead of `npm`.
To force usage of `npm`, set the `ALLENE_PACMAN_CLI` env var:
`export ALLENE_PACMAN_CLI="npm"`

### Example

If you're on the Pvjs team, you can create a dev environment for package `@wikipathways/pvjs`:

1. Login: `npm login`
2. Create workspaces structure for package `@wikipathways/pvjs`:
   `ALLENE_PACMAN_CLI="npm"; ../../allene/allene init '@wikipathways/pvjs'`
3. Update: `ALLENE_PACMAN_CLI="npm"; ../../allene/allene update`
4. Find unused dependencies: `../../allene/allene depcheck`

## TODO

### all namespaced or all not

handle the case where all deps are namespaced or all are not

### tsc --rootDirs

Do we want to specify `rootDirs` for the top-level package.json?

### npm package version formats

`"^1.9 || ^2 || ^2.1.0-beta || ^2.2.0-rc || ^3.0.0"`

## Useful JQ queries

Get the path to any `peerDependencies` keys:
`cat npm-ls-out.json | jq 'path(..|.peerDependencies? | select(. != null))'`
