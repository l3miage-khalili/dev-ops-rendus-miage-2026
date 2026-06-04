package fr.miage.toulouse.m2.ams.banqueannuaire;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication

// Active le serveur d'annuaire Eureka.
@EnableEurekaServer
public class BanqueAnnuaireApplication {

    public static void main(String[] args) {
        SpringApplication.run(BanqueAnnuaireApplication.class, args);
    }

}
