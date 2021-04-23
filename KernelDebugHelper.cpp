#include <stdio.h>
#include "KernelDebugHelper.h"
void ComputePrintDebugInformations(const char *KenelType, int p_Width, int p_Height, float* p_Fov, float* p_Tinyplanet, float* p_Rectilinear, float* p_RotMat, int p_Samples, bool p_Bilinear)
{
#ifdef DEBUG
    const int numberOfLines = 3;
    const int numberColumns = 3;
    int row, column;
    fprintf(stdout, "%sKernel Working for, W:%d H:%d samples:%d bilinear:%d \n",KenelType, p_Width,p_Height,p_Samples,p_Bilinear);
    for (int run=0;run<p_Samples;run++)
    {
        fprintf(stdout,"\tRun %d\n",run);
        fprintf(stdout, "fov:%2.6f tinyplanet:%2.6f rectilinear:%2.6f \n",p_Fov[run], p_Tinyplanet[run], p_Rectilinear[run] );
        
        fprintf(stdout,"\trotMat[%d]\n",run);
        
        for (row=0; row<numberOfLines; row++)
        {
            fprintf(stdout,"\t         :");
            for(column=0; column<numberColumns; column++)
            {
                printf("%*2.4f     ", 6, p_RotMat[row*numberColumns+column+numberOfLines*numberColumns*run]);
            }
            fprintf(stdout,"\n");
        }
        
    }
#endif
}
