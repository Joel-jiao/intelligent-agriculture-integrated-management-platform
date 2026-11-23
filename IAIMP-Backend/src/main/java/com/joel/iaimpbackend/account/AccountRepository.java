package com.joel.iaimpbackend.account;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, String> {

    Optional<Account> findByPortalAndAccount(String portal, String account);
}
