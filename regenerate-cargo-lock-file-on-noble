#!/bin/sh

set -eu

lxc config device remove u24 workdir
lxc config device add u24 workdir disk source="$PWD" path=/src

lxc exec --cwd /src u24 -- sh -c "cargo generate-lockfile"

git add Cargo.lock

git commit -m "Regenerate Cargo.lock with cargo from noble"
