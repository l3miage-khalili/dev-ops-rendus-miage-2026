# Exercice Banque en Ligne Micro-services
## M2 MIAGE Toulouse - TN - AMS
Ce projet regroupe les éléments de configuration pour un lancement automatisé de l'architecture

## References
* Documentation v1.0
* Projet v7.0

## Environnement
* Spring v2.6.4
* Spring cloud v2021.0.1
* Java 8
* MongoDB
* MySQL
* Prometheus
* Zipkin
* Docker

## Elements d'architecture inclus
* Annuaire
* Monitoring
* Distributed Tracing
* Externalisation de configuration
* Load Balancing

## Structure et nom des répertoires :
La répertoire racine du projet doit être struccturé comme suivant :
(Chaque repertoire dispose de son dépôt GIT)
- Racine du projet (Ce dépôt - (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-generalconfig))
  - [Banque-Annuaire](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-annuaire) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-annuaire)
  - [Banque-APIGateway](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-apigateway) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-apigateway)
  - [Banque-ClientService](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-clientservice) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-clientservice)
  - [Banque-CompteService](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-compteservice) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-compteservice)
  - [Banque-CompositeService](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-compositeservice) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-compositeservice)
  - [Banque-ConfigServer](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-configserver) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-configserver)
  - [Banque-configs](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-config) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-config)
  - [config-prometheus](https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-configprometheus) (https://bitbucket.org/CTeyssie/miage-m2-ams-microbanque-configprometheus)

## Construction et lancement
Via docker-compose :
1. docker-compose build
2. docker-compose up.<br>
   Les services lancés sont (ordre non garanti ci-dessous) :
   1. MySQL
   2. MongoDB
   3. Annuaire
   4. Server de configuration
   5. Service Client
   6. Service Comptes
   7. Service ClientCompte
   8. API Gateway
   9. Prometheus
   10. Zipkin
