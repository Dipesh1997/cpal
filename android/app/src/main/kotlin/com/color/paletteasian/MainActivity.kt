package com.color.paletteasian

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import androidx.core.view.WindowCompat
import android.webkit.WebView

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Initialize WebView with the correct context
        try {
            WebView.setWebContentsDebuggingEnabled(false)
            val webView = WebView(this)
            webView.destroy()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}