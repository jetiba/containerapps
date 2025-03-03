using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using TasksTracker.WebPortal.Frontend.Ui.Pages.Tasks.Models;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages
{
    [IgnoreAntiforgeryToken(Order = 1001)]
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly IConfiguration _configuration;
        [BindProperty]
        public string? TasksCreatedBy { get; set; }
        public string? EnvRegion { get; set; }

        public IndexModel(ILogger<IndexModel> logger, IConfiguration configuration)
        {
            _logger = logger;
            _configuration = configuration;
        }

        public void OnGet()
        {
            EnvRegion = _configuration["Region"];
        }

        public IActionResult OnPost()
        {
            if (!string.IsNullOrEmpty(TasksCreatedBy))
            {
                Response.Cookies.Append("TasksCreatedByCookie", TasksCreatedBy);
            }

            return RedirectToPage("./Tasks/Index");
        }
    }
}