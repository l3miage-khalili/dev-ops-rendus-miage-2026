package fr.miage.toulouse.m2.ams.banqueconfigserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.config.server.EnableConfigServer;

@SpringBootApplication
// Activation serveur de configuration
@EnableConfigServer
// Activation enregistrement Annuaire
@EnableDiscoveryClient
public class BanqueConfigServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(BanqueConfigServerApplication.class, args);
    }

}
