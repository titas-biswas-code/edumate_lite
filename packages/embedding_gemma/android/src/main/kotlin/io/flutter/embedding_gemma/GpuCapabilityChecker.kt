package io.flutter.embedding_gemma

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import java.io.File

/**
 * Check GPU/OpenCL capability before attempting GPU initialization
 */
object GpuCapabilityChecker {
    private const val TAG = "GpuCapabilityChecker"

    /**
     * Check if GPU acceleration is safe to use on this device
     * 
     * Known issue: Google's GemmaEmbeddingModel crashes on Android 15+
     * due to namespace isolation preventing access to libvndksupport.so
     */
    fun canUseGpu(context: Context): Boolean {
        if (isEmulator()) return false

        // Android 15+ has namespace restrictions that break Google's RAG library GPU
        if (Build.VERSION.SDK_INT >= 35) {
            Log.i(TAG, "Android 15+ detected, using CPU (Google RAG library limitation)")
            return false
        }

        // Check for OpenCL
        if (!hasOpenClLibrary()) {
            return false
        }

        return true
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic")
            || Build.MODEL.contains("Emulator")
            || Build.MODEL.contains("Android SDK built for x86")
            || Build.PRODUCT.contains("sdk")
    }

    private fun hasOpenClLibrary(): Boolean {
        val possiblePaths = listOf(
            "/system/lib64/libOpenCL.so",
            "/system/lib/libOpenCL.so",
            "/vendor/lib64/libOpenCL.so",
            "/vendor/lib/libOpenCL.so",
            "/system/vendor/lib64/libOpenCL.so",
            "/system/vendor/lib/libOpenCL.so",
        )

        return possiblePaths.any { File(it).exists() }
    }
}

