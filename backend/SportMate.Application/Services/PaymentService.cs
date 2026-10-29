using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Application.DTOs.Requests;
using SportMate.Application.DTOs.Responses;
using SportMate.Domain.Entities;
using SportMate.Domain.Enums;

namespace SportMate.Application.Services;

/// <summary>
/// Payments (UC-058 – UC-060). Payment status is separate from order status (BR-046) and only
/// Staff/Admin can mark a payment as paid (BR-048).
/// </summary>
public class PaymentService(IApplicationDbContext db, IOptions<BankTransferSettings> bankOptions)
{
    private readonly BankTransferSettings _bank = bankOptions.Value;

    // UC-058
    public async Task<PaymentDto> GetOwnAsync(int userId, int orderId, CancellationToken ct)
    {
        var payment = await LoadAsync(p => p.OrderId == orderId && p.Order.UserId == userId, tracking: false, ct)
                      ?? throw AppException.NotFound("Payment");
        return ToDto(payment, payment.Order.OrderCode);
    }

    // UC-059: choosing a method only produces instructions; the payment stays Pending (BR-047).
    public async Task<PaymentDto> InitiateAsync(int userId, int orderId, PaymentMethod method, CancellationToken ct)
    {
        var payment = await LoadAsync(p => p.OrderId == orderId && p.Order.UserId == userId, tracking: true, ct)
                      ?? throw AppException.NotFound("Payment");
        if (payment.Order.Status != OrderStatus.Pending)
            throw AppException.Conflict("The payment method can only be changed while the order is pending.");
        if (payment.Status is PaymentStatus.Paid or PaymentStatus.Refunded)
            throw AppException.Conflict("This order has already been paid.");

        payment.Method = method;
        payment.Status = PaymentStatus.Pending;
        payment.Note = null;
        payment.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        return ToDto(payment, payment.Order.OrderCode);
    }

    // UC-060: confirms a bank transfer once, after the amount and reference were checked (BR-050 – BR-052).
    public async Task<PaymentDto> ConfirmBankTransferAsync(int actorId, int paymentId, ConfirmPaymentRequest r, CancellationToken ct)
    {
        await using var tx = await db.Database.BeginTransactionAsync(ct);
        var payment = await LoadAsync(p => p.Id == paymentId, tracking: true, ct) ?? throw AppException.NotFound("Payment");

        if (payment.Method != PaymentMethod.BankTransfer)
            throw AppException.Conflict("Only bank-transfer payments are confirmed manually.");
        if (payment.Status == PaymentStatus.Paid)
            throw AppException.Conflict("This payment has already been confirmed.");
        if (payment.Status != PaymentStatus.Pending || payment.Order.Status == OrderStatus.Cancelled)
            throw AppException.Conflict($"A {payment.Status} payment of a {payment.Order.Status} order cannot be confirmed.");
        if (r.Amount != payment.Amount)
            throw AppException.BadRequest($"Received amount {r.Amount:N0} does not match the amount due {payment.Amount:N0} VND.", "amount");

        var now = DateTime.UtcNow;
        payment.TransferReference = r.TransferReference.Trim();
        MarkPaid(payment, actorId, now, TextNormalizer.Clean(r.Note) ?? "Bank transfer verified");

        // A confirmed transfer moves a pending order forward.
        if (payment.Order.Status == OrderStatus.Pending)
        {
            payment.Order.Status = OrderStatus.Confirmed;
            payment.Order.UpdatedAt = now;
            db.OrderStatusHistories.Add(new OrderStatusHistory
            {
                OrderId = payment.OrderId, FromStatus = OrderStatus.Pending, ToStatus = OrderStatus.Confirmed,
                ChangedByUserId = actorId, ChangedAt = now, Note = "Payment confirmed",
            });
        }

        await db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return await GetForStaffAsync(paymentId, ct);
    }

    /// <summary>Other permitted payment-state changes, e.g. COD collected, failed, refunded.</summary>
    public async Task<PaymentDto> UpdateStatusAsync(int actorId, int paymentId, PaymentStatus target, string? note, CancellationToken ct)
    {
        var payment = await LoadAsync(p => p.Id == paymentId, tracking: true, ct) ?? throw AppException.NotFound("Payment");
        var now = DateTime.UtcNow;

        switch (payment.Status, target)
        {
            case (PaymentStatus.Pending, PaymentStatus.Paid) when payment.Method == PaymentMethod.BankTransfer:
                throw AppException.Conflict("Use the confirm endpoint to verify bank transfers.");
            case (PaymentStatus.Pending, PaymentStatus.Paid) when payment.Order.Status == OrderStatus.Cancelled:
                throw AppException.Conflict("A cancelled order cannot be marked as paid.");
            case (PaymentStatus.Pending, PaymentStatus.Paid):
                MarkPaid(payment, actorId, now, TextNormalizer.Clean(note) ?? "Cash collected");
                break;
            case (PaymentStatus.Pending, PaymentStatus.Failed):
            case (PaymentStatus.Failed, PaymentStatus.Pending) when payment.Order.Status != OrderStatus.Cancelled:
            case (PaymentStatus.Paid, PaymentStatus.Refunded):
                payment.Status = target;
                payment.Note = TextNormalizer.Clean(note);
                payment.UpdatedAt = now;
                break;
            default:
                throw AppException.Conflict($"A payment cannot move from {payment.Status} to {target}.");
        }

        await db.SaveChangesAsync(ct);
        return await GetForStaffAsync(paymentId, ct);
    }

    public async Task<PaymentDto> GetForStaffAsync(int paymentId, CancellationToken ct)
    {
        var payment = await LoadAsync(p => p.Id == paymentId, tracking: false, ct) ?? throw AppException.NotFound("Payment");
        return ToDto(payment, payment.Order.OrderCode);
    }

    public void MarkPaid(Payment payment, int actorId, DateTime now, string note)
    {
        payment.Status = PaymentStatus.Paid;
        payment.ConfirmedByUserId = actorId;
        payment.ConfirmedAt = now;
        payment.Note = note;
        payment.UpdatedAt = now;
    }

    public PaymentDto ToDto(Payment p, string orderCode) => new(
        p.Id, p.OrderId, orderCode, p.Method, p.Status, p.Amount, p.TransferReference, p.ConfirmedByUser?.FullName,
        p.ConfirmedAt, p.Note,
        p is { Method: PaymentMethod.BankTransfer, Status: PaymentStatus.Pending }
            ? new BankTransferInstructionsDto(_bank.BankName, _bank.AccountNumber, _bank.AccountName, p.Amount, orderCode)
            : null,
        p.CreatedAt, p.UpdatedAt);

    private Task<Payment?> LoadAsync(System.Linq.Expressions.Expression<Func<Payment, bool>> predicate, bool tracking, CancellationToken ct)
    {
        var query = db.Payments.Include(p => p.Order).Include(p => p.ConfirmedByUser).AsQueryable();
        if (!tracking) query = query.AsNoTracking();
        return query.SingleOrDefaultAsync(predicate, ct);
    }
}
