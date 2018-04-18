
from __future__ import print_function
from math import factorial as fac

def print_headers(verifications):
    print("{0:>5} {1:>7} {2:>10}".format("size", "edges", "mitm"), end=" ")
    for v in verifications:
        print ("{0:>5}".format("v=" + str(v)), end=" ")
    print()

def print_row(size, mitm, verifications):
    edges = int(size * (size - 1) / 2)
    print("{0:>5} {1:>7} {2:>10}".format(size, edges, mitm), end=" ")
    for v in verifications:
        a = mitm
        g = edges - mitm
        c = edges
        if edges > (mitm + v):
            not_noticed = ((fac(g) * fac(c - v)) /
                           (fac(c) * fac(g - v)))
        else:
            not_noticed = 0
        detect_prob = 1 - not_noticed
        print ("{0:>6}".format("{0:02.1%}".format(detect_prob)), end=" ")
    print()

if __name__ == "__main__":

    sizes = range(3, 18)
    verifications = range(1, 10)

    print_headers(verifications)

    print_row(size=4, mitm=1, verifications=verifications)
    print_row(size=4, mitm=2, verifications=verifications)
    print_row(size=4, mitm=3, verifications=verifications)
    print_row(size=8, mitm=1, verifications=verifications)
    print_row(size=8, mitm=2, verifications=verifications)
    print_row(size=8, mitm=3, verifications=verifications)

