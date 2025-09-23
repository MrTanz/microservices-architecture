package com.example.service.impl;

import com.example.enums.Role;
import com.example.entity.RoleEntity;
import com.example.repository.RoleRepository;
import com.example.service.RoleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class RoleServiceImpl implements RoleService {

    @Autowired
    private RoleRepository repository;

    @Override
    public Optional<RoleEntity> getRoleByName(Role role) {
        return repository.findByName(role.name());
    }
}
