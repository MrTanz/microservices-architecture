package com.example.controller;

import com.example.dto.UserDetailsDto;
import com.example.model.GenericResponse;
import com.example.service.UserDetailsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping(value = "/users")
public class UserController {

    private final Logger logger = LoggerFactory.getLogger(UserController.class);

    @Autowired
    private UserDetailsService userDetailsService;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'USERS_MANAGER')")
    public ResponseEntity<List<UserDetailsDto>> getUsersProfile() {
        logger.info("[START API GET USERS PROFILE]");
        List<UserDetailsDto> usersProfile= userDetailsService.getUsersProfile();
        logger.info("[END API GET USERS PROFILE]");
        return ResponseEntity.ok(usersProfile);
    }

    @GetMapping(value = "/{username}/profile")
    @PreAuthorize("hasAnyRole('ADMIN', 'USERS_MANAGER', 'USER')")
    public ResponseEntity<UserDetailsDto> getUserProfile(@PathVariable String username) {
        logger.info("[START API GET USER PROFILE] - username = {}", username);
        UserDetailsDto userProfile = userDetailsService.getUserProfile(username);
        logger.info("[END API GET USER PROFILE] - username = {}", username);
        return ResponseEntity.ok(userProfile);
    }

    @PostMapping(value = "/profile")
    public ResponseEntity<GenericResponse> createUserProfile(@Valid @RequestBody UserDetailsDto dto) {
        logger.info("[START API CREATE USER PROFILE] - username = {}", dto.getUsername());
        userDetailsService.createUserProfile(dto);
        logger.info("[END API CREATE USER PROFILE] - username = {}", dto.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new GenericResponse("User created successfully!"));    }

    @PutMapping(value = "/profile")
    @PreAuthorize("hasAnyRole('ADMIN', 'USERS_MANAGER', 'USER')")
    public ResponseEntity<GenericResponse> updateUserProfile(@Valid @RequestBody UserDetailsDto dto) {
        logger.info("[START API UPDATE USER PROFILE] - username = {}", dto.getUsername());
        userDetailsService.updateUserProfile(dto);
        logger.info("[END API UPDATE USER PROFILE] - username = {}", dto.getUsername());
        return ResponseEntity.ok(new GenericResponse("User updated successfully!"));
    }

    @DeleteMapping(value = "/{username}/profile")
    @PreAuthorize("hasAnyRole('ADMIN', 'USERS_MANAGER', 'USER')")
    public ResponseEntity<GenericResponse> deleteUserProfile(@PathVariable String username) {
        logger.info("[START API DELETE USER] - username = {}", username);
        userDetailsService.deleteUserProfile(username);
        logger.info("[END API DELETE USER] - username = {}", username);
        return ResponseEntity.ok(new GenericResponse("User deleted successfully!"));
    }
}
