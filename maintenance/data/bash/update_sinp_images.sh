#!/bin/bash
# Subscript to update SINP images on web-srv.

if [ -z "$STY" ]; then
    exec screen -dmS inpn-images-update /bin/bash "$0"
fi

cd ~/www/taxhub/data/scripts/import_inpn_media
source venv/bin/activate
python import_inpn_media.py
deactivate;

# To keep screen session restart bash
bash
