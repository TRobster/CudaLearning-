#include <iostream>
#include <random>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>
#include <functional>
#include "benchmark.cuh"

// Square in nature, assume 32 x 32 
#define TILE_DIM 32

// Individual chunks pulled into the 
#define BLOCK_ROWS 8

// Dummy matrix dimensions
static int square = 8192 * 8192;

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
    __shared__ float TILEBLOCK[TILE_DIM][TILE_DIM+1];
    int x = TILE_DIM * blockIdx.x + threadIdx.x;
    int y = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM;
    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        TILEBLOCK[threadIdx.y + j][threadIdx.x]  = in[((y + j) * width) +  x];
    }
    __syncthreads();

    // Write 
    x = blockIdx.y * TILE_DIM + threadIdx.x;
    y = blockIdx.x * TILE_DIM + threadIdx.y;

    for (int j = 0; j < TILE_DIM; j+=BLOCK_ROWS) 
    {
        out[((y+j) * width) + x] = TILEBLOCK[threadIdx.x][threadIdx.y + j];
    }

}

__global__ void copyCoalesced(float *in, float *out)
{
     __shared__ float TILEBLOCK[TILE_DIM * TILE_DIM];
    int x = TILE_DIM * blockIdx.x + threadIdx.x;
    int y = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM;
    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        TILEBLOCK[((threadIdx.y + j) * TILE_DIM)+ threadIdx.x]   = in[((y + j) * width) + x];
    }

    __syncthreads();

    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
       out[((y + j) * width) +  x] = TILEBLOCK[((threadIdx.y + j) * TILE_DIM)+ threadIdx.x];
    }

}


int main()
{
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
    //cout << "edge element is (before tpose) " << u_old[511] << endl; 

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

    size_t bytes_moved = 2ull * (size_t)square * sizeof(float);
    auto launch_copy = [&]() { copyCoalesced<<<gridDim, block>>>(d_u_old, d_u_new); };
    BenchResult r = benchmarkKernel(launch_copy);
    r.print("copy upgrade", bytes_moved);
    
    auto launch_tp = [&]() { transposeNaive<<<gridDim, block>>>(d_u_old, d_u_new); };
    BenchResult z = benchmarkKernel(launch_tp);
    z.print("transpose", bytes_moved);

    auto launch_tpC = [&]() { transposeCoalesced<<<gridDim, block>>>(d_u_old, d_u_new); };
    BenchResult x = benchmarkKernel(launch_tpC);
    x.print("transposeCOAL", bytes_moved);

    cudaMemcpy(u_new, d_u_new, tSize, cudaMemcpyDeviceToHost); 
    
    // verify and check 
    //if (compare == sum)
    //{
    //cout << "edge element is (tpose worked) " << u_new[511] << endl; 
    //}

    // host
    free(u_old);
    free(u_new); 

    // device
    cudaFree(d_u_old);
    cudaFree(d_u_new);

}