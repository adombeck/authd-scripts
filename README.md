# Setup

In the authd repository, run the following commands:

```bash
git clone https://github.com/adombeck/authd-scripts .scripts
echo /.scripts/ >> .git/info/exclude
```

To enable the pre-push hook:

```bash
ln -sf .scripts/pre-push .git/hooks/pre-push
```

# Usage

Execute the scripts from the authd repo, like this:

```
.scripts/build-authd-deb --help
```

Check the usage messages of the scripts, they all support `--help` (except the pre-push hook).
