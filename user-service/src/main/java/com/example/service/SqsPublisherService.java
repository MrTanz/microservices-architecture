package com.example.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.Map;

@Service
public class SqsPublisherService {

    private final Logger logger = LoggerFactory.getLogger(SqsPublisherService.class);

    @Value("${aws.sqs.queue-url}")
    private String queueUrl;

    @Autowired
    private SqsClient sqsClient;
    @Autowired
    private ObjectMapper objectMapper;

    public void publishUserDeleted(String username) {
        try {
            logger.info("[START SEND EVENT TO QUEUE] - username = {}", username);

            String message = objectMapper.writeValueAsString(Map.of("username", username));
            SendMessageRequest request = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(message)
                    .build();
            sqsClient.sendMessage(request);

            logger.info("[END SEND EVENT TO QUEUE] - username = {}", username);
        } catch (Exception e) {
            logger.error("[ERROR SEND EVENT TO QUEUE] - username = {}, error = {}", username, e.getMessage());
            throw new RuntimeException("Error in send event of delete user to queue!");
        }
    }
}
