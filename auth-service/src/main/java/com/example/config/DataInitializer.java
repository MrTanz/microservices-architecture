package com.example.config;

import com.example.entity.RoleEntity;
import com.example.entity.UserEntity;
import com.example.enums.Role;
import com.example.repository.RoleRepository;
import com.example.repository.UserRepository;
import com.example.util.PasswordUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.util.*;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private RoleRepository roleRepository;

    @Override
    public void run(String... args) throws NoSuchAlgorithmException, InvalidKeySpecException {
        for (Role role : Role.values()) {
            createRoleIfNotExists(role);
        }

        createUserWithRole("admin@email.it", PasswordUtil.hashPassword("admin1234".toCharArray(), PasswordUtil.getSalt()), Role.ADMIN);
    }

    private void createRoleIfNotExists(Role role) {
        String roleName = role.name();
        roleRepository.findByName(roleName).orElseGet(() ->
                roleRepository.save(new RoleEntity(roleName))
        );
    }

    private void createUserWithRole(String email, String password, Role role) {
        if (userRepository.existsByUsername(email)) return;

        RoleEntity roleEntity = roleRepository.findByName(role.name())
                .orElseThrow(() -> new IllegalStateException("Role " + role + " not found"));

        UserEntity user = new UserEntity();
        user.setUsername(email);
        user.setPassword(password);
        user.setCreateAt(new Date());
        user.setRoles(Set.of(roleEntity));

        userRepository.save(user);
    }
}
