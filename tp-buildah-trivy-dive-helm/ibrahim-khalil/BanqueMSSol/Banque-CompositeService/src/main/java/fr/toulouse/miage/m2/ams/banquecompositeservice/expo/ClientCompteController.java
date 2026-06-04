package fr.toulouse.miage.m2.ams.banquecompositeservice.expo;

import fr.toulouse.miage.m2.ams.banquecompositeservice.metier.ClientsCompteRepository;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.ClientWithCompte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.Compte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.utilities.ClientInconnuException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

/**
 * Service d'exposition REST des comptes-clients.
 * URL / exposée.
 */
@RestController()
/*
    AVANT : @RequestMapping("/api/clientscompte")
    Modif : plus besoin de /api/clientscompte via
    l'usage de l'API Gateway qui va masquer le chemin de l'URL
 */
@RequestMapping("/")
public class ClientCompteController {
    Logger logger = LoggerFactory.getLogger(this.getClass());

    // Injection DAO clients-compte
    ClientsCompteRepository clientsCompteRepository;

    public ClientCompteController(ClientsCompteRepository clientsCompteRepository) {
        this.clientsCompteRepository = clientsCompteRepository;
    }

    /**
     * GET 1 client AVEC la liste de ses comptes
     * @param id id du client
     * @return  converti en JSON
     */
    @GetMapping("{id}")
    public ClientWithCompte getCompteClient(@PathVariable("id") Long id) throws ClientInconnuException {
        logger.info("ClientComptes : demande récup comptes d'un client avec id:{}", id);
        ClientWithCompte c = clientsCompteRepository.getClientWithComptes(id);
        logger.info("ClientComptes : demande done récup comptes client:{}", c);
        return c;
    }

    /**
     * POST un compte
     */
    @PostMapping("{id}")
    public Compte postCompteClient(@PathVariable("id") Long id, @RequestBody Compte cpt) throws ClientInconnuException {
        logger.info("ClientComptes : demande ajout 1 compte pour un client avec id:{}", id);
        Compte cwc = this.clientsCompteRepository.creationCompte(id, cpt);
        logger.info("ClientComptes : demande done ajout 1 compte pour un client avec id:{}", cpt);
        return cwc;
    }

}
