package com.example.service;

import com.example.dto.ChangeRoleRequestDto;
import com.example.dto.LoginRequestDto;
import com.example.dto.LoginResponseDto;
import com.example.dto.SignUpRequestDto;
import com.example.expection.ResourceNotFoundException;
import com.example.model.GenericResponse;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;


public interface AuthService {

    LoginResponseDto login(LoginRequestDto dto) throws NoSuchAlgorithmException, InvalidKeySpecException;

    GenericResponse signUp(SignUpRequestDto dto) throws NoSuchAlgorithmException, InvalidKeySpecException;

    GenericResponse changeRole(ChangeRoleRequestDto dto) throws IllegalArgumentException, ResourceNotFoundException;

    Integer getUserTokenVersion(String username) throws IllegalArgumentException, ResourceNotFoundException;
    
    GenericResponse deleteUserCredentials(String username) throws IllegalArgumentException, ResourceNotFoundException;
}
