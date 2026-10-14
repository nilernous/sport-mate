using Microsoft.Extensions.Options;
using SportMate.Application.Common;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>
/// Payment details returned with a placed order. Payment status is separate from order status (BR-046).
/// </summary>
public class PaymentService(IOptions<BankTransferSettings> bankOptions)
{
    private readonly BankTransferSettings _bank = bankOptions.Value;

    public PaymentDto ToDto(Payment p, string orderCode) => new(
        p.Id, p.OrderId, orderCode, p.Method, p.Status, p.Amount, p.TransferReference, p.ConfirmedByUser?.FullName,
        p.ConfirmedAt, p.Note,
        p is { Method: PaymentMethod.BankTransfer, Status: PaymentStatus.Pending }
            ? new BankTransferInstructionsDto(_bank.BankName, _bank.AccountNumber, _bank.AccountName, p.Amount, orderCode)
            : null,
        p.CreatedAt, p.UpdatedAt);
}
