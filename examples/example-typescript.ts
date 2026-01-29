// ============================================
// TypeScript - Tipagem Avançada
// ============================================

// Tipos básicos
type ID = number | string;
type Email = string;
type Timestamp = number;

// Interfaces
interface User {
    id: ID;
    name: string;
    email: Email;
    role: UserRole;
    active: boolean;
    createdAt: Date;
    metadata?: UserMetadata;
}

interface UserMetadata {
    lastLogin?: Date;
    preferences: {
        theme: 'light' | 'dark';
        language: string;
    };
    tags: string[];
}

// Type Unions e Literals
type UserRole = 'admin' | 'instructor' | 'student' | 'guest';
type CourseLevel = 'beginner' | 'intermediate' | 'advanced';
type EnrollmentStatus = 'pending' | 'active' | 'completed' | 'cancelled';

// Tipos genéricos
interface ApiResponse<T> {
    success: boolean;
    data: T;
    error?: string;
    timestamp: Timestamp;
}

interface PaginatedResponse<T> extends ApiResponse<T[]> {
    page: number;
    pageSize: number;
    total: number;
}

// Classes com TypeScript
class Course {
    private static nextId: number = 1;
    
    readonly id: number;
    public title: string;
    public description: string;
    private _price: number;
    protected instructor: User;
    
    constructor(
        title: string,
        description: string,
        price: number,
        instructor: User
    ) {
        this.id = Course.nextId++;
        this.title = title;
        this.description = description;
        this._price = price;
        this.instructor = instructor;
    }
    
    // Getter e Setter com validação
    get price(): number {
        return this._price;
    }
    
    set price(value: number) {
        if (value < 0) {
            throw new Error('Price cannot be negative');
        }
        this._price = value;
    }
    
    // Método público
    public applyDiscount(percentage: number): number {
        if (percentage < 0 || percentage > 100) {
            throw new Error('Invalid discount percentage');
        }
        return this._price * (1 - percentage / 100);
    }
    
    // Método estático
    static fromJSON(json: any): Course {
        return new Course(
            json.title,
            json.description,
            json.price,
            json.instructor
        );
    }
}

// Classe com Generics
class Repository<T extends { id: ID }> {
    private items: Map<ID, T> = new Map();
    
    add(item: T): void {
        this.items.set(item.id, item);
    }
    
    get(id: ID): T | undefined {
        return this.items.get(id);
    }
    
    getAll(): T[] {
        return Array.from(this.items.values());
    }
    
    update(id: ID, updates: Partial<T>): T | undefined {
        const item = this.items.get(id);
        if (!item) return undefined;
        
        const updated = { ...item, ...updates };
        this.items.set(id, updated);
        return updated;
    }
    
    delete(id: ID): boolean {
        return this.items.delete(id);
    }
    
    filter(predicate: (item: T) => boolean): T[] {
        return this.getAll().filter(predicate);
    }
}

// Type Guards
function isUser(obj: any): obj is User {
    return (
        typeof obj === 'object' &&
        'id' in obj &&
        'name' in obj &&
        'email' in obj &&
        'role' in obj
    );
}

function assertUser(obj: any): asserts obj is User {
    if (!isUser(obj)) {
        throw new Error('Object is not a User');
    }
}

// Utility Types
type PartialUser = Partial<User>;
type RequiredUser = Required<User>;
type ReadonlyUser = Readonly<User>;
type PickedUser = Pick<User, 'id' | 'name' | 'email'>;
type OmittedUser = Omit<User, 'metadata'>;

// Mapped Types
type Nullable<T> = {
    [P in keyof T]: T[P] | null;
};

type Optional<T> = {
    [P in keyof T]?: T[P];
};

// Conditional Types
type IsArray<T> = T extends any[] ? true : false;
type ArrayElement<T> = T extends (infer E)[] ? E : never;
type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never;

// Service Layer
class UserService {
    private repository: Repository<User>;
    
    constructor(repository: Repository<User>) {
        this.repository = repository;
    }
    
    async createUser(
        name: string,
        email: Email,
        role: UserRole
    ): Promise<ApiResponse<User>> {
        try {
            const user: User = {
                id: Date.now(),
                name,
                email,
                role,
                active: true,
                createdAt: new Date()
            };
            
            this.repository.add(user);
            
            return {
                success: true,
                data: user,
                timestamp: Date.now()
            };
        } catch (error) {
            return {
                success: false,
                data: {} as User,
                error: error instanceof Error ? error.message : 'Unknown error',
                timestamp: Date.now()
            };
        }
    }
    
    async getUsers(
        page: number = 1,
        pageSize: number = 10
    ): Promise<PaginatedResponse<User>> {
        const allUsers = this.repository.getAll();
        const start = (page - 1) * pageSize;
        const end = start + pageSize;
        const paginatedUsers = allUsers.slice(start, end);
        
        return {
            success: true,
            data: paginatedUsers,
            page,
            pageSize,
            total: allUsers.length,
            timestamp: Date.now()
        };
    }
    
    async updateUser(
        id: ID,
        updates: Partial<User>
    ): Promise<ApiResponse<User>> {
        const updated = this.repository.update(id, updates);
        
        if (!updated) {
            return {
                success: false,
                data: {} as User,
                error: 'User not found',
                timestamp: Date.now()
            };
        }
        
        return {
            success: true,
            data: updated,
            timestamp: Date.now()
        };
    }
    
    filterByRole(role: UserRole): User[] {
        return this.repository.filter(user => user.role === role);
    }
}

// Async/Await com Tipos
async function fetchUserData(userId: ID): Promise<User | null> {
    try {
        const response = await fetch(`/api/users/${userId}`);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        
        if (isUser(data)) {
            return data;
        }
        
        return null;
    } catch (error) {
        console.error('Error fetching user:', error);
        return null;
    }
}

// Decorators (experimental)
function Log(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = async function(...args: any[]) {
        console.log(`Calling ${propertyKey} with:`, args);
        const result = await originalMethod.apply(this, args);
        console.log(`Result:`, result);
        return result;
    };
    
    return descriptor;
}

function Validate(target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = function(...args: any[]) {
        if (args.some(arg => arg === null || arg === undefined)) {
            throw new Error('Null or undefined argument');
        }
        return originalMethod.apply(this, args);
    };
    
    return descriptor;
}

class EnrollmentService {
    @Log
    @Validate
    async enroll(userId: ID, courseId: ID): Promise<boolean> {
        console.log(`Enrolling user ${userId} in course ${courseId}`);
        // Lógica de matrícula
        return true;
    }
}

// Namespace
namespace Utils {
    export function formatDate(date: Date): string {
        return date.toISOString().split('T')[0];
    }
    
    export function generateId(): ID {
        return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
    
    export class Validator {
        static isEmail(email: string): boolean {
            const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return regex.test(email);
        }
        
        static isValidRole(role: string): role is UserRole {
            return ['admin', 'instructor', 'student', 'guest'].includes(role);
        }
    }
}

// Exemplo de uso
(async () => {
    console.log('=== DevMedia TypeScript Demo ===\n');
    
    // Criar repositório
    const userRepo = new Repository<User>();
    const userService = new UserService(userRepo);
    
    // Criar usuários
    const user1 = await userService.createUser(
        'João Silva',
        'joao@devmedia.com.br',
        'admin'
    );
    
    const user2 = await userService.createUser(
        'Maria Santos',
        'maria@devmedia.com.br',
        'student'
    );
    
    console.log('Usuários criados:', user1.success, user2.success);
    
    // Buscar usuários
    const users = await userService.getUsers(1, 10);
    console.log('Total de usuários:', users.total);
    console.log('Usuários na página:', users.data.length);
    
    // Filtrar por role
    const students = userService.filterByRole('student');
    console.log('Estudantes:', students.length);
    
    // Usar namespace
    console.log('Data formatada:', Utils.formatDate(new Date()));
    console.log('ID gerado:', Utils.generateId());
    console.log('Email válido:', Utils.Validator.isEmail('test@example.com'));
    
    // Enrollment service
    const enrollmentService = new EnrollmentService();
    await enrollmentService.enroll(1, 101);
})();

// Export
export {
    User,
    Course,
    Repository,
    UserService,
    EnrollmentService,
    Utils,
    UserRole,
    CourseLevel,
    ApiResponse,
    PaginatedResponse
};
