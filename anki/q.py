#!/usr/bin/env python3
import os
import glob

from anki import Collection
from anki.importing import TextImporter

def drv(col):
    cwd = os.getcwd()
    flist = glob.glob('????.txt')
    for inf in flist:
        textf = 'economist.words.' + inf
        deckname = textf.rstrip('.txt')
        textf = os.path.join(cwd, textf)
        print(textf)
        deckid = col.decks.id(deckname)

        ti = TextImporter(col, textf)
        ti.model['did'] = deckid
        col.decks.select(deckid)

        ti.delimiter = '\t'
        ti.initMapping()
        ti.run()

def export(col):
    pass

if __name__ == '__main__':
    path_col = '/Users/yousong/Library/Application Support/Anki2/User 1/collection.anki2'
    col = Collection(path_col)
    drv(col)
    col.close()
