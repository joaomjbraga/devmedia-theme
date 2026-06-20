/**
 * Kotlin example - Note-taking app with coroutines and flows
 */
package com.devmedia.example

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.io.File
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.UUID
import kotlin.system.measureTimeMillis

// ---------- Data Classes ----------

data class Note(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val content: String,
    val tags: List<String> = emptyList(),
    val createdAt: LocalDateTime = LocalDateTime.now(),
    val updatedAt: LocalDateTime = LocalDateTime.now(),
    val isPinned: Boolean = false,
)

data class NoteStats(
    val total: Int,
    val pinned: Int,
    val averageLength: Double,
    val mostUsedTag: String?,
)

// ---------- Sealed Class ----------

sealed class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error(val message: String, val exception: Throwable? = null) : Result<Nothing>()
    data object Loading : Result<Nothing>()
}

// ---------- Repository ----------

interface NoteRepository {
    suspend fun findAll(): List<Note>
    suspend fun findById(id: String): Note?
    suspend fun save(note: Note): Note
    suspend fun delete(id: String): Boolean
    suspend fun search(query: String): List<Note>
}

class InMemoryNoteRepository : NoteRepository {
    private val notes = mutableListOf<Note>()

    override suspend fun findAll(): List<Note> {
        delay(50) // simulate async
        return notes.sortedByDescending { it.updatedAt }
    }

    override suspend fun findById(id: String): Note? {
        delay(30)
        return notes.find { it.id == id }
    }

    override suspend fun save(note: Note): Note {
        delay(50)
        val index = notes.indexOfFirst { it.id == note.id }
        val saved = if (index >= 0) {
            val updated = note.copy(updatedAt = LocalDateTime.now())
            notes[index] = updated
            updated
        } else {
            notes.add(note)
            note
        }
        return saved
    }

    override suspend fun delete(id: String): Boolean {
        delay(40)
        return notes.removeAll { it.id == id }
    }

    override suspend fun search(query: String): List<Note> {
        delay(30)
        val q = query.lowercase()
        return notes.filter {
            it.title.lowercase().contains(q) ||
            it.content.lowercase().contains(q) ||
            it.tags.any { tag -> tag.lowercase().contains(q) }
        }
    }
}

// ---------- Service ----------

class NoteService(private val repository: NoteRepository) {
    private val _notesFlow = MutableStateFlow<List<Note>>(emptyList())
    val notesFlow: StateFlow<List<Note>> = _notesFlow.asStateFlow()

    suspend fun loadNotes() {
        val notes = repository.findAll()
        _notesFlow.value = notes
    }

    suspend fun createNote(title: String, content: String, tags: List<String> = emptyList()): Result<Note> {
        return try {
            require(title.isNotBlank()) { "Title must not be blank" }

            val note = Note(
                title = title.trim(),
                content = content.trim(),
                tags = tags.map { it.trim().lowercase() },
            )

            val saved = repository.save(note)
            loadNotes()
            Result.Success(saved)
        } catch (e: Exception) {
            Result.Error("Failed to create note", e)
        }
    }

    suspend fun updateNote(note: Note): Result<Note> {
        return try {
            val saved = repository.save(note)
            loadNotes()
            Result.Success(saved)
        } catch (e: Exception) {
            Result.Error("Failed to update note", e)
        }
    }

    suspend fun deleteNote(id: String): Result<Boolean> {
        return try {
            val deleted = repository.delete(id)
            loadNotes()
            Result.Success(deleted)
        } catch (e: Exception) {
            Result.Error("Failed to delete note", e)
        }
    }

    suspend fun togglePin(id: String): Result<Note> {
        val note = repository.findById(id) ?: return Result.Error("Note not found")
        return updateNote(note.copy(isPinned = !note.isPinned))
    }

    fun getStats(notes: List<Note>): NoteStats {
        val allTags = notes.flatMap { it.tags }
        val tagCounts = allTags.groupingBy { it }.eachCount()
        val mostUsedTag = tagCounts.maxByOrNull { it.value }?.key
        val avgLength = if (notes.isNotEmpty()) {
            notes.map { it.content.length }.average()
        } else 0.0

        return NoteStats(
            total = notes.size,
            pinned = notes.count { it.isPinned },
            averageLength = avgLength,
            mostUsedTag = mostUsedTag,
        )
    }
}

// ---------- Extensions ----------

fun Note.formatted(): String = buildString {
    val formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")
    appendLine("┌──────────────────────────────────")
    appendLine("│ ${if (isPinned) "📌" else "  "} ${title}")
    appendLine("├──────────────────────────────────")
    appendLine("│ ${content.take(50)}${if (content.length > 50) "..." else ""}")
    appendLine("├──────────────────────────────────")
    appendLine("│ Tags: ${tags.joinToString(", ").ifEmpty { "none" }}")
    appendLine("│ Updated: ${updatedAt.format(formatter)}")
    appendLine("└──────────────────────────────────")
}

fun List<Note>.exportToMarkdown(): String = buildString {
    appendLine("# Notes Export")
    appendLine("")
    appendLine("Generated: ${LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME)}")
    appendLine("")
    forEachIndexed { index, note ->
        appendLine("## ${index + 1}. ${note.title}")
        appendLine("")
        appendLine(note.content)
        appendLine("")
        if (note.tags.isNotEmpty()) {
            appendLine("Tags: ${note.tags.joinToString(", ") { "`$it`" }}")
            appendLine("")
        }
        appendLine("---")
        appendLine("")
    }
}

// ---------- Top-level Function ----------

suspend fun <T> withRetry(
    maxRetries: Int = 3,
    delayMs: Long = 100L,
    block: suspend () -> T
): T {
    var lastException: Exception? = null
    for (attempt in 1..maxRetries) {
        try {
            return block()
        } catch (e: Exception) {
            lastException = e
            if (attempt < maxRetries) {
                delay(delayMs * attempt)
            }
        }
    }
    throw lastException ?: RuntimeException("Retry failed")
}

// ---------- Main ----------

fun main() = runBlocking {
    println("📝 DevMedia Notes App (Kotlin Example)")
    println("═".repeat(40))

    val repository = InMemoryNoteRepository()
    val service = NoteService(repository)

    // Create notes
    service.createNote(
        title = "Kotlin Coroutines Guide",
        content = "Coroutines are great for async programming. They allow sequential code while being non-blocking.",
        tags = listOf("kotlin", "coroutines", "async"),
    )

    service.createNote(
        title = "Clean Architecture",
        content = "Separation of concerns is key. Domain, data, and presentation layers should be independent.",
        tags = listOf("architecture", "clean-code"),
    )

    service.createNote(
        title = "Shopping List",
        content = "Rice, beans, pasta, tomatoes, onions, garlic, olive oil",
        tags = listOf("personal"),
        pinned = true,
    )

    // Load and display
    service.loadNotes()
    service.notesFlow.collect { notes ->
        println("\n📋 All Notes:")
        notes.forEach { note ->
            println(note.formatted())
        }

        // Stats
        val stats = service.getStats(notes)
        println("📊 Stats:")
        println("  Total: ${stats.total}")
        println("  Pinned: ${stats.pinned}")
        println("  Avg length: ${"%.1f".format(stats.averageLength)} chars")
        println("  Most used tag: ${stats.mostUsedTag ?: "none"}")

        // Markdown export
        println("\n📄 Markdown Export (first 200 chars):")
        val md = notes.exportToMarkdown()
        println(md.take(200) + "...")

        // Search
        println("\n🔍 Search result for 'kotlin':")
        val searchResults = repository.search("kotlin")
        searchResults.forEach { println("  • ${it.title}") }

        // Measure
        val time = measureTimeMillis {
            withRetry { repository.findAll() }
        }
        println("\n⏱️  Query took ${time}ms")

        // Cancel after showing results
        coroutineContext.job.cancel()
    }
}
