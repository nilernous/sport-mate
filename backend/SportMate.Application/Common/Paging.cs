using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace SportMate.Application.Common;

public class PageQuery
{
    public const int MaxPageSize = 100;

    [Range(1, int.MaxValue)]
    public int Page { get; set; } = 1;

    [Range(1, MaxPageSize)]
    public int PageSize { get; set; } = 20;
}

public record PagedResult<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalItems, int TotalPages);

public static class PagingExtensions
{
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(this IQueryable<T> query, PageQuery paging, CancellationToken ct = default)
    {
        var total = await query.CountAsync(ct);
        var items = await query.Skip((paging.Page - 1) * paging.PageSize).Take(paging.PageSize).ToListAsync(ct);
        return new PagedResult<T>(items, paging.Page, paging.PageSize, total, (int)Math.Ceiling(total / (double)paging.PageSize));
    }
}
