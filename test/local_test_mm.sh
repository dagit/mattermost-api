#!/bin/sh

set -e

HERE=$(cd `dirname $0`; pwd)
TEST_PROGRAM=test-mm-api
ROOT=$HERE/..
CONTAINER=mattermost-preview

function error {
    echo Error: $* >&2
    exit 1
}

function docker_installed {
    which docker 2>/dev/null >/dev/null
}

function container_present {
    docker ps --all | grep $CONTAINER >/dev/null
}

function cleanup_last_container {
    # This check ensures that we only attempt to stop and remove the
    # container if it already exists. Any failure in these commands is
    # thus not indicative of a missing image (say, on first run of this
    # script on a fresh system).
    if container_present
    then
        docker stop $CONTAINER
        docker rm   $CONTAINER
    fi
}

# Note: [JED] You may need to change TEST_RUNNER depending on your
# environment. As of writing this script `cabal new-build` doesn't
# have a `new-run` so I use the following find command to locate the
# test-mm-api executable. YMMV.
TEST_RUNNER=$(find $ROOT -name $TEST_PROGRAM -type f)

if [ -z "$TEST_RUNNER" ]
then
    error "cannot find $TEST_PROGRAM in $ROOT, exiting"
fi

if ! docker_installed
then
    error "'docker' not found in PATH, exiting"
fi

cleanup_last_container

# If this command fails we're in trouble.
docker run  --name $CONTAINER -d --publish 8065:8065 mattermost/$CONTAINER

# It takes a while for the MM server to start accepting logins
$HERE/wait_for_mm.sh
echo

# Finally we are ready to run the test suite
$TEST_RUNNER
