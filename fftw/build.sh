#!/bin/bash
#
# Compile FFTW3 library MACOSX_X64 + GCC-4.9 (from Macports, port install gcc49):
#
# ./configure --enable-sse2 --enable-avx --enable-threads --enable-openmp
# ln -s /usr/bin/clang /opt/local/bin/clang
# make -j4 CFLAGS+=-Wa,-q
#
# You need the native clang assembler or else you can't compile the AVX
# extensions ("no such instruction: ..." errors), so symlink /usr/bin/clang 
# into /opt/local/bin/ and then pass -Wa,-q to make's CFLAGS.

g++-mp-4.9 -fopenmp -L`dirname $0` -lgomp -lfftw3_omp -lfftw3 -o fftwtest `dirname $0`/fftwtest.cpp

# upx pack it?
# download upx for mac here: http://www.idrix.fr/Root/content/category/7/26/49/
#upx -9 --lzma fftwtest
