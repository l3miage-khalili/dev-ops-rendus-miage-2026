package fr.toulouse.miage.m2.ams.banquecompositeservice.metier;

import feign.FeignException;
import fr.toulouse.miage.m2.ams.banquecompositeservice.clients.ClientClients;
import fr.toulouse.miage.m2.ams.banquecompositeservice.clients.ClientComptes;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.Client;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.ClientWithCompte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.Compte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.utilities.ClientInconnuException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.List;

// Composant métier. On aurait pu mettre @Service
@Component
public class ClientsCompteRepositoryImpl implements ClientsCompteRepository {
    Logger logger = LoggerFactory.getLogger(this.getClass());

    private final ClientComptes clientComptes;
    private final ClientClients clientclients;

    public ClientsCompteRepositoryImpl(ClientComptes clientComptes, ClientClients clientclients) {
        this.clientComptes = clientComptes;
        this.clientclients = clientclients;
    }

    // On va interroger successivement les 2 micro-services Client et Comptes
    @Override
    public ClientWithCompte getClientWithComptes(Long idclient) throws ClientInconnuException {
        logger.info("On a 1 demande");
        logger.info("On envoie la demande au service client");

        // On récupère 1 objet client
        Client c= null;
        try {
            c = this.clientclients.getClient(idclient);
        } catch (FeignException.NotFound e) {
            logger.info("404 recu !!! --> on remonte l'exception");
            throw new ClientInconnuException();
        }
        logger.info("On a recue la réponse du service client : {}", c);

        // On récupère la liste des comptes pour 1 client donné
        logger.info("On envoie la demande au service compte");
        List<Compte> cpts = this.clientComptes.getComptes(c.getId());
        logger.info("On a recu la réponse du service comptes : {}", c);

        // On forge la réponse
        ClientWithCompte cwc = new ClientWithCompte();
        cwc.setId(c.getId());
        cwc.setNom(c.getNom());
        cwc.setPrenom(c.getPrenom());
        cwc.setComptes(cpts);
        return cwc;
    }

    @Override
    public Compte creationCompte(Long idclient, Compte compte) throws ClientInconnuException {
        logger.info("On a 1 demande");
        logger.info("On envoie la demande au service client");

        // On récupère 1 objet client
        Client c= null;
        try {
            c = this.clientclients.getClient(idclient);
        } catch (FeignException.NotFound e) {
            logger.info("404 recu !!! --> on remonte l'exception");
            throw new ClientInconnuException();
        }
        logger.info("On a recu la réponse du service client : {}", c);

        // On récupère la liste des comptes pour 1 client donné
        logger.info("On envoie la demande de création au service compte");
        Compte cpt = null;
        try {
            compte.setIdclient(c.getId());
            cpt = clientComptes.postCompte(compte);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        logger.info("On a recue la réponse du service comptes : {}", cpt);
        return cpt;
    }
}
