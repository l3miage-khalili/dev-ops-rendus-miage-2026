# Depôt Configuration Prometheus
Ce projet contient les fichiers de configuration du service de Health Checking Prometheus

## References
* Documentation v1.0
* Projet v7.0

## Elements de configuration
Le fichier prometheus.yml (au format YML)  configure Prometheus pour la surveillance de 3 entités :
* Le service prometheus lui-même
* Le service d'Annuaire <b>situé sur le même sous-réseau et exposant le port 10001</b>
* Les services déployés sur l'Annuaire par consultation de ce dernier.

## Lancement de Prometheus
docker run -p9090:9090 -v /PATH_COMPLET_VERS/config-prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus


