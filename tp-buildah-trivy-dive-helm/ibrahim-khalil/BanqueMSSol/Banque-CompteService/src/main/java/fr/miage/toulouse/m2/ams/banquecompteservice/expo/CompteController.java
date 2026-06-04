package fr.miage.toulouse.m2.ams.banquecompteservice.expo;

import fr.miage.toulouse.m2.ams.banquecompteservice.document.Compte;
import fr.miage.toulouse.m2.ams.banquecompteservice.repo.CompteRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * Service d'exposition REST des comptes.
 * URL / exposée.
 */
@RestController
/*
    AVANT : @RequestMapping("/api/comptes")
    Modif : plus besoin de /api/comptes via
    l'usage de l'API Gateway qui va masquer le chemin de l'URL
 */
@RequestMapping("/")
public class CompteController {
    Logger logger = LoggerFactory.getLogger(CompteController.class);

    // Injection DAO compte
    @Autowired
    private CompteRepository repo;

    /**
     * GET 1 compte
     * @param compte id du compte
     * @return Compte converti en JSON
     */
    @GetMapping("{id}")
    public Compte getCompte(@PathVariable("id") Compte compte) {
        logger.info("Compte : demande d'un compte avec id:{}", compte.getId());
        return compte;
    }

    /**
     * GET liste des comptes d'un client
     * @return liste des comptes en JSON. [] si aucun compte.
     */
    @GetMapping("")
    public Iterable<Compte> getComptes(@RequestParam("client") String id) {
        long idl = Long.parseLong(id);
        logger.info("Compte : demande des comptes d'un client avec id:{}", id);
        Iterable<Compte> liste = repo.findAllByIdclient(idl);
        logger.info("Compte : demande des comptes d'un client avec id:{}", id);
        return liste;
    }
    
    /**
     * GET liste des comptes
     * @return liste des comptes en JSON. [] si aucun compte.
     */
    @GetMapping("all")
    public Iterable<Compte> getComptes() {
        logger.info("Compte : demande de la liste des comptes");
        return repo.findAll();
    }

    /**
     * POST un compte
     * @param cpt compte à ajouter (import JSON)
     * @return compte ajouté
     */
    @PostMapping("")
    public Compte postClient(@RequestBody Compte cpt) {
        logger.info("Compte : demande CREATION d'un compte avec id:{}", cpt.getId());
        return repo.save(cpt);
    }

}
