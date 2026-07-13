#include <iostream>
#include <random>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>

#define TILE_DIM 32
#define BLOCK_ROWS 8
static int square = (TILE_DIM * TILE_DIM);


__global__ void copy(float *out, float *in)
{
    int row = TILE_DIM * blockIdx.x + threadIdx.x;
    int col = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM; 

    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        out[((col+j) * width) + row] = in[((col+j) * width) + row];
    }

}

int main()
{

     // Host memory allocating 
    float *u_old;
    u_old = (float*)malloc(sizeof(float) * square);


    for (int i = 0; i < square; i += 2)
    {
        u_old[i] = (float)i; 
    }
    // Device memory allocating
    float *d_u_old, *d_u_new;
    cudaMalloc(d_u_old, sizeof(float) * square);
    cudaMalloc(d_u_new, sizeof(float) * square);

    // Pull data from host -> device
    cudaMemcpy(d_u_old, u_old, sizeof(float) * square, cudaMemcpyHostToDevice);

    // Needed threads
    dim3 block(TILE_DIM, BLOCK_ROWS);
    dim3 gridDim(32, 32); 
    copy<<<gridDim, block>>>(d_u_old, d_u_new);

}