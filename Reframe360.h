#pragma once

#include "ofxsImageEffect.h"
#define OVERLAP 64
#define CUT 688
#define BASESIZE 4096 //OVERLAP and CUT are based on this size
#define TRUE 1
#define FALSE 0

#ifdef WIN32
#define M_PI_2     1.57079632679489661923   // pi/2
#define M_PI_4     0.785398163397448309616  // pi/4
#define M_1_PI     0.318309886183790671538  // 1/pi
#define M_2_PI     0.636619772367581343076  // 2/pi
#endif

struct int2 { int x; int y; };
struct float2 { float x; float y; };
struct float3 { float x; float y; float z; };
struct float4 { float x; float y; float z; float w; };

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

class Reframe360Factory : public OFX::PluginFactoryHelper<Reframe360Factory>
{
public:
    Reframe360Factory();
    virtual void load() {}
    virtual void unload() {}
    virtual void describe(OFX::ImageEffectDescriptor& p_Desc);
    virtual void describeInContext(OFX::ImageEffectDescriptor& p_Desc, OFX::ContextEnum p_Context);
    virtual OFX::ImageEffect* createInstance(OfxImageEffectHandle p_Handle, OFX::ContextEnum p_Context);
	std::string paramIdForCam(std::string baseName, int cam);
};

float2 rotate_cube_face(float2 uv, int rotation);
int2 transpose_gopromax_overlap(int2 xy, int2 dim);
float3 equirect_to_xyz(int2 xy,int2 size);
float2 xyz_to_cube(float3 xyz, int *direction, int *face);
float2 xyz_to_eac(float3 xyz, int2 size);
