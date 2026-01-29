# ============================================
# Python - Exemplo Completo com Decorators
# ============================================

import asyncio
from typing import List, Dict, Optional, Union, Any
from datetime import datetime
from functools import wraps
from dataclasses import dataclass, field
from enum import Enum
import logging

# Configuração
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# ============================================
# Decorators
# ============================================

def timer(func):
    """Decorator para medir tempo de execução"""
    @wraps(func)
    async def wrapper(*args, **kwargs):
        start = datetime.now()
        result = await func(*args, **kwargs)
        duration = (datetime.now() - start).total_seconds()
        logger.info(f"{func.__name__} executado em {duration:.2f}s")
        return result
    return wrapper


def validate_input(func):
    """Decorator para validar entrada"""
    @wraps(func)
    def wrapper(self, *args, **kwargs):
        if not args and not kwargs:
            raise ValueError("Argumentos obrigatórios faltando")
        return func(self, *args, **kwargs)
    return wrapper


def retry(max_attempts: int = 3):
    """Decorator para retry automático"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    logger.warning(f"Tentativa {attempt + 1} falhou: {e}")
                    await asyncio.sleep(2 ** attempt)
        return wrapper
    return decorator


# ============================================
# Enums e DataClasses
# ============================================

class UserRole(Enum):
    ADMIN = "admin"
    INSTRUCTOR = "instructor"
    STUDENT = "student"
    GUEST = "guest"


class CourseLevel(Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


@dataclass
class User:
    """Classe de usuário usando dataclass"""
    id: int
    name: str
    email: str
    role: UserRole = UserRole.STUDENT
    active: bool = True
    created_at: datetime = field(default_factory=datetime.now)
    
    def __str__(self) -> str:
        return f"User({self.name}, {self.email}, {self.role.value})"
    
    @property
    def is_admin(self) -> bool:
        """Verifica se o usuário é admin"""
        return self.role == UserRole.ADMIN
    
    @property
    def age_in_days(self) -> int:
        """Calcula idade da conta em dias"""
        return (datetime.now() - self.created_at).days


@dataclass
class Course:
    """Classe de curso"""
    id: int
    title: str
    description: str
    price: float
    instructor_id: int
    level: CourseLevel = CourseLevel.BEGINNER
    students: List[int] = field(default_factory=list)
    
    def add_student(self, student_id: int) -> None:
        """Adiciona estudante ao curso"""
        if student_id not in self.students:
            self.students.append(student_id)
            logger.info(f"Estudante {student_id} adicionado ao curso {self.title}")
    
    def apply_discount(self, percentage: float) -> float:
        """Aplica desconto ao preço"""
        if not 0 <= percentage <= 100:
            raise ValueError("Percentual deve estar entre 0 e 100")
        return self.price * (1 - percentage / 100)
    
    @property
    def student_count(self) -> int:
        """Retorna número de estudantes"""
        return len(self.students)


# ============================================
# Classes com Herança
# ============================================

class Repository:
    """Classe base para repositórios"""
    
    def __init__(self):
        self._items: Dict[int, Any] = {}
        self._next_id = 1
    
    def add(self, item: Any) -> int:
        """Adiciona item ao repositório"""
        item_id = self._next_id
        self._items[item_id] = item
        self._next_id += 1
        return item_id
    
    def get(self, item_id: int) -> Optional[Any]:
        """Busca item por ID"""
        return self._items.get(item_id)
    
    def get_all(self) -> List[Any]:
        """Retorna todos os itens"""
        return list(self._items.values())
    
    def delete(self, item_id: int) -> bool:
        """Remove item"""
        if item_id in self._items:
            del self._items[item_id]
            return True
        return False
    
    def __len__(self) -> int:
        return len(self._items)


class UserRepository(Repository):
    """Repositório específico para usuários"""
    
    def find_by_email(self, email: str) -> Optional[User]:
        """Busca usuário por email"""
        for user in self._items.values():
            if isinstance(user, User) and user.email == email:
                return user
        return None
    
    def find_by_role(self, role: UserRole) -> List[User]:
        """Filtra usuários por role"""
        return [
            user for user in self._items.values()
            if isinstance(user, User) and user.role == role
        ]


# ============================================
# Classes com Métodos Assíncronos
# ============================================

class UserService:
    """Serviço para gerenciar usuários"""
    
    def __init__(self, repository: UserRepository):
        self.repository = repository
    
    @validate_input
    def create_user(self, name: str, email: str, role: UserRole) -> User:
        """Cria novo usuário"""
        user_id = len(self.repository) + 1
        user = User(id=user_id, name=name, email=email, role=role)
        self.repository.add(user)
        logger.info(f"Usuário criado: {user}")
        return user
    
    @timer
    @retry(max_attempts=3)
    async def fetch_user_data(self, user_id: int) -> Optional[Dict]:
        """Simula busca assíncrona de dados"""
        await asyncio.sleep(0.5)  # Simula latência
        
        user = self.repository.get(user_id)
        if not user:
            return None
        
        return {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role.value,
            'active': user.active,
            'is_admin': user.is_admin,
            'account_age_days': user.age_in_days
        }
    
    async def batch_fetch_users(self, user_ids: List[int]) -> List[Optional[Dict]]:
        """Busca múltiplos usuários em paralelo"""
        tasks = [self.fetch_user_data(uid) for uid in user_ids]
        return await asyncio.gather(*tasks)


# ============================================
# Context Manager
# ============================================

class DatabaseConnection:
    """Context manager para conexão de banco"""
    
    def __init__(self, db_name: str):
        self.db_name = db_name
        self.connected = False
    
    def __enter__(self):
        logger.info(f"Conectando ao banco: {self.db_name}")
        self.connected = True
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        logger.info(f"Desconectando do banco: {self.db_name}")
        self.connected = False
        if exc_type:
            logger.error(f"Erro: {exc_val}")
        return False
    
    def execute(self, query: str) -> str:
        """Executa query"""
        if not self.connected:
            raise RuntimeError("Não conectado ao banco")
        return f"Executando: {query}"


# ============================================
# Generators
# ============================================

def fibonacci(n: int):
    """Generator de fibonacci"""
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b


def batch_processor(items: List[Any], batch_size: int = 10):
    """Processa itens em lotes"""
    for i in range(0, len(items), batch_size):
        yield items[i:i + batch_size]


# ============================================
# List Comprehensions e Lambda
# ============================================

def filter_and_transform_users(users: List[User]) -> Dict[str, List[str]]:
    """Filtra e transforma usuários usando comprehensions"""
    
    # List comprehension
    active_users = [u for u in users if u.active]
    
    # Dict comprehension
    users_by_role = {
        role.value: [u.name for u in users if u.role == role]
        for role in UserRole
    }
    
    # Set comprehension
    unique_domains = {u.email.split('@')[1] for u in users}
    
    # Lambda com filter e map
    admin_emails = list(
        map(lambda u: u.email, filter(lambda u: u.is_admin, users))
    )
    
    return {
        'active_count': len(active_users),
        'by_role': users_by_role,
        'domains': list(unique_domains),
        'admin_emails': admin_emails
    }


# ============================================
# Exemplo de Uso
# ============================================

async def main():
    print("=== DevMedia - Sistema de Gerenciamento ===\n")
    
    # Criar repositório e serviço
    user_repo = UserRepository()
    user_service = UserService(user_repo)
    
    # Criar usuários
    users = [
        user_service.create_user("João Silva", "joao@devmedia.com.br", UserRole.ADMIN),
        user_service.create_user("Maria Santos", "maria@devmedia.com.br", UserRole.INSTRUCTOR),
        user_service.create_user("Pedro Costa", "pedro@devmedia.com.br", UserRole.STUDENT),
        user_service.create_user("Ana Lima", "ana@gmail.com", UserRole.STUDENT),
    ]
    
    print(f"\n✓ {len(users)} usuários criados\n")
    
    # Buscar dados de usuário
    print("--- Buscando dados do usuário #1 ---")
    user_data = await user_service.fetch_user_data(1)
    if user_data:
        for key, value in user_data.items():
            print(f"  {key}: {value}")
    
    # Batch fetch
    print("\n--- Buscando múltiplos usuários ---")
    batch_data = await user_service.batch_fetch_users([1, 2, 3])
    print(f"✓ {len([d for d in batch_data if d])} usuários encontrados")
    
    # Filtrar por role
    print("\n--- Estudantes ---")
    students = user_repo.find_by_role(UserRole.STUDENT)
    for student in students:
        print(f"  - {student.name} ({student.email})")
    
    # Usar context manager
    print("\n--- Context Manager ---")
    with DatabaseConnection("devmedia_db") as db:
        result = db.execute("SELECT * FROM users")
        print(f"  {result}")
    
    # Generator
    print("\n--- Fibonacci (10 primeiros) ---")
    fib_numbers = list(fibonacci(10))
    print(f"  {fib_numbers}")
    
    # Comprehensions
    print("\n--- Análise de Usuários ---")
    analysis = filter_and_transform_users(users)
    print(f"  Usuários ativos: {analysis['active_count']}")
    print(f"  Domínios únicos: {analysis['domains']}")
    print(f"  Emails de admins: {analysis['admin_emails']}")
    
    # Criar curso
    course = Course(
        id=1,
        title="Python Avançado",
        description="Curso completo de Python",
        price=499.90,
        instructor_id=2,
        level=CourseLevel.ADVANCED
    )
    
    # Adicionar estudantes
    for user in students:
        course.add_student(user.id)
    
    print(f"\n--- Curso: {course.title} ---")
    print(f"  Estudantes: {course.student_count}")
    print(f"  Preço original: R$ {course.price:.2f}")
    print(f"  Com 20% desconto: R$ {course.apply_discount(20):.2f}")


if __name__ == "__main__":
    asyncio.run(main())
