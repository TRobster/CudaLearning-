#include <iostream>
#include <random>
#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>


#define TILE_DIM 32
#define BLOCK_ROWS 8
static int square = (TILE_DIM * TILE_DIM);

using namespace std; 
using ul = unsigned long; 

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

__global__ void transposeNaive(float *out, float *in)
{
    int x = TILE_DIM * blockIdx.x + threadIdx.x;
    int y = TILE_DIM * blockIdx.y + threadIdx.y;
    int width = gridDim.x * TILE_DIM; 
    for (int j = 0; j < TILE_DIM; j += BLOCK_ROWS)
    {
        out[(x * width) + (y+j)] = in[(y + j) * (width * x)];
    }

}

int main()
{

    // 1. Declare and create the events
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // 2. Record the start event
    cudaEventRecord(start);

    // sanity check 
    float compare = (float) ((square * ((square - 1)) / 2));


    // Host memory allocating 
    float *u_old, *u_new; 
    u_old = (float*)malloc(sizeof(float) * square);
    u_new= (float*)malloc(sizeof(float) * square);


    for (int i = 0; i < square; i += 2)
    {
        u_old[i] = (float)i; 
    }
    // Device memory allocating
    float *d_u_old, *d_u_new;

    // use &, we're passing in the address of the value, void** doesn't excempt bad memory access techniques 

    cudaMalloc((void**)&d_u_old, sizeof(float) * square);
    cudaMalloc((void**)&d_u_new, sizeof(float) * square);
    ul tSize = (ul) (sizeof(float) * square) ; 

    // Pull data from host -> device
    cudaMemcpy(d_u_old, u_old, tSize, cudaMemcpyHostToDevice);

    // Needed threads, running copy function 
    dim3 block(TILE_DIM, BLOCK_ROWS);
    dim3 gridDim(32, 32); 
    copy<<<gridDim, block>>>(d_u_old, d_u_new);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    cout << "Kernel Execution Time: " << milliseconds << " ms\n";

    cudaMemcpy(u_new, d_u_new, tSize, cudaMemcpyDeviceToHost); 

    float sum = 0;
    for (int i = 0; i < square; i++)
    {
        sum += (float) i;
    }   

    // verify and check 
    if (count == sum)
    {
       cout << "sum of square is " << sum << endl; 
    }

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