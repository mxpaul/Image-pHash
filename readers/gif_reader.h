#ifndef _GIF_READER_H_
#define _GIF_READER_H_

#include "CImg.h"
using namespace cimg_library;

namespace image_reader {
	static bool _check_gif(const char* buffer, size_t size) {
		return false;
	}
	
	template <typename T>
	static CImg<T> *_read_gif(const char* buffer, size_t size) {
		return NULL;
	}
}

#endif // _GIF_READER_H_
