#!/bin/bash
# Deprecated — use install.sh for production. This wrapper kept for compatibility.
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install.sh" "$@"