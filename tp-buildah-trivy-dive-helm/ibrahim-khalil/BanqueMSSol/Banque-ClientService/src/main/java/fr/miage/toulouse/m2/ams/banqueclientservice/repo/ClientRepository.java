package fr.miage.toulouse.m2.ams.banqueclientservice.repo;

import fr.miage.toulouse.m2.ams.banqueclientservice.entities.Client;
import org.springframework.data.repository.CrudRepository;

/**
 * Repository de gestion des clients de la banque
 */
public interface ClientRepository extends CrudRepository<Client, Long> {
}
