package fr.miage.toulouse.m2.ams.banqueapigateway;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

/**
 * Filtre Zuul pour établir un log lors de chaque requete recue.
 * Le filtre loggue AVANT chaque appel.
 */

@Component
public class LogFilter implements GlobalFilter {
    final Logger logger =
            LoggerFactory.getLogger(LogFilter.class);

    @Override
    public Mono<Void> filter(
            ServerWebExchange exchange,
            GatewayFilterChain chain) {
        logger.info("Called req path:"+exchange.getRequest().getPath()+" params "+exchange.getRequest().getQueryParams());
        return chain.filter(exchange);
    }
}
