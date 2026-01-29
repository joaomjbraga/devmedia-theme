<?php
// PHP - Modern Example with Traits

namespace DevMedia\App;

trait Loggable {
    protected function log(string $message): void {
        echo "[LOG] " . date('Y-m-d H:i:s') . " - $message\n";
    }
}

trait Validatable {
    protected function validateEmail(string $email): bool {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }
}

class User {
    use Loggable, Validatable;
    
    private int $id;
    private string $name;
    private string $email;
    private string $role;
    
    public function __construct(int $id, string $name, string $email, string $role = 'student') {
        $this->id = $id;
        $this->name = $name;
        
        if (!$this->validateEmail($email)) {
            throw new \InvalidArgumentException("Invalid email");
        }
        
        $this->email = $email;
        $this->role = $role;
        $this->log("User created: $name");
    }
    
    public function getId(): int {
        return $this->id;
    }
    
    public function getName(): string {
        return $this->name;
    }
    
    public function getEmail(): string {
        return $this->email;
    }
}

class UserRepository {
    private array $users = [];
    
    public function add(User $user): void {
        $this->users[$user->getId()] = $user;
    }
    
    public function find(int $id): ?User {
        return $this->users[$id] ?? null;
    }
    
    public function findAll(): array {
        return $this->users;
    }
}

// Usage
$repo = new UserRepository();
$user = new User(1, "João Silva", "joao@devmedia.com.br", "admin");
$repo->add($user);

echo "Total users: " . count($repo->findAll()) . "\n";
?>
