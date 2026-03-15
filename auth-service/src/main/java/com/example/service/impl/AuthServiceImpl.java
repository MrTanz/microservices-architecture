package com.example.service.impl;

import com.example.dto.*;
import com.example.entity.RoleEntity;
import com.example.entity.UserEntity;
import com.example.enums.ChangeRoleOperationType;
import com.example.enums.Role;
import com.example.expection.ResourceNotFoundException;
import com.example.model.GenericResponse;
import com.example.repository.UserRepository;
import com.example.service.AuthService;
import com.example.service.RoleService;
import com.example.util.JwtUtil;
import com.example.util.PasswordUtil;
import com.example.util.Utils;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;

@Service
public class AuthServiceImpl implements AuthService {

    private final Logger logger = LoggerFactory.getLogger(AuthServiceImpl.class);
    private final String INTERNAL_API_KEY_HEADER = "internal-api-key";

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleService roleService;
    @Autowired
    private JwtUtil jwtUtil;
    @Autowired
    private RestTemplate restTemplate;

    @Value("${security.internal-api-key}")
    private String internalApiKey;
    @Value("${user-service-url}")
    private String userServiceUrl;

    @Override
    public LoginResponseDto login(LoginRequestDto dto) throws RuntimeException, NoSuchAlgorithmException, InvalidKeySpecException {
        logger.info("[START SERVICE] - method = login, username = {}" , dto.getUsername());
        if (Objects.isNull(dto.getUsername()) || dto.getUsername().isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        if (Objects.isNull(dto.getPassword()) || dto.getPassword().isEmpty())
            throw new IllegalArgumentException("Password is mandatory!");

        Optional<UserEntity> userEntityOptional = userRepository.findByUsername(dto.getUsername());
        if (userEntityOptional.isEmpty()) throw new ResourceNotFoundException("Username not exists!");
        UserEntity userEntity = userEntityOptional.get();

        boolean isSamePassword = PasswordUtil.verifyPassword(dto.getPassword().toCharArray(), userEntity.getPassword());
        if (!isSamePassword) throw new IllegalArgumentException("Credentials are wrong!");

        List<String> roles = userEntity.getRoles().stream().map(RoleEntity::getRole).toList();

        var newTokenVersion = userEntity.getTokenVersion() + 1;

        String jwtToken = jwtUtil.generateToken(userEntity.getUsername(), newTokenVersion, roles);
        userEntity.setTokenVersion(newTokenVersion);
        userRepository.save(userEntity);
        logger.info("[END SERVICE] - method = login, username = {}" , dto.getUsername());
        return new LoginResponseDto(jwtToken);
    }

    @Override
    public GenericResponse signUp(SignUpRequestDto dto) throws RuntimeException, NoSuchAlgorithmException, InvalidKeySpecException {
        logger.info("[START SERVICE] - method = signUp, username = {}" , dto.getUsername());
        if (Objects.isNull(dto.getUsername()) || dto.getUsername().isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        if (Objects.isNull(dto.getPassword()) || dto.getPassword().isEmpty())
            throw new IllegalArgumentException("Password is mandatory!");
        if (!Utils.isValidEmail(dto.getUsername())) {
            throw new IllegalArgumentException("Username is not a valid email!");
        }

        Optional<UserEntity> userEntityOptional = userRepository.findByUsername(dto.getUsername());
        if (userEntityOptional.isPresent()) throw new IllegalArgumentException("Username already exists!");

        Optional<RoleEntity> defaultRoleOptional = roleService.getRoleByName(Role.USER);
        if (defaultRoleOptional.isEmpty()) throw new RuntimeException("Role of type USER is not configured!");
        RoleEntity defaultRole = defaultRoleOptional.get();

        // Salvataggio dettaglio utente tramite lo user-service
        try {
            logger.info("[START - SERVICE] - method = signUp, call user service");
            HttpHeaders headers = new HttpHeaders();
            headers.set(INTERNAL_API_KEY_HEADER, internalApiKey);
            headers.setContentType(MediaType.APPLICATION_JSON);

            CreateUserDetailsRequestDto request = new CreateUserDetailsRequestDto(dto.getUsername(), dto.getName(), dto.getSurname(), dto.getAge());

            HttpEntity<CreateUserDetailsRequestDto> entity = new HttpEntity<>(request, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    userServiceUrl + "/users/profile",
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            logger.info("[END - SERVICE] - method = signUp, call user service, status = {}, response = {}", response.getStatusCode(), response.getBody());

            if(response.getStatusCode().equals(HttpStatusCode.valueOf(201))){
                String passwordHashed = PasswordUtil.hashPassword(dto.getPassword().toCharArray(), PasswordUtil.getSalt());
                UserEntity userToCreate = new UserEntity(dto.getUsername(), passwordHashed, 0, Set.of(defaultRole));
                userRepository.save(userToCreate);

                logger.info("[END SERVICE] - method = signUp, username = {}" , dto.getUsername());
                return new GenericResponse("User created successfully!");
            }

            throw new RuntimeException("Error in create user details!");
        } catch (RestClientException e) {
            logger.error("[SERVICE] - method = signUp, error in creare user details = {}", e.getMessage());
            throw e;
        }
    }

    @Override
    public GenericResponse changeRole(ChangeRoleRequestDto dto) throws IllegalArgumentException, ResourceNotFoundException {
        logger.info("[START SERVICE] - method = changeRole, username = {}, operationType = {}, role = {}", dto.getUsername(), dto.getOperationType(), dto.getRole());
        if (Objects.isNull(dto.getUsername()) || dto.getUsername().isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");
        if (Objects.isNull(dto.getRole()) || dto.getRole().isEmpty())
            throw new IllegalArgumentException("Role is mandatory!");
        if (Objects.isNull(dto.getOperationType()) || dto.getOperationType().isEmpty())
            throw new IllegalArgumentException("Operation type is mandatory!");

        Optional<UserEntity> userEntityOptional = userRepository.findByUsername(dto.getUsername());
        if (userEntityOptional.isEmpty()) throw new ResourceNotFoundException("Username not exists!");

        UserEntity userEntity = userEntityOptional.get();
        Set<RoleEntity> userRoles = userEntity.getRoles();
        ChangeRoleOperationType operationType;
        Role role;

        try {
            operationType = ChangeRoleOperationType.valueOf(dto.getOperationType().toUpperCase());
        } catch (IllegalArgumentException e) {
            logger.error("[SERVICE] - method = changeRole, error in operation type conversion = {}", e.getMessage());
            throw new IllegalArgumentException("Invalid operation type: " + dto.getOperationType());
        }

        try {
            role = Role.valueOf(dto.getRole().toUpperCase());
        } catch (IllegalArgumentException e) {
            logger.error("[SERVICE] - method = changeRole, error in role conversion = {}", e.getMessage());
            throw new IllegalArgumentException("Invalid role: " + dto.getRole());
        }

        switch (operationType) {
            case ADD -> {
                Optional<RoleEntity> roleEntityOptional = roleService.getRoleByName(role);
                if (roleEntityOptional.isEmpty())
                    throw new RuntimeException("Role of type = " + dto.getRole() + "is not configured!");
                userRoles.add(roleEntityOptional.get());
            }
            case REMOVE -> userRoles.removeIf(userRole -> userRole.getRole().equalsIgnoreCase(role.name()));
        }

        userRepository.save(userEntity);
        logger.info("[END SERVICE] - method = changeRole, username = {}, operationType = {}, role = {}", dto.getUsername(), dto.getOperationType(), dto.getRole());
        return new GenericResponse("Role changed successfully!");
    }

    @Transactional
    @Override
    public GenericResponse deleteUserCredentials(String username) throws IllegalArgumentException, ResourceNotFoundException {
        logger.info("[START SERVICE] - method = deleteUserCredentials, username = {}", username);
        if (Objects.isNull(username) || username.isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");

        Optional<UserEntity> userEntityOptional = userRepository.findByUsername(username);
        if (userEntityOptional.isEmpty()) throw new ResourceNotFoundException("Username not exists!");
        userRepository.deleteByUsername(username);

        logger.info("[END SERVICE] - method = deleteUserCredentials, username = {}", username);
        return new GenericResponse("User credentials deleted successfully!");
    }

    @Override
    public Integer getUserTokenVersion(String username) throws IllegalArgumentException, ResourceNotFoundException {
        logger.info("[START SERVICE] - method = getUserTokenVersion, username = {}", username);
        if (Objects.isNull(username) || username.isEmpty())
            throw new IllegalArgumentException("Username is mandatory!");

        Optional<UserEntity> userEntityOptional = userRepository.findByUsername(username);
        if (userEntityOptional.isEmpty()) throw new ResourceNotFoundException("Username not exists!");

        return userEntityOptional.get().getTokenVersion();
    }
}
