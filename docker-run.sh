#!/bin/sh

# Railway volumes need root permissions
if [[ -n "$RAILWAY_ENVIRONMENT" ]]; then
    UID=0
    GID=0
fi

if [[ -z "$GID" ]]; then
    GID="$UID"
fi

# Define fixperms function BEFORE using it
function fixperms {
    chown -R $UID:$GID /data
    
    # /opt/mautrix-linkedin is read-only, so disable file logging if it's pointing there.
    if [[ "$(yq e '.logging.writers[1].filename' /data/config.yaml)" == "./logs/mautrix-linkedin.log" ]]; then
        yq -I4 e -i 'del(.logging.writers[1])' /data/config.yaml
    fi
}

# Generate config if missing
if [[ ! -f /data/config.yaml ]]; then
    /usr/bin/mautrix-linkedin -c /data/config.yaml -e
    echo "Didn't find a config file."
    echo "Copied default config file to /data/config.yaml"
    echo "Modify that config file to your liking."
    echo "Start the container again after that to generate the registration file."
    exit
fi

# Generate registration if missing
if [[ ! -f /data/registration.yaml ]]; then
    /usr/bin/mautrix-linkedin -g -c /data/config.yaml -r /data/registration.yaml || exit $?
    echo "Didn't find a registration file."
    echo "Generated one for you."
    echo "See https://docs.mau.fi/bridges/general/registering-appservices.html on how to use it."
    exit
fi

cd /data
fixperms
exec su-exec $UID:$GID /usr/bin/mautrix-linkedin
