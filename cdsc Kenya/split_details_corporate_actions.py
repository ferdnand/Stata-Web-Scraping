import pandas as pd, re

#split the details section into specifc details including company_name, dividend_type, dividend_amount, announcement_date, books_closure_date, payment_date

def normalize_spaces(s):
    return re.sub(r"\s+", " ", s or "").strip()

# Date patterns seen: 20-Nov-2025, 04-12-2025, 5-Sep-2025
date_pat = re.compile(r"\b\d{1,2}-(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)-\d{4}\b|\b\d{1,2}-\d{1,2}-\d{4}\b", re.IGNORECASE)

# Dividend amount patterns like Kes.1.50, Kes. 2.00, Rwf.11.20
amount_pat = re.compile(r"\b([A-Za-z]{2,4}\.?\s*\d+(?:\.\d+)?)\b")

# Ratio pattern for bonus issue etc.
ratio_pat = re.compile(r"ratio\s+of\s+([0-9]+\s*:\s*[0-9]+)", re.IGNORECASE)

# Dividend/Action type detection
TYPE_RULES = [
    (re.compile(r"\bInterim\s*&\s*Special\s+Dividend\b", re.IGNORECASE), "Interim & Special Dividend"),
    (re.compile(r"\bInterim\s+Dividend\b", re.IGNORECASE), "Interim Dividend"),
    (re.compile(r"\bFinal\s+Dividend\b", re.IGNORECASE), "Final Dividend"),
    (re.compile(r"\bFirst\s*&\s*Final\s+Dividend\b", re.IGNORECASE), "First & Final Dividend"),
    (re.compile(r"\bFirst\s+and\s+Final\s+Dividend\b", re.IGNORECASE), "First & Final Dividend"),
    (re.compile(r"\bSpecial\s+Dividend\b", re.IGNORECASE), "Special Dividend"),
    (re.compile(r"\bBonus\s+Issue\b", re.IGNORECASE), "Bonus Issue"),
    (re.compile(r"\bRights\s+Issue\b", re.IGNORECASE), "Rights Issue"),
    (re.compile(r"\bSplit\b|\bShare\s+Split\b", re.IGNORECASE), "Share Split"),
]

def extract_type(text):
    for rx, label in TYPE_RULES:
        if rx.search(text):
            return label
    # fallback: if contains 'Dividend' but no qualifier
    if re.search(r"\bDividend\b", text, re.IGNORECASE):
        return "Dividend"
    return ""

def extract_dividend_amount(text, dtype):
    t = text
    if dtype == "Bonus Issue":
        m = ratio_pat.search(t)
        if m:
            return m.group(1).replace(" ", "")
        # fallback: any X:Y
        m2 = re.search(r"\b([0-9]+\s*:\s*[0-9]+)\b", t)
        if m2:
            return m2.group(1).replace(" ", "")
        return ""

    # For dividends: prefer 'Dividend of <amount>'
    m = re.search(r"Dividend\s+of\s+([A-Za-z]{2,4}\.?\s*\d+(?:\.\d+)?)", t, re.IGNORECASE)
    if m:
        return normalize_spaces(m.group(1)).replace(" ", "")

    # Sometimes 'dividend of Kes.0.32'
    m = re.search(r"dividend\s+of\s+([A-Za-z]{2,4}\.?\s*\d+(?:\.\d+)?)", t, re.IGNORECASE)
    if m:
        return normalize_spaces(m.group(1)).replace(" ", "")

    # Fallback: first currency+number token near Dividend keyword
    if re.search(r"\bDividend\b", t, re.IGNORECASE):
        # take first currency-like amount in string
        m = re.search(r"\b([A-Za-z]{2,4}\.?\s*\d+(?:\.\d+)?)\b", t)
        if m:
            return normalize_spaces(m.group(1)).replace(" ", "")

    return ""


def extract_announcement_date(text):
    t = text
    # Prefer 'on <date>' near 'announced'
    m = re.search(r"announc(?:ed|es|ing)[^;\.]*?\bon\s+({})".format(date_pat.pattern), t, re.IGNORECASE)
    if m:
        return m.group(1)

    # Or '; On <date>'
    m = re.search(r"\bOn\s+({})".format(date_pat.pattern), t, re.IGNORECASE)
    if m:
        return m.group(1)

    # fallback: first date in text
    m = date_pat.search(t)
    return m.group(0) if m else ""


def extract_books_closure_date(text):
    t = text
    m = re.search(r"Books\s+Closure\s*[:;\-]?\s*({})".format(date_pat.pattern), t, re.IGNORECASE)
    if m:
        return m.group(1)
    # Sometimes 'Books Closure; 08-Dec-2025;' already covered
    return ""


def extract_payment_date(text):
    t = text
    # Payment date / Payment Date / Payment
    m = re.search(r"Payment\s*(?:date|Date)?\s*[:;\-]?\s*({})".format(date_pat.pattern), t, re.IGNORECASE)
    if m:
        return m.group(1)
    return ""


# Load previously generated CSV
infile='nse_corporate_actions.csv'
df=pd.read_csv(infile)

# Parse
df['details_text']=df['details_text'].fillna('').map(normalize_spaces)

dividend_types=[]
dividend_amounts=[]
announcement_dates=[]
books_closure_dates=[]
payment_dates=[]

for txt in df['details_text']:
    dtype=extract_type(txt)
    dividend_types.append(dtype)
    dividend_amounts.append(extract_dividend_amount(txt, dtype))
    announcement_dates.append(extract_announcement_date(txt))
    books_closure_dates.append(extract_books_closure_date(txt))
    payment_dates.append(extract_payment_date(txt))

out=pd.DataFrame({
    'company_name': df['company_name'],
    'dividend_type': dividend_types,
    'dividend_amount': dividend_amounts,
    'announcement_date': announcement_dates,
    'books_closure_date': books_closure_dates,
    'payment_date': payment_dates,
})

outfile='nse_corporate_actions_split.csv'
out.to_csv(outfile, index=False)

# Quick quality stats
print('input_rows', len(df))
print('output_rows', len(out))
print('nonempty dividend_type', (out['dividend_type']!='').sum())
print('nonempty dividend_amount', (out['dividend_amount']!='').sum())
print('nonempty announcement_date', (out['announcement_date']!='').sum())
print('nonempty books_closure_date', (out['books_closure_date']!='').sum())
print('nonempty payment_date', (out['payment_date']!='').sum())
print('saved', outfile)

# show a few rows where parsing might be tricky
sample = out[(out['dividend_type']=='') | (out['payment_date']=='')].head(10)
print('\nSAMPLE potential-missing fields rows (first 10):')
print(sample.to_string(index=False))