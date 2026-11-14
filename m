# MOVIE MANAGEMENT AND TICKET BOOKING – ASP.NET CORE MVC

## 1. Movie.cs

```csharp
using System.ComponentModel.DataAnnotations;

namespace MovieMVC.Models
{
    public class Movie
    {
        public int Id { get; set; }

        [Required]
        [MinLength(2)]
        [MaxLength(200)]
        public string Title { get; set; } = "";

        [Required]
        [Range(0, double.MaxValue)]
        public decimal BasePrice { get; set; }

        [Required]
        [Range(30, 300)]
        public int DurationMinutes { get; set; }

        public string? Genre { get; set; }

        public ICollection<Ticket> Tickets { get; set; }
            = new List<Ticket>();
    }
}
```

## 2. Ticket.cs

```csharp
using System.ComponentModel.DataAnnotations;

namespace MovieMVC.Models
{
    public class Ticket
    {
        public int Id { get; set; }

        [Required]
        public DateTime ShowDate { get; set; }

        [Required]
        [MinLength(3)]
        [MaxLength(100)]
        public string CustomerName { get; set; } = "";

        [Required]
        [Phone]
        public string CustomerPhone { get; set; } = "";

        [Required]
        public int MovieId { get; set; }

        public Movie? Movie { get; set; }

        [Required]
        [Range(1, 10)]
        public int SeatQuantity { get; set; }
    }
}
```

## 3. MovieDbContext.cs

```csharp
using Microsoft.EntityFrameworkCore;

namespace MovieMVC.Models
{
    public class MovieDbContext : DbContext
    {
        public MovieDbContext(DbContextOptions<MovieDbContext> options)
            : base(options)
        {
        }

        public DbSet<Movie> Movies { get; set; }
        public DbSet<Ticket> Tickets { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Movie>()
                .HasMany(m => m.Tickets)
                .WithOne(t => t.Movie)
                .HasForeignKey(t => t.MovieId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
```

## 4. MoviesController.cs

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MovieMVC.Models;

namespace MovieMVC.Controllers
{
    public class MoviesController : Controller
    {
        private readonly MovieDbContext _context;

        public MoviesController(MovieDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var movies = await _context.Movies.ToListAsync();
            return View(movies);
        }
    }
}
```

## 5. TicketsController.cs

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using MovieMVC.Models;

namespace MovieMVC.Controllers
{
    public class TicketsController : Controller
    {
        private readonly MovieDbContext _context;

        public TicketsController(MovieDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var tickets = await _context.Tickets
                .Include(t => t.Movie)
                .ToListAsync();

            return View(tickets);
        }

        public async Task<IActionResult> Create()
        {
            await LoadMovies();
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Ticket ticket)
        {
            if (!await _context.Movies.AnyAsync(m => m.Id == ticket.MovieId))
            {
                ModelState.AddModelError("MovieId", "Please select a valid movie.");
            }

            if (ModelState.IsValid)
            {
                _context.Tickets.Add(ticket);
                await _context.SaveChangesAsync();

                return RedirectToAction(nameof(Index));
            }

            await LoadMovies();
            return View(ticket);
        }

        public async Task<IActionResult> Edit(int id)
        {
            var ticket = await _context.Tickets.FindAsync(id);

            if (ticket == null)
                return NotFound();

            await LoadMovies();
            return View(ticket);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Ticket ticket)
        {
            if (id != ticket.Id)
                return NotFound();

            if (!await _context.Movies.AnyAsync(m => m.Id == ticket.MovieId))
            {
                ModelState.AddModelError("MovieId", "Please select a valid movie.");
            }

            if (ModelState.IsValid)
            {
                var existing = await _context.Tickets.FindAsync(id);

                if (existing == null)
                    return NotFound();

                existing.ShowDate = ticket.ShowDate;
                existing.CustomerName = ticket.CustomerName;
                existing.CustomerPhone = ticket.CustomerPhone;
                existing.MovieId = ticket.MovieId;
                existing.SeatQuantity = ticket.SeatQuantity;

                await _context.SaveChangesAsync();

                return RedirectToAction(nameof(Index));
            }

            await LoadMovies();
            return View(ticket);
        }

        public async Task<IActionResult> Delete(int id)
        {
            var ticket = await _context.Tickets
                .Include(t => t.Movie)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (ticket == null)
                return NotFound();

            return View(ticket);
        }

        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> DeleteConfirmed(int id)
        {
            var ticket = await _context.Tickets.FindAsync(id);

            if (ticket != null)
            {
                _context.Tickets.Remove(ticket);
                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        private async Task LoadMovies()
        {
            ViewBag.MovieId = new SelectList(
                await _context.Movies.ToListAsync(),
                "Id",
                "Title");
        }
    }
}
```

## 6. Views/Movies/Index.cshtml

```html
@model IEnumerable<MovieMVC.Models.Movie>

<h2>Movie List</h2>

<table class="table table-bordered table-striped">
    <thead class="table-dark">
        <tr>
            <th>Title</th>
            <th>Base Price</th>
            <th>Duration</th>
            <th>Genre</th>
        </tr>
    </thead>

    <tbody>
        @foreach (var movie in Model)
        {
            <tr>
                <td>@Html.DisplayFor(m => movie.Title)</td>
                <td>@movie.BasePrice.ToString("N0")</td>
                <td>@movie.DurationMinutes minutes</td>
                <td>@movie.Genre</td>
            </tr>
        }
    </tbody>
</table>
```

## 7. Views/Tickets/Index.cshtml

```html
@model IEnumerable<MovieMVC.Models.Ticket>

<h2>Ticket List</h2>

<a asp-action="Create" class="btn btn-primary mb-3">
    Add Ticket
</a>

<table class="table table-bordered table-striped">
    <thead class="table-dark">
        <tr>
            <th>Movie</th>
            <th>Show Date</th>
            <th>Customer Name</th>
            <th>Phone</th>
            <th>Seats</th>
            <th>Actions</th>
        </tr>
    </thead>

    <tbody>
        @foreach (var ticket in Model)
        {
            <tr>
                <td>@ticket.Movie?.Title</td>
                <td>@ticket.ShowDate.ToString("dd/MM/yyyy HH:mm")</td>
                <td>@ticket.CustomerName</td>
                <td>@ticket.CustomerPhone</td>
                <td>@ticket.SeatQuantity</td>
                <td>
                    <a asp-action="Edit" asp-route-id="@ticket.Id"
                       class="btn btn-warning btn-sm">Edit</a>

                    <a asp-action="Delete" asp-route-id="@ticket.Id"
                       class="btn btn-danger btn-sm">Delete</a>
                </td>
            </tr>
        }
    </tbody>
</table>
```

## 8. Views/Tickets/Create.cshtml

```html
@model MovieMVC.Models.Ticket

<h2>Create Ticket</h2>

<form asp-action="Create" method="post">
    <div asp-validation-summary="ModelOnly"
         class="text-danger"></div>

    <div class="mb-3">
        <label asp-for="ShowDate" class="form-label"></label>
        <input asp-for="ShowDate" type="datetime-local"
               class="form-control" />
        <span asp-validation-for="ShowDate"
              class="text-danger"></span>
    </div>

    <div class="mb-3">
        <label asp-for="CustomerName" class="form-label"></label>
        <input asp-for="CustomerName" class="form-control" />
        <span asp-validation-for="CustomerName"
              class="text-danger"></span>
    </div>

    <div class="mb-3">
        <label asp-for="CustomerPhone" class="form-label"></label>
        <input asp-for="CustomerPhone" class="form-control" />
        <span asp-validation-for="CustomerPhone"
              class="text-danger"></span>
    </div>

    <div class="mb-3">
        <label asp-for="MovieId" class="form-label"></label>
        <select asp-for="MovieId" asp-items="ViewBag.MovieId"
                class="form-select">
            <option value="">-- Select Movie --</option>
        </select>
        <span asp-validation-for="MovieId"
              class="text-danger"></span>
    </div>

    <div class="mb-3">
        <label asp-for="SeatQuantity" class="form-label"></label>
        <input asp-for="SeatQuantity" class="form-control" />
        <span asp-validation-for="SeatQuantity"
              class="text-danger"></span>
    </div>

    <button type="submit" class="btn btn-primary">Save</button>
    <a asp-action="Index" class="btn btn-secondary">Back</a>
</form>

@section Scripts {
    <partial name="_ValidationScriptsPartial" />
}
```

## 9. Views/Tickets/Edit.cshtml

```html
@model MovieMVC.Models.Ticket

<h2>Edit Ticket</h2>

<form asp-action="Edit" method="post">
    <input type="hidden" asp-for="Id" />

    <div asp-validation-summary="ModelOnly"
         class="text-danger"></div>

    <div class="mb-3">
        <label asp-for="ShowDate" class="form-label"></label>
        <input asp-for="ShowDate" type="datetime-local"
               class="form-control" />
        <span asp-validation-for="ShowDate"
              class="text-danger"></span>
    </div>

    <div class="mb-3">
        <label asp-for="CustomerName
