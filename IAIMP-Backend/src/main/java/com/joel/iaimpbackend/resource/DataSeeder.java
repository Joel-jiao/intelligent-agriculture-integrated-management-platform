package com.joel.iaimpbackend.resource;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.joel.iaimpbackend.account.Account;
import com.joel.iaimpbackend.account.AccountRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.util.Iterator;
import java.util.Map;

/**
 * 启动种子加载：首次启动（accounts 表为空）时，把前端 json-server 的 db.json
 * 全量导入 MySQL 结构化表——账号（密码转 BCrypt）与各业务集合（含单例对象）。
 * 业务数据通过 {@link ResourceService} 按表写入。
 */
@Component
public class DataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final AccountRepository accountRepository;
    private final ResourceService resourceService;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    public DataSeeder(AccountRepository accountRepository,
                      ResourceService resourceService,
                      PasswordEncoder passwordEncoder,
                      ObjectMapper objectMapper) {
        this.accountRepository = accountRepository;
        this.resourceService = resourceService;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = objectMapper;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        if (accountRepository.count() > 0) {
            log.info("数据库已有账号数据，跳过种子导入");
            return;
        }

        JsonNode root = readSeed();
        seedAccounts(root.path("accounts"));
        seedResources(root);
        log.info("种子数据导入完成：{} 个账号，其余集合已按 db.json 还原",
                root.path("accounts").size());
    }

    private JsonNode readSeed() throws Exception {
        try (InputStream in = new ClassPathResource("seed/db.json").getInputStream()) {
            return objectMapper.readTree(in);
        }
    }

    private void seedAccounts(JsonNode accounts) {
        if (accounts == null || !accounts.isArray()) {
            return;
        }
        for (JsonNode node : accounts) {
            Account account = new Account();
            account.setId(node.path("id").asText());
            account.setPortal(node.path("portal").asText());
            account.setAccount(node.path("account").asText());
            account.setPassword(passwordEncoder.encode(node.path("password").asText("")));
            account.setName(node.path("name").asText());
            account.setRole(node.path("role").asText());
            account.setStatus(node.path("status").asText("启用"));
            accountRepository.save(account);
        }
    }

    private void seedResources(JsonNode root) {
        Iterator<Map.Entry<String, JsonNode>> fields = root.fields();
        while (fields.hasNext()) {
            Map.Entry<String, JsonNode> entry = fields.next();
            String collection = entry.getKey();
            if ("accounts".equals(collection)) {
                continue;
            }
            JsonNode value = entry.getValue();
            if (value != null && value.isArray()) {
                for (JsonNode item : value) {
                    resourceService.create(collection, item);
                }
            } else if (value != null && value.isObject()) {
                resourceService.create(collection, value);
            }
        }
    }
}
