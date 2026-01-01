package io.nekohasekai.sagernet.ui

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.text.util.Linkify
import android.view.View
import android.widget.Toast
import androidx.activity.result.component1
import androidx.activity.result.component2
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import androidx.core.view.ViewCompat
import androidx.recyclerview.widget.RecyclerView
import com.danielstone.materialaboutlibrary.MaterialAboutFragment
import com.danielstone.materialaboutlibrary.items.MaterialAboutActionItem
import com.danielstone.materialaboutlibrary.model.MaterialAboutCard
import com.danielstone.materialaboutlibrary.model.MaterialAboutList
import io.nekohasekai.sagernet.BuildConfig
import io.nekohasekai.sagernet.R
import io.nekohasekai.sagernet.databinding.LayoutAboutBinding
import io.nekohasekai.sagernet.ktx.*
import io.nekohasekai.sagernet.plugin.PluginManager.loadString
import io.nekohasekai.sagernet.utils.PackageCache
import io.nekohasekai.sagernet.widget.ListListener
import libcore.Libcore
import moe.matsuri.nb4a.plugin.Plugins
import androidx.core.net.toUri
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import io.nekohasekai.sagernet.SagerNet
import io.nekohasekai.sagernet.database.DataStore
import moe.matsuri.nb4a.utils.Util
import org.json.JSONObject
import java.io.File

class AboutFragment : ToolbarFragment(R.layout.layout_about) {

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val binding = LayoutAboutBinding.bind(view)

        ViewCompat.setOnApplyWindowInsetsListener(view, ListListener)
        toolbar.setTitle(R.string.menu_about)

        parentFragmentManager.beginTransaction()
            .replace(R.id.about_fragment_holder, AboutContent())
            .commitAllowingStateLoss()

        runOnDefaultDispatcher {
            val license = view.context.assets.open("LICENSE").bufferedReader().readText()
            onMainDispatcher {
                binding.license.text = license
                Linkify.addLinks(binding.license, Linkify.EMAIL_ADDRESSES or Linkify.WEB_URLS)
            }
        }
    }

    class AboutContent : MaterialAboutFragment() {

        val requestIgnoreBatteryOptimizations = registerForActivityResult(
            ActivityResultContracts.StartActivityForResult()
        ) { (resultCode, _) ->
            if (resultCode == Activity.RESULT_OK) {
                parentFragmentManager.beginTransaction()
                    .replace(R.id.about_fragment_holder, AboutContent())
                    .commitAllowingStateLoss()
            }
        }

        override fun getMaterialAboutList(activityContext: Context): MaterialAboutList {
            return MaterialAboutList.Builder()
                .addCard(
                    MaterialAboutCard.Builder()
                        .outline(false)
                        .addItem(
                            MaterialAboutActionItem.Builder()
                                .icon(R.drawable.ic_baseline_update_24)
                                .text(R.string.app_version)
                                .subText(SagerNet.appVersionNameForDisplay)
                                .setOnClickAction {
                                    requireContext().launchCustomTab(
                                        "https://github.com/moneyfly004/myapk/releases"
                                    )
                                }
                                .build())
                        .addItem(
                            MaterialAboutActionItem.Builder()
                                .text(R.string.check_update_release)
                                .setOnClickAction {
                                    checkUpdate(false)
                                }
                                .build())
                        .addItem(
                            MaterialAboutActionItem.Builder()
                                .icon(R.drawable.ic_baseline_layers_24)
                                .text(getString(R.string.version_x, "sing-box"))
                                .subText(Libcore.versionBox())
                                .setOnClickAction { }
                                .build())
                        .apply {
                            PackageCache.awaitLoadSync()
                            for ((_, pkg) in PackageCache.installedPluginPackages) {
                                try {
                                    val pluginId =
                                        pkg.providers?.get(0)?.loadString(Plugins.METADATA_KEY_ID)
                                    if (pluginId.isNullOrBlank()) continue
                                    addItem(
                                        MaterialAboutActionItem.Builder()
                                            .icon(R.drawable.ic_baseline_nfc_24)
                                            .text(
                                                getString(
                                                    R.string.version_x,
                                                    pluginId
                                                ) + " (${Plugins.displayExeProvider(pkg.packageName)})"
                                            )
                                            .subText("v" + pkg.versionName)
                                            .setOnClickAction {
                                                startActivity(Intent().apply {
                                                    action =
                                                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                                    data = Uri.fromParts(
                                                        "package", pkg.packageName, null
                                                    )
                                                })
                                            }
                                            .build())
                                } catch (e: Exception) {
                                    Logs.w(e)
                                }
                            }
                        }
                        .apply {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val pm = app.getSystemService(Context.POWER_SERVICE) as PowerManager
                                if (!pm.isIgnoringBatteryOptimizations(app.packageName)) {
                                    addItem(
                                        MaterialAboutActionItem.Builder()
                                            .icon(R.drawable.ic_baseline_running_with_errors_24)
                                            .text(R.string.ignore_battery_optimizations)
                                            .subText(R.string.ignore_battery_optimizations_sum)
                                            .setOnClickAction {
                                                requestIgnoreBatteryOptimizations.launch(
                                                    Intent(
                                                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                                        "package:${app.packageName}".toUri()
                                                    )
                                                )
                                            }
                                            .build())
                                }
                            }
                        }
                        .build())
                .addCard(
                    MaterialAboutCard.Builder()
                        .outline(false)
                        .title(R.string.project)
                        .addItem(
                            MaterialAboutActionItem.Builder()
                                .icon(R.drawable.ic_baseline_sanitizer_24)
                                .text(R.string.github)
                                .setOnClickAction {
                                    requireContext().launchCustomTab(
                                        "https://github.com/moneyfly004/myapk"
                                    )
                                }
                                .build())
                        .build())
                .build()

        }

        override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
            super.onViewCreated(view, savedInstanceState)

            view.findViewById<RecyclerView>(R.id.mal_recyclerview).apply {
                overScrollMode = RecyclerView.OVER_SCROLL_NEVER
            }
        }

        fun checkUpdate(checkPreview: Boolean) {
            runOnIoDispatcher {
                try {
                    val client = Libcore.newHttpClient().apply {
                        modernTLS()
                        trySocks5(DataStore.mixedPort)
                    }
                    val response = client.newRequest().apply {
                        setURL("https://api.github.com/repos/moneyfly004/myapk/releases/latest")
                    }.execute()
                    val release = JSONObject(Util.getStringBox(response.contentString))
                    val releaseName = release.getString("name")
                    val releaseTag = release.getString("tag_name")
                    val releaseUrl = release.getString("html_url")
                    
                    // 获取当前版本号（去掉可能的预览后缀）
                    val currentVersion = SagerNet.appVersionNameForDisplay.replace(" pre-.*".toRegex(), "")
                    val latestVersion = releaseTag.replace("^v".toRegex(), "").replace(" pre-.*".toRegex(), "")
                    
                    val haveUpdate = latestVersion != currentVersion
                    
                    runOnMainDispatcher {
                        if (haveUpdate) {
                            val context = requireContext()
                            MaterialAlertDialogBuilder(context)
                                .setTitle(R.string.update_dialog_title)
                                .setMessage(
                                    context.getString(
                                        R.string.update_dialog_message,
                                        SagerNet.appVersionNameForDisplay,
                                        releaseName
                                    )
                                )
                                .setPositiveButton("下载并安装") { _, _ ->
                                    downloadAndInstall(release)
                                }
                                .setNeutralButton("查看详情") { _, _ ->
                                    val intent = Intent(Intent.ACTION_VIEW, releaseUrl.toUri())
                                    context.startActivity(intent)
                                }
                                .setNegativeButton(R.string.no, null)
                                .show()
                        } else {
                            Toast.makeText(app, R.string.check_update_no, Toast.LENGTH_SHORT).show()
                        }
                    }
                } catch (e: Exception) {
                    Logs.w(e)
                    runOnMainDispatcher {
                        Toast.makeText(app, e.readableMessage, Toast.LENGTH_SHORT).show()
                    }
                }
            }
        }
        
        private fun downloadAndInstall(release: JSONObject) {
            runOnIoDispatcher {
                try {
                    val context = requireContext()
                    val client = Libcore.newHttpClient().apply {
                        modernTLS()
                        trySocks5(DataStore.mixedPort)
                    }
                    
                    // 获取 APK 文件
                    val assets = release.getJSONArray("assets")
                    val apkAsset = (0 until assets.length())
                        .map { assets.getJSONObject(it) }
                        .find { it.getString("name").endsWith(".apk") }
                        ?: throw Exception("未找到 APK 文件")
                    
                    val downloadUrl = apkAsset.getString("browser_download_url")
                    val fileName = apkAsset.getString("name")
                    
                    // 创建下载目录
                    val downloadDir = File(context.getExternalFilesDir(null), "updates")
                    downloadDir.mkdirs()
                    val apkFile = File(downloadDir, fileName)
                    
                    // 下载 APK
                    runOnMainDispatcher {
                        Toast.makeText(context, "开始下载更新...", Toast.LENGTH_SHORT).show()
                    }
                    
                    val response = client.newRequest().apply {
                        setURL(downloadUrl)
                    }.execute()
                    
                    response.writeTo(apkFile.canonicalPath)
                    client.close()
                    
                    // 安装 APK
                    runOnMainDispatcher {
                        installApk(apkFile)
                    }
                } catch (e: Exception) {
                    Logs.w(e)
                    runOnMainDispatcher {
                        Toast.makeText(app, "下载失败: ${e.readableMessage}", Toast.LENGTH_LONG).show()
                    }
                }
            }
        }
        
        private fun installApk(apkFile: File) {
            try {
                val context = requireContext()
                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    FileProvider.getUriForFile(
                        context,
                        BuildConfig.APPLICATION_ID + ".cache",
                        apkFile
                    )
                } else {
                    Uri.fromFile(apkFile)
                }
                
                val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                    setDataAndType(uri, "application/vnd.android.package-archive")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    }
                    putExtra(Intent.EXTRA_NOT_UNKNOWN_SOURCE, true)
                }
                
                startActivity(intent)
            } catch (e: Exception) {
                Logs.w(e)
                Toast.makeText(app, "安装失败: ${e.readableMessage}", Toast.LENGTH_LONG).show()
            }
        }

    }

}