import re 

def camelToUnderscore(name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    o = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    return o

def underscoreToCamel(word):
    return ''.join(x.capitalize() or '_' for x in word.split('_'))

