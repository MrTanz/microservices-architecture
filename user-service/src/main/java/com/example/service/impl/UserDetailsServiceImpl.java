package com.example.service.impl;

import com.example.dto.UserDetailsDto;
import com.example.entity.UserDetailsEntity;
import com.example.repository.UserDetailsRepository;
import com.example.service.SqsPublisherService;
import com.example.service.UserDetailsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private final Logger logger = LoggerFactory.getLogger(UserDetailsServiceImpl.class);

    @Autowired
    private UserDetailsRepository userDetailsRepository;

    @Autowired
    private SqsPublisherService sqsPublisherService;

    @Override
    public List<UserDetailsDto> getUsersProfile() {
        logger.info("[START SERVICE] - method = getUsersProfile");
        List<UserDetailsEntity> userDetailsEntities = userDetailsRepository.findAll();
        logger.info("[END SERVICE] - method = getUsersProfile");
        return userDetailsEntities.stream().map(userDetailsEntity ->
                        new UserDetailsDto(userDetailsEntity.getUsername(), userDetailsEntity.getName(), userDetailsEntity.getSurname(), userDetailsEntity.getAge()))
                .toList();
    }

    @Override
    public UserDetailsDto getUserProfile(String username) {
        logger.info("[START SERVICE] - method = getUserProfile, username = {}" , username);
        if (Objects.isNull(username) || username.isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        Optional<UserDetailsEntity> userDetailsEntityOptional = userDetailsRepository.findByUsername(username);
        if (userDetailsEntityOptional.isEmpty()) throw new IllegalArgumentException("Username not exists!");
        UserDetailsEntity userDetailsEntity = userDetailsEntityOptional.get();
        logger.info("[END SERVICE] - method = getUserProfile, username = {}" , username);
        return new UserDetailsDto(userDetailsEntity.getUsername(), userDetailsEntity.getName(), userDetailsEntity.getSurname(), userDetailsEntity.getAge());
    }

    @Override
    public void createUserProfile(UserDetailsDto dto) {
        logger.info("[START SERVICE] - method = createUserProfile, username = {}" , dto.getUsername());
        if (Objects.isNull(dto.getUsername()) || dto.getUsername().isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        Optional<UserDetailsEntity> userDetailsEntityOptional = userDetailsRepository.findByUsername(dto.getUsername());
        if (userDetailsEntityOptional.isPresent()) throw new IllegalArgumentException("Username already exists!");
        UserDetailsEntity userDetailsEntity = new UserDetailsEntity(dto.getUsername(), dto.getName(), dto.getSurname(), dto.getAge());
        userDetailsRepository.save(userDetailsEntity);
        logger.info("[END SERVICE] - method = createUserProfile, username = {}" , dto.getUsername());
    }

    @Override
    public void updateUserProfile(UserDetailsDto dto) {
        logger.info("[START SERVICE] - method = updateUserProfile, username = {}" , dto.getUsername());
        if (Objects.isNull(dto.getUsername()) || dto.getUsername().isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        Optional<UserDetailsEntity> userDetailsEntityOptional = userDetailsRepository.findByUsername(dto.getUsername());
        if (userDetailsEntityOptional.isEmpty()) throw new IllegalArgumentException("Username not exists!");
        UserDetailsEntity userDetailsEntity = userDetailsEntityOptional.get();
        userDetailsEntity.setName(dto.getName());
        userDetailsEntity.setSurname(dto.getSurname());
        userDetailsEntity.setAge(dto.getAge());
        userDetailsRepository.save(userDetailsEntity);
        logger.info("[END SERVICE] - method = updateUserProfile, username = {}" , dto.getUsername());
    }

    @Override
    public void deleteUserProfile(String username) {
        logger.info("[START SERVICE] - method = deleteUserProfile, username = {}" , username);
        if (Objects.isNull(username) || username.isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        Optional<UserDetailsEntity> userDetailsEntityOptional = userDetailsRepository.findByUsername(username);
        if (userDetailsEntityOptional.isEmpty()) throw new IllegalArgumentException("Username not exists!");
        sqsPublisherService.publishUserDeleted(username);
        userDetailsRepository.delete(userDetailsEntityOptional.get());
        logger.info("[END SERVICE] - method = deleteUserProfile, username = {}" , username);
    }
}