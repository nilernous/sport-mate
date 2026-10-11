using Microsoft.Extensions.Options;
using SportMate.Application.Common;

namespace SportMate.Application.Services;

/// <summary>Converts calendar-day filters in the business time zone to UTC instants (BR-069).</summary>
public class ReportSettingsAccessor(IOptions<ReportSettings> options)
{
    public ReportSettings Settings { get; } = options.Value;

    public TimeSpan Offset => TimeSpan.FromHours(Settings.UtcOffsetHours);

    public DateOnly Today => DateOnly.FromDateTime(DateTime.UtcNow.Add(Offset));

    /// <summary>Returns [fromUtc, toUtc) where <paramref name="to"/> is inclusive.</summary>
    public (DateTime? FromUtc, DateTime? ToUtc) ToUtcRange(DateOnly? from, DateOnly? to, bool requireRange)
    {
        if (from is not null && to is not null && from > to)
            throw AppException.BadRequest("'from' must be on or before 'to'.", "from");
        if (requireRange && from is not null && to is not null && to.Value.DayNumber - from.Value.DayNumber + 1 > Settings.MaxRangeDays)
            throw AppException.BadRequest($"The date range cannot exceed {Settings.MaxRangeDays} days.", "to");

        DateTime? fromUtc = from?.ToDateTime(TimeOnly.MinValue).Subtract(Offset);
        DateTime? toUtc = to?.AddDays(1).ToDateTime(TimeOnly.MinValue).Subtract(Offset);
        return (fromUtc, toUtc);
    }

    /// <summary>Resolves an optional report range, defaulting to the last 30 days.</summary>
    public (DateOnly From, DateOnly To, DateTime FromUtc, DateTime ToUtc) ResolveReportRange(DateOnly? from, DateOnly? to)
    {
        var resolvedTo = to ?? Today;
        var resolvedFrom = from ?? resolvedTo.AddDays(-29);
        var (fromUtc, toUtc) = ToUtcRange(resolvedFrom, resolvedTo, requireRange: true);
        return (resolvedFrom, resolvedTo, fromUtc!.Value, toUtc!.Value);
    }

    public DateOnly ToLocalDate(DateTime utc) => DateOnly.FromDateTime(utc.Add(Offset));
}
