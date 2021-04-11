
#define DEBUG false

constant float PI = 3.14159265358979323846;

kernel void scan_blur_image(
    read_only image2d_t scan_rows,
    write_only image2d_t output,
    const int radius,
    const int width,
    const int height
) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    #if DEBUG
    printf("kernel(scan_blur_image): radius=%d, width=%d, height=%d\n", radius, width, height);
    #endif 

    float sum = 0.0;

    for (int iy = -radius; iy <= radius; iy++) {
        float xBound = sqrt((float)(radius*radius - iy*iy));

        // x coordinates at the left and right edges of the circle
        int leftX = clamp((int)(x - xBound), 0, width - 1);
        int rightX = clamp((int)(x + xBound), 0, width - 1);

        int currentY = clamp(y + iy, 0, height - 1);

        float rightValue = read_imagef(scan_rows, (int2)(rightX, currentY)).x;
        float leftValue  = read_imagef(scan_rows, (int2)(leftX, currentY)).x;

        sum += (rightValue - leftValue);
    }

    float result = sum / (PI*radius*radius);

    #if DEBUG
    float input = read_imagef(scan_rows, (int2)(x, y)).x;
    printf("kernel(scan_blur_image): (%d, %d): scan_rows=%f sum=%f result=%f\n---\n", 
        x, y, input, sum, result);
    #endif

    write_imagef(output, (int2)(x, y), (float4)(result, 0.0, 0.0, 1.0));
}

inline int buf_index(int x, int y, int width) {
	return y*width + x;
}


kernel void scan_blur_float4(
    global const float *scan_rows,
    global       float4 *output,
                   int radius,
                   int width,
                   int height
) {
    int x = get_global_id(0);
    int y = get_global_id(1);

    # if DEBUG
    printf("kernel(scan_blur): radius=%d, width=%d, height=%d\n", radius, width, height);
    #endif 

    float4 sum = 0.0;

    for (int iy = -radius; iy <= radius; iy++) {
        int x_bound = (int) sqrt((float)(radius*radius - iy*iy));

        // x coordinates at the left and right edges of the circle
        int left_x  = clamp(x * 4 - x_bound, 0, width - 1);
        int right_x = clamp(x * 4 + x_bound, 0, width - 1);

        int current_y = clamp(y + iy, 0, height - 1);

        //float4 left_value = scan_rows[buf_index(left_x, current_y, width) / 4];
        //float4 right_value = scan_rows[buf_index(right_x, current_y, width) / 4];

        float4 left_value = vload4(buf_index(left_x, current_y, width), scan_rows);
        float4 right_value = vload4(buf_index(right_x, current_y, width), scan_rows);
        

        #if DEBUG
        printf("    kernel(scan_blur): (%d, %d): xBound=%f, right(%d, %d)=%f, left(%d, %d)=%f\n", 
            x, y, x_bound, right_x, current_y, right_value, left_x, current_y, left_value);
        #endif
        

        sum += (right_value - left_value);
    }

    float4 result = sum / (PI*radius*radius);

    #if DEBUG
    printf("kernel(scan_blur): (%d, %d): scan_rows=%f sum=%f result=%f\n---\n", 
        x, y, scan_rows[buf_index(x, y, width)], sum, result);
    #endif

    output[buf_index(x*4, y, width)/4] = result;
    //vstore4(result, buf_index(x*4, y, width), output);
}

kernel void scan_blur(
	global const float *scan_rows,
	global       float *output,
	               int radius,
	               int width,
	               int height
) {
	int x = get_global_id(0);
	int y = get_global_id(1);

	# if DEBUG
	printf("kernel(scan_blur): radius=%d, width=%d, height=%d\n", radius, width, height);
	#endif 

	float sum = 0.0;

	for (int iy = -radius; iy <= radius; iy++) {
        float xBound = sqrt((float)(radius*radius - iy*iy));

        // x coordinates at the left and right edges of the circle
        int leftX = clamp((int)(x - xBound), 0, width - 1);
        int rightX = clamp((int)(x + xBound), 0, width - 1);

        int currentY = clamp(y + iy, 0, height - 1);

        float rightValue = scan_rows[buf_index(rightX, currentY, width)];
        float leftValue = scan_rows[buf_index(leftX, currentY, width)];

        #if DEBUG
        printf("    kernel(scan_blur): (%d, %d): xBound=%f, right(%d, %d)=%f, left(%d, %d)=%f\n", 
        	x, y, xBound, rightX, currentY, rightValue, leftX, currentY, leftValue);
        #endif
        

        sum += (rightValue - leftValue);
    }

    float result = sum / (PI*radius*radius);

    #if DEBUG
    printf("kernel(scan_blur): (%d, %d): scan_rows=%f sum=%f result=%f\n---\n", 
    	x, y, scan_rows[buf_index(x, y, width)], sum, result);
    #endif

    output[buf_index(x, y, width)] = result;
}