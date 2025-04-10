#!/bin/bash
# Update docker.sock permission
sudo chown -R root:docker /var/run/docker.sock

# Setup proxy forward from localhost to host.docker.internal
sudo socat TCP-LISTEN:5432,reuseaddr,fork TCP:host.docker.internal:5432 &
sudo socat TCP-LISTEN:6379,reuseaddr,fork TCP:host.docker.internal:6379 &
sudo socat TCP-LISTEN:4566,reuseaddr,fork TCP:host.docker.internal:4566 &

exec "$@"
