#ifndef _GIF_READER_H_
#define _GIF_READER_H_

#include <string.h>
#include "CImg.h"
#ifdef cimg_use_gif
extern "C" {
#include <gif_lib.h>
}
extern int GifError(void);
extern char *GifErrorString(void);
extern int GifLastError(void);

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
			warn("Error while reading a gif image. Error = %d", err);
			return NULL;
		}
		
		if (DGifSlurp(gif_file) == GIF_ERROR) {
			warn("Error while reading a gif image. Error = %d", GifLastError());
			return NULL;
		}
		
		if (gif_file->ImageCount == 0) {
			warn("No frames found in gif image");
			return NULL;
		}
		
		SavedImage* img = &gif_file->SavedImages[0];
		int width = img->ImageDesc.Width;
		int height = img->ImageDesc.Height;
		int depth = gif_file->SColorResolution;
		int colors = gif_file->SColorMap->ColorCount;
		int background = gif_file->SBackGroundColor;
		
		for (int i = 0; i < img->ExtensionBlockCount; ++i) {
			warn("block[%d]; function = %d", i, img->ExtensionBlocks[i].Function);
			for (int j = 0; j < img->ExtensionBlocks[i].ByteCount; ++j) {
				warn("\t[%d] = %x", j, img->ExtensionBlocks[i].Bytes[j]);
			}
		}
		warn("width = %d; height = %d; depth = %d; colors = %d; background = %d", width, height, depth, colors, background);
		
		
		
		
		// CImg<T> *cimgData = new CImg<T>;
		
		if (!DGifCloseFile(gif_file)) {
			warn("Error while closing a gif image. Error = %d", GifLastError());
			// delete cimgData;
			return NULL;
		}
		
		return NULL;
		
#else
		return NULL;
#endif
	}
}

#endif // _GIF_READER_H_
