package fr.miage.toulouse.m2.ams.banqueapigateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
// Activation enregistrement Annuaire
@EnableDiscoveryClient
public class BanqueApiGatewayApplication {

	public static void main(String[] args) {
		SpringApplication.run(BanqueApiGatewayApplication.class, args);
	}

}
