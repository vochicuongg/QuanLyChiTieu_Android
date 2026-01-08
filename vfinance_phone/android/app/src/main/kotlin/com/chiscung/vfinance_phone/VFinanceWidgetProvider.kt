package com.chiscung.vfinance_phone

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class VFinanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

internal fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
    // Load data from FlutterSharedPreferences
    val widgetData = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.widget_layout)
    
    val balance = widgetData.getString("flutter.widget_balance", "--- ₫")
    val dailyExpense = widgetData.getString("flutter.widget_daily_expense", "0 ₫")
    val balanceLabel = widgetData.getString("flutter.widget_balance_label", "Current Balance")
    val dailyLabel = widgetData.getString("flutter.widget_daily_label", "Total Daily Expense:")
    
    // Retrieve greeting, default to generic welcome if empty
    val greeting = widgetData.getString("flutter.widget_greeting", "Welcome!")
    
    views.setTextViewText(R.id.tv_balance_label, balanceLabel)
    views.setTextViewText(R.id.tv_balance, balance)
    views.setTextViewText(R.id.tv_daily_label, dailyLabel)
    views.setTextViewText(R.id.tv_daily_value, dailyExpense)
    views.setTextViewText(R.id.tv_greeting, greeting)

    // Open App on Click (Background & Refresh Overlay)
    val intent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
    }
    val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
    views.setOnClickPendingIntent(R.id.btn_refresh, pendingIntent)
    
    // Open App on Click (Daily Expense Info)
    val homeIntent = Intent(context, MainActivity::class.java).apply {
        putExtra("route_action", "home")
        data = android.net.Uri.parse("vfinance://home")
    }
    val homePendingIntent = PendingIntent.getActivity(context, 1, homeIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    views.setOnClickPendingIntent(R.id.btn_open_home, homePendingIntent)

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}
