#ifndef _PNG_READER_H_
#define _PNG_READER_H_

#include "CImg.h"
#ifdef cimg_use_png
#  include <png.h>
#endif
using namespace cimg_library;

namespace image_reader {
	static bool _check_png(unsigned char * buf) {
		
#ifdef cimg_use_png
		return !png_sig_cmp(buf, 0, 8);
#endif
		return false;
	}
	
#ifdef cimg_use_png
	struct PngData {
		png_bytep p;
		png_uint_32 len;
		png_uint_32 pos;
	};
	
	typedef PngData* PngDataPtr;
	
	
	static void _read_data_png(png_structp png_ptr, png_bytep data, png_size_t length) {
		PngDataPtr pngData = (PngDataPtr) png_get_io_ptr(png_ptr);
		if (pngData == NULL) {
			return;   // add custom error handling here
		}
		
		if (pngData->pos >= pngData->len) {
			png_error(png_ptr, "EOF");
			return;
		}

		png_size_t bytes_left = pngData->len - pngData->pos;
		if (length > bytes_left) {
			length = bytes_left;
		}
		
		memcpy(data, pngData->p, length);
		pngData->p += length;
		pngData->pos += length;
	}
#endif
	
	template <typename T>
	static CImg<T> *_read_png(unsigned char * buf, unsigned int size) {
#ifdef cimg_use_png
		PngData pngData;
		pngData.p = (png_bytep) (buf + 8);
		pngData.len = (png_uint_32) size;
		pngData.pos = 8;
		
		png_voidp user_error_ptr = 0;
		png_error_ptr user_error_fn = 0, user_warning_fn = 0;
		png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,user_error_ptr,user_error_fn,user_warning_fn);
		if (!png_ptr) {
			return NULL;
		}

		png_infop info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr) {
			png_destroy_read_struct(&png_ptr, (png_infopp) NULL, (png_infopp) NULL);
			return NULL;
		}

		png_infop end_info = png_create_info_struct(png_ptr);
		if (!end_info) {
			png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp) NULL);
			return NULL;
		}
		
		if (setjmp(png_jmpbuf(png_ptr))) {
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
			return NULL;
		}
		
		png_set_sig_bytes(png_ptr, 8);
		png_set_read_fn(png_ptr, &pngData, &_read_data_png);

		// Get PNG Header Info up to data block
		png_read_info(png_ptr, info_ptr);
		
		png_uint_32 W = 0, H = 0;
		int color_type = 0, bit_depth = 0, interlace_type = 0;
		bool is_gray = false;
		
		png_get_IHDR(png_ptr, info_ptr, &W, &H, &bit_depth, &color_type, &interlace_type, (int*)0, (int*)0);
		
		// Transforms to unify image data
		if (color_type == PNG_COLOR_TYPE_PALETTE) {
			png_set_palette_to_rgb(png_ptr);
			color_type = PNG_COLOR_TYPE_RGB;
			bit_depth = 8;
		}
		if (color_type == PNG_COLOR_TYPE_GRAY && bit_depth < 8) {
			png_set_expand_gray_1_2_4_to_8(png_ptr);
			is_gray = true;
			bit_depth = 8;
		}
		if (png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS)) {
			png_set_tRNS_to_alpha(png_ptr);
			color_type |= PNG_COLOR_MASK_ALPHA;
		}
		if (color_type == PNG_COLOR_TYPE_GRAY || color_type == PNG_COLOR_TYPE_GRAY_ALPHA) {
			png_set_gray_to_rgb(png_ptr);
			color_type |= PNG_COLOR_MASK_COLOR;
			is_gray = true;
		}
		if (color_type == PNG_COLOR_TYPE_RGB) {
			png_set_filler(png_ptr, 0xffffU, PNG_FILLER_AFTER);
		}
		
		// warn("w:%d;\th:%d;\tcolor_type:%d;\tbit_depth:%d;\tinterlace_type:%d", W, H, color_type, bit_depth, interlace_type);
		
		png_read_update_info(png_ptr,info_ptr);
		if (bit_depth != 8 && bit_depth != 16) {
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
		}
		const int byte_depth = bit_depth >> 3;
		
		png_bytep *const imgData = new png_bytep[H];
		for (unsigned int row = 0; row < H; ++row) {
			imgData[row] = new png_byte[byte_depth * 4 * W];
		}
		
		png_read_image(png_ptr, imgData);
		png_read_end(png_ptr, end_info);

		// Read pixel data
		if (color_type != PNG_COLOR_TYPE_RGB && color_type != PNG_COLOR_TYPE_RGB_ALPHA) {
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
		}
		
		CImg<T> *cimgData = new CImg<T>;
		
		try {
			const bool is_alpha = (color_type == PNG_COLOR_TYPE_RGBA);
			cimgData->assign(W, H, 1, (is_gray ? 1 : 3) + (is_alpha ? 1 : 0));
			T
			  *ptr_r = cimgData->data(0,0,0,0),
			  *ptr_g = is_gray?0:cimgData->data(0,0,0,1),
			  *ptr_b = is_gray?0:cimgData->data(0,0,0,2),
			  *ptr_a = !is_alpha?0:cimgData->data(0,0,0,is_gray?1:3);
			  
			switch (bit_depth) {
			case 8 : {
				cimg_forY(*cimgData,y) {
					const unsigned char *ptrs = (unsigned char*)imgData[y];
					cimg_forX(*cimgData,x) {
						*(ptr_r++) = (T)*(ptrs++);
						if (ptr_g) *(ptr_g++) = (T)*(ptrs++); else ++ptrs;
						if (ptr_b) *(ptr_b++) = (T)*(ptrs++); else ++ptrs;
						if (ptr_a) *(ptr_a++) = (T)*(ptrs++); else ++ptrs;
					}
				}
				break;
			}
			case 16 : {
				cimg_forY(*cimgData,y) {
					const unsigned short *ptrs = (unsigned short*)(imgData[y]);
					if (!cimg::endianness()) cimg::invert_endianness(ptrs,4*W);
					cimg_forX(*cimgData,x) {
						*(ptr_r++) = (T)*(ptrs++);
						if (ptr_g) *(ptr_g++) = (T)*(ptrs++); else ++ptrs;
						if (ptr_b) *(ptr_b++) = (T)*(ptrs++); else ++ptrs;
						if (ptr_a) *(ptr_a++) = (T)*(ptrs++); else ++ptrs;
					}
				}
				break;
			}
			
			}
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);

			// Deallocate Image Read Memory
			cimg_forY(*cimgData,n) delete[] imgData[n];
			delete[] imgData;
			
			return cimgData;
		} catch (...) {
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
			delete cimgData;
			cimg_forY(*cimgData,n) delete[] imgData[n];
			delete[] imgData;
			
			throw;
		}
#else
		return NULL;
#endif
	}
}

#endif // _PNG_READER_H_
