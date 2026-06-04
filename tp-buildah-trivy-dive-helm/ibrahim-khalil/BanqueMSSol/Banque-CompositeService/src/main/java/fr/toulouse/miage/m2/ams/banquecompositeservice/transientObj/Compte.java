package fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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
 * Objet Compte TRANSIENT (utilisé pour la communication uniquement)
 */
public class Compte {
    private long id;
    private double solde;
    private Long idclient;
}
