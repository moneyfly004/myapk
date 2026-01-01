package io.nekohasekai.sagernet.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
// import moe.matsuri.nb4a.utils.SendLog  // 已禁用自动分享日志功能

class BlankActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 已禁用自动分享日志功能，避免崩溃时自动触发分享
        // process crash log
        // intent?.getStringExtra("sendLog")?.apply {
        //     SendLog.sendLog(this@BlankActivity, this)
        // }

        finish()
    }

}