using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using SportMate.Application.Common;

namespace SportMate.Infrastructure.Persistence;

/// <summary>
/// All timestamps are stored in UTC. SQL Server's datetime2 has no kind, so mark values read back
/// as UTC; JSON output then carries the "Z" suffix and clients convert to local time correctly.
/// </summary>
public class UtcDateTimeConverter() : ValueConverter<DateTime, DateTime>(
    v => DateTimeUtc.ToUtc(v),
    v => DateTime.SpecifyKind(v, DateTimeKind.Utc));
