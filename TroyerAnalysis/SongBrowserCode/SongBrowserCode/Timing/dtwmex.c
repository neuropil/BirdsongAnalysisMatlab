/*
 *  dtwmex.c
 *  Core of dynamic programming/DTW calculation
 *  [warp,range,Dcum] = dtwmex(M,mlim,boundary)
 *
 * Adapted from:
 * 2003-04-02 dpwe@ee.columbia.edu
 * $Header: /Users/dpwe/projects/dtw/RCS/dpcore.c,v 1.3 2006/01/18 20:05:51 dpwe Exp $
% Copyright (c) 2003-05 Dan Ellis <dpwe@ee.columbia.edu>
% released under GPL - see file COPYRIGHT
 */
 
#include    <stdio.h>
#include    <math.h>
#include    <ctype.h>
#include    "mex.h"

/* #define DEBUG */

#define INF HUGE_VAL

void
mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int 	i,j;

#ifdef DEBUG
    mexPrintf("dpcore: Got %d lhs args and %d rhs args.\n", 
	      nlhs, nrhs); 
    for (i=0;i<nrhs;i++) {
	mexPrintf("RHArg #%d is size %d x %d\n", 
		  (long)i, mxGetM(prhs[i]), mxGetN(prhs[i]));
    }
    for (i=0;i<nlhs;i++)
	if (plhs[i]) {
	    mexPrintf("LHArg #%d is size %d x %d\n", 
		      (long)i, mxGetM(plhs[i]), mxGetN(plhs[i]));
	}
#endif /* DEBUG */

    if (nlhs > 0){
        mxArray  *warpMatrix, *rangeMatrix, *DcumMatrix, *moveMatrix; /* output matrices */
        double *pwarp, *prange, *pDcum, *pmove; /* pointers to output data */
        double *pM,  *boundary; /* pointers to input data */
        int rows, cols, bdlim, mlim, mlimpos, mlimneg; /* sizes */
        int imin, imax, itrace, jtrace, tmpmove, ind, indtype; /* counters etc */
        double wt1, wt2; /* wt1 for (1,1) move=sqrt(2);  wt2 for (1,2) and (2,1) move = sqrt(5); */
        double d, d2, d3,minval; /* internal variables */

    /************** preliminaries ************/
        wt1 = sqrt(2); /* length of move (1,1) */
        wt2 = sqrt(5); /* length of moves (1,2)  and (2,1) */

            /* Get inputs and sizes */
        rows = mxGetM(prhs[0]);
        cols = mxGetN(prhs[0]);
        pM = mxGetPr(prhs[0]);

        mlim = *mxGetPr(prhs[1]);

        boundary = mxGetPr(prhs[2]);
        bdlim = mxGetM(prhs[2]);
        if (mxGetN(prhs[2])>bdlim) {bdlim = mxGetN(prhs[2]);}

        /* set outputs */
        warpMatrix = mxCreateDoubleMatrix(1, cols, mxREAL);
        pwarp = mxGetPr(warpMatrix);
        plhs[0] = warpMatrix;

        rangeMatrix = mxCreateDoubleMatrix(2, 2, mxREAL);
        prange = mxGetPr(rangeMatrix);
        if (nlhs > 1) {
            plhs[1] = rangeMatrix;
        }

        DcumMatrix = mxCreateDoubleMatrix(rows, cols, mxREAL);
        pDcum = mxGetPr(DcumMatrix);
        if (nlhs > 2) {
            plhs[2] = DcumMatrix;
        }

        moveMatrix = mxCreateDoubleMatrix(rows, cols, mxREAL);
        pmove = mxGetPr(moveMatrix);
        if (nlhs > 3) {
            plhs[3] = moveMatrix;
        }

    /************** calculate cumulative distance matrix Dcum ************/
        /* set limits for search */
        if (rows>=cols){
            mlimpos = mlim;
            mlimneg = mlim+rows-cols;
        }
        if (rows<cols){
            mlimpos = mlim+cols-rows;
            mlimneg = mlim;
        }

        /* initialize boundaries */
        for (i = 0; i<bdlim; ++i){
            pDcum[i] = boundary[i]+wt1*pM[i];
            pDcum[i*rows] = boundary[i]+wt1*pM[i*rows];
        }

        /* set infinite boundaries if needed */
        if (mlimpos>bdlim){
            for (i = bdlim; i< mlimpos; ++i){
            pDcum[i] = INF+wt1*pM[i];
            }
        }
        if (mlimneg>bdlim){
            for (i = bdlim; i< mlimneg; ++i){
            pDcum[i*rows] = INF+wt1*pM[i*rows];
            }
        }
#ifdef DEBUG
       mexPrintf("rows: %d, cols: %d, bdlim: %d, mlim: %d, mlimpos: %d, mlimneg: %d \n",rows,cols,bdlim,mlim,mlimpos,mlimneg);
#endif /* DEBUG */

        /* first column past boundary can't have move (1,2) */
        j=1;
        imin = 1;
        imax = j+mlimpos-1;
        if (imax>rows-1){imax = rows-1;}
        /* first entry can only use diagonal move because of boundary */
        pDcum[imin+rows*j] = pDcum[(imin-1)+rows*(j-1)]+wt1*pM[imin+rows*j];
        pmove[imin+rows*j] = 1;

        /* other rows */
        for (i = imin+1; i <= imax; ++i) {
            tmpmove = 1;
            d = pDcum[(i-1)+rows*(j-1)]+wt1*pM[i+rows*j];
            d3 =  pDcum[(i-2)+rows*(j-1)]+
                  wt2*(.5*pM[i+rows*j]+.25*pM[(i-1)+rows*(j-1)]+.25*pM[(i-1)+rows*j]);
            if (d3<d){ d = d3; tmpmove = 3; }
            pDcum[i+rows*j] = d;
            pmove[i+rows*j] = tmpmove;
        }

    /* now do other columns */
        for (j = 2; j < cols; ++j) {
            /* set limits on which rows to calculate for in this column */
            imin = j-mlimneg+1;
            if (imin<1){imin=1;}
                imax = j+mlimpos-1;
            if (imax>rows-1){imax = rows-1;}

            /* 2nd row from bottom can't have move (2,1)  */
            tmpmove = 1;
            d = pDcum[(imin-1)+rows*(j-1)]+wt1*pM[imin+rows*j];
            d2 =  pDcum[(imin-1)+rows*(j-2)]+
                  wt2*(.5*pM[imin+rows*j]+.25*pM[(imin-1)+rows*(j-1)]+.25*pM[imin+rows*(j-1)]);
            if (d2<d){ d = d2; tmpmove = 2; }
            pDcum[imin+rows*j] = d;
            pmove[imin+rows*j] = tmpmove;

            /* calculate for middle rows */
            for (i = imin+1; i <= imax; ++i) {
                tmpmove = 1;
                d = pDcum[(i-1)+rows*(j-1)]+wt1*pM[i+rows*j];
                d2 =  pDcum[(i-1)+rows*(j-2)]+
                    wt2*(.5*pM[i+rows*j]+.25*pM[(i-1)+rows*(j-1)]+.25*pM[i+rows*(j-1)]);
                if (d2<d){ d = d2; tmpmove = 2; }
                d3 =  pDcum[(i-2)+rows*(j-1)]+
                    wt2*(.5*pM[i+rows*j]+.25*pM[(i-1)+rows*(j-1)]+.25*pM[(i-1)+rows*j]);
                if (d3<d){ d = d3; tmpmove = 3; }
                pDcum[i+rows*j] = d;
                pmove[i+rows*j] = tmpmove;
            }
            /* top row can't have move (1,2) */
            tmpmove = 1;
            d = pDcum[(imax-1)+rows*(j-1)]+wt1*pM[imax +rows*j];
            d3 =  pDcum[(imax-2)+rows*(j-1)]+
                  wt2*(.5*pM[imax +rows*j]+.25*pM[(imax-1)+rows*(j-1)]+.25*pM[(imax-1)+rows*j]);
            if (d3<d){ d = d3; tmpmove = 3;  }
            pDcum[imax+rows*j] = d;
            pmove[imax+rows*j] = tmpmove;
        }

    /************** find max at boundary ************/
        /* initialize at corner */
        ind = 0;
        indtype = 0; /* 0 = min is along last row; 1 = min is along last col */
        minval = boundary[0]+pDcum[(rows-1)+rows*(cols-1)];
        /* search along edge row and edge col */
        for (i = 1; i<bdlim; ++i){
            if (minval> boundary[i]+pDcum[(rows-1)+rows*(cols-1-i)]){
                minval = boundary[i]+pDcum[(rows-1)+rows*(cols-1-i)];
                ind = i;
                indtype = 0;
            }
            if (minval> boundary[i]+pDcum[(rows-1-i)+rows*(cols-1)]){
                minval = boundary[i]+pDcum[(rows-1-i)+rows*(cols-1)];
                ind = i;
                indtype = 1;
            }
        }
        if (indtype==0){
            itrace = rows-1;
            jtrace = cols-1-ind;
        }
        if (indtype==1){
            itrace = rows-1-ind;
            jtrace = cols-1;
        }

    /************** trace back to find warping path ************/
        prange[1] = jtrace+1; /* +1 included to convert C to matlab indexing */
        prange[3] = itrace+1; /* +1 included to convert C to matlab indexing */
        pwarp[jtrace] = itrace+1; /* +1 included to convert C to matlab indexing */
        while (itrace>0 & jtrace>0){
            tmpmove = pmove[itrace+rows*jtrace];
             switch ( tmpmove ){
                case 1 :
                    itrace = itrace-1;
                    jtrace = jtrace-1;
                    pwarp[jtrace] = itrace+1;
                    break;
                case 2 :
                    itrace = itrace-1;
                    jtrace = jtrace-2;
                    pwarp[jtrace] = itrace+1;
                    pwarp[jtrace+1] = itrace+1.5;
                    break;
                case 3 :
                    itrace = itrace-2;
                    jtrace = jtrace-1;
                    pwarp[jtrace] = itrace+1;
                    break;
                default:
                    if (tmpmove==1){mexPrintf("tmpmove==1\n");}
                    mexPrintf("Improper move %d, (%d,%d)\n", tmpmove,itrace,jtrace);
                    break;
            }
        }
        prange[0] = jtrace+1; /* +1 included to convert C to matlab indexing */
        prange[2] = itrace+1; /* +1 included to convert C to matlab indexing */
    } /* if nrhs>0 */
#ifdef DEBUG
    mexPrintf("dpcore: returning...\n");
#endif /* DEBUG */
}

