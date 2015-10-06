#ifndef _IMAGE_READER_H_
#define _IMAGE_READER_H_

#include <stdint.h>
#include "png_reader.h"
#include "jpeg_reader.h"

using namespace cimg_library;

namespace image_reader {
	
	template <typename T>
	static CImg<T> *read_image(const char *const buffer, unsigned int size) {
		if (buffer == NULL) {
			return NULL;
		}
		unsigned char *buf = (unsigned char *) buffer;
		
		if (_check_png(buf)) {
			return _read_png<T>(buf, size);
		} else if (_check_jpeg(buf)) {
			return _read_jpeg<T>(buf, size);
		} else {
			return NULL;
		}
		
	}

	

}

#endif // _IMAGE_READER_H_
