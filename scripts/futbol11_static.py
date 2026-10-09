"""Parse the small static-data subset of JavaScript without evaluating code."""
import re
from futbol11_source import js_string
TOKEN = re.compile(r'''\s*(?:(?P<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?P<number>-?\d+(?:\.\d+)?)|(?P<identifier>[A-Za-z_$][\w$]*)|(?P<punct>[\[\]{},:]))''')


def array_at(source, start):
    pos = start
    items = 0
    def token():
        nonlocal pos, items
        match = TOKEN.match(source, pos)
        if not match:
            raise ValueError('Non-static JavaScript data at offset '+str(pos))
        pos = match.end(); items += 1
        if items > 100_000:
            raise ValueError('Static data exceeds token limit')
        return match.lastgroup, match.group(match.lastgroup)
    def value(first=None, depth=0):
        if depth > 12:
            raise ValueError('Static data exceeds nesting limit')
        kind, text = first or token()
        if kind == 'string': return js_string(text)
        if kind == 'number': return float(text) if '.' in text else int(text)
        if kind == 'identifier' and text in ('null', 'true', 'false'):
            return {'null': None, 'true': True, 'false': False}[text]
        if text == '[':
            result = []; next_token = token()
            if next_token[1] == ']': return result
            while True:
                result.append(value(next_token, depth+1)); separator = token()[1]
                if separator == ']': return result
                if separator != ',': raise ValueError('Invalid static array')
                next_token = token()
                if next_token[1] == ']': return result
        if text == '{':
            result = {}; next_token = token()
            if next_token[1] == '}': return result
            while True:
                kind, text = next_token
                if kind not in ('identifier', 'string'): raise ValueError('Invalid static object key')
                key = js_string(text) if kind == 'string' else text
                if key in result: raise ValueError('Duplicate static key: '+key)
                if token()[1] != ':': raise ValueError('Invalid static object')
                result[key] = value(depth=depth+1); separator = token()[1]
                if separator == '}': return result
                if separator != ',': raise ValueError('Invalid static object')
                next_token = token()
                if next_token[1] == '}': return result
        raise ValueError('JavaScript expression is not static data')
    result = value()
    if not isinstance(result, list): raise ValueError('Expected a static array')
    return result


def tables(source, required):
    result = []
    for match in re.finditer(r'\[\s*\{\s*(?:id|name)\s*:', source):
        try:
            data = array_at(source, match.start())
        except ValueError:
            continue
        if data and all(isinstance(row, dict) and required <= row.keys() for row in data):
            result.append(data)
    return result


def one_table(source, required):
    matches = tables(source, required)
    if len(matches) != 1: raise ValueError('Expected one unambiguous static table, got '+str(len(matches)))
    return matches[0]
