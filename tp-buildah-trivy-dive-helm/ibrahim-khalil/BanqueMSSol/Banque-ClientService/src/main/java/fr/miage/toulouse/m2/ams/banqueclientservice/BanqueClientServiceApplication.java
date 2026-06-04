package fr.miage.toulouse.m2.ams.banqueclientservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
// Activation enregistrement Annuaire
@EnableDiscoveryClient
public class BanqueClientServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(BanqueClientServiceApplication.class, args);
    }

}
