package com.color.paletteasian

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager
import android.view.WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
import android.webkit.WebView

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            FLAG_LAYOUT_NO_LIMITS,
            FLAG_LAYOUT_NO_LIMITS
        )
        
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