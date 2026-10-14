using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SportMate.API.Common;
using SportMate.API.Middleware;
using SportMate.Application;
using SportMate.Application.Common;
using SportMate.Application.Interfaces;
using SportMate.Infrastructure;
using SportMate.Infrastructure.Identity;
using SportMate.Infrastructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

var jwt = builder.Configuration.GetSection(JwtSettings.Section).Get<JwtSettings>() ?? new JwtSettings();
if (string.IsNullOrWhiteSpace(jwt.Key) || Encoding.UTF8.GetByteCount(jwt.Key) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Key is missing or shorter than 32 bytes. Development reads it from appsettings.Development.json; " +
        "other environments must set it, e.g. the Jwt__Key environment variable (see backend/README.md).");
}

builder.Services.AddApplication(builder.Configuration);
builder.Services.AddInfrastructure(builder.Configuration);

// ---------- Authentication & authorization ----------
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt.Issuer,
            ValidateAudience = true,
            ValidAudience = jwt.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = AuthClaims.Name,
            RoleClaimType = AuthClaims.Role,
        };
        options.Events = new JwtBearerEvents
        {
            // Reject tokens of disabled accounts and tokens revoked by sign-out, password or role change (BR-007, BR-078).
            OnTokenValidated = async context =>
            {
                var principal = context.Principal!;
                var userId = principal.FindUserId();
                var version = principal.FindFirstValue(AuthClaims.TokenVersion);
                var db = context.HttpContext.RequestServices.GetRequiredService<IApplicationDbContext>();
                var user = userId is null
                    ? null
                    : await db.Users.AsNoTracking()
                        .Where(u => u.Id == userId)
                        .Select(u => new { u.IsActive, u.TokenVersion, u.Role })
                        .SingleOrDefaultAsync(context.HttpContext.RequestAborted);

                if (user is null || !user.IsActive || user.TokenVersion.ToString() != version
                    || !principal.IsInRole(user.Role.ToString()))
                {
                    context.Fail("Token has been revoked.");
                }
            },
        };
    });
builder.Services.AddAuthorization();

// ---------- HTTP ----------
builder.Services.AddControllers()
    .AddJsonOptions(o => o.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddProblemDetails();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Sport Mate API", Version = "v1" });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Paste the accessToken returned by /api/v1/auth/login.",
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" },
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = [] });
    c.SupportNonNullableReferenceTypes();
});

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();
// Empty 401/403/404 responses (e.g. from the auth middleware) get a Problem Details body too.
app.UseStatusCodePages();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
    app.UseCors();

    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<DataSeeder>().MigrateAndSeedAsync();
}
else
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program;
