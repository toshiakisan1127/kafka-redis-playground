package com.example.playground;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;

@SpringBootApplication
@EnableKafka
public class KafkaRedisPlaygroundApplication {

    public static void main(String[] args) {
        SpringApplication.run(KafkaRedisPlaygroundApplication.class, args);
    }
}
