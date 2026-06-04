package fr.toulouse.miage.m2.ams.banquecompositeservice.transientObj;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

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
 * Objet Client TRANSIENT (utilisé pour la communication uniquement) embarquant une liste de comptes
 */
public class ClientWithCompte extends Client {
    private List<Compte> comptes;

    public ClientWithCompte(Client c, List<Compte> comptes) {
        super(c.getId(), c.getNom(), c.getPrenom());
        this.comptes = comptes;
    }
}
