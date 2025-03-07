using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks
{
    public class CreateModel : PageModel
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly DaprClient _daprClient;

        private readonly IConfiguration _configuration;

        public string? EnvRegion { get; set; }

        public CreateModel(IHttpClientFactory httpClientFactory, DaprClient daprClient, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _daprClient = daprClient;
            _configuration = configuration;
        }
        public string? TasksCreatedBy { get; set; }

        public IActionResult OnGet()
        {
            EnvRegion = _configuration["Region"];

            TasksCreatedBy = Request.Cookies["TasksCreatedByCookie"];

            return (!String.IsNullOrEmpty(TasksCreatedBy)) ? Page() : RedirectToPage("../Index");
        }

        [BindProperty]
        public TaskAddModel? TaskAdd { get; set; }

        public async Task<IActionResult> OnPostAsync()
        {
            if (!ModelState.IsValid)
            {
                return Page();
            }

            if (TaskAdd != null)
            {
                var createdBy = Request.Cookies["TasksCreatedByCookie"];

                if (!string.IsNullOrEmpty(createdBy))
                {
                    TaskAdd.TaskCreatedBy = createdBy;

                    // Dapr SideCar Invocation
                    await _daprClient.InvokeMethodAsync(HttpMethod.Post, "tasksmanager-backend-api", $"api/tasks", TaskAdd);
                }
            }

            return RedirectToPage("./Index");
        }
    }
}