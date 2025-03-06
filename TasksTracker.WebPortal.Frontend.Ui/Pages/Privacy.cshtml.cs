using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace TasksTracker.WebPortal.Frontend.Ui.Pages;

public class PrivacyModel : PageModel
{
    private readonly ILogger<PrivacyModel> _logger;
    public string? EnvRegion { get; set; }

    public PrivacyModel(ILogger<PrivacyModel> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public void OnGet()
    {
        EnvRegion = _configuration["Region"];
    }
}

