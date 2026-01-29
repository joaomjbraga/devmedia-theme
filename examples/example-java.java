// Java - Spring Boot Example
package com.devmedia.app;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.*;
import org.springframework.web.bind.annotation.*;
import javax.persistence.*;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "courses")
public class Course {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    private Double price;
    
    @ManyToOne
    @JoinColumn(name = "instructor_id")
    private User instructor;
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
}

@Service
public class CourseService {
    @Autowired
    private CourseRepository repository;
    
    @Transactional
    public Course createCourse(Course course) {
        if (course.getTitle() == null || course.getTitle().isEmpty()) {
            throw new IllegalArgumentException("Title is required");
        }
        return repository.save(course);
    }
    
    public List<Course> findAll() {
        return repository.findAll();
    }
}

@RestController
@RequestMapping("/api/courses")
public class CourseController {
    @Autowired
    private CourseService service;
    
    @GetMapping
    public ResponseEntity<List<Course>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }
    
    @PostMapping
    public ResponseEntity<Course> create(@RequestBody Course course) {
        Course created = service.createCourse(course);
        return ResponseEntity.status(201).body(created);
    }
}
