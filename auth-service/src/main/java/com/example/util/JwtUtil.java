package com.example.util;

import io.jsonwebtoken.Jwts;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.spec.SecretKeySpec;
import java.security.Key;
import java.util.Base64;
import java.util.Date;
import java.util.List;

@Component
public class JwtUtil {

    @Value("${security.jwt.secret-key}")
    private String secret;
    @Value("${security.jwt.token-validity}")
    private long tokenTimeValidation;

    private Key key;

    @PostConstruct
    public void init() {
        this.key = new SecretKeySpec(Base64.getDecoder().decode(secret), "HmacSHA256");
    }

    public String generateToken(String username, List<String> roles) {
        long nowMillis = System.currentTimeMillis();
        long expMillis = nowMillis + tokenTimeValidation;
        Date now = new Date(nowMillis);
        Date exp = new Date(expMillis);

        return Jwts.builder()
                .setSubject(username)
                .setIssuedAt(now)
                .setExpiration(exp)
                .claim("roles", roles)
                .signWith(key)
                .compact();
    }
}
