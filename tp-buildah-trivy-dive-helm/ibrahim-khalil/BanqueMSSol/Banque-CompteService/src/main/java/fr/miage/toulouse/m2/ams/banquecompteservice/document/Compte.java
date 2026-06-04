package fr.miage.toulouse.m2.ams.banquecompteservice.document;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;


// Utilisation de lombok pour générer constructeurs, getters...
// on veut le constrcteur avec TOUS les attributs
@AllArgsConstructor
// on veut le constrcteur SANS argument
@NoArgsConstructor
// on veut les setters pour TOUS les attributs
@Setter
// on veut les getters pour TOUS les attributs
@Getter
/**
 * Objet métier Compte
 */
@Document(collection = "comptes")
public class Compte {
    @Id
    private Long id;

    @Field
    private double solde;

    // Pas de relation SQL ici. Le micro-service compte ne gere QUE les comptes.
    @Field
    private Long idclient;
}
