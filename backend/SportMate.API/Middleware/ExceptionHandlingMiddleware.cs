using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SportMate.Application.Common;

namespace SportMate.API.Middleware;

/// <summary>
/// Converts exceptions into RFC 7807 Problem Details so clients always get the same error shape
/// and never see stack traces or SQL details (BR-072).
/// </summary>
public class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (AppException ex)
        {
            await WriteProblemAsync(context, ex.StatusCode, ex.Title, ex.Detail, ex.Errors);
        }
        catch (DbUpdateConcurrencyException)
        {
            await WriteProblemAsync(context, StatusCodes.Status409Conflict, "Conflict",
                "The resource was changed by another request. Reload and try again.");
        }
        catch (DbUpdateException ex) when (IsUniqueViolation(ex))
        {
            await WriteProblemAsync(context, StatusCodes.Status409Conflict, "Conflict",
                "A record with the same unique value already exists.");
        }
        catch (Exception ex) when (!context.Response.HasStarted)
        {
            logger.LogError(ex, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);
            await WriteProblemAsync(context, StatusCodes.Status500InternalServerError, "Internal server error",
                "An unexpected error occurred.");
        }
    }

    // 2601 = duplicate key in unique index, 2627 = unique constraint violation.
    private static bool IsUniqueViolation(DbUpdateException ex) =>
        ex.InnerException is SqlException { Number: 2601 or 2627 };

    private static Task WriteProblemAsync(HttpContext context, int status, string title, string? detail,
        IDictionary<string, string[]>? errors = null)
    {
        ProblemDetails problem = errors is null
            ? new ProblemDetails()
            : new ValidationProblemDetails(errors);
        problem.Type = "about:blank";
        problem.Title = title;
        problem.Status = status;
        problem.Detail = detail;
        problem.Instance = context.Request.Path;

        context.Response.Clear();
        context.Response.StatusCode = status;
        return context.Response.WriteAsJsonAsync(problem, problem.GetType(), options: null, contentType: "application/problem+json");
    }
}
