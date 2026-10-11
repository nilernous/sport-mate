using SportMate.Domain.Enums;

namespace SportMate.Application.Common;

public class ShippingSettings
{
    public const string Section = "Shipping";

    public decimal StandardFee { get; set; } = 30_000m;
    public decimal ExpressFee { get; set; } = 50_000m;

    /// <summary>Standard shipping is free when the discounted subtotal reaches this amount. 0 disables it.</summary>
    public decimal FreeStandardShippingThreshold { get; set; } = 1_000_000m;

    public decimal FeeFor(ShippingMethod method, decimal discountedSubtotal) => method switch
    {
        ShippingMethod.Express => ExpressFee,
        _ when FreeStandardShippingThreshold > 0 && discountedSubtotal >= FreeStandardShippingThreshold => 0m,
        _ => StandardFee,
    };
}

public class BankTransferSettings
{
    public const string Section = "BankTransfer";

    public string BankName { get; set; } = "Vietcombank";
    public string AccountNumber { get; set; } = "0000000000";
    public string AccountName { get; set; } = "SPORT MATE";
}
