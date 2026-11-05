#!/usr/bin/env bash

set -euo pipefail

demo_port="8081"
demo_mode="release"

for demo_argument in "$@"; do
  case "$demo_argument" in
    --debug)
      demo_mode="debug"
      ;;
    --release)
      demo_mode="release"
      ;;
    -h|--help)
      echo "Usage: $0 [port] [--release|--debug]"
      echo "Release mode is the default and is recommended for phone demos."
      exit 0
      ;;
    *)
      if [[ "$demo_argument" =~ ^[0-9]+$ ]]; then
        demo_port="$demo_argument"
      else
        echo "Unknown argument: $demo_argument" >&2
        echo "Usage: $0 [port] [--release|--debug]" >&2
        exit 2
      fi
      ;;
  esac
done

if ((demo_port < 1 || demo_port > 65535)); then
  echo "Port must be a number from 1 to 65535." >&2
  exit 2
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is not on PATH. Add the Flutter SDK bin directory and try again." >&2
  exit 1
fi

demo_ip=""
if command -v ipconfig >/dev/null 2>&1; then
  for demo_interface in en0 en1; do
    demo_ip="$(ipconfig getifaddr "$demo_interface" 2>/dev/null || true)"
    if [[ -n "$demo_ip" ]]; then
      break
    fi
  done
fi

echo "Starting the GeauxPark LAN demo..."
echo "Flutter mode: $demo_mode"
echo "Local URL: http://localhost:$demo_port"
if [[ -n "$demo_ip" ]]; then
  echo "Phone URL: http://$demo_ip:$demo_port"
else
  echo "Could not detect the LAN address automatically."
  echo "Run 'ipconfig getifaddr en0' and open http://<mac-ip>:$demo_port."
fi
echo "Keep this terminal open. Press Ctrl+C to stop the demo."
if [[ "$demo_mode" == "debug" ]]; then
  echo "Debug mode supports hot reload but may feel slower on a phone."
fi
echo

demo_mode_argument="--$demo_mode"
exec flutter run \
  -d web-server \
  "$demo_mode_argument" \
  --web-hostname 0.0.0.0 \
  --web-port "$demo_port" \
  -t lib/main.dart
