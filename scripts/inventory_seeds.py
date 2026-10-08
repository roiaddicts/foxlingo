"""Inspect embedded JSON without executing the downloaded JavaScript."""
from pathlib import Path
import re,json
root=Path(__file__).resolve().parents[1]
s=(root/'ref/futbol11.js').read_text()
rows=[]
for i,m in enumerate(re.finditer(r'JSON\.parse\(\s*("(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\')\s*\)',s)):
 raw=m.group(1)
 try:
  data=json.loads(json.loads(raw) if raw[0]=='"' else raw[1:-1].replace("\\'", "'"))
 except (ValueError,TypeError) as error:raise RuntimeError(f'Dataset {i} cannot decode') from error
 if not isinstance(data,list): continue
 ids=[r['id'] for r in data if isinstance(r,dict) and 'id' in r]
 rows.append(dict(namespace=f'futbol11.dataset{i}',offset=m.start(),records=len(data),fields=sorted({k for r in data if isinstance(r,dict) for k in r}),duplicateIDs=len(ids)-len(set(ids)),madridReferences=[r for r in data if isinstance(r,dict) and 'Real Madrid' in str(r.get('name',''))],xolosReferences=[r for r in data if isinstance(r,dict) and re.search('Tijuana|Xolos',str(r),re.I)]))
(root/'ref/seed-inventory.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')
print(f'Inventoried {len(rows)} datasets. Namespaces and duplicate counts preserved.')
