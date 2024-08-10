const char *KernelSource = "\n" \
"/*\n" \
"* Copyright (c) 2019-2024  Ronan LE MEILLAT, Stefan SIETZEN, Sylvain GRAVEL\n" \
"* License Apache Software License 2.0\n" \
"*/\n" \
"#define OVERLAP 64\n" \
"#define CUT 688\n" \
"#define BASESIZE 4096 // OVERLAP and CUT are based on this size\n" \
"\n" \
"enum Faces {\n" \
"TOP_LEFT,\n" \
"TOP_MIDDLE,\n" \
"TOP_RIGHT,\n" \
"BOTTOM_LEFT,\n" \
"BOTTOM_MIDDLE,\n" \
"BOTTOM_RIGHT,\n" \
"NB_FACES,\n" \
"};\n" \
"\n" \
"enum Direction {\n" \
"RIGHT,\n" \
"LEFT,\n" \
"UP,\n" \
"DOWN,\n" \
"FRONT,\n" \
"BACK,\n" \
"NB_DIRECTIONS,\n" \
"};\n" \
"\n" \
"enum Rotation {\n" \
"ROT_0,\n" \
"ROT_90,\n" \
"ROT_180,\n" \
"ROT_270,\n" \
"NB_ROTATIONS,\n" \
"};\n" \
"\n" \
"enum INPUT_FORMAT {\n" \
"EQUIRECTANGULAR,\n" \
"GOPRO_MAX,\n" \
"EQUIANGULAR_CUBEMAP,\n" \
"NB_INPUT_FORMAT,\n" \
"};\n" \
"\n" \
"float2 rotate_cube_face(float2 uv, int rotation);\n" \
"int2 transpose_gopromax_overlap(int2 xy, int2 dim);\n" \
"float3 equirect_to_xyz(int2 xy, int2 size);\n" \
"float2 xyz_to_cube(float3 xyz, int *direction, int *face);\n" \
"float2 xyz_to_eac(float3 xyz, int2 size);\n" \
"\n" \
"float2 rotate_cube_face(float2 uv, int rotation) {\n" \
"float2 ret_uv;\n" \
"\n" \
"switch (rotation) {\n" \
"case ROT_0:\n" \
"ret_uv = uv;\n" \
"break;\n" \
"case ROT_90:\n" \
"ret_uv.x = -uv.y;\n" \
"ret_uv.y = uv.x;\n" \
"break;\n" \
"case ROT_180:\n" \
"ret_uv.x = -uv.x;\n" \
"ret_uv.y = -uv.y;\n" \
"break;\n" \
"case ROT_270:\n" \
"ret_uv.x = uv.y;\n" \
"ret_uv.y = -uv.x;\n" \
"break;\n" \
"}\n" \
"return ret_uv;\n" \
"}\n" \
"\n" \
"float3 equirect_to_xyz(int2 xy, int2 size) {\n" \
"float3 xyz;\n" \
"float phi = ((2.f * ((float)xy.x) + 0.5f) / ((float)size.x) - 1.f) * M_PI_F;\n" \
"float theta =\n" \
"((2.f * ((float)xy.y) + 0.5f) / ((float)size.y) - 1.f) * M_PI_2_F;\n" \
"\n" \
"xyz.x = cos(theta) * sin(phi);\n" \
"xyz.y = sin(theta);\n" \
"xyz.z = cos(theta) * cos(phi);\n" \
"\n" \
"return xyz;\n" \
"}\n" \
"\n" \
"float2 xyz_to_cube(float3 xyz, int *direction, int *face) {\n" \
"float phi = atan2(xyz.x, xyz.z);\n" \
"float theta = asin(xyz.y);\n" \
"float phi_norm, theta_threshold;\n" \
"int face_rotation;\n" \
"float2 uv;\n" \
"// int direction;\n" \
"\n" \
"if (phi >= -M_PI_4_F && phi < M_PI_4_F) {\n" \
"*direction = FRONT;\n" \
"phi_norm = phi;\n" \
"} else if (phi >= -(M_PI_2_F + M_PI_4_F) && phi < -M_PI_4_F) {\n" \
"*direction = LEFT;\n" \
"phi_norm = phi + M_PI_2_F;\n" \
"} else if (phi >= M_PI_4_F && phi < M_PI_2_F + M_PI_4_F) {\n" \
"*direction = RIGHT;\n" \
"phi_norm = phi - M_PI_2_F;\n" \
"} else {\n" \
"*direction = BACK;\n" \
"phi_norm = phi + ((phi > 0.f) ? -M_PI_F : M_PI_F);\n" \
"}\n" \
"\n" \
"theta_threshold = atan(cos(phi_norm));\n" \
"if (theta > theta_threshold) {\n" \
"*direction = DOWN;\n" \
"} else if (theta < -theta_threshold) {\n" \
"*direction = UP;\n" \
"}\n" \
"\n" \
"theta_threshold = atan(cos(phi_norm));\n" \
"if (theta > theta_threshold) {\n" \
"*direction = DOWN;\n" \
"} else if (theta < -theta_threshold) {\n" \
"*direction = UP;\n" \
"}\n" \
"\n" \
"switch (*direction) {\n" \
"case RIGHT:\n" \
"uv.x = -xyz.z / xyz.x;\n" \
"uv.y = xyz.y / xyz.x;\n" \
"*face = TOP_RIGHT;\n" \
"face_rotation = ROT_0;\n" \
"break;\n" \
"case LEFT:\n" \
"uv.x = -xyz.z / xyz.x;\n" \
"uv.y = -xyz.y / xyz.x;\n" \
"*face = TOP_LEFT;\n" \
"face_rotation = ROT_0;\n" \
"break;\n" \
"case UP:\n" \
"uv.x = -xyz.x / xyz.y;\n" \
"uv.y = -xyz.z / xyz.y;\n" \
"*face = BOTTOM_RIGHT;\n" \
"face_rotation = ROT_270;\n" \
"uv = rotate_cube_face(uv, face_rotation);\n" \
"break;\n" \
"case DOWN:\n" \
"uv.x = xyz.x / xyz.y;\n" \
"uv.y = -xyz.z / xyz.y;\n" \
"*face = BOTTOM_LEFT;\n" \
"face_rotation = ROT_270;\n" \
"uv = rotate_cube_face(uv, face_rotation);\n" \
"break;\n" \
"case FRONT:\n" \
"uv.x = xyz.x / xyz.z;\n" \
"uv.y = xyz.y / xyz.z;\n" \
"*face = TOP_MIDDLE;\n" \
"face_rotation = ROT_0;\n" \
"break;\n" \
"case BACK:\n" \
"uv.x = xyz.x / xyz.z;\n" \
"uv.y = -xyz.y / xyz.z;\n" \
"*face = BOTTOM_MIDDLE;\n" \
"face_rotation = ROT_90;\n" \
"uv = rotate_cube_face(uv, face_rotation);\n" \
"break;\n" \
"}\n" \
"\n" \
"return uv;\n" \
"}\n" \
"\n" \
"float2 xyz_to_eac(float3 xyz, int2 size) {\n" \
"float pixel_pad = 2;\n" \
"float u_pad = pixel_pad / size.x;\n" \
"float v_pad = pixel_pad / size.y;\n" \
"\n" \
"int direction, face;\n" \
"int u_face, v_face;\n" \
"float2 uv = xyz_to_cube(xyz, &direction, &face);\n" \
"\n" \
"u_face = face % 3;\n" \
"v_face = face / 3;\n" \
"// eac expansion\n" \
"uv.x = M_2_PI_F * atan(uv.x) + 0.5f;\n" \
"uv.y = M_2_PI_F * atan(uv.y) + 0.5f;\n" \
"\n" \
"uv.x = (uv.x + u_face) * (1.f - 2.f * u_pad) / 3.f + u_pad;\n" \
"uv.y = uv.y * (0.5f - 2.f * v_pad) + v_pad + 0.5f * v_face;\n" \
"\n" \
"uv.x *= size.x;\n" \
"uv.y *= size.y;\n" \
"\n" \
"return uv;\n" \
"}\n" \
"\n" \
"int2 transpose_gopromax_overlap(int2 xy, int2 dim) {\n" \
"int2 ret;\n" \
"int cut = dim.x * CUT / BASESIZE;\n" \
"int overlap = dim.x * OVERLAP / BASESIZE;\n" \
"if (xy.x < cut) {\n" \
"ret = xy;\n" \
"} else if ((xy.x >= cut) && (xy.x < (dim.x - cut))) {\n" \
"ret.x = xy.x + overlap;\n" \
"ret.y = xy.y;\n" \
"} else {\n" \
"ret.x = xy.x + 2 * overlap;\n" \
"ret.y = xy.y;\n" \
"}\n" \
"return ret;\n" \
"}\n" \
"\n" \
"float3 matMul(float16 rotMat, float3 invec) {\n" \
"float3 outvec;\n" \
"outvec.x = dot(rotMat.s012, invec);\n" \
"outvec.y = dot(rotMat.s345, invec);\n" \
"outvec.z = dot(rotMat.s678, invec);\n" \
"return outvec;\n" \
"}\n" \
"\n" \
"float2 repairUv(float2 uv) {\n" \
"float2 outuv = {0, 0};\n" \
"\n" \
"if (uv.x < 0) {\n" \
"outuv.x = 1.0 + uv.x;\n" \
"} else if (uv.x > 1.0) {\n" \
"outuv.x = uv.x - 1.0;\n" \
"} else {\n" \
"outuv.x = uv.x;\n" \
"}\n" \
"\n" \
"if (uv.y < 0) {\n" \
"outuv.y = 1.0 + uv.y;\n" \
"} else if (uv.y > 1.0) {\n" \
"outuv.y = uv.y - 1.0;\n" \
"} else {\n" \
"outuv.y = uv.y;\n" \
"}\n" \
"\n" \
"outuv.x = min(max(outuv.x, 0.0f), 1.0f);\n" \
"outuv.y = min(max(outuv.y, 0.0f), 1.0f);\n" \
"\n" \
"return outuv;\n" \
"}\n" \
"\n" \
"float2 polarCoord(float3 dir) {\n" \
"float3 ndir = normalize(dir);\n" \
"float longi = -atan2(ndir.z, ndir.x);\n" \
"\n" \
"float lat = acos(-ndir.y);\n" \
"\n" \
"float2 uv;\n" \
"uv.x = longi;\n" \
"uv.y = lat;\n" \
"\n" \
"float2 pitwo = {M_PI_F, M_PI_F};\n" \
"uv /= pitwo;\n" \
"uv.x /= 2.0;\n" \
"float2 ones = {1.0, 1.0};\n" \
"uv = fmod(uv, ones);\n" \
"return uv;\n" \
"}\n" \
"\n" \
"float3 fisheyeDir(float3 dir, float16 rotMat) {\n" \
"if (dir.x == 0 && dir.y == 0)\n" \
"return matMul(rotMat, dir);\n" \
"\n" \
"dir.x = dir.x / dir.z;\n" \
"dir.y = dir.y / dir.z;\n" \
"dir.z = dir.z / dir.z;\n" \
"\n" \
"float2 uv;\n" \
"uv.x = dir.x;\n" \
"uv.y = dir.y;\n" \
"float r = sqrt(uv.x * uv.x + uv.y * uv.y);\n" \
"\n" \
"float phi = atan2(uv.y, uv.x);\n" \
"\n" \
"float theta = r;\n" \
"\n" \
"float3 fedir = {0, 0, 0};\n" \
"fedir.x = sin(theta) * cos(phi);\n" \
"fedir.y = sin(theta) * sin(phi);\n" \
"fedir.z = cos(theta);\n" \
"\n" \
"fedir = matMul(rotMat, fedir);\n" \
"\n" \
"return fedir;\n" \
"}\n" \
"\n" \
"float3 tinyPlanetSph(float3 uv) {\n" \
"if (uv.x == 0 && uv.y == 0)\n" \
"return uv;\n" \
"\n" \
"float3 sph;\n" \
"float2 uvxy;\n" \
"uvxy.x = uv.x / uv.z;\n" \
"uvxy.y = uv.y / uv.z;\n" \
"\n" \
"float u = length(uvxy);\n" \
"float alpha = atan2(2.0f, u);\n" \
"float phi = M_PI_F - 2 * alpha;\n" \
"float z = cos(phi);\n" \
"float x = sin(phi);\n" \
"\n" \
"uvxy = normalize(uvxy);\n" \
"\n" \
"sph.z = z;\n" \
"\n" \
"float2 sphxy;\n" \
"sphxy.x = uvxy.x * x;\n" \
"sphxy.y = uvxy.y * x;\n" \
"\n" \
"sph.x = sphxy.x;\n" \
"sph.y = sphxy.y;\n" \
"\n" \
"return sph;\n" \
"}\n" \
"\n" \
"float4 linInterpCol(float2 uv, __global const float *input, int width,\n" \
"int height) {\n" \
"float4 outCol;\n" \
"float i = floor(uv.x);\n" \
"float j = floor(uv.y);\n" \
"float a = uv.x - i;\n" \
"float b = uv.y - j;\n" \
"int x = (int)i;\n" \
"int y = (int)j;\n" \
"int x1 = (x < width - 1 ? x + 1 : x);\n" \
"int y1 = (y < height - 1 ? y + 1 : y);\n" \
"const int indexX1Y1 = ((y * width) + x) * 4;\n" \
"const int indexX2Y1 = ((y * width) + x1) * 4;\n" \
"const int indexX1Y2 = (((y1)*width) + x) * 4;\n" \
"const int indexX2Y2 = (((y1)*width) + x1) * 4;\n" \
"const int maxIndex = (width * height - 1) * 4;\n" \
"\n" \
"if (indexX2Y2 < maxIndex) {\n" \
"outCol.x = (1.0 - a) * (1.0 - b) * input[indexX1Y1] +\n" \
"a * (1.0 - b) * input[indexX2Y1] +\n" \
"(1.0 - a) * b * input[indexX1Y2] + a * b * input[indexX2Y2];\n" \
"outCol.y = (1.0 - a) * (1.0 - b) * input[indexX1Y1 + 1] +\n" \
"a * (1.0 - b) * input[indexX2Y1 + 1] +\n" \
"(1.0 - a) * b * input[indexX1Y2 + 1] +\n" \
"a * b * input[indexX2Y2 + 1];\n" \
"outCol.z = (1.0 - a) * (1.0 - b) * input[indexX1Y1 + 2] +\n" \
"a * (1.0 - b) * input[indexX2Y1 + 2] +\n" \
"(1.0 - a) * b * input[indexX1Y2 + 2] +\n" \
"a * b * input[indexX2Y2 + 2];\n" \
"outCol.w = (1.0 - a) * (1.0 - b) * input[indexX1Y1 + 3] +\n" \
"a * (1.0 - b) * input[indexX2Y1 + 3] +\n" \
"(1.0 - a) * b * input[indexX1Y2 + 3] +\n" \
"a * b * input[indexX2Y2 + 3];\n" \
"} else {\n" \
"outCol.x = input[indexX1Y1];\n" \
"outCol.y = input[indexX1Y1 + 1];\n" \
"outCol.z = input[indexX1Y1 + 2];\n" \
"outCol.w = input[indexX1Y1 + 3];\n" \
"}\n" \
"return outCol;\n" \
"}\n" \
"\n" \
"float2 get_original_coordinates(const float2 equirect_coordinates, int2 size,\n" \
"bool transpose) {\n" \
"int2 loc = {(int)equirect_coordinates.x, (int)equirect_coordinates.y};\n" \
"int2 eac_size = {size.x - 2 * (size.x * OVERLAP / BASESIZE), size.y};\n" \
"float3 xyz = equirect_to_xyz(loc, size);\n" \
"float2 uv = xyz_to_eac(xyz, eac_size);\n" \
"int2 xy = convert_int2(floor(uv));\n" \
"if (transpose) {\n" \
"xy = transpose_gopromax_overlap(xy, eac_size);\n" \
"}\n" \
"xy.y = size.y - (xy.y + 1);\n" \
"return (float2){(float)xy.x, (float)xy.y};\n" \
"}\n" \
"\n" \
"float2 get_original_gopromax_coordinates(const float2 equirect_coordinates,\n" \
"int2 size) {\n" \
"return get_original_coordinates(equirect_coordinates, size, true);\n" \
"}\n" \
"\n" \
"__kernel void Reframe360Kernel(int p_InputFormat, int p_Width, int p_Height,\n" \
"__global float *p_Fov,\n" \
"__global float *p_Tinyplanet,\n" \
"__global float *p_Rectilinear,\n" \
"__global const float *p_Input,\n" \
"__global float *p_Output, __global float *r,\n" \
"int samples, int bilinear) {\n" \
"const int x = get_global_id(0);\n" \
"const int y = get_global_id(1);\n" \
"const int2 size = {p_Width, p_Height};\n" \
"\n" \
"if ((x < p_Width) && (y < p_Height)) {\n" \
"const int index = ((y * p_Width) + x) * 4;\n" \
"\n" \
"float4 accum_col = {0, 0, 0, 0};\n" \
"\n" \
"float2 uv = {(float)x / p_Width, (float)y / p_Height};\n" \
"switch (p_InputFormat) {\n" \
"case GOPRO_MAX:\n" \
"case EQUIANGULAR_CUBEMAP:\n" \
"// flip y\n" \
"uv.y = 1.0 - uv.y;\n" \
"break;\n" \
"case EQUIRECTANGULAR:\n" \
"break;\n" \
"}\n" \
"float aspect = (float)p_Width / (float)p_Height;\n" \
"\n" \
"for (int i = 0; i < samples; i++) {\n" \
"\n" \
"float fov = p_Fov[i];\n" \
"\n" \
"float3 dir = {0, 0, 0};\n" \
"dir.x = (uv.x - 0.5) * 2.0;\n" \
"dir.y = (uv.y - 0.5) * 2.0;\n" \
"dir.y /= aspect;\n" \
"dir.z = fov;\n" \
"\n" \
"float3 tinyplanet = tinyPlanetSph(dir);\n" \
"tinyplanet = normalize(tinyplanet);\n" \
"\n" \
"float16 rotMat = {r[i * 9 + 0],\n" \
"r[i * 9 + 1],\n" \
"r[i * 9 + 2],\n" \
"r[i * 9 + 3],\n" \
"r[i * 9 + 4],\n" \
"r[i * 9 + 5],\n" \
"r[i * 9 + 6],\n" \
"r[i * 9 + 7],\n" \
"r[i * 9 + 8],\n" \
"0,\n" \
"0,\n" \
"0,\n" \
"0,\n" \
"0,\n" \
"0,\n" \
"0};\n" \
"\n" \
"tinyplanet = matMul(rotMat, tinyplanet);\n" \
"float3 rectdir = matMul(rotMat, dir);\n" \
"\n" \
"rectdir = normalize(rectdir);\n" \
"\n" \
"dir = mix(fisheyeDir(dir, rotMat), tinyplanet, p_Tinyplanet[i]);\n" \
"dir = mix(dir, rectdir, p_Rectilinear[i]);\n" \
"\n" \
"float2 iuv = polarCoord(dir);\n" \
"\n" \
"iuv = repairUv(iuv);\n" \
"\n" \
"iuv.x *= (p_Width - 1);\n" \
"iuv.y *= (p_Height - 1);\n" \
"\n" \
"// get original coordinates\n" \
"switch (p_InputFormat) {\n" \
"case GOPRO_MAX:\n" \
"iuv = get_original_gopromax_coordinates(iuv, size);\n" \
"break;\n" \
"case EQUIANGULAR_CUBEMAP:\n" \
"iuv = get_original_coordinates(iuv, size, false);\n" \
"break;\n" \
"case EQUIRECTANGULAR:\n" \
"break;\n" \
"}\n" \
"\n" \
"int x_new = iuv.x;\n" \
"int y_new = iuv.y;\n" \
"\n" \
"if ((x_new < p_Width) && (y_new < p_Height)) {\n" \
"const int index_new = ((y_new * p_Width) + x_new) * 4;\n" \
"\n" \
"float4 interpCol;\n" \
"if (bilinear) {\n" \
"interpCol = linInterpCol(iuv, p_Input, p_Width, p_Height);\n" \
"} else {\n" \
"interpCol = (float4)(p_Input[index_new + 0], p_Input[index_new + 1],\n" \
"p_Input[index_new + 2], p_Input[index_new + 3]);\n" \
"}\n" \
"\n" \
"accum_col.x += interpCol.x;\n" \
"accum_col.y += interpCol.y;\n" \
"accum_col.z += interpCol.z;\n" \
"accum_col.w += interpCol.w;\n" \
"}\n" \
"}\n" \
"p_Output[index + 0] = accum_col.x / samples;\n" \
"p_Output[index + 1] = accum_col.y / samples;\n" \
"p_Output[index + 2] = accum_col.z / samples;\n" \
"p_Output[index + 3] = accum_col.w / samples;\n" \
"}\n" \
"}\n" \
"\n";
