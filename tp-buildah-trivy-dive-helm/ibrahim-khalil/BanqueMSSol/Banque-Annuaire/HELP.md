# Micro-service Edge Banque Annuaire
Ce micro-service Edge est un serveur d'annuaire pour les services de la banque version micro-services.

## References
* Documentation v1.0
* Projet v7.0

## Environnement
* Spring v2.6.4
* Spring cloud v2021.0.1
  * plus io.micrometer/micrometer-registry-prometheus
* Java 8

## Elements d'architecture inclus
* Annuaire
* Monitoring (dont exposition Prometheus)

## Elements de configuration
Ce micro-service lance le serveur Eureka avec les éléments de confguration suivants :
* Port 10001
* Niveau de Log sur INFO

## Construction et lancement
<b>Sans docker-compose, on va passer par l'hôte pour interonnecter les conteneurs</b>
* Pour construire une image docker :
  * docker build -t banque-annuaire:7.0
* Pour lancer l'image docker :
  * docker run --name bnkannuaire -p 10001:10001 banque-annuaire:7.0