// Kotlin - Complete Example
package com.devmedia.app

import kotlinx.coroutines.*

// Data class
data class Course(
    val id: Int,
    val title: String,
    val description: String,
    val price: Double,
    val instructor: String,
    val level: CourseLevel
)

// Enum
enum class CourseLevel {
    BEGINNER, INTERMEDIATE, ADVANCED
}

// Sealed class for results
sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String) : Result<Nothing>()
    object Loading : Result<Nothing>()
}

// Repository
class CourseRepository {
    private val courses = mutableListOf<Course>()
    
    suspend fun getCourses(): Result<List<Course>> = withContext(Dispatchers.IO) {
        delay(500)
        Result.Success(courses.toList())
    }
    
    fun add(course: Course) {
        courses.add(course)
    }
}

// Extension function
fun List<Course>.filterByLevel(level: CourseLevel) = filter { it.level == level }

// Main
fun main() = runBlocking {
    val repo = CourseRepository()
    
    repo.add(Course(1, "Kotlin Básico", "Aprenda Kotlin", 299.90, "João", CourseLevel.BEGINNER))
    repo.add(Course(2, "Kotlin Avançado", "Kotlin avançado", 499.90, "Maria", CourseLevel.ADVANCED))
    
    when (val result = repo.getCourses()) {
        is Result.Success -> {
            println("Total: ${result.data.size}")
            result.data.forEach { println(it.title) }
        }
        is Result.Error -> println("Error: ${result.message}")
        Result.Loading -> println("Loading...")
    }
}
