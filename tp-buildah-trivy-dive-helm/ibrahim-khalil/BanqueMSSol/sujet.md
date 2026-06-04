# TP – Buildah, Trivy, Dive & Helm/Kubernetes – MIAGE Bank

## Outils requis

Les outils suivants doivent être installés et opérationnels sur votre poste avant de commencer :

| Outil | Usage dans ce TP | Documentation officielle |
|---|---|---|
| Buildah | Build d'images OCI sans démon Docker | |
| Trivy | Scan de sécurité des images | |
| Dive | Audit des layers d'image | |
| Helm | Packaging et déploiement Kubernetes | |
| kubectl | Interaction avec le cluster Kubernetes | |
| ArgoCD CLI | GitOps — déploiement et suivi | |
| Git + GitHub | Versioning et rendu via Pull Request | |
| GitHub Actions | Pipeline CI/CD (obligatoire pour le bonus) | |

---

## Contexte

Ce TP s'inscrit dans la continuité du cours Kubernetes. Il est divisé en deux parties, chacune donnant lieu à une évaluation distincte. L'application cible est **MIAGE-Bank**, le projet fil rouge du cours.

---

## Partie A — Chaîne de build OCI avec Buildah, Trivy et Dive

### Objectifs

- Construire des images OCI en utilisant Buildah
- Analyser la sécurité des images avec Trivy
- Auditer la taille et les layers avec Dive
- Scanner la conformité de votre image via Hadolint
- Intégrer ces outils dans une chaîne de build reproductible pour MIAGE-Bank

---

### 1. Analyse comparative Docker vs Buildah

Rédigez une section d'analyse (dans votre README ou dans un document dédié) expliquant les différences fondamentales entre Docker et Buildah. Votre analyse doit couvrir :

- **Architecture** : modèle démon vs daemonless, exécution en espace utilisateur
- **Sécurité** : surface d'attaque, accès au socket Unix, escalade de privilèges
- **Conformité OCI** : compatibilité avec Docker, Podman et tout runtime OCI
- **Cas d'usage CI/CD** : pertinence dans des environnements rootless (runners GitLab, pipelines Kubernetes)

> **Attendu** : Cette analyse doit figurer dans votre livrable. Elle sera évaluée sur la précision technique et la capacité à argumenter un choix technologique.

---

### 2. Build de MIAGE-Bank avec Buildah

Constituez l'image OCI de MIAGE-Bank en utilisant **exclusivement Buildah**. Deux approches doivent être documentées et comparées:

1. **Via un Containerfile** (équivalent Dockerfile) — image de base adaptée à l'application, JAR MIAGE-Bank copié, port applicatif exposé
2. **Construction layer par layer en mode natif Buildah** — même résultat, sans Containerfile

Comparez les résultats des deux approches et commentez les différences éventuelles.

---

### 3. Scan de sécurité avec Trivy

Effectuez une analyse de sécurité complète de l'image construite :

- Scan de l'image locale
- Filtrage sur les sévérités `HIGH` et `CRITICAL`
- Export du rapport au format JSON
- Export au format SARIF (compatible GitHub Security)

**Livrables attendus :**

- Rapport Trivy complet (JSON ou table)
- Liste des CVE identifiées
- Pour chaque CVE HIGH/CRITICAL : explication de la vulnérabilité et plan de remédiation s'il existe
- Si votre image n'arrive pas à passer cette gate, vous pouvez baisser le niveau de sécurité attendu, mais vous devez l'indiquer dans votre rendu.

---

### 4. Audit de l'image avec Dive

Inspectez le contenu de chaque layer de l'image et identifiez les fichiers superflus.

Configurez et exécutez Dive en mode CI avec les seuils d'efficacité suivants :

- Efficacité minimale : **95%**
- Espace gaspillé maximum : **20 Mo**
- Pourcentage d'espace gaspillé maximum : **10%**

**Livrables attendus :**

- Capture d'écran ou export de l'analyse Dive
- Taille de chaque layer et taille totale
- Identification des fichiers ou répertoires superflus
- Proposition d'optimisation (multi-stage build si applicable, suppression de cache, etc.)
- Un avant/après est une bonne approche
- Si votre image n'arrive pas à passer cette gate, vous pouvez baisser le niveau de sécurité attendu, mais vous devez l'indiquer dans votre rendu.

---

### 5. Script de build intégré

Assemblez les étapes précédentes dans un script / une chaîne CI sur GitHub Actions reproductible qui :

- Construit l'image via Buildah
- Lance le scan Trivy et génère le rapport JSON
- **Interrompt le build** si des CVE CRITICAL sont détectées
- Lance l'analyse Dive en mode CI
- Produit les rapports dans un répertoire `build-reports/`
- Exporte les rapports depuis `build-reports/` ou les place à un endroit où ils peuvent être lus
- Si votre image n'arrive pas à passer cette gate, vous pouvez baisser le niveau de sécurité attendu, mais vous devez l'indiquer dans votre rendu.

> **Attendu** : Le script doit être intégré au dépôt Git et s'exécuter sans erreur. La pipeline GitHub Actions est un **bonus évalué**. Elle doit inclure au minimum les étapes suivantes : lint du Containerfile avec Hadolint, build Buildah, scan Trivy et audit Dive.

---

### Livrables — Partie A

- [ ] Analyse comparative Docker vs Buildah (rédigée, argumentée)
- [ ] Containerfile optimisé pour MIAGE-Bank
- [ ] Script de build / GitHub Actions fonctionnel
- [ ] Rapport Trivy (JSON) avec plan de remédiation
- [ ] Rapport Dive avec analyse des layers et optimisations proposées
- [ ] README documentant la démarche et comment exécuter la chaîne

---

## Partie B — Packaging Helm & Déploiement Kubernetes de MIAGE-Bank

### Objectifs

- Packager MIAGE-Bank sous forme d'un chart Helm
- Déployer l'application dans Kubernetes avec l'ensemble des mécanismes vus en cours
- Mettre en place une gestion sécurisée des secrets via Vault et External Secrets Operator
- Exposer l'application via un Ingress Traefik / ou `minikube tunnel`
- Configurer le GitOps via ArgoCD pour chacune des applications *(attention à l'œuf ou la poule — si pas possible, expliquez)*

---

### 1. Chart Helm pour MIAGE-Bank

Créez un chart Helm pour MIAGE-Bank respectant la structure suivante :

```
miage-bank/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── namespace.yaml
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── networkpolicy.yaml
    └── serviceaccount.yaml
```

#### Exigences du chart

**Deployment**

- Image buildée en Partie A *(registry Harbor si déployé, sinon image locale ou via la registry GitHub)*
    - `readinessProbe` et `livenessProbe` configurées
    - `resources.requests` et `resources.limits` définis
    - `serviceAccountName` dédié

**Service** — Type `ClusterIP` uniquement *(exposition externe via Ingress)*

**Ingress** — Classe `traefik`, hostname paramétrable via `values.yaml`, TLS optionnel *(bonus)*

**NetworkPolicy** — Default-deny en ingress sur le namespace, autorisation uniquement depuis le controller Traefik / minikube

**RBAC** — ServiceAccount dédié, Role et RoleBinding minimalistes *(least privilege)*

#### Gestion des secrets

Les credentials de MIAGE-Bank (base de données, secrets applicatifs) **ne doivent pas figurer en clair dans `values.yaml`**. Deux approches sont acceptées :

1. **Vault + External Secrets Operator** *(approche recommandée, vue en TP12/TP13)*
2. Secret Kubernetes natif avec `stringData` créé séparément du chart et référencé par nom — *perte de points associée*

> **Validation attendue du chart avant déploiement :** `helm lint`, `helm template` et `helm install --dry-run`.

---

### 2. Déploiement dans Kubernetes

Déployez le chart dans un namespace dédié `miage-bank` et validez :

- L'application est accessible via l'Ingress
- Les NetworkPolicies sont actives
- Les secrets ne sont pas exposés en clair

---

### 3. GitOps avec ArgoCD

Versionnez votre chart dans le dépôt Git et déployez-le via une **Application ArgoCD** ciblant la branche `main` avec synchronisation automatique (`prune: true`, `selfHeal: true`).

**Exercice de dérive :**

1. Modifiez manuellement un paramètre de l'application (ex : nombre de réplicas)
2. Observez qu'ArgoCD détecte le statut `OutOfSync`
3. Observez ou déclenchez la réconciliation
4. Documentez cette démonstration dans votre README

---

### Livrables — Partie B

- [ ] Chart Helm complet et fonctionnel dans le dépôt Git
- [ ] `values.yaml` et `values-prod.yaml` documentés
- [ ] Application ArgoCD déployée et synchronisée
- [ ] Secrets gérés via Vault + ESO ou Secret Kubernetes séparé du chart
- [ ] NetworkPolicy en place et validée
- [ ] Ingress exposant MIAGE-Bank
- [ ] README décrivant le déploiement de bout en bout
- [ ] Démonstration de la dérive ArgoCD et de la réconciliation