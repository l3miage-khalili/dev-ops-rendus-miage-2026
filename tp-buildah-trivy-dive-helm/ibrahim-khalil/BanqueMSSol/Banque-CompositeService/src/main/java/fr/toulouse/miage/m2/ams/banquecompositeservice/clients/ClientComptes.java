package fr.toulouse.miage.m2.ams.banquecompositeservice.clients;

import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.Compte;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// Création d'un client REST pour le service "comptes-service" enregistré dans l'annuaire
@FeignClient("comptesservice")
public interface ClientComptes {

    // Déclaration d'usage d'une méthode
    // Pour info, conformement au comptes-service (et pour varier), ici on utilise un RequestParam
    /*
        UPDATE API GATEWAY
        @RequestMapping(method = RequestMethod.GET, value = "/api/comptes", produces = "application/json")        Modif URL pour enlever le /api/clients
     */
    @RequestMapping(method = RequestMethod.GET, value = "/", produces = "application/json")
    List<Compte> getComptes(@RequestParam("client") Long id);

    @RequestMapping(method = RequestMethod.POST, value = "/", produces = "application/json")
    Compte postCompte(@RequestBody Compte compte);

}
