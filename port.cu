#include <iostream>
#include <random>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>
#include <functional>
#include "benchmark.cuh"

// Square in nature, assume 32 x 32 
#define TILE_DIM 32

static int square = 8192 * 8192;

// Individual chunks pulled into the 
#define BLOCK_ROWS 8

__global__ void transfer(float *x, float *y) 
{
    __shared__ float TILEBLOCK[TILE_DIM][TILE_DIM]; 

    int xID = threadIdx.x + TILE_DIM * blockIdx.x;
    int yID = threadIdx.y + TILE_DIM * blockIdx.y;

    int width = gridDim.x * TILE_DIM;
    
    for (int i = 0; i < (TILE_DIM / 2); i += BLOCK_ROWS)
    {
        TILEBLOCK[threadIdx.y + i][threadIdx.x] = x[((yID + i) * width) + xID];
    }

    __syncthreads(); 
    

}


__global__ void vectorAD(float* a, float* b, float* c)
{
    int workID = threadIdx.x + blockDim.x * blockIdx.x;

    c[workID] = a[workID] + b[workID];
}


int main()
{
    // given n-vectors, 

        // Host memory allocating 
    float *v1, *v2, *c;
    v1 = (float*)malloc(sizeof(float) * square);
    v2 =  (float*)malloc(sizeof(float) * square);
    c =  (float*)malloc(sizeof(float) * square);

    for (int i = 0; i < square; i++)
    {
        v1[i] = (float)i;
        v2[i] = (float)i; 
    }
    
    float *dv1, *dv2, *dc;

    unsigned long sizee = (unsigned long) (sizeof(float) * square) ; 
    cudaMalloc((void**)&dv1, sizee);
    cudaMalloc((void**)&dv2, sizee);
    cudaMalloc((void**)&dc, sizee);

    cudaMemcpy(dv1, v1, sizee, cudaMemcpyHostToDevice);
    cudaMemcpy(dv2, v2, sizee, cudaMemcpyHostToDevice);

    dim3 block(TILE_DIM, BLOCK_ROWS);
    size_t grid_sz = sqrt(square) / TILE_DIM;
    dim3 gridDim(grid_sz, grid_sz); 

    size_t bytes_moved = 2ull * (size_t)square * sizeof(float);
    auto launch_naive = [&]() { vectorAD<<<gridDim, block>>>(dv1, dv2, dc); };
    BenchResult z = benchmarkKernel(launch_naive);
    z.print("naive version", bytes_moved);


    free(v1);
    free(v2);
    free(c);
}