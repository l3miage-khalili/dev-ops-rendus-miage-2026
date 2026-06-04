package fr.toulouse.miage.m2.ams.banquecompositeservice.utilities;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class ClientInconnuException extends Exception{
}
