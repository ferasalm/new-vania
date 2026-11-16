#!/bin/sh
# Downloads one Rodin result. Usage: fetch.sh <out.glb> "<signed url>"
# The signed url comes from the Hyper3D "get result" answer (file base_basic_shaded.glb).
# It expires after 7 days and holds an access key: never paste it into a committed file.
curl -s -o "$1" -w "$1 %{http_code} %{size_download}\n" "$2"
