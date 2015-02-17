from cython.operator cimport dereference as deref
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from vocab cimport Vocab
from ngram cimport defaultNgramOrder, Stats
cimport c_vocab

cdef class Lm:
    """Maximum Entropy Language Model"""
    def __cinit__(self, Vocab v, unsigned order = defaultNgramOrder):
        if order < 1:
            raise ValueError('Invalid order')
        self.thisptr = new MEModel(deref(<c_vocab.Vocab *>(v.thisptr)), order)
        if self.thisptr == NULL:
            raise MemoryError
        self.keysptr = <VocabIndex *>PyMem_Malloc((order+1) * sizeof(VocabIndex))
        if self.keysptr == NULL:
            raise MemoryError
        self._vocab = v
        self._order = order

    def __dealloc__(self):
        PyMem_Free(self.keysptr)
        del self.thisptr

    property order:
        def __get__(self):
            return self._order

    def prob(self, VocabIndex word, context):
        pass

    def prob_ngram(self, ngram):
        pass

    def read(self, const char *fname, Boolean limitVocab = False):
        cdef File *fptr = new File(fname, 'r', 0)
        if fptr.error():
            raise IOError
        ok = self.thisptr.read(deref(fptr), limitVocab)
        del fptr
        return ok

    def write(self, const char *fname):
        cdef File *fptr = new File(fname, 'w', 0)
        if fptr.error():
            raise IOError
        self.thisptr.write(deref(fptr))
        del fptr

    def train(self, Stats ts):
        pass
