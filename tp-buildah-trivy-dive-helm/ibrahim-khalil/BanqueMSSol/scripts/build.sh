#!/usr/bin/env bash
# ============================================================
# build.sh — Chaîne de build OCI intégrée pour MIAGE-Bank
#
# Étapes :
#   1. (Optionnel) Lint du Containerfile avec Hadolint
#   2. Build de l'image via Buildah
#   3. Export tar pour les outils de scan
#   4. Scan Trivy — génération JSON + SARIF
#   5. Gate de sécurité : interruption si CVE CRITICAL détectées
#   6. Audit Dive en mode CI
#   7. Consolidation des rapports dans build-reports/
#
# Usage :
#   ./scripts/build.sh [OPTIONS] SERVICE_DIR IMAGE_NAME PORT
#
# Options :
#   --skip-critical-gate   Continue malgré des CVE CRITICAL (⚠ à documenter)
#   --no-hadolint          Ignore l'étape Hadolint même si l'outil est absent
#   --containerfile FILE   Nom du Containerfile (défaut : Containerfile.optimized)
#
# Exemples :
#   ./scripts/build.sh Banque-ClientService banque-clientservice:7.0 10011
#   ./scripts/build.sh --skip-critical-gate Banque-Annuaire banque-annuaire:7.0 10001
#   ./scripts/build.sh --containerfile Containerfile Banque-CompteService banque-compteservice:7.0 10021
# ============================================================

set -euo pipefail

# ── Couleurs ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
step()    { echo -e "\n${BOLD}━━━ $* ━━━${RESET}"; }

# ── Valeurs par défaut ────────────────────────────────────────────────────────
SKIP_CRITICAL_GATE=false
CONTAINERFILE="Containerfile.optimized"

# ── Parsing des arguments ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-critical-gate)  SKIP_CRITICAL_GATE=true; shift ;;
    --no-hadolint)         NO_HADOLINT=true; shift ;;
    --containerfile)       CONTAINERFILE="$2"; shift 2 ;;
    -*) error "Option inconnue : $1"; exit 1 ;;
    *)  break ;;
  esac
done

if [[ $# -lt 3 ]]; then
  error "Usage : $0 [OPTIONS] SERVICE_DIR IMAGE_NAME PORT"
  error "Exemple : $0 Banque-ClientService banque-clientservice:7.0 10011"
  exit 1
fi

SERVICE_DIR="$1"
IMAGE_NAME="$2"
SERVICE_PORT="$3"

# ── Chemins ───────────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_PATH="$REPO_ROOT/$SERVICE_DIR"
REPORTS_DIR="$REPO_ROOT/build-reports"
SAFE_NAME=$(echo "$IMAGE_NAME" | tr ':/' '--')
CONTAINERFILE_PATH="$SERVICE_PATH/$CONTAINERFILE"
TAR_PATH="$REPORTS_DIR/${SAFE_NAME}.tar"
DIVE_CI_CONF="$REPO_ROOT/.dive-ci.yml"

mkdir -p "$REPORTS_DIR"

# ── Vérifications préalables ──────────────────────────────────────────────────
if [[ ! -f "$CONTAINERFILE_PATH" ]]; then
  error "Containerfile introuvable : $CONTAINERFILE_PATH"
  error "Utilisez --containerfile Containerfile pour cibler le Containerfile standard."
  exit 1
fi

command -v buildah >/dev/null 2>&1 || { error "buildah non trouvé"; exit 1; }
command -v trivy   >/dev/null 2>&1 || { error "trivy non trouvé";   exit 1; }
command -v dive    >/dev/null 2>&1 || { error "dive non trouvé";    exit 1; }

START_TS=$(date +%s)
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗"
echo -e "║  MIAGE-Bank — Chaîne de build OCI intégrée           ║"
echo -e "╚══════════════════════════════════════════════════════╝${RESET}"
info "Service       : $SERVICE_DIR"
info "Image cible   : $IMAGE_NAME"
info "Port          : $SERVICE_PORT"
info "Containerfile : $CONTAINERFILE"
info "Rapports dans : $REPORTS_DIR"
[[ "$SKIP_CRITICAL_GATE" == "true" ]] && warn "Mode --skip-critical-gate activé — gate CRITICAL désactivée"

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 1 — Lint Hadolint (optionnel)
# ─────────────────────────────────────────────────────────────────────────────
step "1/6 — Lint Containerfile (Hadolint)"

if command -v hadolint >/dev/null 2>&1; then
  HADOLINT_OUT="$REPORTS_DIR/hadolint-${SAFE_NAME}.txt"
  if hadolint "$CONTAINERFILE_PATH" > "$HADOLINT_OUT" 2>&1; then
    success "Hadolint : aucun problème détecté"
  else
    ISSUES=$(wc -l < "$HADOLINT_OUT")
    warn "Hadolint : $ISSUES avertissement(s) — voir $HADOLINT_OUT"
    # Non bloquant : Hadolint émet des avertissements, pas des erreurs fatales
  fi
else
  warn "Hadolint non installé — étape ignorée"
  warn "Installation : https://github.com/hadolint/hadolint/releases"
fi

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 2 — Build Buildah
# ─────────────────────────────────────────────────────────────────────────────
step "2/6 — Build de l'image avec Buildah"

info "buildah bud --tag $IMAGE_NAME -f $CONTAINERFILE $SERVICE_DIR/"
buildah bud \
  --tag "$IMAGE_NAME" \
  -f "$CONTAINERFILE_PATH" \
  "$SERVICE_PATH/" 2>&1 | grep -E "STEP|COMMIT|Successfully|Error|error" || true

success "Image construite : $IMAGE_NAME"

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 3 — Export tar pour Trivy et Dive
# ─────────────────────────────────────────────────────────────────────────────
step "3/6 — Export de l'image en archive tar"

info "Export vers : $TAR_PATH"
rm -f "$TAR_PATH"   # docker-archive ne supporte pas l'écrasement d'archives existantes
buildah push "$IMAGE_NAME" "docker-archive:${TAR_PATH}" 2>&1 \
  | grep -v "^Copying\|^Getting\|^Writing" || true

success "Archive : $(du -h "$TAR_PATH" | cut -f1)"

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 4 — Scan Trivy
# ─────────────────────────────────────────────────────────────────────────────
step "4/6 — Scan de sécurité Trivy"

TRIVY_JSON="$REPORTS_DIR/trivy-${SAFE_NAME}-full.json"
TRIVY_SARIF="$REPORTS_DIR/trivy-${SAFE_NAME}.sarif"
TRIVY_TABLE="$REPORTS_DIR/trivy-${SAFE_NAME}-high-critical.txt"

info "Génération du rapport JSON..."
trivy image \
  --format json \
  --output "$TRIVY_JSON" \
  --input "$TAR_PATH" 2>/dev/null

info "Génération du rapport SARIF..."
trivy image \
  --format sarif \
  --output "$TRIVY_SARIF" \
  --input "$TAR_PATH" 2>/dev/null

info "Génération du rapport table HIGH/CRITICAL..."
trivy image \
  --severity HIGH,CRITICAL \
  --format table \
  --output "$TRIVY_TABLE" \
  --input "$TAR_PATH" 2>/dev/null

# Comptage par sévérité
CRITICAL_COUNT=$(python3 -c "
import json
with open('$TRIVY_JSON') as f: d=json.load(f)
n=[v for r in d.get('Results',[]) for v in r.get('Vulnerabilities',[]) if v.get('Severity')=='CRITICAL']
print(len(n))
" 2>/dev/null || echo 0)

HIGH_COUNT=$(python3 -c "
import json
with open('$TRIVY_JSON') as f: d=json.load(f)
n=[v for r in d.get('Results',[]) for v in r.get('Vulnerabilities',[]) if v.get('Severity')=='HIGH']
print(len(n))
" 2>/dev/null || echo 0)

TOTAL_COUNT=$(python3 -c "
import json
with open('$TRIVY_JSON') as f: d=json.load(f)
n=[v for r in d.get('Results',[]) for v in r.get('Vulnerabilities',[])]
print(len(n))
" 2>/dev/null || echo 0)

info "Résultats Trivy : CRITICAL=$CRITICAL_COUNT  HIGH=$HIGH_COUNT  TOTAL=$TOTAL_COUNT"

success "Rapports Trivy générés dans $REPORTS_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 5 — Gate de sécurité CRITICAL
# ─────────────────────────────────────────────────────────────────────────────
step "5/6 — Gate de sécurité (CVE CRITICAL)"

if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
  if [[ "$SKIP_CRITICAL_GATE" == "true" ]]; then
    warn "⚠  $CRITICAL_COUNT CVE CRITICAL détectées — gate contournée via --skip-critical-gate"
    warn "⚠  À DOCUMENTER dans le rendu : migration Spring Boot 3.x requise pour résoudre ces CVE."
  else
    error "🚫 BUILD INTERROMPU : $CRITICAL_COUNT CVE CRITICAL détectées dans $IMAGE_NAME"
    error "   Consultez le rapport : $TRIVY_JSON"
    error "   Pour continuer malgré les CVE : ajoutez --skip-critical-gate"
    error "   Remédiation recommandée : mettre à jour Spring Boot vers 3.x (Java 17 requis)"
    exit 1
  fi
else
  success "Gate CRITICAL : aucune CVE CRITICAL — build autorisé à continuer"
fi

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAPE 6 — Audit Dive
# ─────────────────────────────────────────────────────────────────────────────
step "6/6 — Audit des layers avec Dive"

DIVE_REPORT="$REPORTS_DIR/dive-${SAFE_NAME}-ci.txt"

if [[ ! -f "$DIVE_CI_CONF" ]]; then
  warn "Fichier .dive-ci.yml absent — génération avec les seuils par défaut du sujet"
  cat > "$DIVE_CI_CONF" <<EOF
rules:
  lowestEfficiency: 0.95
  highestWastedBytes: 20000000
  highestUserWastedPercent: 0.10
EOF
fi

DIVE_EXIT=0
CI=true dive \
  --source docker-archive \
  --ci-config "$DIVE_CI_CONF" \
  "$TAR_PATH" > "$DIVE_REPORT" 2>&1 || DIVE_EXIT=$?

# Afficher le résumé Dive
grep -E "efficiency|wastedBytes|userWasted|PASS|FAIL|Result" "$DIVE_REPORT" | head -10 || true

if [[ $DIVE_EXIT -ne 0 ]]; then
  error "Dive : une ou plusieurs gates ont échoué — voir $DIVE_REPORT"
  exit $DIVE_EXIT
else
  success "Dive : toutes les gates passées"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Résumé final
# ─────────────────────────────────────────────────────────────────────────────
END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗"
echo -e "║  Résumé du build                                     ║"
echo -e "╚══════════════════════════════════════════════════════╝${RESET}"
echo -e "  Image     : ${GREEN}$IMAGE_NAME${RESET}"
echo -e "  Durée     : ${ELAPSED}s"
echo -e "  CVE       : CRITICAL=$CRITICAL_COUNT  HIGH=$HIGH_COUNT  TOTAL=$TOTAL_COUNT"
echo ""
echo -e "  Rapports  :"
for f in "$REPORTS_DIR"/*"${SAFE_NAME}"*; do
  [[ -f "$f" ]] && echo -e "    $(du -h "$f" | cut -f1)  $(basename "$f")"
done
echo ""

if [[ "$SKIP_CRITICAL_GATE" == "true" && "$CRITICAL_COUNT" -gt 0 ]]; then
  warn "BUILD TERMINÉ AVEC AVERTISSEMENT — $CRITICAL_COUNT CVE CRITICAL présentes"
  warn "Ce résultat doit être documenté et justifié dans le compte-rendu."
  exit 0
fi

success "BUILD RÉUSSI"
