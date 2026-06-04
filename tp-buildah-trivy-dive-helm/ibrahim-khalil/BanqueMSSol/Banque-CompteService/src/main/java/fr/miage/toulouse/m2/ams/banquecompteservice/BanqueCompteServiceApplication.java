package fr.miage.toulouse.m2.ams.banquecompteservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
// Activation enregistrement Annuaire
@EnableDiscoveryClient
public class BanqueCompteServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(BanqueCompteServiceApplication.class, args);
    }

}
