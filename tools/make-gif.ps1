Add-Type -ReferencedAssemblies 'System.Drawing' -TypeDefinition @'
using System;
using System.IO;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Text;
using System.Runtime.InteropServices;

public static class GifMaker
{
    static Color[] Pal;

    static int Nearest(int argb)
    {
        int r = (argb >> 16) & 0xFF, g = (argb >> 8) & 0xFF, b = argb & 0xFF;
        int best = 0; long bd = long.MaxValue;
        for (int i = 0; i < Pal.Length; i++)
        {
            int dr = r - Pal[i].R, dg = g - Pal[i].G, db = b - Pal[i].B;
            long d = (long)dr * dr + (long)dg * dg + (long)db * db;
            if (d < bd) { bd = d; best = i; }
        }
        return best;
    }

    // ---- LZW state (compress.c / Kevin-Weiner-Semantik) ----
    static List<byte> _out;
    static int _bitBuffer, _bitCount, _codeSize, _maxCode, _freeEnt, _clearCode, _eofCode, _initBits;
    static bool _clearFlg;
    const int MAXBITS = 12;
    const int MAXMAX = 1 << 12;

    static void EmitBits(int code)
    {
        _bitBuffer |= code << _bitCount;
        _bitCount += _codeSize;
        while (_bitCount >= 8)
        {
            _out.Add((byte)(_bitBuffer & 0xFF));
            _bitBuffer = (int)((uint)_bitBuffer >> 8);
            _bitCount -= 8;
        }
    }

    // Code-Breiten-Wechsel wird NACH dem Emittieren geprueft (Verzoegerung um 1 Code)
    static void Output(int code)
    {
        EmitBits(code);
        if (_freeEnt > _maxCode || _clearFlg)
        {
            if (_clearFlg) { _codeSize = _initBits; _maxCode = (1 << _codeSize) - 1; _clearFlg = false; }
            else { _codeSize++; if (_codeSize == MAXBITS) _maxCode = MAXMAX; else _maxCode = (1 << _codeSize) - 1; }
        }
    }

    static byte[] Encode(byte[] px, int minCode)
    {
        _out = new List<byte>(); _bitBuffer = 0; _bitCount = 0;
        _clearCode = 1 << minCode; _eofCode = _clearCode + 1; _initBits = minCode + 1;
        _codeSize = _initBits; _maxCode = (1 << _codeSize) - 1; _freeEnt = _eofCode + 1; _clearFlg = false;
        Dictionary<int, int> dict = new Dictionary<int, int>();
        Output(_clearCode);
        int prefix = px[0];
        for (int i = 1; i < px.Length; i++)
        {
            int k = px[i];
            int key = (prefix << 8) | k;
            int code;
            if (dict.TryGetValue(key, out code)) { prefix = code; continue; }
            Output(prefix);
            if (_freeEnt < MAXMAX) { dict[key] = _freeEnt; _freeEnt++; }
            else { dict.Clear(); _freeEnt = _clearCode + 2; _clearFlg = true; Output(_clearCode); }
            prefix = k;
        }
        Output(prefix);
        Output(_eofCode);
        if (_bitCount > 0) { _out.Add((byte)(_bitBuffer & 0xFF)); }
        return _out.ToArray();
    }

    static void RoundRect(Graphics g, Rectangle r, int rad, Brush fill, Pen pen)
    {
        GraphicsPath p = new GraphicsPath();
        p.AddArc(r.X, r.Y, rad, rad, 180, 90);
        p.AddArc(r.Right - rad, r.Y, rad, rad, 270, 90);
        p.AddArc(r.Right - rad, r.Bottom - rad, rad, rad, 0, 90);
        p.AddArc(r.X, r.Bottom - rad, rad, rad, 90, 90);
        p.CloseFigure();
        if (fill != null) g.FillPath(fill, p);
        if (pen != null) g.DrawPath(pen, p);
        p.Dispose();
    }

    static void ShareIcon(Graphics g, int cx, int cy, Pen pen)
    {
        // Tray
        g.DrawLine(pen, cx - 13, cy - 2, cx - 13, cy + 16);
        g.DrawLine(pen, cx + 13, cy - 2, cx + 13, cy + 16);
        g.DrawLine(pen, cx - 13, cy + 16, cx + 13, cy + 16);
        g.DrawLine(pen, cx - 13, cy - 2, cx - 7, cy - 2);
        g.DrawLine(pen, cx + 13, cy - 2, cx + 7, cy - 2);
        // Up arrow
        g.DrawLine(pen, cx, cy - 18, cx, cy + 6);
        g.DrawLine(pen, cx, cy - 18, cx - 6, cy - 12);
        g.DrawLine(pen, cx, cy - 18, cx + 6, cy - 12);
    }

    static void DotsIcon(Graphics g, int cx, int cy, Brush b)
    {
        g.FillEllipse(b, cx - 13, cy - 3, 6, 6);
        g.FillEllipse(b, cx - 4,  cy - 3, 6, 6);
        g.FillEllipse(b, cx + 5,  cy - 3, 6, 6);
    }

    static void DrawScene(Graphics g, int W, int H, int f, int frames, bool compact)
    {
        Color bg = Pal[0], white = Pal[1], blue = Pal[2], dark = Pal[3], border = Pal[4], gray = Pal[5], ring = Pal[6];
        g.Clear(bg);

        // Header
        g.FillRectangle(new SolidBrush(blue), 0, 0, W, 140);
        StringFormat ctr = new StringFormat();
        ctr.Alignment = StringAlignment.Center; ctr.LineAlignment = StringAlignment.Center;
        Font fTitle = new Font("Segoe UI", 36, FontStyle.Bold, GraphicsUnit.Pixel);
        Font fSub = new Font("Segoe UI", 19, FontStyle.Regular, GraphicsUnit.Pixel);
        g.DrawString("Meine App", fTitle, new SolidBrush(white), new RectangleF(0, 28, W, 52), ctr);
        g.DrawString("auf den Startbildschirm legen", fSub, new SolidBrush(white), new RectangleF(0, 92, W, 30), ctr);

        // Body hint
        Font fBody = new Font("Segoe UI", 20, FontStyle.Regular, GraphicsUnit.Pixel);
        string hint = compact ? "iOS 26: in Safari unten auf  ...  tippen"
                              : "In Safari unten auf das Symbol tippen";
        g.DrawString(hint, fBody, new SolidBrush(dark), new RectangleF(20, 172, W - 40, 64), ctr);

        int rr = 16 + (f % 12) * 2;
        int bob = (int)Math.Round(7.0 * Math.Sin(2 * Math.PI * f / frames));
        Pen pGray = new Pen(gray, 3); pGray.StartCap = LineCap.Round; pGray.EndCap = LineCap.Round;
        Pen pBlue = new Pen(blue, 3); pBlue.StartCap = LineCap.Round; pBlue.EndCap = LineCap.Round; pBlue.LineJoin = LineJoin.Round;
        Font fB1 = new Font("Segoe UI", 22, FontStyle.Bold, GraphicsUnit.Pixel);
        Font fB2 = new Font("Segoe UI", 16, FontStyle.Regular, GraphicsUnit.Pixel);

        if (!compact)
        {
            // ---- Klassische Safari-Leiste (iOS < 26): Teilen-Symbol sichtbar ----
            int barY = H - 70;
            g.FillRectangle(new SolidBrush(white), 0, barY, W, 70);
            g.DrawLine(new Pen(border, 1), 0, barY, W, barY);
            int iy = barY + 34;
            g.DrawLine(pGray, 46, iy - 8, 38, iy); g.DrawLine(pGray, 38, iy, 46, iy + 8);
            g.DrawLine(pGray, 104, iy - 8, 112, iy); g.DrawLine(pGray, 112, iy, 104, iy + 8);
            g.DrawRectangle(pGray, 240, iy - 9, 16, 18);
            g.DrawRectangle(pGray, 300, iy - 9, 14, 14); g.DrawRectangle(pGray, 306, iy - 4, 14, 14);

            int cx = 180, cy = iy;
            g.DrawEllipse(new Pen(ring, 3), cx - rr, cy - rr, rr * 2, rr * 2);
            ShareIcon(g, cx, cy, pBlue);

            int bw = 244, bh = 72;
            int bx = cx - bw / 2;
            int by = barY - bh - 14 + bob;
            RoundRect(g, new Rectangle(bx, by, bw, bh), 20, new SolidBrush(blue), null);
            GraphicsPath tri = new GraphicsPath();
            tri.AddPolygon(new Point[] { new Point(cx - 13, by + bh - 1), new Point(cx + 13, by + bh - 1), new Point(cx, by + bh + 18) });
            g.FillPath(new SolidBrush(blue), tri); tri.Dispose();
            g.DrawString("Hier tippen", fB1, new SolidBrush(white), new RectangleF(bx, by + 12, bw, 30), ctr);
            g.DrawString("dann: Zum Home-Bildschirm", fB2, new SolidBrush(white), new RectangleF(bx, by + 43, bw, 24), ctr);
        }
        else
        {
            // ---- iOS 26 "Kompakt": Teilen steckt hinter dem ...-Knopf ----
            int pillX = 24, pillW = W - 48, pillH = 48;
            int pillY = H - 92;
            RoundRect(g, new Rectangle(pillX, pillY, pillW, pillH), pillH, new SolidBrush(white), new Pen(border, 1));
            int cy = pillY + pillH / 2;
            g.DrawLine(pGray, 58, cy - 7, 50, cy); g.DrawLine(pGray, 50, cy, 58, cy + 7);
            Font fUrl = new Font("Segoe UI", 18, FontStyle.Regular, GraphicsUnit.Pixel);
            StringFormat lft = new StringFormat(); lft.Alignment = StringAlignment.Near; lft.LineAlignment = StringAlignment.Center;
            g.DrawString("ari-lzkth.github.io", fUrl, new SolidBrush(gray), new RectangleF(82, pillY, pillW - 140, pillH), lft);

            int cx = W - 58;
            g.DrawEllipse(new Pen(ring, 3), cx - rr, cy - rr, rr * 2, rr * 2);
            DotsIcon(g, cx, cy, new SolidBrush(blue));

            int bw = 268, bh = 74;
            int bx = W - bw - 8;
            int by = pillY - bh - 14 + bob;
            RoundRect(g, new Rectangle(bx, by, bw, bh), 20, new SolidBrush(blue), null);
            GraphicsPath tri = new GraphicsPath();
            tri.AddPolygon(new Point[] { new Point(cx - 13, by + bh - 1), new Point(cx + 13, by + bh - 1), new Point(cx, by + bh + 18) });
            g.FillPath(new SolidBrush(blue), tri); tri.Dispose();
            g.DrawString("Tippe auf  ...", fB1, new SolidBrush(white), new RectangleF(bx, by + 12, bw, 30), ctr);
            g.DrawString("Teilen -> Zum Home-Bildschirm", fB2, new SolidBrush(white), new RectangleF(bx, by + 43, bw, 24), ctr);
        }
    }

    public static void Make(string path, int W, int H, int frames, int delayCs, bool compact)
    {
        Pal = new Color[] {
            Color.FromArgb(0xf5,0xf6,0xf8), // 0 bg
            Color.FromArgb(0xff,0xff,0xff), // 1 white
            Color.FromArgb(0x0d,0x6e,0xfd), // 2 blue
            Color.FromArgb(0x1a,0x1a,0x1a), // 3 dark
            Color.FromArgb(0xe2,0xe4,0xe9), // 4 border
            Color.FromArgb(0x88,0x88,0x88), // 5 gray
            Color.FromArgb(0xae,0xc8,0xff), // 6 ring light-blue
            Color.FromArgb(0x00,0x00,0x00)  // 7 pad
        };
        int minCode = 3; // 8-color table

        FileStream fs = new FileStream(path, FileMode.Create);
        // Header
        byte[] hdr = System.Text.Encoding.ASCII.GetBytes("GIF89a");
        fs.Write(hdr, 0, hdr.Length);
        // Logical Screen Descriptor
        fs.WriteByte((byte)(W & 0xFF)); fs.WriteByte((byte)(W >> 8));
        fs.WriteByte((byte)(H & 0xFF)); fs.WriteByte((byte)(H >> 8));
        fs.WriteByte(0xA2); // GCT, 8 entries
        fs.WriteByte(0);    // bg index
        fs.WriteByte(0);    // aspect
        for (int i = 0; i < 8; i++) { fs.WriteByte(Pal[i].R); fs.WriteByte(Pal[i].G); fs.WriteByte(Pal[i].B); }
        // NETSCAPE loop
        byte[] loop = new byte[] { 0x21, 0xFF, 0x0B, (byte)'N',(byte)'E',(byte)'T',(byte)'S',(byte)'C',(byte)'A',(byte)'P',(byte)'E',(byte)'2',(byte)'.',(byte)'0', 0x03, 0x01, 0x00, 0x00, 0x00 };
        fs.Write(loop, 0, loop.Length);

        for (int f = 0; f < frames; f++)
        {
            byte[] idx = new byte[W * H];
            Bitmap bmp = new Bitmap(W, H);
            Graphics g = Graphics.FromImage(bmp);
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            DrawScene(g, W, H, f, frames, compact);
            g.Dispose();
            System.Drawing.Imaging.BitmapData bd = bmp.LockBits(new Rectangle(0, 0, W, H),
                System.Drawing.Imaging.ImageLockMode.ReadOnly, System.Drawing.Imaging.PixelFormat.Format32bppArgb);
            int[] pix = new int[W * H];
            Marshal.Copy(bd.Scan0, pix, 0, W * H);
            bmp.UnlockBits(bd); bmp.Dispose();
            for (int i = 0; i < pix.Length; i++) idx[i] = (byte)Nearest(pix[i]);

            // Graphic Control Extension
            fs.WriteByte(0x21); fs.WriteByte(0xF9); fs.WriteByte(0x04);
            fs.WriteByte(0x04); // disposal = 1
            fs.WriteByte((byte)(delayCs & 0xFF)); fs.WriteByte((byte)(delayCs >> 8));
            fs.WriteByte(0x00); fs.WriteByte(0x00);
            // Image Descriptor
            fs.WriteByte(0x2C);
            fs.WriteByte(0); fs.WriteByte(0); fs.WriteByte(0); fs.WriteByte(0);
            fs.WriteByte((byte)(W & 0xFF)); fs.WriteByte((byte)(W >> 8));
            fs.WriteByte((byte)(H & 0xFF)); fs.WriteByte((byte)(H >> 8));
            fs.WriteByte(0x00); // no local color table
            fs.WriteByte((byte)minCode);
            byte[] data = Encode(idx, minCode);
            int off = 0;
            while (off < data.Length)
            {
                int n = Math.Min(255, data.Length - off);
                fs.WriteByte((byte)n);
                fs.Write(data, off, n);
                off += n;
            }
            fs.WriteByte(0x00); // block terminator
        }
        fs.WriteByte(0x3B); // trailer
        fs.Close();
    }
}
'@

$dir = "C:\Users\Andreas.Richter\Documents\Claude\Projects\PWA\pwa-install-kit"
$classic = Join-Path $dir "ios-install.gif"
$ios26   = Join-Path $dir "ios26-install.gif"
[GifMaker]::Make($classic, 360, 640, 24, 8, $false)
[GifMaker]::Make($ios26,   360, 640, 24, 8, $true)
Write-Host ("erstellt: {0}  ({1:N0} bytes)" -f $classic, (Get-Item $classic).Length)
Write-Host ("erstellt: {0}  ({1:N0} bytes)" -f $ios26,   (Get-Item $ios26).Length)