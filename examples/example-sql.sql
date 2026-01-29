-- SQL/MySQL - Complete Database Example

-- Create Database
CREATE DATABASE IF NOT EXISTS devmedia_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE devmedia_db;

-- Users Table
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'instructor', 'student', 'guest') DEFAULT 'student',
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB;

-- Courses Table
CREATE TABLE courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    instructor_id INT NOT NULL,
    level ENUM('beginner', 'intermediate', 'advanced') DEFAULT 'beginner',
    published BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_instructor (instructor_id),
    FULLTEXT INDEX idx_search (title, description)
) ENGINE=InnoDB;

-- Enrollments Table
CREATE TABLE enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress DECIMAL(5, 2) DEFAULT 0.00,
    status ENUM('active', 'completed', 'cancelled') DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE KEY unique_enrollment (user_id, course_id)
) ENGINE=InnoDB;

-- View for Course Statistics
CREATE OR REPLACE VIEW course_statistics AS
SELECT 
    c.id,
    c.title,
    COUNT(DISTINCT e.user_id) AS total_students,
    AVG(e.progress) AS avg_progress,
    c.price,
    u.name AS instructor_name
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
JOIN users u ON c.instructor_id = u.id
WHERE c.published = TRUE
GROUP BY c.id;

-- Stored Procedure
DELIMITER //
CREATE PROCEDURE enroll_student(
    IN p_user_id INT,
    IN p_course_id INT
)
BEGIN
    DECLARE v_exists INT;
    
    SELECT COUNT(*) INTO v_exists
    FROM enrollments
    WHERE user_id = p_user_id AND course_id = p_course_id;
    
    IF v_exists = 0 THEN
        INSERT INTO enrollments (user_id, course_id)
        VALUES (p_user_id, p_course_id);
        SELECT 'Enrolled successfully' AS result;
    ELSE
        SELECT 'Already enrolled' AS result;
    END IF;
END //
DELIMITER ;

-- Trigger
DELIMITER //
CREATE TRIGGER update_completion
BEFORE UPDATE ON enrollments
FOR EACH ROW
BEGIN
    IF NEW.progress >= 100 AND OLD.progress < 100 THEN
        SET NEW.status = 'completed';
    END IF;
END //
DELIMITER ;

-- Sample Queries
-- Top 5 most popular courses
SELECT 
    c.title,
    COUNT(e.id) AS enrollments,
    AVG(e.progress) AS avg_progress
FROM courses c
JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id
ORDER BY enrollments DESC
LIMIT 5;

-- Revenue by instructor
SELECT 
    u.name,
    COUNT(DISTINCT c.id) AS courses,
    SUM(c.price) AS revenue
FROM users u
JOIN courses c ON u.id = c.instructor_id
WHERE u.role = 'instructor'
GROUP BY u.id
ORDER BY revenue DESC;
