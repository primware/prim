#!/bin/bash

BUILD_DIR="build/web"
INDEX_FILE="$BUILD_DIR/index.html"
VERSION=$(date +%Y%m%d%H%M%S)

echo "Limpiando proyecto..."
flutter clean

echo "Compilando con versión: $VERSION..."
flutter build web --release

if [ -f "$INDEX_FILE" ]; then
    echo "Agregando versión $VERSION al index.html..."

    # Detectar sistema operativo
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Darwin*)
            # macOS
            sed -i '' "s|<script src=\"flutter_bootstrap\.js[^\"]*\"|<script src=\"flutter_bootstrap.js?v=$VERSION\"|" "$INDEX_FILE"
            ;;
        Linux*)
            # Linux (Ubuntu o WSL)
            sed -i "s|<script src=\"flutter_bootstrap\.js[^\"]*\"|<script src=\"flutter_bootstrap.js?v=$VERSION\"|" "$INDEX_FILE"
            ;;
        *)
            echo "⚠️ Sistema operativo no compatible con este script."
            exit 1
            ;;
    esac

    echo "✅ Versión $VERSION aplicada correctamente en $INDEX_FILE."
else
    echo "❌ Error: No se encontró el archivo $INDEX_FILE."
    exit 1
fi

echo "🏁 Proceso completo."
