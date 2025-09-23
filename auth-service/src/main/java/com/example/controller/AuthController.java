package com.example.controller;

import com.example.dto.ChangeRoleRequestDto;
import com.example.dto.LoginRequestDto;
import com.example.dto.LoginResponseDto;
import com.example.dto.SignUpRequestDto;
import com.example.model.GenericResponse;
import com.example.service.AuthService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;

@RestController
@RequestMapping(value = "/auth")
public class AuthController {

    private final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private AuthService service;

    @PostMapping(value = "/login")
    public ResponseEntity<LoginResponseDto> login(@RequestBody LoginRequestDto dto) throws NoSuchAlgorithmException, InvalidKeySpecException {
        logger.info("[START API LOGIN] - username = {}", dto.getUsername());
        LoginResponseDto response = service.login(dto);
        logger.info("[END API LOGIN] - username = {}", dto.getUsername());
        return ResponseEntity.ok(response);
    }

    @PostMapping(value = "/sign-up")
    public ResponseEntity<GenericResponse> signUp(@RequestBody SignUpRequestDto dto) throws NoSuchAlgorithmException, InvalidKeySpecException {
        logger.info("[START API SIGN UP] - username = {}", dto.getUsername());
        GenericResponse response = service.signUp(dto);
        logger.info("[END API SIGN UP] - username = {}", dto.getUsername());
        return ResponseEntity.ok(response);
    }

    @PutMapping(value = "/change-role")
    @PreAuthorize("hasAnyRole('ADMIN', 'USERS_MANAGER')")
    public ResponseEntity<GenericResponse> addUserRole(@RequestBody ChangeRoleRequestDto dto) {
        logger.info("[START API CHANGE ROLE] - username = {}, operationType = {}, role = {}", dto.getUsername(), dto.getOperationType(), dto.getRole());
        GenericResponse response = service.changeRole(dto);
        logger.info("[END API CHANGE ROLE] - username = {}, operationType = {}, role = {}", dto.getUsername(), dto.getOperationType(), dto.getRole());
        return ResponseEntity.ok(response);
    }

    @DeleteMapping(value = "/{username}/credentials")
    public ResponseEntity<GenericResponse> deleteUserCredentials(@PathVariable String username) {
        logger.info("[START API DELETE USER CREDENTIALS] - username = {}", username);
        GenericResponse response = service.deleteUserCredentials(username);
        logger.info("[END API DELETE USER CREDENTIALS] - username = {}", username);
        return ResponseEntity.ok(response);
    }
}
