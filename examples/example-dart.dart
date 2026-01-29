// Dart/Flutter - Complete Example
import 'dart:async';
import 'dart:convert';

// Model
class Course {
  final int id;
  final String title;
  final String description;
  final double price;
  final String instructor;
  
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.instructor,
  });
  
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      instructor: json['instructor'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'instructor': instructor,
  };
}

// Service
class CourseService {
  final String baseUrl = 'https://api.devmedia.com.br';
  
  Future<List<Course>> fetchCourses() async {
    // Simulated API call
    await Future.delayed(Duration(seconds: 1));
    
    final mockData = [
      {'id': 1, 'title': 'Flutter Básico', 'description': 'Aprenda Flutter', 'price': 299.90, 'instructor': 'João'},
      {'id': 2, 'title': 'Dart Avançado', 'description': 'Dart avançado', 'price': 399.90, 'instructor': 'Maria'},
    ];
    
    return mockData.map((json) => Course.fromJson(json)).toList();
  }
}

// Usage
void main() async {
  final service = CourseService();
  final courses = await service.fetchCourses();
  
  print('Total courses: ${courses.length}');
  for (var course in courses) {
    print('${course.title} - R\$ ${course.price}');
  }
}
