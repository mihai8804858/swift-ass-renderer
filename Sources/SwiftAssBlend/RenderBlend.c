#include <stdlib.h>
#include <string.h>
#include <libass/ass/ass.h>
#include <libass/ass/ass_types.h>
#include "RenderBlend.h"

const float MIN_UINT8_CAST = 0.9 / 255;
const float MAX_UINT8_CAST = 255.9 / 255;

#define CLAMP_UINT8(value) ((value > MIN_UINT8_CAST) ? ((value < MAX_UINT8_CAST) ? (int)(value * 255) : 255) : 0)

void *get_buffer(size_t x, size_t y, size_t member_size) {
    if (x > SIZE_MAX / member_size / y)
        return NULL;

    size_t size = x * y * member_size;
    if (!size)
        size = 1;

    void *buffer = malloc(size);
    if (buffer)
        memset(buffer, 0, size);

    return buffer;
}

Blend_Result renderBlend(ASS_Image *img) {
    Blend_Result blend_result;

    // find bounding rect first
    int min_x = img->dst_x, min_y = img->dst_y;
    int max_x = img->dst_x + img->w - 1, max_y = img->dst_y + img->h - 1;
    ASS_Image *cur;
    for (cur = img->next; cur != NULL; cur = cur->next) {
        if (cur->w == 0 || cur->h == 0) continue; // skip empty images
        if (cur->dst_x < min_x) min_x = cur->dst_x;
        if (cur->dst_y < min_y) min_y = cur->dst_y;
        int right = cur->dst_x + cur->w - 1;
        int bottom = cur->dst_y + cur->h - 1;
        if (right > max_x) max_x = right;
        if (bottom > max_y) max_y = bottom;
    }

    int width = max_x - min_x + 1, height = max_y - min_y + 1;

    blend_result.bounding_rect_x = min_x;
    blend_result.bounding_rect_y = min_y;
    blend_result.bounding_rect_w = width;
    blend_result.bounding_rect_h = height;

    if (width == 0 || height == 0)
        return blend_result;

    // make float buffer for blending
    float* buf = (float*)get_buffer(width, height, sizeof(float) * 4);
    if (buf == NULL)
        return blend_result;

    // blend things in
    for (cur = img; cur != NULL; cur = cur->next) {
        int curw = cur->w, curh = cur->h;
        if (curw == 0 || curh == 0) continue; // skip empty images
        int a = (255 - (cur->color & 0xFF));
        if (a == 0) continue; // skip transparent images

        int curs = (cur->stride >= curw) ? cur->stride : curw;
        int curx = cur->dst_x - min_x, cury = cur->dst_y - min_y;

        unsigned char *bitmap = cur->bitmap;
        float normalized_a = a / 255.0;
        float r = ((cur->color >> 24) & 0xFF) / 255.0;
        float g = ((cur->color >> 16) & 0xFF) / 255.0;
        float b = ((cur->color >> 8) & 0xFF) / 255.0;

        int buf_line_coord = cury * width;
        for (int y = 0, bitmap_offset = 0; y < curh; y++, bitmap_offset += curs, buf_line_coord += width) {
            for (int x = 0; x < curw; x++) {
                float pix_alpha = bitmap[bitmap_offset + x] * normalized_a / 255.0;
                float inv_alpha = 1.0 - pix_alpha;

                int buf_coord = (buf_line_coord + curx + x) << 2;
                float *buf_r = buf + buf_coord;
                float *buf_g = buf + buf_coord + 1;
                float *buf_b = buf + buf_coord + 2;
                float *buf_a = buf + buf_coord + 3;

                // do the compositing, pre-multiply image RGB with alpha for current pixel
                *buf_a = pix_alpha + *buf_a * inv_alpha;
                *buf_r = r * pix_alpha + *buf_r * inv_alpha;
                *buf_g = g * pix_alpha + *buf_g * inv_alpha;
                *buf_b = b * pix_alpha + *buf_b * inv_alpha;
            }
        }
    }

    // now build the result;
    // NOTE: we use a "view" over [float,float,float,float] array of pixels,
    // so we _must_ go left-right top-bottom to not mangle the result
    unsigned int *result = (unsigned int*)buf;
    for (int y = 0, buf_line_coord = 0; y < height; y++, buf_line_coord += width) {
        for (int x = 0; x < width; x++) {
            unsigned int pixel = 0;
            int buf_coord = (buf_line_coord + x) << 2;
            float alpha = buf[buf_coord + 3];
            if (alpha > MIN_UINT8_CAST) {
                // need to un-multiply the result
                float value = buf[buf_coord] / alpha;
                pixel |= CLAMP_UINT8(value); // R
                value = buf[buf_coord + 1] / alpha;
                pixel |= CLAMP_UINT8(value) << 8; // G
                value = buf[buf_coord + 2] / alpha;
                pixel |= CLAMP_UINT8(value) << 16; // B
                pixel |= CLAMP_UINT8(alpha) << 24; // A
            }
            result[buf_line_coord + x] = pixel;
        }
    }

    // return the thing
    blend_result.buffer_size = width * height * 4 * sizeof(float);
    blend_result.buffer = (unsigned char*)result;

    return blend_result;
}
