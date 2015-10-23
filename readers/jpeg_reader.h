#ifndef _JPEG_READER_H_
#define _JPEG_READER_H_

#include "CImg.h"
#ifdef cimg_use_jpeg
extern "C" {
#include <jpeglib.h>
}
#endif
using namespace cimg_library;

namespace image_reader {
	static bool _check_jpeg(const char* buffer, size_t size) {
#ifdef cimg_use_jpeg
		if (size < 4) {
			return false;
		}
		const unsigned char* buf = (const unsigned char*) buffer;
		bool res = buf[0] == 0xff
				&& buf[1] == 0xd8
				&& buf[size-2] == 0xff
				&& buf[size-1] == 0xd9;
		return res;
#else
		return false;
#endif
	}
	
#ifdef cimg_use_jpeg
	const static JOCTET EOI_BUFFER[1] = { JPEG_EOI };
	struct JpegDataSource {
		struct jpeg_source_mgr pub;
		const JOCTET           *data;
		size_t                 len;
	};

	static void my_init_source(j_decompress_ptr cinfo) {
		
	}

	static boolean my_fill_input_buffer(j_decompress_ptr cinfo) {
		JpegDataSource* src = (JpegDataSource*) cinfo->src;
		// No more data.  Probably an incomplete image;  just output EOI.
		src->pub.next_input_byte = EOI_BUFFER;
		src->pub.bytes_in_buffer = 1;
		return TRUE;
	}
	
	static void my_skip_input_data(j_decompress_ptr cinfo, long num_bytes) {
		JpegDataSource* src = (JpegDataSource*)cinfo->src;
		if (src->pub.bytes_in_buffer < num_bytes) {
			// Skipping over all of remaining data;  output EOI.
			src->pub.next_input_byte = EOI_BUFFER;
			src->pub.bytes_in_buffer = 1;
		} else {
			// Skipping over only some of the remaining data.
			src->pub.next_input_byte += num_bytes;
			src->pub.bytes_in_buffer -= num_bytes;
		}
	}
	
	static void my_term_source(j_decompress_ptr cinfo) {
		
	}

	static void my_set_source_mgr(j_decompress_ptr cinfo, const char* data, size_t len) {
		JpegDataSource* src;
		if (cinfo->src == 0) { // if this is first time;  allocate memory
			cinfo->src = (struct jpeg_source_mgr*)(*cinfo->mem->alloc_small)
			  ((j_common_ptr) cinfo, JPOOL_PERMANENT, sizeof(JpegDataSource));
		}
		src = (JpegDataSource*) cinfo->src;
		src->pub.init_source = my_init_source;
		src->pub.fill_input_buffer = my_fill_input_buffer;
		src->pub.skip_input_data = my_skip_input_data;
		src->pub.resync_to_restart = jpeg_resync_to_restart; // default
		src->pub.term_source = my_term_source;
		// fill the buffers
		src->data = (const JOCTET*) data;
		src->len = len;
		src->pub.bytes_in_buffer = len;
		src->pub.next_input_byte = src->data;
	}
#endif
	
	template <typename T>
	static CImg<T> *_read_jpeg(const char* buffer, size_t size) {
#ifdef cimg_use_jpeg
		struct jpeg_decompress_struct cinfo;
		typename CImg<T>::_cimg_error_mgr jerr;
		cinfo.err = jpeg_std_error(&jerr.original);
		jerr.original.error_exit = CImg<T>::_cimg_jpeg_error_exit;

		if (setjmp(jerr.setjmp_buffer)) { // JPEG error
			return NULL;
		}

		// std::FILE *const nfile = file?file:cimg::fopen(filename,"rb");
		jpeg_create_decompress(&cinfo);
		
		my_set_source_mgr(&cinfo, buffer, size);
		
		jpeg_read_header(&cinfo,TRUE);
		jpeg_start_decompress(&cinfo);

		if (cinfo.output_components!=1 && cinfo.output_components!=3 && cinfo.output_components!=4) {
			return NULL;
		}
		CImg<unsigned char> buf(cinfo.output_width*cinfo.output_components);
		CImg<T> *cimgData = new CImg<T>;
		
		try {
			JSAMPROW row_pointer[1];
			cimgData->assign(cinfo.output_width,cinfo.output_height,1,cinfo.output_components);
			T *ptr_r = cimgData->_data,
			  *ptr_g = cimgData->_data + 1UL * cimgData->_width * cimgData->_height,
			  *ptr_b = cimgData->_data + 2UL * cimgData->_width * cimgData->_height,
			  *ptr_a = cimgData->_data + 3UL * cimgData->_width * cimgData->_height;
			while (cinfo.output_scanline < cinfo.output_height) {
				*row_pointer = buf._data;
				if (jpeg_read_scanlines(&cinfo, row_pointer, 1) != 1) {
					warn("load_jpeg(): Incomplete data");
					break;
				}
				const unsigned char *ptrs = buf._data;
				switch (cimgData->_spectrum) {
				case 1: {
					cimg_forX(*cimgData, x) *(ptr_r++) = (T)*(ptrs++);
					break;
				}
				case 3: {
					cimg_forX(*cimgData, x) {
						*(ptr_r++) = (T)*(ptrs++);
						*(ptr_g++) = (T)*(ptrs++);
						*(ptr_b++) = (T)*(ptrs++);
					}
					break;
				}
				case 4: {
					cimg_forX(*cimgData, x) {
						*(ptr_r++) = (T)*(ptrs++);
						*(ptr_g++) = (T)*(ptrs++);
						*(ptr_b++) = (T)*(ptrs++);
						*(ptr_a++) = (T)*(ptrs++);
					}
					break;
				}
				}
			}
			jpeg_finish_decompress(&cinfo);
			jpeg_destroy_decompress(&cinfo);
		} catch (...) {
			delete cimgData;
			jpeg_destroy_decompress(&cinfo);
			throw;
		}
		return cimgData;
#else
		return NULL;
#endif
	}
}

#endif // _JPEG_READER_H_
