using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks
{
    public class EditModel : PageModel
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly DaprClient _daprClient;

        private readonly IConfiguration _configuration;

        [BindProperty]
        public TaskUpdateModel? TaskUpdate { get; set; }
        public string? TasksCreatedBy { get; set; }

        public string? EnvRegion { get; set; }

        public EditModel(IHttpClientFactory httpClientFactory, DaprClient daprClient, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _daprClient = daprClient;
            _configuration = configuration;
        }

        public async Task<IActionResult> OnGetAsync(Guid? id)
        {
            EnvRegion = _configuration["Region"];
            TasksCreatedBy = Request.Cookies["TasksCreatedByCookie"];

            if (String.IsNullOrEmpty(TasksCreatedBy)) {
                return RedirectToPage("../Index");
            }

            if (id == null)
            {
                return NotFound();
            }

            // Dapr SideCar Invocation
            var Task = await _daprClient.InvokeMethodAsync<TaskModel>(HttpMethod.Get, "tasksmanager-backend-api", $"api/tasks/{id}");

            if (Task == null)
            {
                return NotFound();
            }

            TaskUpdate = new TaskUpdateModel()
            {
                TaskId = Task.TaskId,
                TaskName = Task.TaskName,
                TaskAssignedTo = Task.TaskAssignedTo,
                TaskDueDate = Task.TaskDueDate,
            };

            return Page();
        }


        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            if (TaskUpdate != null)
            {
                // Dapr SideCar Invocation
                await _daprClient.InvokeMethodAsync<TaskUpdateModel>(HttpMethod.Put, "tasksmanager-backend-api", $"api/tasks/{TaskUpdate.TaskId}", TaskUpdate);
            }

            return RedirectToPage("./Index");
        }
    }
}