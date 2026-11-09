using System.Data;
using Microsoft.Data.SqlClient;

// ================== API KIỂM TRA GIỮA KỲ: SQL Server + Web API ==================
// Chạy:  dotnet run      ->  http://localhost:5000
// Máy ảo Android gọi về máy tính qua địa chỉ http://10.0.2.2:5000

var builder = WebApplication.CreateBuilder(args);
// Bản cấu hình riêng ở máy (chứa mật khẩu sa, không commit lên Git)
builder.Configuration.AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true);
builder.WebHost.UseUrls("http://0.0.0.0:5000");
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
app.UseCors();

// Tự tìm SQL Server trên máy, tự tạo database KiemTraGK + bảng
string connStr = await Database.KhoiTaoAsync(builder.Configuration);

app.MapGet("/", () => "API KiemTraGK dang chay. Thu: /api/sinhvien  /api/monhoc");

// ------------------------- SINH VIÊN -------------------------
app.MapGet("/api/sinhvien", async (string? maMon) =>
{
    var ds = new List<SinhVien>();
    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    var sql = "SELECT MSSV, HoTen, Anh, MaMon FROM dbo.SinhVien"
              + (string.IsNullOrWhiteSpace(maMon) ? "" : " WHERE MaMon = @maMon")
              + " ORDER BY MSSV";
    await using var cmd = new SqlCommand(sql, cn);
    if (!string.IsNullOrWhiteSpace(maMon)) cmd.Parameters.Add("@maMon", SqlDbType.NVarChar, 20).Value = maMon;
    await using var rd = await cmd.ExecuteReaderAsync();
    while (await rd.ReadAsync())
    {
        ds.Add(new SinhVien(rd.GetString(0), rd.GetString(1),
            rd.IsDBNull(2) ? null : rd.GetString(2),
            rd.IsDBNull(3) ? null : rd.GetString(3)));
    }
    return Results.Ok(ds);
});

app.MapPost("/api/sinhvien", async (SinhVien sv) =>
{
    if (string.IsNullOrWhiteSpace(sv.Mssv) || string.IsNullOrWhiteSpace(sv.HoTen))
        return Results.BadRequest("MSSV va Ho ten khong duoc de trong");

    const string sql = @"
MERGE dbo.SinhVien AS t
USING (SELECT @mssv AS MSSV) AS s ON t.MSSV = s.MSSV
WHEN MATCHED THEN UPDATE SET HoTen = @hoTen, Anh = COALESCE(@anh, t.Anh), MaMon = COALESCE(@maMon, t.MaMon)
WHEN NOT MATCHED THEN INSERT (MSSV, HoTen, Anh, MaMon) VALUES (@mssv, @hoTen, @anh, @maMon);";

    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    await using var cmd = new SqlCommand(sql, cn);
    cmd.Parameters.Add("@mssv", SqlDbType.NVarChar, 20).Value = sv.Mssv.Trim();
    cmd.Parameters.Add("@hoTen", SqlDbType.NVarChar, 100).Value = sv.HoTen.Trim();
    cmd.Parameters.Add("@anh", SqlDbType.NVarChar, -1).Value = (object?)sv.Anh ?? DBNull.Value;
    cmd.Parameters.Add("@maMon", SqlDbType.NVarChar, 20).Value = string.IsNullOrWhiteSpace(sv.MaMon) ? DBNull.Value : sv.MaMon.Trim();
    await cmd.ExecuteNonQueryAsync();
    return Results.Ok(new { message = "Da luu sinh vien", mssv = sv.Mssv });
});

// Nhập danh sách sinh viên từ file Excel (bố cục: STT | MSSV | Họ và tên)
app.MapPost("/api/sinhvien/import", async (NhapExcel req) =>
{
    byte[] data;
    try { data = Convert.FromBase64String(req.FileBase64); }
    catch { return Results.BadRequest("File khong hop le"); }

    List<(string Mssv, string HoTen)> ds;
    try { ds = ExcelReader.DocDanhSachSinhVien(data); }
    catch (Exception ex) { return Results.BadRequest("Khong doc duoc file Excel: " + ex.Message); }

    const string sql = @"
MERGE dbo.SinhVien AS t
USING (SELECT @mssv AS MSSV) AS s ON t.MSSV = s.MSSV
WHEN MATCHED THEN UPDATE SET HoTen = @hoTen, MaMon = COALESCE(@maMon, t.MaMon)
WHEN NOT MATCHED THEN INSERT (MSSV, HoTen, MaMon) VALUES (@mssv, @hoTen, @maMon);";

    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    foreach (var sv in ds)
    {
        await using var cmd = new SqlCommand(sql, cn);
        cmd.Parameters.Add("@mssv", SqlDbType.NVarChar, 20).Value = sv.Mssv;
        cmd.Parameters.Add("@hoTen", SqlDbType.NVarChar, 100).Value = sv.HoTen;
        cmd.Parameters.Add("@maMon", SqlDbType.NVarChar, 20).Value =
            string.IsNullOrWhiteSpace(req.MaMon) ? DBNull.Value : req.MaMon.Trim();
        await cmd.ExecuteNonQueryAsync();
    }
    return Results.Ok(new { soLuong = ds.Count });
});

app.MapDelete("/api/sinhvien/{mssv}", async (string mssv) =>
{
    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    await using var cmd = new SqlCommand("DELETE FROM dbo.SinhVien WHERE MSSV = @mssv", cn);
    cmd.Parameters.Add("@mssv", SqlDbType.NVarChar, 20).Value = mssv;
    int n = await cmd.ExecuteNonQueryAsync();
    return n > 0 ? Results.Ok(new { message = "Da xoa" }) : Results.NotFound("Khong tim thay sinh vien");
});

// ------------------------- MÔN HỌC -------------------------
app.MapGet("/api/monhoc", async () =>
{
    var ds = new List<MonHoc>();
    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    await using var cmd = new SqlCommand("SELECT MaMon, TenMon, CoSo, GioHoc FROM dbo.MonHoc ORDER BY MaMon", cn);
    await using var rd = await cmd.ExecuteReaderAsync();
    while (await rd.ReadAsync())
    {
        ds.Add(new MonHoc(rd.GetString(0), rd.GetString(1), rd.GetString(2), rd.IsDBNull(3) ? null : rd.GetString(3)));
    }
    return Results.Ok(ds);
});

app.MapPost("/api/monhoc", async (MonHoc mh) =>
{
    if (string.IsNullOrWhiteSpace(mh.MaMon) || string.IsNullOrWhiteSpace(mh.TenMon) || string.IsNullOrWhiteSpace(mh.CoSo))
        return Results.BadRequest("Ma mon, ten mon, co so khong duoc de trong");

    const string sql = @"
MERGE dbo.MonHoc AS t
USING (SELECT @maMon AS MaMon) AS s ON t.MaMon = s.MaMon
WHEN MATCHED THEN UPDATE SET TenMon = @tenMon, CoSo = @coSo, GioHoc = @gioHoc
WHEN NOT MATCHED THEN INSERT (MaMon, TenMon, CoSo, GioHoc) VALUES (@maMon, @tenMon, @coSo, @gioHoc);";

    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    await using var cmd = new SqlCommand(sql, cn);
    cmd.Parameters.Add("@maMon", SqlDbType.NVarChar, 20).Value = mh.MaMon.Trim();
    cmd.Parameters.Add("@tenMon", SqlDbType.NVarChar, 200).Value = mh.TenMon.Trim();
    cmd.Parameters.Add("@coSo", SqlDbType.NVarChar, 50).Value = mh.CoSo.Trim();
    cmd.Parameters.Add("@gioHoc", SqlDbType.NVarChar, 30).Value = (object?)mh.GioHoc ?? DBNull.Value;
    await cmd.ExecuteNonQueryAsync();
    return Results.Ok(new { message = "Da luu mon hoc", maMon = mh.MaMon });
});

app.MapDelete("/api/monhoc/{maMon}", async (string maMon) =>
{
    await using var cn = new SqlConnection(connStr);
    await cn.OpenAsync();
    await using var cmd = new SqlCommand("UPDATE dbo.SinhVien SET MaMon = NULL WHERE MaMon = @m; DELETE FROM dbo.MonHoc WHERE MaMon = @m", cn);
    cmd.Parameters.Add("@m", SqlDbType.NVarChar, 20).Value = maMon;
    await cmd.ExecuteNonQueryAsync();
    return Results.Ok(new { message = "Da xoa" });
});

app.Run();

// ------------------------- MODEL -------------------------
record SinhVien(string Mssv, string HoTen, string? Anh, string? MaMon);
record NhapExcel(string FileBase64, string? MaMon);
record MonHoc(string MaMon, string TenMon, string CoSo, string? GioHoc);

// ------------------------- DATABASE -------------------------
static class Database
{
    const string TaoBang = @"
IF OBJECT_ID('dbo.SinhVien', 'U') IS NULL
CREATE TABLE dbo.SinhVien (
    MSSV  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Anh   NVARCHAR(MAX) NULL
);
IF OBJECT_ID('dbo.MonHoc', 'U') IS NULL
CREATE TABLE dbo.MonHoc (
    MaMon  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    TenMon NVARCHAR(200) NOT NULL,
    CoSo   NVARCHAR(50)  NOT NULL,
    GioHoc NVARCHAR(30)  NULL
);
IF COL_LENGTH('dbo.SinhVien', 'MaMon') IS NULL
    ALTER TABLE dbo.SinhVien ADD MaMon NVARCHAR(20) NULL;
IF NOT EXISTS (SELECT 1 FROM dbo.MonHoc)
    INSERT INTO dbo.MonHoc (MaMon, TenMon, CoSo) VALUES (N'1', N'Lập trình đa nền tảng', N'Lê Văn Sỹ');";

    public static async Task<string> KhoiTaoAsync(IConfiguration cfg)
    {
        var dsKetNoi = new List<string>();
        var tuCauHinh = cfg["SqlServer:ConnectionString"];
        if (!string.IsNullOrWhiteSpace(tuCauHinh)) dsKetNoi.Add(tuCauHinh);

        // Thử lần lượt các SQL Server hay gặp trên máy sinh viên (Windows Authentication)
        foreach (var server in new[] { @"localhost\SQLEXPRESS", @".\SQLEXPRESS", ".", "localhost", @"(localdb)\MSSQLLocalDB" })
            dsKetNoi.Add($"Server={server};Database=master;Trusted_Connection=True;TrustServerCertificate=True;Connect Timeout=5");

        Exception? loiCuoi = null;
        foreach (var chuoi in dsKetNoi)
        {
            var b = new SqlConnectionStringBuilder(chuoi) { InitialCatalog = "master" };
            try
            {
                await using (var cn = new SqlConnection(b.ConnectionString))
                {
                    await cn.OpenAsync();
                    await using var cmd = new SqlCommand("IF DB_ID('KiemTraGK') IS NULL CREATE DATABASE KiemTraGK;", cn);
                    await cmd.ExecuteNonQueryAsync();
                }

                b.InitialCatalog = "KiemTraGK";
                await using (var cn = new SqlConnection(b.ConnectionString))
                {
                    await cn.OpenAsync();
                    await using var cmd = new SqlCommand(TaoBang, cn);
                    await cmd.ExecuteNonQueryAsync();
                }

                Console.WriteLine($">>> Da ket noi SQL Server '{b.DataSource}', database KiemTraGK san sang.");
                return b.ConnectionString;
            }
            catch (Exception ex)
            {
                loiCuoi = ex;
                Console.WriteLine($">>> Khong ket noi duoc '{b.DataSource}': {ex.Message}");
            }
        }

        throw new Exception("Khong ket noi duoc SQL Server. Hay dien chuoi ket noi vao appsettings.json -> SqlServer:ConnectionString", loiCuoi);
    }
}
