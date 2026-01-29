-- ==========================================
-- EXEMPLO SQL - DevMedia Theme
-- ==========================================

-- Criação de Database
CREATE DATABASE IF NOT EXISTS devmedia_cursos;
USE devmedia_cursos;

-- Tabela de Estudantes
CREATE TABLE estudantes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT true,
    nivel ENUM('Iniciante', 'Intermediário', 'Avançado') DEFAULT 'Iniciante',
    progresso DECIMAL(5,2) DEFAULT 0.00,
    INDEX idx_email (email),
    INDEX idx_nivel (nivel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela de Cursos
CREATE TABLE cursos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    tecnologia VARCHAR(50) NOT NULL,
    duracao_horas INT NOT NULL,
    nivel VARCHAR(20) NOT NULL,
    preco DECIMAL(10,2) DEFAULT 0.00,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_tecnologia (tecnologia)
) ENGINE=InnoDB;

-- Tabela de Matrículas (relacionamento N:N)
CREATE TABLE matriculas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    estudante_id INT NOT NULL,
    curso_id INT NOT NULL,
    data_matricula DATETIME DEFAULT CURRENT_TIMESTAMP,
    progresso_curso DECIMAL(5,2) DEFAULT 0.00,
    concluido BOOLEAN DEFAULT false,
    nota_final DECIMAL(4,2),
    FOREIGN KEY (estudante_id) REFERENCES estudantes(id) ON DELETE CASCADE,
    FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE CASCADE,
    UNIQUE KEY unique_matricula (estudante_id, curso_id)
) ENGINE=InnoDB;

-- Tabela de Aulas
CREATE TABLE aulas (
    id INT PRIMARY KEY AUTO_INCREMENT,
    curso_id INT NOT NULL,
    titulo VARCHAR(200) NOT NULL,
    ordem INT NOT NULL,
    duracao_minutos INT NOT NULL,
    video_url VARCHAR(500),
    conteudo_texto LONGTEXT,
    FOREIGN KEY (curso_id) REFERENCES cursos(id) ON DELETE CASCADE,
    INDEX idx_curso_ordem (curso_id, ordem)
) ENGINE=InnoDB;

-- INSERT de dados de exemplo
INSERT INTO estudantes (nome, email, nivel, progresso) VALUES
('João Silva', 'joao.silva@email.com', 'Intermediário', 45.50),
('Maria Santos', 'maria.santos@email.com', 'Avançado', 78.30),
('Pedro Costa', 'pedro.costa@email.com', 'Iniciante', 12.00),
('Ana Oliveira', 'ana.oliveira@email.com', 'Intermediário', 56.75);

INSERT INTO cursos (titulo, descricao, tecnologia, duracao_horas, nivel, preco) VALUES
('HTML e CSS Completo', 'Aprenda desenvolvimento front-end do zero', 'HTML/CSS', 40, 'Iniciante', 199.90),
('JavaScript Moderno', 'JavaScript ES6+ e além', 'JavaScript', 60, 'Intermediário', 299.90),
('React do Zero ao Avançado', 'Domine React e suas ferramentas', 'React', 80, 'Avançado', 399.90),
('Node.js e Express', 'Back-end com JavaScript', 'Node.js', 70, 'Intermediário', 349.90),
('Python para Iniciantes', 'Fundamentos de Python', 'Python', 50, 'Iniciante', 249.90);

INSERT INTO matriculas (estudante_id, curso_id, progresso_curso, concluido, nota_final) VALUES
(1, 1, 100.00, true, 9.5),
(1, 2, 65.00, false, NULL),
(2, 3, 100.00, true, 10.0),
(2, 4, 82.50, false, NULL),
(3, 1, 30.00, false, NULL),
(4, 2, 45.00, false, NULL);

-- SELECT básicos
SELECT * FROM estudantes;

SELECT nome, email, nivel 
FROM estudantes 
WHERE ativo = true
ORDER BY progresso DESC;

-- JOIN entre tabelas
SELECT 
    e.nome AS estudante,
    c.titulo AS curso,
    m.progresso_curso AS progresso,
    m.concluido,
    m.nota_final
FROM matriculas m
INNER JOIN estudantes e ON m.estudante_id = e.id
INNER JOIN cursos c ON m.curso_id = c.id
WHERE e.ativo = true
ORDER BY e.nome, c.titulo;

-- Agregações
SELECT 
    tecnologia,
    COUNT(*) AS total_cursos,
    AVG(duracao_horas) AS media_horas,
    SUM(duracao_horas) AS total_horas,
    MIN(preco) AS menor_preco,
    MAX(preco) AS maior_preco
FROM cursos
GROUP BY tecnologia
HAVING COUNT(*) > 0
ORDER BY total_cursos DESC;

-- Subconsultas
SELECT nome, email, progresso
FROM estudantes
WHERE progresso > (
    SELECT AVG(progresso) 
    FROM estudantes
);

-- Cursos mais populares
SELECT 
    c.titulo,
    c.tecnologia,
    COUNT(m.id) AS total_matriculas,
    AVG(m.progresso_curso) AS progresso_medio
FROM cursos c
LEFT JOIN matriculas m ON c.id = m.curso_id
GROUP BY c.id, c.titulo, c.tecnologia
ORDER BY total_matriculas DESC
LIMIT 5;

-- UPDATE com condições
UPDATE estudantes
SET nivel = CASE
    WHEN progresso >= 70 THEN 'Avançado'
    WHEN progresso >= 30 THEN 'Intermediário'
    ELSE 'Iniciante'
END
WHERE ativo = true;

-- UPDATE de progresso
UPDATE estudantes e
INNER JOIN (
    SELECT estudante_id, AVG(progresso_curso) AS media_progresso
    FROM matriculas
    GROUP BY estudante_id
) m ON e.id = m.estudante_id
SET e.progresso = m.media_progresso;

-- DELETE com segurança
DELETE FROM matriculas
WHERE concluido = true 
  AND data_matricula < DATE_SUB(NOW(), INTERVAL 2 YEAR);

-- VIEW para relatório
CREATE OR REPLACE VIEW vw_relatorio_estudantes AS
SELECT 
    e.id,
    e.nome,
    e.email,
    e.nivel,
    e.progresso,
    COUNT(m.id) AS total_cursos,
    SUM(CASE WHEN m.concluido = true THEN 1 ELSE 0 END) AS cursos_concluidos,
    AVG(m.nota_final) AS media_notas
FROM estudantes e
LEFT JOIN matriculas m ON e.id = m.estudante_id
WHERE e.ativo = true
GROUP BY e.id, e.nome, e.email, e.nivel, e.progresso;

-- Consulta na VIEW
SELECT * FROM vw_relatorio_estudantes
WHERE cursos_concluidos > 0
ORDER BY media_notas DESC;

-- STORED PROCEDURE
DELIMITER //

CREATE PROCEDURE sp_matricular_estudante(
    IN p_estudante_id INT,
    IN p_curso_id INT
)
BEGIN
    DECLARE v_existe INT;
    
    -- Verifica se já existe matrícula
    SELECT COUNT(*) INTO v_existe
    FROM matriculas
    WHERE estudante_id = p_estudante_id 
      AND curso_id = p_curso_id;
    
    IF v_existe = 0 THEN
        INSERT INTO matriculas (estudante_id, curso_id)
        VALUES (p_estudante_id, p_curso_id);
        
        SELECT 'Matrícula realizada com sucesso!' AS mensagem;
    ELSE
        SELECT 'Estudante já matriculado neste curso!' AS mensagem;
    END IF;
END //

DELIMITER ;

-- TRIGGER para auditoria
CREATE TABLE auditoria_estudantes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    estudante_id INT,
    acao VARCHAR(10),
    data_acao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100)
);

DELIMITER //

CREATE TRIGGER trg_after_insert_estudante
AFTER INSERT ON estudantes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_estudantes (estudante_id, acao, usuario)
    VALUES (NEW.id, 'INSERT', USER());
END //

DELIMITER ;

-- Transações
START TRANSACTION;

UPDATE estudantes 
SET progresso = progresso + 10
WHERE id = 1;

UPDATE matriculas
SET progresso_curso = progresso_curso + 10
WHERE estudante_id = 1 AND concluido = false;

COMMIT;

-- Índices para performance
CREATE INDEX idx_estudantes_progresso ON estudantes(progresso);
CREATE INDEX idx_matriculas_concluido ON matriculas(concluido);
CREATE INDEX idx_cursos_nivel ON cursos(nivel);

-- Análise de performance
EXPLAIN SELECT 
    e.nome,
    c.titulo,
    m.progresso_curso
FROM estudantes e
INNER JOIN matriculas m ON e.id = m.estudante_id
INNER JOIN cursos c ON m.curso_id = c.id
WHERE e.progresso > 50
  AND c.tecnologia = 'React';
