// ============================================
// React - Componentes Modernos com Hooks
// ============================================

import React, { useState, useEffect, useCallback, useMemo, useRef, useContext, createContext } from 'react';

// Context API
const ThemeContext = createContext({
    theme: 'light',
    toggleTheme: () => {}
});

const UserContext = createContext({
    user: null,
    setUser: () => {}
});

// Custom Hook
function useLocalStorage(key, initialValue) {
    const [value, setValue] = useState(() => {
        try {
            const item = window.localStorage.getItem(key);
            return item ? JSON.parse(item) : initialValue;
        } catch (error) {
            console.error(error);
            return initialValue;
        }
    });

    const setStoredValue = useCallback((newValue) => {
        try {
            setValue(newValue);
            window.localStorage.setItem(key, JSON.stringify(newValue));
        } catch (error) {
            console.error(error);
        }
    }, [key]);

    return [value, setStoredValue];
}

// Custom Hook para API
function useFetch(url) {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        let isMounted = true;

        const fetchData = async () => {
            try {
                setLoading(true);
                const response = await fetch(url);
                const json = await response.json();
                
                if (isMounted) {
                    setData(json);
                    setError(null);
                }
            } catch (err) {
                if (isMounted) {
                    setError(err.message);
                }
            } finally {
                if (isMounted) {
                    setLoading(false);
                }
            }
        };

        fetchData();

        return () => {
            isMounted = false;
        };
    }, [url]);

    return { data, loading, error };
}

// Componente de Contador
const Counter = ({ initialValue = 0, step = 1, onValueChange }) => {
    const [count, setCount] = useState(initialValue);
    const [history, setHistory] = useState([initialValue]);

    useEffect(() => {
        console.log(`Count changed: ${count}`);
        onValueChange?.(count);
    }, [count, onValueChange]);

    const increment = useCallback(() => {
        setCount(prev => {
            const newValue = prev + step;
            setHistory(h => [...h, newValue]);
            return newValue;
        });
    }, [step]);

    const decrement = useCallback(() => {
        setCount(prev => {
            const newValue = Math.max(0, prev - step);
            setHistory(h => [...h, newValue]);
            return newValue;
        });
    }, [step]);

    const reset = () => {
        setCount(initialValue);
        setHistory([initialValue]);
    };

    return (
        <div className="counter">
            <h2>Contador: {count}</h2>
            <div className="buttons">
                <button onClick={decrement}>- {step}</button>
                <button onClick={reset}>Reset</button>
                <button onClick={increment}>+ {step}</button>
            </div>
            {history.length > 1 && (
                <p className="history">
                    Histórico: {history.join(' → ')}
                </p>
            )}
        </div>
    );
};

// Componente de Lista de Cursos
const CourseList = () => {
    const [courses, setCourses] = useState([]);
    const [filter, setFilter] = useState('');
    const [sortBy, setSortBy] = useState('title');
    const searchInputRef = useRef(null);

    useEffect(() => {
        // Simular fetch de dados
        const mockCourses = [
            { id: 1, title: 'React Básico', price: 299.90, level: 'beginner', students: 1250 },
            { id: 2, title: 'React Avançado', price: 499.90, level: 'advanced', students: 780 },
            { id: 3, title: 'JavaScript ES6+', price: 349.90, level: 'intermediate', students: 2100 },
            { id: 4, title: 'TypeScript', price: 399.90, level: 'intermediate', students: 950 },
        ];
        setCourses(mockCourses);
    }, []);

    // useMemo para filtrar e ordenar
    const filteredAndSortedCourses = useMemo(() => {
        let result = courses.filter(course =>
            course.title.toLowerCase().includes(filter.toLowerCase())
        );

        result.sort((a, b) => {
            if (sortBy === 'price') return a.price - b.price;
            if (sortBy === 'students') return b.students - a.students;
            return a.title.localeCompare(b.title);
        });

        return result;
    }, [courses, filter, sortBy]);

    const handleSearch = (e) => {
        setFilter(e.target.value);
    };

    const focusSearch = () => {
        searchInputRef.current?.focus();
    };

    return (
        <div className="course-list">
            <div className="controls">
                <input
                    ref={searchInputRef}
                    type="text"
                    placeholder="Buscar cursos..."
                    value={filter}
                    onChange={handleSearch}
                />
                <button onClick={focusSearch}>Focar busca</button>
                
                <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
                    <option value="title">Título</option>
                    <option value="price">Preço</option>
                    <option value="students">Alunos</option>
                </select>
            </div>

            <div className="courses">
                {filteredAndSortedCourses.map(course => (
                    <CourseCard key={course.id} course={course} />
                ))}
            </div>

            {filteredAndSortedCourses.length === 0 && (
                <p className="empty">Nenhum curso encontrado</p>
            )}
        </div>
    );
};

// Componente de Card
const CourseCard = React.memo(({ course }) => {
    const [enrolled, setEnrolled] = useState(false);

    const handleEnroll = () => {
        setEnrolled(true);
        console.log(`Enrolled in: ${course.title}`);
    };

    return (
        <div className={`course-card ${enrolled ? 'enrolled' : ''}`}>
            <h3>{course.title}</h3>
            <div className="course-info">
                <span className={`level ${course.level}`}>
                    {course.level}
                </span>
                <span className="students">
                    👥 {course.students.toLocaleString()}
                </span>
            </div>
            <p className="price">
                R$ {course.price.toFixed(2)}
            </p>
            <button
                onClick={handleEnroll}
                disabled={enrolled}
            >
                {enrolled ? 'Matriculado ✓' : 'Matricular'}
            </button>
        </div>
    );
});

// Componente Principal com Context
const App = () => {
    const [theme, setTheme] = useLocalStorage('theme', 'light');
    const [user, setUser] = useState(null);

    const toggleTheme = useCallback(() => {
        setTheme(prev => prev === 'light' ? 'dark' : 'light');
    }, [setTheme]);

    useEffect(() => {
        document.body.className = theme;
    }, [theme]);

    return (
        <ThemeContext.Provider value={{ theme, toggleTheme }}>
            <UserContext.Provider value={{ user, setUser }}>
                <div className={`app theme-${theme}`}>
                    <Header />
                    <main>
                        <Counter
                            initialValue={0}
                            step={5}
                            onValueChange={(value) => console.log('New value:', value)}
                        />
                        <CourseList />
                    </main>
                </div>
            </UserContext.Provider>
        </ThemeContext.Provider>
    );
};

// Componente Header usando Context
const Header = () => {
    const { theme, toggleTheme } = useContext(ThemeContext);
    const { user } = useContext(UserContext);

    return (
        <header className="header">
            <h1>DevMedia</h1>
            <div className="header-actions">
                {user && <span>Olá, {user.name}</span>}
                <button onClick={toggleTheme}>
                    {theme === 'light' ? '🌙' : '☀️'}
                </button>
            </div>
        </header>
    );
};

// Higher Order Component
function withLoading(Component) {
    return function WithLoadingComponent({ isLoading, ...props }) {
        if (isLoading) {
            return <div className="loading">Carregando...</div>;
        }
        return <Component {...props} />;
    };
}

// Exemplo de uso do HOC
const CourseListWithLoading = withLoading(CourseList);

// Componente com useReducer
function useCounter(initialValue = 0) {
    const reducer = (state, action) => {
        switch (action.type) {
            case 'INCREMENT':
                return { count: state.count + (action.payload || 1) };
            case 'DECREMENT':
                return { count: Math.max(0, state.count - (action.payload || 1)) };
            case 'RESET':
                return { count: initialValue };
            default:
                return state;
        }
    };

    const [state, dispatch] = React.useReducer(reducer, { count: initialValue });

    return {
        count: state.count,
        increment: (value) => dispatch({ type: 'INCREMENT', payload: value }),
        decrement: (value) => dispatch({ type: 'DECREMENT', payload: value }),
        reset: () => dispatch({ type: 'RESET' })
    };
}

export default App;
export {
    Counter,
    CourseList,
    CourseCard,
    Header,
    useFetch,
    useLocalStorage,
    useCounter,
    withLoading
};
