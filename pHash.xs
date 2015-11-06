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
#define cimg_use_gif 1

#define PNG_SKIP_SETJMP_CHECK
#include "util/cwarn.h"
#include "CImg.h"
#include "readers/image_reader.h"
using namespace cimg_library;
using namespace image_reader;

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

int ph_dct_imagehash(CImg<uint8_t> &src,ulong64 &hash){
	CImg<float> meanfilter(7,7,1,1,1);
	CImg<float> img;
	if (src.spectrum() == 3){
		img = src.RGBtoYCbCr().channel(0).get_convolve(meanfilter);
	} else if (src.spectrum() == 4){
		int width = src.width();
		int height = src.height();
		int depth = src.depth();
		img = src.crop(0,0,0,0,width-1,height-1,depth-1,2).RGBtoYCbCr().channel(0).get_convolve(meanfilter);
	} else {
		img = src.channel(0).get_convolve(meanfilter);
	}

	img.resize(32,32);
	CImg<float> *C  = ph_dct_matrix(32);
	CImg<float> Ctransp = C->get_transpose();

	CImg<float> dctImage = (*C)*img*Ctransp;

	CImg<float> subsec = dctImage.crop(1,1,8,8).unroll('x');
	
	float median = subsec.median();
	ulong64 one = 0x0000000000000001;
	hash = 0x0000000000000000;
	for (int i=0;i< 64;i++){
		float current = subsec(i);
		if (current > median) {
			hash |= one;
		}
		one = one << 1;
	}
	
	delete C;

	return 0;
}

int ph_dct_imagehash(const char* file, ulong64 &hash){
	if (!file){
		return -1;
	}
	CImg<uint8_t> src;
	try {
		src.load(file);
	} catch (CImgIOException ex){
		return -1;
	}
	// warn("fromFile: %d %d %d %d", src.width(), src.height(), src.depth(), src.spectrum());
	return ph_dct_imagehash(src, hash);
}

int ph_dct_imagehash(const char* const buffer, size_t size, ulong64 &hash) {
	CImg<uint8_t> *src = read_image<uint8_t>(buffer, size);
	
	if (src == NULL) {
		cwarn("Image couldn't be decoded from memory.");
		return -1;
	}
	
	int h = ph_dct_imagehash(*src, hash);
	delete src;
	return h;
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



CImg<float>* GetMHKernel(float alpha, float level){
	int sigma = (int)4*(int)pow((float)alpha,(float)level);
	static CImg<float> *pkernel = NULL;
	float xpos, ypos, A;
	if (!pkernel){
		pkernel = new CImg<float>(2*sigma+1,2*sigma+1,1,1,0);
		cimg_forXY(*pkernel,X,Y){
			xpos = pow(alpha,-level)*(X-sigma);
			ypos = pow(alpha,-level)*(Y-sigma);
			A = xpos*xpos + ypos*ypos;
			pkernel->atXY(X,Y) = (2-A)*exp(-A/2);
		}
	}
	return pkernel;
}

uint8_t* ph_mh_imagehash(CImg<uint8_t> &src, int &N,float alpha, float lvl){
	CImg<uint8_t> img;

	uint8_t *hash = (unsigned char*)malloc(72*sizeof(uint8_t));
	N = 72;
	
	if (src.spectrum() == 3){
		img = src.get_RGBtoYCbCr().channel(0).blur(1.0).resize(512,512,1,1,5).get_equalize(256);
	} else{
		img = src.channel(0).get_blur(1.0).resize(512,512,1,1,5).get_equalize(256);
	}
	src.clear();

	CImg<float> *pkernel = GetMHKernel(alpha,lvl);
	CImg<float> fresp =  img.get_correlate(*pkernel);
	img.clear();
	fresp.normalize(0,1.0);
	CImg<float> blocks(31,31,1,1,0);
	for (int rindex=0;rindex < 31;rindex++){
		for (int cindex=0;cindex < 31;cindex++){
			blocks(rindex,cindex) = fresp.get_crop(rindex*16,cindex*16,rindex*16+16-1,cindex*16+16-1).sum();
		}
	}
	int hash_index;
	int nb_ones = 0, nb_zeros = 0;
	int bit_index = 0;
	unsigned char hashbyte = 0;
	for (int rindex=0;rindex < 31-2;rindex+=4){
		CImg<float> subsec;
		for (int cindex=0;cindex < 31-2;cindex+=4){
			subsec = blocks.get_crop(cindex,rindex, cindex+2, rindex+2).unroll('x');
			float ave = subsec.mean();
			cimg_forX(subsec, I){
				hashbyte <<= 1;
				if (subsec(I) > ave){
					hashbyte |= 0x01;
					nb_ones++;
				} else {
					nb_zeros++;
				}
				bit_index++;
				if ((bit_index%8) == 0){
					hash_index = (int)(bit_index/8) - 1;
					hash[hash_index] = hashbyte;
					hashbyte = 0x00;
				}
			}
		}
	}

	return hash;
}

uint8_t* ph_mh_imagehash(const char *const buffer, size_t size, int &N, float alpha, float lvl){
	
	if (buffer == NULL){
		return NULL;
	}
	
	CImg<uint8_t> *src = read_image<uint8_t>(buffer, size);
	
	if (src == NULL) {
		return NULL;
	}
	
	uint8_t* h = ph_mh_imagehash(*src, N, alpha, lvl);
	delete src;
	return h;
}

uint8_t* ph_mh_imagehash(const char *filename, int &N,float alpha, float lvl){
	if (filename == NULL){
		return NULL;
	}
	
	CImg<uint8_t> src(filename);
	return ph_mh_imagehash(src, N, alpha, lvl);
}

int ph_bitcount8(uint8_t val){
	int num = 0;
	while (val){
		++num;
		val &= val - 1;
	}
	return num;
}

double ph_hammingdistance2(uint8_t *hashA, int lenA, uint8_t *hashB, int lenB){
	if (lenA != lenB){
		return -1.0;
	}
	if ((hashA == NULL) || (hashB == NULL) || (lenA <= 0)){
		return -1.0;
	}
	double dist = 0;
	uint8_t D = 0;
	for (int i=0;i<lenA;i++){
		D = hashA[i]^hashB[i];
		dist = dist + (double)ph_bitcount8(D);
	}
	double bits = (double)lenA*8;
	return dist/bits;

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
hash_mem(buffer)
		SV *buffer;
	PPCODE:
		STRLEN na;
		char *buf = (char*) SvPV(buffer, na);
		size_t buf_len = (size_t) na;
		
		// warn("%p %d %d %d %d", buffer, SvIV(ST(1)), SvIV(ST(2)), SvIV(ST(3)), SvIV(ST(4)));
		
		ulong64 hash = 0;
		int x = -1;

		try {
			x = ph_dct_imagehash(buf, buf_len, hash);
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

SV*
mh_hash(path, param_alpha, param_level)
		char *path;
		double param_alpha;
		double param_level;
	PROTOTYPE: $$$
	PPCODE:
		int hashlen = 0;
		char *hash = NULL;
		float alpha, level;
		alpha = (float)( param_alpha );
		level = (float)( param_level );

		try {
			hash = (char*)ph_mh_imagehash(path, hashlen, alpha, level);
		}
		catch( char * e ) {
			croak("Exception while ...: %s", e);
			if ( hash ) {
				free(hash);
			}
		}
		catch ( ... ) {
			croak("Exception while ...");
			if ( hash ) {
				free(hash);
			}
		}
		
		//printf("x = %d h = %llu\n",x,hash);
		if (hash == NULL) {
			XSRETURN_UNDEF;
		}
		else {
			ST(0) = sv_2mortal( newSVpvn( hash ,hashlen) );
			free(hash);
			XSRETURN(1);
		}
		
SV*
mh_hash_mem(buffer, param_alpha, param_level)
		SV *buffer;
		double param_alpha;
		double param_level;
	PPCODE:
		int hashlen = 0;
		char *hash = NULL;
		float alpha, level;
		alpha = (float)( param_alpha );
		level = (float)( param_level );
		
		STRLEN na;
		char *buf = (char*) SvPV(buffer, na);
		size_t size = (size_t) na;

		try {
			hash = (char*)ph_mh_imagehash(buf, size, hashlen, alpha, level);
		}
		catch( char * e ) {
			croak("Exception while ...: %s", e);
			if ( hash ) {
				free(hash);
			}
		}
		catch ( ... ) {
			croak("Exception while ...");
			if ( hash ) {
				free(hash);
			}
		}
		
		//printf("x = %d h = %llu\n",x,hash);
		if (hash == NULL) {
			XSRETURN_UNDEF;
		}
		else {
			ST(0) = sv_2mortal( newSVpvn( hash ,hashlen) );
			free(hash);
			XSRETURN(1);
		}

SV*
mh_dist(hs1,hs2)
		SV * hs1;
		SV * hs2;
	PROTOTYPE: $$
	PPCODE:
		double dist = 0;
		char *h1, *h2;
		STRLEN na;
		h1 = (char*)SvPV( hs1,na );
		h2 = (char*)SvPV( hs2,na );

		try {
			dist = ph_hammingdistance2((uint8_t*)h1,strlen(h1), (uint8_t*)h2, strlen(h2));
		}
		catch( char * e ) {
			croak("Exception while ...: %s", e);
		}
		catch ( ... ) {
			croak("Exception while ...");
		}

		ST(0) = sv_2mortal( newSVnv( dist ) );
		XSRETURN(1);

