#!/bin/sh
# Use Spotify's supported PulseAudio backend through pipewire-pulse, with
# playback headroom independent of Quickshell's graphics and spectrum work.
export PULSE_LATENCY_MSEC=80
exec /opt/spotify/spotify --audio-api=pulseaudio --ozone-platform=wayland --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 "$@"
