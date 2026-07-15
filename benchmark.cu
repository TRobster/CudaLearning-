#include <functional>

// Runs `launch` warmup_runs times (untimed), then timed_runs times (timed),
// returns average milliseconds per launch.
float benchmarkKernel(std::function<void()> launch, int warmup_runs = 5, int timed_runs = 20)
{
    // Warmup — absorbs first-launch overhead, not representative of steady state
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

    return total_ms / timed_runs;   // avg ms for ONE launch
}

// bytes_moved = total bytes read + written by one kernel launch
double computeBandwidthGBs(size_t bytes_moved, float avg_ms)
{
    double seconds = avg_ms / 1000.0;
    return (double)bytes_moved / 1e9 / seconds;
}