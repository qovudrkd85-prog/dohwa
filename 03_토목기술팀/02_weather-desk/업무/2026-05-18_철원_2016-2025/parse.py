# -*- coding: utf-8 -*-
"""철원 ASOS 월자료 CSV → excel_export.py 입력 JSON 변환."""
import csv, json

SRC = r"E:\개인 FIle\00_dohwa\03_토목기술팀\01_data-download-desk\업무\2026-05-18_철원_ASOS월자료_2016-2025\철원_ASOS_월자료_201601-202512.csv"
OUT = r"E:\개인 FIle\00_dohwa\03_토목기술팀\02_weather-desk\업무\2026-05-18_철원_2016-2025\rows.json"


def num(v):
    s = (v or "").strip()
    if s in ("", "-", "-9", "-99", "-999"):
        return None
    try:
        return float(s)
    except ValueError:
        return None


def find(header, *needles, exclude=()):
    for i, h in enumerate(header):
        if all(n in h for n in needles) and not any(x in h for x in exclude):
            return i
    return None


with open(SRC, encoding="cp949") as f:
    data = list(csv.reader(f))

header = data[0]
idx = {
    "date": find(header, "일시") or 2,
    "tempAvg": find(header, "평균기온", exclude=("최고", "최저")),
    "tempMax": find(header, "평균최고기온"),
    "tempMin": find(header, "평균최저기온"),
    "precipitation": find(header, "월합강수량"),
    "windAvg": find(header, "평균풍속"),
    "windMax": find(header, "최대풍속", "m/s", exclude=("풍향", "나타난날", "순간")),
    "humidity": find(header, "평균상대습도"),
    "sunshine": find(header, "일조시간"),
}
print("[컬럼 매핑]")
for k, v in idx.items():
    print(f"  {k:14s} -> col {v}  ({header[v] if v is not None else 'N/A'})")

rows = []
for r in data[1:]:
    if len(r) < 3 or not r[idx["date"]].strip():
        continue
    y, m = r[idx["date"]].split("-")
    row = {"year": int(y), "month": int(m), "station": "철원", "stationId": "95"}
    for key in ("tempAvg", "tempMax", "tempMin", "precipitation",
                "windAvg", "windMax", "humidity", "sunshine"):
        row[key] = num(r[idx[key]]) if idx[key] is not None else None
    rows.append(row)

years = sorted({r["year"] for r in rows})
out = {"station": "철원", "stationId": "95", "years": years,
       "rows": rows, "totalRows": len(rows)}
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False)

print(f"\n[결과] {len(rows)}개월 / {years[0]}~{years[-1]}  -> rows.json")
print("샘플 2016-01:", json.dumps(rows[0], ensure_ascii=False))
