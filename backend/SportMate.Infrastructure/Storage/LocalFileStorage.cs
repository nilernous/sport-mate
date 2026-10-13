using Microsoft.Extensions.Options;
using SportMate.Application.Interfaces;

namespace SportMate.Infrastructure.Storage;

public class FileStorageOptions
{
    /// <summary>Folder served as static files by the API (its wwwroot).</summary>
    public string RootPath { get; set; } = string.Empty;
}

/// <summary>
/// Saves uploads under the web root and returns server-relative URLs ("/uploads/..."),
/// so they work whichever host the client uses to reach the API.
/// </summary>
public class LocalFileStorage(IOptions<FileStorageOptions> options) : IFileStorage
{
    private readonly string _root = options.Value.RootPath;

    public async Task<string> SaveAsync(Stream content, string folder, string fileName, CancellationToken ct)
    {
        var directory = Path.Combine(_root, folder);
        Directory.CreateDirectory(directory);
        var safeName = Path.GetFileName(fileName);
        await using (var file = File.Create(Path.Combine(directory, safeName)))
            await content.CopyToAsync(file, ct);
        return $"/{folder.Trim('/')}/{safeName}";
    }

    public Task DeleteAsync(string url, CancellationToken ct)
    {
        // External image URLs are not ours to delete.
        if (!url.StartsWith('/')) return Task.CompletedTask;

        var relative = url.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var path = Path.GetFullPath(Path.Combine(_root, relative));
        // Never delete anything outside the storage root.
        if (path.StartsWith(Path.GetFullPath(_root), StringComparison.OrdinalIgnoreCase) && File.Exists(path))
            File.Delete(path);
        return Task.CompletedTask;
    }
}
