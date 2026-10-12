// Backend S — direct OpenXML SDK generator for the rewritten formal paper.
//
// Recipe family: AcademicThesis (APA-style), values taken from
// scripts/dotnet/MiniMaxAIDocx.Core/Samples/AestheticRecipeSamples.cs
// -> CreateAcademicThesisDocument:
//   Times New Roman 12pt, double spacing (480), 0.5in first-line indent,
//   all headings 12pt with hierarchy via bold/italic/centering,
//   APA page numbers top-right in the header, italic 12pt captions.
//
// Localizations vs the sample: A4 instead of Letter (1.27in margins on all
// sides instead of a 1.5in binding margin, because the figures are 6.1in wide
// and need the extra column).
//
// Image embedding follows ImageSamples.cs -> BuildDrawingElement: the
// Drawing/DW.Inline extent and PIC.ShapeProperties extents MUST match, the
// ImagePart is added to the MainDocumentPart, and each Drawing needs a unique
// DocProperties Id.

using System.Text.Json;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using A = DocumentFormat.OpenXml.Drawing;
using DW = DocumentFormat.OpenXml.Drawing.Wordprocessing;
using PIC = DocumentFormat.OpenXml.Drawing.Pictures;

internal static class Program
{
    const long EmuPerInch = 914400L;
    const int BodyHalfPts = 24;          // 12pt
    const int EqDpi = 600;               // equations were rasterized at 600dpi

    // A4 with 1in margins -> usable text width
    const int PageW = 11906, PageH = 16838, Margin = 1440;
    static int UsableDxa => PageW - 2 * Margin;   // 9026 dxa = 6.27in

    static uint _docPropId = 1;

    static int Main(string[] args)
    {
        string planPath = args.Length > 0 ? args[0] : "content.json";
        string outPath = args.Length > 1 ? args[1] : "out.docx";

        using var jdoc = JsonDocument.Parse(File.ReadAllText(planPath));
        var root = jdoc.RootElement;
        var meta = root.GetProperty("meta");
        string title = meta.GetProperty("title").GetString();
        string runningHead = meta.GetProperty("running_head").GetString();

        // Author and affiliation come from content.json rather than being
        // hardcoded here, so renaming the author is a one-line change in
        // content.py instead of a rebuild-and-hunt in the generator.
        string author = meta.TryGetProperty("author", out var a) ? a.GetString() : null;
        string affiliation = meta.TryGetProperty("affiliation", out var af) ? af.GetString() : null;

        if (File.Exists(outPath)) File.Delete(outPath);
        using var doc = WordprocessingDocument.Create(outPath, WordprocessingDocumentType.Document);
        var main = doc.AddMainDocumentPart();
        main.Document = new Document(new Body());
        var body = main.Document.Body;

        BuildStyles(main);

        var sectPr = new SectionProperties();
        sectPr.Append(new PageSize { Width = (UInt32Value)(uint)PageW, Height = (UInt32Value)(uint)PageH });
        sectPr.Append(new PageMargin
        {
            Top = Margin,
            Bottom = Margin,
            Left = (UInt32Value)(uint)Margin,
            Right = (UInt32Value)(uint)Margin,
            Header = 720U,
            Footer = 720U,
            Gutter = 0U
        });

        // APA: running head + page number, right aligned, in the header.
        var headerPart = main.AddNewPart<HeaderPart>();
        headerPart.Header = new Header(
            new Paragraph(
                new ParagraphProperties(
                    new Tabs(new TabStop { Val = TabStopValues.Right, Position = UsableDxa }),
                    new SpacingBetweenLines { Line = "240", LineRule = LineSpacingRuleValues.Auto, After = "0" },
                    new Indentation { FirstLine = "0" },
                    new Justification { Val = JustificationValues.Right }),
                new Run(
                    new RunProperties(
                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                        new FontSize { Val = "20" },
                        new Color { Val = "404040" }),
                    new Text(runningHead + "\t") { Space = SpaceProcessingModeValues.Preserve }),
                new Run(
                    new RunProperties(
                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                        new FontSize { Val = "20" },
                        new Color { Val = "404040" }),
                    new FieldChar { FieldCharType = FieldCharValues.Begin }),
                new Run(
                    new RunProperties(
                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                        new FontSize { Val = "20" },
                        new Color { Val = "404040" }),
                    new FieldCode(" PAGE ") { Space = SpaceProcessingModeValues.Preserve }),
                new Run(
                    new RunProperties(
                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                        new FontSize { Val = "20" },
                        new Color { Val = "404040" }),
                    new FieldChar { FieldCharType = FieldCharValues.End })));
        sectPr.Append(new HeaderReference { Type = HeaderFooterValues.Default, Id = main.GetIdOfPart(headerPart) });

        // ── title block ──
        body.Append(Para(title, sizeHalfPts: 28, bold: true, centered: true, indent: false,
                         spaceBefore: 0, spaceAfter: 240));
        if (!string.IsNullOrEmpty(author))
        {
            bool hasAffiliation = !string.IsNullOrEmpty(affiliation);
            body.Append(Para(author, sizeHalfPts: 24, centered: true, indent: false,
                             spaceAfter: hasAffiliation ? 60 : 360));
            if (hasAffiliation)
                body.Append(Para(affiliation, sizeHalfPts: 22, centered: true, indent: false,
                                 spaceAfter: 360));
        }

        // ── body blocks ──
        int nRefs = 0;
        foreach (var b in root.GetProperty("blocks").EnumerateArray())
        {
            switch (b.GetProperty("t").GetString())
            {
                case "h1":
                    body.Append(Para(b.GetProperty("text").GetString(), bold: true, centered: true,
                                     indent: false, spaceBefore: 360, keepNext: true));
                    break;

                case "p":
                    body.Append(Para(b.GetProperty("text").GetString(), indent: true));
                    break;

                case "eq":
                    body.Append(EquationParagraph(main,
                        b.GetProperty("path").GetString(),
                        b.GetProperty("num").GetInt32()));
                    break;

                case "fig":
                    body.Append(FigureParagraph(main,
                        b.GetProperty("path").GetString(),
                        b.GetProperty("widthIn").GetDouble()));
                    body.Append(Para(b.GetProperty("cap").GetString(), italic: true, indent: false,
                                     spaceBefore: 60, spaceAfter: 240, sizeHalfPts: 20));
                    break;

                case "refs":
                    foreach (var r in b.GetProperty("items").EnumerateArray())
                    {
                        nRefs++;
                        var p = new Paragraph(
                            new ParagraphProperties(
                                new Tabs(new TabStop { Val = TabStopValues.Left, Position = 480 }),
                                new SpacingBetweenLines { Line = "240", LineRule = LineSpacingRuleValues.Auto, After = "80" },
                                new Indentation { Left = "480", Hanging = "480" },
                                new Justification { Val = JustificationValues.Left }),
                            new Run(new RunProperties(
                                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                                        new FontSize { Val = "20" }),
                                    new Text($"{nRefs}.\t") { Space = SpaceProcessingModeValues.Preserve }),
                            new Run(new RunProperties(
                                        new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                                        new FontSize { Val = "20" }),
                                    new Text(r.GetString()) { Space = SpaceProcessingModeValues.Preserve }));
                        body.Append(p);
                    }
                    break;
            }
        }

        sectPr.Append(new DocGrid { LinePitch = 360 });
        body.Append(sectPr);
        main.Document.Save();

        Console.WriteLine($"wrote {outPath}");
        Console.WriteLine($"  running head : {runningHead}");
        Console.WriteLine($"  references    : {nRefs}");
        return 0;
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    static Paragraph Para(string text, bool bold = false, bool italic = false, bool centered = false,
                          bool indent = true, int spaceBefore = 0, int spaceAfter = 0,
                          int sizeHalfPts = BodyHalfPts, bool keepNext = false)
    {
        var pPr = new ParagraphProperties();
        if (keepNext) pPr.Append(new KeepNext());
        pPr.Append(new SpacingBetweenLines
        {
            Line = centered ? "240" : "480",
            LineRule = LineSpacingRuleValues.Auto,
            Before = spaceBefore.ToString(),
            After = spaceAfter.ToString()
        });
        pPr.Append(new Indentation { FirstLine = indent ? "720" : "0" });
        if (centered) pPr.Append(new Justification { Val = JustificationValues.Center });

        var rPr = new RunProperties(
            new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
            new FontSize { Val = sizeHalfPts.ToString() });
        if (bold) rPr.Append(new Bold());
        if (italic) rPr.Append(new Italic());

        return new Paragraph(pPr, new Run(rPr, new Text(text) { Space = SpaceProcessingModeValues.Preserve }));
    }

    /// Centered equation image with a right-aligned equation number, LaTeX style.
    static Paragraph EquationParagraph(MainDocumentPart main, string path, int num)
    {
        var (cx, cy) = PngSize(path);
        long dispW = (long)(cx / (double)EqDpi * EmuPerInch);
        long dispH = (long)(cy / (double)EqDpi * EmuPerInch);

        var p = new Paragraph(new ParagraphProperties(
            new Tabs(
                new TabStop { Val = TabStopValues.Center, Position = UsableDxa / 2 },
                new TabStop { Val = TabStopValues.Right, Position = UsableDxa }),
            new SpacingBetweenLines { Line = "240", LineRule = LineSpacingRuleValues.Auto, Before = "160", After = "160" },
            new Indentation { FirstLine = "0" }));

        p.Append(new Run(new TabChar()));
        p.Append(new Run(BuildDrawing(main, path, dispW, dispH, $"eq{num}")));
        p.Append(new Run(new TabChar(),
                         new RunProperties(
                             new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                             new FontSize { Val = BodyHalfPts.ToString() }),
                         new Text($"({num})") { Space = SpaceProcessingModeValues.Preserve }));
        return p;
    }

    static Paragraph FigureParagraph(MainDocumentPart main, string path, double widthIn)
    {
        var (cx, cy) = PngSize(path);
        long dispW = (long)(widthIn * EmuPerInch);
        long dispH = (long)(dispW * (cy / (double)cx));

        var p = new Paragraph(new ParagraphProperties(
            new KeepNext(),
            new SpacingBetweenLines { Line = "240", LineRule = LineSpacingRuleValues.Auto, Before = "240", After = "60" },
            new Indentation { FirstLine = "0" },
            new Justification { Val = JustificationValues.Center }));
        p.Append(new Run(BuildDrawing(main, path, dispW, dispH, Path.GetFileName(path))));
        return p;
    }

    /// ImageSamples.BuildDrawingElement: DW.Inline extent and PIC extents must match.
    static Drawing BuildDrawing(MainDocumentPart main, string path, long cx, long cy, string name)
    {
        ImagePart imagePart = main.AddImagePart(ImagePartType.Png);
        using (var fs = File.OpenRead(path)) imagePart.FeedData(fs);
        string relId = main.GetIdOfPart(imagePart);
        uint id = _docPropId++;

        var docProps = new DW.DocProperties { Id = id, Name = name };

        var picture = new PIC.Picture(
            new PIC.NonVisualPictureProperties(
                new PIC.NonVisualDrawingProperties { Id = 0U, Name = name },
                new PIC.NonVisualPictureDrawingProperties()),
            new PIC.BlipFill(
                new A.Blip { Embed = relId, CompressionState = A.BlipCompressionValues.Print },
                new A.Stretch(new A.FillRectangle())),
            new PIC.ShapeProperties(
                new A.Transform2D(
                    new A.Offset { X = 0L, Y = 0L },
                    new A.Extents { Cx = cx, Cy = cy }),
                new A.PresetGeometry(new A.AdjustValueList()) { Preset = A.ShapeTypeValues.Rectangle }));

        return new Drawing(
            new DW.Inline(
                new DW.Extent { Cx = cx, Cy = cy },
                new DW.EffectExtent { LeftEdge = 0L, TopEdge = 0L, RightEdge = 0L, BottomEdge = 0L },
                docProps,
                new DW.NonVisualGraphicFrameDrawingProperties(
                    new A.GraphicFrameLocks { NoChangeAspect = true }),
                new A.Graphic(
                    new A.GraphicData(picture)
                    { Uri = "http://schemas.openxmlformats.org/drawingml/2006/picture" }))
            {
                DistanceFromTop = 0U,
                DistanceFromBottom = 0U,
                DistanceFromLeft = 0U,
                DistanceFromRight = 0U
            });
    }

    /// Read pixel size from the PNG IHDR chunk, keeping aspect ratio.
    static (long cx, long cy) PngSize(string path)
    {
        byte[] head = new byte[24];
        using (var fs = File.OpenRead(path))
        {
            if (fs.Read(head, 0, 24) < 24)
                throw new InvalidOperationException("not a PNG: " + path);
        }
        int w = (head[16] << 24) | (head[17] << 16) | (head[18] << 8) | head[19];
        int h = (head[20] << 24) | (head[21] << 16) | (head[22] << 8) | head[23];
        return (w, h);
    }

    /// AcademicThesis recipe defaults.
    static void BuildStyles(MainDocumentPart main)
    {
        var part = main.AddNewPart<StyleDefinitionsPart>();
        var styles = new Styles();

        styles.Append(new DocDefaults(
            new RunPropertiesDefault(
                new RunPropertiesBaseStyle(
                    new RunFonts
                    {
                        Ascii = "Times New Roman",
                        HighAnsi = "Times New Roman",
                        EastAsia = "SimSun",
                        ComplexScript = "Times New Roman"
                    },
                    new FontSize { Val = BodyHalfPts.ToString() },
                    new Color { Val = "000000" },
                    new Languages { Val = "en-US", EastAsia = "zh-CN" })),
            new ParagraphPropertiesDefault(
                new ParagraphPropertiesBaseStyle(
                    new SpacingBetweenLines
                    {
                        Line = "480",
                        LineRule = LineSpacingRuleValues.Auto,
                        After = "0"
                    },
                    new Indentation { FirstLine = "720" }))));

        styles.Append(new Style(
            new StyleName { Val = "Normal" },
            new PrimaryStyle())
        { Type = StyleValues.Paragraph, StyleId = "Normal", Default = true });

        styles.Append(new Style(
            new StyleName { Val = "heading 1" },
            new BasedOn { Val = "Normal" },
            new NextParagraphStyle { Val = "Normal" },
            new PrimaryStyle(),
            new StyleParagraphProperties(
                new KeepNext(),
                new SpacingBetweenLines { Before = "360", After = "0", Line = "480", LineRule = LineSpacingRuleValues.Auto },
                new Indentation { FirstLine = "0" },
                new Justification { Val = JustificationValues.Center },
                new OutlineLevel { Val = 0 }),
            new StyleRunProperties(
                new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                new FontSize { Val = BodyHalfPts.ToString() },
                new Bold()))
        { Type = StyleValues.Paragraph, StyleId = "Heading1" });

        styles.Append(new Style(
            new StyleName { Val = "heading 2" },
            new BasedOn { Val = "Normal" },
            new NextParagraphStyle { Val = "Normal" },
            new PrimaryStyle(),
            new StyleParagraphProperties(
                new KeepNext(),
                new SpacingBetweenLines { Before = "360", After = "0", Line = "480", LineRule = LineSpacingRuleValues.Auto },
                new Indentation { FirstLine = "0" },
                new OutlineLevel { Val = 1 }),
            new StyleRunProperties(
                new RunFonts { Ascii = "Times New Roman", HighAnsi = "Times New Roman" },
                new FontSize { Val = BodyHalfPts.ToString() },
                new Bold()))
        { Type = StyleValues.Paragraph, StyleId = "Heading2" });

        part.Styles = styles;
        part.Styles.Save();
    }
}
