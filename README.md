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

The hook formats Robot Framework tests with Robocop. If formatting changes any
files, the push is rejected so you can review and commit those changes first.

# Usage

Execute the scripts from the authd repo, like this:

```
.scripts/build-authd-deb --help
```

Check the usage messages of the scripts, they all support `--help` (except the pre-push hook).

To debug an end-to-end test run from its hosted log URL:

```
.scripts/debug-ci-e2e-test 'https://authd-e2e-test-logs.adrian-dombeck.workers.dev/pr-1927/run-35341372449-1/resolute-authd-msentraid/log.html'
.scripts/debug-ci-e2e-test 'https://authd-e2e-test-logs.adrian-dombeck.workers.dev/push-36452199482/run-36452199482-1/noble-authd-msentraid/log.html'
```

Non-PR log URLs use the event and workflow run ID in the first path segment.
The workflow also creates logs for pushes (to `main` and tags), manual
(`workflow_dispatch`), and scheduled (`schedule`) runs.
