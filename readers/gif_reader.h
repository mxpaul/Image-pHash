#ifndef _GIF_READER_H_
#define _GIF_READER_H_

#include <string.h>
#include "CImg.h"
#include "../util/cwarn.h"
#ifdef cimg_use_gif
extern "C" {
#include <gif_lib.h>
}
extern int GifError(void);
extern char *GifErrorString(void);
extern int GifLastError(void);

#ifndef GRAPHICS_EXT_FUNC_CODE
#  define GRAPHICS_EXT_FUNC_CODE    0xf9
#endif

#ifndef NO_TRANSPARENT_COLOR
#  define NO_TRANSPARENT_COLOR	-1
#endif

#endif
using namespace cimg_library;

namespace image_reader {
	static bool _check_gif(const char* buffer, size_t size) {
		char gif_header1[] = { 0x47, 0x49, 0x46, 0x38, 0x39, 0x61 };
		char gif_header2[] = { 0x47, 0x49, 0x46, 0x38, 0x37, 0x61 };
		const size_t gif_header_len = 6;

		if (strncmp(buffer, gif_header1, gif_header_len) == 0) {
			return true;
		} else if (strncmp(buffer, gif_header2, gif_header_len) == 0) {
			return true;
		}
		return false;
	}


#ifdef cimg_use_gif
	struct GifDataSource {
		const char* buf;
		size_t len;
		size_t pos;
	};

	int gif_read(GifFileType *gif, GifByteType *out, int length) {
		GifDataSource *src = (GifDataSource *) gif->UserData;
		if (src == NULL) {
			return 0;
		}
		if (src->pos >= src->len) {
			// png_error(png_ptr, "EOF");
			return 0;
		}

		size_t bytes_left = src->len - src->pos;
		if (length > bytes_left) {
			length = bytes_left;
		}

		memcpy(out, src->buf, length);
		src->buf += length;
		src->pos += length;
		return length;
	}

#endif

	template <typename T>
	static CImg<T> *_read_gif(const char* buffer, size_t size) {
#ifdef cimg_use_gif
		GifDataSource gif;
		gif.buf = buffer;
		gif.len = size;
		gif.pos = 0;

		// warn("%d.%d.%d", GIFLIB_MAJOR, GIFLIB_MINOR, GIFLIB_RELEASE);
		GifFileType *gif_file = DGifOpen(&gif, &gif_read);
		int err = GifLastError();
		if (err != 0) {
			cwarn("Error while reading a gif image. Error = %d.", err);
			return NULL;
		}

		if (DGifSlurp(gif_file) == GIF_ERROR) {
			cwarn("Error while reading a gif image. Error = %d", GifLastError());
			return NULL;
		}

		if (gif_file->ImageCount == 0) {
			cwarn("No frames found in gif image");
			return NULL;
		}

		CImgList<T> cimgList;
		cimgList.assign();

		try {
			for (int i = 0; i < gif_file->ImageCount; ++i) {
				SavedImage* img = &gif_file->SavedImages[i];
				int width = img->ImageDesc.Width;
				int height = img->ImageDesc.Height;
				int depth = gif_file->SColorResolution;
				int colors = gif_file->SColorMap == NULL ? 0 : gif_file->SColorMap->ColorCount;
				int background = gif_file->SBackGroundColor;
				ColorMapObject* color_map = img->ImageDesc.ColorMap ? img->ImageDesc.ColorMap : gif_file->SColorMap;
				/* if (color_map == NULL) { // no tests no code :-)
					cwarn("No color map for gif image");
					continue;
				} */

				ExtensionBlock* gcb = NULL;
				for (int i = 0; i < img->ExtensionBlockCount; ++i) {
					if (img->ExtensionBlocks[i].Function == GRAPHICS_EXT_FUNC_CODE) {
						gcb = &img->ExtensionBlocks[i];
						break;
					}
				}
				int transparent_color = NO_TRANSPARENT_COLOR;
				bool is_alpha = gcb && (gcb->Bytes[0] & 0x01);
				if (is_alpha) {
					transparent_color = gcb->Bytes[3];
				}
				// cwarn("width = %d; height = %d; depth = %d; colors = %d; background = %d; is_alpha = %d, transparent_color = %d", width, height, depth, colors, background, is_alpha, transparent_color);

				CImg<T> frame_img;
				frame_img.assign(width, height, 1, 3 + (is_alpha?1:0));

				T *ptr_r = frame_img.data(0,0,0,0),
				  *ptr_g = frame_img.data(0,0,0,1),
				  *ptr_b = frame_img.data(0,0,0,2),
				  *ptr_a = is_alpha ? frame_img.data(0,0,0,3) : 0;

				for (int y = 0; y < height; ++y) {
					for (int x = 0; x < width; ++x) {
						unsigned char color_idx = img->RasterBits[y * width + x];
						GifColorType& color_obj = color_map->Colors[color_idx];
						GifByteType r = color_obj.Red;
						GifByteType g = color_obj.Green;
						GifByteType b = color_obj.Blue;
						GifByteType alpha = color_idx == (unsigned char) transparent_color ? 0x00 : 0xFF;

						switch (frame_img._spectrum) {
						case 3: {
							*(ptr_r++) = (T) r;
							*(ptr_g++) = (T) g;
							*(ptr_b++) = (T) b;
							break;
						}
						case 4: {
							*(ptr_r++) = (T) r;
							*(ptr_g++) = (T) g;
							*(ptr_b++) = (T) b;
							if (ptr_a) {
								*(ptr_a++) = (T) alpha;
							}
							break;
						}
						}
					}
				}

				if (frame_img) {
					frame_img.move_to(cimgList);
				}

			}
		} catch (...) {
			if (!DGifCloseFile(gif_file)) {
				cwarn("Error while closing a gif image. Error = %d", GifLastError());
			}

			throw;
		}

		if (!DGifCloseFile(gif_file)) {
			cwarn("Error while closing a gif image. Error = %d", GifLastError());
			return NULL;
		}

		return new CImg<T>(cimgList.get_append('z', 0));

#else
		return NULL;
#endif
	}
}

#endif // _GIF_READER_H_
