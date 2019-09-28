# allify

Tools to help work with the [alle](https://github.com/boennemann/alle) structure,
which allows for editing multiple related projects in sync.

- `collect-local-packages.sh`: get name/repo for every dep in `./packages/`

## Sync mynixpkgs

You probably don't need to worry about this. But if for some reason you want to sync the `mynixpkgs` subtree repo:

```
git subtree pull --prefix mynixpkgs mynixpkgs master --squash
git subtree push --prefix mynixpkgs mynixpkgs master
```

## TODO

## command line tools

It seems necessary to symlink some Node.js command line tools. For example,
this gives an error about gulp not being available:

```
cd ./packages/node_modules/svg-pan-zoom
npm run build
```

Doing this fixes that error:

```
mkdir -p ./packages/node_modules/.bin
cd ./packages/node_modules/.bin
ln -s ../../../node_modules/gulp/bin/gulp.js gulp
```

But some of my Node.js command line tools seem to work fine without doing this.
Why?

### all namespaced or all not

handle the case where all deps are namespaced or all are not

### tsc --rootDirs

Do we want to specify `rootDirs` for the top-level alle package.json?

### npm package version formats

`"^1.9 || ^2 || ^2.1.0-beta || ^2.2.0-rc || ^3.0.0"`

## Useful JQ queries

Get the path to any `peerDependencies` keys:
`cat npm-ls-out.json | jq 'path(..|.peerDependencies? | select(. != null))'`
