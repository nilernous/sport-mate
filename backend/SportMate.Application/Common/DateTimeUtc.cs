namespace SportMate.Application.Common;

public static class DateTimeUtc
{
    /// <summary>All timestamps are stored in UTC; values without an offset are treated as UTC.</summary>
    public static DateTime ToUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Utc => value,
        DateTimeKind.Local => value.ToUniversalTime(),
        _ => DateTime.SpecifyKind(value, DateTimeKind.Utc),
    };
}
