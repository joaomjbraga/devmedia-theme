# ==========================================
# EXEMPLO PYTHON - DevMedia Theme
# ==========================================

# Imports
from typing import List, Dict
import datetime

# Classe com decoradores
class Estudante:
    """Classe que representa um estudante da DevMedia"""
    
    def __init__(self, nome: str, idade: int):
        self.nome = nome
        self.idade = idade
        self.cursos_concluidos = []
        self.progresso = 0
    
    @property
    def nivel(self):
        """Retorna o nível baseado no progresso"""
        if self.progresso < 30:
            return "Iniciante"
        elif self.progresso < 70:
            return "Intermediário"
        else:
            return "Avançado"
    
    @staticmethod
    def calcular_media(notas: List[float]) -> float:
        """Calcula a média das notas"""
        return sum(notas) / len(notas) if notas else 0.0
    
    def estudar(self, horas: int) -> None:
        """Adiciona horas de estudo ao progresso"""
        self.progresso += horas * 5
        print(f"{self.nome} estudou {horas}h. Progresso: {self.progresso}%")

# Funções
def listar_tecnologias() -> List[str]:
    """Retorna lista de tecnologias disponíveis"""
    tecnologias = [
        'Python',
        'JavaScript',
        'React',
        'Node.js',
        'SQL',
        'Django'
    ]
    return tecnologias

def processar_dados(dados: Dict[str, any]) -> Dict[str, any]:
    """Processa os dados do estudante"""
    resultado = {
        'nome': dados.get('nome', 'Desconhecido'),
        'idade': dados.get('idade', 0),
        'ativo': True,
        'data_cadastro': datetime.datetime.now()
    }
    return resultado

# List Comprehension
numeros = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
pares = [n for n in numeros if n % 2 == 0]
quadrados = [n ** 2 for n in numeros]

# Dictionary Comprehension
tecnologias = listar_tecnologias()
cursos = {tech: f"Curso de {tech}" for tech in tecnologias}

# Lambda Functions
somar = lambda x, y: x + y
multiplicar = lambda x, y: x * y

# Operadores e Comparações
x = 10
y = 20
resultado = x + y * 2
esta_aprovado = x >= 7 and y >= 7
tem_bonus = "Sim" if esta_aprovado else "Não"

# String Formatting
nome = "João"
idade = 25
mensagem = f"""
Bem-vindo à DevMedia, {nome}!
Idade: {idade} anos
Tecnologias disponíveis: {len(tecnologias)}
"""

# Try/Except
def dividir(a: float, b: float) -> float:
    """Divide dois números com tratamento de erro"""
    try:
        resultado = a / b
        return resultado
    except ZeroDivisionError:
        print("Erro: Divisão por zero!")
        return 0.0
    except Exception as e:
        print(f"Erro inesperado: {e}")
        return None
    finally:
        print("Operação concluída")

# Context Manager
with open('arquivo.txt', 'r') as arquivo:
    conteudo = arquivo.read()
    print(conteudo)

# Generators
def fibonacci(n: int):
    """Gera sequência de Fibonacci"""
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b

# Uso das classes e funções
estudante = Estudante("Maria Silva", 22)
estudante.estudar(5)
print(f"Nível: {estudante.nivel}")

notas = [8.5, 9.0, 7.5, 10.0]
media = Estudante.calcular_media(notas)
print(f"Média: {media:.2f}")

# Decoradores customizados
def log_execucao(func):
    """Decorador para logar execução de função"""
    def wrapper(*args, **kwargs):
        print(f"Executando {func.__name__}...")
        resultado = func(*args, **kwargs)
        print(f"{func.__name__} concluído!")
        return resultado
    return wrapper

@log_execucao
def processar_curso(nome_curso: str) -> Dict[str, any]:
    """Processa informações do curso"""
    return {
        'nome': nome_curso,
        'status': 'Ativo',
        'alunos': 1500
    }

# Type Hints avançados
from typing import Optional, Union, Callable

def buscar_estudante(id: int) -> Optional[Estudante]:
    """Busca estudante por ID"""
    # Implementação...
    return None

def processar_callback(
    dados: List[str], 
    callback: Callable[[str], str]
) -> List[str]:
    """Processa dados com callback"""
    return [callback(item) for item in dados]

# Constants
PI = 3.14159
VERSAO = "1.0.0"
DEBUG = True
