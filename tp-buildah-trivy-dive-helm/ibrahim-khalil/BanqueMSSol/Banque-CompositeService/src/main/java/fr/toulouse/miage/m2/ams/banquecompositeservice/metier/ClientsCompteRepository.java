package fr.toulouse.miage.m2.ams.banquecompositeservice.metier;

import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.ClientWithCompte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj.Compte;
import fr.toulouse.miage.m2.ams.banquecompositeservice.utilities.ClientInconnuException;

/**
 * Repository de manipulation des ClientsCompte
 */
public interface ClientsCompteRepository {

    ClientWithCompte getClientWithComptes(Long idclient) throws ClientInconnuException;

    Compte creationCompte(Long idclient, Compte compte) throws ClientInconnuException;

}
