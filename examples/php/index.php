<?php
/**
 * PHP example - Blog engine with PDO and templates
 */
declare(strict_types=1);

namespace DevMedia\Example;

use DateTimeImmutable;
use PDO;
use PDOException;
use InvalidArgumentException;

// ---------- Constants ----------

const DB_PATH = __DIR__ . '/data/blog.sqlite';
const SITE_NAME = 'DevMedia Blog';
const POSTS_PER_PAGE = 10;

// ---------- Autoload (manual for example) ----------

spl_autoload_register(function (string $class): void {
    $prefix = 'DevMedia\\Example\\';
    if (str_starts_with($class, $prefix)) {
        $relative = substr($class, strlen($prefix));
        $file = __DIR__ . '/src/' . str_replace('\\', '/', $relative) . '.php';
        if (file_exists($file)) {
            require_once $file;
        }
    }
});

// ---------- Enums (PHP 8.1+) ----------

enum PostStatus: string
{
    case Draft = 'draft';
    case Published = 'published';
    case Archived = 'archived';

    public function label(): string
    {
        return match ($this) {
            self::Draft => 'Rascunho',
            self::Published => 'Publicado',
            self::Archived => 'Arquivado',
        };
    }
}

// ---------- DTOs ----------

readonly class Author
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
        public ?string $bio = null,
    ) {}
}

readonly class Post
{
    public function __construct(
        public int $id,
        public string $title,
        public string $content,
        public Author $author,
        public PostStatus $status,
        public DateTimeImmutable $createdAt,
        public DateTimeImmutable $updatedAt,
        public array $tags = [],
    ) {}
}

// ---------- Database ----------

class Database
{
    private static ?PDO $instance = null;

    public static function connect(): PDO
    {
        if (self::$instance === null) {
            $dir = dirname(DB_PATH);
            if (!is_dir($dir)) {
                mkdir($dir, 0755, true);
            }

            self::$instance = new PDO(
                'sqlite:' . DB_PATH,
                options: [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );

            self::migrate();
        }

        return self::$instance;
    }

    private static function migrate(): void
    {
        $pdo = self::$instance;

        $pdo->exec('
            CREATE TABLE IF NOT EXISTS authors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                bio TEXT,
                created_at TEXT NOT NULL DEFAULT (datetime("now"))
            )
        ');

        $pdo->exec('
            CREATE TABLE IF NOT EXISTS posts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                author_id INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT "draft",
                tags TEXT NOT NULL DEFAULT "[]",
                created_at TEXT NOT NULL DEFAULT (datetime("now")),
                updated_at TEXT NOT NULL DEFAULT (datetime("now")),
                FOREIGN KEY (author_id) REFERENCES authors(id)
            )
        ');
    }
}

// ---------- Repository ----------

class PostRepository
{
    public function __construct(
        private PDO $pdo
    ) {}

    public function create(array $data): Post
    {
        $stmt = $this->pdo->prepare('
            INSERT INTO posts (title, content, author_id, status, tags)
            VALUES (:title, :content, :author_id, :status, :tags)
        ');

        $stmt->execute([
            'title' => $data['title'],
            'content' => $data['content'],
            'author_id' => $data['author_id'],
            'status' => $data['status'] ?? PostStatus::Draft->value,
            'tags' => json_encode($data['tags'] ?? []),
        ]);

        return $this->findById((int) $this->pdo->lastInsertId());
    }

    public function findById(int $id): ?Post
    {
        $stmt = $this->pdo->prepare('
            SELECT p.*, a.name as author_name, a.email as author_email, a.bio as author_bio
            FROM posts p
            JOIN authors a ON p.author_id = a.id
            WHERE p.id = :id
        ');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row ? $this->mapRowToPost($row) : null;
    }

    public function findAll(int $page = 1, int $limit = POSTS_PER_PAGE): array
    {
        $offset = ($page - 1) * $limit;

        $stmt = $this->pdo->prepare('
            SELECT p.*, a.name as author_name, a.email as author_email, a.bio as author_bio
            FROM posts p
            JOIN authors a ON p.author_id = a.id
            WHERE p.status = :status
            ORDER BY p.created_at DESC
            LIMIT :limit OFFSET :offset
        ');

        $stmt->bindValue('status', PostStatus::Published->value);
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->bindValue('offset', $offset, PDO::PARAM_INT);
        $stmt->execute();

        $posts = array_map(fn(array $row) => $this->mapRowToPost($row), $stmt->fetchAll());

        $countStmt = $this->pdo->query('SELECT COUNT(*) FROM posts WHERE status = "published"');
        $total = (int) $countStmt->fetchColumn();

        return [
            'posts' => $posts,
            'total' => $total,
            'page' => $page,
            'pages' => (int) ceil($total / $limit),
        ];
    }

    private function mapRowToPost(array $row): Post
    {
        return new Post(
            id: (int) $row['id'],
            title: $row['title'],
            content: $row['content'],
            author: new Author(
                id: (int) $row['author_id'],
                name: $row['author_name'],
                email: $row['author_email'],
                bio: $row['author_bio'],
            ),
            status: PostStatus::from($row['status']),
            createdAt: new DateTimeImmutable($row['created_at']),
            updatedAt: new DateTimeImmutable($row['updated_at']),
            tags: json_decode($row['tags'], true) ?? [],
        );
    }
}

// ---------- Service ----------

class BlogService
{
    public function __construct(
        private PostRepository $repository,
    ) {}

    public function createPost(array $data): Post
    {
        if (empty($data['title'])) {
            throw new InvalidArgumentException('Title is required');
        }
        if (empty($data['content'])) {
            throw new InvalidArgumentException('Content is required');
        }

        return $this->repository->create($data);
    }

    public function getPost(int $id): ?Post
    {
        return $this->repository->findById($id);
    }

    public function listPosts(int $page = 1): array
    {
        return $this->repository->findAll($page);
    }
}

// ---------- Bootstrap ----------

try {
    $pdo = Database::connect();
    $repository = new PostRepository($pdo);
    $service = new BlogService($repository);

    // Seed data
    $pdo->exec('DELETE FROM posts; DELETE FROM authors');
    $pdo->exec('INSERT INTO authors (id, name, email) VALUES (1, \'João Braga\', \'joao@devmedia.com\')');

    $post = $service->createPost([
        'title' => 'Introdução ao PHP 8',
        'content' => 'PHP 8 trouxe diversas funcionalidades como JIT, atributos, tipos union...',
        'author_id' => 1,
        'status' => PostStatus::Published->value,
        'tags' => ['php', 'web', 'tutorial'],
    ]);

    echo json_encode($post, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";
} catch (PDOException $e) {
    echo "Database error: " . $e->getMessage() . "\n";
    exit(1);
} catch (\Throwable $e) {
    echo "Error: " . $e->getMessage() . "\n";
    exit(1);
}
