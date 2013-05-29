#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef __cplusplus
}
#endif

#define cimg_debug 0
#define cimg_display 0
#define cimg_use_png 1
#define cimg_use_jpeg 1

#define PNG_SKIP_SETJMP_CHECK
#include "CImg.h"
using namespace cimg_library;

/*
#include <limits.h>
#include <math.h>
#include <dirent.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

*/


//#define __STDC_CONSTANT_MACROS

#include <stdint.h>

#define ulong64 uint64_t

CImg<float>* ph_dct_matrix(const int N){
    CImg<float> *ptr_matrix = new CImg<float>(N,N,1,1,1/sqrt((float)N));
    const float c1 = sqrt(2.0/N); 
    for (int x=0;x<N;x++){
	for (int y=1;y<N;y++){
	    *ptr_matrix->data(x,y) = c1*cos((cimg::PI/2/N)*y*(2*x+1));
	}
    }
    return ptr_matrix;
}

int ph_dct_imagehash(const char* file,ulong64 &hash){

    if (!file){
	return -1;
    }
    CImg<uint8_t> src;
    try {
	src.load(file);
    } catch (CImgIOException ex){
	return -1;
    }
    CImg<float> meanfilter(7,7,1,1,1);
    CImg<float> img;
    if (src.spectrum() == 3){
        img = src.RGBtoYCbCr().channel(0).get_convolve(meanfilter);
    } else if (src.spectrum() == 4){
	int width = img.width();
        int height = img.height();
        int depth = img.depth();
	img = src.crop(0,0,0,0,width-1,height-1,depth-1,2).RGBtoYCbCr().channel(0).get_convolve(meanfilter);
    } else {
	img = src.channel(0).get_convolve(meanfilter);
    }

    img.resize(32,32);
    CImg<float> *C  = ph_dct_matrix(32);
    CImg<float> Ctransp = C->get_transpose();

    CImg<float> dctImage = (*C)*img*Ctransp;

    CImg<float> subsec = dctImage.crop(1,1,8,8).unroll('x');;
   
    float median = subsec.median();
    ulong64 one = 0x0000000000000001;
    hash = 0x0000000000000000;
    for (int i=0;i< 64;i++){
	float current = subsec(i);
        if (current > median)
	    hash |= one;
	one = one << 1;
    }
  
    delete C;

    return 0;
}

int ph_hamming_distance(const ulong64 hash1,const ulong64 hash2){
    ulong64 x = hash1^hash2;
    const ulong64 m1  = 0x5555555555555555ULL;
    const ulong64 m2  = 0x3333333333333333ULL;
    const ulong64 h01 = 0x0101010101010101ULL;
    const ulong64 m4  = 0x0f0f0f0f0f0f0f0fULL;
    x -= (x >> 1) & m1;
    x = (x & m2) + ((x >> 2) & m2);
    x = (x + (x >> 4)) & m4;
    return (x * h01)>>56;
}


MODULE = Image::pHash		PACKAGE = Image::pHash

SV*
hash(path)
        char *path;
    PROTOTYPE: $
    PPCODE:
        ulong64 hash = 0;
        int x = -1;

        try {
            x = ph_dct_imagehash(path, hash);
        }
        catch( char * e ) {
            croak("Exception while ...: %s", e);
        }
        catch ( ... ) {
            croak("Exception while ...");
        }
        
        //printf("x = %d h = %llu\n",x,hash);
        if (x < 0) {
            XSRETURN_UNDEF;
        }
        else {
            ST(0) = sv_2mortal( newSVuv( hash ) );
            XSRETURN(1);
        }

SV*
dist(hs1,hs2)
        SV * hs1;
        SV * hs2;
    PROTOTYPE: $$
    PPCODE:
        int dist = -1;
        ulong64 h1, h2;
        h1 = (ulong64) SvIV( hs1 );
        h2 = (ulong64) SvIV( hs2 );

        try {
            dist = ph_hamming_distance(h1, h2);
        }
        catch( char * e ) {
            croak("Exception while ...: %s", e);
        }
        catch ( ... ) {
            croak("Exception while ...");
        }

        if (dist < 0) {
            XSRETURN_UNDEF;
        }
        else {
            ST(0) = sv_2mortal( newSVuv( dist ) );
            XSRETURN(1);
        }
