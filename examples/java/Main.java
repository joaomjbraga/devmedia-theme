/**
 * Java example - Banking system with records, streams, and records
 */
package com.devmedia.example;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Predicate;
import java.util.stream.Collectors;

public class Main {

    public static void main(String[] args) {
        var bank = new Bank("DevMedia Bank");

        // Creating accounts
        var acc1 = bank.createAccount("Alice", BigDecimal.valueOf(1000));
        var acc2 = bank.createAccount("Bob", BigDecimal.valueOf(500));
        var acc3 = bank.createAccount("Charlie", BigDecimal.valueOf(2500));

        // Transactions
        bank.transfer(acc1.id(), acc2.id(), BigDecimal.valueOf(200));
        bank.deposit(acc3.id(), BigDecimal.valueOf(1000));
        bank.withdraw(acc1.id(), BigDecimal.valueOf(50));

        // Querying
        System.out.println("=== All Accounts ===");
        bank.listAccounts().forEach(System.out::println);

        System.out.println("\n=== Rich Accounts (balance > 1000) ===");
        bank.findAccounts(a -> a.balance().compareTo(BigDecimal.valueOf(1000)) > 0)
            .forEach(System.out::println);

        System.out.println("\n=== Transaction History ===");
        bank.getTransactionHistory(acc1.id())
            .forEach(System.out::println);
    }
}

/**
 * Immutable account record
 */
record Account(
    String id,
    String holderName,
    BigDecimal balance,
    LocalDateTime createdAt
) {}

/**
 * Immutable transaction record
 */
record Transaction(
    String id,
    String accountId,
    TransactionType type,
    BigDecimal amount,
    LocalDateTime timestamp
) {
    public Transaction {
        Objects.requireNonNull(id);
        Objects.requireNonNull(accountId);
        Objects.requireNonNull(type);
        Objects.requireNonNull(amount);
        Objects.requireNonNull(timestamp);
    }
}

enum TransactionType {
    DEPOSIT,
    WITHDRAWAL,
    TRANSFER_IN,
    TRANSFER_OUT
}

sealed interface BankOperation permits Deposit, Withdrawal, Transfer {}

record Deposit(String accountId, BigDecimal amount) implements BankOperation {}
record Withdrawal(String accountId, BigDecimal amount) implements BankOperation {}
record Transfer(String fromAccountId, String toAccountId, BigDecimal amount)
    implements BankOperation {}

class Bank {
    private static final AtomicLong ID_COUNTER = new AtomicLong(0);

    private final String name;
    private final Map<String, Account> accounts = new ConcurrentHashMap<>();
    private final Map<String, List<Transaction>> transactions = new ConcurrentHashMap<>();

    public Bank(String name) {
        this.name = Objects.requireNonNull(name);
    }

    public Account createAccount(String holderName, BigDecimal initialDeposit) {
        var id = "ACC-" + ID_COUNTER.incrementAndGet();
        var account = new Account(
            id,
            holderName,
            initialDeposit.setScale(2, RoundingMode.HALF_UP),
            LocalDateTime.now()
        );
        accounts.put(id, account);
        transactions.put(id, new ArrayList<>());

        if (initialDeposit.compareTo(BigDecimal.ZERO) > 0) {
            addTransaction(id, TransactionType.DEPOSIT, initialDeposit);
        }

        return account;
    }

    public Optional<Account> getAccount(String id) {
        return Optional.ofNullable(accounts.get(id));
    }

    public List<Account> listAccounts() {
        return List.copyOf(accounts.values());
    }

    public List<Account> findAccounts(Predicate<Account> predicate) {
        return accounts.values().stream()
            .filter(predicate)
            .collect(Collectors.toUnmodifiableList());
    }

    public void deposit(String accountId, BigDecimal amount) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }

        accounts.computeIfPresent(accountId, (id, acc) -> {
            var newBalance = acc.balance().add(amount);
            addTransaction(id, TransactionType.DEPOSIT, amount);
            return new Account(id, acc.holderName(), newBalance, acc.createdAt());
        });
    }

    public void withdraw(String accountId, BigDecimal amount) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }

        accounts.computeIfPresent(accountId, (id, acc) -> {
            if (acc.balance().compareTo(amount) < 0) {
                throw new IllegalStateException("Insufficient funds");
            }
            var newBalance = acc.balance().subtract(amount);
            addTransaction(id, TransactionType.WITHDRAWAL, amount);
            return new Account(id, acc.holderName(), newBalance, acc.createdAt());
        });
    }

    public void transfer(String fromId, String toId, BigDecimal amount) {
        if (amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be positive");
        }

        withdraw(fromId, amount);
        deposit(toId, amount);
        addTransaction(fromId, TransactionType.TRANSFER_OUT, amount);
        addTransaction(toId, TransactionType.TRANSFER_IN, amount);
    }

    public List<Transaction> getTransactionHistory(String accountId) {
        return List.copyOf(
            transactions.getOrDefault(accountId, List.of())
        );
    }

    public BigDecimal getTotalBalance() {
        return accounts.values().stream()
            .map(Account::balance)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private void addTransaction(
        String accountId,
        TransactionType type,
        BigDecimal amount
    ) {
        var tx = new Transaction(
            "TXN-" + ID_COUNTER.incrementAndGet(),
            accountId,
            type,
            amount,
            LocalDateTime.now()
        );
        transactions.get(accountId).add(tx);
    }

    @Override
    public String toString() {
        return "Bank{name='" + name + "', accounts=" + accounts.size() + "}";
    }
}
