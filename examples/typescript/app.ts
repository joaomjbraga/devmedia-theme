/**
 * TypeScript example - Task Management API with NestJS-style patterns
 */
import { randomUUID } from "node:crypto";
import { createServer, IncomingMessage, ServerResponse } from "node:http";

// ---------- Types & Interfaces ----------
export type TaskStatus = "todo" | "in_progress" | "done";

export interface Task {
  readonly id: string;
  title: string;
  description: string;
  status: TaskStatus;
  priority: number;
  tags: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateTaskDto {
  title: string;
  description?: string;
  priority?: number;
  tags?: string[];
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

// ---------- Decorator ----------
function logMethod(
  target: unknown,
  propertyKey: string,
  descriptor: PropertyDescriptor,
): PropertyDescriptor {
  const original = descriptor.value;
  descriptor.value = function (...args: unknown[]) {
    console.log(`[LOG] Calling ${propertyKey} with args:`, args);
    const result = original.apply(this, args);
    if (result instanceof Promise) {
      return result.then((res: unknown) => {
        console.log(`[LOG] ${propertyKey} resolved`);
        return res;
      });
    }
    console.log(`[LOG] ${propertyKey} returned`);
    return result;
  };
  return descriptor;
}

// ---------- Generic Repository ----------
abstract class BaseRepository<T extends { id: string }> {
  protected storage = new Map<string, T>();

  findAll(): T[] {
    return [...this.storage.values()];
  }

  findById(id: string): T | undefined {
    return this.storage.get(id);
  }

  save(entity: T): T {
    this.storage.set(entity.id, entity);
    return entity;
  }

  delete(id: string): boolean {
    return this.storage.delete(id);
  }
}

// ---------- Service ----------
class TaskRepository extends BaseRepository<Task> {}

class TaskService {
  constructor(private readonly repository: TaskRepository) {}

  @logMethod
  async create(dto: CreateTaskDto): Promise<Task> {
    const now = new Date();
    const task: Task = {
      id: randomUUID(),
      title: dto.title,
      description: dto.description ?? "",
      status: "todo",
      priority: dto.priority ?? 0,
      tags: dto.tags ?? [],
      createdAt: now,
      updatedAt: now,
    };
    return this.repository.save(task);
  }

  @logMethod
  async list(page = 1, limit = 10): Promise<PaginatedResult<Task>> {
    const all = this.repository.findAll();
    const start = (page - 1) * limit;
    const data = all.slice(start, start + limit);
    return {
      data,
      total: all.length,
      page,
      limit,
      hasMore: start + limit < all.length,
    };
  }

  @logMethod
  async getById(id: string): Promise<Task | null> {
    return this.repository.findById(id) ?? null;
  }

  @logMethod
  async updateStatus(id: string, status: TaskStatus): Promise<Task | null> {
    const task = this.repository.findById(id);
    if (!task) return null;

    const updated: Task = {
      ...task,
      status,
      updatedAt: new Date(),
    };
    return this.repository.save(updated);
  }
}

// ---------- Controller ----------
function parseBody(req: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on("data", (chunk: Buffer) => chunks.push(chunk));
    req.on("end", () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString()));
      } catch {
        reject(new Error("Invalid JSON"));
      }
    });
    req.on("error", reject);
  });
}

function sendJson(res: ServerResponse, data: unknown, status = 200) {
  res.writeHead(status, { "Content-Type": "application/json" });
  res.end(JSON.stringify(data, null, 2));
}

class TaskController {
  constructor(private readonly service: TaskService) {}

  async handle(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const url = new URL(req.url ?? "/", `http://${req.headers.host}`);
    const pathParts = url.pathname.split("/").filter(Boolean);

    try {
      if (req.method === "GET" && pathParts[0] === "tasks" && !pathParts[1]) {
        const page = Number(url.searchParams.get("page")) || 1;
        const limit = Number(url.searchParams.get("limit")) || 10;
        const result = await this.service.list(page, limit);
        return sendJson(res, result);
      }

      if (req.method === "GET" && pathParts[0] === "tasks" && pathParts[1]) {
        const task = await this.service.getById(pathParts[1]);
        if (!task) return sendJson(res, { error: "Not found" }, 404);
        return sendJson(res, task);
      }

      if (req.method === "POST" && pathParts[0] === "tasks") {
        const body = (await parseBody(req)) as CreateTaskDto;
        const task = await this.service.create(body);
        return sendJson(res, task, 201);
      }

      sendJson(res, { error: "Not found" }, 404);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unknown error";
      sendJson(res, { error: message }, 500);
    }
  }
}

// ---------- Bootstrap ----------
const repository = new TaskRepository();
const service = new TaskService(repository);
const controller = new TaskController(service);

const server = createServer((req, res) => {
  controller.handle(req, res);
});

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

export { repository, service };
