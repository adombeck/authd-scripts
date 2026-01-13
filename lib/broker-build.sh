#!/bin/bash

LIBHIMMELBLAU_DIR="third_party/libhimmelblau"

create_and_switch_to_broker_build_dir() {
    set -euo pipefail

    local BASE_BRANCH=${1}
    local BUILD_DIR=${2}

    local ORIG_BRANCH
    ORIG_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    ORIG_DIR=$(pwd)

    # Export uncommitted changes from main repo
    git diff > /tmp/uncommitted.patch
    git diff --staged >> /tmp/uncommitted.patch

    if ! git submodule status "${LIBHIMMELBLAU_DIR}" &> /dev/null; then
        IGNORE_LIBHIMMELBLAU=1
    fi

    if [ -z "${IGNORE_LIBHIMMELBLAU:-}" ]; then
        local LIBHIMMELBLAU_COMMIT
        LIBHIMMELBLAU_COMMIT=$(git -C "${LIBHIMMELBLAU_DIR}" rev-parse HEAD)
        git -C "${LIBHIMMELBLAU_DIR}" diff "${LIBHIMMELBLAU_COMMIT}" > /tmp/libhimmelblau_uncommitted.patch

        # Ensure that the current commit of the libhimmelblau submodule is a reference that can be fetched
        LIBHIMMELBLAU_BRANCH="build-${RANDOM}"
        git -C "${LIBHIMMELBLAU_DIR}" branch -f "${LIBHIMMELBLAU_BRANCH}" HEAD
    fi

    if [ ! -d "${BUILD_DIR}" ]; then
        # Clone the build directory if it doesn't exist
        mkdir -p "$(dirname "${BUILD_DIR}")"
        git clone --recurse-submodules "$(pwd)" "${BUILD_DIR}"
        git -C "${BUILD_DIR}/${LIBHIMMELBLAU_DIR}" remote set-url origin "${ORIG_DIR}/${LIBHIMMELBLAU_DIR}"
    fi

    # Switch to the build directory
    pushd "${BUILD_DIR}"
    git fetch origin
    git -C "${LIBHIMMELBLAU_DIR}" fetch origin
    git reset --hard

    # Create a new branch based on the base branch with the commits that are not in the main branch cherry-picked
    if ! git show-ref --verify --quiet "refs/heads/build"; then
        git checkout -b build "origin/${BASE_BRANCH}"
    else
        git checkout build
        git reset --hard "origin/${BASE_BRANCH}"
    fi
    if [ "${ORIG_BRANCH}" != "main" ]; then
        git cherry-pick --abort || true # Abort any previous cherry-pick operation
        git cherry-pick --strategy-option=ours --empty=drop origin/main..origin/"${ORIG_BRANCH}"
    fi
    git submodule update
    # We need the main branch for the snap/version script
    git fetch origin main:main

    # Checkout the libhimmelblau commit in the submodule
    if [ -z "${IGNORE_LIBHIMMELBLAU:-}" ]; then
        git -C "${LIBHIMMELBLAU_DIR}" checkout "${LIBHIMMELBLAU_COMMIT}"
        cp "${ORIG_DIR}/${LIBHIMMELBLAU_DIR}/Cargo.lock" "${LIBHIMMELBLAU_DIR}/"
    fi

    # Apply uncommitted changes from the main repo
    if [ -s /tmp/uncommitted.patch ]; then
        git apply /tmp/uncommitted.patch
    fi
    if [ -s /tmp/libhimmelblau_uncommitted.patch ]; then
        git -C "${LIBHIMMELBLAU_DIR}" apply /tmp/libhimmelblau_uncommitted.patch
    fi

    git restore-mtime
    if [ -z "${IGNORE_LIBHIMMELBLAU:-}" ]; then
        git -C "${LIBHIMMELBLAU_DIR}" restore-mtime
    fi

    cleanup() {
        echo >&2 "---------- Cleaning up ----------"

        # Return to the original directory
        popd

        if [ -z "${IGNORE_LIBHIMMELBLAU:-}" ]; then
            # Delete the temporary libhimmelblau branch
            git -C "${LIBHIMMELBLAU_DIR}" branch -D "${LIBHIMMELBLAU_BRANCH}" || true
        fi

        # Print a message that the build failed if the exit code is non-zero
        if [ "$EXIT_CODE" -ne 0 ]; then
            echo >&2 "❌ Error: Build failed with exit code $EXIT_CODE, see above for details."
            exit "$EXIT_CODE"
        else
            echo >&2 "✅ Build completed successfully."
        fi
    }
    if [ -z "${SKIP_CLEANUP:-}" ]; then
        trap 'EXIT_CODE=$?; set +x; cleanup' EXIT
    fi
}
