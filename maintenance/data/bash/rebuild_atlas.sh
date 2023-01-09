#!/bin/bash
# Subscript to rebuild GeoNature Atlas on web-srv.

# Run script inside Screen session
if [ -z "$STY" ]; then
    exec screen -dm -S atlas-update /bin/bash "$0";
fi

cd ~/www/atlas/

sudo -u postgres \
    psql -c "SELECT pg_terminate_backend(pg_stat_activity.pid)
        FROM pg_stat_activity
        WHERE pg_stat_activity.datname = 'gnatlas'
            AND pid <> pg_backend_pid();" \
    && ./install_db.sh

