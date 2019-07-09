/*==========================================================
 * thresholdsHSVfast.c
 *
 *========================================================*/

#include "mex.h"

/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    
    double *I;               /* 1xN input matrix */
    double *T;  /* 1xN input matrix */
    size_t imHeight, imWidth, nChannels; /* size of matrices H, S, V */                 
    mxLogical *L;              /* output matrix */
    double Hmin, Hmax, Smin, Smax, Vmin, Vmax; /* scalar thresholds */
    mwSize n;
    size_t nDimNum;
    const mwSize* pDims;
    
    
    /* check for proper number of arguments */
    if(nrhs!=2) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:nrhs","Two inputs required.");
    }
    if(nlhs!=1) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:nlhs","One output required.");
    }
    
    /* make sure the first input argument is type double */
    if( !mxIsDouble(prhs[0]) ) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:notDouble","Input matrix I must be type double.");
    }
    
    /* make sure the second input argument is type double */
    if( !mxIsDouble(prhs[1]) ) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:notDouble","Input matrix T must be type double.");
    }
    
    
    /* check that number of rows in second input argument is 1 */
    if(mxGetM(prhs[1])!=1) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:notRowVector","Input T must be a row vector.");
    }
    
    nDimNum = mxGetNumberOfDimensions(prhs[0]);
    pDims = mxGetDimensions(prhs[0]);
    
    
    imHeight = pDims[0];
    imWidth = pDims[1];
    nChannels = pDims[2];
        
    if(nChannels != 3) {
        mexErrMsgIdAndTxt("findROI:thresholdsHSVmex:not3Dmatrix","Input I must be a 3D double matrix.");
    }
    

    /* create a pointer to the input matrices  */
    I = mxGetPr(prhs[0]);
    T = mxGetPr(prhs[1]);
        
    Hmin = T[0];
    Hmax = T[1];
    Smin = T[2];
    Smax = T[3];
    Vmin = T[4];
    Vmax = T[5];
    
    // Number of pixels in one layer
    n = (mwSize) (imHeight * imWidth);
    
    /* create the output matrix */
    plhs[0] = mxCreateNumericMatrix(imHeight, imWidth, mxLOGICAL_CLASS, mxREAL);
    L = (mxLogical *) mxGetPr(plhs[0]);
    
    /* The computational routine */
    mwSize i;
    
    if (Hmin > Hmax){
        for (i=0; i<n; i++) {
            L[i] =
                    (Hmin <= I[i] || I[i] <= Hmax) &&
                    (Smin <= I[i+n] && I[i+n] <= Smax) &&
                    (Vmin <= I[i+2*n] && I[i+2*n] <= Vmax);
        }
    }
    else {
        for (i=0; i<n; i++) {
            L[i] =
                    (Hmin <= I[i] && I[i] <= Hmax) &&
                    (Smin <= I[i+n] && I[i+n] <= Smax) &&
                    (Vmin <= I[i+2*n] && I[i+2*n] <= Vmax);
        }
    }
}
