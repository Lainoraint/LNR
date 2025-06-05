# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Suppress warnings
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options