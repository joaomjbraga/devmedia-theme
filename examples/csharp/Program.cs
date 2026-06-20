/**
 * C# example - E-commerce order processing with modern C# features
 */
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;

namespace DevMedia.Example;

public static class Program
{
    public static async Task Main(string[] args)
    {
        var store = new Store("DevMedia Shop");

        var product1 = new Product("P001", "Laptop", 4500.00m);
        var product2 = new Product("P002", "Mouse", 150.00m);
        var product3 = new Product("P003", "Keyboard", 350.00m);

        store.AddProduct(product1);
        store.AddProduct(product2);
        store.AddProduct(product3);

        var order = new OrderBuilder()
            .WithCustomer("Alice")
            .AddItem(product1, 1)
            .AddItem(product2, 2)
            .Build();

        var processed = await store.ProcessOrderAsync(order);

        Console.WriteLine($"Order {processed.Id} processed!");
        Console.WriteLine($"Total: {processed.Total:C}");
        Console.WriteLine($"Status: {processed.Status}");

        var json = JsonSerializer.Serialize(processed, new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        });
        Console.WriteLine(json);
    }
}

// Records
public record Product(string Code, string Name, decimal Price);
public record OrderItem(Product Product, int Quantity);

public enum OrderStatus
{
    Pending,
    Paid,
    Shipped,
    Delivered,
    Cancelled
}

public record Order
{
    public string Id { get; init; } = Guid.NewGuid().ToString("N");
    public string Customer { get; init; } = string.Empty;
    public List<OrderItem> Items { get; init; } = [];
    public decimal Total => Items.Sum(i => i.Product.Price * i.Quantity);
    public OrderStatus Status { get; init; } = OrderStatus.Pending;
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
}

// Builder pattern
public class OrderBuilder
{
    private string _customer = string.Empty;
    private readonly List<OrderItem> _items = [];

    public OrderBuilder WithCustomer(string customer)
    {
        _customer = customer;
        return this;
    }

    public OrderBuilder AddItem(Product product, int quantity = 1)
    {
        _items.Add(new OrderItem(product, quantity));
        return this;
    }

    public Order Build() => new()
    {
        Customer = _customer,
        Items = [.. _items],
    };
}

// Primary constructor
public class Store(string name)
{
    private readonly ConcurrentDictionary<string, Product> _products = new();
    private readonly ConcurrentQueue<Order> _queue = new();

    public string Name { get; } = name;

    public void AddProduct(Product product)
    {
        if (!_products.TryAdd(product.Code, product))
        {
            throw new InvalidOperationException($"Product {product.Code} already exists");
        }
    }

    // Async method
    public async Task<Order> ProcessOrderAsync(Order order)
    {
        Console.WriteLine($"Processing order {order.Id}...");

        // Simulate async work
        await Task.Delay(500);

        if (!order.Items.All(i => _products.ContainsKey(i.Product.Code)))
        {
            throw new InvalidOperationException("Product not found in store");
        }

        _queue.Enqueue(order);

        var processed = order with
        {
            Status = OrderStatus.Paid,
        };

        // Pattern matching
        var discount = processed.Total switch
        {
            > 5000m => 0.10m,
            > 1000m => 0.05m,
            _ => 0m,
        };

        if (discount > 0)
        {
            Console.WriteLine($"Discount applied: {discount:P0}");
        }

        return await Task.FromResult(processed);
    }

    public IEnumerable<Order> PendingOrders =>
        _queue.Where(o => o.Status == OrderStatus.Pending);
}

// Extension methods
public static class DecimalExtensions
{
    public static decimal WithTax(this decimal amount, decimal taxRate = 0.08m)
    {
        return amount * (1 + taxRate);
    }
}

// Generic repository pattern
public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(string id);
    Task<IEnumerable<T>> GetAllAsync();
    Task AddAsync(T entity);
    Task<bool> DeleteAsync(string id);
}

public class InMemoryRepository<T> : IRepository<T> where T : class
{
    private readonly ConcurrentDictionary<string, T> _store = new();

    public Task<T?> GetByIdAsync(string id)
    {
        _store.TryGetValue(id, out var value);
        return Task.FromResult(value);
    }

    public Task<IEnumerable<T>> GetAllAsync()
    {
        return Task.FromResult<IEnumerable<T>>(_store.Values.ToList());
    }

    public Task AddAsync(T entity)
    {
        var id = Guid.NewGuid().ToString();
        _store.TryAdd(id, entity);
        return Task.CompletedTask;
    }

    public Task<bool> DeleteAsync(string id)
    {
        return Task.FromResult(_store.TryRemove(id, out _));
    }
}
