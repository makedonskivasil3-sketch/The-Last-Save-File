import importlib.util, os, sys
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table,
    TableStyle, PageBreak, Image, KeepTogether, NextPageTemplate)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = sys.argv[1]

FONT = "/usr/share/fonts/truetype/dejavu/"
pdfmetrics.registerFont(TTFont("DV", FONT + "DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("DVB", FONT + "DejaVuSans-Bold.ttf"))
pdfmetrics.registerFontFamily("DV", normal="DV", bold="DVB", italic="DV", boldItalic="DVB")

INK = colors.HexColor("#1d1a22")
MUTED = colors.HexColor("#5d5866")
RAIN = colors.HexColor("#e9b44c")   # Rue's raincoat
SCARF = colors.HexColor("#d8463a")
CYAN = colors.HexColor("#2a8fa0")
PAPER = colors.HexColor("#f6f2ea")
RULE = colors.HexColor("#d9d2c5")

def load(name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, name + ".py"))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m

LANGS = [load("content_en"), load("content_de"), load("content_bg")]

st = {
    "title": ParagraphStyle("title", fontName="DVB", fontSize=34, leading=40, textColor=INK, alignment=TA_CENTER),
    "sub": ParagraphStyle("sub", fontName="DV", fontSize=14, leading=20, textColor=MUTED, alignment=TA_CENTER),
    "langtitle": ParagraphStyle("lt", fontName="DVB", fontSize=24, leading=30, textColor=INK, spaceAfter=4),
    "note": ParagraphStyle("note", fontName="DV", fontSize=8.5, leading=12, textColor=MUTED, spaceAfter=10),
    "h1": ParagraphStyle("h1", fontName="DVB", fontSize=13.5, leading=18, textColor=INK, spaceBefore=12, spaceAfter=6, keepWithNext=1),
    "p": ParagraphStyle("p", fontName="DV", fontSize=9.6, leading=14.2, textColor=INK, spaceAfter=6),
    "li": ParagraphStyle("li", fontName="DV", fontSize=9.6, leading=14, textColor=INK, leftIndent=12, bulletIndent=2, spaceAfter=3),
    "cell": ParagraphStyle("cell", fontName="DV", fontSize=8.6, leading=11.6, textColor=INK),
    "cellh": ParagraphStyle("cellh", fontName="DVB", fontSize=8.6, leading=11.6, textColor=colors.white),
    "quote": ParagraphStyle("quote", fontName="DV", fontSize=10, leading=15, textColor=INK, leftIndent=10, rightIndent=10,
        backColor=colors.HexColor("#fbf3dc"), borderColor=RAIN, borderWidth=0, borderPadding=8, spaceBefore=6, spaceAfter=10),
    "cap": ParagraphStyle("cap", fontName="DV", fontSize=8, leading=11, textColor=MUTED, alignment=TA_CENTER, spaceAfter=8),
    "toc": ParagraphStyle("toc", fontName="DV", fontSize=11, leading=17, textColor=INK, alignment=TA_CENTER),
}

class Doc(BaseDocTemplate):
    def __init__(self, path):
        super().__init__(path, pagesize=A4, leftMargin=20*mm, rightMargin=20*mm, topMargin=20*mm, bottomMargin=18*mm,
            title="The Last Save File — Game concept (EN / DE / BG)", author="The Last Save File")
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="f")
        # One body template per language, so the running header is right from
        # each part's first page.
        self.addPageTemplates([PageTemplate("cover", [frame], onPage=self._cover)] + [
            PageTemplate(L.LANG, [frame], onPage=lambda c, d, name=L.LANG.upper(): self._body(c, d, name)) for L in LANGS])

    def _cover(self, c, d):
        c.saveState()
        c.setFillColor(PAPER)
        c.rect(0, 0, A4[0], A4[1], stroke=0, fill=1)
        c.setFillColor(RAIN)
        c.rect(0, A4[1] - 14*mm, A4[0], 14*mm, stroke=0, fill=1)
        c.setFillColor(SCARF)
        c.rect(0, A4[1] - 16*mm, A4[0], 2*mm, stroke=0, fill=1)
        c.restoreState()

    def _body(self, c, d, lang):
        c.saveState()
        c.setStrokeColor(RULE)
        c.setLineWidth(0.6)
        c.line(self.leftMargin, A4[1] - 13*mm, A4[0] - self.rightMargin, A4[1] - 13*mm)
        c.setFont("DV", 8)
        c.setFillColor(MUTED)
        c.drawString(self.leftMargin, A4[1] - 11*mm, "THE LAST SAVE FILE")
        c.drawRightString(A4[0] - self.rightMargin, A4[1] - 11*mm, lang)
        c.drawCentredString(A4[0] / 2, 10*mm, str(d.page))
        c.setFillColor(RAIN)
        c.rect(0, 0, 4*mm, A4[1], stroke=0, fill=1)
        c.restoreState()


def img(path, width):
    from reportlab.lib.utils import ImageReader
    w, h = ImageReader(path).getSize()
    return Image(path, width=width, height=width * h / w)

def table(rows, width):
    head, body = rows[0], rows[1:]
    n = len(head)
    widths = {2: [0.27, 0.73], 3: [0.22, 0.33, 0.45]}[n]
    data = [[Paragraph(h, st["cellh"]) for h in head]] + [[Paragraph(c, st["cell"]) for c in r] for r in body]
    t = Table(data, colWidths=[width * w for w in widths], repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), INK),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f4f1ec")]),
        ("GRID", (0, 0), (-1, -1), 0.4, RULE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t

CAPTIONS = {
    "English": "Arin's room in the current build: Mira speaks, the owner's note reads I SAW YOU, the awareness meter at the top right.",
    "Deutsch": "Arins Zimmer im aktuellen Build: Mira spricht, die Notiz des Owners sagt I SAW YOU, oben rechts die Aufmerksamkeitsanzeige.",
    "Български": "Стаята на Арин в сегашната версия: Мира говори, бележката на собственика казва I SAW YOU, горе вдясно е измерителят на вниманието.",
}

def build():
    doc = Doc(OUT)
    W = doc.width
    s = [NextPageTemplate("cover"), Spacer(1, 38*mm),
         Paragraph("THE LAST SAVE FILE", st["title"]), Spacer(1, 6*mm),
         Paragraph("Game concept · Spielkonzept · Концепция на играта", st["sub"]), Spacer(1, 14*mm),
         img(os.path.join(REPO, "docs/review/rue_expressions_restored.png"), W), Spacer(1, 14*mm),
         Paragraph("“You wake up inside someone else’s video game save file. You are an intruder.”", st["sub"]),
         Spacer(1, 20*mm),
         Paragraph("1 · English<br/>2 · Deutsch<br/>3 · Български", st["toc"]),
         Spacer(1, 22*mm),
         Paragraph("19.10.2026 · build of branch claude/dark-truth-design", st["cap"]),
         ]
    for i, L in enumerate(LANGS):
        s.append(NextPageTemplate(L.LANG))
        s.append(PageBreak())
        s.append(Paragraph("%d · %s" % (i + 1, L.LANG), st["langtitle"]))
        s.append(Paragraph("%s — %s" % (L.TITLE, L.SUBTITLE), st["h1"]))
        s.append(Paragraph(L.STATUS_NOTE, st["note"]))
        cap_shot = CAPTIONS[L.LANG]
        for n, (kind, val) in enumerate(L.BLOCKS):
            if kind == "h1":
                s.append(Paragraph(val, st["h1"]))
                # The screenshot, after the backstory section heading of section 5 (the world).
                if val.startswith("5."):
                    s.append(KeepTogether([img(os.path.join(REPO, "docs/review/after_mira_dialogue_portrait.png"), W * 0.82), Paragraph(cap_shot, st["cap"])]))
            elif kind == "p":
                s.append(Paragraph(val, st["p"]))
            elif kind == "ul":
                for it in val:
                    s.append(Paragraph(it, st["li"], bulletText="•"))
                s.append(Spacer(1, 3))
            elif kind == "table":
                s.append(table(val, W))
                s.append(Spacer(1, 6))
            elif kind == "quote":
                s.append(Paragraph(val, st["quote"]))
    doc.build(s)

build()
print("wrote", OUT)
