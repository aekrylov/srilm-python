from cython.operator cimport dereference as deref
from vocab cimport vocab, Vocab_None
from cpython cimport array
from array import array
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free

cdef inline bint _isindices(words):
    return isinstance(words, array) and words.typecode == 'I'

cdef inline void _tobuffer(unsigned int order, VocabIndex *buff, array.array words):
    cdef int n = min(order, len(words))
    cdef int i
    for i in range(n):
        buff[i] = words[i]
    buff[n] = Vocab_None

cdef inline array.array _toarray(unsigned int order, VocabIndex *buff):
    cdef array.array a = array('I', [])
    cdef int i
    for i in range(order):
        a.append(buff[i])
    return a

cdef class lm:

    def __cinit__(self, vocab v, unsigned order = defaultNgramOrder):
        self.thisptr = new Ngram(deref(<Vocab *>(v.thisptr)), order)
        if self.thisptr == NULL:
            raise MemoryError
        self.keysptr = <VocabIndex *>PyMem_Malloc((order+1) * sizeof(VocabIndex))
        if self.keysptr == NULL:
            raise MemoryError

    def __dealloc__(self):
        PyMem_Free(self.keysptr)
        del self.thisptr

    property order:
        def __get__(self):
            return self.thisptr.setorder(0)

        def __set__(self, unsigned neworder):
            cdef VocabIndex *p = <VocabIndex *>PyMem_Realloc(self.keysptr, (neworder+1) * sizeof(VocabIndex))
            if p == NULL:
                raise MemoryError
            self.keysptr = p
            self.thisptr.setorder(neworder)

    def prob(self, VocabIndex word, context):
        """Return log probability of p(word | context)
        
           Note that the context is an ngram context in reverse order, i.e., if the text is 
                      ... w_0 w_1 w_2 ...
           then this function computes
                      p(w_2 | w_1, w_0)
           and 'context' should be (w_1, w_0), *not* (w_0, w_1).
        """
        if not context:
            return self.thisptr.wordProb(word, NULL)
        elif _isindices(context):
            _tobuffer(self.order, self.keysptr, context)
            return self.thisptr.wordProb(word, self.keysptr)
        else:
            raise TypeError('Expect array')

    def read(self, const char *fname, Boolean limitVocab = 0):
        cdef File *fptr = new File(fname, 'r', 1)
        cdef bint ok = self.thisptr.read(deref(fptr), limitVocab)
        del fptr
        return ok

    def write(self, const char *fname):
        cdef File *fptr = new File(<const char*>fname, 'w', 1)
        self.thisptr.write(deref(fptr))
        del fptr

cdef class stats:
    """Holds ngram counts as a trie"""
    def __cinit__(self, vocab v, unsigned int order):
        self.thisptr = new NgramStats(deref(<Vocab *>(v.thisptr)), order)
        if self.thisptr == NULL:
            raise MemoryError
        self.keysptr = <VocabIndex *>PyMem_Malloc((order+1) * sizeof(VocabIndex))
        if self.keysptr == NULL:
            raise MemoryError

    def __dealloc__(self):
        PyMem_Free(self.keysptr)
        del self.thisptr

    property order:
        def __get__(self):
            return self.thisptr.getorder()

    def get(self, words):
        return self.__getitem__(words)

    def set(self, words, count):
        return self.__setitem__(words, count)

    def remove(self, words):
        cdef NgramCount count
        cdef Boolean b
        if not words:
            b = self.thisptr.removeCount(NULL, &count)
            return count if b else 0
        elif _isindices(words):
            _tobuffer(self.order, self.keysptr, words)
            b = self.thisptr.removeCount(self.keysptr, &count)
            return count if b else 0
        else:
            raise TypeError('Expect array')

    def read(self, const char *fname):
        cdef File *fptr = new File(<const char*>fname, 'r', 1)
        cdef bint ok = self.thisptr.read(deref(fptr))
        del fptr
        return ok

    def write(self, const char *fname):
        cdef File *fptr = new File(<const char*>fname, 'w', 1)
        self.thisptr.write(deref(fptr))
        del fptr

    def __getitem__(self, words):
        cdef NgramCount *p
        if not words:
            p = self.thisptr.findCount(NULL)
            return 0 if p == NULL else deref(p)
        elif _isindices(words):
            _tobuffer(self.order, self.keysptr, words)
            p = self.thisptr.findCount(self.keysptr)
            return 0 if p == NULL else deref(p)
        else:
            raise TypeError('Expect array')

    def __setitem__(self, words, NgramCount count):
        cdef NgramCount *p
        if not words:
            p = self.thisptr.insertCount(NULL)
            p[0] = count
        elif _isindices(words):
            _tobuffer(self.order, self.keysptr, words)
            p = self.thisptr.insertCount(self.keysptr)
            p[0] = count
        else:
            raise TypeError('Expect array')

    def __delitem__(self, words):
        self.remove(words)

    def __iter__(self):
        self.iterptr = new NgramsIter(deref(self.thisptr), self.keysptr, self.order, NULL)
        return self

    def __next__(self):
        cdef NgramCount *p = self.iterptr.next()
        cdef array.array keys
        if p == NULL:
            del self.iterptr
            raise StopIteration
        else:
            keys = _toarray(self.order, self.keysptr)
            return (keys, deref(p))
