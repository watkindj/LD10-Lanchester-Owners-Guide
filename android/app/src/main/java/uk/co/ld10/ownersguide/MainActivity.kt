
package uk.co.ld10.ownersguide

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageView
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import android.content.res.ColorStateList
import java.io.BufferedInputStream
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.ZipInputStream
import java.util.concurrent.Executors

class MainActivity : Activity() {

    private val green = Color.rgb(18, 56, 33)
    private val cream = Color.rgb(246, 235, 202)

    private lateinit var webView: WebView
    private lateinit var statusText: TextView
    private lateinit var buttonPanel: LinearLayout
    private lateinit var backButton: Button

    private val worker = Executors.newSingleThreadExecutor()

    private val siteRoot: File
        get() = File(filesDir, "LD10Website")

    private val packageBase =
        "https://raw.githubusercontent.com/watkindj/" +
        "LD10-Lanchester-Owners-Guide/LD10-Android/WebsitePackages/"

    private data class Section(
        val title: String,
        val path: String
    )

    private val sections = listOf(
        Section("Maintenance", "index_5.htm"),
        Section("Technical Information", "index_6.htm"),
        Section("Interior & Exterior", "trim/ntrim.htm"),
        Section("Spares", "docs/spares.htm"),
        Section("Owners' Cars", "docs/cars.htm"),
        Section("Photographs", "photos/photos.htm"),
        Section("Contact", "docs/contact.htm")
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.statusBarColor = green
        window.navigationBarColor = green

        buildScreen()
        showHome()
    }

    private fun buildScreen() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(cream)
            setPadding(20, 18, 20, 12)
        }


val brand = ImageView(this).apply {
    setImageResource(R.drawable.ld10logo_cream)
    scaleType = ImageView.ScaleType.FIT_CENTER
    adjustViewBounds = true
}

val logo = ImageView(this).apply {
    setImageResource(R.drawable.ld10script_cream)
    scaleType = ImageView.ScaleType.FIT_CENTER
    adjustViewBounds = true
}

val brandingPanel = LinearLayout(this).apply {
    orientation = LinearLayout.VERTICAL
    setBackgroundColor(green)
    val padding = (12 * resources.displayMetrics.density).toInt()
    setPadding(padding, padding, padding, padding)
    gravity = android.view.Gravity.CENTER
}

brandingPanel.addView(
    brand,
    LinearLayout.LayoutParams(
        (230 * resources.displayMetrics.density).toInt(),
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply {
        gravity = android.view.Gravity.CENTER
    }
)

brandingPanel.addView(
    logo,
    LinearLayout.LayoutParams(
        (145 * resources.displayMetrics.density).toInt(),
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply {
        gravity = android.view.Gravity.CENTER
    }
)

        val heading = TextView(this).apply {
            text = "Briggs and Barker Owner's Guide"
            textSize = 19f
            setTextColor(green)
            gravity = android.view.Gravity.CENTER
        }

        val strapline = TextView(this).apply {
            text = "History · Engineering · Preservation"
            textSize = 14f
            setTextColor(green)
            gravity = android.view.Gravity.CENTER
        }

        statusText = TextView(this).apply {
            text = "Welcome to the Lanchester LD10 guide"
            textSize = 13f
            setTextColor(green)
            gravity = android.view.Gravity.CENTER
            setPadding(0, 12, 0, 12)
        }

        backButton = Button(this).apply {
            text = "Back to Sections"
            setTextColor(cream)
            backgroundTintList = ColorStateList.valueOf(green)
            visibility = View.GONE
            setOnClickListener { showHome() }
        }

        buttonPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        sections.forEach { section ->
            val button = Button(this).apply {
                text = section.title
                textSize = 15f
                setTextColor(cream)
                backgroundTintList = ColorStateList.valueOf(green)
                setOnClickListener {
                    loadSection(section)
                }
            }

            buttonPanel.addView(
                button,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    bottomMargin = 5
                }
            )
        }

        webView = WebView(this).apply {
            visibility = View.GONE
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = true

            webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(
                    view: WebView,
                    request: android.webkit.WebResourceRequest
                ): Boolean {
                    val uri = request.url

                    if (uri.scheme != "file") return false

                    val target = try {
                        File(uri.path ?: return false).canonicalFile
                    } catch (_: Exception) {
                        return false
                    }

                    val rootPath = siteRoot.canonicalPath +
                        File.separator

                    if (!target.path.startsWith(rootPath)) {
                        return false
                    }

                    if (target.exists()) return false

                    val relative = target.path.removePrefix(rootPath)

                    worker.execute {
                        try {
                            ensurePackagesFor(relative)

                            runOnUiThread {
                                if (target.exists()) {
                                    webView.loadUrl(uri.toString())
                                } else {
                                    statusText.text =
                                        "This page could not be found."
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread {
                                statusText.text =
                                    "Unable to load this page: ${e.message}"
                            }
                        }
                    }

                    return true
                }
            }
        }

root.addView(
    brandingPanel,
    LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply {
        bottomMargin = (12 * resources.displayMetrics.density).toInt()
    }
)
        root.addView(heading)
        root.addView(strapline)
        root.addView(statusText)
        root.addView(backButton)
        root.addView(buttonPanel)

        root.addView(
            webView,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        )

        setContentView(root)
    }

    private fun showHome() {
        webView.stopLoading()
        webView.visibility = View.GONE
        buttonPanel.visibility = View.VISIBLE
        backButton.visibility = View.GONE
        statusText.text = "Welcome to the Lanchester LD10 guide"
    }

    private fun loadSection(section: Section) {
        statusText.text = "Preparing ${section.title}..."

        worker.execute {
            try {
                ensurePackagesFor(section.path)

                val target = safeFile(section.path)

                if (!target.exists()) {
                    throw Exception(
                        "The requested guide page was not found."
                    )
                }

                runOnUiThread {
                    statusText.text = section.title
                    buttonPanel.visibility = View.GONE
                    backButton.visibility = View.VISIBLE
                    webView.visibility = View.VISIBLE
                    webView.loadUrl(Uri.fromFile(target).toString())
                }

            } catch (e: Exception) {
                runOnUiThread {
                    statusText.text = "Unable to open ${section.title}"
                    Toast.makeText(
                        this,
                        e.message ?: "Download failed",
                        Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
    }

    private fun packagesForPath(path: String): List<String> {
        val result = mutableListOf("LD10-Main")

        when {
            path.startsWith("bay/") ->
                result.add("LD10-Bay")

            path.startsWith("controls/") ->
                result.add("LD10-Controls")

            path.startsWith("restore/") ->
                result.add("LD10-Restore")

            path.startsWith("trim/") ->
                result.add("LD10-Trim")

            path.startsWith("photos/") ->
                result.addAll(
                    (1..7).map { "Photos-%02d".format(it) }
                )
        }

        return result
    }

    private fun ensurePackagesFor(path: String) {
        siteRoot.mkdirs()

        packagesForPath(path).forEach { name ->
            installPackage(name)
        }
    }


private fun installPackage(name: String) {
    val isPhotoPackage = name.startsWith("Photos-")

    val markerName = if (isPhotoPackage) {
        ".ld10-$name-installed-v2"
    } else {
        ".ld10-$name-installed"
    }

    val marker = File(filesDir, markerName)

    if (marker.exists()) return

    val zipFile = File(cacheDir, "$name.zip")
    val address = URL("$packageBase$name.zip")

    val connection =
        address.openConnection() as HttpURLConnection

    connection.connectTimeout = 30000
    connection.readTimeout = 60000
    connection.requestMethod = "GET"

    try {
        connection.connect()

        if (connection.responseCode != 200) {
            throw Exception(
                "Download failed for $name: HTTP ${connection.responseCode}"
            )
        }

        connection.inputStream.use { input ->
            FileOutputStream(zipFile).use { output ->
                input.copyTo(output)
            }
        }

        val destination = if (isPhotoPackage) {
            File(siteRoot, "photos")
        } else {
            siteRoot
        }

        unzipPackage(zipFile, destination)
        marker.writeText("installed")

    } finally {
        connection.disconnect()
        zipFile.delete()
    }
}

private fun unzipPackage(zipFile: File, destinationRoot: File) {
    val root = destinationRoot.canonicalFile
    root.mkdirs()

    val rootPath = root.path + File.separator

    ZipInputStream(
        BufferedInputStream(zipFile.inputStream())
    ).use { zip ->

        var entry = zip.nextEntry

        while (entry != null) {
            val destination =
                File(root, entry.name).canonicalFile

            if (
                destination.path != root.path &&
                !destination.path.startsWith(rootPath)
            ) {
                throw Exception("Invalid ZIP entry detected")
            }

            if (entry.isDirectory) {
                destination.mkdirs()
            } else {
                destination.parentFile?.mkdirs()

                FileOutputStream(destination).use { output ->
                    zip.copyTo(output)
                }
            }

            zip.closeEntry()
            entry = zip.nextEntry
        }
    }
}


    private fun safeFile(relativePath: String): File {
        val root = siteRoot.canonicalFile
        val target = File(root, relativePath).canonicalFile

        if (!target.path.startsWith(root.path + File.separator)) {
            throw Exception("Invalid page path")
        }

        return target
    }

    override fun onBackPressed() {
        if (::webView.isInitialized && webView.visibility == View.VISIBLE) {
            if (webView.canGoBack()) {
                webView.goBack()
            } else {
                showHome()
            }
        } else {
            super.onBackPressed()
        }
    }

    override fun onDestroy() {
        if (::webView.isInitialized) {
            webView.destroy()
        }

        worker.shutdown()
        super.onDestroy()
    }
}
