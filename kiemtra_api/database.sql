-- Script tạo CSDL (API cũng tự chạy đoạn này khi khởi động, chỉ cần dùng nếu muốn tạo bằng SSMS)
IF DB_ID('KiemTraGK') IS NULL CREATE DATABASE KiemTraGK;
GO
USE KiemTraGK;
GO
IF OBJECT_ID('dbo.SinhVien', 'U') IS NULL
CREATE TABLE dbo.SinhVien (
    MSSV  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Anh   NVARCHAR(MAX) NULL      -- ảnh dạng base64
);
IF OBJECT_ID('dbo.MonHoc', 'U') IS NULL
CREATE TABLE dbo.MonHoc (
    MaMon  NVARCHAR(20)  NOT NULL PRIMARY KEY,
    TenMon NVARCHAR(200) NOT NULL,
    CoSo   NVARCHAR(50)  NOT NULL,
    GioHoc NVARCHAR(30)  NULL
);
GO
SELECT * FROM dbo.SinhVien;
SELECT * FROM dbo.MonHoc;
