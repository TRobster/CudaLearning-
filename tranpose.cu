#include <iostream>
#include <random>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>
#include "benchmark.cu"

// Square in nature, assume 32 x 32 
#define TILE_DIM 32

// Individual chunks pulled into the 
#define BLOCK_ROWS 8

// Dummy matrix dimensions
static int square = 512 * 512;

using namespace std; 
using ul = unsigned long; 

__global__ void copy(float *in, float *out)
{
    int row = TILE_DIM * blockIdx.x + threadIdx.x;
    int col = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM; 

    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        out[((col+j) * width) + row] = in[((col+j) * width) + row];
    }

}

__global__ void transposeNaive(float *in, float *out)
{
    int x = TILE_DIM * blockIdx.x + threadIdx.x;
    int y = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM; 
    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        out[(x * width) + (y+j)] = in[((y + j) * width) +  x];
    }

}

__global__ void transposeCoalesced(float *in, float *out)
{
    __shared__ TILEBLOCK[TILE_DIM][TILE_DIM];
    int x = TILE_DIM * blockIdx.x + threadIdx.x;
    int y = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM;
    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        TILEBLOCK[threadIdx.y + j][threadIdx.x]  = in[((y + j) * width) +  x];
    }
    __syncthreads();

    int tilex=

}

int main()
{

    // 1. Declare and create the events
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // sanity check 
    float compare = (float) ((square * ((square - 1)) / 2));


    // Host memory allocating 
    float *u_old, *u_new; 
    u_old = (float*)malloc(sizeof(float) * square);
    u_new= (float*)malloc(sizeof(float) * square);


    for (int i = 0; i < square; i++)
    {
        u_old[i] = (float)i; 
    }
    cout << "edge element is (before tpose) " << u_old[511] << endl; 

    // Device memory allocating
    float *d_u_old, *d_u_new;

    // use &, we're passing in the address of the value, void** doesn't excempt bad memory access techniques 
    ul tSize = (ul) (sizeof(float) * square) ; 
    cudaMalloc((void**)&d_u_old, tSize);
    cudaMalloc((void**)&d_u_new, tSize);


    // Pull data from host -> device
    cudaMemcpy(d_u_old, u_old, tSize, cudaMemcpyHostToDevice);

    // Needed threads, running copy function 

    dim3 block(TILE_DIM, BLOCK_ROWS);
    // squareable 
    size_t grid_sz = sqrt(square) / TILE_DIM; 
    dim3 gridDim(grid_sz, grid_sz); 

    cudaEventRecord(start);
    transposeNaive<<<gridDim, block>>>(d_u_old, d_u_new);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    cout << "Kernel Execution Time: " << milliseconds << " ms\n";

    cudaMemcpy(u_new, d_u_new, tSize, cudaMemcpyDeviceToHost); 
    
    
    // verify and check 
    //if (compare == sum)
    //{
    cout << "edge element is (tpose worked) " << u_new[511] << endl; 
    //}

    // host
    free(u_old);
    free(u_new); 

    // device
    cudaFree(d_u_old);
    cudaFree(d_u_new);

    // timing 
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}