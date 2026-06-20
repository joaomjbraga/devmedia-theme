// Rust example - CLI todo application
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;
use std::fs;
use std::path::PathBuf;
use std::sync::Mutex;

// ---------- Data Types ----------

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
enum Priority {
    Low,
    Medium,
    High,
    Critical,
}

impl fmt::Display for Priority {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Priority::Low => write!(f, "LOW"),
            Priority::Medium => write!(f, "MEDIUM"),
            Priority::High => write!(f, "HIGH"),
            Priority::Critical => write!(f, "CRITICAL"),
        }
    }
}

impl TryFrom<&str> for Priority {
    type Error = String;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        match value.to_lowercase().as_str() {
            "low" => Ok(Priority::Low),
            "medium" => Ok(Priority::Medium),
            "high" => Ok(Priority::High),
            "critical" => Ok(Priority::Critical),
            _ => Err(format!("Invalid priority: {}", value)),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Task {
    id: u64,
    title: String,
    description: Option<String>,
    priority: Priority,
    completed: bool,
    tags: Vec<String>,
    created_at: chrono::DateTime<chrono::Utc>,
}

impl Task {
    fn new(id: u64, title: String, priority: Priority) -> Self {
        Self {
            id,
            title,
            description: None,
            priority,
            completed: false,
            tags: Vec::new(),
            created_at: chrono::Utc::now(),
        }
    }
}

impl fmt::Display for Task {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let status = if self.completed { "[x]" } else { "[ ]" };
        write!(
            f,
            "{} #{}: {} ({})",
            status, self.id, self.title, self.priority
        )
    }
}

// ---------- Error Handling ----------

#[derive(Debug)]
enum AppError {
    Io(std::io::Error),
    Serialization(serde_json::Error),
    NotFound(String),
    InvalidInput(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::Io(e) => write!(f, "IO error: {}", e),
            AppError::Serialization(e) => write!(f, "Serialization error: {}", e),
            AppError::NotFound(msg) => write!(f, "Not found: {}", msg),
            AppError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
        }
    }
}

impl From<std::io::Error> for AppError {
    fn from(e: std::io::Error) -> Self {
        AppError::Io(e)
    }
}

impl From<serde_json::Error> for AppError {
    fn from(e: serde_json::Error) -> Self {
        AppError::Serialization(e)
    }
}

type Result<T> = std::result::Result<T, AppError>;

// ---------- Repository ----------

trait TaskRepository {
    fn create(&mut self, title: String, priority: Priority) -> Result<Task>;
    fn get(&self, id: u64) -> Option<&Task>;
    fn list(&self) -> Vec<&Task>;
    fn update(&mut self, id: u64, f: Box<dyn FnOnce(&mut Task)>) -> Result<()>;
    fn delete(&mut self, id: u64) -> Result<Task>;
    fn save(&self) -> Result<()>;
}

struct JsonFileRepository {
    path: PathBuf,
    tasks: HashMap<u64, Task>,
    next_id: u64,
}

impl JsonFileRepository {
    fn new(path: PathBuf) -> Result<Self> {
        let (tasks, next_id) = if path.exists() {
            let content = fs::read_to_string(&path)?;
            let tasks: HashMap<u64, Task> = serde_json::from_str(&content)?;
            let next_id = tasks.keys().max().unwrap_or(&0) + 1;
            (tasks, next_id)
        } else {
            (HashMap::new(), 1)
        };

        Ok(Self {
            path,
            tasks,
            next_id,
        })
    }
}

impl TaskRepository for JsonFileRepository {
    fn create(&mut self, title: String, priority: Priority) -> Result<Task> {
        let task = Task::new(self.next_id, title, priority);
        self.next_id += 1;
        self.tasks.insert(task.id, task.clone());
        self.save()?;
        Ok(task)
    }

    fn get(&self, id: u64) -> Option<&Task> {
        self.tasks.get(&id)
    }

    fn list(&self) -> Vec<&Task> {
        let mut tasks: Vec<&Task> = self.tasks.values().collect();
        tasks.sort_by_key(|t| std::cmp::Reverse(t.priority.clone() as u8));
        tasks
    }

    fn update(&mut self, id: u64, f: Box<dyn FnOnce(&mut Task)>) -> Result<()> {
        let task = self
            .tasks
            .get_mut(&id)
            .ok_or_else(|| AppError::NotFound(format!("Task {} not found", id)))?;
        f(task);
        self.save()?;
        Ok(())
    }

    fn delete(&mut self, id: u64) -> Result<Task> {
        let task = self
            .tasks
            .remove(&id)
            .ok_or_else(|| AppError::NotFound(format!("Task {} not found", id)))?;
        self.save()?;
        Ok(task)
    }

    fn save(&self) -> Result<()> {
        let content = serde_json::to_string_pretty(&self.tasks)?;
        fs::write(&self.path, content)?;
        Ok(())
    }
}

// ---------- App ----------

struct App {
    repo: Mutex<Box<dyn TaskRepository>>,
}

impl App {
    fn new(repo: Box<dyn TaskRepository>) -> Self {
        Self {
            repo: Mutex::new(repo),
        }
    }

    fn add_task(&self, title: String, priority: Priority) -> Result<Task> {
        let mut repo = self.repo.lock().unwrap();
        repo.create(title, priority)
    }

    fn list_tasks(&self) -> Result<Vec<String>> {
        let repo = self.repo.lock().unwrap();
        Ok(repo.list().iter().map(|t| t.to_string()).collect())
    }

    fn complete_task(&self, id: u64) -> Result<()> {
        let mut repo = self.repo.lock().unwrap();
        repo.update(id, Box::new(|t| t.completed = true))
    }

    fn delete_task(&self, id: u64) -> Result<Task> {
        let mut repo = self.repo.lock().unwrap();
        repo.delete(id)
    }
}

// ---------- Main ----------

fn main() -> Result<()> {
    let data_dir = PathBuf::from("./data");
    fs::create_dir_all(&data_dir).ok();
    let repo = JsonFileRepository::new(data_dir.join("tasks.json"))?;
    let app = App::new(Box::new(repo));

    app.add_task("Learn Rust".into(), Priority::High)?;
    app.add_task("Write examples".into(), Priority::Medium)?;
    app.add_task("Review code".into(), Priority::Low)?;

    println!("=== Tasks ===");
    for task in app.list_tasks()? {
        println!("{}", task);
    }

    app.complete_task(1)?;
    println!("\nAfter completing task 1:");
    for task in app.list_tasks()? {
        println!("{}", task);
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_priority_from_str() {
        assert_eq!(
            Priority::try_from("high").unwrap(),
            Priority::High
        );
        assert!(Priority::try_from("invalid").is_err());
    }

    #[test]
    fn test_task_creation() {
        let task = Task::new(1, "Test".into(), Priority::Medium);
        assert_eq!(task.title, "Test");
        assert!(!task.completed);
    }
}
