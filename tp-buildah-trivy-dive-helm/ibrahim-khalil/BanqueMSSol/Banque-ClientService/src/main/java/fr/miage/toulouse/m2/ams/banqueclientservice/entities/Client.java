package fr.miage.toulouse.m2.ams.banqueclientservice.entities;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import javax.persistence.Entity;
import javax.persistence.Id;

// Utilisation de lombok pour générer constructeurs, getters...
// on veut le constructeur avec TOUS les attributs
@AllArgsConstructor
// on veut le constructeur SANS argument
@NoArgsConstructor
// on veut les setters pour TOUS les attributs
@Setter
// on veut les getters pour TOUS les attributs
@Getter
/**
 * Objet métier Client
 */
@Entity
public class Client {
    @Id
    private long id;

    private String nom;

    private String prenom;

}
