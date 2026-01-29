// ==========================================
// EXEMPLO DE CÓDIGO - DevMedia Theme
// ==========================================

// JavaScript / TypeScript
function calcularMedia(notas) {
  // Comentário: calcula a média das notas
  const soma = notas.reduce((acc, nota) => acc + nota, 0);
  const media = soma / notas.length;
  return media;
}

const aluno = {
  nome: "João Silva",
  idade: 25,
  aprovado: true,
  notas: [8.5, 9.0, 7.5, 10.0]
};

console.log(`Média: ${calcularMedia(aluno.notas)}`);

// React Component
import React, { useState } from 'react';

const DevMediaCard = ({ title, description }) => {
  const [isActive, setIsActive] = useState(false);
  
  return (
    <div className="card" onClick={() => setIsActive(!isActive)}>
      <h2>{title}</h2>
      <p>{description}</p>
      {isActive && <span>Ativo!</span>}
    </div>
  );
};

export default DevMediaCard;

// Classes e OOP
class Estudante {
  constructor(nome, curso) {
    this.nome = nome;
    this.curso = curso;
    this.progresso = 0;
  }
  
  estudar(horas) {
    this.progresso += horas * 10;
    console.log(`${this.nome} estudou ${horas}h. Progresso: ${this.progresso}%`);
  }
}

const estudante = new Estudante("Maria", "Fullstack");
estudante.estudar(2);

// Async/Await
async function buscarCursos() {
  try {
    const response = await fetch('https://api.devmedia.com.br/cursos');
    const cursos = await response.json();
    return cursos;
  } catch (error) {
    console.error('Erro ao buscar cursos:', error);
    return null;
  }
}

// Arrow Functions e Array Methods
const tecnologias = ['JavaScript', 'React', 'Node.js', 'Python', 'SQL'];
const cursosDisponiveis = tecnologias
  .filter(tech => tech.includes('Script'))
  .map(tech => ({ nome: tech, nivel: 'Intermediário' }));

// Template Literals
const mensagem = `
  Bem-vindo à DevMedia!
  Aprenda: ${tecnologias.join(', ')}
  Total de tecnologias: ${tecnologias.length}
`;

// Operadores
const x = 10;
const y = 20;
const resultado = x + y * 2;
const estaAprovado = x >= 7 && y >= 7;
const temBonus = estaAprovado ? 'Sim' : 'Não';

// Destructuring
const { nome: nomeAluno, notas: notasAluno } = aluno;
const [primeira, ...resto] = tecnologias;

// Spread Operator
const novasTecnologias = [...tecnologias, 'Vue.js', 'Angular'];
const alunoCompleto = { ...aluno, mentor: 'DevMedia' };
