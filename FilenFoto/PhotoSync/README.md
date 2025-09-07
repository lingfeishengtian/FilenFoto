#  PhotoSync Documentation

## Concurrency

Swift fundamentally uses a non-blocking approach to concurrency. This means that the classic producer/consumer model needs to be morphed a little bit to work without blocking threads in order to conform to the Swift concurrency model.
