package fr.toulouse.miage.m2.ams.banquecompositeservice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.loadbalancer.annotation.LoadBalancerClients;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
// Activation enregistrement Annuaire
@EnableDiscoveryClient
// Activation et auto-confoguiration de clients Feign
@EnableFeignClients
// Activation LoadBalancer avec politique par défaut
@LoadBalancerClients
public class BanqueCompositeServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(BanqueCompositeServiceApplication.class, args);
    }

}
