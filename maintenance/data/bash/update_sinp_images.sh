#!/bin/bash
# Subscript to update SINP images on web-srv.

# Run script inside Screen session
if [ -z "$STY" ]; then
    exec screen -dm -S inpn-images-update /bin/bash "$0";
fi

cd ~/www/taxhub/data/scripts/import_inpn_media
source venv/bin/activate
python import_inpn_media.py
deactivate
