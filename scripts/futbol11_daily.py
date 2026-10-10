"""Compile auditable daily selections from a verified Futbol11 module archive."""
import argparse,hashlib,json,math,os,re,tempfile
from datetime import date,datetime,time,timedelta,timezone
from pathlib import Path
from zoneinfo import ZoneInfo
from urllib.parse import urlsplit
from futbol11_archive import Archive
from futbol11_source import LITERAL
from futbol11_static import one_table,array_at
ROOT=Path(__file__).resolve().parents[1]
DATE_HELPER='function Fy(){const e=new Date;e.setHours(0,0,0,0);const t=new Date(e.getFullYear(),0,0);t.setHours(0,0,0,0);const n=e.getTime()-t.getTime(),r=1e3*60*60*24;return Math.round(n/r)}'
RNG_HELPER='function Dy(e){let t=2166136261;for(let n=0;n<e.length;n++)t^=e.charCodeAt(n),t+=(t<<1)+(t<<4)+(t<<7)+(t<<8)+(t<<24);return()=>(t+=t<<13,t^=t>>>7,t+=t<<3,t^=t>>>17,t+=t<<5,(t>>>0)/4294967296)}'
SHUFFLE_HELPER='function ab(e,t){const n=[...e],r=Dy(t);for(let s=n.length-1;s>0;s--){const o=Math.floor(r()*(s+1));[n[s],n[o]]=[n[o],n[s]]}return n}'

def selector_digest(source):
    """Pin reviewed selection code while allowing hashed filenames and static data updates."""
    source=LITERAL.sub('JSON.parse("STATIC_DATA")',source)
    spans=[]
    for match in re.finditer(r'\[\s*\{\s*(?:id|name)\s*:',source):
        if any(start<=match.start()<end for start,end in spans):continue
        try:
            _,end=array_at(source,match.start(),with_end=True);spans.append((match.start(),end))
        except ValueError:continue
    for start,end in reversed(spans):source=source[:start]+'["STATIC_TABLE"]'+source[end:]
    source=re.sub(r'from"[^" ]+\.js"','from"MODULE"',source)
    source=re.sub(r'import"[^" ]+\.js"','import"MODULE"',source)
    return hashlib.sha256(source.encode()).hexdigest()

def signed(v):
    value=int(v)&0xffffffff
    return value-0x100000000 if value>=0x80000000 else value

def shuffle(values,seed):
    # JavaScript arithmetic is a double until each bitwise operation coerces Int32.
    # Retain that distinction rather than truncating every addition.
    state=2166136261
    encoded=seed.encode('utf-16-le') if isinstance(seed,str) else b''
    for code in [int.from_bytes(encoded[i:i+2],'little') for i in range(0,len(encoded),2)]:
        state=signed(int(state)^code)
        state+=sum(signed(signed(state)<<shift) for shift in (1,4,7,8,24))
    result=list(values)
    for i in range(len(result)-1,0,-1):
        state+=signed(signed(state)<<13);state=signed(int(state)^(int(state)&0xffffffff)>>7)
        state+=signed(signed(state)<<3);state=signed(int(state)^(int(state)&0xffffffff)>>17)
        state+=signed(signed(state)<<5)
        j=math.floor(((int(state)&0xffffffff)/4294967296)*(i+1))
        result[i],result[j]=result[j],result[i]
    return result

def squad_shuffle(values,seed):
    """SquadSlice uses FNV-1a and Mulberry32, not the shared daily shuffle."""
    state=2166136261
    encoded=seed.encode('utf-16-le')
    for i in range(0,len(encoded),2):state=((state^int.from_bytes(encoded[i:i+2],'little'))*16777619)&0xffffffff
    result=list(values)
    for i in range(len(result)-1,0,-1):
        state=(state+1831565813)&0xffffffff
        value=((state^(state>>15))*(state|1))&0xffffffff
        value=((value+(((value^(value>>7))*(value|61))&0xffffffff))^value)&0xffffffff
        rand=((value^(value>>14))&0xffffffff)/4294967296
        j=math.floor(rand*(i+1));result[i],result[j]=result[j],result[i]
    return result

def day_indexes(day,zone):
    z=ZoneInfo(zone);start=datetime.combine(day,time.min,z)
    jan0=datetime.combine(date(day.year,1,1)-timedelta(days=1),time.min,z)
    difference=(start.timestamp()-jan0.timestamp())/86400
    return math.floor(difference+0.5),math.floor(difference)

def csv(value):
    if isinstance(value,list):return [int(v) for v in value]
    return [int(v.strip()) for v in value.split(',') if v.strip()]

def compile_daily(snapshot,day,zone):
    archive=Archive(snapshot);main=archive.text(archive.main())
    if not all(h in main for h in [DATE_HELPER,RNG_HELPER,SHUFFLE_HELPER,'Fy as e','ab as s']):raise ValueError('Daily date/shuffle helper changed')
    contracts=json.loads((ROOT/'content/futbol11-daily-contracts.json').read_text())
    if contracts['schemaVersion']!=1:raise ValueError('Unsupported daily selector contract version')
    for name,digest in contracts['selectors'].items():
        if selector_digest(archive.text(archive.mode(name)))!=digest:raise ValueError('Daily selector contract changed: '+name)
    ordinal,floor_index=day_indexes(day,zone)
    stamp=day.strftime('%m/%d/%Y');games=[]
    def module(name,required):
        url=archive.mode(name);text=archive.text(url)
        if not all(s in text for s in required):raise ValueError('Daily selector changed: '+name)
        date_alias={'top10':'S','statdle':'m','legacy':'f','link':'g','squadslice':'B','guesswho':'R','wordle':'x','pyramid':'T','countries':'C','clubs':'w','retro':'M','legends':'M','america':'g','goltexto':'x','impostor':'_','bingo':'V','bingo-retro':'J','grid':'K','connections':'T'}[name]
        if archive.import_symbol(url,date_alias)!=('e',archive.main()):raise ValueError('Date helper binding changed: '+name)
        return url,text
    def add(name,url,selection,method,randomness=False):
        asset=archive.modules[url][0]
        games.append(dict(id=name,sourceURL=archive.meta['sourceURL'].rstrip('/')+('/guess-the-footballer' if name=='guesswho' else '/futbol11' if name=='countries' else '/futbol11-'+name),selector=method,selection=selection,sourceModule=url,sourceModuleSHA256=asset['sha256'],randomPlayOrder=randomness))
    # Each inline table stays in its own provider namespace. No shared raw-ID joins.
    for name,fields,guard in [
        ('top10',{'id','title','players'},'h.value=e[S()]'),
        ('statdle',{'id','info'},'p[m()].info.split(";")[0]'),
        ('legacy',{'id','player','clubs'},'N[f()].clubs.split(",").map(Number)'),
        ('link',{'id','player','teammates'},'A[g()].teammates.split(",").map(Number)'),
        ('squadslice',{'clubID','season','players'},'const s=o2[B()]'),
        ('guesswho',{'birthday','height','id','name','position','previousClubs','previousLeagues','secID'},'const d=u(Oe[R()])')]:
        url,text=module(name,[guard]);rows=archive.rows(fields,url)
        if not 0<=ordinal<len(rows):raise ValueError('Daily index outside '+name+' source coverage')
        add(name,url,dict(record=rows[ordinal],index=ordinal,datasetRecords=len(rows)),'local-day-of-year array index')
    # Legacy, Link and Statdle import the same inline club/kit catalog.
    # These modes explicitly import the GENERAL player table, not the Clubs XI IDs.
    stat_url=archive.mode('statdle');club_url=archive.imported(stat_url,'w')
    if archive.imported(archive.mode('legacy'),'q')!=club_url:raise ValueError('Legacy club catalog binding changed')
    club_source=archive.text(club_url)
    if selector_digest(club_source)!=contracts.get('supportSelectors',{}).get('clubCatalog'):raise ValueError('Club catalog support contract changed')
    club_matches=list(re.finditer(r'=\[\{id:',club_source))
    if len(club_matches)!=1:raise ValueError('Club kit catalog changed')
    clubs=array_at(club_source,club_matches[0].start()+1)
    if not clubs or any(set(row)!={'id','lastName','image','country'} for row in clubs):raise ValueError('Invalid club kit catalog')
    if len({c['id'] for c in clubs})!=len(clubs):raise ValueError('Duplicate kit catalog club IDs')
    support=dict(clubs=dict(sourceURL=club_url,assetSHA256=archive.modules[club_url][0]['sha256'],data=clubs))
    general=archive.roles['gamePlayers'];general_ids={p['id'] for p in general}
    general_url=next(d['sourceURL'] for d in archive.meta['datasets'] if set(d['fields'])=={'bingo','countryID','firstName','grid','id','image','lastName','nickname'})
    for name,alias in [('statdle','L'),('legacy','k'),('link','h')]:
        if archive.imported(archive.mode(name),alias)!=general_url:raise ValueError('General player namespace binding changed: '+name)
        game=next(g for g in games if g['id']==name);record=game['selection']['record']
        if record['id'] not in general_ids:raise ValueError('Missing daily answer profile: '+name)
        if name=='legacy':
            ids=csv(record['clubs'])
            order=[c['id'] for c in shuffle(clubs,ordinal) if c['id'] in ids]
            if len(ids)!=4 or len(set(ids))!=4 or len(order)!=4:raise ValueError('Incomplete Legacy club clues')
            game['selection']['clueOrder']=order
        elif name=='link':
            ids=csv(record['teammates'])
            order=[p['id'] for p in shuffle(general,stamp) if p['id'] in ids]
            if len(ids)!=5 or len(set(ids))!=5 or len(order)!=5 or record['id'] in ids:raise ValueError('Incomplete Link teammate clues')
            game['selection']['clueOrder']=order
        else:
            game['randomPlayOrder']=True # Eight clue reveals are randomized during play.
    squad_game=next(g for g in games if g['id']=='squadslice');squad_record=squad_game['selection']['record']
    squad_url=archive.mode('squadslice')
    if archive.imported(squad_url,'l2')!=general_url or archive.imported(squad_url,'r2')!=club_url:raise ValueError('SquadSlice identity binding changed')
    country_url=archive.imported(squad_url,'t2');countries=archive.rows({'id','name','flag','bgColor'},country_url)
    country_ids={c['id'] for c in countries};general_map={p['id']:p for p in general}
    roster=[general_map[i] for i in csv(squad_record['players']) if i in general_map]
    if not roster or len({p['id'] for p in roster})!=len(roster):raise ValueError('Invalid SquadSlice roster')
    groups={}
    for player in roster:
        if player['countryID'] not in country_ids:raise ValueError('Missing squad nationality flag')
        groups.setdefault(player['countryID'],[]).append(player['id'])
    slices=[dict(countryID=country,playerIDs=groups[country],count=len(groups[country])) for country in sorted(groups)]
    slices.sort(key=lambda row:-row['count']) # Stable ties retain Object.values numeric-key order.
    squad_game['selection']['slices']=slices
    squad_game['selection']['revealOrder']=[r['countryID'] for r in squad_shuffle(slices,str(squad_record['clubID'])+'-'+squad_record['season'])]
    squad_game['selection']['omittedPlayerIDs']=[i for i in csv(squad_record['players']) if i not in general_map]
    if not any(c['id']==squad_record['clubID'] for c in clubs):raise ValueError('Missing squad answer club')
    guess_game=next(g for g in games if g['id']=='guesswho');guess_url=archive.mode('guesswho');guess_text=archive.text(guess_url)
    if archive.imported(guess_url,'Q')!=general_url or archive.imported(guess_url,'j')!=country_url:raise ValueError('GuessWho identity binding changed')
    guess_players_url=archive.imported(guess_url,'T')
    guess_players=archive.rows({'id','clubID','firstName','lastName','nickname','positions'},guess_players_url)
    guess_rows=archive.rows({'birthday','height','id','name','position','previousClubs','previousLeagues','secID'},guess_url)
    def inline_guess(name):
        match=re.search(r'(?:const |,)'+name+r'=\[',guess_text)
        if match is None:raise ValueError('GuessWho question catalog changed')
        return array_at(guess_text,match.end()-1)
    question_clubs=inline_guess('q');question_leagues=inline_guess('we')
    if any(set(c)!={'id','name','countryID'} for c in question_clubs) or any(set(c)!={'id','name'} for c in question_leagues):raise ValueError('Invalid GuessWho catalogs')
    aliases={'Man United':'Man Utd','Sporting CP':'Sporting'}
    for club in question_clubs:
        matches=[c for c in clubs if c['lastName']==aliases.get(club['name'],club['name']) and c['country']==club['countryID']]
        if len(matches)>1:raise ValueError('Ambiguous GuessWho kit identity')
        if matches:club['image']=matches[0]['image']
    crosswalk={}
    for row in guess_rows:
        if row['secID'] not in general_ids or not any(p['id']==row['id'] for p in guess_players):raise ValueError('Missing GuessWho source identity')
        if str(row['id']) in crosswalk and crosswalk[str(row['id'])]!=row['secID']:raise ValueError('Conflicting GuessWho portrait crosswalk')
        crosswalk[str(row['id'])]=row['secID']
    # Artwork-only joins require a unique full name in BOTH catalogs. Explicit
    # source secID links take precedence; no factual membership crosses this join.
    def full_name(player):
        first=player.get('firstName','').strip();last=player.get('lastName','').strip()
        return ' '.join((first+' '+last).lower().split()) if first and last else ''
    general_names={};guess_names={}
    for player in general:
        name=full_name(player)
        if name:general_names.setdefault(name,[]).append(player['id'])
    for player in guess_players:
        name=full_name(player)
        if name:guess_names.setdefault(name,[]).append(player['id'])
    for name,ids in guess_names.items():
        matches=general_names.get(name,[])
        if len(ids)==1 and len(matches)==1:crosswalk.setdefault(str(ids[0]),matches[0])
    guess_game['selection']['catalog']=dict(clubs=question_clubs,leagues=question_leagues,playerSourceURL=guess_players_url,portraitPlayerIDs=crosswalk)
    # Pyramid deliberately uses floor rather than the common rounded day helper.
    url,text=module('pyramid',['p=Math.floor(C/G)','let S=u1[p]','i.has(r.number)?!1:(i.add(r.number),!0)'])
    if archive.imported(url,'a1')!=general_url:raise ValueError('Pyramid player namespace binding changed')
    rows=archive.rows({'id','title','players'},url)
    if not 0<=floor_index<len(rows):raise ValueError('Pyramid index outside source coverage')
    chosen=rows[floor_index];seen=set();rank=[]
    for pair in chosen['players'].split('.'):
        player,value=pair.split(',');value=int(value)
        if value not in seen:rank.append(dict(playerID=int(player),value=value));seen.add(value)
    selected=shuffle(rank,ordinal)[:10]
    add('pyramid',url,dict(record=chosen,index=floor_index,players=selected),'local elapsed-day floor; first unique values; day-seeded shuffle')
    # Wordle has a static string array, not a JSON.parse dataset.
    url,text=module('wordle',['b.value=B[x()]'])
    deps=[u for u in archive.dependencies(url) if '"GOTZE","ANTONY"' in archive.text(u)]
    if len(deps)!=1:raise ValueError('Wordle dictionary changed')
    dictionary_url=deps[0]
    if archive.import_symbol(url,'B')!=('w',dictionary_url) or archive.imported(url,'Z')!=general_url:raise ValueError('Wordle dictionary/player binding changed')
    words=archive.text(dictionary_url);match=re.search(r'=\["GOTZE","ANTONY"',words)
    start=match.start()+1;values,end=array_at(words,start,with_end=True)
    wrapper=words[:start]+'["STATIC_WORDS"]'+words[end:]
    if selector_digest(wrapper)!=contracts.get('supportSelectors',{}).get('wordleDictionary'):raise ValueError('Wordle dictionary support contract changed')
    if not values or any(not isinstance(w,str) or re.fullmatch('[A-Z]{4,7}',w) is None for w in values):raise ValueError('Invalid Wordle dictionary')
    if not 0<=ordinal<len(values):raise ValueError('Wordle index outside dictionary')
    catalog=dict(sourceURL=dictionary_url,assetSHA256=archive.modules[dictionary_url][0]['sha256'],words=values,playerSourceURL=general_url)
    add('wordle',url,dict(answer=values[ordinal],index=ordinal,catalog=catalog),'local-day-of-year string array index')
    # Five XI pools use the same seeded shuffle with mode-specific salts and indexes.
    form_deps=[u for u in archive.modules if len(re.findall(r'name:"442",players:',archive.text(u)))==1 and len(re.findall(r'name:"433",players:',archive.text(u)))==1]
    # Prefer the standalone formation component rather than per-mode duplicated code.
    formations=[]
    for u in form_deps:
        try:forms=one_table(archive.text(u),{'name','players'})
        except ValueError:continue
        if len(forms)==5:formations.append((u,forms))
    unique={json.dumps(f,sort_keys=True):f for _,f in formations}
    if len(unique)!=1:raise ValueError('Formation tables changed')
    forms=next(iter(unique.values()))
    for name,salt,index in [('countries','/c1fdE',1),('clubs','/CA',1),('retro','osaIS3',1),('legends','ofADI',0),('america','/CA',3)]:
        url,text=module(name,['+"'+salt+'"','.slice(0,11)'])
        if name=='countries':
            candidates=[]
            for dep in archive.dependencies(url):
                try:table=one_table(archive.text(dep),{'id','name','logo'})
                except ValueError:continue
                if len(table)>=11 and table[0].get("id")==6 and table[0].get("name")=="England":candidates.append(table)
            if len(candidates)!=1:raise ValueError('Nations table changed')
            groups=candidates[0]
        elif name=='retro':
            groups=archive.roles['classicSquads'];seen=set();groups=[g for g in groups if not (g['clubID'] in seen or seen.add(g['clubID']))]
            if 'e===m.findIndex(c=>c.clubID===n.clubID)' not in text:raise ValueError('Retro distinct-club selector changed')
        else:groups=one_table(text,{'id','name','logo','players'} if name=='clubs' else {'id','name','logo'})
        seed=str(ordinal)+salt
        # Formation index and identical salt occur in the reviewed setup selector.
        if not re.search(re.escape('+"'+salt+'")['+str(index)+']'),text):raise ValueError('Formation index changed: '+name)
        add(name,url,dict(groups=shuffle(groups,seed)[:11],formation=shuffle(forms,seed)[index]),'day-of-year salted seeded shuffle')
    # Goltexto shuffles the first 366 eligible profiles with a constant seed.
    url,text=module('goltexto',['typeof a.clubID=="number"&&a.birthday).slice(0,366),"today")[x()]'])
    rows=archive.rows({'birthday','clubID','countryID','firstName','id','lastName','nickname','ovr','positions'},archive.imported(url,'L'))
    eligible=[p for p in rows if isinstance(p.get('clubID'),(int,float)) and p.get('birthday')][:366]
    if not 0<=ordinal<len(eligible):raise ValueError('Goltexto index outside pool')
    order=shuffle(eligible,'today')
    country_export,country_module=archive.import_symbol(url,'oa');country_text=archive.text(country_module)
    export_specs=[spec.strip().split(' as ') for match in re.finditer(r'export\{([^}]+)\}',country_text) for spec in match.group(1).split(',')]
    locals_for_export=[spec[0] for spec in export_specs if spec[-1]==country_export]
    if len(locals_for_export)!=1:raise ValueError('Goltexto country binding changed')
    match=re.search(r'const '+re.escape(locals_for_export[0])+r'=\[',country_text)
    if match is None:raise ValueError('Goltexto country table changed')
    flags=array_at(country_text,match.end()-1)
    extra=re.search(r'const ma=\[',text)
    if extra is None:raise ValueError('Goltexto extra flags changed')
    flags+=array_at(text,extra.end()-1)
    if any(set(c)!={'id','name','logo'} for c in flags) or len({c['id'] for c in flags})!=len(flags):raise ValueError('Invalid Goltexto country catalog')
    def groups(function):
        match=re.search(r'(?:const |,)'+function+r'=a=>\{const i=\{(.*?)\};for',text)
        if match is None:raise ValueError('Goltexto grouping function changed')
        group_text=match.group(1);pairs=re.findall(r'(\d+):(\[[\d,]+\])',group_text)
        if re.sub(r'\d+:\[[\d,]+\]','',group_text).strip(',') or not pairs:raise ValueError('Non-static Goltexto groups')
        result={key:json.loads(value) for key,value in pairs}
        all_ids=[i for values in result.values() for i in values]
        if len(pairs)!=len(result) or len(all_ids)!=len(set(all_ids)):raise ValueError('Ambiguous Goltexto grouping')
        return result
    if archive.imported(url,'na')!=club_url:raise ValueError('Goltexto club binding changed')
    import unicodedata
    def normalized_full(player):
        first=player.get('firstName','').strip();last=player.get('lastName','').strip()
        if not first or not last:return ''
        name=unicodedata.normalize('NFD',first+' '+last)
        return ' '.join(''.join(c for c in name if not unicodedata.combining(c)).lower().split())
    candidates=[p for p in rows if isinstance(p.get('clubID'),(int,float)) and p['clubID']]
    general_names={};candidate_names={}
    for p in general:
        name=normalized_full(p)
        if name:general_names.setdefault(name,[]).append(p['id'])
    for p in candidates:
        name=normalized_full(p)
        if name:candidate_names.setdefault(name,[]).append(p['id'])
    portraits={str(ids[0]):general_names[name][0] for name,ids in candidate_names.items() if len(ids)==1 and len(general_names.get(name,[]))==1}
    catalog=dict(playerSourceURL=archive.imported(url,'L'),countries=flags,leagueGroups=groups('W'),regionGroups=groups('E'),portraitPlayerIDs=portraits)
    add('goltexto',url,dict(player=order[ordinal],index=ordinal,orderPlayerIDs=[p['id'] for p in order],catalog=catalog),'constant-seeded eligible pool; local-day-of-year index')
    # Impostor has an explicit provider fallback when a day is not covered.
    url,text=module('impostor',['let l=A[o.value.day]','l.correctPl=l.correctPl.split(",").map(Number)'])
    rows=archive.rows({'id','title','correctPl','addcorr','impostors'})
    fallback=ordinal>=len(rows)
    if fallback:raise ValueError('Impostor date requires source fallback; not a dated challenge')
    row=rows[ordinal]
    add('impostor',url,dict(record=row,index=ordinal,correctPlayerIDs=csv(row['correctPl']),extraCorrectPlayerIDs=csv(row.get('addcorr','')),impostorPlayerIDs=csv(row['impostors'])),'local-day-of-year index; normal mode',True)
    # Bingo boards are dated; offered players and their pacing are intentionally random.
    for name,counts in [('bingo',[('club',4),('club2',1),('country',2),('country2|continent',1),('extra',1),('award',2),('league',1)]),('bingo-retro',[('club',4),('club2',2),('country',3),('award',1),('continent',1),('other',1)])]:
        url,text=module(name,['getMonth()+1','Math.random()','type=="club"'])
        if name=='bingo':groups=archive.rows({'id','logo','name','type'})
        else:groups=one_table(text,{'id','name','logo','type'})
        selected=[]
        for types,count in counts:
            # Guard source type counts so a changed recipe fails closed.
            if not re.search(r'type=="'+types.split('|')[0]+r'"[^;]*?\.slice\(0,'+str(count)+r'\)',text):raise ValueError('Bingo type recipe changed')
            selected+=shuffle([g for g in groups if g['type'] in types.split('|')],stamp)[:count]
        if len(selected)!=12:raise ValueError('Incomplete bingo board')
        selection=dict(groups=shuffle(selected,stamp))
        if name=='bingo-retro':
            legends=archive.rows({'id','name','image','groups'},url)
            if len({p['id'] for p in legends})!=len(legends) or any(not isinstance(p['groups'],list) or not p['groups'] or any(not isinstance(i,int) for i in p['groups']) for p in legends):raise ValueError('Invalid Bingo Retro player memberships')
            if any(not any(g['id'] in p['groups'] for p in legends) for g in selected):raise ValueError('Unplayable Bingo Retro category')
            selection['catalog']=dict(playerSourceURL=url,groups=groups,boardDate=day.isoformat())
        add(name,url,selection,'MM/DD/YYYY category-specific seeded shuffle; random player offers',True)
    # Grid creates memberships from each player's explicit grid field.
    url,text=module('grid',['let a=d','s++','gameLevel:"easy"','r.footballers.some(N=>c.footballers.includes(N))','s.bingo&&s.bingo.split(",").map(Number).includes(a.id)||s.grid&&s.grid.split(",").map(Number).includes(a.id)'])
    groups=archive.rows({'id','logo','name','type'});players=archive.roles['gamePlayers']
    memberships={g['id']:set(p['id'] for p in players if g['id'] in csv(p.get('grid',''))+csv(p.get('bingo',''))) for g in groups}
    pool=[g for g in groups if g['type'] in ['club','country']];horizontal=shuffle(pool,stamp)[:3];counter=0
    while True:
        candidates=[g for g in pool if g['id'] not in {r['id'] for r in horizontal} and all(memberships[g['id']] & memberships[r['id']] for r in horizontal)]
        vertical=shuffle(candidates,stamp)[:3]
        if len(vertical)==3:break
        if counter>=1000:raise ValueError('No source-compatible grid after bounded search')
        horizontal=shuffle(pool,counter)[:3];counter+=1
    add('grid',url,dict(columns=horizontal,rows=vertical,mode='easy'),'MM/DD/YYYY seeded intersections; source fallback counter')
    # Connections needs mutually exclusive selected people, not merely four random categories.
    url,text=module('connections',['i[m].players.some(y=>n.value.includes(y))','!c.value.includes(y)','w=D+"/"+S+"/"+G+"/"'])
    categories=archive.rows({'id','title','level','players'},url);with_images={p['id'] for p in players if p.get('image')}
    candidates=[]
    for category in categories:
        members=[p for p in csv(category['players']) if p in with_images]
        if len(members)>=4:candidates.append(dict(category,players=members))
    selected=[];chosen=set();excluded=set()
    for group in shuffle(candidates,stamp+'/'):
        if chosen & set(group['players']):continue
        picked=shuffle([p for p in group['players'] if p not in chosen|excluded],stamp+'/')[:4]
        if len(picked)!=4:continue
        selected.append(dict(id=group['id'],title=group['title'],playerIDs=picked));chosen.update(picked);excluded.update(group['players'])
        if len(selected)==4:break
    if len(selected)!=4:raise ValueError('Source Connections cannot form four groups')
    add('connections',url,dict(groups=selected,order=shuffle([p for g in selected for p in g['playerIDs']],stamp+'/')),'MM/DD/YYYY/ seeded compatible groups; normal mode')
    catalog=json.loads((ROOT/'content/futbol11-game-catalog.json').read_text())
    expected={g['id'] for g in catalog['games']};actual={('futbol11' if g['id']=='countries' else 'guess-the-footballer' if g['id']=='guesswho' else g['id']) for g in games}
    expected_routes={urlsplit(g['sourceURL']).path for g in catalog['games']}
    if archive.catalog_routes()!=expected_routes:raise ValueError('Live homepage game inventory changed; review coverage')
    if actual!=expected:raise ValueError('Daily mode coverage mismatch')
    return dict(schemaVersion=1,gameDate=day.isoformat(),timeZone=zone,dayOfYear=ordinal,elapsedDayFloor=floor_index,fetchedAt=archive.meta['fetchedAt'],compiledAt=datetime.now(timezone.utc).isoformat(),selectorContractsSHA256=hashlib.sha256((ROOT/'content/futbol11-daily-contracts.json').read_bytes()).hexdigest(),sourceSnapshotSHA256=hashlib.sha256(Path(snapshot).read_bytes()).hexdigest(),sourceURL=archive.meta['sourceURL'],datasets=archive.meta['datasets'],support=support,scope='Daily selections from the archived source. Game date is not player/stat freshness. Random offer order is not a shared daily answer.',games=games)

def publish(pack,destination):
    destination=Path(destination);destination.mkdir(parents=True,exist_ok=True)
    raw=(json.dumps(pack,ensure_ascii=False,indent=2)+'\n').encode();digest=hashlib.sha256(raw).hexdigest()
    name=pack['gameDate']+'-'+digest[:12]+'.json';target=destination/name
    if not target.exists():
        fd,temp=tempfile.mkstemp(prefix='.daily-',dir=destination)
        try:
            with os.fdopen(fd,'wb') as f:f.write(raw);f.flush();os.fsync(f.fileno())
            os.replace(temp,target)
        finally:
            if os.path.exists(temp):os.unlink(temp)
    pointer=destination/'latest.json';previous=json.loads(pointer.read_text()).get('file') if pointer.exists() else None
    value=dict(file=name,previous=previous,sha256=digest,gameDate=pack['gameDate'],timeZone=pack['timeZone'],modes=len(pack['games']))
    fd,temp=tempfile.mkstemp(prefix='.pointer-',dir=destination)
    try:
        with os.fdopen(fd,'w') as f:json.dump(value,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
        os.replace(temp,pointer)
    finally:
        if os.path.exists(temp):os.unlink(temp)
    return target

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--snapshot',type=Path,required=True);parser.add_argument('--date',type=date.fromisoformat,required=True);parser.add_argument('--timezone',required=True);parser.add_argument('--destination',type=Path,default=ROOT/'ref/futbol11-daily');args=parser.parse_args()
    try:
        pack=compile_daily(args.snapshot,args.date,args.timezone);target=publish(pack,args.destination);print(str(target));print(len(pack['games']),'daily modes compiled')
    except Exception as error:parser.exit(1,'Daily refresh rejected; previous daily package retained: '+str(error)+'\n')
