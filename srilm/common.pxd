from libcpp cimport bool
from array import array
cimport c_vocab

cdef extern from "Boolean.h":
    ctypedef bool Boolean

cdef extern from "Prob.h":
    ctypedef float LogP
    ctypedef double LogP2
    ctypedef double Prob
    Prob LogPtoPPL(LogP2 prob)

cdef extern from "File.h":
    cdef cppclass File:
        File(const char *name, const char *mode, int exitOnError)
        Boolean error()

cdef extern from "Counts.h":
    ctypedef double FloatCount
        
cdef extern from "TextStats.h":
    cdef cppclass TextStats:
        TextStats()
        LogP2 prob
        FloatCount zeroProbs
        FloatCount numSentences
        FloatCount numWords
        FloatCount numOOVs

cdef extern from "NgramStats.h":
    cdef cppclass NgramStats:
        NgramStats(c_vocab.Vocab &vocab, unsigned int order)

cdef extern from "Discount.h":
    cdef cppclass Discount:
        Discount()
        Boolean estimate(NgramStats &counts, unsigned order)
        Boolean interpolate

    cdef cppclass ModKneserNey:
        ModKneserNey()

    cdef cppclass KneserNey:
        KneserNey()

    cdef cppclass GoodTuring:
        GoodTuring()

    cdef cppclass WittenBell:
        WittenBell()




