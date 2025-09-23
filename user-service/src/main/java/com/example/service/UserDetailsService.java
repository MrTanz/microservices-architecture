package com.example.service;

import com.example.dto.UserDetailsDto;

import java.util.List;

public interface UserDetailsService {

    List<UserDetailsDto> getUsersProfile();

    UserDetailsDto getUserProfile(String username);

    void createUserProfile(UserDetailsDto dto);

    void updateUserProfile(UserDetailsDto dto);

    void deleteUserProfile(String username);
}
