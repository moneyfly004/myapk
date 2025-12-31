package io.nekohasekai.sagernet.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import io.nekohasekai.sagernet.R

/**
 * 订阅信息卡片适配器
 */
class SubscriptionInfoAdapter(
    private val items: List<SubscriptionInfoItem>,
    private val onItemClick: ((SubscriptionInfoItem) -> Unit)? = null
) : RecyclerView.Adapter<SubscriptionInfoAdapter.ViewHolder>() {

    data class SubscriptionInfoItem(
        val icon: Int,
        val text: String,
        val type: String? = null,
        val status: String? = null,
        val showActions: Boolean = false
    )

    class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val icon: ImageView = itemView.findViewById(R.id.info_icon)
        val text: TextView = itemView.findViewById(R.id.info_text)
        val type: TextView = itemView.findViewById(R.id.info_type)
        val status: TextView = itemView.findViewById(R.id.info_status)
        val actions: LinearLayout = itemView.findViewById(R.id.info_actions)
        val btnEdit: ImageButton = itemView.findViewById(R.id.btn_edit)
        val btnShare: ImageButton = itemView.findViewById(R.id.btn_share)
        val btnDelete: ImageButton = itemView.findViewById(R.id.btn_delete)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_subscription_info_card, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = items[position]
        
        holder.icon.setImageResource(item.icon)
        holder.text.text = item.text
        
        if (item.type != null) {
            holder.type.text = item.type
            holder.type.visibility = View.VISIBLE
        } else {
            holder.type.visibility = View.GONE
        }
        
        if (item.status != null) {
            holder.status.text = item.status
            holder.status.visibility = View.VISIBLE
            // 根据状态设置颜色
            when {
                item.status.contains("超时") -> holder.status.setTextColor(0xFFF44336.toInt())
                item.status.contains("ms") -> holder.status.setTextColor(0xFF4CAF50.toInt())
                else -> holder.status.setTextColor(0xFF757575.toInt())
            }
        } else {
            holder.status.visibility = View.GONE
        }
        
        if (item.showActions) {
            holder.actions.visibility = View.VISIBLE
            holder.btnEdit.setOnClickListener { onItemClick?.invoke(item) }
            holder.btnShare.setOnClickListener { onItemClick?.invoke(item) }
            holder.btnDelete.setOnClickListener { onItemClick?.invoke(item) }
        } else {
            holder.actions.visibility = View.GONE
        }
        
        holder.itemView.setOnClickListener {
            onItemClick?.invoke(item)
        }
    }

    override fun getItemCount(): Int = items.size
}
