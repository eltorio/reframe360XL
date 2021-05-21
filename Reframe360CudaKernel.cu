/*
* Copyright (c) 2019-2021  Ronan LE MEILLAT, Stefan SIETZEN, Sylvain GRAVEL
* License Apache Software License 2.0
*/
#include "device_launch_parameters.h"
#include "helper_math.h"

#define M_PI	   3.14159265358979323846
#define M_PI_2     1.57079632679489661923   // pi/2
#define M_PI_4     0.785398163397448309616  // pi/4
#define M_1_PI     0.318309886183790671538  // 1/pi
#define M_2_PI     0.636619772367581343076  // 2/pi
#define OVERLAP 64
#define CUT 688
#define BASESIZE 4096 //OVERLAP and CUT are based on this size
#define TRUE	1
#define FALSE	0

enum Faces {
	TOP_LEFT,
	TOP_MIDDLE,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_MIDDLE,
	BOTTOM_RIGHT,
	NB_FACES,
};

enum Direction {
	RIGHT,
	LEFT,
	UP,
	DOWN,
	FRONT,
	BACK,
	NB_DIRECTIONS,
};

enum Rotation {
	ROT_0,
	ROT_90,
	ROT_180,
	ROT_270,
	NB_ROTATIONS,
};

enum INPUT_FORMAT {
	EQUIRECTANGULAR,
	GOPRO_MAX,
	EQUIANGULAR_CUBEMAP,
	NB_INPUT_FORMAT,
};

__device__ float2 rotate_cube_face(float2 uv, int rotation)
{
	float2 ret_uv;

	switch (rotation) {
	case ROT_0:
		ret_uv = uv;
		break;
	case ROT_90:
		ret_uv.x = -uv.y;
		ret_uv.y = uv.x;
		break;
	case ROT_180:
		ret_uv.x = -uv.x;
		ret_uv.y = -uv.y;
		break;
	case ROT_270:
		ret_uv.x = uv.y;
		ret_uv.y = -uv.x;
		break;
	}
	return ret_uv;
}

__device__ float3 equirect_to_xyz(int2 xy, int2 size)
{
	float3 xyz;
	float phi = ((2.f * ((float)xy.x) + 0.5f) / ((float)size.x) - 1.f) * M_PI;
	float theta = ((2.f * ((float)xy.y) + 0.5f) / ((float)size.y) - 1.f) * M_PI_2;

	xyz.x = cos(theta) * sin(phi);
	xyz.y = sin(theta);
	xyz.z = cos(theta) * cos(phi);

	return xyz;
}

__device__ float2 xyz_to_cube(float3 xyz, int* direction, int* face)
{
	float phi = atan2(xyz.x, xyz.z);
	float theta = asin(xyz.y);
	float phi_norm, theta_threshold;
	int face_rotation;
	float2 uv;
	//int direction;

	if (phi >= -M_PI_4 && phi < M_PI_4) {
		*direction = FRONT;
		phi_norm = phi;
	}
	else if (phi >= -(M_PI_2 + M_PI_4) && phi < -M_PI_4) {
		*direction = LEFT;
		phi_norm = phi + M_PI_2;
	}
	else if (phi >= M_PI_4 && phi < M_PI_2 + M_PI_4) {
		*direction = RIGHT;
		phi_norm = phi - M_PI_2;
	}
	else {
		*direction = BACK;
		phi_norm = phi + ((phi > 0.f) ? -M_PI : M_PI);
	}

	theta_threshold = atan(cos(phi_norm));
	if (theta > theta_threshold) {
		*direction = DOWN;
	}
	else if (theta < -theta_threshold) {
		*direction = UP;
	}

	theta_threshold = atan(cos(phi_norm));
	if (theta > theta_threshold) {
		*direction = DOWN;
	}
	else if (theta < -theta_threshold) {
		*direction = UP;
	}

	switch (*direction) {
	case RIGHT:
		uv.x = -xyz.z / xyz.x;
		uv.y = xyz.y / xyz.x;
		*face = TOP_RIGHT;
		face_rotation = ROT_0;
		break;
	case LEFT:
		uv.x = -xyz.z / xyz.x;
		uv.y = -xyz.y / xyz.x;
		*face = TOP_LEFT;
		face_rotation = ROT_0;
		break;
	case UP:
		uv.x = -xyz.x / xyz.y;
		uv.y = -xyz.z / xyz.y;
		*face = BOTTOM_RIGHT;
		face_rotation = ROT_270;
		uv = rotate_cube_face(uv, face_rotation);
		break;
	case DOWN:
		uv.x = xyz.x / xyz.y;
		uv.y = -xyz.z / xyz.y;
		*face = BOTTOM_LEFT;
		face_rotation = ROT_270;
		uv = rotate_cube_face(uv, face_rotation);
		break;
	case FRONT:
		uv.x = xyz.x / xyz.z;
		uv.y = xyz.y / xyz.z;
		*face = TOP_MIDDLE;
		face_rotation = ROT_0;
		break;
	case BACK:
		uv.x = xyz.x / xyz.z;
		uv.y = -xyz.y / xyz.z;
		*face = BOTTOM_MIDDLE;
		face_rotation = ROT_90;
		uv = rotate_cube_face(uv, face_rotation);
		break;
	}

	return uv;
}

__device__ float2 xyz_to_eac(float3 xyz, int2 size)
{
	float pixel_pad = 2;
	float u_pad = pixel_pad / size.x;
	float v_pad = pixel_pad / size.y;

	int direction, face;
	int u_face, v_face;
	float2 uv = xyz_to_cube(xyz, &direction, &face);

	u_face = face % 3;
	v_face = face / 3;
	//eac expansion
	uv.x = M_2_PI * atan(uv.x) + 0.5f;
	uv.y = M_2_PI * atan(uv.y) + 0.5f;

	uv.x = (uv.x + u_face) * (1.f - 2.f * u_pad) / 3.f + u_pad;
	uv.y = uv.y * (0.5f - 2.f * v_pad) + v_pad + 0.5f * v_face;

	uv.x *= size.x;
	uv.y *= size.y;

	return uv;
}


__device__ int2 transpose_gopromax_overlap(int2 xy, int2 dim)
{
	int2 ret;
	int cut = dim.x * CUT / BASESIZE;
	int overlap = dim.x * OVERLAP / BASESIZE;
	if (xy.x < cut)
	{
		ret = xy;
	}
	else if ((xy.x >= cut) && (xy.x < (dim.x - cut)))
	{
		ret.x = xy.x + overlap;
		ret.y = xy.y;
	}
	else
	{
		ret.x = xy.x + 2 * overlap;
		ret.y = xy.y;
	}
	return ret;
}

__device__ float3 matMul(const float3 r012, const float3 r345, const float3 r678, float3 v){
	float3 outvec = { 0, 0, 0 };
	outvec.x = r012.x * v.x + r012.y * v.y + r012.z * v.z;
	outvec.y = r345.x * v.x + r345.y * v.y + r345.z * v.z;
	outvec.z = r678.x * v.x + r678.y * v.y + r678.z * v.z;
	return outvec;
}

__device__ float2 repairUv(float2 uv){
	float2 outuv;

	if(uv.x<0) {
		outuv.x = 1.0 + uv.x;
		}else if(uv.x > 1.0){
			outuv.x = uv.x -1.0;
		} else {
			outuv.x = uv.x;
		}

		if(uv.y<0) {
			outuv.y = 1.0 + uv.y;
		} else if(uv.y > 1.0){
			outuv.y = uv.y -1.0;
		} else {
			outuv.y = uv.y;
		}

	outuv.x = min(max(outuv.x, 0.0), 1.0);
	outuv.y = min(max(outuv.y, 0.0), 1.0);

	return outuv;
}

__device__ float2 polarCoord(float3 dir) {	
	float3 ndir = normalize(dir);
	float longi = -atan2(ndir.z, ndir.x);
	
	float lat = acos(-ndir.y);
	
	float2 uv;
	uv.x = longi;
	uv.y = lat;
	
	float2 M_PItwo = {M_PI, M_PI};
	uv /= M_PItwo;
	uv.x /= 2.0;
	float2 ones = {1.0, 1.0};
	uv = fmodf(uv, ones);
	return uv;
}


__device__ float3 fisheyeDir(float3 dir, const float3 r012, const float3 r345, const float3 r678) {

	if (dir.x == 0 && dir.y == 0)
		return matMul(r012, r345, r678, dir);
		
	dir.x = dir.x / dir.z;
	dir.y = dir.y / dir.z;
	dir.z = 1;
	
	float2 uv;
	uv.x = dir.x;
	uv.y = dir.y;
	float r = sqrtf(uv.x*uv.x + uv.y*uv.y);
	
	float phi = atan2f(uv.y, uv.x);
	
	float theta = r;
	
	float3 fedir = { 0, 0, 0 };
	fedir.x = sin(theta) * cos(phi);
	fedir.y = sin(theta) * sin(phi);
	fedir.z = cos(theta);

	fedir = matMul(r012, r345, r678, fedir);
	
	return fedir;
}

__device__ float3 tinyPlanetSph(float3 uv) {
	if (uv.x == 0 && uv.y == 0)
		return uv;

    float3 sph;
	float2 uvxy;
	uvxy.x = uv.x/uv.z;
	uvxy.y = uv.y/uv.z;

	float u  =length(uvxy);
	float alpha = atan2(2.0f, u);
	float phi = M_PI - 2*alpha;
	float z = cos(phi);
	float x = sin(phi);
	
	uvxy = normalize(uvxy);
	
	sph.z = z;
	
	float2 sphxy = uvxy * x;

	sph.x = sphxy.x;
	sph.y = sphxy.y;
	
	return sph;
}

__device__ float4 linInterpCol(float2 uv, const float* input, int width, int height){
	float4 outCol = {0,0,0,0};
	float i = floorf(uv.x);
	float j = floorf(uv.y);
	float a = uv.x-i;
	float b = uv.y-j;
	int x = (int)i;
	int y = (int)j;
	int x1 = (x < width - 1 ? x + 1 : x);
	int y1 = (y < height - 1 ? y + 1 : y);
	const int indexX1Y1 = ((y * width) + x) * 4;
	const int indexX2Y1 = ((y * width) + x1) * 4;
	const int indexX1Y2 = (((y1) * width) + x) * 4;
	const int indexX2Y2 = (((y1) * width) + x1) * 4;
	const int maxIndex = (width * height -1) * 4;
	
	if(indexX2Y2 < maxIndex){
		outCol.x = (1.0 - a)*(1.0 - b)*input[indexX1Y1] + a*(1.0 - b)*input[indexX2Y1] + (1.0 - a)*b*input[indexX1Y2] + a*b*input[indexX2Y2];
		outCol.y = (1.0 - a)*(1.0 - b)*input[indexX1Y1 + 1] + a*(1.0 - b)*input[indexX2Y1 + 1] + (1.0 - a)*b*input[indexX1Y2 + 1] + a*b*input[indexX2Y2 + 1];
		outCol.z = (1.0 - a)*(1.0 - b)*input[indexX1Y1 + 2] + a*(1.0 - b)*input[indexX2Y1 + 2] + (1.0 - a)*b*input[indexX1Y2 + 2] + a*b*input[indexX2Y2 + 2];
		outCol.w = (1.0 - a)*(1.0 - b)*input[indexX1Y1 + 3] + a*(1.0 - b)*input[indexX2Y1 + 3] + (1.0 - a)*b*input[indexX1Y2 + 3] + a*b*input[indexX2Y2 + 3];
	} else {
		outCol.x = input[indexX1Y1];
		outCol.y = input[indexX1Y1+ 1];
		outCol.z = input[indexX1Y1+ 2];
		outCol.w = input[indexX1Y1+ 3];
	}
	return outCol;
}

__device__ float2 get_original_coordinates(const float2 equirect_coordinates, int2 size, int transpose)
{
	int2 loc = { (int)equirect_coordinates.x, (int)equirect_coordinates.y };
	int2 eac_size = { size.x - 2 * (size.x * OVERLAP / BASESIZE),size.y };
	float3 xyz = equirect_to_xyz(loc, size);
	float2 uv = xyz_to_eac(xyz, eac_size);
	int2 xy;
	xy.x = roundf(uv.x);
	xy.y = roundf(uv.y);
	if (transpose>0)
	{
		xy = transpose_gopromax_overlap(xy, eac_size);
	}
	xy.y = size.y - (xy.y + 1);
	float2 ret = { (float)xy.x, (float)xy.y } ;
	return ret;
}

__device__ float2 get_original_gopromax_coordinates(const float2 equirect_coordinates, int2 size)
{
	return get_original_coordinates(equirect_coordinates, size, TRUE);
}

__global__ void Reframe360CudaKernel(int p_InputFormat, int p_Width, int p_Height, float* p_Fov, float* p_Tinyplanet, float* p_Rectilinear,
								const float* p_Input, float* p_Output, const float* r, int samples, bool bilinear)
{
   const int x = blockIdx.x * blockDim.x + threadIdx.x;
   const int y = blockIdx.y * blockDim.y + threadIdx.y;

   if ((x < p_Width) && (y < p_Height))
   {
		const int index = ((y * p_Width) + x) * 4;

		float4 accum_col = {0, 0, 0, 0};

        float2 uv = { (float)x / p_Width, (float)y / p_Height };
        float aspect = (float)p_Width / (float)p_Height;
           
		for(int i=0; i<samples; i++){
			float fov = p_Fov[i];

		   float3 dir = { 0, 0, 0 };
		   dir.x = (uv.x * 2) - 1;
		   dir.y = (uv.y * 2) - 1;
		   dir.y /= aspect;
		   dir.z = fov;

		   float3 tinyplanet = tinyPlanetSph(dir);
		   tinyplanet = normalize(tinyplanet);

		   const float3 r012 = {r[i*9+0], r[i*9+1], r[i*9+2]};
		   const float3 r345 = {r[i*9+3], r[i*9+4], r[i*9+5]};
		   const float3 r678 = {r[i*9+6], r[i*9+7], r[i*9+8]};

		   tinyplanet = matMul(r012, r345, r678, tinyplanet);
		   float3 rectdir = matMul(r012, r345, r678, dir);

		   rectdir = normalize(rectdir);
		   dir = lerp(fisheyeDir(dir, r012, r345, r678), tinyplanet, p_Tinyplanet[i]);
		   dir = lerp(dir, rectdir, p_Rectilinear[i]);

		   float2 iuv = polarCoord(dir);
		   iuv = repairUv(iuv);

		   iuv.x *= (p_Width - 1);
		   iuv.y *= (p_Height - 1);
		   //get original coordinates

		   switch (p_InputFormat) {
		   case GOPRO_MAX:
			   iuv = get_original_gopromax_coordinates(iuv, { p_Width, p_Height });
			   break;
		   case EQUIANGULAR_CUBEMAP:
			   iuv = get_original_coordinates(iuv, { p_Width, p_Height }, FALSE);
			   break;
		   case EQUIRECTANGULAR:
			   break;
		   }

		   int x_new = iuv.x;
		   int y_new = iuv.y;

		   if ((x_new < p_Width) && (y_new < p_Height))
		   {
			   const int index_new = ((y_new * p_Width) + x_new) * 4;
			   
			   float4 interpCol;

			   if (bilinear){
				   interpCol = linInterpCol(iuv, p_Input, p_Width, p_Height);
			   }
			   else
			   {
				   interpCol = { p_Input[index_new + 0], p_Input[index_new + 1], p_Input[index_new + 2], p_Input[index_new + 3] };
			   }

			   accum_col.x += interpCol.x;
			   accum_col.y += interpCol.y;
			   accum_col.z += interpCol.z;
			   accum_col.w += interpCol.w;

			}
		}
		p_Output[index + 0] = accum_col.x / samples;
		p_Output[index + 1] = accum_col.y / samples;
		p_Output[index + 2] = accum_col.z / samples;
		p_Output[index + 3] = accum_col.w / samples;
   }
}


void RunCudaKernel(void* p_Stream, int p_inputFormat, int p_Width, int p_Height, float* p_Fov, float* p_Tinyplanet, float* p_Rectilinear, const float* p_Input, float* p_Output, const float* p_RotMat, int p_Samples, bool p_Bilinear)
{
	
    dim3 threads(128, 1, 1);
    dim3 blocks(((p_Width + threads.x - 1) / threads.x), p_Height, 1);
	cudaStream_t stream = static_cast<cudaStream_t>(p_Stream);

	float* dev_rmat;
	cudaMalloc((void**)&dev_rmat, sizeof(float)*9*p_Samples);
	cudaMemcpy((void*)dev_rmat, (void*)p_RotMat, sizeof(float)*9*p_Samples, cudaMemcpyHostToDevice);

	float* dev_fov;
	cudaMalloc((void**)&dev_fov, sizeof(float)*p_Samples);
	cudaMemcpy((void*)dev_fov, (void*)p_Fov, sizeof(float)*p_Samples, cudaMemcpyHostToDevice);

	float* dev_tinyplanet;
	cudaMalloc((void**)&dev_tinyplanet, sizeof(float)*p_Samples);
	cudaMemcpy((void*)dev_tinyplanet, (void*)p_Tinyplanet, sizeof(float)*p_Samples, cudaMemcpyHostToDevice);
	
	float* dev_rectilinear;
	cudaMalloc((void**)&dev_rectilinear, sizeof(float)*p_Samples);
	cudaMemcpy((void*)dev_rectilinear, (void*)p_Rectilinear, sizeof(float)*p_Samples, cudaMemcpyHostToDevice);


    Reframe360CudaKernel <<<blocks, threads, 0, stream >>> (p_inputFormat, p_Width, p_Height, dev_fov, dev_tinyplanet, dev_rectilinear,p_Input, p_Output, dev_rmat, p_Samples, p_Bilinear);


	cudaFree( dev_rmat );
	cudaFree( dev_fov );
	cudaFree( dev_tinyplanet );
	cudaFree( dev_rectilinear );

}
