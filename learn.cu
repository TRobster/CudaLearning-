
#include <iostream>
#include <random>
#include <cuda_runtime.h>

using uint = unsigned int; 
__global__ void vectorAD(float* a, float* b, float* c)
{
    int workID = threadIdx.x + blockDim.x * blockIdx.x;

    c[workID] = a[workID] + b[workID];
}

int main ()
{   

    const int N = 512;
    const size_t size = N * sizeof(float);

    // Generate random arrays on host
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dist(-1000.0f, 1000.0f);

    float *A = (float *)malloc(sizeof(float) * N);
    float *B = (float *)malloc(sizeof(float) * N);
    float *C = (float *)malloc(sizeof(float) * N);
    uint i; 
    for (i = 0; i < N; i++){
        A[i] = dist(gen);
    }
    for (i = 0; i < N; i++){
        B[i] = dist(gen);
    }

    float *cA, *cB, *cC;

    cudaMalloc(&cA, size);
    cudaMalloc(&cB, size);
    cudaMalloc(&cC, size);

    


}