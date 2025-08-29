#!/bin/bash
set -euo pipefail

BUILD_DIR="build/web"
INDEX_FILE="$BUILD_DIR/index.html"
VERSION=$(date +%Y%m%d%H%M%S)
SNIPPET_FILE="$BUILD_DIR/__version_snippet__.html"
TMP_FILE="$INDEX_FILE.tmp"

echo "🧹 Limpiando proyecto..."
flutter clean

echo "🏗️  Compilando con versión: $VERSION..."
flutter build web --release

if [ ! -f "$INDEX_FILE" ]; then
  echo "❌ Error: No se encontró $INDEX_FILE"
  exit 1
fi

echo "🔗 Aplicando versión en flutter_bootstrap.js..."
# Reescribe cualquier <script src="flutter_bootstrap.js..."> para meter ?v=VERSION
awk -v ver="$VERSION" '{
  gsub(/<script src="flutter_bootstrap\.js[^"]*"/,
       "<script src=\"flutter_bootstrap.js?v=" ver "\"");
  print
}' "$INDEX_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$INDEX_FILE"

echo "🧽 Eliminando bloque previo de versión (si existiera)..."
# Borra el bloque entre marcadores (multilínea) si existía
perl -0777 -pe 's/<!-- BUILD_VERSION_START -->.*?<!-- BUILD_VERSION_END -->\n?//s' \
  -i "$INDEX_FILE"

echo "🧩 Creando snippet de AUTO-UPDATE..."
cat > "$SNIPPET_FILE" <<EOF
<!-- BUILD_VERSION_START -->
<script>
(function () {
  var currentVersion = "$VERSION";

  // 1) Fuerza a que el SW busque updates en cada visita
  if ('serviceWorker' in navigator) {
    try {
      navigator.serviceWorker.getRegistrations()
        .then(function (regs) { return Promise.all(regs.map(function (r){ return r.update(); })); })
        .catch(function(){});
    } catch(e) {}

    // 2) Cuando el nuevo SW toma control, recargamos una sola vez
    (function(){
      var reloaded = false;
      navigator.serviceWorker.addEventListener('controllerchange', function () {
        if (!reloaded) {
          reloaded = true;
          try { localStorage.setItem('app_build', currentVersion); } catch(e) {}
          location.reload();
        }
      });
    })();
  }

  // 3) Persistimos versión y recarga "fallback" si NO hay SW
  try {
    var prev = localStorage.getItem('app_build');
    // Guard para evitar bucles de recarga en esta sesión
    var alreadyReloaded = sessionStorage.getItem('__app_auto_reloaded__') === '1';

    if (!prev) {
      localStorage.setItem('app_build', currentVersion);
    } else if (prev !== currentVersion) {
      localStorage.setItem('app_build', currentVersion);

      // Si no hay SW (o no dispara controllerchange), hacemos UNA recarga
      if (!('serviceWorker' in navigator)) {
        if (!alreadyReloaded) {
          sessionStorage.setItem('__app_auto_reloaded__', '1');
          location.reload();
        }
      } else {
        // Hay SW: normalmente controllerchange recargará.
        // Si por alguna razón no activa, como plan B puedes forzar:
        // setTimeout(function(){ if (!sessionStorage.getItem('__app_auto_reloaded__')) { sessionStorage.setItem('__app_auto_reloaded__','1'); location.reload(); } }, 4000);
      }
    }
  } catch(e) {}
})();
</script>
<!-- BUILD_VERSION_END -->
EOF

echo "📎 Insertando snippet antes de </body>..."
# Inserta el snippet justo antes de </body>. Si no hay </body>, lo agrega al final.
awk -v file="$SNIPPET_FILE" '
BEGIN{inserted=0}
{
  if (!inserted && /<\/body>/) {
    system("cat " file);
    inserted=1;
  }
  print;
}
END{
  if (!inserted) {
    system("cat " file);
  }
}
' "$INDEX_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$INDEX_FILE"

rm -f "$SNIPPET_FILE"

echo "✅ Versión $VERSION aplicada y auto-update habilitado en $INDEX_FILE."
echo "🏁 Proceso completo."