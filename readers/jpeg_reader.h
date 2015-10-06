#ifndef _JPEG_READER_H_
#define _JPEG_READER_H_

#include "CImg.h"
#ifdef cimg_use_jpeg
/*include goes here*/
#endif
using namespace cimg_library;

namespace image_reader {
	static bool _check_jpeg(unsigned char * buf) {
		return false;
	}
	
#ifdef cimg_use_jpeg

#endif
	
	template <typename T>
	static CImg<T> *_read_jpeg(unsigned char * buf, unsigned int size) {
#ifdef cimg_use_jpeg
		return NULL;
#else
		return NULL;
#endif
	}
}

#endif // _JPEG_READER_H_
