#ifndef RENDER_BLEND_H
#define RENDER_BLEND_H

#include <libass/ass/ass.h>
#include <libass/ass/ass_types.h>

typedef struct blend_result {
    int bounding_rect_x;
    int bounding_rect_y;
    int bounding_rect_w;
    int bounding_rect_h;

    int buffer_size;
    unsigned char* buffer;
} Blend_Result;

Blend_Result renderBlend(ASS_Image *img);

#endif
