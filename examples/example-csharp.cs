// C# / .NET - Complete Example
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace DevMedia.App
{
    // Model
    public class Course
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public int InstructorId { get; set; }
        public bool IsPublished { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
    
    // Interface
    public interface ICourseService
    {
        Task<IEnumerable<Course>> GetAllAsync();
        Task<Course> GetByIdAsync(int id);
        Task<Course> CreateAsync(Course course);
    }
    
    // Service
    public class CourseService : ICourseService
    {
        private readonly List<Course> _courses = new();
        
        public async Task<IEnumerable<Course>> GetAllAsync()
        {
            return await Task.FromResult(_courses.AsEnumerable());
        }
        
        public async Task<Course> GetByIdAsync(int id)
        {
            var course = _courses.FirstOrDefault(c => c.Id == id);
            return await Task.FromResult(course);
        }
        
        public async Task<Course> CreateAsync(Course course)
        {
            course.Id = _courses.Count + 1;
            _courses.Add(course);
            return await Task.FromResult(course);
        }
    }
    
    // Controller
    [ApiController]
    [Route("api/[controller]")]
    public class CoursesController : ControllerBase
    {
        private readonly ICourseService _service;
        
        public CoursesController(ICourseService service)
        {
            _service = service;
        }
        
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var courses = await _service.GetAllAsync();
            return Ok(new { success = true, data = courses });
        }
        
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Course course)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);
            
            var created = await _service.CreateAsync(course);
            return CreatedAtAction(nameof(GetAll), new { id = created.Id }, created);
        }
    }
}
