using System.IO.Compression;
using System.Xml.Linq;

/// Đọc file .xlsx (sheet đầu tiên) bằng thư viện có sẵn của .NET (không cần NuGet)
static class ExcelReader
{
    static readonly XNamespace Ns = "http://schemas.openxmlformats.org/spreadsheetml/2006/main";

    public static List<List<string>> DocSheetDauTien(byte[] data)
    {
        using var zip = new ZipArchive(new MemoryStream(data), ZipArchiveMode.Read);

        var chuoiChung = new List<string>();
        var ss = zip.GetEntry("xl/sharedStrings.xml");
        if (ss != null)
        {
            using var s = ss.Open();
            var doc = XDocument.Load(s);
            foreach (var si in doc.Root!.Elements(Ns + "si"))
                chuoiChung.Add(string.Concat(si.Descendants(Ns + "t").Select(t => t.Value)));
        }

        var sheet = zip.GetEntry("xl/worksheets/sheet1.xml")
                    ?? zip.Entries.First(e => e.FullName.StartsWith("xl/worksheets/sheet") && e.FullName.EndsWith(".xml"));
        using var st = sheet.Open();
        var sd = XDocument.Load(st);

        var dong = new List<List<string>>();
        foreach (var row in sd.Descendants(Ns + "row"))
        {
            var o = new List<string>();
            foreach (var c in row.Elements(Ns + "c"))
            {
                var r = (string?)c.Attribute("r");
                int cot = string.IsNullOrEmpty(r) ? o.Count : ChiSoCot(r);
                while (o.Count < cot) o.Add("");
                string t = (string?)c.Attribute("t") ?? "";
                string v = c.Element(Ns + "v")?.Value ?? "";
                string giaTri = t switch
                {
                    "s" => int.TryParse(v, out var i) && i < chuoiChung.Count ? chuoiChung[i] : "",
                    "inlineStr" => string.Concat(c.Descendants(Ns + "t").Select(x => x.Value)),
                    _ => v
                };
                if (o.Count == cot) o.Add(giaTri.Trim()); else o[cot] = giaTri.Trim();
            }
            dong.Add(o);
        }
        return dong;
    }

    static int ChiSoCot(string r)
    {
        int n = 0;
        foreach (var ch in r)
        {
            if (!char.IsLetter(ch)) break;
            n = n * 26 + (char.ToUpper(ch) - 'A' + 1);
        }
        return Math.Max(n - 1, 0);
    }

    /// Tìm dòng tiêu đề có "MSSV" và cột "Họ ... tên", trả về danh sách (mssv, hoTen)
    public static List<(string Mssv, string HoTen)> DocDanhSachSinhVien(byte[] data)
    {
        var dong = DocSheetDauTien(data);
        int dongTieuDe = -1, cotMssv = 1, cotTen = 2;
        for (int i = 0; i < dong.Count; i++)
        {
            int idx = dong[i].FindIndex(x => x.Equals("MSSV", StringComparison.OrdinalIgnoreCase));
            if (idx >= 0)
            {
                dongTieuDe = i;
                cotMssv = idx;
                int t = dong[i].FindIndex(x => x.ToLower().Contains("tên"));
                cotTen = t >= 0 ? t : idx + 1;
                break;
            }
        }

        var kq = new List<(string, string)>();
        for (int i = dongTieuDe + 1; i < dong.Count; i++)
        {
            var d = dong[i];
            string mssv = d.Count > cotMssv ? d[cotMssv] : "";
            string ten = d.Count > cotTen ? d[cotTen] : "";
            if (mssv.Contains('E') && double.TryParse(mssv, System.Globalization.NumberStyles.Float,
                    System.Globalization.CultureInfo.InvariantCulture, out var so))
                mssv = ((long)so).ToString();
            mssv = mssv.Trim();
            if (mssv.Length == 0 || ten.Length == 0 || !mssv.All(char.IsDigit)) continue;
            kq.Add((mssv, ten));
        }
        return kq;
    }
}
