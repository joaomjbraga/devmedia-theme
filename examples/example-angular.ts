// Angular - Complete Example

import { Component, OnInit, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';

// Model
export interface Course {
  id: number;
  title: string;
  description: string;
  price: number;
  instructor: string;
  level: 'beginner' | 'intermediate' | 'advanced';
}

// Service
@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = 'https://api.devmedia.com.br/courses';

  constructor(private http: HttpClient) {}

  getCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(this.apiUrl).pipe(
      map(response => response),
      catchError(error => {
        console.error('Error:', error);
        throw error;
      })
    );
  }

  createCourse(course: Partial<Course>): Observable<Course> {
    return this.http.post<Course>(this.apiUrl, course);
  }
}

// Component
@Component({
  selector: 'app-course-list',
  template: `
    <div class="course-list">
      <h1>Cursos DevMedia</h1>
      
      <div *ngIf="loading">Carregando...</div>
      
      <div *ngIf="!loading" class="courses">
        <div *ngFor="let course of courses" class="course-card">
          <h3>{{ course.title }}</h3>
          <p>{{ course.description }}</p>
          <span class="price">R$ {{ course.price | number:'1.2-2' }}</span>
          <button (click)="enroll(course.id)">Matricular</button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .course-list {
      padding: 20px;
    }
    .courses {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 20px;
    }
    .course-card {
      border: 1px solid #6F9A35;
      padding: 20px;
      border-radius: 8px;
    }
  `]
})
export class CourseListComponent implements OnInit {
  courses: Course[] = [];
  loading = false;

  constructor(private courseService: CourseService) {}

  ngOnInit(): void {
    this.loadCourses();
  }

  loadCourses(): void {
    this.loading = true;
    this.courseService.getCourses().subscribe({
      next: (courses) => {
        this.courses = courses;
        this.loading = false;
      },
      error: (error) => {
        console.error(error);
        this.loading = false;
      }
    });
  }

  enroll(courseId: number): void {
    console.log('Enrolling in course:', courseId);
  }
}
