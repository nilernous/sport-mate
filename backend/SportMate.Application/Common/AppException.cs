namespace SportMate.Application.Common;

/// <summary>
/// Expected business/validation failure. Translated to a Problem Details response
/// by the API's exception-handling middleware.
/// </summary>
public class AppException(int statusCode, string title, string? detail = null, IDictionary<string, string[]>? errors = null)
    : Exception(detail ?? title)
{
    public int StatusCode { get; } = statusCode;
    public string Title { get; } = title;
    public string? Detail { get; } = detail;
    public IDictionary<string, string[]>? Errors { get; } = errors;

    public static AppException BadRequest(string detail, string? field = null) =>
        new(400, "Validation failed", detail,
            field is null ? null : new Dictionary<string, string[]> { [field] = [detail] });

    public static AppException Unauthorized(string detail) =>
        new(401, "Unauthorized", detail);

    public static AppException Forbidden(string detail) =>
        new(403, "Forbidden", detail);

    public static AppException NotFound(string resource) =>
        new(404, "Not found", $"{resource} was not found.");

    public static AppException Conflict(string detail) =>
        new(409, "Conflict", detail);
}
