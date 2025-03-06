using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;
using Dapr.Client;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks
{
    public class IndexModel : PageModel
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly DaprClient _daprClient;

        private readonly IConfiguration _configuration;
        public List<TaskModel>? TasksList { get; set; }

        [BindProperty]
        public string? TasksCreatedBy { get; set; }

        public string? EnvRegion { get; set; }

        public IndexModel(IHttpClientFactory httpClientFactory, DaprClient daprClient, IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _daprClient = daprClient;    
            _configuration = configuration;
        }

        public async Task<IActionResult> OnGetAsync()
        {
            EnvRegion = _configuration["Region"];
            TasksCreatedBy = Request.Cookies["TasksCreatedByCookie"];

            if (!String.IsNullOrEmpty(TasksCreatedBy)) {
                // Invoke via internal URL (without Dapr)
                // var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
                // TasksList = await httpClient.GetFromJsonAsync<List<TaskModel>>($"api/tasks?createdBy={TasksCreatedBy}");
                
                // Invoke via DaprSDK (invoke HTTP Service using Dapr)
                TasksList = await _daprClient.InvokeMethodAsync<List<TaskModel>>(HttpMethod.Get, "tasksmanager-backend-api", $"api/tasks?createdBy={TasksCreatedBy}");
                return Page();
            } else {
                return RedirectToPage("../Index");
            }
        }

        public async Task<IActionResult> OnPostDeleteAsync(Guid id)
        {
            // direct svc to svc http request
            // var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
            // var result = await httpClient.DeleteAsync($"api/tasks/{id}");

            // Invoke via DaprSDK (invoke HTTP Service using Dapr)
            await _daprClient.InvokeMethodAsync(HttpMethod.Delete, "tasksmanager-backend-api", $"api/tasks/{id}");
            return RedirectToPage();
        }

        public async Task<IActionResult> OnPostCompleteAsync(Guid id)
        {
            // direct svc to svc http request
            // var httpClient = _httpClientFactory.CreateClient("BackEndApiExternal");
            // var result = await httpClient.PutAsync($"api/tasks/{id}/markcomplete", null);

            // Invoke via DaprSDK (invoke HTTP Service using Dapr)
            await _daprClient.InvokeMethodAsync(HttpMethod.Put, "tasksmanager-backend-api", $"api/tasks/{id}/markcomplete");
            return RedirectToPage();
        }
    }
}