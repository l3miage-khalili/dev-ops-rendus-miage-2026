#!/usr/bin/env bash
# Build d'un service MIAGE-Bank layer par layer via Buildah natif (sans Containerfile).
# Démontre le contrôle fin sur chaque layer, équivalent à l'approche Containerfile multi-stage.
#
# Usage : ./scripts/buildah-native.sh [SERVICE_DIR] [IMAGE_NAME] [PORT]
# Exemple depuis la racine du repo :
#   ./scripts/buildah-native.sh Banque-ClientService banque-clientservice:7.0 10011

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_DIR="${1:-Banque-ClientService}"
IMAGE_NAME="${2:-banque-clientservice:7.0}"
SERVICE_PORT="${3:-10011}"
FULL_SERVICE_PATH="$REPO_ROOT/$SERVICE_DIR"

echo "=== Buildah native build ==="
echo "Service : $SERVICE_DIR"
echo "Image   : $IMAGE_NAME"
echo "Port    : $SERVICE_PORT"
echo ""

# ---------------------------------------------------------------------------
# ÉTAPE 1 : Compilation Maven dans un conteneur éphémère
# ---------------------------------------------------------------------------
echo "[1/4] Compilation Maven..."

BUILD_CTR=$(buildah from docker.io/library/maven:3.9-eclipse-temurin-11)
buildah config --workingdir /workspace "$BUILD_CTR"

# Layer : copie pom.xml seul d'abord → les dépendances Maven sont cachées si pom.xml n'a pas changé
buildah copy "$BUILD_CTR" "$FULL_SERVICE_PATH/pom.xml" /workspace/pom.xml
buildah run "$BUILD_CTR" -- mvn dependency:go-offline -B -q

# Layer : copie du code source et compilation
buildah copy "$BUILD_CTR" "$FULL_SERVICE_PATH/src" /workspace/src
buildah run "$BUILD_CTR" -- mvn package -DskipTests -B -q

# Commit en image intermédiaire pour accéder au JAR depuis l'étape suivante
BUILD_IMG=$(buildah commit "$BUILD_CTR" "miage-build-stage-tmp:latest")
buildah rm "$BUILD_CTR"

# ---------------------------------------------------------------------------
# ÉTAPE 2 : Extraction des layers Spring Boot (depuis l'image de build)
# ---------------------------------------------------------------------------
echo "[2/4] Extraction des layers Spring Boot..."

EXTRACT_CTR=$(buildah from "$BUILD_IMG")
buildah config --workingdir /workspace "$EXTRACT_CTR"
buildah run "$EXTRACT_CTR" -- sh -c \
    'cp target/*.jar /workspace/application.jar && \
     java -Djarmode=layertools -jar /workspace/application.jar extract --destination /workspace/extracted'

EXTRACT_IMG=$(buildah commit "$EXTRACT_CTR" "miage-extract-stage-tmp:latest")
buildah rm "$EXTRACT_CTR"
buildah rmi "$BUILD_IMG"

# ---------------------------------------------------------------------------
# ÉTAPE 3 : Construction de l'image runtime layer par layer
# ---------------------------------------------------------------------------
echo "[3/4] Construction de l'image runtime..."

RUNTIME_CTR=$(buildah from docker.io/library/eclipse-temurin:11-jre-jammy)

# Layer : métadonnées OCI (labels)
buildah config \
    --label "org.opencontainers.image.title=${IMAGE_NAME%%:*}" \
    --label "org.opencontainers.image.description=MIAGE-Bank — service ${SERVICE_DIR}" \
    --label "org.opencontainers.image.version=7.0" \
    "$RUNTIME_CTR"

# Layer : répertoire de travail
buildah config --workingdir /app "$RUNTIME_CTR"

# Layer : binaire wait (téléchargé via curl puis curl supprimé — évite l'antipattern ADD URL)
buildah run "$RUNTIME_CTR" -- sh -c \
    'apt-get update -q && \
     apt-get install -y --no-install-recommends curl && \
     curl -fsSL https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait -o /wait && \
     chmod +x /wait && \
     apt-get purge -y curl && apt-get autoremove -y && \
     rm -rf /var/lib/apt/lists/*'

# Layers Spring Boot : montage via buildah unshare pour accéder au filesystem du conteneur d'extraction
# Ordre des copies : dépendances stables en premier → meilleure réutilisation du cache
EXTRACT_CTR2=$(buildah from "$EXTRACT_IMG")

buildah unshare -- bash -c "
  set -e
  MOUNT=\$(buildah mount '$EXTRACT_CTR2')
  echo 'Extraction montée sur : '\$MOUNT
  buildah copy '$RUNTIME_CTR' \"\$MOUNT/workspace/extracted/dependencies/\"         /app/
  buildah copy '$RUNTIME_CTR' \"\$MOUNT/workspace/extracted/snapshot-dependencies/\" /app/
  buildah copy '$RUNTIME_CTR' \"\$MOUNT/workspace/extracted/spring-boot-loader/\"    /app/
  buildah copy '$RUNTIME_CTR' \"\$MOUNT/workspace/extracted/application/\"           /app/
  buildah unmount '$EXTRACT_CTR2'
"

buildah rm "$EXTRACT_CTR2"
buildah rmi "$EXTRACT_IMG"

# Layer : script de démarrage
buildah copy "$RUNTIME_CTR" "$FULL_SERVICE_PATH/startup.sh" /startup.sh
buildah run "$RUNTIME_CTR" -- chmod +x /startup.sh

# Layer : utilisateur non-root (principe du moindre privilège)
buildah run "$RUNTIME_CTR" -- sh -c \
    'groupadd -r appgroup && useradd -r -g appgroup appuser && chown -R appuser:appgroup /app'
buildah config --user appuser "$RUNTIME_CTR"

# Métadonnées réseau et point d'entrée
buildah config --port "$SERVICE_PORT" "$RUNTIME_CTR"
buildah config --entrypoint "[\"/bin/sh\", \"-c\", \"/startup.sh\"]" --cmd '' "$RUNTIME_CTR"

# ---------------------------------------------------------------------------
# ÉTAPE 4 : Commit de l'image finale
# ---------------------------------------------------------------------------
echo "[4/4] Commit de l'image $IMAGE_NAME..."

buildah commit "$RUNTIME_CTR" "$IMAGE_NAME"
buildah rm "$RUNTIME_CTR"

echo ""
echo "Image construite avec succès : $IMAGE_NAME"
buildah images | grep "${IMAGE_NAME%%:*}"
