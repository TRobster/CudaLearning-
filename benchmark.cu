// cuda_bench.cuh (fully AI generated boilerplace benchmark code) 
//
// Standalone CUDA kernel benchmarking utility.
// Include this in your own .cu file with:
//     #include "cuda_bench.cuh" 
//
// Usage:
//     auto launch_copy = [&]() { copy<<<gridDim, block>>>(d_in, d_out); };
//     BenchResult r = benchmarkKernel(launch_copy);
//     r.print("copy", bytes_moved);
//
// This file intentionally contains ONLY benchmarking machinery —
// no kernel logic, no problem-specific launch configs, no application code.

#pragma once

#include <cuda_runtime.h>
#include <functional>
#include <iostream>
#include <string>

struct BenchResult
{
    float avg_ms;     // average time per single kernel launch, in milliseconds
    int   timed_runs;

    double bandwidthGBs(size_t bytes_moved_per_launch) const
    {
        double seconds = avg_ms / 1000.0;
        return (double)bytes_moved_per_launch / 1e9 / seconds;
    }

    void print(const std::string &label, size_t bytes_moved_per_launch) const
    {
        std::cout << label
                   << ": " << avg_ms << " ms/launch"
                   << ", " << bandwidthGBs(bytes_moved_per_launch) << " GB/s"
                   << " (avg over " << timed_runs << " runs)\n";
    }
};

// Runs `launch` warmup_runs times (untimed, absorbs first-launch overhead),
// then timed_runs times (timed as one batch, averaged).
//
// `launch` must be a no-argument callable — wrap your kernel launch in a
// lambda, e.g. [&]() { myKernel<<<grid, block>>>(args...); }
inline BenchResult benchmarkKernel(std::function<void()> launch,
                                    int warmup_runs = 5,
                                    int timed_runs  = 20)
{
    for (int i = 0; i < warmup_runs; i++) launch();
    cudaDeviceSynchronize();

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < timed_runs; i++) launch();
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float total_ms = 0.0f;
    cudaEventElapsedTime(&total_ms, start, stop);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return BenchResult{ total_ms / timed_runs, timed_runs };
}
