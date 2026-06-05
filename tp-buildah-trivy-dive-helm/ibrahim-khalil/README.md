# nom et prénoms: Ibrahim Goukouni KHALIL

# MIAGE-Bank — Buildah · Trivy · Dive · Helm · Kubernetes

Ce dépôt contient l'application micro-services MIAGE-Bank ainsi que la chaîne de build OCI
réalisée dans le cadre du TP DevOps (Buildah · Trivy · Dive · Helm · Kubernetes).

L'analyse détaillée (résultats, CVE, mesures Dive, comparaisons) est dans
[compte-rendu.md](compte-rendu.md).

---

## Prérequis

| Outil | Version testée | Installation |
|---|---|---|
| Buildah | 1.33.7 | `sudo apt-get install buildah` |
| Trivy | 0.70.0 | [aquasecurity/trivy](https://github.com/aquasecurity/trivy/releases) |
| Dive | 0.12.0 | [wagoodman/dive](https://github.com/wagoodman/dive/releases) |
| Hadolint | — | [hadolint/hadolint](https://github.com/hadolint/hadolint/releases) (optionnel) |
| Helm | 3.x | `sudo snap install helm --classic` |
| kubectl | 1.29+ | `sudo snap install kubectl --classic` |
| minikube | 1.32+ | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |

> Les images de base sont tirées de `docker.io`. Buildah doit pouvoir résoudre les noms
> pleinement qualifiés (`docker.io/library/...`). Vérifiez `/etc/containers/registries.conf`
> si vous obtenez une erreur `short-name`.

---

## Structure du dépôt

```
ibrahim-khalil/
├── README.md                      # Ce fichier
├── compte-rendu.md                # Rapport d'analyse complet
└── BanqueMSSol/
    ├── Banque-Annuaire/
    │   ├── Containerfile              # Dockerfile original (référence)
    │   └── Containerfile.optimized    # Build optimisé (utilisé par build.sh)
    ├── Banque-ConfigServer/           # idem
    ├── Banque-ClientService/          # idem
    ├── Banque-CompteService/          # idem
    ├── Banque-CompositeService/       # idem
    ├── Banque-APIGateway/             # idem
    ├── scripts/
    │   ├── build.sh                   # Chaîne de build intégrée (Q5)
    │   └── buildah-native.sh          # Build layer-par-layer sans Containerfile (Q2)
    ├── build-reports/                 # Rapports générés (Trivy JSON/SARIF, Dive CI)
    ├── helm/miage-bank/               # Chart Helm (Partie B)
    ├── argocd/
    │   └── application.yaml           # Manifest ArgoCD (GitOps Q3)
    └── .dive-ci.yml                   # Seuils Dive CI
```

---

## Builder une image avec Buildah

### Approche 1 — Containerfile (recommandée)

```bash
# Depuis la racine du dépôt
buildah bud \
  --tag banque-clientservice:7.0 \
  -f Banque-ClientService/Containerfile.optimized \
  Banque-ClientService/
```

Remplacer `Banque-ClientService` / `banque-clientservice` / `7.0` selon le service voulu :

| Service | Tag | Port |
|---|---|---|
| Banque-Annuaire | `banque-annuaire:7.0` | 10001 |
| Banque-ConfigServer | `banque-configserver:7.0` | 10003 |
| Banque-ClientService | `banque-clientservice:7.0` | 10011 |
| Banque-CompteService | `banque-compteservice:7.0` | 10021 |
| Banque-CompositeService | `banque-compositeservice:7.0` | 10031 |
| Banque-APIGateway | `banque-apigateway:7.0` | 10000 |

### Approche 2 — Buildah natif (sans Containerfile)

```bash
./scripts/buildah-native.sh Banque-ClientService banque-clientservice:7.0 10011
```

---

## Lancer la chaîne de build intégrée (build.sh)

```bash
# Build complet avec gate CRITICAL (s'arrête si CVE CRITICAL détectées)
./scripts/build.sh Banque-ClientService banque-clientservice:7.0 10011

# Avec gate CRITICAL désactivée (⚠ à documenter — voir compte-rendu.md)
./scripts/build.sh --skip-critical-gate Banque-ClientService banque-clientservice:7.0 10011

# Cibler le Containerfile non optimisé
./scripts/build.sh --containerfile Containerfile Banque-Annuaire banque-annuaire:7.0 10001
```

**Étapes exécutées :**

```
1/6  Hadolint   — lint du Containerfile
2/6  Buildah    — build de l'image OCI
3/6  Export     — archive tar pour les scanners
4/6  Trivy      — rapport JSON + SARIF + table HIGH/CRITICAL
5/6  Gate       — interruption si CVE CRITICAL > 0
6/6  Dive CI    — audit des layers (.dive-ci.yml)
```

**Rapports produits dans `build-reports/` :**

```
banque-clientservice-7.0.tar
trivy-banque-clientservice-7.0-full.json
trivy-banque-clientservice-7.0.sarif
trivy-banque-clientservice-7.0-high-critical.txt
dive-banque-clientservice-7.0-ci.txt
hadolint-banque-clientservice-7.0.txt
```

---

## Scan Trivy seul

```bash
# Export de l'image
buildah push banque-clientservice:7.0 \
  docker-archive:build-reports/banque-clientservice-7.0.tar

# Scan complet (JSON)
trivy image --format json \
  --output build-reports/trivy-clientservice-full.json \
  --input build-reports/banque-clientservice-7.0.tar

# Filtrage HIGH et CRITICAL
trivy image --severity HIGH,CRITICAL \
  --format table \
  --input build-reports/banque-clientservice-7.0.tar
```

---

## Audit Dive seul

```bash
# Mode CI avec les seuils du projet
CI=true dive --source docker-archive \
  --ci-config .dive-ci.yml \
  build-reports/banque-clientservice-7.0.tar
```

Seuils configurés dans `.dive-ci.yml` :

```yaml
rules:
  lowestEfficiency: 0.95        # efficacité minimale : 95 %
  highestWastedBytes: 20000000  # espace gaspillé max : 20 Mo
  highestUserWastedPercent: 0.10
```

---

## Pipeline GitHub Actions

Le workflow `.github/workflows/build-ibrahim-khalil.yml` (à la racine du dépôt) s'exécute sur `push`/`pull_request` vers `main`
et enchaîne pour chacun des 6 services :

1. **Lint** — Hadolint avec upload SARIF vers GitHub Security
2. **Build** — `buildah bud`
3. **Scan** — Trivy avec upload SARIF vers GitHub Security
4. **Gate** — avertissement si CVE CRITICAL (commenté pour le TP)
5. **Audit** — Dive CI
6. **Push** — vers GHCR sur la branche `main`

---

## Déploiement Kubernetes (Partie B)

Le chart Helm se trouve dans `helm/miage-bank/`. Il déploie les 6 services Spring Boot,
MySQL, MongoDB, l'Ingress Traefik et les secrets via Vault + External Secrets Operator.

### 1. Charger les images dans minikube

```bash
for svc in annuaire configserver clientservice compteservice compositeservice apigateway; do
  minikube image load localhost/banque-${svc}:7.0
done
```

### 2. Installer les dépendances cluster

```bash
# Traefik (IngressClass "traefik")
helm repo add traefik https://helm.traefik.io/traefik
helm install traefik traefik/traefik --namespace traefik-system --create-namespace \
  --set service.type=NodePort

# Vault (mode dev — token root = "root")
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --namespace vault --create-namespace \
  --set server.dev.enabled=true --set server.dev.devRootToken=root

# External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace
```

### 3. Configurer Vault

```bash
# Se connecter au pod Vault
kubectl exec -it vault-0 -n vault -- vault login root

# Activer l'auth Kubernetes
kubectl exec -it vault-0 -n vault -- vault auth enable kubernetes
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc"

# Écrire les secrets
kubectl exec -it vault-0 -n vault -- vault kv put secret/miage-bank/mysql \
  username=root password=rootpassword
kubectl exec -it vault-0 -n vault -- vault kv put secret/miage-bank/mongodb \
  username=root password=rootpassword
kubectl exec -it vault-0 -n vault -- vault kv put secret/miage-bank/git \
  username=<git-user> password=<git-token>

# Policy + rôle Kubernetes
kubectl exec -it vault-0 -n vault -- vault policy write miage-bank - <<'EOF'
path "secret/data/miage-bank/*" { capabilities = ["read"] }
EOF

kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/role/miage-bank \
  bound_service_account_names=miage-bank-sa \
  bound_service_account_namespaces=miage-bank \
  policies=miage-bank ttl=24h
```

### 4. Déployer le chart

```bash
helm install miage-bank helm/miage-bank/ \
  --create-namespace \
  --set vault.enabled=true \
  --set nativeSecrets.enabled=false \
  --set networkPolicy.ingressControllerNamespace=traefik-system
```

Vérification :

```bash
kubectl get pods -n miage-bank
# Attendre que tous les pods soient 1/1 Running (environ 5 minutes)

kubectl get externalsecret -n miage-bank
# STATUS: SecretSynced pour les 3 secrets
```

### 5. Accéder à l'application

```bash
# Obtenir le NodePort Traefik
kubectl get svc traefik -n traefik-system
# → PORT(S): 80:<nodeport>/TCP

# Ajouter l'entrée hosts (remplacer <nodeport> et l'IP minikube)
echo "$(minikube ip) miage-bank.local" | sudo tee -a /etc/hosts

# Test de santé via l'Ingress
curl -H "Host: miage-bank.local" http://$(minikube ip):<nodeport>/actuator/health
# {"status":"UP","groups":["liveness","readiness"]}
```

---

## GitOps avec ArgoCD (Partie B — Question 3)

### 1. Installer ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exposer l'UI en NodePort
kubectl patch svc argocd-server -n argocd \
  -p '{"spec":{"type":"NodePort"}}'

# Mot de passe admin initial
kubectl get secret argocd-initial-admin-secret \
  -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### 2. Déployer l'Application ArgoCD

> **Prérequis** : Vault et ESO doivent être configurés avant cette étape
> (voir section "Configurer Vault" ci-dessus).

```bash
# Désinstaller le déploiement Helm manuel si existant
helm uninstall miage-bank -n miage-bank

# Appliquer le manifest ArgoCD (versionné dans argocd/application.yaml)
kubectl apply -f argocd/application.yaml
```

ArgoCD surveille la branche `main` du dépôt et synchronise automatiquement le chart
`helm/miage-bank/` avec `prune: true` et `selfHeal: true`.

```bash
# Vérifier la synchronisation
kubectl get application miage-bank -n argocd
# NAME         SYNC STATUS   HEALTH STATUS
# miage-bank   Synced        Healthy
```

### 3. Démonstration de la dérive

```bash
# 1. Introduire une dérive manuelle
kubectl scale deployment banque-clientservice --replicas=2 -n miage-bank

# 2. Constater OutOfSync (quasi-immédiat via webhook, ~13 secondes)
kubectl get application miage-bank -n argocd
# NAME         SYNC STATUS   HEALTH STATUS
# miage-bank   OutOfSync     Progressing

# 3. ArgoCD réconcilie automatiquement (selfHeal: true) en ~13 secondes
# → replicas revient à 1, pod surnuméraire supprimé (prune: true)
kubectl get application miage-bank -n argocd
# NAME         SYNC STATUS   HEALTH STATUS
# miage-bank   Synced        Healthy
```

---

### Notes sur la configuration Spring Boot

Plusieurs services nécessitent des surcharges pour fonctionner en K8s (noms DNS Docker Compose
vers Services K8s, conflits de configuration Spring Boot 2.6.4). Ces workarounds sont déjà
intégrés dans `values.yaml` — aucune intervention manuelle requise :

| Service | Problème | Workaround dans values.yaml |
|---|---|---|
| `banque-compteservice` | `IllegalStateException` Spring Boot si `uri` et `host/credentials` coexistent | `SPRING_CONFIG_IMPORT` absent → `uri=null` ; config MongoDB via `SPRING_APPLICATION_JSON` |
| `banque-apigateway` | Config-server impose `server.port=10050`, probe K8s attend 10000 | `SPRING_APPLICATION_JSON: '{"server":{"port":10000}}'` |
| Tous (sauf annuaire) | Eureka pointe vers `bnkannuaire` (Docker Compose) | `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE` dans le ConfigMap |
