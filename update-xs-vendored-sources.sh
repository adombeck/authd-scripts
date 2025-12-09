#!/bin/sh

set -eu

rm -rf vendor_rust || true
cargo vendor-filterer vendor_rust

export CARGO_VENDOR_DIR=vendor_rust
VENDORED_SOURCES=$(/usr/share/cargo/bin/dh-cargo-vendored-sources 2>&1) || cmd_status=$?
OUTPUT=$(echo "$VENDORED_SOURCES" | grep ^XS-Vendored-Sources-Rust: || true)
if [ -z "${OUTPUT}" ]; then
    if [ "${cmd_status:-0}" -ne 0 ]; then
      # dh-cargo-vendored-sources failed because of other reason, so let's fail with it!
      echo "dh-cargo-vendored-sources failed:"
      echo "${VENDORED_SOURCES}"
      exit "${cmd_status}"
    fi

    echo "XS-Vendored-Sources-Rust is up to date. No change is needed.";
    exit 0
fi

echo "XS-Vendored-Sources-Rust is out of date. Updating it now."
sed -i "s/^XS-Vendored-Sources-Rust:.*/$OUTPUT/" debian/control

git add debian/control
git commit -m "debian/control: Update XS-Vendored-Sources-Rust"
