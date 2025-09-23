package com.example.security;

import com.example.controller.UserController;
import com.example.model.GenericResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import jakarta.annotation.PostConstruct;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.security.Key;
import java.util.Base64;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private static final String INTERNAL_API_KEY_HEADER = "internal-api-key";
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private Key signingKey;

    @Value("${security.jwt.secret-key}")
    private String secret;
    @Value("${security.internal-api-key}")
    private String internalApiKey;

    @Autowired
    private ObjectMapper objectMapper;

    @PostConstruct
    public void init() {
        this.signingKey = new SecretKeySpec(Base64.getDecoder().decode(secret), "HmacSHA256");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        HttpMethod httpMethod = HttpMethod.valueOf(request.getMethod());

        String path = request.getRequestURI();
        String internalApiKeyHeader = request.getHeader(INTERNAL_API_KEY_HEADER);
        String authorizationHeader = request.getHeader(AUTHORIZATION_HEADER);

        if (HttpMethod.POST.equals(httpMethod) && "/users/profile".equals(path)) {
            if(Objects.isNull(internalApiKeyHeader) || !internalApiKey.equals(internalApiKeyHeader)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                response.getWriter().write(objectMapper.writeValueAsString(new GenericResponse("Unauthorized!")));
                return;
            }
            filterChain.doFilter(request, response);
            return;
        }

        if (Objects.isNull(authorizationHeader) || !authorizationHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authorizationHeader.substring(7);

        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(signingKey)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            String username = claims.getSubject();

            logger.info("[USER FROM TOKEN] - username = {}", username);

            List<?> roles = claims.get("roles", List.class);
            List<SimpleGrantedAuthority> authorities = roles.stream()
                    .map(Object::toString)
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .toList();

            Authentication auth = new UsernamePasswordAuthenticationToken(
                    username,
                    null,
                    authorities
            );

            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (JwtException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(objectMapper.writeValueAsString(new GenericResponse("Invalid or expired token!")));
            return;
        }

        filterChain.doFilter(request, response);
    }
}
