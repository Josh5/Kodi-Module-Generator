# Just some docs for me to refer to when publishing to the official repo


## Initial setup Update branch
```bash
# Fetch fork of main repo
git clone git@github.com:Josh5/repo-scripts.git
cd repo-scripts

git checkout matrix

git remote add upstream git@github.com:xbmc/repo-scripts.git

git pull upstream matrix

```

## Adding / Updating a module

### New module:
```bash
# Checkout a new  repo as a new branch
git checkout --orphan script.module.MODULE_NAME

# Update this new branch
git rm --cached -r .

```

### Existing module:
```bash
git checkout script.module.MODULE_NAME

```


## Creating A PR
```bash
# Checkout the official branch
git checkout matrix

# Create PR branch
git checkout -b matrix-MODULE_NAME

# Use subtree to place add-on into main repo tree
git read-tree --prefix=script.module.MODULE_NAME/ -u module.MODULE_NAME

```
