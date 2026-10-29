using System.ComponentModel.DataAnnotations;
using SportMate.Application.DTOs.Requests;

namespace SportMate.API.Requests;

/// <summary>multipart/form-data body for adding a product image: an uploaded file or an image URL.</summary>
public class AddImageForm
{
    /// <summary>Image file (jpg, png, webp; max 5 MB). Either File or Url is required.</summary>
    public IFormFile? File { get; init; }

    [Url, StringLength(500)]
    public string? Url { get; init; }

    [StringLength(200)]
    public string? AltText { get; init; }

    [Range(0, 1000)]
    public int? DisplayOrder { get; init; }

    public bool IsPrimary { get; init; }

    public AddImageRequest ToRequest() => new()
    {
        File = File is null ? null : new FileUpload(File.OpenReadStream(), File.FileName, File.ContentType, File.Length),
        Url = Url,
        AltText = AltText,
        DisplayOrder = DisplayOrder,
        IsPrimary = IsPrimary,
    };
}
