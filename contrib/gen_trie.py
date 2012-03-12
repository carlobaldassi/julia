#!/usr/bin/env python
import sys

def prettyprintstr(data, ldel, rdel, sep):
    if len(data) == 0:
        return ""
    outstr = ldel
    for i,d in enumerate(data):
        outstr += d + data[d][0] + prettyprintstr(data[d][1], ldel, rdel, sep)
        if i != len(data) - 1:
            outstr += sep
    outstr += rdel
    return outstr

# Patricia Trie implementation by Justin Peel
# http://stackoverflow.com/questions/2406416/implementing-a-patricia-trie-for-use-as-a-dictionary/2412468#2412468

class patricia():
    def __init__(self):
        self._data = {}

    def prettyprint(self, ldel, rdel, sep):
        print prettyprintstr(self._data, ldel, rdel, sep)

    def addWord(self, word):
        data = self._data
        i = 0
        while 1:
            try:
                node = data[word[i:i+1]]
            except KeyError:
                if data:
                    data[word[i:i+1]] = [word[i+1:],{}]
                else:
                    if word[i:i+1] == '':
                        return
                    else:
                        if i != 0:
                            data[''] = ['',{}]
                        data[word[i:i+1]] = [word[i+1:],{}]
                return

            i += 1
            if word.startswith(node[0],i):
                if len(word[i:]) == len(node[0]):
                    if node[1]:
                        try:
                            node[1]['']
                        except KeyError:
                            data = node[1]
                            data[''] = ['',{}]
                    return
                else:
                    i += len(node[0])
                    data = node[1]
            else:
                ii = i
                j = 0
                while ii != len(word) and j != len(node[0]) and \
                      word[ii:ii+1] == node[0][j:j+1]:
                    ii += 1
                    j += 1
                tmpdata = {}
                tmpdata[node[0][j:j+1]] = [node[0][j+1:],node[1]]
                tmpdata[word[ii:ii+1]] = [word[ii+1:],{}]
                data[word[i-1:i]] = [node[0][:j],tmpdata]
                return

    def isWord(self,word):
        data = self._data
        i = 0
        while 1:
            try:
                node = data[word[i:i+1]]
            except KeyError:
                return False
            i += 1
            if word.startswith(node[0],i):
                if len(word[i:]) == len(node[0]):
                    if node[1]:
                        try:
                            node[1]['']
                        except KeyError:
                            return False
                    return True
                else:
                    i += len(node[0])
                    data = node[1]
            else:
                return False

    def isPrefix(self,word):
        data = self._data
        i = 0
        wordlen = len(word)
        while 1:
            try:
                node = data[word[i:i+1]]
            except KeyError:
                return False
            i += 1
            if word.startswith(node[0][:wordlen-i],i):
                if wordlen - i > len(node[0]):
                    i += len(node[0])
                    data = node[1]
                else:
                    return True
            else:
                return False

    def removeWord(self,word):
        data = self._data
        i = 0
        while 1:
            try:
                node = data[word[i:i+1]]
            except KeyError:
                print "Word is not in trie."
                return
            i += 1
            if word.startswith(node[0],i):
                if len(word[i:]) == len(node[0]):
                    if node[1]:
                        try:
                            node[1]['']
                            node[1].pop('')
                        except KeyError:
                            print "Word is not in trie."
                        return
                    data.pop(word[i-1:i])
                    return
                else:
                    i += len(node[0])
                    data = node[1]
            else:
                print "Word is not in trie."
                return


    __getitem__ = isWord


def main():
	fin = sys.stdin
	fout = sys.stdout

	p = patricia()
	ls = fin.readlines()
	for l in ls:
		p.addWord(l.rstrip())
        p.prettyprint("\%(", "\)", "\|")
	return 0

if __name__ == "__main__":
	sys.exit(main())




