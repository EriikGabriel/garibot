#!/bin/bash
for i in `find . -name "*.png" -type f`; do
    echo "Otimizando imagem $i..." &&
    optipng -o7 -zm1-9 "$i" &&
    echo "$i Otimizada!"
done