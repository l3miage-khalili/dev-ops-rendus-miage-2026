package fr.miage.toulouse.m2.ams.banquecompteservice.repo;

import fr.miage.toulouse.m2.ams.banquecompteservice.document.Compte;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.List;

/**
 * Repository de gestion des comptes en banque
 */
public interface CompteRepository extends MongoRepository<Compte,Long> {

    List<Compte> findAllByIdclient(Long idclient);
}
