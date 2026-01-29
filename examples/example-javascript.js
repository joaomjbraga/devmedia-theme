// ============================================
// JavaScript Moderno - ES6+ Features
// ============================================

// Constantes e variáveis
const API_URL = 'https://api.devmedia.com.br';
const MAX_RETRIES = 3;
let totalUsers = 0;
let isLoading = false;

// ============================================
// Classes e Herança
// ============================================

/**
 * Classe base para entidades
 */
class Entity {
    constructor(id) {
        this.id = id;
        this.createdAt = new Date();
    }

    getAge() {
        const now = new Date();
        const diff = now - this.createdAt;
        return Math.floor(diff / 1000); // segundos
    }
}

/**
 * Classe para gerenciar usuários
 * @extends Entity
 */
class User extends Entity {
    constructor(id, name, email, role = 'user') {
        super(id);
        this.name = name;
        this.email = email;
        this.role = role;
        this.active = true;
    }

    // Getter
    get displayName() {
        return `${this.name} (${this.email})`;
    }

    // Setter
    set displayName(value) {
        const [name, email] = value.split(' - ');
        this.name = name;
        this.email = email;
    }

    // Método estático
    static fromJSON(json) {
        return new User(json.id, json.name, json.email, json.role);
    }

    // Método de instância
    hasPermission(permission) {
        const permissions = {
            admin: ['read', 'write', 'delete'],
            user: ['read', 'write'],
            guest: ['read']
        };
        return permissions[this.role]?.includes(permission) ?? false;
    }
}

// ============================================
// Arrow Functions e Async/Await
// ============================================

class UserManager {
    constructor(apiUrl = API_URL) {
        this.apiUrl = apiUrl;
        this.users = [];
        this.cache = new Map();
    }

    // Arrow function para manter o contexto
    fetchUsers = async () => {
        isLoading = true;
        
        try {
            const response = await fetch(`${this.apiUrl}/users`);
            
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const data = await response.json();
            this.users = data.users.map(User.fromJSON);
            totalUsers = this.users.length;
            
            return this.users;
        } catch (error) {
            console.error('Erro ao buscar usuários:', error);
            throw error;
        } finally {
            isLoading = false;
        }
    }

    // Método com retry automático
    async fetchWithRetry(url, retries = MAX_RETRIES) {
        for (let i = 0; i < retries; i++) {
            try {
                return await fetch(url);
            } catch (error) {
                if (i === retries - 1) throw error;
                await this.delay(1000 * (i + 1));
            }
        }
    }

    delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

    // Template literals
    getUserInfo(userId) {
        const user = this.users.find(u => u.id === userId);
        
        if (!user) {
            return `Usuário #${userId} não encontrado`;
        }
        
        return `
            Nome: ${user.name}
            Email: ${user.email}
            Role: ${user.role}
            Ativo: ${user.active ? 'Sim' : 'Não'}
            Criado há: ${user.getAge()} segundos
        `.trim();
    }

    // Destructuring e spread operator
    updateUser(userId, updates) {
        const userIndex = this.users.findIndex(u => u.id === userId);
        
        if (userIndex === -1) {
            throw new Error('Usuário não encontrado');
        }
        
        const oldUser = this.users[userIndex];
        const updatedUser = { ...oldUser, ...updates };
        this.users[userIndex] = User.fromJSON(updatedUser);
        
        return this.users[userIndex];
    }

    // Array methods modernos
    filterActiveUsers() {
        return this.users.filter(user => user.active);
    }

    getUsersByRole(role) {
        return this.users.filter(user => user.role === role);
    }

    sortUsersByName() {
        return [...this.users].sort((a, b) => a.name.localeCompare(b.name));
    }

    // Map, filter, reduce
    getUserStats() {
        const stats = this.users.reduce((acc, user) => {
            acc.total++;
            acc.byRole[user.role] = (acc.byRole[user.role] || 0) + 1;
            if (user.active) acc.active++;
            return acc;
        }, { total: 0, active: 0, byRole: {} });

        return stats;
    }
}

// ============================================
// Higher Order Functions
// ============================================

const createLogger = (prefix) => {
    return (message) => {
        console.log(`[${prefix}] ${new Date().toISOString()} - ${message}`);
    };
};

const userLogger = createLogger('USER');
const errorLogger = createLogger('ERROR');

// Decorator function
function withLogging(fn) {
    return async function(...args) {
        userLogger(`Calling ${fn.name} with args: ${JSON.stringify(args)}`);
        try {
            const result = await fn.apply(this, args);
            userLogger(`${fn.name} completed successfully`);
            return result;
        } catch (error) {
            errorLogger(`${fn.name} failed: ${error.message}`);
            throw error;
        }
    };
}

// ============================================
// Promises e Promise.all
// ============================================

class DataService {
    constructor() {
        this.endpoints = {
            users: '/users',
            courses: '/courses',
            enrollments: '/enrollments'
        };
    }

    async fetchAll() {
        const promises = Object.entries(this.endpoints).map(([key, endpoint]) => {
            return fetch(`${API_URL}${endpoint}`)
                .then(res => res.json())
                .then(data => ({ [key]: data }));
        });

        const results = await Promise.all(promises);
        return Object.assign({}, ...results);
    }

    async fetchSequential() {
        const data = {};
        
        for (const [key, endpoint] of Object.entries(this.endpoints)) {
            const response = await fetch(`${API_URL}${endpoint}`);
            data[key] = await response.json();
        }
        
        return data;
    }

    // Promise.race para timeout
    async fetchWithTimeout(url, timeout = 5000) {
        const fetchPromise = fetch(url);
        const timeoutPromise = new Promise((_, reject) => {
            setTimeout(() => reject(new Error('Timeout')), timeout);
        });

        return Promise.race([fetchPromise, timeoutPromise]);
    }
}

// ============================================
// Generators e Iterators
// ============================================

function* userGenerator(users) {
    for (const user of users) {
        yield user;
    }
}

function* fibonacci(n) {
    let [a, b] = [0, 1];
    for (let i = 0; i < n; i++) {
        yield a;
        [a, b] = [b, a + b];
    }
}

// ============================================
// Módulos ES6
// ============================================

export { User, UserManager, DataService };
export default UserManager;

// ============================================
// Exemplo de Uso
// ============================================

(async function main() {
    console.log('=== DevMedia - Sistema de Gerenciamento de Usuários ===\n');

    const manager = new UserManager();

    // Criar usuários de exemplo
    const users = [
        new User(1, 'João Silva', 'joao@devmedia.com.br', 'admin'),
        new User(2, 'Maria Santos', 'maria@devmedia.com.br', 'user'),
        new User(3, 'Pedro Oliveira', 'pedro@devmedia.com.br', 'user'),
        new User(4, 'Ana Costa', 'ana@devmedia.com.br', 'guest')
    ];

    manager.users = users;

    // Usar métodos
    console.log('Usuários ativos:');
    manager.filterActiveUsers().forEach(user => {
        console.log(`  - ${user.displayName}`);
    });

    console.log('\nUsuários por role:');
    const stats = manager.getUserStats();
    console.log(stats);

    // Usar generator
    console.log('\nIterando com generator:');
    const gen = userGenerator(manager.users);
    for (const user of gen) {
        console.log(`  - ${user.name}`);
    }

    // Template literals
    console.log('\nInformações do usuário #1:');
    console.log(manager.getUserInfo(1));

    // Fibonacci
    console.log('\nPrimeiros 10 números de Fibonacci:');
    console.log([...fibonacci(10)].join(', '));

    // Destructuring
    const [first, second, ...rest] = manager.users;
    console.log(`\nPrimeiro: ${first.name}, Segundo: ${second.name}`);
    console.log(`Restantes: ${rest.length} usuários`);

    // Optional chaining e nullish coalescing
    const userEmail = manager.users.find(u => u.id === 999)?.email ?? 'Email não encontrado';
    console.log(`\nEmail do usuário #999: ${userEmail}`);

})();
