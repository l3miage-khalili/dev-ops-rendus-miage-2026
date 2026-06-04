# Depôt des Configurations
Ce projet contient les fichiers de confoguration des micro-services pour les services de la banque version micro-services. 
Ces configurations des services doivent être hébergées sur GIT.

## References
* Documentation v1.0
* Projet v7.0

## Fichiers de configuration inclus
* API Gateway
* Service de gestion des comptes Clients
* Service de gestion des comptes bancaires
* Service composite d'association des comptes Clients et comptes bancaires

## Elements inclus
* Annuaire
* Monitoring (dont exposition Prometheus)
* Distributed Tracing (via Zipkin)
* Externalisation de configuration
* Load Balancing

## Elements de configuration
Les fichiers au format YML doivent être nommés selon la configuration du NOM de l'application à configurer.
Ce NOM est concaténé au profil de lancement.
<b>Ici, seuls les profils "dev" sont gérés.</b>

## Notes et remarques
* Il ne peut y avoir de '-' dans le nom des services
* Le fichier de configuration de l'annuaire n'est pas présent. Element central de  l'architecture, il doit être démarré AVANT tout service. Il ne peut donc pas bénéficier du service de configuration.
* Le fichier de configuration du service de configuration n'est pas présent ici pour des raisons évidentes d'impossibilité technique
* <b>Les fichiers de configuration doivent être mis à jour pour un fonctionnement HORS docker-compose</b>