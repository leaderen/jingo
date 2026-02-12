#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translation script for JinGo VPN
Generates translations for zh_CN, zh_TW, ru_RU, fa_IR, vi_VN, km_KH, my_MM
"""

import xml.etree.ElementTree as ET
import os
import re

# Simplified to Traditional Chinese conversion table
S2T_TABLE = {
    '简': '簡', '体': '體', '语': '語', '设': '設', '备': '備', '网': '網',
    '络': '絡', '连': '連', '断': '斷', '开': '開', '关': '關', '钮': '鈕',
    '务': '務', '器': '器', '载': '載', '录': '錄', '认': '認', '证': '證',
    '码': '碼', '邮': '郵', '箱': '箱', '号': '號', '户': '戶', '订': '訂',
    '阅': '閱', '测': '測', '试': '試', '时': '時', '间': '間', '长': '長',
    '选': '選', '择': '擇', '输': '輸', '入': '入', '请': '請', '错': '錯',
    '误': '誤', '确': '確', '认': '認', '取': '取', '消': '消', '保': '保',
    '存': '存', '删': '刪', '编': '編', '辑': '輯', '复': '復', '制': '製',
    '粘': '貼', '贴': '貼', '搜': '搜', '索': '索', '刷': '刷', '新': '新',
    '启': '啟', '动': '動', '运': '運', '行': '行', '停': '停', '止': '止',
    '显': '顯', '示': '示', '隐': '隱', '藏': '藏', '配': '配', '置': '置',
    '系': '系', '统': '統', '代': '代', '理': '理', '模': '模', '式': '式',
    '路': '路', '由': '由', '域': '域', '名': '名', '解': '解', '析': '析',
    '策': '策', '略': '略', '国': '國', '家': '家', '地': '地', '区': '區',
    '洲': '洲', '亚': '亞', '欧': '歐', '非': '非', '美': '美', '澳': '澳',
    '际': '際', '内': '內', '外': '外', '绕': '繞', '过': '過', '流': '流',
    '量': '量', '速': '速', '度': '度', '延': '延', '迟': '遲', '超': '超',
    '历': '歷', '史': '史', '记': '記', '当': '當', '前': '前', '总': '總',
    '计': '計', '划': '劃', '费': '費', '用': '用', '月': '月', '年': '年',
    '小': '小', '毫': '毫', '秒': '秒', '分': '分', '钟': '鐘', '个': '個',
    '无': '無', '有': '有', '限': '限', '已': '已', '未': '未', '正': '正',
    '在': '在', '中': '中', '完': '完', '成': '成', '失': '失', '败': '敗',
    '等': '等', '待': '待', '处': '處', '标': '標', '题': '題', '详': '詳',
    '情': '情', '帮': '幫', '助': '助', '说': '說', '明': '明', '更': '更',
    '金': '金', '额': '額', '支': '支', '付': '付', '创': '創', '建': '建',
    '注': '註', '册': '冊', '忘': '忘', '重': '重', '发': '發', '送': '送',
    '邀': '邀', '约': '約', '推': '推', '荐': '薦', '返': '返', '回': '回',
    '退': '退', '出': '出', '进': '進', '链': '鏈', '接': '接', '地': '地',
    '址': '址', '端': '端', '口': '口', '协': '協', '议': '議', '账': '帳',
    '余': '餘', '佣': '傭', '复': '複', '份': '份', '浅': '淺', '深': '深',
    '色': '色', '主': '主', '题': '題', '外': '外', '观': '觀', '调': '調',
    '应': '應', '检': '檢', '查': '查', '版': '版', '本': '本', '全': '全',
    '球': '球', '智': '智', '能': '能', '仅': '僅', '优': '優', '先': '先',
    '缺': '缺', '省': '省', '默': '默', '认': '認', '自': '自', '机': '機',
    '线': '線', '里': '裡', '点': '點', '击': '擊', '添': '添', '加': '加',
    '移': '移', '除': '除', '清': '清', '必': '必', '须': '須', '字': '字',
    '符': '符', '至': '至', '少': '少', '最': '最', '多': '多', '数': '數',
    '据': '據', '来': '來', '参': '參', '考': '考', '资': '資', '料': '料',
    '信': '信', '息': '息', '项': '項', '目': '目', '分': '分', '类': '類',
    '组': '組', '单': '單', '列': '列', '表': '表', '视': '視', '图': '圖',
    '窗': '窗', '稿': '稿', '载': '載', '读': '讀', '写': '寫', '件': '件',
    '夹': '夾', '传': '傳', '导': '導', '航': '航', '栏': '欄', '侧': '側',
    '边': '邊', '顶': '頂', '部': '部', '底': '底', '左': '左', '右': '右',
    '样': '樣', '台': '台', '湾': '灣', '韩': '韓', '俄': '俄', '罗': '羅',
    '斯': '斯', '伊': '伊', '朗': '朗', '波': '波', '兰': '蘭', '士': '士',
    '瑞': '瑞', '典': '典', '义': '義', '利': '利', '班': '班', '牙': '牙',
    '荷': '荷', '巴': '巴', '印': '印', '坡': '坡', '港': '港', '香': '香',
}

def s2t(text):
    """Convert Simplified Chinese to Traditional Chinese"""
    if not text:
        return text
    result = []
    for char in text:
        result.append(S2T_TABLE.get(char, char))
    return ''.join(result)


# Translation dictionaries
TRANSLATIONS = {
    # Common UI elements
    "Connect": {"zh_CN": "连接", "zh_TW": "連接", "ru_RU": "Подключить", "fa_IR": "اتصال", "vi_VN": "Kết nối", "km_KH": "ភ្ជាប់", "my_MM": "ချိတ်ဆက်"},
    "Disconnect": {"zh_CN": "断开", "zh_TW": "斷開", "ru_RU": "Отключить", "fa_IR": "قطع اتصال", "vi_VN": "Ngắt", "km_KH": "ផ្ដាច់", "my_MM": "ဖြတ်"},
    "Connected": {"zh_CN": "已连接", "zh_TW": "已連接", "ru_RU": "Подключено", "fa_IR": "متصل", "vi_VN": "Đã kết nối", "km_KH": "បានភ្ជាប់", "my_MM": "ချိတ်ဆက်ပြီး"},
    "Disconnected": {"zh_CN": "已断开", "zh_TW": "已斷開", "ru_RU": "Отключено", "fa_IR": "قطع شده", "vi_VN": "Đã ngắt", "km_KH": "បានផ្ដាច់", "my_MM": "ဖြတ်ပြီး"},
    "Connecting...": {"zh_CN": "正在连接...", "zh_TW": "正在連接...", "ru_RU": "Подключение...", "fa_IR": "در حال اتصال...", "vi_VN": "Đang kết nối...", "km_KH": "កំពុងភ្ជាប់...", "my_MM": "ချိတ်ဆက်နေ..."},
    "Disconnecting...": {"zh_CN": "正在断开...", "zh_TW": "正在斷開...", "ru_RU": "Отключение...", "fa_IR": "در حال قطع اتصال...", "vi_VN": "Đang ngắt...", "km_KH": "កំពុងផ្ដាច់...", "my_MM": "ဖြတ်နေ..."},

    # Navigation
    "Servers": {"zh_CN": "服务器", "zh_TW": "伺服器", "ru_RU": "Серверы", "fa_IR": "سرورها", "vi_VN": "Máy chủ", "km_KH": "ម៉ាស៊ីនមេ", "my_MM": "ဆာဗာ"},
    "Settings": {"zh_CN": "设置", "zh_TW": "設定", "ru_RU": "Настройки", "fa_IR": "تنظیمات", "vi_VN": "Cài đặt", "km_KH": "ការកំណត់", "my_MM": "ဆက်တင်"},
    "Profile": {"zh_CN": "资料", "zh_TW": "資料", "ru_RU": "Профиль", "fa_IR": "پروفایل", "vi_VN": "Hồ sơ", "km_KH": "ប្រវត្តិរូប", "my_MM": "ပရိုဖိုင်"},
    "Subscription": {"zh_CN": "订阅", "zh_TW": "訂閱", "ru_RU": "Подписка", "fa_IR": "اشتراک", "vi_VN": "Đăng ký", "km_KH": "ការជាវ", "my_MM": "စာရင်းသွင်း"},
    "Store": {"zh_CN": "商店", "zh_TW": "商店", "ru_RU": "Магазин", "fa_IR": "فروشگاه", "vi_VN": "Cửa hàng", "km_KH": "ហាង", "my_MM": "စတိုး"},

    # Authentication
    "Login": {"zh_CN": "登录", "zh_TW": "登入", "ru_RU": "Войти", "fa_IR": "ورود", "vi_VN": "Đăng nhập", "km_KH": "ចូល", "my_MM": "ဝင်ရောက်"},
    "Logout": {"zh_CN": "退出登录", "zh_TW": "登出", "ru_RU": "Выйти", "fa_IR": "خروج", "vi_VN": "Đăng xuất", "km_KH": "ចេញ", "my_MM": "ထွက်"},
    "Register": {"zh_CN": "注册", "zh_TW": "註冊", "ru_RU": "Регистрация", "fa_IR": "ثبت نام", "vi_VN": "Đăng ký", "km_KH": "ចុះឈ្មោះ", "my_MM": "စာရင်းသွင်း"},
    "Sign Up": {"zh_CN": "注册账号", "zh_TW": "註冊帳號", "ru_RU": "Зарегистрироваться", "fa_IR": "ثبت نام", "vi_VN": "Đăng ký", "km_KH": "ចុះឈ្មោះ", "my_MM": "အကောင့်ဖွင့်"},
    "Email": {"zh_CN": "邮箱", "zh_TW": "電子郵件", "ru_RU": "Эл. почта", "fa_IR": "ایمیل", "vi_VN": "Email", "km_KH": "អ៊ីមែល", "my_MM": "အီးမေးလ်"},
    "Password": {"zh_CN": "密码", "zh_TW": "密碼", "ru_RU": "Пароль", "fa_IR": "رمز عبور", "vi_VN": "Mật khẩu", "km_KH": "លេខសម្ងាត់", "my_MM": "စကားဝှက်"},
    "Forgot Password?": {"zh_CN": "忘记密码？", "zh_TW": "忘記密碼？", "ru_RU": "Забыли пароль?", "fa_IR": "رمز عبور را فراموش کردید؟", "vi_VN": "Quên mật khẩu?", "km_KH": "ភ្លេចលេខសម្ងាត់?", "my_MM": "စကားဝှက်မေ့?"},
    "Back to Login": {"zh_CN": "返回登录", "zh_TW": "返回登入", "ru_RU": "Вернуться к входу", "fa_IR": "بازگشت به ورود", "vi_VN": "Quay lại", "km_KH": "ត្រឡប់", "my_MM": "နောက်သို့"},
    "Change Password": {"zh_CN": "修改密码", "zh_TW": "修改密碼", "ru_RU": "Изменить пароль", "fa_IR": "تغییر رمز عبور", "vi_VN": "Đổi mật khẩu", "km_KH": "ប្ដូរលេខសម្ងាត់", "my_MM": "စကားဝှက်ပြောင်း"},
    "Current Password": {"zh_CN": "当前密码", "zh_TW": "當前密碼", "ru_RU": "Текущий пароль", "fa_IR": "رمز عبور فعلی", "vi_VN": "Mật khẩu hiện tại", "km_KH": "លេខសម្ងាត់បច្ចុប្បន្ន", "my_MM": "လက်ရှိစကားဝှက်"},
    "New Password": {"zh_CN": "新密码", "zh_TW": "新密碼", "ru_RU": "Новый пароль", "fa_IR": "رمز عبور جدید", "vi_VN": "Mật khẩu mới", "km_KH": "លេខសម្ងាត់ថ្មី", "my_MM": "စကားဝှက်အသစ်"},
    "Confirm Password": {"zh_CN": "确认密码", "zh_TW": "確認密碼", "ru_RU": "Подтвердите пароль", "fa_IR": "تایید رمز عبور", "vi_VN": "Xác nhận", "km_KH": "បញ្ជាក់", "my_MM": "အတည်ပြု"},

    # Server list
    "Server List": {"zh_CN": "服务器列表", "zh_TW": "伺服器列表", "ru_RU": "Список серверов", "fa_IR": "لیست سرورها", "vi_VN": "Danh sách", "km_KH": "បញ្ជី", "my_MM": "စာရင်း"},
    "Search servers...": {"zh_CN": "搜索服务器...", "zh_TW": "搜尋伺服器...", "ru_RU": "Поиск серверов...", "fa_IR": "جستجوی سرورها...", "vi_VN": "Tìm kiếm...", "km_KH": "ស្វែងរក...", "my_MM": "ရှာဖွေ..."},
    "No servers available": {"zh_CN": "暂无可用服务器", "zh_TW": "暫無可用伺服器", "ru_RU": "Нет доступных серверов", "fa_IR": "سروری در دسترس نیست", "vi_VN": "Không có máy chủ", "km_KH": "គ្មានម៉ាស៊ីនមេ", "my_MM": "ဆာဗာမရှိ"},
    "Test Latency": {"zh_CN": "测试延迟", "zh_TW": "測試延遲", "ru_RU": "Тест задержки", "fa_IR": "تست تاخیر", "vi_VN": "Test ping", "km_KH": "សាកល្បង", "my_MM": "စမ်းသပ်"},
    "Testing...": {"zh_CN": "测试中...", "zh_TW": "測試中...", "ru_RU": "Тестирование...", "fa_IR": "در حال آزمایش...", "vi_VN": "Đang test...", "km_KH": "កំពុងសាកល្បង...", "my_MM": "စမ်းသပ်နေ..."},
    "Timeout": {"zh_CN": "超时", "zh_TW": "逾時", "ru_RU": "Тайм-аут", "fa_IR": "زمان تمام شد", "vi_VN": "Hết giờ", "km_KH": "អស់ពេល", "my_MM": "အချိန်ကုန်"},
    "Refresh": {"zh_CN": "刷新", "zh_TW": "重新整理", "ru_RU": "Обновить", "fa_IR": "بازخوانی", "vi_VN": "Làm mới", "km_KH": "ផ្ទុកឡើងវិញ", "my_MM": "ပြန်စဖွင့်"},
    "Sort by latency": {"zh_CN": "按延迟排序", "zh_TW": "按延遲排序", "ru_RU": "Сортировать по задержке", "fa_IR": "مرتب سازی بر اساس تاخیر", "vi_VN": "Theo ping", "km_KH": "តម្រៀប", "my_MM": "ping အလိုက်"},
    "Sort by name": {"zh_CN": "按名称排序", "zh_TW": "按名稱排序", "ru_RU": "Сортировать по имени", "fa_IR": "مرتب سازی بر اساس نام", "vi_VN": "Theo tên", "km_KH": "តាមឈ្មោះ", "my_MM": "အမည်အလိုက်"},
    "Test all servers": {"zh_CN": "测试所有服务器", "zh_TW": "測試所有伺服器", "ru_RU": "Тестировать все серверы", "fa_IR": "آزمایش همه سرورها", "vi_VN": "Test tất cả", "km_KH": "សាកល្បងទាំងអស់", "my_MM": "အားလုံးစမ်း"},
    "Copy": {"zh_CN": "复制", "zh_TW": "複製", "ru_RU": "Копировать", "fa_IR": "کپی", "vi_VN": "Sao chép", "km_KH": "ចម្លង", "my_MM": "ကူးယူ"},
    "Go": {"zh_CN": "连接", "zh_TW": "連接", "ru_RU": "Подключить", "fa_IR": "اتصال", "vi_VN": "Kết nối", "km_KH": "ភ្ជាប់", "my_MM": "ချိတ်"},
    "Off": {"zh_CN": "断开", "zh_TW": "斷開", "ru_RU": "Откл.", "fa_IR": "قطع", "vi_VN": "Ngắt", "km_KH": "បិទ", "my_MM": "ပိတ်"},
    "Go to Subscriptions": {"zh_CN": "前往订阅", "zh_TW": "前往訂閱", "ru_RU": "Перейти к подпискам", "fa_IR": "رفتن به اشتراک‌ها", "vi_VN": "Đến đăng ký", "km_KH": "ទៅការជាវ", "my_MM": "စာရင်းသို့"},
    "Loading servers...": {"zh_CN": "正在加载服务器...", "zh_TW": "正在載入伺服器...", "ru_RU": "Загрузка серверов...", "fa_IR": "در حال بارگذاری سرورها...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "Please wait a moment": {"zh_CN": "请稍候", "zh_TW": "請稍候", "ru_RU": "Пожалуйста, подождите", "fa_IR": "لطفا صبر کنید", "vi_VN": "Vui lòng đợi", "km_KH": "សូមរង់ចាំ", "my_MM": "စောင့်ပါ"},
    "Refresh server list": {"zh_CN": "刷新服务器列表", "zh_TW": "重新整理伺服器列表", "ru_RU": "Обновить список серверов", "fa_IR": "بازخوانی لیست سرورها", "vi_VN": "Làm mới", "km_KH": "ធ្វើឱ្យស្រស់", "my_MM": "ပြန်ဖွင့်"},
    "Share link copied": {"zh_CN": "分享链接已复制", "zh_TW": "分享連結已複製", "ru_RU": "Ссылка скопирована", "fa_IR": "لینک اشتراک کپی شد", "vi_VN": "Đã sao chép", "km_KH": "បានចម្លង", "my_MM": "ကူးပြီး"},

    # Connection page
    "Connection": {"zh_CN": "连接", "zh_TW": "連接", "ru_RU": "Подключение", "fa_IR": "اتصال", "vi_VN": "Kết nối", "km_KH": "ការភ្ជាប់", "my_MM": "ချိတ်ဆက်"},
    "Upload": {"zh_CN": "上传", "zh_TW": "上傳", "ru_RU": "Отправлено", "fa_IR": "آپلود", "vi_VN": "Tải lên", "km_KH": "ផ្ទុកឡើង", "my_MM": "အပ်လုဒ်"},
    "Download": {"zh_CN": "下载", "zh_TW": "下載", "ru_RU": "Загружено", "fa_IR": "دانلود", "vi_VN": "Tải xuống", "km_KH": "ទាញយក", "my_MM": "ဒေါင်းလုဒ်"},
    "Latency": {"zh_CN": "延迟", "zh_TW": "延遲", "ru_RU": "Задержка", "fa_IR": "تاخیر", "vi_VN": "Độ trễ", "km_KH": "ការពន្យឺត", "my_MM": "နှောင့်နှေး"},
    "Duration": {"zh_CN": "时长", "zh_TW": "時長", "ru_RU": "Длительность", "fa_IR": "مدت زمان", "vi_VN": "Thời gian", "km_KH": "រយៈពេល", "my_MM": "ကြာချိန်"},
    "Select Server": {"zh_CN": "选择服务器", "zh_TW": "選擇伺服器", "ru_RU": "Выберите сервер", "fa_IR": "انتخاب سرور", "vi_VN": "Chọn máy chủ", "km_KH": "ជ្រើសម៉ាស៊ីនមេ", "my_MM": "ဆာဗာရွေး"},
    "No server selected": {"zh_CN": "未选择服务器", "zh_TW": "未選擇伺服器", "ru_RU": "Сервер не выбран", "fa_IR": "سروری انتخاب نشده", "vi_VN": "Chưa chọn", "km_KH": "មិនបានជ្រើស", "my_MM": "မရွေးရသေး"},
    "Please select a server first": {"zh_CN": "请先选择服务器", "zh_TW": "請先選擇伺服器", "ru_RU": "Сначала выберите сервер", "fa_IR": "لطفا ابتدا سرور را انتخاب کنید", "vi_VN": "Vui lòng chọn máy chủ", "km_KH": "សូមជ្រើសម៉ាស៊ីនមេ", "my_MM": "ဆာဗာရွေးပါ"},
    "Not Connected": {"zh_CN": "未连接", "zh_TW": "未連接", "ru_RU": "Не подключено", "fa_IR": "متصل نیست", "vi_VN": "Chưa kết nối", "km_KH": "មិនបានភ្ជាប់", "my_MM": "မချိတ်ရသေး"},
    "Click to connect": {"zh_CN": "点击连接", "zh_TW": "點擊連接", "ru_RU": "Нажмите для подключения", "fa_IR": "برای اتصال کلیک کنید", "vi_VN": "Nhấn để kết nối", "km_KH": "ចុចដើម្បីភ្ជាប់", "my_MM": "ချိတ်ရန်နှိပ်"},
    "Click to disconnect": {"zh_CN": "点击断开", "zh_TW": "點擊斷開", "ru_RU": "Нажмите для отключения", "fa_IR": "برای قطع اتصال کلیک کنید", "vi_VN": "Nhấn để ngắt", "km_KH": "ចុចដើម្បីផ្ដាច់", "my_MM": "ဖြတ်ရန်နှိပ်"},
    "Connection Settings": {"zh_CN": "连接设置", "zh_TW": "連接設定", "ru_RU": "Настройки подключения", "fa_IR": "تنظیمات اتصال", "vi_VN": "Cài đặt kết nối", "km_KH": "ការកំណត់ការភ្ជាប់", "my_MM": "ချိတ်ဆက်ဆက်တင်"},

    # Settings page
    "General Settings": {"zh_CN": "通用设置", "zh_TW": "一般設定", "ru_RU": "Общие настройки", "fa_IR": "تنظیمات عمومی", "vi_VN": "Cài đặt chung", "km_KH": "ការកំណត់ទូទៅ", "my_MM": "အထွေထွေ"},
    "Appearance": {"zh_CN": "外观", "zh_TW": "外觀", "ru_RU": "Внешний вид", "fa_IR": "ظاهر", "vi_VN": "Giao diện", "km_KH": "រូបរាង", "my_MM": "အသွင်အပြင်"},
    "Theme": {"zh_CN": "主题", "zh_TW": "主題", "ru_RU": "Тема", "fa_IR": "تم", "vi_VN": "Chủ đề", "km_KH": "ប្រធានបទ", "my_MM": "အပြင်အဆင်"},
    "Light": {"zh_CN": "浅色", "zh_TW": "淺色", "ru_RU": "Светлая", "fa_IR": "روشن", "vi_VN": "Sáng", "km_KH": "ភ្លឺ", "my_MM": "အလင်း"},
    "Dark": {"zh_CN": "深色", "zh_TW": "深色", "ru_RU": "Темная", "fa_IR": "تیره", "vi_VN": "Tối", "km_KH": "ងងឹត", "my_MM": "အမှောင်"},
    "System": {"zh_CN": "跟随系统", "zh_TW": "跟隨系統", "ru_RU": "Системная", "fa_IR": "سیستم", "vi_VN": "Hệ thống", "km_KH": "ប្រព័ន្ធ", "my_MM": "စနစ်"},
    "Language": {"zh_CN": "语言", "zh_TW": "語言", "ru_RU": "Язык", "fa_IR": "زبان", "vi_VN": "Ngôn ngữ", "km_KH": "ភាសា", "my_MM": "ဘာသာစကား"},
    "English": {"zh_CN": "英语", "zh_TW": "英語", "ru_RU": "Английский", "fa_IR": "انگلیسی", "vi_VN": "Tiếng Anh", "km_KH": "អង់គ្លេស", "my_MM": "အင်္ဂလိပ်"},
    "Chinese": {"zh_CN": "中文", "zh_TW": "中文", "ru_RU": "Китайский", "fa_IR": "چینی", "vi_VN": "Tiếng Trung", "km_KH": "ចិន", "my_MM": "တရုတ်"},
    "Russian": {"zh_CN": "俄语", "zh_TW": "俄語", "ru_RU": "Русский", "fa_IR": "روسی", "vi_VN": "Tiếng Nga", "km_KH": "រុស្ស៊ី", "my_MM": "ရုရှ"},
    "Persian": {"zh_CN": "波斯语", "zh_TW": "波斯語", "ru_RU": "Персидский", "fa_IR": "فارسی", "vi_VN": "Tiếng Ba Tư", "km_KH": "ភើសៀ", "my_MM": "ပါရှန်"},
    "Routing Settings": {"zh_CN": "路由设置", "zh_TW": "路由設定", "ru_RU": "Настройки маршрутизации", "fa_IR": "تنظیمات مسیریابی", "vi_VN": "Định tuyến", "km_KH": "ការកំណត់ផ្លូវ", "my_MM": "လမ်းကြောင်း"},
    "DNS Settings": {"zh_CN": "DNS设置", "zh_TW": "DNS設定", "ru_RU": "Настройки DNS", "fa_IR": "تنظیمات DNS", "vi_VN": "Cài đặt DNS", "km_KH": "ការកំណត់ DNS", "my_MM": "DNS ဆက်တင်"},
    "Network Settings": {"zh_CN": "网络设置", "zh_TW": "網路設定", "ru_RU": "Сетевые настройки", "fa_IR": "تنظیمات شبکه", "vi_VN": "Cài đặt mạng", "km_KH": "ការកំណត់បណ្ដាញ", "my_MM": "ကွန်ရက်ဆက်တင်"},
    "VPN Mode": {"zh_CN": "VPN模式", "zh_TW": "VPN模式", "ru_RU": "Режим VPN", "fa_IR": "حالت VPN", "vi_VN": "Chế độ VPN", "km_KH": "របៀប VPN", "my_MM": "VPN မုဒ်"},
    "TUN Mode": {"zh_CN": "TUN模式", "zh_TW": "TUN模式", "ru_RU": "Режим TUN", "fa_IR": "حالت TUN", "vi_VN": "Chế độ TUN", "km_KH": "របៀប TUN", "my_MM": "TUN မုဒ်"},
    "Proxy Mode": {"zh_CN": "代理模式", "zh_TW": "代理模式", "ru_RU": "Режим прокси", "fa_IR": "حالت پروکسی", "vi_VN": "Chế độ Proxy", "km_KH": "របៀប Proxy", "my_MM": "Proxy မုဒ်"},
    "System Proxy": {"zh_CN": "系统代理", "zh_TW": "系統代理", "ru_RU": "Системный прокси", "fa_IR": "پروکسی سیستم", "vi_VN": "Proxy hệ thống", "km_KH": "Proxy ប្រព័ន្ធ", "my_MM": "စနစ် Proxy"},
    "Enable system proxy": {"zh_CN": "启用系统代理", "zh_TW": "啟用系統代理", "ru_RU": "Включить системный прокси", "fa_IR": "فعال کردن پروکسی سیستم", "vi_VN": "Bật proxy hệ thống", "km_KH": "បើក Proxy ប្រព័ន្ធ", "my_MM": "စနစ် Proxy ဖွင့်"},
    "Bypass LAN addresses": {"zh_CN": "绕过局域网地址", "zh_TW": "繞過區域網路位址", "ru_RU": "Обходить LAN-адреса", "fa_IR": "دور زدن آدرس‌های شبکه محلی", "vi_VN": "Bỏ qua LAN", "km_KH": "រំលង LAN", "my_MM": "LAN ကျော်"},
    "LAN traffic bypass proxy": {"zh_CN": "局域网流量绕过代理", "zh_TW": "區域網路流量繞過代理", "ru_RU": "Трафик LAN в обход прокси", "fa_IR": "ترافیک شبکه محلی از پروکسی عبور نمی‌کند", "vi_VN": "Bỏ qua LAN", "km_KH": "ចរាចរ LAN រំលង", "my_MM": "LAN အသွားအလာကျော်"},
    "About": {"zh_CN": "关于", "zh_TW": "關於", "ru_RU": "О программе", "fa_IR": "درباره", "vi_VN": "Giới thiệu", "km_KH": "អំពី", "my_MM": "အကြောင်း"},
    "Check": {"zh_CN": "检查更新", "zh_TW": "檢查更新", "ru_RU": "Проверить", "fa_IR": "بررسی", "vi_VN": "Kiểm tra", "km_KH": "ពិនិត្យ", "my_MM": "စစ်ဆေး"},
    "Application Version": {"zh_CN": "应用版本", "zh_TW": "應用版本", "ru_RU": "Версия приложения", "fa_IR": "نسخه برنامه", "vi_VN": "Phiên bản", "km_KH": "កំណែកម្មវិធី", "my_MM": "ဗားရှင်း"},
    "Subscription Settings": {"zh_CN": "订阅设置", "zh_TW": "訂閱設定", "ru_RU": "Настройки подписки", "fa_IR": "تنظیمات اشتراک", "vi_VN": "Cài đặt đăng ký", "km_KH": "ការកំណត់ការជាវ", "my_MM": "စာရင်းသွင်းဆက်တင်"},
    "Server subscription update settings": {"zh_CN": "服务器订阅更新设置", "zh_TW": "伺服器訂閱更新設定", "ru_RU": "Настройки обновления подписки", "fa_IR": "تنظیمات به‌روزرسانی اشتراک", "vi_VN": "Cập nhật đăng ký", "km_KH": "ការកំណត់ធ្វើបច្ចុប្បន្នភាព", "my_MM": "အပ်ဒိတ်ဆက်တင်"},
    "Auto Update Interval": {"zh_CN": "自动更新间隔", "zh_TW": "自動更新間隔", "ru_RU": "Интервал автообновления", "fa_IR": "فاصله به‌روزرسانی خودکار", "vi_VN": "Khoảng cập nhật", "km_KH": "ចន្លោះធ្វើបច្ចុប្បន្នភាព", "my_MM": "အလိုအလျောက်အပ်ဒိတ်"},
    "How often to automatically update server list": {"zh_CN": "服务器列表自动更新频率", "zh_TW": "伺服器列表自動更新頻率", "ru_RU": "Как часто автообновлять список серверов", "fa_IR": "هر چند وقت لیست سرورها به‌روز شود", "vi_VN": "Tần suất cập nhật", "km_KH": "ប្រេកង់ធ្វើបច្ចុប្បន្នភាព", "my_MM": "မကြာခဏအပ်ဒိတ်"},
    "1 Hour": {"zh_CN": "1小时", "zh_TW": "1小時", "ru_RU": "1 час", "fa_IR": "1 ساعت", "vi_VN": "1 giờ", "km_KH": "១ម៉ោង", "my_MM": "၁နာရီ"},
    "3 Hours": {"zh_CN": "3小时", "zh_TW": "3小時", "ru_RU": "3 часа", "fa_IR": "3 ساعت", "vi_VN": "3 giờ", "km_KH": "៣ម៉ោង", "my_MM": "၃နာရီ"},
    "6 Hours": {"zh_CN": "6小时", "zh_TW": "6小時", "ru_RU": "6 часов", "fa_IR": "6 ساعت", "vi_VN": "6 giờ", "km_KH": "៦ម៉ោង", "my_MM": "၆နာရီ"},
    "12 Hours": {"zh_CN": "12小时", "zh_TW": "12小時", "ru_RU": "12 часов", "fa_IR": "12 ساعت", "vi_VN": "12 giờ", "km_KH": "១២ម៉ោង", "my_MM": "၁၂နာရီ"},
    "24 Hours": {"zh_CN": "24小时", "zh_TW": "24小時", "ru_RU": "24 часа", "fa_IR": "24 ساعت", "vi_VN": "24 giờ", "km_KH": "២៤ម៉ោង", "my_MM": "၂၄နာရီ"},
    "Network Interface": {"zh_CN": "网络接口", "zh_TW": "網路介面", "ru_RU": "Сетевой интерфейс", "fa_IR": "رابط شبکه", "vi_VN": "Giao diện mạng", "km_KH": "ចំណុចភ្ជាប់បណ្ដាញ", "my_MM": "ကွန်ရက် Interface"},
    "Select the network interface for VPN outbound traffic": {"zh_CN": "选择VPN出站流量使用的网络接口", "zh_TW": "選擇VPN出站流量使用的網路介面", "ru_RU": "Выберите сетевой интерфейс для исходящего VPN-трафика", "fa_IR": "رابط شبکه برای ترافیک خروجی VPN را انتخاب کنید", "vi_VN": "Chọn giao diện mạng", "km_KH": "ជ្រើសចំណុចភ្ជាប់បណ្ដាញ", "my_MM": "ကွန်ရက် Interface ရွေး"},
    "Network Test": {"zh_CN": "网络测试", "zh_TW": "網路測試", "ru_RU": "Тест сети", "fa_IR": "آزمایش شبکه", "vi_VN": "Test mạng", "km_KH": "សាកល្បងបណ្ដាញ", "my_MM": "ကွန်ရက်စမ်း"},
    "Connection test settings": {"zh_CN": "连接测试设置", "zh_TW": "連接測試設定", "ru_RU": "Настройки теста соединения", "fa_IR": "تنظیمات آزمایش اتصال", "vi_VN": "Cài đặt test", "km_KH": "ការកំណត់សាកល្បង", "my_MM": "စမ်းသပ်ဆက်တင်"},
    "Test Method": {"zh_CN": "测试方法", "zh_TW": "測試方法", "ru_RU": "Метод теста", "fa_IR": "روش آزمایش", "vi_VN": "Phương pháp", "km_KH": "វិធីសាស្ត្រ", "my_MM": "နည်းလမ်း"},
    "TCP Test": {"zh_CN": "TCP测试", "zh_TW": "TCP測試", "ru_RU": "TCP тест", "fa_IR": "تست TCP", "vi_VN": "Test TCP", "km_KH": "សាកល្បង TCP", "my_MM": "TCP စမ်း"},
    "HTTP Test": {"zh_CN": "HTTP测试", "zh_TW": "HTTP測試", "ru_RU": "HTTP тест", "fa_IR": "تست HTTP", "vi_VN": "Test HTTP", "km_KH": "សាកល្បង HTTP", "my_MM": "HTTP စမ်း"},
    "ICMP Ping": {"zh_CN": "ICMP Ping", "zh_TW": "ICMP Ping", "ru_RU": "ICMP Ping", "fa_IR": "ICMP Ping", "vi_VN": "ICMP Ping", "km_KH": "ICMP Ping", "my_MM": "ICMP Ping"},
    "Test Timeout (ms)": {"zh_CN": "测试超时 (毫秒)", "zh_TW": "測試逾時 (毫秒)", "ru_RU": "Тайм-аут теста (мс)", "fa_IR": "زمان تمام شدن آزمایش (میلی‌ثانیه)", "vi_VN": "Thời gian chờ (ms)", "km_KH": "អស់ពេល (ms)", "my_MM": "အချိန်ကုန် (ms)"},
    "Latency Test Interval": {"zh_CN": "延迟测试间隔", "zh_TW": "延遲測試間隔", "ru_RU": "Интервал теста задержки", "fa_IR": "فاصله آزمایش تاخیر", "vi_VN": "Khoảng test", "km_KH": "ចន្លោះសាកល្បង", "my_MM": "စမ်းသပ်ကြား"},
    "0 = disabled, test latency periodically when connected": {"zh_CN": "0=禁用，连接时定期测试延迟", "zh_TW": "0=停用，連接時定期測試延遲", "ru_RU": "0 = отключено, тест задержки при подключении", "fa_IR": "0 = غیرفعال، تست تاخیر در هنگام اتصال", "vi_VN": "0 = tắt", "km_KH": "០ = បិទ", "my_MM": "0 = ပိတ်"},
    "Disabled": {"zh_CN": "已禁用", "zh_TW": "已停用", "ru_RU": "Отключено", "fa_IR": "غیرفعال", "vi_VN": "Tắt", "km_KH": "បិទ", "my_MM": "ပိတ်"},
    "Control how traffic is routed and split": {"zh_CN": "控制流量路由和分流", "zh_TW": "控制流量路由和分流", "ru_RU": "Управление маршрутизацией трафика", "fa_IR": "کنترل نحوه مسیریابی ترافیک", "vi_VN": "Kiểm soát định tuyến", "km_KH": "ត្រួតពិនិត្យផ្លូវ", "my_MM": "လမ်းကြောင်းထိန်း"},
    "Domain Resolution Strategy": {"zh_CN": "域名解析策略", "zh_TW": "網域解析策略", "ru_RU": "Стратегия разрешения доменов", "fa_IR": "استراتژی حل دامنه", "vi_VN": "Phân giải tên miền", "km_KH": "យុទ្ធសាស្ត្រដោះស្រាយដែន", "my_MM": "Domain ဖြေရှင်းနည်း"},
    "Control how domains are resolved": {"zh_CN": "控制域名解析方式", "zh_TW": "控制網域解析方式", "ru_RU": "Управление разрешением доменов", "fa_IR": "نحوه حل دامنه‌ها", "vi_VN": "Cách phân giải", "km_KH": "វិធីដោះស្រាយ", "my_MM": "ဖြေရှင်းပုံ"},
    "User Country": {"zh_CN": "用户国家", "zh_TW": "使用者國家", "ru_RU": "Страна пользователя", "fa_IR": "کشور کاربر", "vi_VN": "Quốc gia", "km_KH": "ប្រទេសអ្នកប្រើ", "my_MM": "နိုင်ငံ"},
    "Select your country for optimal routing": {"zh_CN": "选择您的国家以优化路由", "zh_TW": "選擇您的國家以最佳化路由", "ru_RU": "Выберите страну для оптимальной маршрутизации", "fa_IR": "کشور خود را برای مسیریابی بهینه انتخاب کنید", "vi_VN": "Chọn quốc gia", "km_KH": "ជ្រើសប្រទេស", "my_MM": "နိုင်ငံရွေး"},
    "China": {"zh_CN": "中国", "zh_TW": "中國", "ru_RU": "Китай", "fa_IR": "چین", "vi_VN": "Trung Quốc", "km_KH": "ចិន", "my_MM": "တရုတ်"},
    "Russia": {"zh_CN": "俄罗斯", "zh_TW": "俄羅斯", "ru_RU": "Россия", "fa_IR": "روسیه", "vi_VN": "Nga", "km_KH": "រុស្ស៊ី", "my_MM": "ရုရှ"},
    "Iran": {"zh_CN": "伊朗", "zh_TW": "伊朗", "ru_RU": "Иран", "fa_IR": "ایران", "vi_VN": "Iran", "km_KH": "អ៊ីរ៉ង់", "my_MM": "အီရန်"},
    "DNS server configuration": {"zh_CN": "DNS服务器配置", "zh_TW": "DNS伺服器設定", "ru_RU": "Конфигурация DNS-сервера", "fa_IR": "پیکربندی سرور DNS", "vi_VN": "Cấu hình DNS", "km_KH": "ការកំណត់ម៉ាស៊ីនមេ DNS", "my_MM": "DNS ဆာဗာ ပြင်ဆင်"},
    "Domestic DNS 1": {"zh_CN": "国内DNS 1", "zh_TW": "國內DNS 1", "ru_RU": "Внутренний DNS 1", "fa_IR": "DNS داخلی 1", "vi_VN": "DNS nội địa 1", "km_KH": "DNS ក្នុងស្រុក ១", "my_MM": "ပြည်တွင်း DNS 1"},
    "Domestic DNS 2": {"zh_CN": "国内DNS 2", "zh_TW": "國內DNS 2", "ru_RU": "Внутренний DNS 2", "fa_IR": "DNS داخلی 2", "vi_VN": "DNS nội địa 2", "km_KH": "DNS ក្នុងស្រុក ២", "my_MM": "ပြည်တွင်း DNS 2"},
    "Foreign DNS": {"zh_CN": "国外DNS", "zh_TW": "國外DNS", "ru_RU": "Зарубежный DNS", "fa_IR": "DNS خارجی", "vi_VN": "DNS nước ngoài", "km_KH": "DNS បរទេស", "my_MM": "နိုင်ငံခြား DNS"},

    # Store page
    "Current Subscription": {"zh_CN": "当前订阅", "zh_TW": "目前訂閱", "ru_RU": "Текущая подписка", "fa_IR": "اشتراک فعلی", "vi_VN": "Gói hiện tại", "km_KH": "ការជាវបច្ចុប្បន្ន", "my_MM": "လက်ရှိစာရင်း"},
    "NoneSubscription": {"zh_CN": "无订阅", "zh_TW": "無訂閱", "ru_RU": "Нет подписки", "fa_IR": "بدون اشتراک", "vi_VN": "Chưa đăng ký", "km_KH": "គ្មានការជាវ", "my_MM": "မရှိ"},
    "Select a plan below to get started": {"zh_CN": "选择下方套餐开始使用", "zh_TW": "選擇下方方案開始使用", "ru_RU": "Выберите план ниже для начала", "fa_IR": "برای شروع یک طرح انتخاب کنید", "vi_VN": "Chọn gói bên dưới", "km_KH": "ជ្រើសរើសគម្រោង", "my_MM": "အစီအစဉ်ရွေး"},
    "Update & Subscriptions": {"zh_CN": "更新与订阅", "zh_TW": "更新與訂閱", "ru_RU": "Обновления и подписки", "fa_IR": "به‌روزرسانی و اشتراک‌ها", "vi_VN": "Cập nhật", "km_KH": "ការធ្វើបច្ចុប្បន្នភាព", "my_MM": "အပ်ဒိတ်"},
    "Subscription link": {"zh_CN": "订阅链接", "zh_TW": "訂閱連結", "ru_RU": "Ссылка на подписку", "fa_IR": "لینک اشتراک", "vi_VN": "Link đăng ký", "km_KH": "តំណការជាវ", "my_MM": "လင့်"},
    "Copy subscription link": {"zh_CN": "复制订阅链接", "zh_TW": "複製訂閱連結", "ru_RU": "Копировать ссылку подписки", "fa_IR": "کپی لینک اشتراک", "vi_VN": "Sao chép link", "km_KH": "ចម្លងតំណ", "my_MM": "လင့်ကူး"},
    "Update subscription link": {"zh_CN": "更新订阅链接", "zh_TW": "更新訂閱連結", "ru_RU": "Обновить ссылку подписки", "fa_IR": "به‌روزرسانی لینک اشتراک", "vi_VN": "Cập nhật link", "km_KH": "ធ្វើបច្ចុប្បន្នភាពតំណ", "my_MM": "လင့်အပ်ဒိတ်"},
    "Updating...": {"zh_CN": "更新中...", "zh_TW": "更新中...", "ru_RU": "Обновление...", "fa_IR": "در حال به‌روزرسانی...", "vi_VN": "Đang cập nhật...", "km_KH": "កំពុងធ្វើបច្ចុប្បន្នភាព...", "my_MM": "အပ်ဒိတ်နေ..."},
    "Loading subscription information...": {"zh_CN": "正在加载订阅信息...", "zh_TW": "正在載入訂閱資訊...", "ru_RU": "Загрузка информации о подписке...", "fa_IR": "در حال بارگذاری اطلاعات اشتراک...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "Please login first to view subscription information": {"zh_CN": "请先登录以查看订阅信息", "zh_TW": "請先登入以查看訂閱資訊", "ru_RU": "Войдите для просмотра подписки", "fa_IR": "برای مشاهده اطلاعات اشتراک ابتدا وارد شوید", "vi_VN": "Vui lòng đăng nhập", "km_KH": "សូមចូល", "my_MM": "ဝင်ပါ"},
    "Expires": {"zh_CN": "到期", "zh_TW": "到期", "ru_RU": "Истекает", "fa_IR": "انقضا", "vi_VN": "Hết hạn", "km_KH": "ផុតកំណត់", "my_MM": "သက်တမ်းကုန်"},
    "Remaining": {"zh_CN": "剩余", "zh_TW": "剩餘", "ru_RU": "Осталось", "fa_IR": "باقی‌مانده", "vi_VN": "Còn lại", "km_KH": "នៅសល់", "my_MM": "ကျန်"},
    "Used": {"zh_CN": "已用", "zh_TW": "已用", "ru_RU": "Использовано", "fa_IR": "استفاده شده", "vi_VN": "Đã dùng", "km_KH": "បានប្រើ", "my_MM": "သုံးပြီး"},
    "Unlimited": {"zh_CN": "无限制", "zh_TW": "無限制", "ru_RU": "Неограниченно", "fa_IR": "نامحدود", "vi_VN": "Không giới hạn", "km_KH": "គ្មានដែនកំណត់", "my_MM": "အကန့်မရှိ"},
    "Available Plans": {"zh_CN": "可用套餐", "zh_TW": "可用方案", "ru_RU": "Доступные планы", "fa_IR": "طرح‌های موجود", "vi_VN": "Gói có sẵn", "km_KH": "គម្រោងដែលមាន", "my_MM": "ရရှိနိုင်သောအစီအစဉ်"},
    "No plans available": {"zh_CN": "暂无可用套餐", "zh_TW": "暫無可用方案", "ru_RU": "Нет доступных планов", "fa_IR": "طرحی موجود نیست", "vi_VN": "Không có gói", "km_KH": "គ្មានគម្រោង", "my_MM": "အစီအစဉ်မရှိ"},
    "Subscribe": {"zh_CN": "订阅", "zh_TW": "訂閱", "ru_RU": "Подписаться", "fa_IR": "اشتراک", "vi_VN": "Đăng ký", "km_KH": "ជាវ", "my_MM": "စာရင်းသွင်း"},
    "Renew": {"zh_CN": "续费", "zh_TW": "續費", "ru_RU": "Продлить", "fa_IR": "تمدید", "vi_VN": "Gia hạn", "km_KH": "បន្ត", "my_MM": "သက်တမ်းတိုး"},
    "month": {"zh_CN": "月", "zh_TW": "月", "ru_RU": "мес.", "fa_IR": "ماه", "vi_VN": "tháng", "km_KH": "ខែ", "my_MM": "လ"},
    "year": {"zh_CN": "年", "zh_TW": "年", "ru_RU": "год", "fa_IR": "سال", "vi_VN": "năm", "km_KH": "ឆ្នាំ", "my_MM": "နှစ်"},
    "/month": {"zh_CN": "/月", "zh_TW": "/月", "ru_RU": "/мес.", "fa_IR": "/ماه", "vi_VN": "/tháng", "km_KH": "/ខែ", "my_MM": "/လ"},
    "/year": {"zh_CN": "/年", "zh_TW": "/年", "ru_RU": "/год", "fa_IR": "/سال", "vi_VN": "/năm", "km_KH": "/ឆ្នាំ", "my_MM": "/နှစ်"},
    "✓ Subscription link updated": {"zh_CN": "✓ 订阅链接已更新", "zh_TW": "✓ 訂閱連結已更新", "ru_RU": "✓ Ссылка обновлена", "fa_IR": "✓ لینک اشتراک به‌روز شد"},
    "✓ Copied": {"zh_CN": "✓ 已复制", "zh_TW": "✓ 已複製", "ru_RU": "✓ Скопировано", "fa_IR": "✓ کپی شد"},

    # Profile page
    "User Profile": {"zh_CN": "用户资料", "zh_TW": "使用者資料", "ru_RU": "Профиль пользователя", "fa_IR": "پروفایل کاربر", "vi_VN": "Hồ sơ", "km_KH": "ប្រវត្តិរូប", "my_MM": "ပရိုဖိုင်"},
    "Account": {"zh_CN": "账号", "zh_TW": "帳號", "ru_RU": "Аккаунт", "fa_IR": "حساب کاربری", "vi_VN": "Tài khoản", "km_KH": "គណនី", "my_MM": "အကောင့်"},
    "Balance": {"zh_CN": "余额", "zh_TW": "餘額", "ru_RU": "Баланс", "fa_IR": "موجودی", "vi_VN": "Số dư", "km_KH": "សមតុល្យ", "my_MM": "လက်ကျန်"},
    "Commission": {"zh_CN": "佣金", "zh_TW": "佣金", "ru_RU": "Комиссия", "fa_IR": "کمیسیون", "vi_VN": "Hoa hồng", "km_KH": "កម្រៃ", "my_MM": "ကော်မရှင်"},
    "Invited Users": {"zh_CN": "邀请用户", "zh_TW": "邀請使用者", "ru_RU": "Приглашенные", "fa_IR": "کاربران دعوت شده", "vi_VN": "Đã mời", "km_KH": "បានអញ្ជើញ", "my_MM": "ဖိတ်ထား"},
    "Referral Link": {"zh_CN": "推荐链接", "zh_TW": "推薦連結", "ru_RU": "Реферальная ссылка", "fa_IR": "لینک معرفی", "vi_VN": "Link giới thiệu", "km_KH": "តំណណែនាំ", "my_MM": "ရည်ညွှန်းလင့်"},
    "Copy Link": {"zh_CN": "复制链接", "zh_TW": "複製連結", "ru_RU": "Копировать ссылку", "fa_IR": "کپی لینک", "vi_VN": "Sao chép link", "km_KH": "ចម្លងតំណ", "my_MM": "လင့်ကူး"},
    "Please login to view profile": {"zh_CN": "请登录查看资料", "zh_TW": "請登入查看資料", "ru_RU": "Войдите для просмотра профиля", "fa_IR": "برای مشاهده پروفایل وارد شوید", "vi_VN": "Vui lòng đăng nhập", "km_KH": "សូមចូល", "my_MM": "ဝင်ပါ"},

    # Login form
    "Sign In": {"zh_CN": "登录", "zh_TW": "登入", "ru_RU": "Войти", "fa_IR": "ورود", "vi_VN": "Đăng nhập", "km_KH": "ចូល", "my_MM": "ဝင်ရောက်"},
    "Please enter your email": {"zh_CN": "请输入邮箱", "zh_TW": "請輸入電子郵件", "ru_RU": "Введите эл. почту", "fa_IR": "لطفا ایمیل را وارد کنید", "vi_VN": "Nhập email", "km_KH": "បញ្ចូលអ៊ីមែល", "my_MM": "အီးမေးလ်ရိုက်"},
    "Please enter your password": {"zh_CN": "请输入密码", "zh_TW": "請輸入密碼", "ru_RU": "Введите пароль", "fa_IR": "لطفا رمز عبور را وارد کنید", "vi_VN": "Nhập mật khẩu", "km_KH": "បញ្ចូលលេខសម្ងាត់", "my_MM": "စကားဝှက်ရိုက်"},
    "Remember me": {"zh_CN": "记住我", "zh_TW": "記住我", "ru_RU": "Запомнить меня", "fa_IR": "مرا به خاطر بسپار", "vi_VN": "Ghi nhớ", "km_KH": "ចាំខ្ញុំ", "my_MM": "မှတ်ထား"},
    "No account? Register now": {"zh_CN": "没有账号？立即注册", "zh_TW": "沒有帳號？立即註冊", "ru_RU": "Нет аккаунта? Зарегистрируйтесь", "fa_IR": "حساب کاربری ندارید؟ ثبت نام کنید", "vi_VN": "Chưa có? Đăng ký", "km_KH": "គ្មានគណនី? ចុះឈ្មោះ", "my_MM": "မရှိ? အကောင့်ဖွင့်"},

    # Register form
    "Create Account": {"zh_CN": "创建账号", "zh_TW": "建立帳號", "ru_RU": "Создать аккаунт", "fa_IR": "ایجاد حساب", "vi_VN": "Tạo tài khoản", "km_KH": "បង្កើតគណនី", "my_MM": "အကောင့်ဖွင့်"},
    "Verification Code": {"zh_CN": "验证码", "zh_TW": "驗證碼", "ru_RU": "Код подтверждения", "fa_IR": "کد تایید", "vi_VN": "Mã xác nhận", "km_KH": "លេខកូដផ្ទៀងផ្ទាត់", "my_MM": "အတည်ပြုကုဒ်"},
    "Send Code": {"zh_CN": "发送验证码", "zh_TW": "發送驗證碼", "ru_RU": "Отправить код", "fa_IR": "ارسال کد", "vi_VN": "Gửi mã", "km_KH": "ផ្ញើលេខកូដ", "my_MM": "ကုဒ်ပို့"},
    "Resend": {"zh_CN": "重新发送", "zh_TW": "重新發送", "ru_RU": "Отправить снова", "fa_IR": "ارسال مجدد", "vi_VN": "Gửi lại", "km_KH": "ផ្ញើម្ដងទៀត", "my_MM": "ပြန်ပို့"},
    "Already have an account? Sign in": {"zh_CN": "已有账号？立即登录", "zh_TW": "已有帳號？立即登入", "ru_RU": "Уже есть аккаунт? Войти", "fa_IR": "حساب کاربری دارید؟ وارد شوید", "vi_VN": "Đã có? Đăng nhập", "km_KH": "មានគណនី? ចូល", "my_MM": "ရှိပြီး? ဝင်မည်"},
    "Invite Code (Optional)": {"zh_CN": "邀请码（可选）", "zh_TW": "邀請碼（選填）", "ru_RU": "Код приглашения (необязательно)", "fa_IR": "کد دعوت (اختیاری)", "vi_VN": "Mã mời", "km_KH": "លេខកូដអញ្ជើញ", "my_MM": "ဖိတ်ကုဒ်"},

    # Forgot password
    "Reset Password": {"zh_CN": "重置密码", "zh_TW": "重設密碼", "ru_RU": "Сбросить пароль", "fa_IR": "بازیابی رمز عبور", "vi_VN": "Đặt lại mật khẩu", "km_KH": "កំណត់ឡើងវិញ", "my_MM": "စကားဝှက်ပြန်သတ်မှတ်"},
    "Enter your email to reset password": {"zh_CN": "输入邮箱以重置密码", "zh_TW": "輸入電子郵件以重設密碼", "ru_RU": "Введите email для сброса пароля", "fa_IR": "ایمیل خود را برای بازیابی رمز وارد کنید", "vi_VN": "Nhập email", "km_KH": "បញ្ចូលអ៊ីមែល", "my_MM": "အီးမေးလ်ရိုက်"},
    "Back": {"zh_CN": "返回", "zh_TW": "返回", "ru_RU": "Назад", "fa_IR": "بازگشت", "vi_VN": "Quay lại", "km_KH": "ត្រឡប់", "my_MM": "နောက်သို့"},

    # Error messages
    "Error": {"zh_CN": "错误", "zh_TW": "錯誤", "ru_RU": "Ошибка", "fa_IR": "خطا", "vi_VN": "Lỗi", "km_KH": "កំហុស", "my_MM": "အမှား"},
    "Success": {"zh_CN": "成功", "zh_TW": "成功", "ru_RU": "Успешно", "fa_IR": "موفقیت", "vi_VN": "Thành công", "km_KH": "ជោគជ័យ", "my_MM": "အောင်မြင်"},
    "Warning": {"zh_CN": "警告", "zh_TW": "警告", "ru_RU": "Предупреждение", "fa_IR": "هشدار", "vi_VN": "Cảnh báo", "km_KH": "ការព្រមាន", "my_MM": "သတိပေး"},
    "Info": {"zh_CN": "信息", "zh_TW": "資訊", "ru_RU": "Информация", "fa_IR": "اطلاعات", "vi_VN": "Thông tin", "km_KH": "ព័ត៌មាន", "my_MM": "အချက်အလက်"},
    "Network error": {"zh_CN": "网络错误", "zh_TW": "網路錯誤", "ru_RU": "Ошибка сети", "fa_IR": "خطای شبکه", "vi_VN": "Lỗi mạng", "km_KH": "កំហុសបណ្ដាញ", "my_MM": "ကွန်ရက်အမှား"},
    "Connection failed": {"zh_CN": "连接失败", "zh_TW": "連接失敗", "ru_RU": "Ошибка подключения", "fa_IR": "اتصال ناموفق", "vi_VN": "Kết nối thất bại", "km_KH": "ការភ្ជាប់បរាជ័យ", "my_MM": "ချိတ်ဆက်မအောင်"},
    "Login failed": {"zh_CN": "登录失败", "zh_TW": "登入失敗", "ru_RU": "Ошибка входа", "fa_IR": "ورود ناموفق", "vi_VN": "Đăng nhập thất bại", "km_KH": "ចូលបរាជ័យ", "my_MM": "ဝင်မအောင်"},
    "Registration failed": {"zh_CN": "注册失败", "zh_TW": "註冊失敗", "ru_RU": "Ошибка регистрации", "fa_IR": "ثبت نام ناموفق", "vi_VN": "Đăng ký thất bại", "km_KH": "ចុះឈ្មោះបរាជ័យ", "my_MM": "စာရင်းသွင်းမအောင်"},
    "Invalid email or password": {"zh_CN": "邮箱或密码错误", "zh_TW": "電子郵件或密碼錯誤", "ru_RU": "Неверный email или пароль", "fa_IR": "ایمیل یا رمز عبور نادرست", "vi_VN": "Email hoặc mật khẩu sai", "km_KH": "អ៊ីមែល ឬលេខសម្ងាត់មិនត្រឹមត្រូវ", "my_MM": "အီးမေးလ် သို့ စကားဝှက်မှား"},
    "Email or password cannot be empty": {"zh_CN": "邮箱或密码不能为空", "zh_TW": "電子郵件或密碼不能為空", "ru_RU": "Email или пароль не могут быть пустыми", "fa_IR": "ایمیل یا رمز عبور نمی‌تواند خالی باشد", "vi_VN": "Email hoặc mật khẩu trống", "km_KH": "អ៊ីមែល ឬលេខសម្ងាត់មិនអាចទទេ", "my_MM": "အီးမေးလ် သို့ စကားဝှက်ဖြည့်ပါ"},
    "Email and password cannot be empty": {"zh_CN": "邮箱和密码不能为空", "zh_TW": "電子郵件和密碼不能為空", "ru_RU": "Email и пароль не могут быть пустыми", "fa_IR": "ایمیل و رمز عبور نمی‌توانند خالی باشند", "vi_VN": "Email và mật khẩu trống", "km_KH": "អ៊ីមែល និងលេខសម្ងាត់មិនអាចទទេ", "my_MM": "အီးမေးလ်နှင့် စကားဝှက်ဖြည့်ပါ"},
    "Email cannot be empty": {"zh_CN": "邮箱不能为空", "zh_TW": "電子郵件不能為空", "ru_RU": "Email не может быть пустым", "fa_IR": "ایمیل نمی‌تواند خالی باشد", "vi_VN": "Email không được trống", "km_KH": "អ៊ីមែលមិនអាចទទេ", "my_MM": "အီးမေးလ်ဖြည့်ပါ"},
    "Password cannot be empty": {"zh_CN": "密码不能为空", "zh_TW": "密碼不能為空", "ru_RU": "Пароль не может быть пустым", "fa_IR": "رمز عبور نمی‌تواند خالی باشد", "vi_VN": "Mật khẩu không được trống", "km_KH": "លេខសម្ងាត់មិនអាចទទេ", "my_MM": "စကားဝှက်ဖြည့်ပါ"},
    "Not logged in": {"zh_CN": "未登录", "zh_TW": "未登入", "ru_RU": "Не авторизован", "fa_IR": "وارد نشده‌اید", "vi_VN": "Chưa đăng nhập", "km_KH": "មិនទាន់ចូល", "my_MM": "မဝင်ရသေး"},
    "Server response format error: missing token": {"zh_CN": "服务器响应格式错误：缺少令牌", "zh_TW": "伺服器回應格式錯誤：缺少令牌", "ru_RU": "Ошибка формата ответа: отсутствует токен", "fa_IR": "خطای فرمت پاسخ سرور: توکن وجود ندارد", "vi_VN": "Lỗi máy chủ: thiếu token", "km_KH": "កំហុសម៉ាស៊ីនមេ: គ្មាន token", "my_MM": "ဆာဗာအမှား: token မရှိ"},
    "User info parse failed": {"zh_CN": "用户信息解析失败", "zh_TW": "使用者資訊解析失敗", "ru_RU": "Ошибка разбора данных пользователя", "fa_IR": "خطا در تحلیل اطلاعات کاربر", "vi_VN": "Lỗi phân tích thông tin", "km_KH": "កំហុសវិភាគព័ត៌មាន", "my_MM": "အချက်အလက်မှား"},
    "User info invalid or incomplete": {"zh_CN": "用户信息无效或不完整", "zh_TW": "使用者資訊無效或不完整", "ru_RU": "Данные пользователя недействительны", "fa_IR": "اطلاعات کاربر نامعتبر یا ناقص است", "vi_VN": "Thông tin không hợp lệ", "km_KH": "ព័ត៌មានមិនត្រឹមត្រូវ", "my_MM": "အချက်အလက်မမှန်"},
    "Subscription information is empty": {"zh_CN": "订阅信息为空", "zh_TW": "訂閱資訊為空", "ru_RU": "Информация о подписке пуста", "fa_IR": "اطلاعات اشتراک خالی است", "vi_VN": "Thông tin đăng ký trống", "km_KH": "ព័ត៌មានការជាវទទេ", "my_MM": "စာရင်းအချက်အလက်မရှိ"},
    "Server response data format error": {"zh_CN": "服务器返回的数据格式错误", "zh_TW": "伺服器返回的資料格式錯誤", "ru_RU": "Ошибка формата данных от сервера", "fa_IR": "خطای فرمت داده‌های سرور", "vi_VN": "Lỗi định dạng máy chủ", "km_KH": "កំហុសទម្រង់ម៉ាស៊ីនមេ", "my_MM": "ဆာဗာပုံစံမှား"},
    "Email, verification code and new password cannot be empty": {"zh_CN": "邮箱、验证码和新密码不能为空", "zh_TW": "電子郵件、驗證碼和新密碼不能為空", "ru_RU": "Email, код и новый пароль не могут быть пустыми", "fa_IR": "ایمیل، کد تایید و رمز جدید نمی‌توانند خالی باشند", "vi_VN": "Điền đầy đủ thông tin", "km_KH": "បំពេញព័ត៌មានទាំងអស់", "my_MM": "အားလုံးဖြည့်ပါ"},
    "My Subscription": {"zh_CN": "我的订阅", "zh_TW": "我的訂閱", "ru_RU": "Моя подписка", "fa_IR": "اشتراک من", "vi_VN": "Đăng ký của tôi", "km_KH": "ការជាវរបស់ខ្ញុំ", "my_MM": "ကျွန်ုပ်စာရင်း"},

    # About dialog
    "About JinGoVPN": {"zh_CN": "关于 JinGoVPN", "zh_TW": "關於 JinGoVPN", "ru_RU": "О JinGoVPN", "fa_IR": "درباره JinGoVPN", "vi_VN": "Về JinGoVPN", "km_KH": "អំពី JinGoVPN", "my_MM": "JinGoVPN အကြောင်း"},
    "JinGoVPN Client": {"zh_CN": "JinGoVPN 客户端", "zh_TW": "JinGoVPN 用戶端", "ru_RU": "Клиент JinGoVPN", "fa_IR": "کلاینت JinGoVPN", "vi_VN": "JinGoVPN Client", "km_KH": "JinGoVPN Client", "my_MM": "JinGoVPN Client"},
    "Version: 1.0.0": {"zh_CN": "版本：1.0.0", "zh_TW": "版本：1.0.0", "ru_RU": "Версия: 1.0.0", "fa_IR": "نسخه: 1.0.0", "vi_VN": "Phiên bản: 1.0.0", "km_KH": "កំណែ: 1.0.0", "my_MM": "ဗားရှင်း: 1.0.0"},
    "Powered by: Xray Core, Qt/QML": {"zh_CN": "技术支持：Xray Core、Qt/QML", "zh_TW": "技術支援：Xray Core、Qt/QML", "ru_RU": "На базе: Xray Core, Qt/QML", "fa_IR": "قدرت گرفته از: Xray Core، Qt/QML", "vi_VN": "Xray Core, Qt/QML", "km_KH": "Xray Core, Qt/QML", "my_MM": "Xray Core, Qt/QML"},
    "© 2024 JinGo Team. All rights reserved.": {"zh_CN": "© 2024 JinGo Team. All rights reserved.", "zh_TW": "© 2024 JinGo Team. All rights reserved.", "ru_RU": "© 2024 JinGo Team. Все права защищены.", "fa_IR": "© 2024 JinGo Team. تمامی حقوق محفوظ است.", "vi_VN": "© 2024 JinGo Team.", "km_KH": "© 2024 JinGo Team.", "my_MM": "© 2024 JinGo Team."},

    # Continents
    "Asia": {"zh_CN": "亚洲", "zh_TW": "亞洲", "ru_RU": "Азия", "fa_IR": "آسیا", "vi_VN": "Châu Á", "km_KH": "អាស៊ី", "my_MM": "အာရှ"},
    "Europe": {"zh_CN": "欧洲", "zh_TW": "歐洲", "ru_RU": "Европа", "fa_IR": "اروپا", "vi_VN": "Châu Âu", "km_KH": "អឺរ៉ុប", "my_MM": "ဥရောပ"},
    "North America": {"zh_CN": "北美洲", "zh_TW": "北美洲", "ru_RU": "Северная Америка", "fa_IR": "آمریکای شمالی", "vi_VN": "Bắc Mỹ", "km_KH": "អាមេរិកខាងជើង", "my_MM": "မြောက်အမေရိက"},
    "South America": {"zh_CN": "南美洲", "zh_TW": "南美洲", "ru_RU": "Южная Америка", "fa_IR": "آمریکای جنوبی", "vi_VN": "Nam Mỹ", "km_KH": "អាមេរិកខាងត្បូង", "my_MM": "တောင်အမေရိက"},
    "Africa": {"zh_CN": "非洲", "zh_TW": "非洲", "ru_RU": "Африка", "fa_IR": "آفریقا", "vi_VN": "Châu Phi", "km_KH": "អាហ្រ្វិក", "my_MM": "အာဖရိက"},
    "Oceania": {"zh_CN": "大洋洲", "zh_TW": "大洋洲", "ru_RU": "Океания", "fa_IR": "اقیانوسیه", "vi_VN": "Châu Đại Dương", "km_KH": "អូសេអានី", "my_MM": "သမုဒ္ဒရာ"},
    "Other": {"zh_CN": "其他", "zh_TW": "其他", "ru_RU": "Другое", "fa_IR": "سایر", "vi_VN": "Khác", "km_KH": "ផ្សេងទៀត", "my_MM": "အခြား"},

    # Misc
    "Cancel": {"zh_CN": "取消", "zh_TW": "取消", "ru_RU": "Отмена", "fa_IR": "لغو", "vi_VN": "Hủy", "km_KH": "បោះបង់", "my_MM": "ပယ်ဖျက်"},
    "OK": {"zh_CN": "确定", "zh_TW": "確定", "ru_RU": "ОК", "fa_IR": "تایید", "vi_VN": "OK", "km_KH": "យល់ព្រម", "my_MM": "အိုကေ"},
    "Confirm": {"zh_CN": "确认", "zh_TW": "確認", "ru_RU": "Подтвердить", "fa_IR": "تایید", "vi_VN": "Xác nhận", "km_KH": "បញ្ជាក់", "my_MM": "အတည်ပြု"},
    "Save": {"zh_CN": "保存", "zh_TW": "儲存", "ru_RU": "Сохранить", "fa_IR": "ذخیره", "vi_VN": "Lưu", "km_KH": "រក្សាទុក", "my_MM": "သိမ်း"},
    "Delete": {"zh_CN": "删除", "zh_TW": "刪除", "ru_RU": "Удалить", "fa_IR": "حذف", "vi_VN": "Xóa", "km_KH": "លុប", "my_MM": "ဖျက်"},
    "Edit": {"zh_CN": "编辑", "zh_TW": "編輯", "ru_RU": "Редактировать", "fa_IR": "ویرایش", "vi_VN": "Sửa", "km_KH": "កែសម្រួល", "my_MM": "တည်းဖြတ်"},
    "Close": {"zh_CN": "关闭", "zh_TW": "關閉", "ru_RU": "Закрыть", "fa_IR": "بستن", "vi_VN": "Đóng", "km_KH": "បិទ", "my_MM": "ပိတ်"},
    "Yes": {"zh_CN": "是", "zh_TW": "是", "ru_RU": "Да", "fa_IR": "بله", "vi_VN": "Có", "km_KH": "បាទ/ចាស", "my_MM": "ဟုတ်"},
    "No": {"zh_CN": "否", "zh_TW": "否", "ru_RU": "Нет", "fa_IR": "خیر", "vi_VN": "Không", "km_KH": "ទេ", "my_MM": "မဟုတ်"},
    "Loading...": {"zh_CN": "加载中...", "zh_TW": "載入中...", "ru_RU": "Загрузка...", "fa_IR": "در حال بارگذاری...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "Please wait...": {"zh_CN": "请稍候...", "zh_TW": "請稍候...", "ru_RU": "Пожалуйста, подождите...", "fa_IR": "لطفا صبر کنید...", "vi_VN": "Vui lòng đợi...", "km_KH": "សូមរង់ចាំ...", "my_MM": "စောင့်ပါ..."},
    "Retry": {"zh_CN": "重试", "zh_TW": "重試", "ru_RU": "Повторить", "fa_IR": "تلاش مجدد", "vi_VN": "Thử lại", "km_KH": "ព្យាយាមម្ដងទៀត", "my_MM": "ထပ်စမ်း"},
    "Unknown": {"zh_CN": "未知", "zh_TW": "未知", "ru_RU": "Неизвестно", "fa_IR": "ناشناخته", "vi_VN": "Không rõ", "km_KH": "មិនដឹង", "my_MM": "မသိ"},
    "None": {"zh_CN": "无", "zh_TW": "無", "ru_RU": "Нет", "fa_IR": "هیچ", "vi_VN": "Không", "km_KH": "គ្មាន", "my_MM": "မရှိ"},
    "All": {"zh_CN": "全部", "zh_TW": "全部", "ru_RU": "Все", "fa_IR": "همه", "vi_VN": "Tất cả", "km_KH": "ទាំងអស់", "my_MM": "အားလုံး"},
    "Select": {"zh_CN": "选择", "zh_TW": "選擇", "ru_RU": "Выбрать", "fa_IR": "انتخاب", "vi_VN": "Chọn", "km_KH": "ជ្រើសរើស", "my_MM": "ရွေး"},
    "Clear": {"zh_CN": "清除", "zh_TW": "清除", "ru_RU": "Очистить", "fa_IR": "پاک کردن", "vi_VN": "Xóa", "km_KH": "សម្អាត", "my_MM": "ရှင်း"},
    "Add": {"zh_CN": "添加", "zh_TW": "新增", "ru_RU": "Добавить", "fa_IR": "افزودن", "vi_VN": "Thêm", "km_KH": "បន្ថែម", "my_MM": "ထည့်"},
    "Remove": {"zh_CN": "移除", "zh_TW": "移除", "ru_RU": "Удалить", "fa_IR": "حذف", "vi_VN": "Xóa", "km_KH": "ដកចេញ", "my_MM": "ဖယ်"},
    "Enable": {"zh_CN": "启用", "zh_TW": "啟用", "ru_RU": "Включить", "fa_IR": "فعال", "vi_VN": "Bật", "km_KH": "បើក", "my_MM": "ဖွင့်"},
    "Disable": {"zh_CN": "禁用", "zh_TW": "停用", "ru_RU": "Отключить", "fa_IR": "غیرفعال", "vi_VN": "Tắt", "km_KH": "បិទ", "my_MM": "ပိတ်"},
    "On": {"zh_CN": "开", "zh_TW": "開", "ru_RU": "Вкл.", "fa_IR": "روشن", "vi_VN": "Bật", "km_KH": "បើក", "my_MM": "ဖွင့်"},
    "Default": {"zh_CN": "默认", "zh_TW": "預設", "ru_RU": "По умолчанию", "fa_IR": "پیش‌فرض", "vi_VN": "Mặc định", "km_KH": "លំនាំដើម", "my_MM": "မူရင်း"},
    "Auto": {"zh_CN": "自动", "zh_TW": "自動", "ru_RU": "Авто", "fa_IR": "خودکار", "vi_VN": "Tự động", "km_KH": "ស្វ័យប្រវត្តិ", "my_MM": "အလိုအလျောက်"},
    "Manual": {"zh_CN": "手动", "zh_TW": "手動", "ru_RU": "Вручную", "fa_IR": "دستی", "vi_VN": "Thủ công", "km_KH": "ដោយដៃ", "my_MM": "လက်ဖြင့်"},
    "Custom": {"zh_CN": "自定义", "zh_TW": "自訂", "ru_RU": "Пользовательский", "fa_IR": "سفارشی", "vi_VN": "Tùy chỉnh", "km_KH": "កែសម្រួល", "my_MM": "စိတ်ကြိုက်"},
    "Apply": {"zh_CN": "应用", "zh_TW": "套用", "ru_RU": "Применить", "fa_IR": "اعمال", "vi_VN": "Áp dụng", "km_KH": "អនុវត្ត", "my_MM": "အသုံးချ"},
    "Reset": {"zh_CN": "重置", "zh_TW": "重設", "ru_RU": "Сбросить", "fa_IR": "بازنشانی", "vi_VN": "Đặt lại", "km_KH": "កំណត់ឡើងវិញ", "my_MM": "ပြန်သတ်မှတ်"},
    "Details": {"zh_CN": "详情", "zh_TW": "詳情", "ru_RU": "Подробности", "fa_IR": "جزئیات", "vi_VN": "Chi tiết", "km_KH": "លម្អិត", "my_MM": "အသေးစိတ်"},
    "More": {"zh_CN": "更多", "zh_TW": "更多", "ru_RU": "Ещё", "fa_IR": "بیشتر", "vi_VN": "Thêm", "km_KH": "ច្រើនទៀត", "my_MM": "ထပ်ကြည့်"},
    "Less": {"zh_CN": "收起", "zh_TW": "收起", "ru_RU": "Меньше", "fa_IR": "کمتر", "vi_VN": "Ẩn bớt", "km_KH": "តិច", "my_MM": "ချုံ့"},
    "Help": {"zh_CN": "帮助", "zh_TW": "說明", "ru_RU": "Справка", "fa_IR": "کمک", "vi_VN": "Trợ giúp", "km_KH": "ជំនួយ", "my_MM": "အကူအညီ"},
    "Support": {"zh_CN": "支持", "zh_TW": "支援", "ru_RU": "Поддержка", "fa_IR": "پشتیبانی", "vi_VN": "Hỗ trợ", "km_KH": "គាំទ្រ", "my_MM": "ပံ့ပိုး"},
    "Feedback": {"zh_CN": "反馈", "zh_TW": "意見反映", "ru_RU": "Обратная связь", "fa_IR": "بازخورد", "vi_VN": "Phản hồi", "km_KH": "មតិកែលម្អ", "my_MM": "တုံ့ပြန်"},
    "Privacy Policy": {"zh_CN": "隐私政策", "zh_TW": "隱私權政策", "ru_RU": "Политика конфиденциальности", "fa_IR": "سیاست حفظ حریم خصوصی", "vi_VN": "Chính sách", "km_KH": "គោលការណ៍ឯកជន", "my_MM": "ကိုယ်ရေးမူဝါဒ"},
    "Terms of Service": {"zh_CN": "服务条款", "zh_TW": "服務條款", "ru_RU": "Условия использования", "fa_IR": "شرایط خدمات", "vi_VN": "Điều khoản", "km_KH": "ល័ក្ខខ័ណ្ឌ", "my_MM": "စည်းမျဉ်း"},

    # New password fields
    "Enter current password": {"zh_CN": "输入当前密码", "zh_TW": "輸入當前密碼", "ru_RU": "Введите текущий пароль", "fa_IR": "رمز عبور فعلی را وارد کنید", "vi_VN": "Nhập mật khẩu hiện tại", "km_KH": "បញ្ចូលលេខសម្ងាត់បច្ចុប្បន្ន", "my_MM": "လက်ရှိစကားဝှက်ရိုက်"},
    "Enter new password (min 6 chars)": {"zh_CN": "输入新密码（至少6位）", "zh_TW": "輸入新密碼（至少6位）", "ru_RU": "Введите новый пароль (мин. 6 символов)", "fa_IR": "رمز جدید را وارد کنید (حداقل 6 کاراکتر)", "vi_VN": "Nhập mật khẩu mới (ít nhất 6 ký tự)", "km_KH": "បញ្ចូលលេខសម្ងាត់ថ្មី (យ៉ាងតិច ៦)", "my_MM": "စကားဝှက်အသစ် (အနည်းဆုံး ၆)"},
    "• Password must be at least 6 characters": {"zh_CN": "• 密码至少6个字符", "zh_TW": "• 密碼至少6個字元", "ru_RU": "• Пароль минимум 6 символов", "fa_IR": "• رمز عبور باید حداقل 6 کاراکتر باشد", "vi_VN": "• Ít nhất 6 ký tự", "km_KH": "• យ៉ាងតិច ៦ តួអក្សរ", "my_MM": "• အနည်းဆုံး ၆ လုံး"},
    "Saving...": {"zh_CN": "保存中...", "zh_TW": "儲存中...", "ru_RU": "Сохранение...", "fa_IR": "در حال ذخیره...", "vi_VN": "Đang lưu...", "km_KH": "កំពុងរក្សាទុក...", "my_MM": "သိမ်းနေ..."},
    "Please enter current password": {"zh_CN": "请输入当前密码", "zh_TW": "請輸入當前密碼", "ru_RU": "Введите текущий пароль", "fa_IR": "لطفا رمز عبور فعلی را وارد کنید", "vi_VN": "Nhập mật khẩu hiện tại", "km_KH": "បញ្ចូលលេខសម្ងាត់បច្ចុប្បន្ន", "my_MM": "လက်ရှိစကားဝှက်ရိုက်"},
    "Please enter new password": {"zh_CN": "请输入新密码", "zh_TW": "請輸入新密碼", "ru_RU": "Введите новый пароль", "fa_IR": "لطفا رمز عبور جدید را وارد کنید", "vi_VN": "Nhập mật khẩu mới", "km_KH": "បញ្ចូលលេខសម្ងាត់ថ្មី", "my_MM": "စကားဝှက်အသစ်ရိုက်"},
    "New password must be at least 6 characters": {"zh_CN": "新密码至少6个字符", "zh_TW": "新密碼至少6個字元", "ru_RU": "Новый пароль минимум 6 символов", "fa_IR": "رمز عبور جدید باید حداقل 6 کاراکتر باشد", "vi_VN": "Ít nhất 6 ký tự", "km_KH": "យ៉ាងតិច ៦ តួអក្សរ", "my_MM": "အနည်းဆုံး ၆ လုံး"},

    # Latency history
    "Latency History": {"zh_CN": "延迟历史", "zh_TW": "延遲歷史", "ru_RU": "История задержки", "fa_IR": "تاریخچه تاخیر", "vi_VN": "Lịch sử độ trễ", "km_KH": "ប្រវត្តិការពន្យឺត", "my_MM": "နှောင့်နှေးမှုမှတ်တမ်း"},

    # VPN/Proxy modes
    "VPN/Proxy": {"zh_CN": "VPN/代理", "zh_TW": "VPN/代理", "ru_RU": "VPN/Прокси", "fa_IR": "VPN/پروکسی", "vi_VN": "VPN/Proxy", "km_KH": "VPN/Proxy", "my_MM": "VPN/Proxy"},
    "Traffic routing": {"zh_CN": "流量路由", "zh_TW": "流量路由", "ru_RU": "Маршрутизация трафика", "fa_IR": "مسیریابی ترافیک", "vi_VN": "Định tuyến", "km_KH": "ផ្លូវចរាចរ", "my_MM": "လမ်းကြောင်း"},

    # Countries
    "United States": {"zh_CN": "美国", "zh_TW": "美國", "ru_RU": "США", "fa_IR": "ایالات متحده", "vi_VN": "Hoa Kỳ", "km_KH": "សហរដ្ឋអាមេរិក", "my_MM": "အမေရိကန်"},
    "United Kingdom": {"zh_CN": "英国", "zh_TW": "英國", "ru_RU": "Великобритания", "fa_IR": "بریتانیا", "vi_VN": "Anh", "km_KH": "ចក្រភពអង់គ្លេស", "my_MM": "ဗြိတိန်"},
    "Japan": {"zh_CN": "日本", "zh_TW": "日本", "ru_RU": "Япония", "fa_IR": "ژاپن", "vi_VN": "Nhật Bản", "km_KH": "ជប៉ុន", "my_MM": "ဂျပန်"},
    "South Korea": {"zh_CN": "韩国", "zh_TW": "韓國", "ru_RU": "Южная Корея", "fa_IR": "کره جنوبی", "vi_VN": "Hàn Quốc", "km_KH": "កូរ៉េខាងត្បូង", "my_MM": "တောင်ကိုရီးယား"},
    "Hong Kong": {"zh_CN": "香港", "zh_TW": "香港", "ru_RU": "Гонконг", "fa_IR": "هنگ کنگ", "vi_VN": "Hồng Kông", "km_KH": "ហុងកុង", "my_MM": "ဟောင်ကောင်"},
    "Taiwan": {"zh_CN": "台湾", "zh_TW": "台灣", "ru_RU": "Тайвань", "fa_IR": "تایوان", "vi_VN": "Đài Loan", "km_KH": "តៃវ៉ាន់", "my_MM": "ထိုင်ဝမ်"},
    "Singapore": {"zh_CN": "新加坡", "zh_TW": "新加坡", "ru_RU": "Сингапур", "fa_IR": "سنگاپور", "vi_VN": "Singapore", "km_KH": "សិង្ហបុរី", "my_MM": "စင်္ကာပူ"},
    "Germany": {"zh_CN": "德国", "zh_TW": "德國", "ru_RU": "Германия", "fa_IR": "آلمان", "vi_VN": "Đức", "km_KH": "អាល្លឺម៉ង់", "my_MM": "ဂျာမနီ"},
    "France": {"zh_CN": "法国", "zh_TW": "法國", "ru_RU": "Франция", "fa_IR": "فرانسه", "vi_VN": "Pháp", "km_KH": "បារាំង", "my_MM": "ပြင်သစ်"},
    "Canada": {"zh_CN": "加拿大", "zh_TW": "加拿大", "ru_RU": "Канада", "fa_IR": "کانادا", "vi_VN": "Canada", "km_KH": "កាណាដា", "my_MM": "ကနေဒါ"},
    "Australia": {"zh_CN": "澳大利亚", "zh_TW": "澳洲", "ru_RU": "Австралия", "fa_IR": "استرالیا", "vi_VN": "Úc", "km_KH": "អូស្ត្រាលី", "my_MM": "သြစတြေးလျ"},
    "India": {"zh_CN": "印度", "zh_TW": "印度", "ru_RU": "Индия", "fa_IR": "هند", "vi_VN": "Ấn Độ", "km_KH": "ឥណ្ឌា", "my_MM": "အိန္ဒိယ"},
    "Brazil": {"zh_CN": "巴西", "zh_TW": "巴西", "ru_RU": "Бразилия", "fa_IR": "برزیل", "vi_VN": "Brazil", "km_KH": "ប្រេស៊ីល", "my_MM": "ဘရာဇီး"},
    "Netherlands": {"zh_CN": "荷兰", "zh_TW": "荷蘭", "ru_RU": "Нидерланды", "fa_IR": "هلند", "vi_VN": "Hà Lan", "km_KH": "ហូឡង់", "my_MM": "နယ်သာလန်"},
    "Sweden": {"zh_CN": "瑞典", "zh_TW": "瑞典", "ru_RU": "Швеция", "fa_IR": "سوئد", "vi_VN": "Thụy Điển", "km_KH": "ស៊ុយអែត", "my_MM": "ဆွီဒင်"},
    "Switzerland": {"zh_CN": "瑞士", "zh_TW": "瑞士", "ru_RU": "Швейцария", "fa_IR": "سوئیس", "vi_VN": "Thụy Sĩ", "km_KH": "ស្វីស", "my_MM": "ဆွစ်ဇာလန်"},
    "Italy": {"zh_CN": "意大利", "zh_TW": "義大利", "ru_RU": "Италия", "fa_IR": "ایتالیا", "vi_VN": "Ý", "km_KH": "អ៊ីតាលី", "my_MM": "အီတလီ"},
    "Spain": {"zh_CN": "西班牙", "zh_TW": "西班牙", "ru_RU": "Испания", "fa_IR": "اسپانیا", "vi_VN": "Tây Ban Nha", "km_KH": "អេស្ប៉ាញ", "my_MM": "စပိန်"},
    "Vietnam": {"zh_CN": "越南", "zh_TW": "越南", "ru_RU": "Вьетнам", "fa_IR": "ویتنام", "vi_VN": "Việt Nam", "km_KH": "វៀតណាម", "my_MM": "ဗီယက်နမ်"},
    "Cambodia": {"zh_CN": "柬埔寨", "zh_TW": "柬埔寨", "ru_RU": "Камбоджа", "fa_IR": "کامبوج", "vi_VN": "Campuchia", "km_KH": "កម្ពុជា", "my_MM": "ကမ္ဘောဒီးယား"},
    "Myanmar": {"zh_CN": "缅甸", "zh_TW": "緬甸", "ru_RU": "Мьянма", "fa_IR": "میانمار", "vi_VN": "Myanmar", "km_KH": "មីយ៉ាន់ម៉ា", "my_MM": "မြန်မာ"},

    # Help center
    "Help Center": {"zh_CN": "帮助中心", "zh_TW": "說明中心", "ru_RU": "Справочный центр", "fa_IR": "مرکز راهنما", "vi_VN": "Trợ giúp", "km_KH": "មជ្ឈមណ្ឌលជំនួយ", "my_MM": "အကူအညီ"},
    "Loading articles...": {"zh_CN": "正在加载文章...", "zh_TW": "正在載入文章...", "ru_RU": "Загрузка статей...", "fa_IR": "در حال بارگذاری مقالات...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "No articles available": {"zh_CN": "暂无文章", "zh_TW": "暫無文章", "ru_RU": "Статьи отсутствуют", "fa_IR": "مقاله‌ای موجود نیست", "vi_VN": "Không có bài viết", "km_KH": "គ្មានអត្ថបទ", "my_MM": "ဆောင်းပါးမရှိ"},
    "Help articles will appear here": {"zh_CN": "帮助文章将显示在这里", "zh_TW": "說明文章將顯示在這裡", "ru_RU": "Здесь появятся справочные статьи", "fa_IR": "مقالات راهنما در اینجا نمایش داده می‌شوند", "vi_VN": "Bài viết sẽ hiển thị ở đây", "km_KH": "អត្ថបទនឹងបង្ហាញនៅទីនេះ", "my_MM": "ဆောင်းပါးများပေါ်မည်"},
    "Untitled": {"zh_CN": "无标题", "zh_TW": "無標題", "ru_RU": "Без названия", "fa_IR": "بدون عنوان", "vi_VN": "Không có tiêu đề", "km_KH": "គ្មានចំណងជើង", "my_MM": "ခေါင်းစဉ်မရှိ"},
    "Loading article...": {"zh_CN": "正在加载文章...", "zh_TW": "正在載入文章...", "ru_RU": "Загрузка статьи...", "fa_IR": "در حال بارگذاری مقاله...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "Updated: ": {"zh_CN": "更新于：", "zh_TW": "更新於：", "ru_RU": "Обновлено: ", "fa_IR": "به‌روزرسانی: ", "vi_VN": "Cập nhật: ", "km_KH": "ធ្វើបច្ចុប្បន្នភាព: ", "my_MM": "အပ်ဒိတ်: "},

    # Email validation
    "Enter email": {"zh_CN": "输入邮箱", "zh_TW": "輸入電子郵件", "ru_RU": "Введите email", "fa_IR": "ایمیل را وارد کنید", "vi_VN": "Nhập email", "km_KH": "បញ្ចូលអ៊ីមែល", "my_MM": "အီးမေးလ်ရိုက်"},
    "Invalid email format": {"zh_CN": "邮箱格式无效", "zh_TW": "電子郵件格式無效", "ru_RU": "Неверный формат email", "fa_IR": "فرمت ایمیل نامعتبر است", "vi_VN": "Email không hợp lệ", "km_KH": "ទម្រង់អ៊ីមែលមិនត្រឹមត្រូវ", "my_MM": "အီးမေးလ်မမှန်"},

    # Order management
    "Order Management": {"zh_CN": "订单管理", "zh_TW": "訂單管理", "ru_RU": "Управление заказами", "fa_IR": "مدیریت سفارشات", "vi_VN": "Quản lý đơn hàng", "km_KH": "គ្រប់គ្រងការបញ្ជាទិញ", "my_MM": "အော်ဒါစီမံ"},
    "Order #%1": {"zh_CN": "订单 #%1", "zh_TW": "訂單 #%1", "ru_RU": "Заказ #%1", "fa_IR": "سفارش #%1", "vi_VN": "Đơn #%1", "km_KH": "ការបញ្ជាទិញ #%1", "my_MM": "အော်ဒါ #%1"},
    "Plan:": {"zh_CN": "套餐：", "zh_TW": "方案：", "ru_RU": "План:", "fa_IR": "طرح:", "vi_VN": "Gói:", "km_KH": "គម្រោង:", "my_MM": "အစီအစဉ်:"},
    "Unknown Plan": {"zh_CN": "未知套餐", "zh_TW": "未知方案", "ru_RU": "Неизвестный план", "fa_IR": "طرح نامشخص", "vi_VN": "Gói không xác định", "km_KH": "គម្រោងមិនស្គាល់", "my_MM": "မသိအစီအစဉ်"},
    "Amount:": {"zh_CN": "金额：", "zh_TW": "金額：", "ru_RU": "Сумма:", "fa_IR": "مبلغ:", "vi_VN": "Số tiền:", "km_KH": "ចំនួនទឹកប្រាក់:", "my_MM": "ပမာဏ:"},
    "Created:": {"zh_CN": "创建时间：", "zh_TW": "建立時間：", "ru_RU": "Создано:", "fa_IR": "ایجاد شده:", "vi_VN": "Tạo lúc:", "km_KH": "បង្កើតនៅ:", "my_MM": "ဖန်တီးချိန်:"},
    "Paid:": {"zh_CN": "支付时间：", "zh_TW": "付款時間：", "ru_RU": "Оплачено:", "fa_IR": "پرداخت شده:", "vi_VN": "Thanh toán:", "km_KH": "បានបង់:", "my_MM": "ပေးချေပြီး:"},
    "Cancel Order": {"zh_CN": "取消订单", "zh_TW": "取消訂單", "ru_RU": "Отменить заказ", "fa_IR": "لغو سفارش", "vi_VN": "Hủy đơn", "km_KH": "បោះបង់ការបញ្ជាទិញ", "my_MM": "အော်ဒါပယ်ဖျက်"},
    "Loading orders...": {"zh_CN": "正在加载订单...", "zh_TW": "正在載入訂單...", "ru_RU": "Загрузка заказов...", "fa_IR": "در حال بارگذاری سفارشات...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "No orders yet": {"zh_CN": "暂无订单", "zh_TW": "暫無訂單", "ru_RU": "Заказов пока нет", "fa_IR": "هنوز سفارشی نیست", "vi_VN": "Chưa có đơn hàng", "km_KH": "មិនទាន់មានការបញ្ជាទិញ", "my_MM": "အော်ဒါမရှိသေး"},
    "Your order history will appear here": {"zh_CN": "您的订单历史将显示在这里", "zh_TW": "您的訂單歷史將顯示在這裡", "ru_RU": "История заказов появится здесь", "fa_IR": "تاریخچه سفارشات شما در اینجا نمایش داده می‌شود", "vi_VN": "Lịch sử đơn hàng sẽ hiển thị ở đây", "km_KH": "ប្រវត្តិការបញ្ជាទិញនឹងបង្ហាញនៅទីនេះ", "my_MM": "အော်ဒါမှတ်တမ်းပေါ်မည်"},
    "OrderManager not available": {"zh_CN": "订单管理器不可用", "zh_TW": "訂單管理器不可用", "ru_RU": "Менеджер заказов недоступен", "fa_IR": "مدیریت سفارشات در دسترس نیست", "vi_VN": "Không khả dụng", "km_KH": "មិនអាចប្រើបាន", "my_MM": "မရရှိနိုင်"},

    # Order status
    "Pending Payment": {"zh_CN": "待支付", "zh_TW": "待付款", "ru_RU": "Ожидает оплаты", "fa_IR": "در انتظار پرداخت", "vi_VN": "Chờ thanh toán", "km_KH": "រង់ចាំការបង់ប្រាក់", "my_MM": "ငွေပေးရန်စောင့်"},
    "Processing": {"zh_CN": "处理中", "zh_TW": "處理中", "ru_RU": "Обработка", "fa_IR": "در حال پردازش", "vi_VN": "Đang xử lý", "km_KH": "កំពុងដំណើរការ", "my_MM": "ဆောင်ရွက်နေ"},
    "Cancelled": {"zh_CN": "已取消", "zh_TW": "已取消", "ru_RU": "Отменено", "fa_IR": "لغو شده", "vi_VN": "Đã hủy", "km_KH": "បានបោះបង់", "my_MM": "ပယ်ဖျက်ပြီး"},
    "Completed": {"zh_CN": "已完成", "zh_TW": "已完成", "ru_RU": "Завершено", "fa_IR": "تکمیل شده", "vi_VN": "Hoàn thành", "km_KH": "បានបញ្ចប់", "my_MM": "ပြီးစီး"},
    "Refunded": {"zh_CN": "已退款", "zh_TW": "已退款", "ru_RU": "Возвращено", "fa_IR": "بازپرداخت شده", "vi_VN": "Đã hoàn tiền", "km_KH": "បានសងប្រាក់វិញ", "my_MM": "ငွေပြန်ပေးပြီး"},
    "N/A": {"zh_CN": "无", "zh_TW": "無", "ru_RU": "Н/Д", "fa_IR": "ندارد", "vi_VN": "Không có", "km_KH": "គ្មាន", "my_MM": "မရှိ"},

    # Payment
    "Select Payment Method": {"zh_CN": "选择支付方式", "zh_TW": "選擇付款方式", "ru_RU": "Выберите способ оплаты", "fa_IR": "روش پرداخت را انتخاب کنید", "vi_VN": "Chọn thanh toán", "km_KH": "ជ្រើសវិធីបង់ប្រាក់", "my_MM": "ငွေပေးနည်းရွေး"},
    "Plan: %1 - %2%3": {"zh_CN": "套餐：%1 - %2%3", "zh_TW": "方案：%1 - %2%3", "ru_RU": "План: %1 - %2%3", "fa_IR": "طرح: %1 - %2%3", "vi_VN": "Gói: %1 - %2%3", "km_KH": "គម្រោង: %1 - %2%3", "my_MM": "အစီအစဉ်: %1 - %2%3"},
    "Unknown Method": {"zh_CN": "未知方式", "zh_TW": "未知方式", "ru_RU": "Неизвестный метод", "fa_IR": "روش نامشخص", "vi_VN": "Không xác định", "km_KH": "វិធីមិនស្គាល់", "my_MM": "မသိနည်းလမ်း"},
    "No payment methods available": {"zh_CN": "暂无可用支付方式", "zh_TW": "暫無可用付款方式", "ru_RU": "Нет доступных методов оплаты", "fa_IR": "روش پرداختی موجود نیست", "vi_VN": "Không có phương thức", "km_KH": "គ្មានវិធីបង់ប្រាក់", "my_MM": "ငွေပေးနည်းမရှိ"},
    "Processing payment...": {"zh_CN": "正在处理支付...", "zh_TW": "正在處理付款...", "ru_RU": "Обработка платежа...", "fa_IR": "در حال پردازش پرداخت...", "vi_VN": "Đang xử lý...", "km_KH": "កំពុងដំណើរការ...", "my_MM": "ဆောင်ရွက်နေ..."},

    # Additional strings from ts file
    "Global": {"zh_CN": "全球", "zh_TW": "全球", "ru_RU": "Глобальный", "fa_IR": "جهانی", "vi_VN": "Toàn cầu", "km_KH": "សកល", "my_MM": "ကမ္ဘာလုံး"},
    "Direct": {"zh_CN": "直连", "zh_TW": "直連", "ru_RU": "Напрямую", "fa_IR": "مستقیم", "vi_VN": "Trực tiếp", "km_KH": "ផ្ទាល់", "my_MM": "တိုက်ရိုက်"},
    "Smart": {"zh_CN": "智能", "zh_TW": "智慧", "ru_RU": "Умный", "fa_IR": "هوشمند", "vi_VN": "Thông minh", "km_KH": "ឆ្លាតវៃ", "my_MM": "စမတ်"},
    "AsIs": {"zh_CN": "保持原样", "zh_TW": "保持原樣", "ru_RU": "Как есть", "fa_IR": "همانطور که هست", "vi_VN": "Giữ nguyên", "km_KH": "ដូចដើម", "my_MM": "မူရင်းအတိုင်း"},
    "IPIfNonMatch": {"zh_CN": "无匹配时使用IP", "zh_TW": "無匹配時使用IP", "ru_RU": "IP если нет совпадения", "fa_IR": "IP در صورت عدم تطابق", "vi_VN": "IP nếu không khớp", "km_KH": "IP បើមិនផ្គូផ្គង", "my_MM": "မကိုက်လျှင် IP"},
    "IPOnDemand": {"zh_CN": "按需解析IP", "zh_TW": "按需解析IP", "ru_RU": "IP по требованию", "fa_IR": "IP در صورت نیاز", "vi_VN": "IP theo yêu cầu", "km_KH": "IP តម្រូវការ", "my_MM": "လိုအပ်ချိန် IP"},
    "IPv4Only": {"zh_CN": "仅IPv4", "zh_TW": "僅IPv4", "ru_RU": "Только IPv4", "fa_IR": "فقط IPv4", "vi_VN": "Chỉ IPv4", "km_KH": "IPv4 តែប៉ុណ្ណោះ", "my_MM": "IPv4 သာ"},
    "IPv6Only": {"zh_CN": "仅IPv6", "zh_TW": "僅IPv6", "ru_RU": "Только IPv6", "fa_IR": "فقط IPv6", "vi_VN": "Chỉ IPv6", "km_KH": "IPv6 តែប៉ុណ្ណោះ", "my_MM": "IPv6 သာ"},
    "PreferIPv4": {"zh_CN": "优先IPv4", "zh_TW": "優先IPv4", "ru_RU": "Предпочитать IPv4", "fa_IR": "ترجیح IPv4", "vi_VN": "Ưu tiên IPv4", "km_KH": "ផ្តល់អាទិភាព IPv4", "my_MM": "IPv4 ဦးစား"},
    "PreferIPv6": {"zh_CN": "优先IPv6", "zh_TW": "優先IPv6", "ru_RU": "Предпочитать IPv6", "fa_IR": "ترجیح IPv6", "vi_VN": "Ưu tiên IPv6", "km_KH": "ផ្តល់អាទិភាព IPv6", "my_MM": "IPv6 ဦးစား"},

    # Language names
    "Simplified Chinese": {"zh_CN": "简体中文", "zh_TW": "簡體中文", "ru_RU": "Упрощенный китайский", "fa_IR": "چینی ساده شده", "vi_VN": "Tiếng Trung giản thể", "km_KH": "ចិនសាមញ្ញ", "my_MM": "ရိုးရှင်းတရုတ်"},
    "Traditional Chinese": {"zh_CN": "繁体中文", "zh_TW": "繁體中文", "ru_RU": "Традиционный китайский", "fa_IR": "چینی سنتی", "vi_VN": "Tiếng Trung phồn thể", "km_KH": "ចិនប្រពៃណី", "my_MM": "ရိုးရာတရုတ်"},

    # More UI strings
    "Start on Boot": {"zh_CN": "开机启动", "zh_TW": "開機啟動", "ru_RU": "Запуск при загрузке", "fa_IR": "اجرا هنگام بوت", "vi_VN": "Khởi động cùng hệ thống", "km_KH": "ចាប់ផ្តើមពេលបើក", "my_MM": "စနစ်နှင့်စတင်"},
    "Automatically start application on system boot": {"zh_CN": "系统启动时自动启动应用", "zh_TW": "系統啟動時自動啟動應用", "ru_RU": "Автозапуск при старте системы", "fa_IR": "اجرای خودکار برنامه هنگام راه‌اندازی سیستم", "vi_VN": "Tự động khởi động", "km_KH": "ចាប់ផ្តើមស្វ័យប្រវត្តិ", "my_MM": "အလိုအလျောက်စတင်"},
    "Auto Connect": {"zh_CN": "自动连接", "zh_TW": "自動連接", "ru_RU": "Автоподключение", "fa_IR": "اتصال خودکار", "vi_VN": "Tự động kết nối", "km_KH": "ភ្ជាប់ស្វ័យប្រវត្តិ", "my_MM": "အလိုအလျောက်ချိတ်"},
    "Automatically connect when application starts": {"zh_CN": "应用启动时自动连接", "zh_TW": "應用啟動時自動連接", "ru_RU": "Автоподключение при запуске", "fa_IR": "اتصال خودکار هنگام اجرای برنامه", "vi_VN": "Kết nối khi khởi động", "km_KH": "ភ្ជាប់ពេលចាប់ផ្តើម", "my_MM": "စတင်ချိန်ချိတ်"},
    "Auto Update Servers": {"zh_CN": "自动更新服务器", "zh_TW": "自動更新伺服器", "ru_RU": "Автообновление серверов", "fa_IR": "به‌روزرسانی خودکار سرورها", "vi_VN": "Tự động cập nhật", "km_KH": "ធ្វើបច្ចុប្បន្នភាពស្វ័យប្រវត្តិ", "my_MM": "အလိုအလျောက်အပ်ဒိတ်"},
    "Automatically update server list on connect": {"zh_CN": "连接时自动更新服务器列表", "zh_TW": "連接時自動更新伺服器列表", "ru_RU": "Автообновление списка серверов", "fa_IR": "به‌روزرسانی خودکار لیست سرورها هنگام اتصال", "vi_VN": "Cập nhật khi kết nối", "km_KH": "ធ្វើបច្ចុប្បន្នភាពពេលភ្ជាប់", "my_MM": "ချိတ်ချိန်အပ်ဒိတ်"},

    # Connection status
    "Server: %1": {"zh_CN": "服务器：%1", "zh_TW": "伺服器：%1", "ru_RU": "Сервер: %1", "fa_IR": "سرور: %1", "vi_VN": "Máy chủ: %1", "km_KH": "ម៉ាស៊ីនមេ: %1", "my_MM": "ဆာဗာ: %1"},
    "Status: %1": {"zh_CN": "状态：%1", "zh_TW": "狀態：%1", "ru_RU": "Статус: %1", "fa_IR": "وضعیت: %1", "vi_VN": "Trạng thái: %1", "km_KH": "ស្ថានភាព: %1", "my_MM": "အခြေအနေ: %1"},
    "Initializing...": {"zh_CN": "初始化中...", "zh_TW": "初始化中...", "ru_RU": "Инициализация...", "fa_IR": "در حال راه‌اندازی...", "vi_VN": "Khởi tạo...", "km_KH": "កំពុងចាប់ផ្តើម...", "my_MM": "စတင်နေ..."},
    "Error: %1": {"zh_CN": "错误：%1", "zh_TW": "錯誤：%1", "ru_RU": "Ошибка: %1", "fa_IR": "خطا: %1", "vi_VN": "Lỗi: %1", "km_KH": "កំហុស: %1", "my_MM": "အမှား: %1"},

    # Version check
    "New version available!": {"zh_CN": "有新版本可用！", "zh_TW": "有新版本可用！", "ru_RU": "Доступна новая версия!", "fa_IR": "نسخه جدید موجود است!", "vi_VN": "Có phiên bản mới!", "km_KH": "មានកំណែថ្មី!", "my_MM": "ဗားရှင်းအသစ်ရှိ!"},
    "Version %1 is available. Would you like to update?": {"zh_CN": "版本 %1 可用。是否更新？", "zh_TW": "版本 %1 可用。是否更新？", "ru_RU": "Версия %1 доступна. Обновить?", "fa_IR": "نسخه %1 موجود است. آیا می‌خواهید به‌روزرسانی کنید؟", "vi_VN": "Phiên bản %1. Cập nhật?", "km_KH": "កំណែ %1។ ធ្វើបច្ចុប្បន្នភាព?", "my_MM": "ဗားရှင်း %1။ အပ်ဒိတ်လုပ်မလား?"},
    "Update Now": {"zh_CN": "立即更新", "zh_TW": "立即更新", "ru_RU": "Обновить сейчас", "fa_IR": "الان به‌روزرسانی کنید", "vi_VN": "Cập nhật ngay", "km_KH": "ធ្វើបច្ចុប្បន្នភាពឥឡូវ", "my_MM": "ယခုအပ်ဒိတ်"},
    "Later": {"zh_CN": "稍后", "zh_TW": "稍後", "ru_RU": "Позже", "fa_IR": "بعدا", "vi_VN": "Để sau", "km_KH": "ពេលក្រោយ", "my_MM": "နောက်မှ"},
    "You are running the latest version.": {"zh_CN": "您正在使用最新版本。", "zh_TW": "您正在使用最新版本。", "ru_RU": "У вас последняя версия.", "fa_IR": "شما آخرین نسخه را اجرا می‌کنید.", "vi_VN": "Bạn đang dùng phiên bản mới nhất.", "km_KH": "អ្នកកំពុងប្រើកំណែចុងក្រោយ។", "my_MM": "နောက်ဆုံးဗားရှင်းဖြစ်ပါပြီ။"},

    # Server groups
    "All Servers": {"zh_CN": "所有服务器", "zh_TW": "所有伺服器", "ru_RU": "Все серверы", "fa_IR": "همه سرورها", "vi_VN": "Tất cả máy chủ", "km_KH": "ម៉ាស៊ីនមេទាំងអស់", "my_MM": "ဆာဗာအားလုံး"},
    "Favorites": {"zh_CN": "收藏", "zh_TW": "收藏", "ru_RU": "Избранное", "fa_IR": "موردعلاقه‌ها", "vi_VN": "Yêu thích", "km_KH": "ចូលចិត្ត", "my_MM": "အကြိုက်ဆုံး"},
    "Recent": {"zh_CN": "最近", "zh_TW": "最近", "ru_RU": "Недавние", "fa_IR": "اخیر", "vi_VN": "Gần đây", "km_KH": "ថ្មីៗ", "my_MM": "မကြာသေး"},
    "Add to favorites": {"zh_CN": "添加到收藏", "zh_TW": "加入收藏", "ru_RU": "В избранное", "fa_IR": "افزودن به موردعلاقه‌ها", "vi_VN": "Thêm yêu thích", "km_KH": "បន្ថែមចូលចិត្ត", "my_MM": "အကြိုက်ထည့်"},
    "Remove from favorites": {"zh_CN": "从收藏移除", "zh_TW": "從收藏移除", "ru_RU": "Убрать из избранного", "fa_IR": "حذف از موردعلاقه‌ها", "vi_VN": "Xóa yêu thích", "km_KH": "ដកចូលចិត្ត", "my_MM": "အကြိုက်ဖယ်"},

    # Notifications
    "Notification": {"zh_CN": "通知", "zh_TW": "通知", "ru_RU": "Уведомление", "fa_IR": "اعلان", "vi_VN": "Thông báo", "km_KH": "ការជូនដំណឹង", "my_MM": "အကြောင်းကြား"},
    "Connection established": {"zh_CN": "连接已建立", "zh_TW": "連接已建立", "ru_RU": "Соединение установлено", "fa_IR": "اتصال برقرار شد", "vi_VN": "Đã kết nối", "km_KH": "បានភ្ជាប់", "my_MM": "ချိတ်ဆက်ပြီး"},
    "Connection lost": {"zh_CN": "连接已断开", "zh_TW": "連接已斷開", "ru_RU": "Соединение потеряно", "fa_IR": "اتصال قطع شد", "vi_VN": "Mất kết nối", "km_KH": "បាត់ការភ្ជាប់", "my_MM": "ချိတ်ဆက်ပြတ်"},

    # Misc additional
    "seconds": {"zh_CN": "秒", "zh_TW": "秒", "ru_RU": "сек.", "fa_IR": "ثانیه", "vi_VN": "giây", "km_KH": "វិនាទី", "my_MM": "စက္ကန့်"},
    "minutes": {"zh_CN": "分钟", "zh_TW": "分鐘", "ru_RU": "мин.", "fa_IR": "دقیقه", "vi_VN": "phút", "km_KH": "នាទី", "my_MM": "မိနစ်"},
    "hours": {"zh_CN": "小时", "zh_TW": "小時", "ru_RU": "ч.", "fa_IR": "ساعت", "vi_VN": "giờ", "km_KH": "ម៉ោង", "my_MM": "နာရီ"},
    "days": {"zh_CN": "天", "zh_TW": "天", "ru_RU": "дн.", "fa_IR": "روز", "vi_VN": "ngày", "km_KH": "ថ្ងៃ", "my_MM": "ရက်"},
    "ms": {"zh_CN": "毫秒", "zh_TW": "毫秒", "ru_RU": "мс", "fa_IR": "میلی‌ثانیه", "vi_VN": "ms", "km_KH": "មិល្លីវិនាទី", "my_MM": "ms"},

    # Server info
    "Server Name": {"zh_CN": "服务器名称", "zh_TW": "伺服器名稱", "ru_RU": "Имя сервера", "fa_IR": "نام سرور", "vi_VN": "Tên máy chủ", "km_KH": "ឈ្មោះម៉ាស៊ីនមេ", "my_MM": "ဆာဗာအမည်"},
    "Server Address": {"zh_CN": "服务器地址", "zh_TW": "伺服器地址", "ru_RU": "Адрес сервера", "fa_IR": "آدرس سرور", "vi_VN": "Địa chỉ máy chủ", "km_KH": "អាសយដ្ឋានម៉ាស៊ីនមេ", "my_MM": "ဆာဗာလိပ်စာ"},
    "Port": {"zh_CN": "端口", "zh_TW": "埠", "ru_RU": "Порт", "fa_IR": "پورت", "vi_VN": "Cổng", "km_KH": "ច្រក", "my_MM": "ပို့တ်"},
    "Protocol": {"zh_CN": "协议", "zh_TW": "協定", "ru_RU": "Протокол", "fa_IR": "پروتکل", "vi_VN": "Giao thức", "km_KH": "ពិធីការ", "my_MM": "ပရိုတိုကော"},

    # Data usage
    "Traffic Usage": {"zh_CN": "流量使用", "zh_TW": "流量使用", "ru_RU": "Использование трафика", "fa_IR": "مصرف ترافیک", "vi_VN": "Lưu lượng", "km_KH": "ការប្រើចរាចរ", "my_MM": "အသွားအလာ"},
    "Total Traffic": {"zh_CN": "总流量", "zh_TW": "總流量", "ru_RU": "Общий трафик", "fa_IR": "کل ترافیک", "vi_VN": "Tổng lưu lượng", "km_KH": "ចរាចរសរុប", "my_MM": "စုစုပေါင်း"},
    "Upload Speed": {"zh_CN": "上传速度", "zh_TW": "上傳速度", "ru_RU": "Скорость отправки", "fa_IR": "سرعت آپلود", "vi_VN": "Tốc độ tải lên", "km_KH": "ល្បឿនផ្ទុកឡើង", "my_MM": "အပ်လုဒ်နှုန်း"},
    "Download Speed": {"zh_CN": "下载速度", "zh_TW": "下載速度", "ru_RU": "Скорость загрузки", "fa_IR": "سرعت دانلود", "vi_VN": "Tốc độ tải xuống", "km_KH": "ល្បឿនទាញយក", "my_MM": "ဒေါင်းလုဒ်နှုန်း"},

    # Coupon
    "Coupon": {"zh_CN": "优惠券", "zh_TW": "優惠券", "ru_RU": "Купон", "fa_IR": "کوپن", "vi_VN": "Mã giảm giá", "km_KH": "គូប៉ុង", "my_MM": "ကူပွန်"},
    "Enter coupon code": {"zh_CN": "输入优惠码", "zh_TW": "輸入優惠碼", "ru_RU": "Введите код купона", "fa_IR": "کد کوپن را وارد کنید", "vi_VN": "Nhập mã giảm giá", "km_KH": "បញ្ចូលលេខកូដគូប៉ុង", "my_MM": "ကူပွန်ကုဒ်ရိုက်"},
    "Apply Coupon": {"zh_CN": "应用优惠券", "zh_TW": "套用優惠券", "ru_RU": "Применить купон", "fa_IR": "اعمال کوپن", "vi_VN": "Áp dụng mã", "km_KH": "អនុវត្តគូប៉ុង", "my_MM": "ကူပွန်သုံး"},

    # Testing
    "Testing %1 servers...": {"zh_CN": "正在测试 %1 个服务器...", "zh_TW": "正在測試 %1 個伺服器...", "ru_RU": "Тестирование %1 серверов...", "fa_IR": "در حال آزمایش %1 سرور...", "vi_VN": "Đang test %1 máy chủ...", "km_KH": "កំពុងសាកល្បង %1 ម៉ាស៊ីនមេ...", "my_MM": "ဆာဗာ %1 ခုစမ်းနေ..."},
    "Test completed": {"zh_CN": "测试完成", "zh_TW": "測試完成", "ru_RU": "Тест завершен", "fa_IR": "آزمایش تکمیل شد", "vi_VN": "Test xong", "km_KH": "សាកល្បងបានបញ្ចប់", "my_MM": "စမ်းပြီး"},
    "Test failed": {"zh_CN": "测试失败", "zh_TW": "測試失敗", "ru_RU": "Тест не пройден", "fa_IR": "آزمایش ناموفق", "vi_VN": "Test thất bại", "km_KH": "សាកល្បងបរាជ័យ", "my_MM": "စမ်းမအောင်"},

    # Payment methods
    "Processing...": {"zh_CN": "处理中...", "zh_TW": "處理中...", "ru_RU": "Обработка...", "fa_IR": "در حال پردازش...", "vi_VN": "Đang xử lý...", "km_KH": "កំពុងដំណើរការ...", "my_MM": "ဆောင်ရွက်နေ..."},
    "Confirm Payment": {"zh_CN": "确认支付", "zh_TW": "確認付款", "ru_RU": "Подтвердить оплату", "fa_IR": "تایید پرداخت", "vi_VN": "Xác nhận thanh toán", "km_KH": "បញ្ជាក់ការបង់ប្រាក់", "my_MM": "ငွေပေးချေအတည်ပြု"},
    "Alipay": {"zh_CN": "支付宝", "zh_TW": "支付寶", "ru_RU": "Alipay", "fa_IR": "علی‌پی", "vi_VN": "Alipay", "km_KH": "Alipay", "my_MM": "Alipay"},
    "WeChat Pay": {"zh_CN": "微信支付", "zh_TW": "微信支付", "ru_RU": "WeChat Pay", "fa_IR": "وی‌چت پی", "vi_VN": "WeChat Pay", "km_KH": "WeChat Pay", "my_MM": "WeChat Pay"},
    "Credit/Debit Card": {"zh_CN": "信用卡/借记卡", "zh_TW": "信用卡/簽帳卡", "ru_RU": "Карта", "fa_IR": "کارت اعتباری/بدهی", "vi_VN": "Thẻ ngân hàng", "km_KH": "កាតឥណទាន", "my_MM": "ကတ်"},
    "PayPal": {"zh_CN": "PayPal", "zh_TW": "PayPal", "ru_RU": "PayPal", "fa_IR": "پی‌پال", "vi_VN": "PayPal", "km_KH": "PayPal", "my_MM": "PayPal"},
    "Bank Transfer": {"zh_CN": "银行转账", "zh_TW": "銀行轉帳", "ru_RU": "Банковский перевод", "fa_IR": "انتقال بانکی", "vi_VN": "Chuyển khoản", "km_KH": "ផ្ទេរប្រាក់", "my_MM": "ငွေလွှဲ"},
    "Cryptocurrency": {"zh_CN": "加密货币", "zh_TW": "加密貨幣", "ru_RU": "Криптовалюта", "fa_IR": "ارز دیجیتال", "vi_VN": "Tiền điện tử", "km_KH": "រូបិយប័ណ្ណឌីជីថល", "my_MM": "ဒစ်ဂျစ်တယ်ငွေ"},
    "Online Payment": {"zh_CN": "在线支付", "zh_TW": "線上付款", "ru_RU": "Онлайн-оплата", "fa_IR": "پرداخت آنلاین", "vi_VN": "Thanh toán online", "km_KH": "ការបង់ប្រាក់អនឡាញ", "my_MM": "အွန်လိုင်းငွေပေး"},
    "Password changed successfully": {"zh_CN": "密码修改成功", "zh_TW": "密碼修改成功", "ru_RU": "Пароль изменен", "fa_IR": "رمز عبور با موفقیت تغییر کرد", "vi_VN": "Đổi mật khẩu thành công", "km_KH": "ប្ដូរលេខសម្ងាត់ជោគជ័យ", "my_MM": "စကားဝှက်ပြောင်းပြီး"},

    # Verification
    "Email Verification Code": {"zh_CN": "邮箱验证码", "zh_TW": "電子郵件驗證碼", "ru_RU": "Код подтверждения email", "fa_IR": "کد تایید ایمیل", "vi_VN": "Mã xác nhận email", "km_KH": "លេខកូដផ្ទៀងផ្ទាត់អ៊ីមែល", "my_MM": "အီးမေးလ်အတည်ပြုကုဒ်"},
    "Enter verification code": {"zh_CN": "输入验证码", "zh_TW": "輸入驗證碼", "ru_RU": "Введите код", "fa_IR": "کد تایید را وارد کنید", "vi_VN": "Nhập mã xác nhận", "km_KH": "បញ្ចូលលេខកូដផ្ទៀងផ្ទាត់", "my_MM": "အတည်ပြုကုဒ်ရိုက်"},
    "Sending...": {"zh_CN": "发送中...", "zh_TW": "發送中...", "ru_RU": "Отправка...", "fa_IR": "در حال ارسال...", "vi_VN": "Đang gửi...", "km_KH": "កំពុងផ្ញើ...", "my_MM": "ပို့နေ..."},
    "Resend (%1s)": {"zh_CN": "重新发送 (%1秒)", "zh_TW": "重新發送 (%1秒)", "ru_RU": "Повторить (%1с)", "fa_IR": "ارسال مجدد (%1ثانیه)", "vi_VN": "Gửi lại (%1s)", "km_KH": "ផ្ញើម្ដងទៀត (%1វិនាទី)", "my_MM": "ပြန်ပို့ (%1s)"},
    "Enter invite code if you have one": {"zh_CN": "如有邀请码请输入", "zh_TW": "如有邀請碼請輸入", "ru_RU": "Введите код приглашения, если есть", "fa_IR": "در صورت داشتن کد دعوت وارد کنید", "vi_VN": "Nhập mã mời nếu có", "km_KH": "បញ្ចូលលេខកូដអញ្ជើញបើមាន", "my_MM": "ဖိတ်ကြားကုဒ်ရှိလျှင်ရိုက်"},

    # Test method descriptions
    "TCP: Direct TCP connection to server port (fast, recommended)": {"zh_CN": "TCP：直接TCP连接到服务器端口（快速，推荐）", "zh_TW": "TCP：直接TCP連接到伺服器埠（快速，推薦）", "ru_RU": "TCP: Прямое TCP-подключение к серверу (быстро, рекомендуется)", "fa_IR": "TCP: اتصال مستقیم TCP به پورت سرور (سریع، توصیه شده)", "vi_VN": "TCP: Kết nối trực tiếp (nhanh, khuyến nghị)", "km_KH": "TCP: ការភ្ជាប់ផ្ទាល់ (លឿន, ណែនាំ)", "my_MM": "TCP: တိုက်ရိုက်ချိတ် (မြန်, အကြံပြု)"},
    "HTTP: Test via proxy HTTP request (most accurate for actual usage)": {"zh_CN": "HTTP：通过代理HTTP请求测试（最准确反映实际使用）", "zh_TW": "HTTP：透過代理HTTP請求測試（最準確反映實際使用）", "ru_RU": "HTTP: Тест через HTTP-запрос (точнее отражает реальное использование)", "fa_IR": "HTTP: تست از طریق درخواست HTTP پروکسی (دقیق‌ترین برای استفاده واقعی)", "vi_VN": "HTTP: Test qua proxy (chính xác nhất)", "km_KH": "HTTP: សាកល្បងតាម proxy (ត្រឹមត្រូវបំផុត)", "my_MM": "HTTP: proxy ဖြင့်စမ်း (တိကျဆုံး)"},
    "HTTP": {"zh_CN": "HTTP", "zh_TW": "HTTP", "ru_RU": "HTTP", "fa_IR": "HTTP", "vi_VN": "HTTP", "km_KH": "HTTP", "my_MM": "HTTP"},
    "Disabled: No periodic latency testing when connected": {"zh_CN": "禁用：连接时不进行定期延迟测试", "zh_TW": "停用：連接時不進行定期延遲測試", "ru_RU": "Отключено: нет периодического теста задержки", "fa_IR": "غیرفعال: بدون تست تاخیر دوره‌ای هنگام اتصال", "vi_VN": "Tắt: Không test định kỳ", "km_KH": "បិទ: គ្មានការសាកល្បងទៀងទាត់", "my_MM": "ပိတ်: ပုံမှန်မစမ်း"},
    "Test latency every %1 seconds when connected": {"zh_CN": "连接时每 %1 秒测试延迟", "zh_TW": "連接時每 %1 秒測試延遲", "ru_RU": "Тест задержки каждые %1 сек. при подключении", "fa_IR": "تست تاخیر هر %1 ثانیه هنگام اتصال", "vi_VN": "Test mỗi %1 giây khi kết nối", "km_KH": "សាកល្បងរៀងរាល់ %1 វិនាទី", "my_MM": "ချိတ်ဆက်ချိန် %1 စက္ကန့်တိုင်းစမ်း"},

    # Payment status
    "Payment initiated successfully": {"zh_CN": "支付已发起", "zh_TW": "付款已發起", "ru_RU": "Оплата инициирована", "fa_IR": "پرداخت با موفقیت آغاز شد", "vi_VN": "Đã khởi tạo thanh toán", "km_KH": "បានចាប់ផ្តើមការបង់ប្រាក់", "my_MM": "ငွေပေးချေမှုစတင်ပြီ"},
    "Please login first": {"zh_CN": "请先登录", "zh_TW": "請先登入", "ru_RU": "Сначала войдите", "fa_IR": "لطفا ابتدا وارد شوید", "vi_VN": "Vui lòng đăng nhập", "km_KH": "សូមចូលជាមុន", "my_MM": "ဦးစွာဝင်ပါ"},
    "Order manager not available": {"zh_CN": "订单管理器不可用", "zh_TW": "訂單管理器不可用", "ru_RU": "Менеджер заказов недоступен", "fa_IR": "مدیریت سفارش در دسترس نیست", "vi_VN": "Không khả dụng", "km_KH": "មិនអាចប្រើបាន", "my_MM": "မရရှိနိုင်"},
    "Payment manager not available": {"zh_CN": "支付管理器不可用", "zh_TW": "付款管理器不可用", "ru_RU": "Менеджер платежей недоступен", "fa_IR": "مدیریت پرداخت در دسترس نیست", "vi_VN": "Không khả dụng", "km_KH": "មិនអាចប្រើបាន", "my_MM": "မရရှိနိုင်"},
    "Invalid order": {"zh_CN": "无效订单", "zh_TW": "無效訂單", "ru_RU": "Неверный заказ", "fa_IR": "سفارش نامعتبر", "vi_VN": "Đơn hàng không hợp lệ", "km_KH": "ការបញ្ជាទិញមិនត្រឹមត្រូវ", "my_MM": "အော်ဒါမမှန်"},

    # Ticket system
    "Ticket System": {"zh_CN": "工单系统", "zh_TW": "工單系統", "ru_RU": "Система тикетов", "fa_IR": "سیستم تیکت", "vi_VN": "Hệ thống hỗ trợ", "km_KH": "ប្រព័ន្ធសំបុត្រ", "my_MM": "လက်မှတ်စနစ်"},
    "New Ticket": {"zh_CN": "新建工单", "zh_TW": "新建工單", "ru_RU": "Новый тикет", "fa_IR": "تیکت جدید", "vi_VN": "Tạo yêu cầu mới", "km_KH": "សំបុត្រថ្មី", "my_MM": "လက်မှတ်အသစ်"},
    "Ticket Detail": {"zh_CN": "工单详情", "zh_TW": "工單詳情", "ru_RU": "Детали тикета", "fa_IR": "جزئیات تیکت", "vi_VN": "Chi tiết yêu cầu", "km_KH": "ព័ត៌មានលម្អិតសំបុត្រ", "my_MM": "လက်မှတ်အသေးစိတ်"},
    "Pending": {"zh_CN": "待处理", "zh_TW": "待處理", "ru_RU": "В ожидании", "fa_IR": "در انتظار", "vi_VN": "Chờ xử lý", "km_KH": "កំពុងរង់ចាំ", "my_MM": "စောင့်ဆိုင်း"},
    "Closed": {"zh_CN": "已关闭", "zh_TW": "已關閉", "ru_RU": "Закрыт", "fa_IR": "بسته شده", "vi_VN": "Đã đóng", "km_KH": "បានបិទ", "my_MM": "ပိတ်ပြီး"},
    "Low": {"zh_CN": "低", "zh_TW": "低", "ru_RU": "Низкий", "fa_IR": "کم", "vi_VN": "Thấp", "km_KH": "ទាប", "my_MM": "နိမ့်"},
    "Medium": {"zh_CN": "中", "zh_TW": "中", "ru_RU": "Средний", "fa_IR": "متوسط", "vi_VN": "Trung bình", "km_KH": "មធ្យម", "my_MM": "အလယ်အလတ်"},
    "High": {"zh_CN": "高", "zh_TW": "高", "ru_RU": "Высокий", "fa_IR": "بالا", "vi_VN": "Cao", "km_KH": "ខ្ពស់", "my_MM": "မြင့်"},
    "Loading tickets...": {"zh_CN": "正在加载工单...", "zh_TW": "正在載入工單...", "ru_RU": "Загрузка тикетов...", "fa_IR": "در حال بارگذاری تیکت‌ها...", "vi_VN": "Đang tải...", "km_KH": "កំពុងផ្ទុក...", "my_MM": "ဖွင့်နေ..."},
    "No tickets yet": {"zh_CN": "暂无工单", "zh_TW": "暫無工單", "ru_RU": "Тикетов пока нет", "fa_IR": "هنوز تیکتی نیست", "vi_VN": "Chưa có yêu cầu", "km_KH": "មិនទាន់មានសំបុត្រ", "my_MM": "လက်မှတ်မရှိသေး"},
    "Click 'New Ticket' to submit your question": {"zh_CN": "点击「新建工单」提交您的问题", "zh_TW": "點擊「新建工單」提交您的問題", "ru_RU": "Нажмите 'Новый тикет' чтобы задать вопрос", "fa_IR": "برای ارسال سوال روی 'تیکت جدید' کلیک کنید", "vi_VN": "Nhấn 'Tạo yêu cầu mới' để gửi câu hỏi", "km_KH": "ចុច 'សំបុត្រថ្មី' ដើម្បីដាក់សំណួរ", "my_MM": "'လက်မှတ်အသစ်' နှိပ်ပါ"},
    "No Subject": {"zh_CN": "无标题", "zh_TW": "無標題", "ru_RU": "Без темы", "fa_IR": "بدون موضوع", "vi_VN": "Không có tiêu đề", "km_KH": "គ្មានចំណងជើង", "my_MM": "ခေါင်းစဉ်မရှိ"},
    "Has Reply": {"zh_CN": "有回复", "zh_TW": "有回覆", "ru_RU": "Есть ответ", "fa_IR": "دارای پاسخ", "vi_VN": "Có trả lời", "km_KH": "មានការឆ្លើយតប", "my_MM": "ပြန်စာရှိ"},
    "Please enter ticket subject": {"zh_CN": "请输入工单标题", "zh_TW": "請輸入工單標題", "ru_RU": "Введите тему тикета", "fa_IR": "لطفا موضوع تیکت را وارد کنید", "vi_VN": "Nhập tiêu đề", "km_KH": "បញ្ចូលចំណងជើង", "my_MM": "ခေါင်းစဉ်ရိုက်"},
    "Please enter ticket content": {"zh_CN": "请输入工单内容", "zh_TW": "請輸入工單內容", "ru_RU": "Введите содержание тикета", "fa_IR": "لطفا محتوای تیکت را وارد کنید", "vi_VN": "Nhập nội dung", "km_KH": "បញ្ចូលមាតិកា", "my_MM": "အကြောင်းအရာရိုက်"},
    "Ticket content must be at least 10 characters": {"zh_CN": "工单内容至少10个字符", "zh_TW": "工單內容至少10個字元", "ru_RU": "Содержание минимум 10 символов", "fa_IR": "محتوای تیکت باید حداقل 10 کاراکتر باشد", "vi_VN": "Ít nhất 10 ký tự", "km_KH": "យ៉ាងតិច ១០ តួអក្សរ", "my_MM": "အနည်းဆုံး ၁၀ လုံး"},
    "System error": {"zh_CN": "系统错误", "zh_TW": "系統錯誤", "ru_RU": "Системная ошибка", "fa_IR": "خطای سیستم", "vi_VN": "Lỗi hệ thống", "km_KH": "កំហុសប្រព័ន្ធ", "my_MM": "စနစ်အမှား"},
    "Subject": {"zh_CN": "标题", "zh_TW": "標題", "ru_RU": "Тема", "fa_IR": "موضوع", "vi_VN": "Tiêu đề", "km_KH": "ចំណងជើង", "my_MM": "ခေါင်းစဉ်"},
    "Brief description of your issue": {"zh_CN": "简要描述您的问题", "zh_TW": "簡要描述您的問題", "ru_RU": "Краткое описание проблемы", "fa_IR": "توضیح کوتاه مشکل شما", "vi_VN": "Mô tả ngắn gọn vấn đề", "km_KH": "ការពិពណ៌នាខ្លី", "my_MM": "အကျဉ်းချုပ်ဖော်ပြ"},
    "Priority": {"zh_CN": "优先级", "zh_TW": "優先級", "ru_RU": "Приоритет", "fa_IR": "اولویت", "vi_VN": "Độ ưu tiên", "km_KH": "អាទិភាព", "my_MM": "ဦးစားပေး"},
    "Content": {"zh_CN": "内容", "zh_TW": "內容", "ru_RU": "Содержание", "fa_IR": "محتوا", "vi_VN": "Nội dung", "km_KH": "មាតិកា", "my_MM": "အကြောင်းအရာ"},
    "Please describe your issue in detail...": {"zh_CN": "请详细描述您的问题...", "zh_TW": "請詳細描述您的問題...", "ru_RU": "Подробно опишите проблему...", "fa_IR": "لطفا مشکل خود را به طور کامل شرح دهید...", "vi_VN": "Mô tả chi tiết vấn đề...", "km_KH": "សូមពិពណ៌នាលម្អិត...", "my_MM": "အသေးစိတ်ဖော်ပြပါ..."},
    "Minimum 10 characters": {"zh_CN": "至少10个字符", "zh_TW": "至少10個字元", "ru_RU": "Минимум 10 символов", "fa_IR": "حداقل 10 کاراکتر", "vi_VN": "Ít nhất 10 ký tự", "km_KH": "យ៉ាងតិច ១០ តួអក្សរ", "my_MM": "အနည်းဆုံး ၁၀ လုံး"},
    "Submitting...": {"zh_CN": "提交中...", "zh_TW": "提交中...", "ru_RU": "Отправка...", "fa_IR": "در حال ارسال...", "vi_VN": "Đang gửi...", "km_KH": "កំពុងដាក់ស្នើ...", "my_MM": "တင်သွင်းနေ..."},
    "Submit Ticket": {"zh_CN": "提交工单", "zh_TW": "提交工單", "ru_RU": "Отправить тикет", "fa_IR": "ارسال تیکت", "vi_VN": "Gửi yêu cầu", "km_KH": "ដាក់ស្នើសំបុត្រ", "my_MM": "လက်မှတ်တင်"},
    "Original Message": {"zh_CN": "原始消息", "zh_TW": "原始訊息", "ru_RU": "Исходное сообщение", "fa_IR": "پیام اصلی", "vi_VN": "Tin nhắn gốc", "km_KH": "សារដើម", "my_MM": "မူရင်းစာ"},
    "Conversation": {"zh_CN": "对话", "zh_TW": "對話", "ru_RU": "Переписка", "fa_IR": "مکالمه", "vi_VN": "Hội thoại", "km_KH": "ការសន្ទនា", "my_MM": "စကားပြော"},
    "You": {"zh_CN": "你", "zh_TW": "你", "ru_RU": "Вы", "fa_IR": "شما", "vi_VN": "Bạn", "km_KH": "អ្នក", "my_MM": "သင်"},
    "Enter your reply...": {"zh_CN": "输入您的回复...", "zh_TW": "輸入您的回覆...", "ru_RU": "Введите ответ...", "fa_IR": "پاسخ خود را وارد کنید...", "vi_VN": "Nhập trả lời...", "km_KH": "បញ្ចូលការឆ្លើយតប...", "my_MM": "ပြန်စာရိုက်..."},
    "Close Ticket": {"zh_CN": "关闭工单", "zh_TW": "關閉工單", "ru_RU": "Закрыть тикет", "fa_IR": "بستن تیکت", "vi_VN": "Đóng yêu cầu", "km_KH": "បិទសំបុត្រ", "my_MM": "လက်မှတ်ပိတ်"},
    "Send": {"zh_CN": "发送", "zh_TW": "發送", "ru_RU": "Отправить", "fa_IR": "ارسال", "vi_VN": "Gửi", "km_KH": "ផ្ញើ", "my_MM": "ပို့"},
    "This ticket has been closed": {"zh_CN": "该工单已关闭", "zh_TW": "該工單已關閉", "ru_RU": "Тикет закрыт", "fa_IR": "این تیکت بسته شده است", "vi_VN": "Yêu cầu đã đóng", "km_KH": "សំបុត្រនេះត្រូវបានបិទ", "my_MM": "လက်မှတ်ပိတ်ပြီး"},

    # System status messages
    "Checking system requirements...": {"zh_CN": "正在检查系统要求...", "zh_TW": "正在檢查系統需求...", "ru_RU": "Проверка системных требований...", "fa_IR": "در حال بررسی نیازمندی‌های سیستم...", "vi_VN": "Đang kiểm tra...", "km_KH": "កំពុងពិនិត្យ...", "my_MM": "စစ်ဆေးနေ..."},
    "Checking WinTun driver...": {"zh_CN": "正在检查WinTun驱动...", "zh_TW": "正在檢查WinTun驅動...", "ru_RU": "Проверка драйвера WinTun...", "fa_IR": "در حال بررسی درایور WinTun...", "vi_VN": "Kiểm tra WinTun...", "km_KH": "កំពុងពិនិត្យ WinTun...", "my_MM": "WinTun စစ်နေ..."},
    "Preparing routes...": {"zh_CN": "正在准备路由...", "zh_TW": "正在準備路由...", "ru_RU": "Подготовка маршрутов...", "fa_IR": "در حال آماده‌سازی مسیرها...", "vi_VN": "Chuẩn bị định tuyến...", "km_KH": "កំពុងរៀបចំផ្លូវ...", "my_MM": "လမ်းကြောင်းပြင်နေ..."},
    "Creating TUN device...": {"zh_CN": "正在创建TUN设备...", "zh_TW": "正在建立TUN裝置...", "ru_RU": "Создание TUN-устройства...", "fa_IR": "در حال ایجاد دستگاه TUN...", "vi_VN": "Tạo TUN...", "km_KH": "កំពុងបង្កើត TUN...", "my_MM": "TUN ဖန်တီးနေ..."},
    "Waiting for TUN device...": {"zh_CN": "正在等待TUN设备...", "zh_TW": "正在等待TUN裝置...", "ru_RU": "Ожидание TUN-устройства...", "fa_IR": "در انتظار دستگاه TUN...", "vi_VN": "Đợi TUN...", "km_KH": "កំពុងរង់ចាំ TUN...", "my_MM": "TUN စောင့်နေ..."},
    "Configuring TUN routes...": {"zh_CN": "正在配置TUN路由...", "zh_TW": "正在設定TUN路由...", "ru_RU": "Настройка TUN-маршрутов...", "fa_IR": "در حال پیکربندی مسیرهای TUN...", "vi_VN": "Cấu hình TUN...", "km_KH": "កំពុងកំណត់ TUN...", "my_MM": "TUN ပြင်ဆင်နေ..."},
    "TCP connection failed": {"zh_CN": "TCP连接失败", "zh_TW": "TCP連接失敗", "ru_RU": "TCP-подключение не удалось", "fa_IR": "اتصال TCP ناموفق بود", "vi_VN": "Kết nối TCP thất bại", "km_KH": "ការភ្ជាប់ TCP បរាជ័យ", "my_MM": "TCP ချိတ်ဆက်မအောင်"},
    "HTTP request failed": {"zh_CN": "HTTP请求失败", "zh_TW": "HTTP請求失敗", "ru_RU": "HTTP-запрос не удался", "fa_IR": "درخواست HTTP ناموفق بود", "vi_VN": "Yêu cầu HTTP thất bại", "km_KH": "សំណើ HTTP បរាជ័យ", "my_MM": "HTTP တောင်းဆိုမှုမအောင်"},
    "Ping not supported on this platform": {"zh_CN": "此平台不支持Ping", "zh_TW": "此平台不支援Ping", "ru_RU": "Ping не поддерживается на этой платформе", "fa_IR": "Ping در این پلتفرم پشتیبانی نمی‌شود", "vi_VN": "Không hỗ trợ Ping", "km_KH": "មិនគាំទ្រ Ping", "my_MM": "Ping မပံ့ပိုး"},

    # Last remaining strings
    "TCP": {"zh_CN": "TCP", "zh_TW": "TCP", "ru_RU": "TCP", "fa_IR": "TCP", "vi_VN": "TCP", "km_KH": "TCP", "my_MM": "TCP"},
    "Failed to update database": {"zh_CN": "更新数据库失败", "zh_TW": "更新資料庫失敗", "ru_RU": "Не удалось обновить базу данных", "fa_IR": "به‌روزرسانی پایگاه داده ناموفق بود", "vi_VN": "Cập nhật database thất bại", "km_KH": "ធ្វើបច្ចុប្បន្នភាពមូលដ្ឋានទិន្នន័យបរាជ័យ", "my_MM": "database အပ်ဒိတ်မအောင်"},
    "Connected (Windows TUN Mode)": {"zh_CN": "已连接（Windows TUN模式）", "zh_TW": "已連接（Windows TUN模式）", "ru_RU": "Подключено (Windows TUN)", "fa_IR": "متصل (حالت TUN ویندوز)", "vi_VN": "Đã kết nối (Windows TUN)", "km_KH": "បានភ្ជាប់ (Windows TUN)", "my_MM": "ချိတ်ဆက်ပြီး (Windows TUN)"},

    # License Dialog
    "Open Source Licenses": {"zh_CN": "开源许可证", "zh_TW": "開源授權", "ru_RU": "Лицензии открытого ПО", "fa_IR": "مجوزهای متن‌باز", "vi_VN": "Giấy phép mã nguồn mở", "km_KH": "អាជ្ញាប័ណ្ណប្រភពបើកចំហ", "my_MM": "Open Source လိုင်စင်"},
    "Project Links:": {"zh_CN": "项目链接：", "zh_TW": "專案連結：", "ru_RU": "Ссылки на проекты:", "fa_IR": "لینک‌های پروژه:", "vi_VN": "Link dự án:", "km_KH": "តំណគម្រោង:", "my_MM": "ပရောဂျက်လင့်:"},
    "Website": {"zh_CN": "官网", "zh_TW": "官網", "ru_RU": "Веб-сайт", "fa_IR": "وب‌سایت", "vi_VN": "Website", "km_KH": "គេហទំព័រ", "my_MM": "ဝဘ်ဆိုဒ်"},
    "Powered by": {"zh_CN": "技术支持", "zh_TW": "技術支援", "ru_RU": "На базе", "fa_IR": "قدرت گرفته از", "vi_VN": "Hỗ trợ bởi", "km_KH": "គាំទ្រដោយ", "my_MM": "ပံ့ပိုးသူ"},
    "Version": {"zh_CN": "版本", "zh_TW": "版本", "ru_RU": "Версия", "fa_IR": "نسخه", "vi_VN": "Phiên bản", "km_KH": "កំណែ", "my_MM": "ဗားရှင်း"},
    "Copyright": {"zh_CN": "版权所有", "zh_TW": "版權所有", "ru_RU": "Авторское право", "fa_IR": "حق نشر", "vi_VN": "Bản quyền", "km_KH": "រក្សាសិទ្ធិ", "my_MM": "မူပိုင်ခွင့်"},
    "All rights reserved.": {"zh_CN": "保留所有权利。", "zh_TW": "保留所有權利。", "ru_RU": "Все права защищены.", "fa_IR": "تمامی حقوق محفوظ است.", "vi_VN": "Mọi quyền được bảo lưu.", "km_KH": "រក្សាសិទ្ធិគ្រប់យ៉ាង។", "my_MM": "မူပိုင်ခွင့်အားလုံးရယူထားသည်။"},

    # Update Check Dialog
    "Update Available": {"zh_CN": "有可用更新", "zh_TW": "有可用更新", "ru_RU": "Доступно обновление", "fa_IR": "به‌روزرسانی موجود است", "vi_VN": "Có bản cập nhật", "km_KH": "មានការធ្វើបច្ចុប្បន្នភាព", "my_MM": "အပ်ဒိတ်ရှိ"},
    "A new version is available": {"zh_CN": "有新版本可用", "zh_TW": "有新版本可用", "ru_RU": "Доступна новая версия", "fa_IR": "نسخه جدید موجود است", "vi_VN": "Có phiên bản mới", "km_KH": "មានកំណែថ្មី", "my_MM": "ဗားရှင်းအသစ်ရှိ"},
    "Current version:": {"zh_CN": "当前版本：", "zh_TW": "目前版本：", "ru_RU": "Текущая версия:", "fa_IR": "نسخه فعلی:", "vi_VN": "Phiên bản hiện tại:", "km_KH": "កំណែបច្ចុប្បន្ន:", "my_MM": "လက်ရှိဗားရှင်း:"},
    "Latest version:": {"zh_CN": "最新版本：", "zh_TW": "最新版本：", "ru_RU": "Последняя версия:", "fa_IR": "آخرین نسخه:", "vi_VN": "Phiên bản mới nhất:", "km_KH": "កំណែចុងក្រោយ:", "my_MM": "နောက်ဆုံးဗားရှင်း:"},
    "What's New:": {"zh_CN": "更新内容：", "zh_TW": "更新內容：", "ru_RU": "Что нового:", "fa_IR": "تغییرات جدید:", "vi_VN": "Có gì mới:", "km_KH": "អ្វីដែលថ្មី:", "my_MM": "အသစ်အဆန်း:"},
    "Download Update": {"zh_CN": "下载更新", "zh_TW": "下載更新", "ru_RU": "Скачать обновление", "fa_IR": "دانلود به‌روزرسانی", "vi_VN": "Tải xuống", "km_KH": "ទាញយកការធ្វើបច្ចុប្បន្នភាព", "my_MM": "ဒေါင်းလုဒ်"},
    "Remind Me Later": {"zh_CN": "稍后提醒", "zh_TW": "稍後提醒", "ru_RU": "Напомнить позже", "fa_IR": "بعدا یادآوری کن", "vi_VN": "Nhắc sau", "km_KH": "រំលឹកខ្ញុំពេលក្រោយ", "my_MM": "နောက်မှသတိပေး"},
    "Skip This Version": {"zh_CN": "跳过此版本", "zh_TW": "略過此版本", "ru_RU": "Пропустить версию", "fa_IR": "رد کردن این نسخه", "vi_VN": "Bỏ qua phiên bản này", "km_KH": "រំលងកំណែនេះ", "my_MM": "ဒီဗားရှင်းကျော်"},
    "No updates available": {"zh_CN": "没有可用更新", "zh_TW": "沒有可用更新", "ru_RU": "Нет доступных обновлений", "fa_IR": "به‌روزرسانی موجود نیست", "vi_VN": "Không có bản cập nhật", "km_KH": "គ្មានការធ្វើបច្ចុប្បន្នភាព", "my_MM": "အပ်ဒိတ်မရှိ"},
    "You are using the latest version.": {"zh_CN": "您正在使用最新版本。", "zh_TW": "您正在使用最新版本。", "ru_RU": "Вы используете последнюю версию.", "fa_IR": "شما از آخرین نسخه استفاده می‌کنید.", "vi_VN": "Bạn đang dùng phiên bản mới nhất.", "km_KH": "អ្នកកំពុងប្រើកំណែចុងក្រោយ។", "my_MM": "နောက်ဆုံးဗားရှင်းသုံးနေပါပြီ။"},
    "Checking for updates...": {"zh_CN": "正在检查更新...", "zh_TW": "正在檢查更新...", "ru_RU": "Проверка обновлений...", "fa_IR": "در حال بررسی به‌روزرسانی‌ها...", "vi_VN": "Đang kiểm tra...", "km_KH": "កំពុងពិនិត្យ...", "my_MM": "စစ်ဆေးနေ..."},
    "Update check failed": {"zh_CN": "检查更新失败", "zh_TW": "檢查更新失敗", "ru_RU": "Ошибка проверки обновлений", "fa_IR": "بررسی به‌روزرسانی ناموفق بود", "vi_VN": "Kiểm tra thất bại", "km_KH": "ពិនិត្យបរាជ័យ", "my_MM": "စစ်ဆေးမအောင်"},
    "Mandatory Update": {"zh_CN": "强制更新", "zh_TW": "強制更新", "ru_RU": "Обязательное обновление", "fa_IR": "به‌روزرسانی اجباری", "vi_VN": "Cập nhật bắt buộc", "km_KH": "ការធ្វើបច្ចុប្បន្នភាពចាំបាច់", "my_MM": "မဖြစ်မနေအပ်ဒိတ်"},
    "This update is required to continue using the app.": {"zh_CN": "此更新是继续使用应用程序所必需的。", "zh_TW": "此更新是繼續使用應用程式所必需的。", "ru_RU": "Это обновление необходимо для продолжения работы.", "fa_IR": "این به‌روزرسانی برای ادامه استفاده از برنامه الزامی است.", "vi_VN": "Cần cập nhật để tiếp tục sử dụng.", "km_KH": "ត្រូវការធ្វើបច្ចុប្បន្នភាពដើម្បីបន្ត។", "my_MM": "ဆက်သုံးရန်အပ်ဒိတ်လိုအပ်သည်။"},

    # Qt Designer Components - AbstractButton
    "AbstractButton": {"zh_CN": "抽象按钮", "zh_TW": "抽象按鈕", "ru_RU": "Абстрактная кнопка", "fa_IR": "دکمه انتزاعی"},
    "Text": {"zh_CN": "文本", "zh_TW": "文字", "ru_RU": "Текст", "fa_IR": "متن"},
    "The text displayed on the button.": {"zh_CN": "按钮上显示的文本。", "zh_TW": "按鈕上顯示的文字。", "ru_RU": "Текст на кнопке.", "fa_IR": "متن نمایش داده شده روی دکمه."},
    "Display": {"zh_CN": "显示", "zh_TW": "顯示", "ru_RU": "Отображение", "fa_IR": "نمایش"},
    "Determines how the icon and text are displayed within the button.": {"zh_CN": "决定图标和文本在按钮内的显示方式。", "zh_TW": "決定圖示和文字在按鈕內的顯示方式。", "ru_RU": "Определяет отображение иконки и текста в кнопке.", "fa_IR": "تعیین نحوه نمایش آیکون و متن در دکمه."},
    "Checkable": {"zh_CN": "可选中", "zh_TW": "可選中", "ru_RU": "Переключаемая", "fa_IR": "قابل علامت‌گذاری"},
    "Whether the button is checkable.": {"zh_CN": "按钮是否可选中。", "zh_TW": "按鈕是否可選中。", "ru_RU": "Может ли кнопка быть переключаемой.", "fa_IR": "آیا دکمه قابل علامت‌گذاری است."},
    "Checked": {"zh_CN": "已选中", "zh_TW": "已選中", "ru_RU": "Отмечено", "fa_IR": "علامت‌گذاری شده"},
    "Whether the button is checked.": {"zh_CN": "按钮是否已选中。", "zh_TW": "按鈕是否已選中。", "ru_RU": "Отмечена ли кнопка.", "fa_IR": "آیا دکمه علامت‌گذاری شده است."},
    "Exclusive": {"zh_CN": "独占", "zh_TW": "獨佔", "ru_RU": "Эксклюзивная", "fa_IR": "انحصاری"},
    "Whether the button is exclusive.": {"zh_CN": "按钮是否独占。", "zh_TW": "按鈕是否獨佔。", "ru_RU": "Является ли кнопка эксклюзивной.", "fa_IR": "آیا دکمه انحصاری است."},
    "Auto-Repeat": {"zh_CN": "自动重复", "zh_TW": "自動重複", "ru_RU": "Автоповтор", "fa_IR": "تکرار خودکار"},
    "Whether the button repeats pressed(), released() and clicked() signals while the button is pressed and held down.": {"zh_CN": "当按钮被按下并保持时，是否重复发送pressed()、released()和clicked()信号。", "zh_TW": "當按鈕被按下並保持時，是否重複發送pressed()、released()和clicked()信號。", "ru_RU": "Повторяет ли кнопка сигналы pressed(), released() и clicked() при удержании.", "fa_IR": "آیا دکمه سیگنال‌های pressed()، released() و clicked() را در هنگام فشار و نگه داشتن تکرار می‌کند."},

    # BusyIndicator
    "BusyIndicator": {"zh_CN": "忙碌指示器", "zh_TW": "忙碌指示器", "ru_RU": "Индикатор занятости", "fa_IR": "نشانگر مشغول"},
    "Running": {"zh_CN": "运行中", "zh_TW": "執行中", "ru_RU": "Выполняется", "fa_IR": "در حال اجرا"},
    "Whether the busy indicator is currently indicating activity.": {"zh_CN": "忙碌指示器是否正在指示活动。", "zh_TW": "忙碌指示器是否正在指示活動。", "ru_RU": "Указывает ли индикатор активность в данный момент.", "fa_IR": "آیا نشانگر مشغول در حال نمایش فعالیت است."},

    # Button
    "Button": {"zh_CN": "按钮", "zh_TW": "按鈕", "ru_RU": "Кнопка", "fa_IR": "دکمه"},
    "Flat": {"zh_CN": "平面", "zh_TW": "平面", "ru_RU": "Плоская", "fa_IR": "مسطح"},
    "Whether the button is flat.": {"zh_CN": "按钮是否为平面样式。", "zh_TW": "按鈕是否為平面樣式。", "ru_RU": "Является ли кнопка плоской.", "fa_IR": "آیا دکمه مسطح است."},
    "Highlighted": {"zh_CN": "高亮", "zh_TW": "高亮", "ru_RU": "Выделенная", "fa_IR": "برجسته"},
    "Whether the button is highlighted.": {"zh_CN": "按钮是否高亮。", "zh_TW": "按鈕是否高亮。", "ru_RU": "Выделена ли кнопка.", "fa_IR": "آیا دکمه برجسته است."},

    # Password Dialog
    "Enter new password (min 8 chars)": {"zh_CN": "输入新密码（至少8位）", "zh_TW": "輸入新密碼（至少8位）", "ru_RU": "Введите новый пароль (мин. 8 символов)", "fa_IR": "رمز جدید را وارد کنید (حداقل 8 کاراکتر)"},
    "• Password must be at least 8 characters": {"zh_CN": "• 密码至少8个字符", "zh_TW": "• 密碼至少8個字符", "ru_RU": "• Пароль должен содержать минимум 8 символов", "fa_IR": "• رمز عبور باید حداقل 8 کاراکتر باشد"},
    "New password must be at least 8 characters": {"zh_CN": "新密码至少8个字符", "zh_TW": "新密碼至少8個字符", "ru_RU": "Новый пароль должен содержать минимум 8 символов", "fa_IR": "رمز جدید باید حداقل 8 کاراکتر باشد"},
    "Internal error: authManager not available": {"zh_CN": "内部错误：authManager不可用", "zh_TW": "內部錯誤：authManager不可用", "ru_RU": "Внутренняя ошибка: authManager недоступен", "fa_IR": "خطای داخلی: authManager در دسترس نیست"},

    # CheckBox
    "CheckBox": {"zh_CN": "复选框", "zh_TW": "核取方塊", "ru_RU": "Флажок", "fa_IR": "چک باکس"},
    "CheckDelegate": {"zh_CN": "复选代理", "zh_TW": "核取代理", "ru_RU": "Делегат флажка", "fa_IR": "نماینده چک باکس"},
    "Check State": {"zh_CN": "选中状态", "zh_TW": "選取狀態", "ru_RU": "Состояние отметки", "fa_IR": "وضعیت علامت"},
    "The current check state.": {"zh_CN": "当前的选中状态。", "zh_TW": "目前的選取狀態。", "ru_RU": "Текущее состояние отметки.", "fa_IR": "وضعیت فعلی علامت."},
    "Tri-state": {"zh_CN": "三态", "zh_TW": "三態", "ru_RU": "Три состояния", "fa_IR": "سه حالته"},
    "Whether the checkbox has three states.": {"zh_CN": "复选框是否有三种状态。", "zh_TW": "核取方塊是否有三種狀態。", "ru_RU": "Имеет ли флажок три состояния.", "fa_IR": "آیا چک باکس سه حالت دارد."},

    # Color Dialog
    "Color": {"zh_CN": "颜色", "zh_TW": "顏色", "ru_RU": "Цвет", "fa_IR": "رنگ"},
    "Hex": {"zh_CN": "十六进制", "zh_TW": "十六進位", "ru_RU": "Hex", "fa_IR": "مبنای ۱۶"},
    "RGB": {"zh_CN": "RGB", "zh_TW": "RGB", "ru_RU": "RGB", "fa_IR": "RGB"},
    "HSV": {"zh_CN": "HSV", "zh_TW": "HSV", "ru_RU": "HSV", "fa_IR": "HSV"},
    "HSL": {"zh_CN": "HSL", "zh_TW": "HSL", "ru_RU": "HSL", "fa_IR": "HSL"},

    # ComboBox
    "ComboBox": {"zh_CN": "组合框", "zh_TW": "組合方塊", "ru_RU": "Выпадающий список", "fa_IR": "کومبو باکس"},
    "Text Role": {"zh_CN": "文本角色", "zh_TW": "文字角色", "ru_RU": "Текстовая роль", "fa_IR": "نقش متن"},
    "The model role used for displaying text.": {"zh_CN": "用于显示文本的模型角色。", "zh_TW": "用於顯示文字的模型角色。", "ru_RU": "Роль модели для отображения текста.", "fa_IR": "نقش مدل برای نمایش متن."},
    "Current": {"zh_CN": "当前", "zh_TW": "目前", "ru_RU": "Текущий", "fa_IR": "فعلی"},
    "The index of the current item.": {"zh_CN": "当前项的索引。", "zh_TW": "目前項目的索引。", "ru_RU": "Индекс текущего элемента.", "fa_IR": "شاخص مورد فعلی."},
    "Editable": {"zh_CN": "可编辑", "zh_TW": "可編輯", "ru_RU": "Редактируемый", "fa_IR": "قابل ویرایش"},
    "Whether the combo box is editable.": {"zh_CN": "组合框是否可编辑。", "zh_TW": "組合方塊是否可編輯。", "ru_RU": "Можно ли редактировать выпадающий список.", "fa_IR": "آیا کومبو باکس قابل ویرایش است."},
    "Whether the combo box button is flat.": {"zh_CN": "组合框按钮是否为平面样式。", "zh_TW": "組合方塊按鈕是否為平面樣式。", "ru_RU": "Является ли кнопка списка плоской.", "fa_IR": "آیا دکمه کومبو باکس مسطح است."},
    "DisplayText": {"zh_CN": "显示文本", "zh_TW": "顯示文字", "ru_RU": "Отображаемый текст", "fa_IR": "متن نمایش"},
    "Holds the text that is displayed on the combo box button.": {"zh_CN": "保存在组合框按钮上显示的文本。", "zh_TW": "保存在組合方塊按鈕上顯示的文字。", "ru_RU": "Содержит текст, отображаемый на кнопке списка.", "fa_IR": "متنی که روی دکمه کومبو باکس نمایش داده می‌شود."},

    # Container & Control
    "Container": {"zh_CN": "容器", "zh_TW": "容器", "ru_RU": "Контейнер", "fa_IR": "ظرف"},
    "Control": {"zh_CN": "控件", "zh_TW": "控制項", "ru_RU": "Элемент управления", "fa_IR": "کنترل"},
    "Enabled": {"zh_CN": "启用", "zh_TW": "啟用", "ru_RU": "Включено", "fa_IR": "فعال"},
    "Whether the control is enabled.": {"zh_CN": "控件是否启用。", "zh_TW": "控制項是否啟用。", "ru_RU": "Включен ли элемент управления.", "fa_IR": "آیا کنترل فعال است."},
    "Focus Policy": {"zh_CN": "焦点策略", "zh_TW": "焦點策略", "ru_RU": "Политика фокуса", "fa_IR": "سیاست فوکوس"},
    "Focus policy of the control.": {"zh_CN": "控件的焦点策略。", "zh_TW": "控制項的焦點策略。", "ru_RU": "Политика фокуса элемента управления.", "fa_IR": "سیاست فوکوس کنترل."},
    "Hover": {"zh_CN": "悬停", "zh_TW": "懸停", "ru_RU": "Наведение", "fa_IR": "شناور"},
    "Whether control accepts hover events.": {"zh_CN": "控件是否接受悬停事件。", "zh_TW": "控制項是否接受懸停事件。", "ru_RU": "Принимает ли элемент события наведения.", "fa_IR": "آیا کنترل رویدادهای شناور را می‌پذیرد."},
    "Spacing": {"zh_CN": "间距", "zh_TW": "間距", "ru_RU": "Интервал", "fa_IR": "فاصله"},
    "Spacing between internal elements of the control.": {"zh_CN": "控件内部元素之间的间距。", "zh_TW": "控制項內部元素之間的間距。", "ru_RU": "Интервал между внутренними элементами управления.", "fa_IR": "فاصله بین عناصر داخلی کنترل."},
    "Wheel": {"zh_CN": "滚轮", "zh_TW": "滾輪", "ru_RU": "Колесико", "fa_IR": "چرخ"},
    "Whether control accepts wheel events.": {"zh_CN": "控件是否接受滚轮事件。", "zh_TW": "控制項是否接受滾輪事件。", "ru_RU": "Принимает ли элемент события колесика мыши.", "fa_IR": "آیا کنترل رویدادهای چرخ را می‌پذیرد."},

    # Connection View Model
    "Reconnecting...": {"zh_CN": "重新连接中...", "zh_TW": "重新連接中...", "ru_RU": "Переподключение...", "fa_IR": "در حال اتصال مجدد..."},
    "Connection Error": {"zh_CN": "连接错误", "zh_TW": "連接錯誤", "ru_RU": "Ошибка подключения", "fa_IR": "خطای اتصال"},
    "Unknown Status": {"zh_CN": "未知状态", "zh_TW": "未知狀態", "ru_RU": "Неизвестное состояние", "fa_IR": "وضعیت نامشخص"},
    "None": {"zh_CN": "无", "zh_TW": "無", "ru_RU": "Нет", "fa_IR": "هیچ"},

    # DelayButton
    "DelayButton": {"zh_CN": "延迟按钮", "zh_TW": "延遲按鈕", "ru_RU": "Кнопка с задержкой", "fa_IR": "دکمه تاخیری"},
    "Delay": {"zh_CN": "延迟", "zh_TW": "延遲", "ru_RU": "Задержка", "fa_IR": "تاخیر"},
    "The delay in milliseconds.": {"zh_CN": "延迟时间（毫秒）。", "zh_TW": "延遲時間（毫秒）。", "ru_RU": "Задержка в миллисекундах.", "fa_IR": "تاخیر به میلی‌ثانیه."},

    # Dial
    "Dial": {"zh_CN": "刻度盘", "zh_TW": "刻度盤", "ru_RU": "Циферблат", "fa_IR": "صفحه"},
    "Value": {"zh_CN": "值", "zh_TW": "值", "ru_RU": "Значение", "fa_IR": "مقدار"},
    "The current value of the dial.": {"zh_CN": "刻度盘的当前值。", "zh_TW": "刻度盤的目前值。", "ru_RU": "Текущее значение циферблата.", "fa_IR": "مقدار فعلی صفحه."},
    "From": {"zh_CN": "从", "zh_TW": "從", "ru_RU": "От", "fa_IR": "از"},
    "The starting value of the dial range.": {"zh_CN": "刻度盘范围的起始值。", "zh_TW": "刻度盤範圍的起始值。", "ru_RU": "Начальное значение диапазона циферблата.", "fa_IR": "مقدار شروع محدوده صفحه."},
    "To": {"zh_CN": "到", "zh_TW": "到", "ru_RU": "До", "fa_IR": "تا"},
    "The ending value of the dial range.": {"zh_CN": "刻度盘范围的结束值。", "zh_TW": "刻度盤範圍的結束值。", "ru_RU": "Конечное значение диапазона циферблата.", "fa_IR": "مقدار پایان محدوده صفحه."},
    "Step Size": {"zh_CN": "步长", "zh_TW": "步長", "ru_RU": "Размер шага", "fa_IR": "اندازه گام"},
    "The step size of the dial.": {"zh_CN": "刻度盘的步长。", "zh_TW": "刻度盤的步長。", "ru_RU": "Размер шага циферблата.", "fa_IR": "اندازه گام صفحه."},
    "Snap Mode": {"zh_CN": "吸附模式", "zh_TW": "吸附模式", "ru_RU": "Режим привязки", "fa_IR": "حالت چسبیدن"},
    "The snap mode of the dial.": {"zh_CN": "刻度盘的吸附模式。", "zh_TW": "刻度盤的吸附模式。", "ru_RU": "Режим привязки циферблата.", "fa_IR": "حالت چسبیدن صفحه."},
    "Live": {"zh_CN": "实时", "zh_TW": "即時", "ru_RU": "В реальном времени", "fa_IR": "زنده"},
    "Whether the dial provides live value updates.": {"zh_CN": "刻度盘是否提供实时值更新。", "zh_TW": "刻度盤是否提供即時值更新。", "ru_RU": "Обновляет ли циферблат значения в реальном времени.", "fa_IR": "آیا صفحه به‌روزرسانی‌های زنده ارائه می‌دهد."},
    "Input Mode": {"zh_CN": "输入模式", "zh_TW": "輸入模式", "ru_RU": "Режим ввода", "fa_IR": "حالت ورودی"},
    "How the dial tracks movement.": {"zh_CN": "刻度盘如何跟踪移动。", "zh_TW": "刻度盤如何跟蹤移動。", "ru_RU": "Как циферблат отслеживает движение.", "fa_IR": "نحوه ردیابی حرکت توسط صفحه."},
    "Wrap": {"zh_CN": "循环", "zh_TW": "循環", "ru_RU": "Зацикливание", "fa_IR": "حلقه"},
    "Whether the dial wraps when dragged.": {"zh_CN": "拖动时刻度盘是否循环。", "zh_TW": "拖動時刻度盤是否循環。", "ru_RU": "Зацикливается ли циферблат при перетаскивании.", "fa_IR": "آیا صفحه هنگام کشیدن حلقه می‌شود."},

    # File Dialog
    "Overwrite file?": {"zh_CN": "覆盖文件？", "zh_TW": "覆寫檔案？", "ru_RU": "Перезаписать файл?", "fa_IR": "بازنویسی فایل؟"},
    "\"%1\" already exists.\nDo you want to replace it?": {"zh_CN": "\"%1\" 已存在。\n是否替换？", "zh_TW": "\"%1\" 已存在。\n是否取代？", "ru_RU": "\"%1\" уже существует.\nЗаменить его?", "fa_IR": "\"%1\" از قبل وجود دارد.\nآیا می‌خواهید آن را جایگزین کنید?"},
    "File name": {"zh_CN": "文件名", "zh_TW": "檔案名稱", "ru_RU": "Имя файла", "fa_IR": "نام فایل"},
    "Folder": {"zh_CN": "文件夹", "zh_TW": "資料夾", "ru_RU": "Папка", "fa_IR": "پوشه"},

    # Font Dialog
    "Font": {"zh_CN": "字体", "zh_TW": "字型", "ru_RU": "Шрифт", "fa_IR": "فونت"},

    # Frame & GroupBox
    "Frame": {"zh_CN": "框架", "zh_TW": "框架", "ru_RU": "Рамка", "fa_IR": "قاب"},
    "GroupBox": {"zh_CN": "分组框", "zh_TW": "群組方塊", "ru_RU": "Группа", "fa_IR": "گروه‌بندی"},
    "Title": {"zh_CN": "标题", "zh_TW": "標題", "ru_RU": "Заголовок", "fa_IR": "عنوان"},

    # ItemDelegate
    "ItemDelegate": {"zh_CN": "项目代理", "zh_TW": "項目代理", "ru_RU": "Делегат элемента", "fa_IR": "نماینده مورد"},

    # Label
    "Label": {"zh_CN": "标签", "zh_TW": "標籤", "ru_RU": "Метка", "fa_IR": "برچسب"},

    # Page
    "Page": {"zh_CN": "页面", "zh_TW": "頁面", "ru_RU": "Страница", "fa_IR": "صفحه"},
    "Header": {"zh_CN": "页眉", "zh_TW": "頁首", "ru_RU": "Заголовок", "fa_IR": "سربرگ"},
    "Footer": {"zh_CN": "页脚", "zh_TW": "頁尾", "ru_RU": "Нижний колонтитул", "fa_IR": "پاورقی"},

    # PageIndicator
    "PageIndicator": {"zh_CN": "页面指示器", "zh_TW": "頁面指示器", "ru_RU": "Индикатор страниц", "fa_IR": "نشانگر صفحه"},
    "Count": {"zh_CN": "计数", "zh_TW": "計數", "ru_RU": "Количество", "fa_IR": "تعداد"},
    "Interactive": {"zh_CN": "交互式", "zh_TW": "互動式", "ru_RU": "Интерактивный", "fa_IR": "تعاملی"},
    "The number of pages.": {"zh_CN": "页面数量。", "zh_TW": "頁面數量。", "ru_RU": "Количество страниц.", "fa_IR": "تعداد صفحات."},
    "Whether the indicator is interactive.": {"zh_CN": "指示器是否可交互。", "zh_TW": "指示器是否可互動。", "ru_RU": "Является ли индикатор интерактивным.", "fa_IR": "آیا نشانگر تعاملی است."},

    # Pane & Popup
    "Pane": {"zh_CN": "面板", "zh_TW": "面板", "ru_RU": "Панель", "fa_IR": "پنل"},
    "Popup": {"zh_CN": "弹出窗口", "zh_TW": "彈出視窗", "ru_RU": "Всплывающее окно", "fa_IR": "پنجره بازشو"},
    "Dim": {"zh_CN": "变暗", "zh_TW": "變暗", "ru_RU": "Затемнение", "fa_IR": "تیره"},
    "Whether the popup dims the background.": {"zh_CN": "弹出窗口是否使背景变暗。", "zh_TW": "彈出視窗是否使背景變暗。", "ru_RU": "Затемняет ли всплывающее окно фон.", "fa_IR": "آیا پنجره بازشو پس‌زمینه را تیره می‌کند."},
    "Modal": {"zh_CN": "模态", "zh_TW": "強制回應", "ru_RU": "Модальное", "fa_IR": "مودال"},
    "Whether the popup is modal.": {"zh_CN": "弹出窗口是否为模态。", "zh_TW": "彈出視窗是否為強制回應。", "ru_RU": "Является ли всплывающее окно модальным.", "fa_IR": "آیا پنجره بازشو مودال است."},
    "Close Policy": {"zh_CN": "关闭策略", "zh_TW": "關閉策略", "ru_RU": "Политика закрытия", "fa_IR": "سیاست بستن"},
    "Determines the circumstances under which the popup closes.": {"zh_CN": "确定弹出窗口关闭的条件。", "zh_TW": "確定彈出視窗關閉的條件。", "ru_RU": "Определяет условия закрытия всплывающего окна.", "fa_IR": "شرایطی که پنجره بازشو بسته می‌شود را تعیین می‌کند."},

    # ProgressBar
    "ProgressBar": {"zh_CN": "进度条", "zh_TW": "進度列", "ru_RU": "Прогресс-бар", "fa_IR": "نوار پیشرفت"},
    "Indeterminate": {"zh_CN": "不确定", "zh_TW": "不確定", "ru_RU": "Неопределенный", "fa_IR": "نامشخص"},
    "Whether the progress is indeterminate.": {"zh_CN": "进度是否不确定。", "zh_TW": "進度是否不確定。", "ru_RU": "Является ли прогресс неопределенным.", "fa_IR": "آیا پیشرفت نامشخص است."},

    # RadioButton & RadioDelegate
    "RadioButton": {"zh_CN": "单选按钮", "zh_TW": "選項按鈕", "ru_RU": "Переключатель", "fa_IR": "دکمه رادیویی"},
    "RadioDelegate": {"zh_CN": "单选代理", "zh_TW": "選項代理", "ru_RU": "Делегат переключателя", "fa_IR": "نماینده رادیویی"},

    # RangeSlider
    "RangeSlider": {"zh_CN": "范围滑块", "zh_TW": "範圍滑桿", "ru_RU": "Диапазонный слайдер", "fa_IR": "اسلایدر محدوده"},
    "Orientation": {"zh_CN": "方向", "zh_TW": "方向", "ru_RU": "Ориентация", "fa_IR": "جهت"},
    "The orientation of the slider.": {"zh_CN": "滑块的方向。", "zh_TW": "滑桿的方向。", "ru_RU": "Ориентация слайдера.", "fa_IR": "جهت اسلایدر."},
    "The snap mode of the slider.": {"zh_CN": "滑块的吸附模式。", "zh_TW": "滑桿的吸附模式。", "ru_RU": "Режим привязки слайдера.", "fa_IR": "حالت چسبیدن اسلایدر."},
    "First Value": {"zh_CN": "第一个值", "zh_TW": "第一個值", "ru_RU": "Первое значение", "fa_IR": "مقدار اول"},
    "The first value in the range.": {"zh_CN": "范围内的第一个值。", "zh_TW": "範圍內的第一個值。", "ru_RU": "Первое значение в диапазоне.", "fa_IR": "مقدار اول در محدوده."},
    "Second Value": {"zh_CN": "第二个值", "zh_TW": "第二個值", "ru_RU": "Второе значение", "fa_IR": "مقدار دوم"},
    "The second value in the range.": {"zh_CN": "范围内的第二个值。", "zh_TW": "範圍內的第二個值。", "ru_RU": "Второе значение в диапазоне.", "fa_IR": "مقدار دوم در محدوده."},

    # RoundButton
    "RoundButton": {"zh_CN": "圆形按钮", "zh_TW": "圓形按鈕", "ru_RU": "Круглая кнопка", "fa_IR": "دکمه گرد"},
    "Radius": {"zh_CN": "半径", "zh_TW": "半徑", "ru_RU": "Радиус", "fa_IR": "شعاع"},
    "The radius of the button.": {"zh_CN": "按钮的半径。", "zh_TW": "按鈕的半徑。", "ru_RU": "Радиус кнопки.", "fa_IR": "شعاع دکمه."},

    # ScrollBar & ScrollIndicator & ScrollView
    "ScrollBar": {"zh_CN": "滚动条", "zh_TW": "捲軸", "ru_RU": "Полоса прокрутки", "fa_IR": "نوار پیمایش"},
    "Active": {"zh_CN": "活动", "zh_TW": "活動", "ru_RU": "Активный", "fa_IR": "فعال"},
    "Whether the scrollbar is active.": {"zh_CN": "滚动条是否活动。", "zh_TW": "捲軸是否活動。", "ru_RU": "Активна ли полоса прокрутки.", "fa_IR": "آیا نوار پیمایش فعال است."},
    "Policy": {"zh_CN": "策略", "zh_TW": "策略", "ru_RU": "Политика", "fa_IR": "سیاست"},
    "Determines when the scrollbar is visible.": {"zh_CN": "确定滚动条何时可见。", "zh_TW": "確定捲軸何時可見。", "ru_RU": "Определяет, когда полоса прокрутки видима.", "fa_IR": "تعیین می‌کند که نوار پیمایش چه زمانی قابل مشاهده است."},
    "Size": {"zh_CN": "大小", "zh_TW": "大小", "ru_RU": "Размер", "fa_IR": "اندازه"},
    "Position": {"zh_CN": "位置", "zh_TW": "位置", "ru_RU": "Позиция", "fa_IR": "موقعیت"},
    "The size of the scrollbar.": {"zh_CN": "滚动条的大小。", "zh_TW": "捲軸的大小。", "ru_RU": "Размер полосы прокрутки.", "fa_IR": "اندازه نوار پیمایش."},
    "The position of the scrollbar.": {"zh_CN": "滚动条的位置。", "zh_TW": "捲軸的位置。", "ru_RU": "Позиция полосы прокрутки.", "fa_IR": "موقعیت نوار پیمایش."},
    "ScrollIndicator": {"zh_CN": "滚动指示器", "zh_TW": "捲動指示器", "ru_RU": "Индикатор прокрутки", "fa_IR": "نشانگر پیمایش"},
    "ScrollView": {"zh_CN": "滚动视图", "zh_TW": "捲動檢視", "ru_RU": "Область прокрутки", "fa_IR": "نمای پیمایش"},

    # Slider
    "Slider": {"zh_CN": "滑块", "zh_TW": "滑桿", "ru_RU": "Слайдер", "fa_IR": "اسلایدر"},
    "Whether the slider provides live value updates.": {"zh_CN": "滑块是否提供实时值更新。", "zh_TW": "滑桿是否提供即時值更新。", "ru_RU": "Обновляет ли слайдер значения в реальном времени.", "fa_IR": "آیا اسلایدر به‌روزرسانی‌های زنده ارائه می‌دهد."},
    "Handle": {"zh_CN": "手柄", "zh_TW": "手把", "ru_RU": "Ручка", "fa_IR": "دسته"},
    "Pressed": {"zh_CN": "按下", "zh_TW": "按下", "ru_RU": "Нажато", "fa_IR": "فشرده شده"},
    "Whether the slider handle is pressed.": {"zh_CN": "滑块手柄是否被按下。", "zh_TW": "滑桿手把是否被按下。", "ru_RU": "Нажата ли ручка слайдера.", "fa_IR": "آیا دسته اسلایدر فشرده شده است."},

    # SpinBox
    "SpinBox": {"zh_CN": "微调框", "zh_TW": "微調方塊", "ru_RU": "Счетчик", "fa_IR": "جعبه چرخشی"},
    "The amount by which the spin box value changes when using the up and down buttons.": {"zh_CN": "使用上下按钮时微调框值的变化量。", "zh_TW": "使用上下按鈕時微調方塊值的變化量。", "ru_RU": "Величина изменения значения счетчика при нажатии кнопок вверх и вниз.", "fa_IR": "مقدار تغییر مقدار جعبه چرخشی هنگام استفاده از دکمه‌های بالا و پایین."},
    "Whether the spin box wraps around.": {"zh_CN": "微调框是否循环。", "zh_TW": "微調方塊是否循環。", "ru_RU": "Зацикливается ли счетчик.", "fa_IR": "آیا جعبه چرخشی حلقه می‌شود."},

    # SplitView
    "SplitView": {"zh_CN": "分割视图", "zh_TW": "分割檢視", "ru_RU": "Разделенное представление", "fa_IR": "نمای تقسیم"},
    "Resizing": {"zh_CN": "调整大小", "zh_TW": "調整大小", "ru_RU": "Изменение размера", "fa_IR": "تغییر اندازه"},
    "Whether the handles are resizable.": {"zh_CN": "手柄是否可调整大小。", "zh_TW": "手把是否可調整大小。", "ru_RU": "Можно ли изменять размер ручек.", "fa_IR": "آیا دسته‌ها قابل تغییر اندازه هستند."},

    # StackView
    "StackView": {"zh_CN": "堆栈视图", "zh_TW": "堆疊檢視", "ru_RU": "Стек представлений", "fa_IR": "نمای پشته"},
    "Depth": {"zh_CN": "深度", "zh_TW": "深度", "ru_RU": "Глубина", "fa_IR": "عمق"},
    "The number of views currently on the stack.": {"zh_CN": "当前堆栈上的视图数量。", "zh_TW": "目前堆疊上的檢視數量。", "ru_RU": "Количество представлений в стеке.", "fa_IR": "تعداد نماهای فعلی در پشته."},
    "Initial Item": {"zh_CN": "初始项", "zh_TW": "初始項目", "ru_RU": "Начальный элемент", "fa_IR": "مورد اولیه"},
    "The initial item in the stack.": {"zh_CN": "堆栈中的初始项。", "zh_TW": "堆疊中的初始項目。", "ru_RU": "Начальный элемент в стеке.", "fa_IR": "مورد اولیه در پشته."},

    # SwipeDelegate & SwipeView
    "SwipeDelegate": {"zh_CN": "滑动代理", "zh_TW": "滑動代理", "ru_RU": "Делегат смахивания", "fa_IR": "نماینده کشیدن"},
    "SwipeView": {"zh_CN": "滑动视图", "zh_TW": "滑動檢視", "ru_RU": "Представление смахивания", "fa_IR": "نمای کشیدن"},

    # Switch & SwitchDelegate
    "Switch": {"zh_CN": "开关", "zh_TW": "開關", "ru_RU": "Переключатель", "fa_IR": "سوئیچ"},
    "SwitchDelegate": {"zh_CN": "开关代理", "zh_TW": "開關代理", "ru_RU": "Делегат переключателя", "fa_IR": "نماینده سوئیچ"},

    # TabBar & TabButton
    "TabBar": {"zh_CN": "标签栏", "zh_TW": "標籤列", "ru_RU": "Панель вкладок", "fa_IR": "نوار برگه"},
    "TabButton": {"zh_CN": "标签按钮", "zh_TW": "標籤按鈕", "ru_RU": "Кнопка вкладки", "fa_IR": "دکمه برگه"},

    # TextArea & TextField
    "TextArea": {"zh_CN": "文本区域", "zh_TW": "文字區域", "ru_RU": "Текстовая область", "fa_IR": "ناحیه متن"},
    "TextField": {"zh_CN": "文本框", "zh_TW": "文字方塊", "ru_RU": "Текстовое поле", "fa_IR": "فیلد متن"},
    "Placeholder": {"zh_CN": "占位符", "zh_TW": "預留位置", "ru_RU": "Заполнитель", "fa_IR": "جای‌نما"},
    "Read Only": {"zh_CN": "只读", "zh_TW": "唯讀", "ru_RU": "Только чтение", "fa_IR": "فقط خواندنی"},
    "Whether the text field is read only.": {"zh_CN": "文本框是否只读。", "zh_TW": "文字方塊是否唯讀。", "ru_RU": "Доступно ли текстовое поле только для чтения.", "fa_IR": "آیا فیلد متن فقط خواندنی است."},

    # ToolBar, ToolButton, ToolSeparator
    "ToolBar": {"zh_CN": "工具栏", "zh_TW": "工具列", "ru_RU": "Панель инструментов", "fa_IR": "نوار ابزار"},
    "ToolButton": {"zh_CN": "工具按钮", "zh_TW": "工具按鈕", "ru_RU": "Кнопка инструмента", "fa_IR": "دکمه ابزار"},
    "ToolSeparator": {"zh_CN": "工具分隔符", "zh_TW": "工具分隔符", "ru_RU": "Разделитель инструментов", "fa_IR": "جداکننده ابزار"},

    # ToolTip
    "ToolTip": {"zh_CN": "工具提示", "zh_TW": "工具提示", "ru_RU": "Всплывающая подсказка", "fa_IR": "راهنمای ابزار"},
    "The timeout after which the tooltip is hidden.": {"zh_CN": "工具提示隐藏的超时时间。", "zh_TW": "工具提示隱藏的逾時時間。", "ru_RU": "Время, после которого подсказка скрывается.", "fa_IR": "زمان پس از آن راهنما پنهان می‌شود."},
    "The delay after which the tooltip is shown.": {"zh_CN": "工具提示显示的延迟时间。", "zh_TW": "工具提示顯示的延遲時間。", "ru_RU": "Задержка перед показом подсказки.", "fa_IR": "تاخیر قبل از نمایش راهنما."},

    # Tumbler
    "Tumbler": {"zh_CN": "滚筒选择器", "zh_TW": "滾筒選擇器", "ru_RU": "Барабан", "fa_IR": "چرخ انتخاب"},
    "Visible Count": {"zh_CN": "可见数量", "zh_TW": "可見數量", "ru_RU": "Видимое количество", "fa_IR": "تعداد قابل مشاهده"},
    "The number of items visible in the tumbler.": {"zh_CN": "滚筒选择器中可见的项目数量。", "zh_TW": "滾筒選擇器中可見的項目數量。", "ru_RU": "Количество видимых элементов в барабане.", "fa_IR": "تعداد موارد قابل مشاهده در چرخ انتخاب."},

    # Old password errors from AuthManager
    "Old password is incorrect": {"zh_CN": "旧密码错误", "zh_TW": "舊密碼錯誤", "ru_RU": "Старый пароль неверен", "fa_IR": "رمز قدیمی نادرست است"},
    "Password change failed": {"zh_CN": "密码修改失败", "zh_TW": "密碼修改失敗", "ru_RU": "Ошибка смены пароля", "fa_IR": "تغییر رمز ناموفق بود"},

    # Additional common terms
    "Unknown": {"zh_CN": "未知", "zh_TW": "未知", "ru_RU": "Неизвестно", "fa_IR": "نامشخص"},
    "Antarctica": {"zh_CN": "南极洲", "zh_TW": "南極洲", "ru_RU": "Антарктида", "fa_IR": "جنوبگان"},
    "United States": {"zh_CN": "美国", "zh_TW": "美國", "ru_RU": "США", "fa_IR": "ایالات متحده"},
    "United Kingdom": {"zh_CN": "英国", "zh_TW": "英國", "ru_RU": "Великобритания", "fa_IR": "بریتانیا"},
    "Japan": {"zh_CN": "日本", "zh_TW": "日本", "ru_RU": "Япония", "fa_IR": "ژاپن"},
    "South Korea": {"zh_CN": "韩国", "zh_TW": "韓國", "ru_RU": "Южная Корея", "fa_IR": "کره جنوبی"},
    "Hong Kong": {"zh_CN": "香港", "zh_TW": "香港", "ru_RU": "Гонконг", "fa_IR": "هنگ کنگ"},
    "Taiwan": {"zh_CN": "台湾", "zh_TW": "台灣", "ru_RU": "Тайвань", "fa_IR": "تایوان"},
    "Singapore": {"zh_CN": "新加坡", "zh_TW": "新加坡", "ru_RU": "Сингапур", "fa_IR": "سنگاپور"},
    "Germany": {"zh_CN": "德国", "zh_TW": "德國", "ru_RU": "Германия", "fa_IR": "آلمان"},
    "France": {"zh_CN": "法国", "zh_TW": "法國", "ru_RU": "Франция", "fa_IR": "فرانسه"},
    "Canada": {"zh_CN": "加拿大", "zh_TW": "加拿大", "ru_RU": "Канада", "fa_IR": "کانادا"},
    "Australia": {"zh_CN": "澳大利亚", "zh_TW": "澳洲", "ru_RU": "Австралия", "fa_IR": "استرالیا"},
    "India": {"zh_CN": "印度", "zh_TW": "印度", "ru_RU": "Индия", "fa_IR": "هند"},
    "Brazil": {"zh_CN": "巴西", "zh_TW": "巴西", "ru_RU": "Бразилия", "fa_IR": "برزیل"},
    "Netherlands": {"zh_CN": "荷兰", "zh_TW": "荷蘭", "ru_RU": "Нидерланды", "fa_IR": "هلند"},
    "Sweden": {"zh_CN": "瑞典", "zh_TW": "瑞典", "ru_RU": "Швеция", "fa_IR": "سوئد"},
    "Switzerland": {"zh_CN": "瑞士", "zh_TW": "瑞士", "ru_RU": "Швейцария", "fa_IR": "سوئیس"},
    "Italy": {"zh_CN": "意大利", "zh_TW": "義大利", "ru_RU": "Италия", "fa_IR": "ایتالیا"},
    "Spain": {"zh_CN": "西班牙", "zh_TW": "西班牙", "ru_RU": "Испания", "fa_IR": "اسپانیا"},

    # Time format strings
    "%1 / %2 (remaining %3)": {"zh_CN": "%1 / %2 (剩余 %3)", "zh_TW": "%1 / %2 (剩餘 %3)", "ru_RU": "%1 / %2 (осталось %3)", "fa_IR": "%1 / %2 (باقی‌مانده %3)"},
    "%1 GB": {"zh_CN": "%1 GB", "zh_TW": "%1 GB", "ru_RU": "%1 ГБ", "fa_IR": "%1 گیگابایت"},
    "%1 Mbps": {"zh_CN": "%1 Mbps", "zh_TW": "%1 Mbps", "ru_RU": "%1 Мбит/с", "fa_IR": "%1 مگابیت بر ثانیه"},
    "%1 days ago": {"zh_CN": "%1 天前", "zh_TW": "%1 天前", "ru_RU": "%1 дней назад", "fa_IR": "%1 روز پیش"},
    "%1 days later": {"zh_CN": "%1 天后", "zh_TW": "%1 天後", "ru_RU": "через %1 дней", "fa_IR": "%1 روز بعد"},
    "%1 devices": {"zh_CN": "%1 台设备", "zh_TW": "%1 台設備", "ru_RU": "%1 устройств", "fa_IR": "%1 دستگاه"},
    "%1 hours ago": {"zh_CN": "%1 小时前", "zh_TW": "%1 小時前", "ru_RU": "%1 часов назад", "fa_IR": "%1 ساعت پیش"},
    "%1 hours later": {"zh_CN": "%1 小时后", "zh_TW": "%1 小時後", "ru_RU": "через %1 часов", "fa_IR": "%1 ساعت بعد"},
    "%1 minutes ago": {"zh_CN": "%1 分钟前", "zh_TW": "%1 分鐘前", "ru_RU": "%1 минут назад", "fa_IR": "%1 دقیقه پیش"},
    "%1 minutes later": {"zh_CN": "%1 分钟后", "zh_TW": "%1 分鐘後", "ru_RU": "через %1 минут", "fa_IR": "%1 دقیقه بعد"},
    "%1 months ago": {"zh_CN": "%1 个月前", "zh_TW": "%1 個月前", "ru_RU": "%1 месяцев назад", "fa_IR": "%1 ماه پیش"},
    "%1 online": {"zh_CN": "%1 在线", "zh_TW": "%1 在線", "ru_RU": "%1 онлайн", "fa_IR": "%1 آنلاین"},
    "%1 seconds ago": {"zh_CN": "%1 秒前", "zh_TW": "%1 秒前", "ru_RU": "%1 секунд назад", "fa_IR": "%1 ثانیه پیش"},
    "%1 seconds later": {"zh_CN": "%1 秒后", "zh_TW": "%1 秒後", "ru_RU": "через %1 секунд", "fa_IR": "%1 ثانیه بعد"},
    "Just now": {"zh_CN": "刚刚", "zh_TW": "剛剛", "ru_RU": "Только что", "fa_IR": "همین الان"},
    "on %1": {"zh_CN": "于 %1", "zh_TW": "於 %1", "ru_RU": "на %1", "fa_IR": "در %1"},

    # Speed test settings
    "100MB: Accurate test (~30-60 seconds)": {"zh_CN": "100MB：精确测试（约30-60秒）", "zh_TW": "100MB：精確測試（約30-60秒）", "ru_RU": "100MB: Точный тест (~30-60 сек)", "fa_IR": "100MB: تست دقیق (~30-60 ثانیه)"},
    "10MB: Quick test (~5-10 seconds)": {"zh_CN": "10MB：快速测试（约5-10秒）", "zh_TW": "10MB：快速測試（約5-10秒）", "ru_RU": "10MB: Быстрый тест (~5-10 сек)", "fa_IR": "10MB: تست سریع (~5-10 ثانیه)"},
    "25MB: Standard test (~10-20 seconds)": {"zh_CN": "25MB：标准测试（约10-20秒）", "zh_TW": "25MB：標準測試（約10-20秒）", "ru_RU": "25MB: Стандартный тест (~10-20 сек)", "fa_IR": "25MB: تست استاندارد (~10-20 ثانیه)"},
    "Speed Test File Size": {"zh_CN": "测速文件大小", "zh_TW": "測速檔案大小", "ru_RU": "Размер файла теста скорости", "fa_IR": "اندازه فایل تست سرعت"},
    "Speed:": {"zh_CN": "速度：", "zh_TW": "速度：", "ru_RU": "Скорость:", "fa_IR": "سرعت:"},

    # Subscription periods
    "2 Years": {"zh_CN": "2年", "zh_TW": "2年", "ru_RU": "2 года", "fa_IR": "2 سال"},
    "3 Years": {"zh_CN": "3年", "zh_TW": "3年", "ru_RU": "3 года", "fa_IR": "3 سال"},
    "Annual": {"zh_CN": "年付", "zh_TW": "年付", "ru_RU": "Годовой", "fa_IR": "سالانه"},
    "Monthly": {"zh_CN": "月付", "zh_TW": "月付", "ru_RU": "Ежемесячно", "fa_IR": "ماهانه"},
    "Quarterly": {"zh_CN": "季付", "zh_TW": "季付", "ru_RU": "Ежеквартально", "fa_IR": "سه ماهه"},
    "Semi-Annual": {"zh_CN": "半年付", "zh_TW": "半年付", "ru_RU": "Полугодовой", "fa_IR": "شش ماهه"},
    "Yearly": {"zh_CN": "年付", "zh_TW": "年付", "ru_RU": "Ежегодно", "fa_IR": "سالانه"},
    "One-time": {"zh_CN": "一次性", "zh_TW": "一次性", "ru_RU": "Единоразово", "fa_IR": "یک‌بار"},
    "One-time payment, no renewal": {"zh_CN": "一次性付款，无需续费", "zh_TW": "一次性付款，無需續費", "ru_RU": "Одноразовый платеж, без продления", "fa_IR": "پرداخت یک‌بار، بدون تمدید"},
    "Unknown Period": {"zh_CN": "未知周期", "zh_TW": "未知週期", "ru_RU": "Неизвестный период", "fa_IR": "دوره نامشخص"},

    # Billing strings
    "Billed annually - Best value!": {"zh_CN": "按年计费 - 最超值！", "zh_TW": "按年計費 - 最超值！", "ru_RU": "Ежегодная оплата - лучшая цена!", "fa_IR": "صورتحساب سالانه - بهترین ارزش!"},
    "Billed every 2 years": {"zh_CN": "每2年计费", "zh_TW": "每2年計費", "ru_RU": "Оплата каждые 2 года", "fa_IR": "صورتحساب هر 2 سال"},
    "Billed every 3 months": {"zh_CN": "每3个月计费", "zh_TW": "每3個月計費", "ru_RU": "Оплата каждые 3 месяца", "fa_IR": "صورتحساب هر 3 ماه"},
    "Billed every 3 years": {"zh_CN": "每3年计费", "zh_TW": "每3年計費", "ru_RU": "Оплата каждые 3 года", "fa_IR": "صورتحساب هر 3 سال"},
    "Billed every 6 months": {"zh_CN": "每6个月计费", "zh_TW": "每6個月計費", "ru_RU": "Оплата каждые 6 месяцев", "fa_IR": "صورتحساب هر 6 ماه"},
    "Billed monthly": {"zh_CN": "按月计费", "zh_TW": "按月計費", "ru_RU": "Ежемесячная оплата", "fa_IR": "صورتحساب ماهانه"},
    "Choose your billing cycle:": {"zh_CN": "选择计费周期：", "zh_TW": "選擇計費週期：", "ru_RU": "Выберите период оплаты:", "fa_IR": "دوره صورتحساب را انتخاب کنید:"},
    "Day %1 of each month": {"zh_CN": "每月第 %1 天", "zh_TW": "每月第 %1 天", "ru_RU": "День %1 каждого месяца", "fa_IR": "روز %1 هر ماه"},
    "≈ %1%2/mo": {"zh_CN": "≈ %1%2/月", "zh_TW": "≈ %1%2/月", "ru_RU": "≈ %1%2/мес", "fa_IR": "≈ %1%2/ماه"},

    # Payment/Store strings
    "Amount to Pay": {"zh_CN": "应付金额", "zh_TW": "應付金額", "ru_RU": "Сумма к оплате", "fa_IR": "مبلغ قابل پرداخت"},
    "Continue": {"zh_CN": "继续", "zh_TW": "繼續", "ru_RU": "Продолжить", "fa_IR": "ادامه"},
    "Device Limit:": {"zh_CN": "设备限制：", "zh_TW": "設備限制：", "ru_RU": "Лимит устройств:", "fa_IR": "محدودیت دستگاه:"},
    "Devices:": {"zh_CN": "设备：", "zh_TW": "設備：", "ru_RU": "Устройства:", "fa_IR": "دستگاه‌ها:"},
    "Discount:": {"zh_CN": "折扣：", "zh_TW": "折扣：", "ru_RU": "Скидка:", "fa_IR": "تخفیف:"},
    "Download Used:": {"zh_CN": "已用下载：", "zh_TW": "已用下載：", "ru_RU": "Использовано загрузки:", "fa_IR": "دانلود استفاده شده:"},
    "Fee: %1%": {"zh_CN": "手续费：%1%", "zh_TW": "手續費：%1%", "ru_RU": "Комиссия: %1%", "fa_IR": "کارمزد: %1%"},
    "Final Amount:": {"zh_CN": "最终金额：", "zh_TW": "最終金額：", "ru_RU": "Итого:", "fa_IR": "مبلغ نهایی:"},
    "Free User": {"zh_CN": "免费用户", "zh_TW": "免費用戶", "ru_RU": "Бесплатный пользователь", "fa_IR": "کاربر رایگان"},
    "Lifetime Member": {"zh_CN": "终身会员", "zh_TW": "終身會員", "ru_RU": "Пожизненный член", "fa_IR": "عضو مادام‌العمر"},
    "Original Price:": {"zh_CN": "原价：", "zh_TW": "原價：", "ru_RU": "Исходная цена:", "fa_IR": "قیمت اصلی:"},
    "Pay Now": {"zh_CN": "立即支付", "zh_TW": "立即付款", "ru_RU": "Оплатить сейчас", "fa_IR": "پرداخت کنید"},
    "Payment Information": {"zh_CN": "支付信息", "zh_TW": "付款資訊", "ru_RU": "Информация об оплате", "fa_IR": "اطلاعات پرداخت"},
    "Period:": {"zh_CN": "周期：", "zh_TW": "週期：", "ru_RU": "Период:", "fa_IR": "دوره:"},
    "Plan #%1": {"zh_CN": "套餐 #%1", "zh_TW": "方案 #%1", "ru_RU": "План #%1", "fa_IR": "طرح #%1"},
    "Plan Information": {"zh_CN": "套餐信息", "zh_TW": "方案資訊", "ru_RU": "Информация о плане", "fa_IR": "اطلاعات طرح"},
    "Plan Name:": {"zh_CN": "套餐名称：", "zh_TW": "方案名稱：", "ru_RU": "Название плана:", "fa_IR": "نام طرح:"},
    "Plan: %1": {"zh_CN": "套餐：%1", "zh_TW": "方案：%1", "ru_RU": "План: %1", "fa_IR": "طرح: %1"},
    "Popular": {"zh_CN": "热门", "zh_TW": "熱門", "ru_RU": "Популярный", "fa_IR": "محبوب"},
    "Purchased": {"zh_CN": "已购买", "zh_TW": "已購買", "ru_RU": "Куплено", "fa_IR": "خریداری شده"},
    "Recommended": {"zh_CN": "推荐", "zh_TW": "推薦", "ru_RU": "Рекомендуемый", "fa_IR": "پیشنهادی"},
    "Select Payment": {"zh_CN": "选择支付方式", "zh_TW": "選擇付款方式", "ru_RU": "Выберите способ оплаты", "fa_IR": "انتخاب پرداخت"},
    "Select Subscription Period": {"zh_CN": "选择订阅周期", "zh_TW": "選擇訂閱週期", "ru_RU": "Выберите период подписки", "fa_IR": "انتخاب دوره اشتراک"},
    "Speed Limit:": {"zh_CN": "速度限制：", "zh_TW": "速度限制：", "ru_RU": "Лимит скорости:", "fa_IR": "محدودیت سرعت:"},
    "Time Information": {"zh_CN": "时间信息", "zh_TW": "時間資訊", "ru_RU": "Информация о времени", "fa_IR": "اطلاعات زمان"},
    "Traffic:": {"zh_CN": "流量：", "zh_TW": "流量：", "ru_RU": "Трафик:", "fa_IR": "ترافیک:"},
    "Upload Used:": {"zh_CN": "已用上传：", "zh_TW": "已用上傳：", "ru_RU": "Использовано отправки:", "fa_IR": "آپلود استفاده شده:"},
    "View Details": {"zh_CN": "查看详情", "zh_TW": "查看詳情", "ru_RU": "Подробнее", "fa_IR": "مشاهده جزئیات"},
    "Hide Details...": {"zh_CN": "隐藏详情...", "zh_TW": "隱藏詳情...", "ru_RU": "Скрыть подробности...", "fa_IR": "پنهان کردن جزئیات..."},
    "Show Details...": {"zh_CN": "显示详情...", "zh_TW": "顯示詳情...", "ru_RU": "Показать подробности...", "fa_IR": "نمایش جزئیات..."},
    "Order Detail": {"zh_CN": "订单详情", "zh_TW": "訂單詳情", "ru_RU": "Детали заказа", "fa_IR": "جزئیات سفارش"},
    "No pricing options available": {"zh_CN": "暂无可用价格选项", "zh_TW": "暫無可用價格選項", "ru_RU": "Нет доступных вариантов цен", "fa_IR": "گزینه قیمت‌گذاری موجود نیست"},

    # Connection status strings
    "Connected (System Proxy)": {"zh_CN": "已连接（系统代理）", "zh_TW": "已連接（系統代理）", "ru_RU": "Подключено (системный прокси)", "fa_IR": "متصل (پروکسی سیستم)"},
    "Connected (TUN Mode)": {"zh_CN": "已连接（TUN模式）", "zh_TW": "已連接（TUN模式）", "ru_RU": "Подключено (режим TUN)", "fa_IR": "متصل (حالت TUN)"},
    "Connected to %1": {"zh_CN": "已连接到 %1", "zh_TW": "已連接到 %1", "ru_RU": "Подключено к %1", "fa_IR": "متصل به %1"},
    "Connecting": {"zh_CN": "正在连接", "zh_TW": "正在連接", "ru_RU": "Подключение", "fa_IR": "در حال اتصال"},
    "Connecting to %1...": {"zh_CN": "正在连接到 %1...", "zh_TW": "正在連接到 %1...", "ru_RU": "Подключение к %1...", "fa_IR": "در حال اتصال به %1..."},
    "Disconnecting": {"zh_CN": "正在断开", "zh_TW": "正在斷開", "ru_RU": "Отключение", "fa_IR": "در حال قطع اتصال"},
    "Preparing to connect...": {"zh_CN": "准备连接...", "zh_TW": "準備連接...", "ru_RU": "Подготовка к подключению...", "fa_IR": "آماده‌سازی برای اتصال..."},
    "Reconnecting": {"zh_CN": "重新连接中", "zh_TW": "重新連接中", "ru_RU": "Переподключение", "fa_IR": "در حال اتصال مجدد"},
    "Starting": {"zh_CN": "正在启动", "zh_TW": "正在啟動", "ru_RU": "Запуск", "fa_IR": "در حال شروع"},
    "Stopped": {"zh_CN": "已停止", "zh_TW": "已停止", "ru_RU": "Остановлено", "fa_IR": "متوقف شده"},
    "Stopping": {"zh_CN": "正在停止", "zh_TW": "正在停止", "ru_RU": "Остановка", "fa_IR": "در حال توقف"},
    "Will reconnect in %1 seconds (attempt %2/%3)": {"zh_CN": "将在 %1 秒后重连（尝试 %2/%3）", "zh_TW": "將在 %1 秒後重連（嘗試 %2/%3）", "ru_RU": "Переподключение через %1 сек (попытка %2/%3)", "fa_IR": "اتصال مجدد در %1 ثانیه (تلاش %2/%3)"},

    # Connection errors
    "ConnectFailed": {"zh_CN": "连接失败", "zh_TW": "連接失敗", "ru_RU": "Ошибка подключения", "fa_IR": "اتصال ناموفق"},
    "ConnectTimeout": {"zh_CN": "连接超时", "zh_TW": "連接逾時", "ru_RU": "Тайм-аут подключения", "fa_IR": "زمان اتصال تمام شد"},
    "Configuration generation failed": {"zh_CN": "配置生成失败", "zh_TW": "設定檔生成失敗", "ru_RU": "Ошибка генерации конфигурации", "fa_IR": "تولید پیکربندی ناموفق بود"},
    "Connection failed: maximum retry attempts exceeded": {"zh_CN": "连接失败：超过最大重试次数", "zh_TW": "連接失敗：超過最大重試次數", "ru_RU": "Ошибка: превышено макс. число попыток", "fa_IR": "اتصال ناموفق: تلاش‌های مجدد به حداکثر رسید"},
    "DisconnectConnect": {"zh_CN": "断开并重连", "zh_TW": "斷開並重連", "ru_RU": "Отключить и подключить", "fa_IR": "قطع و اتصال مجدد"},
    "Failed to configure TUN device": {"zh_CN": "配置TUN设备失败", "zh_TW": "設定TUN裝置失敗", "ru_RU": "Ошибка настройки TUN-устройства", "fa_IR": "پیکربندی دستگاه TUN ناموفق بود"},
    "Failed to create TUN device": {"zh_CN": "创建TUN设备失败", "zh_TW": "建立TUN裝置失敗", "ru_RU": "Ошибка создания TUN-устройства", "fa_IR": "ایجاد دستگاه TUN ناموفق بود"},
    "Failed to parse ping result": {"zh_CN": "解析ping结果失败", "zh_TW": "解析ping結果失敗", "ru_RU": "Ошибка разбора результата ping", "fa_IR": "تحلیل نتیجه پینگ ناموفق بود"},
    "Failed to start Xray: %1": {"zh_CN": "启动Xray失败：%1", "zh_TW": "啟動Xray失敗：%1", "ru_RU": "Ошибка запуска Xray: %1", "fa_IR": "شروع Xray ناموفق بود: %1"},
    "Failed to start connection": {"zh_CN": "启动连接失败", "zh_TW": "啟動連接失敗", "ru_RU": "Ошибка запуска соединения", "fa_IR": "شروع اتصال ناموفق بود"},
    "Maximum retry attempts exceeded": {"zh_CN": "超过最大重试次数", "zh_TW": "超過最大重試次數", "ru_RU": "Превышено макс. число попыток", "fa_IR": "تلاش‌های مجدد به حداکثر رسید"},
    "PingFailed": {"zh_CN": "Ping失败", "zh_TW": "Ping失敗", "ru_RU": "Ping не удался", "fa_IR": "پینگ ناموفق"},
    "Reconnect failed: no current server": {"zh_CN": "重连失败：没有当前服务器", "zh_TW": "重連失敗：沒有當前伺服器", "ru_RU": "Ошибка переподключения: нет текущего сервера", "fa_IR": "اتصال مجدد ناموفق: سرور فعلی وجود ندارد"},
    "Reconnect failed: server object invalid": {"zh_CN": "重连失败：服务器对象无效", "zh_TW": "重連失敗：伺服器物件無效", "ru_RU": "Ошибка переподключения: недействительный сервер", "fa_IR": "اتصال مجدد ناموفق: شی سرور نامعتبر"},
    "System not ready, please try again later": {"zh_CN": "系统未就绪，请稍后重试", "zh_TW": "系統未就緒，請稍後重試", "ru_RU": "Система не готова, попробуйте позже", "fa_IR": "سیستم آماده نیست، لطفا بعدا تلاش کنید"},
    "TUN device error: %1": {"zh_CN": "TUN设备错误：%1", "zh_TW": "TUN裝置錯誤：%1", "ru_RU": "Ошибка TUN-устройства: %1", "fa_IR": "خطای دستگاه TUN: %1"},
    "VPN not connected": {"zh_CN": "VPN未连接", "zh_TW": "VPN未連接", "ru_RU": "VPN не подключен", "fa_IR": "VPN متصل نیست"},
    "VPN permission denied. Please grant VPN permission in Settings and try again.": {"zh_CN": "VPN权限被拒绝。请在设置中授予VPN权限后重试。", "zh_TW": "VPN權限被拒絕。請在設定中授予VPN權限後重試。", "ru_RU": "Доступ к VPN запрещен. Разрешите VPN в настройках и повторите.", "fa_IR": "دسترسی VPN رد شد. لطفا در تنظیمات مجوز VPN را بدهید و دوباره تلاش کنید."},
    "XrayCore initialization failed": {"zh_CN": "XrayCore初始化失败", "zh_TW": "XrayCore初始化失敗", "ru_RU": "Ошибка инициализации XrayCore", "fa_IR": "راه‌اندازی XrayCore ناموفق بود"},

    # Server configuration errors
    "No servers parsed": {"zh_CN": "未解析到服务器", "zh_TW": "未解析到伺服器", "ru_RU": "Серверы не найдены", "fa_IR": "سروری تجزیه نشد"},
    "Port not configured": {"zh_CN": "端口未配置", "zh_TW": "埠未設定", "ru_RU": "Порт не настроен", "fa_IR": "پورت پیکربندی نشده"},
    "Port number invalid (must be between 1-65535)": {"zh_CN": "端口号无效（必须在1-65535之间）", "zh_TW": "埠號無效（必須在1-65535之間）", "ru_RU": "Неверный номер порта (1-65535)", "fa_IR": "شماره پورت نامعتبر (باید بین 1-65535 باشد)"},
    "Protocol type not configured": {"zh_CN": "协议类型未配置", "zh_TW": "協定類型未設定", "ru_RU": "Тип протокола не настроен", "fa_IR": "نوع پروتکل پیکربندی نشده"},
    "SOCKS5 port not ready": {"zh_CN": "SOCKS5端口未就绪", "zh_TW": "SOCKS5埠未就緒", "ru_RU": "SOCKS5 порт не готов", "fa_IR": "پورت SOCKS5 آماده نیست"},
    "Server address cannot be empty": {"zh_CN": "服务器地址不能为空", "zh_TW": "伺服器地址不能為空", "ru_RU": "Адрес сервера не может быть пустым", "fa_IR": "آدرس سرور نمی‌تواند خالی باشد"},
    "Server address is empty": {"zh_CN": "服务器地址为空", "zh_TW": "伺服器地址為空", "ru_RU": "Адрес сервера пуст", "fa_IR": "آدرس سرور خالی است"},
    "Server configuration format invalid": {"zh_CN": "服务器配置格式无效", "zh_TW": "伺服器設定格式無效", "ru_RU": "Неверный формат конфигурации сервера", "fa_IR": "فرمت پیکربندی سرور نامعتبر"},
    "Server configuration invalid: %1": {"zh_CN": "服务器配置无效：%1", "zh_TW": "伺服器設定無效：%1", "ru_RU": "Неверная конфигурация сервера: %1", "fa_IR": "پیکربندی سرور نامعتبر: %1"},
    "Server configuration is empty": {"zh_CN": "服务器配置为空", "zh_TW": "伺服器設定為空", "ru_RU": "Конфигурация сервера пуста", "fa_IR": "پیکربندی سرور خالی است"},
    "Server content cannot be empty": {"zh_CN": "服务器内容不能为空", "zh_TW": "伺服器內容不能為空", "ru_RU": "Содержимое сервера не может быть пустым", "fa_IR": "محتوای سرور نمی‌تواند خالی باشد"},
    "Server object has expired": {"zh_CN": "服务器对象已过期", "zh_TW": "伺服器物件已過期", "ru_RU": "Объект сервера устарел", "fa_IR": "شی سرور منقضی شده"},
    "Server object invalid": {"zh_CN": "服务器对象无效", "zh_TW": "伺服器物件無效", "ru_RU": "Недействительный объект сервера", "fa_IR": "شی سرور نامعتبر"},
    "ServersInvalid": {"zh_CN": "服务器无效", "zh_TW": "伺服器無效", "ru_RU": "Серверы недействительны", "fa_IR": "سرورها نامعتبر"},
    "Shadowsocks encryption method not configured": {"zh_CN": "Shadowsocks加密方式未配置", "zh_TW": "Shadowsocks加密方式未設定", "ru_RU": "Метод шифрования Shadowsocks не настроен", "fa_IR": "روش رمزنگاری Shadowsocks پیکربندی نشده"},
    "Shadowsocks password cannot be empty": {"zh_CN": "Shadowsocks密码不能为空", "zh_TW": "Shadowsocks密碼不能為空", "ru_RU": "Пароль Shadowsocks не может быть пустым", "fa_IR": "رمز Shadowsocks نمی‌تواند خالی باشد"},
    "Trojan password cannot be empty": {"zh_CN": "Trojan密码不能为空", "zh_TW": "Trojan密碼不能為空", "ru_RU": "Пароль Trojan не может быть пустым", "fa_IR": "رمز Trojan نمی‌تواند خالی باشد"},
    "UUID cannot be empty": {"zh_CN": "UUID不能为空", "zh_TW": "UUID不能為空", "ru_RU": "UUID не может быть пустым", "fa_IR": "UUID نمی‌تواند خالی باشد"},
    "UUID format invalid": {"zh_CN": "UUID格式无效", "zh_TW": "UUID格式無效", "ru_RU": "Неверный формат UUID", "fa_IR": "فرمت UUID نامعتبر"},
    "Unsupported configuration version": {"zh_CN": "不支持的配置版本", "zh_TW": "不支援的設定版本", "ru_RU": "Неподдерживаемая версия конфигурации", "fa_IR": "نسخه پیکربندی پشتیبانی نمی‌شود"},
    "Unsupported protocol: %1": {"zh_CN": "不支持的协议：%1", "zh_TW": "不支援的協定：%1", "ru_RU": "Неподдерживаемый протокол: %1", "fa_IR": "پروتکل پشتیبانی نمی‌شود: %1"},
    "Unsupported transport protocol: %1": {"zh_CN": "不支持的传输协议：%1", "zh_TW": "不支援的傳輸協定：%1", "ru_RU": "Неподдерживаемый транспорт: %1", "fa_IR": "پروتکل انتقال پشتیبانی نمی‌شود: %1"},
    "WebSocket transport requires path configuration": {"zh_CN": "WebSocket传输需要配置路径", "zh_TW": "WebSocket傳輸需要設定路徑", "ru_RU": "Для WebSocket требуется настройка пути", "fa_IR": "انتقال WebSocket نیاز به پیکربندی مسیر دارد"},

    # Subscription errors
    "DeleteSubscriptionFailed": {"zh_CN": "删除订阅失败", "zh_TW": "刪除訂閱失敗", "ru_RU": "Ошибка удаления подписки", "fa_IR": "حذف اشتراک ناموفق بود"},
    "No subscription available for update": {"zh_CN": "没有可更新的订阅", "zh_TW": "沒有可更新的訂閱", "ru_RU": "Нет подписки для обновления", "fa_IR": "اشتراکی برای به‌روزرسانی موجود نیست"},
    "SaveServersFailed": {"zh_CN": "保存服务器失败", "zh_TW": "儲存伺服器失敗", "ru_RU": "Ошибка сохранения серверов", "fa_IR": "ذخیره سرورها ناموفق بود"},
    "SaveSubscriptionFailed": {"zh_CN": "保存订阅失败", "zh_TW": "儲存訂閱失敗", "ru_RU": "Ошибка сохранения подписки", "fa_IR": "ذخیره اشتراک ناموفق بود"},
    "Subscription %1": {"zh_CN": "订阅 %1", "zh_TW": "訂閱 %1", "ru_RU": "Подписка %1", "fa_IR": "اشتراک %1"},
    "Subscription URL cannot be empty": {"zh_CN": "订阅URL不能为空", "zh_TW": "訂閱URL不能為空", "ru_RU": "URL подписки не может быть пустым", "fa_IR": "آدرس اشتراک نمی‌تواند خالی باشد"},
    "Subscription already exists": {"zh_CN": "订阅已存在", "zh_TW": "訂閱已存在", "ru_RU": "Подписка уже существует", "fa_IR": "اشتراک قبلا وجود دارد"},
    "Subscription does not exist": {"zh_CN": "订阅不存在", "zh_TW": "訂閱不存在", "ru_RU": "Подписка не существует", "fa_IR": "اشتراک وجود ندارد"},
    "Subscription is disabled": {"zh_CN": "订阅已禁用", "zh_TW": "訂閱已停用", "ru_RU": "Подписка отключена", "fa_IR": "اشتراک غیرفعال است"},
    "Subscription link cannot be empty": {"zh_CN": "订阅链接不能为空", "zh_TW": "訂閱連結不能為空", "ru_RU": "Ссылка подписки не может быть пустой", "fa_IR": "لینک اشتراک نمی‌تواند خالی باشد"},
    "Subscription link format invalid": {"zh_CN": "订阅链接格式无效", "zh_TW": "訂閱連結格式無效", "ru_RU": "Неверный формат ссылки подписки", "fa_IR": "فرمت لینک اشتراک نامعتبر"},
    "Subscription link updated": {"zh_CN": "订阅链接已更新", "zh_TW": "訂閱連結已更新", "ru_RU": "Ссылка подписки обновлена", "fa_IR": "لینک اشتراک به‌روز شد"},
    "Update Subscription Link?": {"zh_CN": "更新订阅链接？", "zh_TW": "更新訂閱連結？", "ru_RU": "Обновить ссылку подписки?", "fa_IR": "لینک اشتراک به‌روز شود؟"},
    "The old subscription URL will become invalid immediately.": {"zh_CN": "旧订阅URL将立即失效。", "zh_TW": "舊訂閱URL將立即失效。", "ru_RU": "Старая ссылка станет недействительной.", "fa_IR": "آدرس اشتراک قدیمی فورا نامعتبر می‌شود."},
    "You will need to re-import the new subscription link on all your devices after updating.": {"zh_CN": "更新后，您需要在所有设备上重新导入新的订阅链接。", "zh_TW": "更新後，您需要在所有裝置上重新匯入新的訂閱連結。", "ru_RU": "После обновления нужно заново импортировать ссылку на всех устройствах.", "fa_IR": "پس از به‌روزرسانی، باید لینک جدید را در همه دستگاه‌ها مجددا وارد کنید."},
    "Warning: This action cannot be undone!": {"zh_CN": "警告：此操作无法撤销！", "zh_TW": "警告：此操作無法撤銷！", "ru_RU": "Предупреждение: это действие нельзя отменить!", "fa_IR": "هشدار: این عمل قابل برگشت نیست!"},

    # Server names/types
    "Clash Server %1": {"zh_CN": "Clash服务器 %1", "zh_TW": "Clash伺服器 %1", "ru_RU": "Сервер Clash %1", "fa_IR": "سرور Clash %1"},
    "Manual server %1": {"zh_CN": "手动服务器 %1", "zh_TW": "手動伺服器 %1", "ru_RU": "Ручной сервер %1", "fa_IR": "سرور دستی %1"},
    "Manually added servers": {"zh_CN": "手动添加的服务器", "zh_TW": "手動新增的伺服器", "ru_RU": "Серверы, добавленные вручную", "fa_IR": "سرورهای اضافه شده دستی"},
    "No Server Selected": {"zh_CN": "未选择服务器", "zh_TW": "未選擇伺服器", "ru_RU": "Сервер не выбран", "fa_IR": "سروری انتخاب نشده"},

    # Help center
    "Article Content": {"zh_CN": "文章内容", "zh_TW": "文章內容", "ru_RU": "Содержание статьи", "fa_IR": "محتوای مقاله"},
    "Clear Search": {"zh_CN": "清除搜索", "zh_TW": "清除搜尋", "ru_RU": "Очистить поиск", "fa_IR": "پاک کردن جستجو"},
    "No articles yet": {"zh_CN": "暂无文章", "zh_TW": "暫無文章", "ru_RU": "Статей пока нет", "fa_IR": "هنوز مقاله‌ای نیست"},
    "No content": {"zh_CN": "无内容", "zh_TW": "無內容", "ru_RU": "Нет содержимого", "fa_IR": "بدون محتوا"},
    "No data received": {"zh_CN": "未收到数据", "zh_TW": "未收到資料", "ru_RU": "Данные не получены", "fa_IR": "داده‌ای دریافت نشد"},
    "No matching articles": {"zh_CN": "没有匹配的文章", "zh_TW": "沒有匹配的文章", "ru_RU": "Статьи не найдены", "fa_IR": "مقاله‌ای یافت نشد"},
    "Search articles...": {"zh_CN": "搜索文章...", "zh_TW": "搜尋文章...", "ru_RU": "Поиск статей...", "fa_IR": "جستجوی مقالات..."},
    "Try different keywords": {"zh_CN": "尝试不同的关键词", "zh_TW": "嘗試不同的關鍵字", "ru_RU": "Попробуйте другие ключевые слова", "fa_IR": "کلمات کلیدی دیگر را امتحان کنید"},
    "Was this article helpful?": {"zh_CN": "这篇文章有帮助吗？", "zh_TW": "這篇文章有幫助嗎？", "ru_RU": "Была ли статья полезной?", "fa_IR": "آیا این مقاله مفید بود؟"},

    # Misc UI elements
    "Add Favorite": {"zh_CN": "添加收藏", "zh_TW": "新增收藏", "ru_RU": "В избранное", "fa_IR": "افزودن به علاقه‌مندی‌ها"},
    "Copied to clipboard": {"zh_CN": "已复制到剪贴板", "zh_TW": "已複製到剪貼簿", "ru_RU": "Скопировано в буфер обмена", "fa_IR": "در کلیپ‌بورد کپی شد"},
    "Do not auto update": {"zh_CN": "不自动更新", "zh_TW": "不自動更新", "ru_RU": "Не обновлять автоматически", "fa_IR": "به‌روزرسانی خودکار نکن"},
    "Enter password": {"zh_CN": "输入密码", "zh_TW": "輸入密碼", "ru_RU": "Введите пароль", "fa_IR": "رمز عبور را وارد کنید"},
    "Expired": {"zh_CN": "已过期", "zh_TW": "已過期", "ru_RU": "Истек", "fa_IR": "منقضی شده"},
    "Filter": {"zh_CN": "筛选", "zh_TW": "篩選", "ru_RU": "Фильтр", "fa_IR": "فیلتر"},
    "Image": {"zh_CN": "图片", "zh_TW": "圖片", "ru_RU": "Изображение", "fa_IR": "تصویر"},
    "Image load failed": {"zh_CN": "图片加载失败", "zh_TW": "圖片載入失敗", "ru_RU": "Ошибка загрузки изображения", "fa_IR": "بارگذاری تصویر ناموفق بود"},
    "JSON parse error": {"zh_CN": "JSON解析错误", "zh_TW": "JSON解析錯誤", "ru_RU": "Ошибка разбора JSON", "fa_IR": "خطای تجزیه JSON"},
    "JinGo VPN": {"zh_CN": "JinGo VPN", "zh_TW": "JinGo VPN", "ru_RU": "JinGo VPN", "fa_IR": "JinGo VPN"},
    "Loading image...": {"zh_CN": "正在加载图片...", "zh_TW": "正在載入圖片...", "ru_RU": "Загрузка изображения...", "fa_IR": "در حال بارگذاری تصویر..."},
    "Never": {"zh_CN": "从不", "zh_TW": "從不", "ru_RU": "Никогда", "fa_IR": "هرگز"},
    "Password must be at least 6 characters": {"zh_CN": "密码至少6个字符", "zh_TW": "密碼至少6個字元", "ru_RU": "Пароль минимум 6 символов", "fa_IR": "رمز باید حداقل 6 کاراکتر باشد"},
    "Password reset email sent to %1": {"zh_CN": "密码重置邮件已发送至 %1", "zh_TW": "密碼重設郵件已發送至 %1", "ru_RU": "Письмо для сброса пароля отправлено на %1", "fa_IR": "ایمیل بازیابی رمز به %1 ارسال شد"},
    "Please enterUsername": {"zh_CN": "请输入用户名", "zh_TW": "請輸入使用者名稱", "ru_RU": "Введите имя пользователя", "fa_IR": "لطفا نام کاربری را وارد کنید"},
    "Quick Connect": {"zh_CN": "快速连接", "zh_TW": "快速連接", "ru_RU": "Быстрое подключение", "fa_IR": "اتصال سریع"},
    "Quit": {"zh_CN": "退出", "zh_TW": "結束", "ru_RU": "Выход", "fa_IR": "خروج"},
    "Remove from dictionary": {"zh_CN": "从词典中移除", "zh_TW": "從詞典中移除", "ru_RU": "Удалить из словаря", "fa_IR": "حذف از فرهنگ لغت"},
    "Show Main Window": {"zh_CN": "显示主窗口", "zh_TW": "顯示主視窗", "ru_RU": "Показать главное окно", "fa_IR": "نمایش پنجره اصلی"},
    "Update": {"zh_CN": "更新", "zh_TW": "更新", "ru_RU": "Обновить", "fa_IR": "به‌روزرسانی"},
    "Update Required": {"zh_CN": "需要更新", "zh_TW": "需要更新", "ru_RU": "Требуется обновление", "fa_IR": "به‌روزرسانی لازم است"},
    "\"%1\" already exists.": {"zh_CN": "\"%1\" 已存在。", "zh_TW": "\"%1\" 已存在。", "ru_RU": "\"%1\" уже существует.", "fa_IR": "\"%1\" قبلا وجود دارد."},

    # Ticket system additions
    "Add attachment": {"zh_CN": "添加附件", "zh_TW": "新增附件", "ru_RU": "Добавить вложение", "fa_IR": "افزودن پیوست"},
    "All Files": {"zh_CN": "所有文件", "zh_TW": "所有檔案", "ru_RU": "Все файлы", "fa_IR": "همه فایل‌ها"},
    "Attachment": {"zh_CN": "附件", "zh_TW": "附件", "ru_RU": "Вложение", "fa_IR": "پیوست"},
    "Click to select file": {"zh_CN": "点击选择文件", "zh_TW": "點擊選擇檔案", "ru_RU": "Нажмите для выбора файла", "fa_IR": "برای انتخاب فایل کلیک کنید"},
    "Documents": {"zh_CN": "文档", "zh_TW": "文件", "ru_RU": "Документы", "fa_IR": "اسناد"},
    "Images": {"zh_CN": "图片", "zh_TW": "圖片", "ru_RU": "Изображения", "fa_IR": "تصاویر"},
    "Optional": {"zh_CN": "可选", "zh_TW": "選填", "ru_RU": "Необязательно", "fa_IR": "اختیاری"},
    "Select Attachment": {"zh_CN": "选择附件", "zh_TW": "選擇附件", "ru_RU": "Выберите вложение", "fa_IR": "انتخاب پیوست"},

    # Qt Designer strings that appear in UI
    "Block word": {"zh_CN": "屏蔽词", "zh_TW": "屏蔽詞", "ru_RU": "Заблокированное слово", "fa_IR": "کلمه مسدود"},
    "Bottom": {"zh_CN": "底部", "zh_TW": "底部", "ru_RU": "Низ", "fa_IR": "پایین"},
    "Bottom inset for the background.": {"zh_CN": "背景的底部内边距。", "zh_TW": "背景的底部內邊距。", "ru_RU": "Нижний отступ фона.", "fa_IR": "فاصله پایین برای پس‌زمینه."},
    "Content Height": {"zh_CN": "内容高度", "zh_TW": "內容高度", "ru_RU": "Высота содержимого", "fa_IR": "ارتفاع محتوا"},
    "Content Width": {"zh_CN": "内容宽度", "zh_TW": "內容寬度", "ru_RU": "Ширина содержимого", "fa_IR": "عرض محتوا"},
    "Content height used for calculating the total implicit height.": {"zh_CN": "用于计算总隐式高度的内容高度。", "zh_TW": "用於計算總隱式高度的內容高度。", "ru_RU": "Высота содержимого для расчета общей неявной высоты.", "fa_IR": "ارتفاع محتوا برای محاسبه ارتفاع ضمنی کل."},
    "Content height used for calculating the total implicit width.": {"zh_CN": "用于计算总隐式宽度的内容高度。", "zh_TW": "用於計算總隱式寬度的內容高度。", "ru_RU": "Высота содержимого для расчета общей неявной ширины.", "fa_IR": "ارتفاع محتوا برای محاسبه عرض ضمنی کل."},
    "Effects": {"zh_CN": "效果", "zh_TW": "效果", "ru_RU": "Эффекты", "fa_IR": "افکت‌ها"},
    "Family": {"zh_CN": "字体族", "zh_TW": "字型族", "ru_RU": "Семейство", "fa_IR": "خانواده"},
    "Horizontal": {"zh_CN": "水平", "zh_TW": "水平", "ru_RU": "Горизонтальный", "fa_IR": "افقی"},
    "Inset": {"zh_CN": "内边距", "zh_TW": "內邊距", "ru_RU": "Внутренний отступ", "fa_IR": "فاصله داخلی"},
    "Left": {"zh_CN": "左侧", "zh_TW": "左側", "ru_RU": "Слева", "fa_IR": "چپ"},
    "Left inset for the background.": {"zh_CN": "背景的左侧内边距。", "zh_TW": "背景的左側內邊距。", "ru_RU": "Левый отступ фона.", "fa_IR": "فاصله چپ برای پس‌زمینه."},
    "Orientation of the view.": {"zh_CN": "视图的方向。", "zh_TW": "視圖的方向。", "ru_RU": "Ориентация представления.", "fa_IR": "جهت نما."},
    "Padding": {"zh_CN": "内边距", "zh_TW": "內邊距", "ru_RU": "Отступ", "fa_IR": "فاصله"},
    "Padding between the content and the bottom edge of the control.": {"zh_CN": "内容与控件底部边缘之间的内边距。", "zh_TW": "內容與控制項底部邊緣之間的內邊距。", "ru_RU": "Отступ между содержимым и нижним краем элемента.", "fa_IR": "فاصله بین محتوا و لبه پایین کنترل."},
    "Padding between the content and the left edge of the control.": {"zh_CN": "内容与控件左侧边缘之间的内边距。", "zh_TW": "內容與控制項左側邊緣之間的內邊距。", "ru_RU": "Отступ между содержимым и левым краем элемента.", "fa_IR": "فاصله بین محتوا و لبه چپ کنترل."},
    "Padding between the content and the right edge of the control.": {"zh_CN": "内容与控件右侧边缘之间的内边距。", "zh_TW": "內容與控制項右側邊緣之間的內邊距。", "ru_RU": "Отступ между содержимым и правым краем элемента.", "fa_IR": "فاصله بین محتوا و لبه راست کنترل."},
    "Padding between the content and the top edge of the control.": {"zh_CN": "内容与控件顶部边缘之间的内边距。", "zh_TW": "內容與控制項頂部邊緣之間的內邊距。", "ru_RU": "Отступ между содержимым и верхним краем элемента.", "fa_IR": "فاصله بین محتوا و لبه بالای کنترل."},
    "Page %1 location %2, %3 zoom %4": {"zh_CN": "第 %1 页 位置 %2, %3 缩放 %4", "zh_TW": "第 %1 頁 位置 %2, %3 縮放 %4", "ru_RU": "Страница %1 позиция %2, %3 масштаб %4", "fa_IR": "صفحه %1 موقعیت %2, %3 بزرگنمایی %4"},
    "Placeholder Text Color": {"zh_CN": "占位符文本颜色", "zh_TW": "預留位置文字顏色", "ru_RU": "Цвет текста заполнителя", "fa_IR": "رنگ متن جای‌نما"},
    "Placeholder text displayed when the editor is empty.": {"zh_CN": "编辑器为空时显示的占位符文本。", "zh_TW": "編輯器為空時顯示的預留位置文字。", "ru_RU": "Текст заполнителя, когда редактор пуст.", "fa_IR": "متن جای‌نما هنگامی که ویرایشگر خالی است."},
    "Position of the tabbar.": {"zh_CN": "标签栏的位置。", "zh_TW": "標籤列的位置。", "ru_RU": "Позиция панели вкладок.", "fa_IR": "موقعیت نوار برگه."},
    "Position of the toolbar.": {"zh_CN": "工具栏的位置。", "zh_TW": "工具列的位置。", "ru_RU": "Позиция панели инструментов.", "fa_IR": "موقعیت نوار ابزار."},
    "Radius of the button.": {"zh_CN": "按钮的半径。", "zh_TW": "按鈕的半徑。", "ru_RU": "Радиус кнопки.", "fa_IR": "شعاع دکمه."},
    "Right": {"zh_CN": "右侧", "zh_TW": "右側", "ru_RU": "Справа", "fa_IR": "راست"},
    "Right inset for the background.": {"zh_CN": "背景的右侧内边距。", "zh_TW": "背景的右側內邊距。", "ru_RU": "Правый отступ фона.", "fa_IR": "فاصله راست برای پس‌زمینه."},
    "Sample": {"zh_CN": "示例", "zh_TW": "範例", "ru_RU": "Образец", "fa_IR": "نمونه"},
    "Strikeout": {"zh_CN": "删除线", "zh_TW": "刪除線", "ru_RU": "Зачеркнутый", "fa_IR": "خط خورده"},
    "Style": {"zh_CN": "样式", "zh_TW": "樣式", "ru_RU": "Стиль", "fa_IR": "سبک"},
    "Style Color": {"zh_CN": "样式颜色", "zh_TW": "樣式顏色", "ru_RU": "Цвет стиля", "fa_IR": "رنگ سبک"},
    "Text Color": {"zh_CN": "文本颜色", "zh_TW": "文字顏色", "ru_RU": "Цвет текста", "fa_IR": "رنگ متن"},
    "The count of visible items.": {"zh_CN": "可见项目的数量。", "zh_TW": "可見項目的數量。", "ru_RU": "Количество видимых элементов.", "fa_IR": "تعداد موارد قابل مشاهده."},
    "The current value of the progress.": {"zh_CN": "进度的当前值。", "zh_TW": "進度的目前值。", "ru_RU": "Текущее значение прогресса.", "fa_IR": "مقدار فعلی پیشرفت."},
    "The current value of the slider.": {"zh_CN": "滑块的当前值。", "zh_TW": "滑桿的目前值。", "ru_RU": "Текущее значение слайдера.", "fa_IR": "مقدار فعلی اسلایدر."},
    "The current value of the spinbox.": {"zh_CN": "微调框的当前值。", "zh_TW": "微調方塊的目前值。", "ru_RU": "Текущее значение счетчика.", "fa_IR": "مقدار فعلی جعبه چرخشی."},
    "The ending value for the progress.": {"zh_CN": "进度的结束值。", "zh_TW": "進度的結束值。", "ru_RU": "Конечное значение прогресса.", "fa_IR": "مقدار پایانی پیشرفت."},
    "The ending value of the range slider range.": {"zh_CN": "范围滑块的结束值。", "zh_TW": "範圍滑桿的結束值。", "ru_RU": "Конечное значение диапазона слайдера.", "fa_IR": "مقدار پایانی محدوده اسلایدر."},
    "The ending value of the slider range.": {"zh_CN": "滑块范围的结束值。", "zh_TW": "滑桿範圍的結束值。", "ru_RU": "Конечное значение диапазона слайдера.", "fa_IR": "مقدار پایانی محدوده اسلایدر."},
    "The ending value of the spinbox range.": {"zh_CN": "微调框范围的结束值。", "zh_TW": "微調方塊範圍的結束值。", "ru_RU": "Конечное значение диапазона счетчика.", "fa_IR": "مقدار پایانی محدوده جعبه چرخشی."},
    "The index of the current page.": {"zh_CN": "当前页面的索引。", "zh_TW": "當前頁面的索引。", "ru_RU": "Индекс текущей страницы.", "fa_IR": "شاخص صفحه فعلی."},
    "The orientation of the range slider.": {"zh_CN": "范围滑块的方向。", "zh_TW": "範圍滑桿的方向。", "ru_RU": "Ориентация слайдера диапазона.", "fa_IR": "جهت اسلایدر محدوده."},
    "The orientation of the separator.": {"zh_CN": "分隔符的方向。", "zh_TW": "分隔符的方向。", "ru_RU": "Ориентация разделителя.", "fa_IR": "جهت جداکننده."},
    "The rate at which a flick will decelerate.": {"zh_CN": "轻弹减速的速率。", "zh_TW": "輕彈減速的速率。", "ru_RU": "Скорость замедления пролистывания.", "fa_IR": "نرخ کاهش سرعت حرکت سریع."},
    "The snap mode of the range slider.": {"zh_CN": "范围滑块的吸附模式。", "zh_TW": "範圍滑桿的吸附模式。", "ru_RU": "Режим привязки слайдера диапазона.", "fa_IR": "حالت چسبیدن اسلایدر محدوده."},
    "The starting value for the progress.": {"zh_CN": "进度的起始值。", "zh_TW": "進度的起始值。", "ru_RU": "Начальное значение прогресса.", "fa_IR": "مقدار شروع پیشرفت."},
    "The starting value of the range slider range.": {"zh_CN": "范围滑块的起始值。", "zh_TW": "範圍滑桿的起始值。", "ru_RU": "Начальное значение диапазона слайдера.", "fa_IR": "مقدار شروع محدوده اسلایدر."},
    "The starting value of the slider range.": {"zh_CN": "滑块范围的起始值。", "zh_TW": "滑桿範圍的起始值。", "ru_RU": "Начальное значение диапазона слайдера.", "fa_IR": "مقدار شروع محدوده اسلایدر."},
    "The starting value of the spinbox range.": {"zh_CN": "微调框范围的起始值。", "zh_TW": "微調方塊範圍的起始值。", "ru_RU": "Начальное значение диапазона счетчика.", "fa_IR": "مقدار شروع محدوده جعبه چرخشی."},
    "The step size of the range slider.": {"zh_CN": "范围滑块的步长。", "zh_TW": "範圍滑桿的步長。", "ru_RU": "Размер шага слайдера диапазона.", "fa_IR": "اندازه گام اسلایدر محدوده."},
    "The step size of the slider.": {"zh_CN": "滑块的步长。", "zh_TW": "滑桿的步長。", "ru_RU": "Размер шага слайдера.", "fa_IR": "اندازه گام اسلایدر."},
    "The step size of the spinbox.": {"zh_CN": "微调框的步长。", "zh_TW": "微調方塊的步長。", "ru_RU": "Размер шага счетчика.", "fa_IR": "اندازه گام جعبه چرخشی."},
    "The threshold (in logical pixels) at which a touch drag event will be initiated.": {"zh_CN": "触发触摸拖动事件的阈值（逻辑像素）。", "zh_TW": "觸發觸控拖動事件的閾值（邏輯像素）。", "ru_RU": "Порог (в логических пикселях) для начала события перетаскивания.", "fa_IR": "آستانه (به پیکسل منطقی) که رویداد کشیدن لمسی آغاز می‌شود."},
    "The title of the group box.": {"zh_CN": "分组框的标题。", "zh_TW": "群組方塊的標題。", "ru_RU": "Заголовок группы.", "fa_IR": "عنوان گروه‌بندی."},
    "The value of the first range slider handle.": {"zh_CN": "第一个范围滑块手柄的值。", "zh_TW": "第一個範圍滑桿手把的值。", "ru_RU": "Значение первой ручки слайдера диапазона.", "fa_IR": "مقدار دسته اول اسلایدر محدوده."},
    "The value of the second range slider handle.": {"zh_CN": "第二个范围滑块手柄的值。", "zh_TW": "第二個範圍滑桿手把的值。", "ru_RU": "Значение второй ручки слайдера диапазона.", "fa_IR": "مقدار دسته دوم اسلایدر محدوده."},
    "Title of the page.": {"zh_CN": "页面的标题。", "zh_TW": "頁面的標題。", "ru_RU": "Заголовок страницы.", "fa_IR": "عنوان صفحه."},
    "Top": {"zh_CN": "顶部", "zh_TW": "頂部", "ru_RU": "Верх", "fa_IR": "بالا"},
    "Top inset for the background.": {"zh_CN": "背景的顶部内边距。", "zh_TW": "背景的頂部內邊距。", "ru_RU": "Верхний отступ фона.", "fa_IR": "فاصله بالا برای پس‌زمینه."},
    "Touch drag threshold": {"zh_CN": "触摸拖动阈值", "zh_TW": "觸控拖動閾值", "ru_RU": "Порог перетаскивания касанием", "fa_IR": "آستانه کشیدن لمسی"},
    "Underline": {"zh_CN": "下划线", "zh_TW": "底線", "ru_RU": "Подчеркнутый", "fa_IR": "زیرخط"},
    "Vertical": {"zh_CN": "垂直", "zh_TW": "垂直", "ru_RU": "Вертикальный", "fa_IR": "عمودی"},
    "Whether text area accepts hover events.": {"zh_CN": "文本区域是否接受悬停事件。", "zh_TW": "文字區域是否接受懸停事件。", "ru_RU": "Принимает ли текстовая область события наведения.", "fa_IR": "آیا ناحیه متن رویدادهای شناور را می‌پذیرد."},
    "Whether text field accepts hover events.": {"zh_CN": "文本框是否接受悬停事件。", "zh_TW": "文字方塊是否接受懸停事件。", "ru_RU": "Принимает ли текстовое поле события наведения.", "fa_IR": "آیا فیلد متن رویدادهای شناور را می‌پذیرد."},
    "Whether the control is interactive.": {"zh_CN": "控件是否可交互。", "zh_TW": "控制項是否可互動。", "ru_RU": "Является ли элемент интерактивным.", "fa_IR": "آیا کنترل تعاملی است."},
    "Whether the delegate is highlighted.": {"zh_CN": "代理是否高亮。", "zh_TW": "代理是否高亮。", "ru_RU": "Выделен ли делегат.", "fa_IR": "آیا نماینده برجسته است."},
    "Whether the range slider provides live value updates.": {"zh_CN": "范围滑块是否提供实时值更新。", "zh_TW": "範圍滑桿是否提供即時值更新。", "ru_RU": "Обновляет ли слайдер диапазона значения в реальном времени.", "fa_IR": "آیا اسلایدر محدوده به‌روزرسانی‌های زنده ارائه می‌دهد."},
    "Whether the spinbox is editable.": {"zh_CN": "微调框是否可编辑。", "zh_TW": "微調方塊是否可編輯。", "ru_RU": "Можно ли редактировать счетчик.", "fa_IR": "آیا جعبه چرخشی قابل ویرایش است."},
    "Whether the spinbox wraps.": {"zh_CN": "微调框是否循环。", "zh_TW": "微調方塊是否循環。", "ru_RU": "Зацикливается ли счетчик.", "fa_IR": "آیا جعبه چرخشی حلقه می‌شود."},
    "Whether the tumbler wrap.": {"zh_CN": "滚筒选择器是否循环。", "zh_TW": "滾筒選擇器是否循環。", "ru_RU": "Зацикливается ли барабан.", "fa_IR": "آیا چرخ انتخاب حلقه می‌شود."},
    "Whether the view is interactive.": {"zh_CN": "视图是否可交互。", "zh_TW": "視圖是否可互動。", "ru_RU": "Является ли представление интерактивным.", "fa_IR": "آیا نما تعاملی است."},
    "Writing System": {"zh_CN": "书写系统", "zh_TW": "書寫系統", "ru_RU": "Система письма", "fa_IR": "سیستم نوشتار"},
    "flickDeceleration": {"zh_CN": "轻弹减速", "zh_TW": "輕彈減速", "ru_RU": "Замедление пролистывания", "fa_IR": "کاهش سرعت حرکت"},

    # Multiline file dialog string (with Unicode curly quotes U+201C and U+201D)
    "\u201c%1\u201d already exists.\nDo you want to replace it?": {"zh_CN": "\u201c%1\u201d 已存在。\n是否替换？", "zh_TW": "\u201c%1\u201d 已存在。\n是否取代？", "ru_RU": "\u201c%1\u201d уже существует.\nЗаменить его?", "fa_IR": "\u201c%1\u201d از قبل وجود دارد.\nآیا می‌خواهید آن را جایگزین کنید؟"},

    # Additional UI translations (newly added)
    "%1 Servers": {"zh_CN": "%1 个服务器", "zh_TW": "%1 個伺服器", "ru_RU": "%1 серверов", "fa_IR": "%1 سرور"},
    "* Changes to connection settings require reconnecting to take effect": {"zh_CN": "* 连接设置的更改需要重新连接才能生效", "zh_TW": "* 連接設定的變更需要重新連接才能生效", "ru_RU": "* Изменения настроек подключения требуют переподключения", "fa_IR": "* تغییرات تنظیمات اتصال نیاز به اتصال مجدد دارد"},
    "API Port": {"zh_CN": "API 端口", "zh_TW": "API 埠", "ru_RU": "Порт API", "fa_IR": "پورت API"},
    "Account Actions": {"zh_CN": "账户操作", "zh_TW": "帳戶操作", "ru_RU": "Действия с аккаунтом", "fa_IR": "عملیات حساب"},
    "Account ID: ": {"zh_CN": "账户 ID：", "zh_TW": "帳戶 ID：", "ru_RU": "ID аккаунта: ", "fa_IR": "شناسه حساب: "},
    "Account management and data operations": {"zh_CN": "账户管理和数据操作", "zh_TW": "帳戶管理和資料操作", "ru_RU": "Управление аккаунтом и операции с данными", "fa_IR": "مدیریت حساب و عملیات داده"},
    "Advanced user options, modify with caution": {"zh_CN": "高级用户选项，请谨慎修改", "zh_TW": "進階用戶選項，請謹慎修改", "ru_RU": "Расширенные настройки, изменяйте с осторожностью", "fa_IR": "گزینه‌های پیشرفته، با احتیاط تغییر دهید"},
    "AdvancedSettings": {"zh_CN": "高级设置", "zh_TW": "進階設定", "ru_RU": "Дополнительные настройки", "fa_IR": "تنظیمات پیشرفته"},
    "Allow LAN Connections": {"zh_CN": "允许局域网连接", "zh_TW": "允許區域網路連接", "ru_RU": "Разрешить LAN-подключения", "fa_IR": "اجازه اتصالات LAN"},
    "Allow other devices in LAN to connect to this proxy": {"zh_CN": "允许局域网内其他设备连接此代理", "zh_TW": "允許區域網路內其他裝置連接此代理", "ru_RU": "Разрешить другим устройствам в LAN подключаться к этому прокси", "fa_IR": "اجازه اتصال سایر دستگاه‌های LAN به این پروکسی"},
    "Application Basic Configuration": {"zh_CN": "应用基本配置", "zh_TW": "應用程式基本配置", "ru_RU": "Базовые настройки приложения", "fa_IR": "پیکربندی پایه برنامه"},
    "Application and core log configuration": {"zh_CN": "应用和核心日志配置", "zh_TW": "應用程式和核心日誌配置", "ru_RU": "Настройки журналов приложения и ядра", "fa_IR": "پیکربندی لاگ برنامه و هسته"},
    "Application minimized to system tray, double-click the tray icon to reopen": {"zh_CN": "应用已最小化到系统托盘，双击托盘图标重新打开", "zh_TW": "應用程式已最小化到系統匣，雙擊系統匣圖示重新開啟", "ru_RU": "Приложение свернуто в трей, дважды щелкните значок для открытия", "fa_IR": "برنامه به سینی سیستم کوچک شد، برای باز کردن دوبار کلیک کنید"},
    "Auto clean old logs": {"zh_CN": "自动清理旧日志", "zh_TW": "自動清理舊日誌", "ru_RU": "Автоматическая очистка старых журналов", "fa_IR": "پاکسازی خودکار لاگ‌های قدیمی"},
    "Auto identify traffic type for routing": {"zh_CN": "自动识别流量类型进行路由", "zh_TW": "自動識別流量類型進行路由", "ru_RU": "Автоматическое определение типа трафика для маршрутизации", "fa_IR": "شناسایی خودکار نوع ترافیک برای مسیریابی"},
    "Auto-connect on startup": {"zh_CN": "启动时自动连接", "zh_TW": "啟動時自動連接", "ru_RU": "Автоподключение при запуске", "fa_IR": "اتصال خودکار در هنگام راه‌اندازی"},
    "Automatically connect VPN when network changes": {"zh_CN": "网络变化时自动连接 VPN", "zh_TW": "網路變更時自動連接 VPN", "ru_RU": "Автоподключение VPN при смене сети", "fa_IR": "اتصال خودکار VPN هنگام تغییر شبکه"},
    "Automatically connect to last used server on startup": {"zh_CN": "启动时自动连接到上次使用的服务器", "zh_TW": "啟動時自動連接到上次使用的伺服器", "ru_RU": "Автоподключение к последнему серверу при запуске", "fa_IR": "اتصال خودکار به آخرین سرور در هنگام راه‌اندازی"},
    "Avg Download": {"zh_CN": "平均下载", "zh_TW": "平均下載", "ru_RU": "Средняя загрузка", "fa_IR": "میانگین دانلود"},
    "Avg Upload": {"zh_CN": "平均上传", "zh_TW": "平均上傳", "ru_RU": "Средняя отдача", "fa_IR": "میانگین آپلود"},
    "Basic Member": {"zh_CN": "基础会员", "zh_TW": "基礎會員", "ru_RU": "Базовый участник", "fa_IR": "عضو پایه"},
    "Bypass Countries": {"zh_CN": "绕过国家", "zh_TW": "繞過國家", "ru_RU": "Обход стран", "fa_IR": "کشورهای دور زدن"},
    "Change your account password": {"zh_CN": "更改您的账户密码", "zh_TW": "更改您的帳戶密碼", "ru_RU": "Изменить пароль аккаунта", "fa_IR": "تغییر رمز عبور حساب"},
    "Clear Cache": {"zh_CN": "清除缓存", "zh_TW": "清除快取", "ru_RU": "Очистить кэш", "fa_IR": "پاک کردن کش"},
    "Clear application cache data": {"zh_CN": "清除应用缓存数据", "zh_TW": "清除應用程式快取資料", "ru_RU": "Очистить данные кэша приложения", "fa_IR": "پاک کردن داده‌های کش برنامه"},
    "Click 'Refresh' button above to load servers": {"zh_CN": "点击上方「刷新」按钮加载服务器", "zh_TW": "點擊上方「重新整理」按鈕載入伺服器", "ru_RU": "Нажмите кнопку «Обновить» выше для загрузки серверов", "fa_IR": "روی دکمه «بازخوانی» بالا کلیک کنید"},
    "Connect Settings": {"zh_CN": "连接设置", "zh_TW": "連接設定", "ru_RU": "Настройки подключения", "fa_IR": "تنظیمات اتصال"},
    "Connect on Demand": {"zh_CN": "按需连接", "zh_TW": "按需連接", "ru_RU": "Подключение по требованию", "fa_IR": "اتصال بر اساس تقاضا"},
    "Connection Duration": {"zh_CN": "连接时长", "zh_TW": "連接時長", "ru_RU": "Длительность подключения", "fa_IR": "مدت اتصال"},
    "Connection establishment timeout": {"zh_CN": "连接建立超时", "zh_TW": "連接建立逾時", "ru_RU": "Тайм-аут установки соединения", "fa_IR": "زمان انتظار برقراری اتصال"},
    "Core Version": {"zh_CN": "核心版本", "zh_TW": "核心版本", "ru_RU": "Версия ядра", "fa_IR": "نسخه هسته"},
    "Custom GeoIP Database": {"zh_CN": "自定义 GeoIP 数据库", "zh_TW": "自訂 GeoIP 資料庫", "ru_RU": "Пользовательская база GeoIP", "fa_IR": "پایگاه داده GeoIP سفارشی"},
    "Custom GeoSite Database": {"zh_CN": "自定义 GeoSite 数据库", "zh_TW": "自訂 GeoSite 資料庫", "ru_RU": "Пользовательская база GeoSite", "fa_IR": "پایگاه داده GeoSite سفارشی"},
    "DNS Query Strategy": {"zh_CN": "DNS 查询策略", "zh_TW": "DNS 查詢策略", "ru_RU": "Стратегия DNS-запросов", "fa_IR": "استراتژی پرس‌وجوی DNS"},
    "Days Used": {"zh_CN": "已使用天数", "zh_TW": "已使用天數", "ru_RU": "Использовано дней", "fa_IR": "روزهای استفاده شده"},
    "Documentation": {"zh_CN": "文档", "zh_TW": "文件", "ru_RU": "Документация", "fa_IR": "مستندات"},
    "Email/Username": {"zh_CN": "邮箱/用户名", "zh_TW": "電子郵件/用戶名", "ru_RU": "Эл. почта/Имя пользователя", "fa_IR": "ایمیل/نام کاربری"},
    "Enable Mux multiplexing": {"zh_CN": "启用 Mux 多路复用", "zh_TW": "啟用 Mux 多路復用", "ru_RU": "Включить Mux-мультиплексирование", "fa_IR": "فعال کردن چندگانه‌سازی Mux"},
    "Enable TFO to reduce latency (requires system support)": {"zh_CN": "启用 TFO 以减少延迟（需要系统支持）", "zh_TW": "啟用 TFO 以減少延遲（需要系統支援）", "ru_RU": "Включить TFO для снижения задержки (требуется поддержка системы)", "fa_IR": "فعال کردن TFO برای کاهش تأخیر (نیاز به پشتیبانی سیستم)"},
    "Enable access log": {"zh_CN": "启用访问日志", "zh_TW": "啟用存取日誌", "ru_RU": "Включить журнал доступа", "fa_IR": "فعال کردن لاگ دسترسی"},
    "Enable traffic sniffing": {"zh_CN": "启用流量嗅探", "zh_TW": "啟用流量嗅探", "ru_RU": "Включить анализ трафика", "fa_IR": "فعال کردن شنود ترافیک"},
    "Enter email address": {"zh_CN": "输入邮箱地址", "zh_TW": "輸入電子郵件地址", "ru_RU": "Введите адрес эл. почты", "fa_IR": "آدرس ایمیل را وارد کنید"},
    "Enter email or username": {"zh_CN": "输入邮箱或用户名", "zh_TW": "輸入電子郵件或用戶名", "ru_RU": "Введите эл. почту или имя пользователя", "fa_IR": "ایمیل یا نام کاربری را وارد کنید"},
    "Enter password (min 6 chars)": {"zh_CN": "输入密码（至少6位）", "zh_TW": "輸入密碼（至少6位）", "ru_RU": "Введите пароль (мин. 6 символов)", "fa_IR": "رمز عبور را وارد کنید (حداقل ۶ کاراکتر)"},
    "Enter registered email": {"zh_CN": "输入注册邮箱", "zh_TW": "輸入註冊電子郵件", "ru_RU": "Введите зарегистрированную почту", "fa_IR": "ایمیل ثبت‌نام شده را وارد کنید"},
    "Excellent": {"zh_CN": "极佳", "zh_TW": "極佳", "ru_RU": "Отлично", "fa_IR": "عالی"},
    "Exp: %1": {"zh_CN": "到期：%1", "zh_TW": "到期：%1", "ru_RU": "Истекает: %1", "fa_IR": "انقضا: %1"},
    "File": {"zh_CN": "文件", "zh_TW": "檔案", "ru_RU": "Файл", "fa_IR": "فایل"},
    "General": {"zh_CN": "通用", "zh_TW": "一般", "ru_RU": "Общие", "fa_IR": "عمومی"},
    "GeneralSettings": {"zh_CN": "通用设置", "zh_TW": "一般設定", "ru_RU": "Общие настройки", "fa_IR": "تنظیمات عمومی"},
    "Good": {"zh_CN": "良好", "zh_TW": "良好", "ru_RU": "Хорошо", "fa_IR": "خوب"},
    "Groups": {"zh_CN": "分组", "zh_TW": "群組", "ru_RU": "Группы", "fa_IR": "گروه‌ها"},
    "HTTP Proxy Port": {"zh_CN": "HTTP 代理端口", "zh_TW": "HTTP 代理埠", "ru_RU": "Порт HTTP-прокси", "fa_IR": "پورت پروکسی HTTP"},
    "Have any questions? Visit": {"zh_CN": "有任何问题？访问", "zh_TW": "有任何問題？訪問", "ru_RU": "Есть вопросы? Посетите", "fa_IR": "سؤالی دارید؟ مراجعه کنید به"},
    "IP Address": {"zh_CN": "IP 地址", "zh_TW": "IP 位址", "ru_RU": "IP-адрес", "fa_IR": "آدرس IP"},
    "IPv4/IPv6 Query Strategy": {"zh_CN": "IPv4/IPv6 查询策略", "zh_TW": "IPv4/IPv6 查詢策略", "ru_RU": "Стратегия запросов IPv4/IPv6", "fa_IR": "استراتژی پرس‌وجوی IPv4/IPv6"},
    "JinGo VPN - GNU General Public License v3.0\n\nCopyright (C) 2024-2025 JinGo Team\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\n(at your option) any later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program. If not, see <https://www.gnu.org/licenses/>.\n\n---\n\nThird-party components:\n- Xray-core: Mozilla Public License 2.0\n- Qt Framework: LGPL v3\n- OpenSSL: Apache License 2.0\n": {"zh_CN": "JinGo VPN - GNU 通用公共许可证 v3.0\n\n版权所有 (C) 2024-2025 JinGo 团队\n\n本程序是自由软件：您可以根据自由软件基金会发布的 GNU 通用公共许可证的条款重新发布和/或修改它，可以是许可证的第 3 版，或（由您选择）任何更高版本。\n\n本程序的发布是希望它有用，但没有任何保证；甚至没有对适销性或特定用途适用性的暗示保证。详细信息请参阅 GNU 通用公共许可证。\n\n您应该已经收到了 GNU 通用公共许可证的副本。如果没有，请参阅 <https://www.gnu.org/licenses/>。\n\n---\n\n第三方组件：\n- Xray-core：Mozilla 公共许可证 2.0\n- Qt 框架：LGPL v3\n- OpenSSL：Apache 许可证 2.0\n", "zh_TW": "JinGo VPN - GNU 通用公共授權條款 v3.0\n\n版權所有 (C) 2024-2025 JinGo 團隊\n\n本程式是自由軟體：您可以根據自由軟體基金會發布的 GNU 通用公共授權條款的條款重新發布和/或修改它，可以是授權條款的第 3 版，或（由您選擇）任何更高版本。\n\n本程式的發布是希望它有用，但沒有任何保證；甚至沒有對適銷性或特定用途適用性的暗示保證。詳細資訊請參閱 GNU 通用公共授權條款。\n\n您應該已經收到了 GNU 通用公共授權條款的副本。如果沒有，請參閱 <https://www.gnu.org/licenses/>。\n\n---\n\n第三方元件：\n- Xray-core：Mozilla 公共授權條款 2.0\n- Qt 框架：LGPL v3\n- OpenSSL：Apache 授權條款 2.0\n", "ru_RU": "JinGo VPN - Универсальная общественная лицензия GNU v3.0\n\nАвторское право (C) 2024-2025 Команда JinGo\n\nЭта программа является свободным программным обеспечением: вы можете распространять и/или модифицировать её на условиях Универсальной общественной лицензии GNU, опубликованной Фондом свободного программного обеспечения, либо версии 3 лицензии, либо (по вашему выбору) любой более поздней версии.\n\nЭта программа распространяется в надежде, что она будет полезной, но БЕЗ КАКИХ-ЛИБО ГАРАНТИЙ; даже без подразумеваемой гарантии ТОВАРНОЙ ПРИГОДНОСТИ или ПРИГОДНОСТИ ДЛЯ ОПРЕДЕЛЕННОЙ ЦЕЛИ. Подробнее см. Универсальную общественную лицензию GNU.\n\nВы должны были получить копию Универсальной общественной лицензии GNU вместе с этой программой. Если нет, см. <https://www.gnu.org/licenses/>.\n\n---\n\nСторонние компоненты:\n- Xray-core: Mozilla Public License 2.0\n- Qt Framework: LGPL v3\n- OpenSSL: Apache License 2.0\n", "fa_IR": "JinGo VPN - مجوز عمومی عمومی گنو نسخه 3.0\n\nحق نشر (C) 2024-2025 تیم JinGo\n\nاین برنامه نرم‌افزار آزاد است: شما می‌توانید آن را تحت شرایط مجوز عمومی عمومی گنو که توسط بنیاد نرم‌افزار آزاد منتشر شده است، بازتوزیع و/یا تغییر دهید، چه نسخه 3 مجوز یا (به انتخاب شما) هر نسخه بعدی.\n\nاین برنامه به امید مفید بودن توزیع می‌شود، اما بدون هیچ ضمانتی؛ حتی بدون ضمانت ضمنی قابلیت فروش یا مناسب بودن برای هدف خاص. برای جزئیات بیشتر مجوز عمومی عمومی گنو را ببینید.\n\nشما باید یک کپی از مجوز عمومی عمومی گنو همراه با این برنامه دریافت کرده باشید. اگر نه، به <https://www.gnu.org/licenses/> مراجعه کنید.\n\n---\n\nاجزای شخص ثالث:\n- Xray-core: Mozilla Public License 2.0\n- Qt Framework: LGPL v3\n- OpenSSL: Apache License 2.0\n"},
    "JinGoVPN": {"zh_CN": "JinGoVPN", "zh_TW": "JinGoVPN", "ru_RU": "JinGoVPN", "fa_IR": "JinGoVPN"},
    "Latency Test Method": {"zh_CN": "延迟测试方法", "zh_TW": "延遲測試方法", "ru_RU": "Метод тестирования задержки", "fa_IR": "روش تست تأخیر"},
    "Launch at system startup": {"zh_CN": "系统启动时启动", "zh_TW": "系統啟動時啟動", "ru_RU": "Запускать при старте системы", "fa_IR": "اجرا در هنگام راه‌اندازی سیستم"},
    "Load %1%": {"zh_CN": "负载 %1%", "zh_TW": "負載 %1%", "ru_RU": "Нагрузка %1%", "fa_IR": "بار %1%"},
    "LoadingPlans...": {"zh_CN": "加载套餐中...", "zh_TW": "載入方案中...", "ru_RU": "Загрузка планов...", "fa_IR": "در حال بارگذاری طرح‌ها..."},
    "Local HTTP proxy listen port - requires reconnecting after modification": {"zh_CN": "本地 HTTP 代理监听端口 - 修改后需要重新连接", "zh_TW": "本地 HTTP 代理監聽埠 - 修改後需要重新連接", "ru_RU": "Порт локального HTTP-прокси - требуется переподключение после изменения", "fa_IR": "پورت گوش‌دهی پروکسی HTTP محلی - نیاز به اتصال مجدد پس از تغییر"},
    "Local Proxy": {"zh_CN": "本地代理", "zh_TW": "本地代理", "ru_RU": "Локальный прокси", "fa_IR": "پروکسی محلی"},
    "Local SOCKS/HTTP proxy server settings": {"zh_CN": "本地 SOCKS/HTTP 代理服务器设置", "zh_TW": "本地 SOCKS/HTTP 代理伺服器設定", "ru_RU": "Настройки локального SOCKS/HTTP прокси-сервера", "fa_IR": "تنظیمات سرور پروکسی SOCKS/HTTP محلی"},
    "Local SOCKS5 proxy listen port - requires reconnecting after modification": {"zh_CN": "本地 SOCKS5 代理监听端口 - 修改后需要重新连接", "zh_TW": "本地 SOCKS5 代理監聽埠 - 修改後需要重新連接", "ru_RU": "Порт локального SOCKS5-прокси - требуется переподключение после изменения", "fa_IR": "پورت گوش‌دهی پروکسی SOCKS5 محلی - نیاز به اتصال مجدد پس از تغییر"},
    "Log Level": {"zh_CN": "日志级别", "zh_TW": "日誌等級", "ru_RU": "Уровень журнала", "fa_IR": "سطح لاگ"},
    "Log Settings": {"zh_CN": "日志设置", "zh_TW": "日誌設定", "ru_RU": "Настройки журнала", "fa_IR": "تنظیمات لاگ"},
    "Log all connection requests": {"zh_CN": "记录所有连接请求", "zh_TW": "記錄所有連接請求", "ru_RU": "Записывать все запросы на подключение", "fa_IR": "ثبت تمام درخواست‌های اتصال"},
    "Log retention days": {"zh_CN": "日志保留天数", "zh_TW": "日誌保留天數", "ru_RU": "Дней хранения журнала", "fa_IR": "روزهای نگهداری لاگ"},
    "Logging in...": {"zh_CN": "正在登录...", "zh_TW": "正在登入...", "ru_RU": "Вход...", "fa_IR": "در حال ورود..."},
    "Login/Register": {"zh_CN": "登录/注册", "zh_TW": "登入/註冊", "ru_RU": "Вход/Регистрация", "fa_IR": "ورود/ثبت‌نام"},
    "Manage your VPN connection": {"zh_CN": "管理您的 VPN 连接", "zh_TW": "管理您的 VPN 連接", "ru_RU": "Управление VPN-подключением", "fa_IR": "مدیریت اتصال VPN"},
    "Maximum concurrent multiplexed connections": {"zh_CN": "最大并发多路复用连接数", "zh_TW": "最大並行多路復用連接數", "ru_RU": "Максимум параллельных мультиплексных соединений", "fa_IR": "حداکثر اتصالات چندگانه همزمان"},
    "Minimize to System Tray": {"zh_CN": "最小化到系统托盘", "zh_TW": "最小化到系統匣", "ru_RU": "Свернуть в системный трей", "fa_IR": "کوچک کردن به سینی سیستم"},
    "Minimize to system tray instead of quit when closing window": {"zh_CN": "关闭窗口时最小化到系统托盘而不是退出", "zh_TW": "關閉視窗時最小化到系統匣而不是退出", "ru_RU": "Сворачивать в трей вместо закрытия при закрытии окна", "fa_IR": "کوچک کردن به سینی سیستم به جای خروج هنگام بستن پنجره"},
    "Modify": {"zh_CN": "修改", "zh_TW": "修改", "ru_RU": "Изменить", "fa_IR": "تغییر"},
    "Month": {"zh_CN": "月", "zh_TW": "月", "ru_RU": "Месяц", "fa_IR": "ماه"},
    "Monthly Traffic": {"zh_CN": "月流量", "zh_TW": "月流量", "ru_RU": "Месячный трафик", "fa_IR": "ترافیک ماهانه"},
    "Mux concurrent connections": {"zh_CN": "Mux 并发连接数", "zh_TW": "Mux 並行連接數", "ru_RU": "Параллельные Mux-соединения", "fa_IR": "اتصالات همزمان Mux"},
    "Network test": {"zh_CN": "网络测试", "zh_TW": "網路測試", "ru_RU": "Тест сети", "fa_IR": "تست شبکه"},
    "No Servers": {"zh_CN": "无服务器", "zh_TW": "無伺服器", "ru_RU": "Нет серверов", "fa_IR": "بدون سرور"},
    "No Servers Available": {"zh_CN": "无可用服务器", "zh_TW": "無可用伺服器", "ru_RU": "Нет доступных серверов", "fa_IR": "سروری در دسترس نیست"},
    "No matching servers found": {"zh_CN": "未找到匹配的服务器", "zh_TW": "未找到匹配的伺服器", "ru_RU": "Подходящие серверы не найдены", "fa_IR": "سرور منطبقی پیدا نشد"},
    "NoneAvailablePlans": {"zh_CN": "无可用套餐", "zh_TW": "無可用方案", "ru_RU": "Нет доступных планов", "fa_IR": "طرحی در دسترس نیست"},
    "Not Tested": {"zh_CN": "未测试", "zh_TW": "未測試", "ru_RU": "Не тестировано", "fa_IR": "تست نشده"},
    "Open": {"zh_CN": "打开", "zh_TW": "開啟", "ru_RU": "Открыть", "fa_IR": "باز کردن"},
    "Open Source License": {"zh_CN": "开源许可", "zh_TW": "開源授權", "ru_RU": "Лицензия с открытым исходным кодом", "fa_IR": "مجوز متن‌باز"},
    "Overseas DNS 1": {"zh_CN": "海外 DNS 1", "zh_TW": "海外 DNS 1", "ru_RU": "Зарубежный DNS 1", "fa_IR": "DNS خارجی 1"},
    "Overseas DNS 2": {"zh_CN": "海外 DNS 2", "zh_TW": "海外 DNS 2", "ru_RU": "Зарубежный DNS 2", "fa_IR": "DNS خارجی 2"},
    "Peak Download": {"zh_CN": "峰值下载", "zh_TW": "峰值下載", "ru_RU": "Пиковая загрузка", "fa_IR": "حداکثر دانلود"},
    "Peak Upload": {"zh_CN": "峰值上传", "zh_TW": "峰值上傳", "ru_RU": "Пиковая отдача", "fa_IR": "حداکثر آپلود"},
    "Plan Name": {"zh_CN": "套餐名称", "zh_TW": "方案名稱", "ru_RU": "Название плана", "fa_IR": "نام طرح"},
    "Plans #": {"zh_CN": "套餐 #", "zh_TW": "方案 #", "ru_RU": "План #", "fa_IR": "طرح #"},
    "Please add a subscription first": {"zh_CN": "请先添加订阅", "zh_TW": "請先新增訂閱", "ru_RU": "Сначала добавьте подписку", "fa_IR": "ابتدا یک اشتراک اضافه کنید"},
    "Please enter your registered email, we will send a reset link.": {"zh_CN": "请输入您的注册邮箱，我们将发送重置链接。", "zh_TW": "請輸入您的註冊電子郵件，我們將發送重設連結。", "ru_RU": "Введите зарегистрированную почту, мы отправим ссылку для сброса.", "fa_IR": "ایمیل ثبت‌نام خود را وارد کنید، لینک بازنشانی برایتان ارسال می‌شود."},
    "Poor": {"zh_CN": "较差", "zh_TW": "較差", "ru_RU": "Плохо", "fa_IR": "ضعیف"},
    "Preferences": {"zh_CN": "偏好设置", "zh_TW": "偏好設定", "ru_RU": "Настройки", "fa_IR": "ترجیحات"},
    "Premium Member": {"zh_CN": "高级会员", "zh_TW": "高級會員", "ru_RU": "Премиум участник", "fa_IR": "عضو ویژه"},
    "Price / Period": {"zh_CN": "价格/周期", "zh_TW": "價格/週期", "ru_RU": "Цена / Период", "fa_IR": "قیمت / دوره"},
    "Protocol transport related configuration": {"zh_CN": "协议传输相关配置", "zh_TW": "協定傳輸相關配置", "ru_RU": "Настройки транспорта протокола", "fa_IR": "پیکربندی مربوط به انتقال پروتکل"},
    "Purchase Now": {"zh_CN": "立即购买", "zh_TW": "立即購買", "ru_RU": "Купить сейчас", "fa_IR": "خرید"},
    "Refresh List": {"zh_CN": "刷新列表", "zh_TW": "重新整理列表", "ru_RU": "Обновить список", "fa_IR": "بازخوانی لیست"},
    "Registration Email": {"zh_CN": "注册邮箱", "zh_TW": "註冊電子郵件", "ru_RU": "Эл. почта регистрации", "fa_IR": "ایمیل ثبت‌نام"},
    "Rem: %1": {"zh_CN": "剩余：%1", "zh_TW": "剩餘：%1", "ru_RU": "Осталось: %1", "fa_IR": "باقیمانده: %1"},
    "Report Issue": {"zh_CN": "报告问题", "zh_TW": "回報問題", "ru_RU": "Сообщить о проблеме", "fa_IR": "گزارش مشکل"},
    "Reset all settings": {"zh_CN": "重置所有设置", "zh_TW": "重設所有設定", "ru_RU": "Сбросить все настройки", "fa_IR": "بازنشانی تمام تنظیمات"},
    "Restore default settings (does not affect account data)": {"zh_CN": "恢复默认设置（不影响账户数据）", "zh_TW": "還原預設設定（不影響帳戶資料）", "ru_RU": "Восстановить настройки по умолчанию (не влияет на данные аккаунта)", "fa_IR": "بازگرداندن تنظیمات پیش‌فرض (داده‌های حساب تأثیر نمی‌گیرد)"},
    "Rule": {"zh_CN": "规则", "zh_TW": "規則", "ru_RU": "Правило", "fa_IR": "قانون"},
    "Running Mode": {"zh_CN": "运行模式", "zh_TW": "執行模式", "ru_RU": "Режим работы", "fa_IR": "حالت اجرا"},
    "SOCKS Proxy Port": {"zh_CN": "SOCKS 代理端口", "zh_TW": "SOCKS 代理埠", "ru_RU": "Порт SOCKS-прокси", "fa_IR": "پورت پروکسی SOCKS"},
    "Select Plan": {"zh_CN": "选择套餐", "zh_TW": "選擇方案", "ru_RU": "Выбрать план", "fa_IR": "انتخاب طرح"},
    "Select app display language": {"zh_CN": "选择应用显示语言", "zh_TW": "選擇應用程式顯示語言", "ru_RU": "Выберите язык интерфейса", "fa_IR": "زبان نمایش برنامه را انتخاب کنید"},
    "Select app theme style": {"zh_CN": "选择应用主题样式", "zh_TW": "選擇應用程式主題樣式", "ru_RU": "Выберите тему оформления", "fa_IR": "سبک تم برنامه را انتخاب کنید"},
    "Select countries to bypass, their websites will connect directly": {"zh_CN": "选择要绕过的国家，其网站将直接连接", "zh_TW": "選擇要繞過的國家，其網站將直接連接", "ru_RU": "Выберите страны для обхода, их сайты будут подключаться напрямую", "fa_IR": "کشورهایی را برای دور زدن انتخاب کنید، وب‌سایت‌های آن‌ها مستقیم متصل می‌شوند"},
    "Select the best server": {"zh_CN": "选择最佳服务器", "zh_TW": "選擇最佳伺服器", "ru_RU": "Выбрать лучший сервер", "fa_IR": "انتخاب بهترین سرور"},
    "Send Reset Link": {"zh_CN": "发送重置链接", "zh_TW": "發送重設連結", "ru_RU": "Отправить ссылку для сброса", "fa_IR": "ارسال لینک بازنشانی"},
    "Server latency test timeout duration": {"zh_CN": "服务器延迟测试超时时长", "zh_TW": "伺服器延遲測試逾時時長", "ru_RU": "Тайм-аут теста задержки сервера", "fa_IR": "مدت زمان انتظار تست تأخیر سرور"},
    "Set log verbosity level": {"zh_CN": "设置日志详细级别", "zh_TW": "設定日誌詳細等級", "ru_RU": "Установить уровень детализации журнала", "fa_IR": "تنظیم سطح جزئیات لاگ"},
    "Signing up...": {"zh_CN": "正在注册...", "zh_TW": "正在註冊...", "ru_RU": "Регистрация...", "fa_IR": "در حال ثبت‌نام..."},
    "Start at Login": {"zh_CN": "登录时启动", "zh_TW": "登入時啟動", "ru_RU": "Запускать при входе", "fa_IR": "شروع در هنگام ورود"},
    "TCP Fast Open": {"zh_CN": "TCP 快速打开", "zh_TW": "TCP 快速開啟", "ru_RU": "TCP Fast Open", "fa_IR": "TCP Fast Open"},
    "Test Timeout": {"zh_CN": "测试超时", "zh_TW": "測試逾時", "ru_RU": "Тайм-аут теста", "fa_IR": "زمان انتظار تست"},
    "Total %1 servers": {"zh_CN": "共 %1 个服务器", "zh_TW": "共 %1 個伺服器", "ru_RU": "Всего %1 серверов", "fa_IR": "مجموع %1 سرور"},
    "Traffic Reset Date:": {"zh_CN": "流量重置日期：", "zh_TW": "流量重設日期：", "ru_RU": "Дата сброса трафика:", "fa_IR": "تاریخ بازنشانی ترافیک:"},
    "Traffic Statistics": {"zh_CN": "流量统计", "zh_TW": "流量統計", "ru_RU": "Статистика трафика", "fa_IR": "آمار ترافیک"},
    "Transfer multiple data streams through single connection, may reduce latency": {"zh_CN": "通过单个连接传输多个数据流，可能减少延迟", "zh_TW": "透過單一連接傳輸多個資料流，可能減少延遲", "ru_RU": "Передача нескольких потоков данных через одно соединение, может снизить задержку", "fa_IR": "انتقال چندین جریان داده از طریق یک اتصال، ممکن است تأخیر را کاهش دهد"},
    "Transport Layer Settings": {"zh_CN": "传输层设置", "zh_TW": "傳輸層設定", "ru_RU": "Настройки транспортного уровня", "fa_IR": "تنظیمات لایه انتقال"},
    "UnknownPlans": {"zh_CN": "未知套餐", "zh_TW": "未知方案", "ru_RU": "Неизвестные планы", "fa_IR": "طرح‌های ناشناخته"},
    "UnknownServers": {"zh_CN": "未知服务器", "zh_TW": "未知伺服器", "ru_RU": "Неизвестные серверы", "fa_IR": "سرورهای ناشناخته"},
    "Unlimited traffic, 5 devices": {"zh_CN": "无限流量，5台设备", "zh_TW": "無限流量，5台裝置", "ru_RU": "Безлимитный трафик, 5 устройств", "fa_IR": "ترافیک نامحدود، ۵ دستگاه"},
    "Unnamed Plan": {"zh_CN": "未命名套餐", "zh_TW": "未命名方案", "ru_RU": "План без названия", "fa_IR": "طرح بدون نام"},
    "Upgrade your subscription plan": {"zh_CN": "升级您的订阅套餐", "zh_TW": "升級您的訂閱方案", "ru_RU": "Обновить план подписки", "fa_IR": "ارتقای طرح اشتراک"},
    "Use custom IP geolocation database": {"zh_CN": "使用自定义 IP 地理位置数据库", "zh_TW": "使用自訂 IP 地理位置資料庫", "ru_RU": "Использовать пользовательскую базу геолокации IP", "fa_IR": "استفاده از پایگاه داده موقعیت جغرافیایی IP سفارشی"},
    "Use custom domain categorization database": {"zh_CN": "使用自定义域名分类数据库", "zh_TW": "使用自訂網域分類資料庫", "ru_RU": "Использовать пользовательскую базу категоризации доменов", "fa_IR": "استفاده از پایگاه داده دسته‌بندی دامنه سفارشی"},
    "Users": {"zh_CN": "用户", "zh_TW": "使用者", "ru_RU": "Пользователи", "fa_IR": "کاربران"},
    "VPN ConnectSuccess": {"zh_CN": "VPN 连接成功", "zh_TW": "VPN 連接成功", "ru_RU": "VPN подключен", "fa_IR": "اتصال VPN موفق"},
    "VPN Disconnected": {"zh_CN": "VPN 已断开", "zh_TW": "VPN 已斷開", "ru_RU": "VPN отключен", "fa_IR": "VPN قطع شد"},
    "View": {"zh_CN": "查看", "zh_TW": "檢視", "ru_RU": "Просмотр", "fa_IR": "مشاهده"},
    "View Logs": {"zh_CN": "查看日志", "zh_TW": "檢視日誌", "ru_RU": "Просмотр журналов", "fa_IR": "مشاهده لاگ‌ها"},
    "View Orders": {"zh_CN": "查看订单", "zh_TW": "檢視訂單", "ru_RU": "Просмотр заказов", "fa_IR": "مشاهده سفارش‌ها"},
    "View and manage your subscription orders": {"zh_CN": "查看和管理您的订阅订单", "zh_TW": "檢視和管理您的訂閱訂單", "ru_RU": "Просмотр и управление заказами подписки", "fa_IR": "مشاهده و مدیریت سفارش‌های اشتراک"},
    "Welcome to JinGoVPN": {"zh_CN": "欢迎使用 JinGoVPN", "zh_TW": "歡迎使用 JinGoVPN", "ru_RU": "Добро пожаловать в JinGoVPN", "fa_IR": "به JinGoVPN خوش آمدید"},
    "xray-core API service port": {"zh_CN": "xray-core API 服务端口", "zh_TW": "xray-core API 服務埠", "ru_RU": "Порт API-сервиса xray-core", "fa_IR": "پورت سرویس API xray-core"},

    # Additional translations
    "About JinGo": {"zh_CN": "关于 JinGo", "zh_TW": "關於 JinGo", "ru_RU": "О JinGo", "fa_IR": "درباره JinGo", "vi_VN": "Về JinGo", "km_KH": "អំពី JinGo", "my_MM": "JinGo အကြောင်း"},
    "JinGo Client": {"zh_CN": "JinGo 客户端", "zh_TW": "JinGo 用戶端", "ru_RU": "Клиент JinGo", "fa_IR": "کلاینت JinGo", "vi_VN": "JinGo Client", "km_KH": "JinGo Client", "my_MM": "JinGo Client"},
    "Tap to retry": {"zh_CN": "点击重试", "zh_TW": "點擊重試", "ru_RU": "Нажмите для повтора", "fa_IR": "برای تلاش مجدد ضربه بزنید", "vi_VN": "Nhấn để thử lại", "km_KH": "ចុចដើម្បីព្យាយាមម្ដងទៀត", "my_MM": "ထပ်စမ်းရန်နှိပ်"},
    "Free": {"zh_CN": "免费", "zh_TW": "免費", "ru_RU": "Бесплатно", "fa_IR": "رایگان", "vi_VN": "Miễn phí", "km_KH": "ឥតគិតថ្លៃ", "my_MM": "အခမဲ့"},
    "Standard": {"zh_CN": "标准", "zh_TW": "標準", "ru_RU": "Стандарт", "fa_IR": "استاندارد", "vi_VN": "Tiêu chuẩn", "km_KH": "ស្តង់ដារ", "my_MM": "စံသတ်မှတ်"},
    "Premium": {"zh_CN": "高级", "zh_TW": "高級", "ru_RU": "Премиум", "fa_IR": "ویژه", "vi_VN": "Cao cấp", "km_KH": "ពិសេស", "my_MM": "ပရီမီယံ"},
    "Pro": {"zh_CN": "专业", "zh_TW": "專業", "ru_RU": "Про", "fa_IR": "حرفه‌ای", "vi_VN": "Chuyên nghiệp", "km_KH": "វិជ្ជាជីវៈ", "my_MM": "ပရို"},
    "Elite": {"zh_CN": "精英", "zh_TW": "精英", "ru_RU": "Элита", "fa_IR": "نخبه", "vi_VN": "Tinh hoa", "km_KH": "អ្នកជំនាញ", "my_MM": "အထူး"},
    "Enterprise": {"zh_CN": "企业", "zh_TW": "企業", "ru_RU": "Корпоративный", "fa_IR": "سازمانی", "vi_VN": "Doanh nghiệp", "km_KH": "សហគ្រាស", "my_MM": "လုပ်ငန်း"},
    "Welcome to JinGo": {"zh_CN": "欢迎使用 JinGo", "zh_TW": "歡迎使用 JinGo", "ru_RU": "Добро пожаловать в JinGo", "fa_IR": "به JinGo خوش آمدید", "vi_VN": "Chào mừng đến JinGo", "km_KH": "សូមស្វាគមន៍មក JinGo", "my_MM": "JinGo မှကြိုဆိုပါသည်"},
    "Groups": {"zh_CN": "分组", "zh_TW": "群組", "ru_RU": "Группы", "fa_IR": "گروه‌ها", "vi_VN": "Nhóm", "km_KH": "ក្រុម", "my_MM": "အုပ်စုများ"},
    "Traffic": {"zh_CN": "流量", "zh_TW": "流量", "ru_RU": "Трафик", "fa_IR": "ترافیک", "vi_VN": "Lưu lượng", "km_KH": "ចរាចរណ៍", "my_MM": "အသွားအလာ"},
    "Days": {"zh_CN": "天", "zh_TW": "天", "ru_RU": "Дней", "fa_IR": "روز", "vi_VN": "Ngày", "km_KH": "ថ្ងៃ", "my_MM": "ရက်"},
    "Status": {"zh_CN": "状态", "zh_TW": "狀態", "ru_RU": "Статус", "fa_IR": "وضعیت", "vi_VN": "Trạng thái", "km_KH": "ស្ថានភាព", "my_MM": "အခြေအနေ"},
    "Test Speed": {"zh_CN": "测速", "zh_TW": "測速", "ru_RU": "Тест скорости", "fa_IR": "تست سرعت", "vi_VN": "Test tốc độ", "km_KH": "សាកល្បងល្បឿន", "my_MM": "အမြန်နှုန်းစမ်း"},
    "Server not found": {"zh_CN": "未找到服务器", "zh_TW": "未找到伺服器", "ru_RU": "Сервер не найден", "fa_IR": "سرور یافت نشد", "vi_VN": "Không tìm thấy máy chủ", "km_KH": "រកមិនឃើញម៉ាស៊ីនមេ", "my_MM": "ဆာဗာမတွေ့"},

    # App selector
    "Select Apps": {"zh_CN": "选择应用", "zh_TW": "選擇應用程式", "ru_RU": "Выбрать приложения", "fa_IR": "انتخاب برنامه‌ها", "vi_VN": "Chọn ứng dụng", "km_KH": "ជ្រើសរើសកម្មវិធី", "my_MM": "အက်ပ်ရွေး"},
    "%1 selected": {"zh_CN": "已选择 %1 个", "zh_TW": "已選擇 %1 個", "ru_RU": "%1 выбрано", "fa_IR": "%1 انتخاب شده", "vi_VN": "Đã chọn %1", "km_KH": "បានជ្រើស %1", "my_MM": "%1 ရွေးပြီး"},
    "Search apps...": {"zh_CN": "搜索应用...", "zh_TW": "搜尋應用程式...", "ru_RU": "Поиск приложений...", "fa_IR": "جستجوی برنامه‌ها...", "vi_VN": "Tìm ứng dụng...", "km_KH": "ស្វែងរកកម្មវិធី...", "my_MM": "အက်ပ်ရှာ..."},
    "Select All": {"zh_CN": "全选", "zh_TW": "全選", "ru_RU": "Выбрать все", "fa_IR": "انتخاب همه", "vi_VN": "Chọn tất cả", "km_KH": "ជ្រើសទាំងអស់", "my_MM": "အားလုံးရွေး"},
    "Deselect All": {"zh_CN": "取消全选", "zh_TW": "取消全選", "ru_RU": "Снять выделение", "fa_IR": "لغو انتخاب همه", "vi_VN": "Bỏ chọn tất cả", "km_KH": "មិនជ្រើសទាំងអស់", "my_MM": "အားလုံးဖြုတ်"},
    "No apps found": {"zh_CN": "未找到应用", "zh_TW": "未找到應用程式", "ru_RU": "Приложения не найдены", "fa_IR": "برنامه‌ای یافت نشد", "vi_VN": "Không tìm thấy ứng dụng", "km_KH": "រកមិនឃើញកម្មវិធី", "my_MM": "အက်ပ်မတွေ့"},
    "Save Selection": {"zh_CN": "保存选择", "zh_TW": "儲存選擇", "ru_RU": "Сохранить выбор", "fa_IR": "ذخیره انتخاب", "vi_VN": "Lưu lựa chọn", "km_KH": "រក្សាទុកការជ្រើសរើស", "my_MM": "ရွေးချယ်မှုသိမ်း"},

    # Password
    "Enter new password (min 8 chars)": {"zh_CN": "输入新密码（至少8位）", "zh_TW": "輸入新密碼（至少8位）", "ru_RU": "Введите новый пароль (мин. 8 символов)", "fa_IR": "رمز عبور جدید وارد کنید (حداقل 8 کاراکتر)", "vi_VN": "Nhập mật khẩu mới (tối thiểu 8 ký tự)", "km_KH": "បញ្ចូលពាក្យសម្ងាត់ថ្មី (យ៉ាងហោច 8 តួអក្សរ)", "my_MM": "စကားဝှက်အသစ်ထည့်ပါ (အနည်းဆုံး 8 လုံး)"},
    "• Password must be at least 8 characters": {"zh_CN": "• 密码至少需要8个字符", "zh_TW": "• 密碼至少需要8個字元", "ru_RU": "• Пароль должен содержать минимум 8 символов", "fa_IR": "• رمز عبور باید حداقل 8 کاراکتر باشد", "vi_VN": "• Mật khẩu phải có ít nhất 8 ký tự", "km_KH": "• ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោច 8 តួអក្សរ", "my_MM": "• စကားဝှက်သည် အနည်းဆုံး 8 လုံးရှိရမည်"},
    "New password must be at least 8 characters": {"zh_CN": "新密码至少需要8个字符", "zh_TW": "新密碼至少需要8個字元", "ru_RU": "Новый пароль должен содержать минимум 8 символов", "fa_IR": "رمز عبور جدید باید حداقل 8 کاراکتر باشد", "vi_VN": "Mật khẩu mới phải có ít nhất 8 ký tự", "km_KH": "ពាក្យសម្ងាត់ថ្មីត្រូវមានយ៉ាងហោច 8 តួអក្សរ", "my_MM": "စကားဝှက်အသစ်သည် အနည်းဆုံး 8 လုံးရှိရမည်"},

    # Connection
    "No Server Selected": {"zh_CN": "未选择服务器", "zh_TW": "未選擇伺服器", "ru_RU": "Сервер не выбран", "fa_IR": "سروری انتخاب نشده", "vi_VN": "Chưa chọn máy chủ", "km_KH": "មិនបានជ្រើសម៉ាស៊ីនមេ", "my_MM": "ဆာဗာမရွေးရသေး"},
    "Connection Duration": {"zh_CN": "连接时长", "zh_TW": "連接時長", "ru_RU": "Длительность соединения", "fa_IR": "مدت اتصال", "vi_VN": "Thời gian kết nối", "km_KH": "រយៈពេលភ្ជាប់", "my_MM": "ချိတ်ဆက်ချိန်"},
    "Connect Settings": {"zh_CN": "连接设置", "zh_TW": "連接設定", "ru_RU": "Настройки соединения", "fa_IR": "تنظیمات اتصال", "vi_VN": "Cài đặt kết nối", "km_KH": "ការកំណត់ការភ្ជាប់", "my_MM": "ချိတ်ဆက်ဆက်တင်"},
    "* Changes to connection settings require reconnecting to take effect": {"zh_CN": "* 连接设置的更改需要重新连接才能生效", "zh_TW": "* 連接設定的變更需要重新連接才能生效", "ru_RU": "* Изменения настроек соединения требуют переподключения", "fa_IR": "* تغییرات تنظیمات اتصال نیاز به اتصال مجدد دارد", "vi_VN": "* Thay đổi cài đặt kết nối cần kết nối lại", "km_KH": "* ការផ្លាស់ប្ដូរការកំណត់ការភ្ជាប់ត្រូវការភ្ជាប់ម្ដងទៀត", "my_MM": "* ချိတ်ဆက်ဆက်တင်ပြောင်းလဲမှုများ အသက်ဝင်ရန် ပြန်ချိတ်ဆက်ရမည်"},
    "Internal error: authManager not available": {"zh_CN": "内部错误：认证管理器不可用", "zh_TW": "內部錯誤：認證管理器不可用", "ru_RU": "Внутренняя ошибка: authManager недоступен", "fa_IR": "خطای داخلی: authManager در دسترس نیست", "vi_VN": "Lỗi nội bộ: authManager không khả dụng", "km_KH": "កំហុសខាងក្នុង: authManager មិនមាន", "my_MM": "အတွင်းပိုင်းအမှား: authManager မရနိုင်"},

    # Countries
    "Antarctica": {"zh_CN": "南极洲", "zh_TW": "南極洲", "ru_RU": "Антарктида", "fa_IR": "قطب جنوب", "vi_VN": "Nam Cực", "km_KH": "អង់តាក់ទិក", "my_MM": "အန္တာတိက"},
    "United States": {"zh_CN": "美国", "zh_TW": "美國", "ru_RU": "США", "fa_IR": "ایالات متحده", "vi_VN": "Hoa Kỳ", "km_KH": "សហរដ្ឋអាមេរិក", "my_MM": "အမေရိကန်"},
    "United Kingdom": {"zh_CN": "英国", "zh_TW": "英國", "ru_RU": "Великобритания", "fa_IR": "بریتانیا", "vi_VN": "Vương quốc Anh", "km_KH": "ចក្រភពអង់គ្លេស", "my_MM": "ဗြိတိန်"},
    "Japan": {"zh_CN": "日本", "zh_TW": "日本", "ru_RU": "Япония", "fa_IR": "ژاپن", "vi_VN": "Nhật Bản", "km_KH": "ជប៉ុន", "my_MM": "ဂျပန်"},
    "South Korea": {"zh_CN": "韩国", "zh_TW": "韓國", "ru_RU": "Южная Корея", "fa_IR": "کره جنوبی", "vi_VN": "Hàn Quốc", "km_KH": "កូរ៉េខាងត្បូង", "my_MM": "တောင်ကိုရီးယား"},
    "Hong Kong": {"zh_CN": "香港", "zh_TW": "香港", "ru_RU": "Гонконг", "fa_IR": "هنگ کنگ", "vi_VN": "Hồng Kông", "km_KH": "ហុងកុង", "my_MM": "ဟောင်ကောင်"},
    "Taiwan": {"zh_CN": "台湾", "zh_TW": "台灣", "ru_RU": "Тайвань", "fa_IR": "تایوان", "vi_VN": "Đài Loan", "km_KH": "តៃវ៉ាន់", "my_MM": "ထိုင်ဝမ်"},
    "Singapore": {"zh_CN": "新加坡", "zh_TW": "新加坡", "ru_RU": "Сингапур", "fa_IR": "سنگاپور", "vi_VN": "Singapore", "km_KH": "សិង្ហបុរី", "my_MM": "စင်ကာပူ"},
    "Germany": {"zh_CN": "德国", "zh_TW": "德國", "ru_RU": "Германия", "fa_IR": "آلمان", "vi_VN": "Đức", "km_KH": "អាល្លឺម៉ង់", "my_MM": "ဂျာမနီ"},
    "France": {"zh_CN": "法国", "zh_TW": "法國", "ru_RU": "Франция", "fa_IR": "فرانسه", "vi_VN": "Pháp", "km_KH": "បារាំង", "my_MM": "ပြင်သစ်"},
    "Canada": {"zh_CN": "加拿大", "zh_TW": "加拿大", "ru_RU": "Канада", "fa_IR": "کانادا", "vi_VN": "Canada", "km_KH": "កាណាដា", "my_MM": "ကနေဒါ"},
    "Australia": {"zh_CN": "澳大利亚", "zh_TW": "澳大利亞", "ru_RU": "Австралия", "fa_IR": "استرالیا", "vi_VN": "Úc", "km_KH": "អូស្ត្រាលី", "my_MM": "သြစတြေးလျ"},
    "India": {"zh_CN": "印度", "zh_TW": "印度", "ru_RU": "Индия", "fa_IR": "هند", "vi_VN": "Ấn Độ", "km_KH": "ឥណ្ឌា", "my_MM": "အိန္ဒိယ"},
    "Brazil": {"zh_CN": "巴西", "zh_TW": "巴西", "ru_RU": "Бразилия", "fa_IR": "برزیل", "vi_VN": "Brazil", "km_KH": "ប្រេស៊ីល", "my_MM": "ဘရာဇီး"},
    "Netherlands": {"zh_CN": "荷兰", "zh_TW": "荷蘭", "ru_RU": "Нидерланды", "fa_IR": "هلند", "vi_VN": "Hà Lan", "km_KH": "ហូឡង់", "my_MM": "နယ်သာလန်"},
    "Sweden": {"zh_CN": "瑞典", "zh_TW": "瑞典", "ru_RU": "Швеция", "fa_IR": "سوئد", "vi_VN": "Thụy Điển", "km_KH": "ស៊ុយអែត", "my_MM": "ဆွီဒင်"},
    "Switzerland": {"zh_CN": "瑞士", "zh_TW": "瑞士", "ru_RU": "Швейцария", "fa_IR": "سوئیس", "vi_VN": "Thụy Sĩ", "km_KH": "ស្វ៊ីស", "my_MM": "ဆွစ်ဇာလန်"},
    "Italy": {"zh_CN": "意大利", "zh_TW": "義大利", "ru_RU": "Италия", "fa_IR": "ایتالیا", "vi_VN": "Ý", "km_KH": "អ៊ីតាលី", "my_MM": "အီတလီ"},
    "Spain": {"zh_CN": "西班牙", "zh_TW": "西班牙", "ru_RU": "Испания", "fa_IR": "اسپانیا", "vi_VN": "Tây Ban Nha", "km_KH": "អេស្ប៉ាញ", "my_MM": "စပိန်"},

    # Forgot password
    "Enter your email to receive a verification code, then set a new password.": {"zh_CN": "输入您的邮箱以接收验证码，然后设置新密码。", "zh_TW": "輸入您的電子郵件以接收驗證碼，然後設定新密碼。", "ru_RU": "Введите email для получения кода подтверждения, затем установите новый пароль.", "fa_IR": "ایمیل خود را برای دریافت کد تأیید وارد کنید، سپس رمز عبور جدید تنظیم کنید.", "vi_VN": "Nhập email để nhận mã xác nhận, sau đó đặt mật khẩu mới.", "km_KH": "បញ្ចូលអ៊ីមែលរបស់អ្នកដើម្បីទទួលលេខកូដផ្ទៀងផ្ទាត់ បន្ទាប់មកកំណត់ពាក្យសម្ងាត់ថ្មី។", "my_MM": "အီးမေးလ်ထည့်၍ အတည်ပြုကုဒ်ရယူပါ၊ ထို့နောက် စကားဝှက်အသစ်သတ်မှတ်ပါ။"},
    "Enter registered email": {"zh_CN": "输入注册邮箱", "zh_TW": "輸入註冊電子郵件", "ru_RU": "Введите зарегистрированный email", "fa_IR": "ایمیل ثبت‌نام شده را وارد کنید", "vi_VN": "Nhập email đã đăng ký", "km_KH": "បញ្ចូលអ៊ីមែលដែលបានចុះឈ្មោះ", "my_MM": "မှတ်ပုံတင်ထားသောအီးမေးလ်ထည့်ပါ"},
    "Reset Successful": {"zh_CN": "重置成功", "zh_TW": "重設成功", "ru_RU": "Сброс выполнен", "fa_IR": "بازنشانی موفق", "vi_VN": "Đặt lại thành công", "km_KH": "កំណត់ឡើងវិញជោគជ័យ", "my_MM": "ပြန်သတ်မှတ်အောင်မြင်"},
    "Resetting...": {"zh_CN": "重置中...", "zh_TW": "重設中...", "ru_RU": "Сброс...", "fa_IR": "در حال بازنشانی...", "vi_VN": "Đang đặt lại...", "km_KH": "កំពុងកំណត់ឡើងវិញ...", "my_MM": "ပြန်သတ်မှတ်နေ..."},
    "System not ready, please try again later": {"zh_CN": "系统未就绪，请稍后重试", "zh_TW": "系統未就緒，請稍後重試", "ru_RU": "Система не готова, попробуйте позже", "fa_IR": "سیستم آماده نیست، لطفا بعدا تلاش کنید", "vi_VN": "Hệ thống chưa sẵn sàng, vui lòng thử lại sau", "km_KH": "ប្រព័ន្ធមិនទាន់រួចរាល់ សូមព្យាយាមម្ដងទៀត", "my_MM": "စနစ်အဆင်သင့်မဖြစ်သေး၊ နောက်မှထပ်စမ်းပါ"},

    # Help center
    "Search articles...": {"zh_CN": "搜索文章...", "zh_TW": "搜尋文章...", "ru_RU": "Поиск статей...", "fa_IR": "جستجوی مقالات...", "vi_VN": "Tìm bài viết...", "km_KH": "ស្វែងរកអត្ថបទ...", "my_MM": "ဆောင်းပါးရှာ..."},
    "No matching articles": {"zh_CN": "没有匹配的文章", "zh_TW": "沒有符合的文章", "ru_RU": "Статьи не найдены", "fa_IR": "مقاله‌ای مطابقت ندارد", "vi_VN": "Không tìm thấy bài viết", "km_KH": "គ្មានអត្ថបទដែលត្រូវគ្នា", "my_MM": "ကိုက်ညီသောဆောင်းပါးမရှိ"},
    "No articles yet": {"zh_CN": "暂无文章", "zh_TW": "暫無文章", "ru_RU": "Пока нет статей", "fa_IR": "هنوز مقاله‌ای نیست", "vi_VN": "Chưa có bài viết", "km_KH": "មិនទាន់មានអត្ថបទ", "my_MM": "ဆောင်းပါးမရှိသေး"},
    "Try different keywords": {"zh_CN": "尝试不同的关键词", "zh_TW": "嘗試不同的關鍵字", "ru_RU": "Попробуйте другие ключевые слова", "fa_IR": "کلمات کلیدی دیگری امتحان کنید", "vi_VN": "Thử từ khóa khác", "km_KH": "សាកល្បងពាក្យគន្លឹះផ្សេង", "my_MM": "အခြားသော့ချက်စာလုံးများဖြင့်စမ်းကြည့်ပါ"},
    "Clear Search": {"zh_CN": "清除搜索", "zh_TW": "清除搜尋", "ru_RU": "Очистить поиск", "fa_IR": "پاک کردن جستجو", "vi_VN": "Xóa tìm kiếm", "km_KH": "សម្អាតការស្វែងរក", "my_MM": "ရှာဖွေမှုရှင်း"},

    # Speed test
    "Save to Downloads folder": {"zh_CN": "保存到下载文件夹", "zh_TW": "儲存到下載資料夾", "ru_RU": "Сохранить в папку Загрузки", "fa_IR": "ذخیره در پوشه دانلودها", "vi_VN": "Lưu vào thư mục Tải xuống", "km_KH": "រក្សាទុកក្នុងថតទាញយក", "my_MM": "ဒေါင်းလုဒ်ဖိုဒါတွင်သိမ်းပါ"},
    "10MB: Quick test": {"zh_CN": "10MB：快速测试", "zh_TW": "10MB：快速測試", "ru_RU": "10МБ: Быстрый тест", "fa_IR": "10 مگابایت: تست سریع", "vi_VN": "10MB: Test nhanh", "km_KH": "10MB: សាកល្បងរហ័ស", "my_MM": "10MB: အမြန်စမ်းသပ်"},
    "25MB: Standard test": {"zh_CN": "25MB：标准测试", "zh_TW": "25MB：標準測試", "ru_RU": "25МБ: Стандартный тест", "fa_IR": "25 مگابایت: تست استاندارد", "vi_VN": "25MB: Test tiêu chuẩn", "km_KH": "25MB: សាកល្បងស្តង់ដារ", "my_MM": "25MB: စံစမ်းသပ်"},
    "Delete all logs except current": {"zh_CN": "删除当前日志以外的所有日志", "zh_TW": "刪除當前日誌以外的所有日誌", "ru_RU": "Удалить все журналы кроме текущего", "fa_IR": "حذف همه لاگ‌ها به جز لاگ فعلی", "vi_VN": "Xóa tất cả nhật ký trừ hiện tại", "km_KH": "លុបកំណត់ត្រាទាំងអស់លើកលែងបច្ចុប្បន្ន", "my_MM": "လက်ရှိမှတ်တမ်းမှလွဲ၍ အားလုံးဖျက်"},
    "Open log directory": {"zh_CN": "打开日志目录", "zh_TW": "開啟日誌目錄", "ru_RU": "Открыть папку журналов", "fa_IR": "باز کردن پوشه لاگ", "vi_VN": "Mở thư mục nhật ký", "km_KH": "បើកថតកំណត់ត្រា", "my_MM": "မှတ်တမ်းဖိုဒါဖွင့်"},

    # Version
    "Version": {"zh_CN": "版本", "zh_TW": "版本", "ru_RU": "Версия", "fa_IR": "نسخه", "vi_VN": "Phiên bản", "km_KH": "កំណែ", "my_MM": "ဗားရှင်း"},
    "Powered by": {"zh_CN": "技术支持", "zh_TW": "技術支援", "ru_RU": "На базе", "fa_IR": "قدرت گرفته از", "vi_VN": "Được hỗ trợ bởi", "km_KH": "ដំណើរការដោយ", "my_MM": "ပံ့ပိုးသည်"},
    "Open Source Licenses": {"zh_CN": "开源许可证", "zh_TW": "開源授權", "ru_RU": "Лицензии открытого кода", "fa_IR": "مجوزهای متن‌باز", "vi_VN": "Giấy phép mã nguồn mở", "km_KH": "អាជ្ញាប័ណ្ណកូដចំហ", "my_MM": "အိုပင်ဆိုစ်လိုင်စင်"},
    "Website": {"zh_CN": "官网", "zh_TW": "官網", "ru_RU": "Сайт", "fa_IR": "وب‌سایت", "vi_VN": "Website", "km_KH": "គេហទំព័រ", "my_MM": "ဝဘ်ဆိုက်"},
    "Copyright": {"zh_CN": "版权", "zh_TW": "版權", "ru_RU": "Авторские права", "fa_IR": "حق نشر", "vi_VN": "Bản quyền", "km_KH": "រក្សាសិទ្ធិ", "my_MM": "မူပိုင်ခွင့်"},
    "All rights reserved.": {"zh_CN": "保留所有权利。", "zh_TW": "保留所有權利。", "ru_RU": "Все права защищены.", "fa_IR": "تمامی حقوق محفوظ است.", "vi_VN": "Bảo lưu mọi quyền.", "km_KH": "រក្សាសិទ្ធិគ្រប់យ៉ាង។", "my_MM": "မူပိုင်ခွင့်အားလုံးထိန်းသိမ်းထားပါသည်။"},

    # Running mode
    "Running Mode": {"zh_CN": "运行模式", "zh_TW": "執行模式", "ru_RU": "Режим работы", "fa_IR": "حالت اجرا", "vi_VN": "Chế độ chạy", "km_KH": "របៀបដំណើរការ", "my_MM": "အလုပ်လုပ်ပုံ"},
    "Rule": {"zh_CN": "规则", "zh_TW": "規則", "ru_RU": "Правило", "fa_IR": "قانون", "vi_VN": "Quy tắc", "km_KH": "ច្បាប់", "my_MM": "စည်းမျဉ်း"},
    "IP Address": {"zh_CN": "IP 地址", "zh_TW": "IP 位址", "ru_RU": "IP-адрес", "fa_IR": "آدرس IP", "vi_VN": "Địa chỉ IP", "km_KH": "អាសយដ្ឋាន IP", "my_MM": "IP လိပ်စာ"},

    # Help articles
    "Article Content": {"zh_CN": "文章内容", "zh_TW": "文章內容", "ru_RU": "Содержание статьи", "fa_IR": "محتوای مقاله", "vi_VN": "Nội dung bài viết", "km_KH": "មាតិកាអត្ថបទ", "my_MM": "ဆောင်းပါးအကြောင်းအရာ"},
    "Image": {"zh_CN": "图片", "zh_TW": "圖片", "ru_RU": "Изображение", "fa_IR": "تصویر", "vi_VN": "Hình ảnh", "km_KH": "រូបភាព", "my_MM": "ပုံ"},
    "Loading image...": {"zh_CN": "加载图片中...", "zh_TW": "載入圖片中...", "ru_RU": "Загрузка изображения...", "fa_IR": "در حال بارگذاری تصویر...", "vi_VN": "Đang tải hình...", "km_KH": "កំពុងផ្ទុករូបភាព...", "my_MM": "ပုံဖွင့်နေ..."},
    "Image load failed": {"zh_CN": "图片加载失败", "zh_TW": "圖片載入失敗", "ru_RU": "Ошибка загрузки изображения", "fa_IR": "بارگذاری تصویر ناموفق", "vi_VN": "Tải hình thất bại", "km_KH": "ផ្ទុករូបភាពបរាជ័យ", "my_MM": "ပုံဖွင့်မအောင်"},
    "Was this article helpful?": {"zh_CN": "这篇文章有帮助吗？", "zh_TW": "這篇文章有幫助嗎？", "ru_RU": "Была ли статья полезной?", "fa_IR": "آیا این مقاله مفید بود؟", "vi_VN": "Bài viết này có hữu ích không?", "km_KH": "តើអត្ថបទនេះមានប្រយោជន៍ទេ?", "my_MM": "ဒီဆောင်းပါးအသုံးဝင်ပါသလား?"},

    # Authentication
    "Email/Username": {"zh_CN": "邮箱/用户名", "zh_TW": "電子郵件/使用者名稱", "ru_RU": "Email/Имя пользователя", "fa_IR": "ایمیل/نام کاربری", "vi_VN": "Email/Tên người dùng", "km_KH": "អ៊ីមែល/ឈ្មោះអ្នកប្រើ", "my_MM": "အီးမေးလ်/အသုံးပြုသူအမည်"},
    "Enter email or username": {"zh_CN": "输入邮箱或用户名", "zh_TW": "輸入電子郵件或使用者名稱", "ru_RU": "Введите email или имя пользователя", "fa_IR": "ایمیل یا نام کاربری را وارد کنید", "vi_VN": "Nhập email hoặc tên người dùng", "km_KH": "បញ្ចូលអ៊ីមែល ឬឈ្មោះអ្នកប្រើ", "my_MM": "အီးမေးလ် သို့ အသုံးပြုသူအမည်ထည့်ပါ"},
    "Enter password": {"zh_CN": "输入密码", "zh_TW": "輸入密碼", "ru_RU": "Введите пароль", "fa_IR": "رمز عبور را وارد کنید", "vi_VN": "Nhập mật khẩu", "km_KH": "បញ្ចូលពាក្យសម្ងាត់", "my_MM": "စကားဝှက်ထည့်ပါ"},
    "Remember password": {"zh_CN": "记住密码", "zh_TW": "記住密碼", "ru_RU": "Запомнить пароль", "fa_IR": "یادآوری رمز عبور", "vi_VN": "Ghi nhớ mật khẩu", "km_KH": "ចាំពាក្យសម្ងាត់", "my_MM": "စကားဝှက်မှတ်ထား"},
    "Have any questions? Visit": {"zh_CN": "有任何问题？访问", "zh_TW": "有任何問題？訪問", "ru_RU": "Есть вопросы? Посетите", "fa_IR": "سوالی دارید؟ مراجعه کنید به", "vi_VN": "Có câu hỏi? Truy cập", "km_KH": "មានសំណួរ? សូមចូលទៅ", "my_MM": "မေးစရာရှိပါသလား?"},

    # Payment
    "Order Detail": {"zh_CN": "订单详情", "zh_TW": "訂單詳情", "ru_RU": "Детали заказа", "fa_IR": "جزئیات سفارش", "vi_VN": "Chi tiết đơn hàng", "km_KH": "ព័ត៌មានលម្អិតការបញ្ជាទិញ", "my_MM": "အော်ဒါအသေးစိတ်"},
    "Select Payment": {"zh_CN": "选择支付方式", "zh_TW": "選擇付款方式", "ru_RU": "Выберите способ оплаты", "fa_IR": "انتخاب روش پرداخت", "vi_VN": "Chọn thanh toán", "km_KH": "ជ្រើសរើសការទូទាត់", "my_MM": "ငွေပေးချေမှုရွေး"},
    "Pay Now": {"zh_CN": "立即支付", "zh_TW": "立即付款", "ru_RU": "Оплатить", "fa_IR": "پرداخت", "vi_VN": "Thanh toán ngay", "km_KH": "បង់ឥឡូវ", "my_MM": "ယခုပေးချေ"},
    "View Details": {"zh_CN": "查看详情", "zh_TW": "檢視詳情", "ru_RU": "Подробнее", "fa_IR": "مشاهده جزئیات", "vi_VN": "Xem chi tiết", "km_KH": "មើលព័ត៌មានលម្អិត", "my_MM": "အသေးစိတ်ကြည့်"},
    "Plan Information": {"zh_CN": "套餐信息", "zh_TW": "方案資訊", "ru_RU": "Информация о плане", "fa_IR": "اطلاعات طرح", "vi_VN": "Thông tin gói", "km_KH": "ព័ត៌មានគម្រោង", "my_MM": "အစီအစဉ်အချက်အလက်"},
    "Plan Name:": {"zh_CN": "套餐名称：", "zh_TW": "方案名稱：", "ru_RU": "Название плана:", "fa_IR": "نام طرح:", "vi_VN": "Tên gói:", "km_KH": "ឈ្មោះគម្រោង:", "my_MM": "အစီအစဉ်အမည်:"},
    "Period:": {"zh_CN": "周期：", "zh_TW": "週期：", "ru_RU": "Период:", "fa_IR": "دوره:", "vi_VN": "Chu kỳ:", "km_KH": "រយៈពេល:", "my_MM": "ကာလ:"},
    "Payment Information": {"zh_CN": "支付信息", "zh_TW": "付款資訊", "ru_RU": "Информация об оплате", "fa_IR": "اطلاعات پرداخت", "vi_VN": "Thông tin thanh toán", "km_KH": "ព័ត៌មានការទូទាត់", "my_MM": "ငွေပေးချေမှုအချက်အလက်"},
    "Original Price:": {"zh_CN": "原价：", "zh_TW": "原價：", "ru_RU": "Исходная цена:", "fa_IR": "قیمت اصلی:", "vi_VN": "Giá gốc:", "km_KH": "តម្លៃដើម:", "my_MM": "မူလစျေးနှုန်း:"},
    "Discount:": {"zh_CN": "折扣：", "zh_TW": "折扣：", "ru_RU": "Скидка:", "fa_IR": "تخفیف:", "vi_VN": "Giảm giá:", "km_KH": "បញ្ចុះតម្លៃ:", "my_MM": "လျှော့စျေး:"},
    "Final Amount:": {"zh_CN": "最终金额：", "zh_TW": "最終金額：", "ru_RU": "Итоговая сумма:", "fa_IR": "مبلغ نهایی:", "vi_VN": "Số tiền cuối:", "km_KH": "ចំនួនទឹកប្រាក់ចុងក្រោយ:", "my_MM": "နောက်ဆုံးငွေပမာဏ:"},
    "Time Information": {"zh_CN": "时间信息", "zh_TW": "時間資訊", "ru_RU": "Информация о времени", "fa_IR": "اطلاعات زمان", "vi_VN": "Thông tin thời gian", "km_KH": "ព័ត៌មានពេលវេលា", "my_MM": "အချိန်အချက်အလက်"},
    "Amount to Pay": {"zh_CN": "应付金额", "zh_TW": "應付金額", "ru_RU": "Сумма к оплате", "fa_IR": "مبلغ قابل پرداخت", "vi_VN": "Số tiền phải trả", "km_KH": "ចំនួនទឹកប្រាក់ត្រូវបង់", "my_MM": "ပေးရမည့်ငွေပမာဏ"},
    "Fee: %1%": {"zh_CN": "手续费：%1%", "zh_TW": "手續費：%1%", "ru_RU": "Комиссия: %1%", "fa_IR": "کارمزد: %1%", "vi_VN": "Phí: %1%", "km_KH": "ថ្លៃសេវា: %1%", "my_MM": "အခကြေးငွေ: %1%"},

    # Billing periods
    "Monthly": {"zh_CN": "月付", "zh_TW": "月付", "ru_RU": "Ежемесячно", "fa_IR": "ماهانه", "vi_VN": "Hàng tháng", "km_KH": "ប្រចាំខែ", "my_MM": "လစဉ်"},
    "Quarterly": {"zh_CN": "季付", "zh_TW": "季付", "ru_RU": "Ежеквартально", "fa_IR": "سه ماهه", "vi_VN": "Hàng quý", "km_KH": "ត្រីមាស", "my_MM": "သုံးလတစ်ကြိမ်"},
    "Semi-Annual": {"zh_CN": "半年付", "zh_TW": "半年付", "ru_RU": "Полугодовой", "fa_IR": "شش ماهه", "vi_VN": "Nửa năm", "km_KH": "កន្លះឆ្នាំ", "my_MM": "နှစ်ဝက်"},
    "Annual": {"zh_CN": "年付", "zh_TW": "年付", "ru_RU": "Ежегодно", "fa_IR": "سالانه", "vi_VN": "Hàng năm", "km_KH": "ប្រចាំឆ្នាំ", "my_MM": "နှစ်စဉ်"},
    "2 Years": {"zh_CN": "两年", "zh_TW": "兩年", "ru_RU": "2 года", "fa_IR": "2 سال", "vi_VN": "2 năm", "km_KH": "2 ឆ្នាំ", "my_MM": "2 နှစ်"},
    "3 Years": {"zh_CN": "三年", "zh_TW": "三年", "ru_RU": "3 года", "fa_IR": "3 سال", "vi_VN": "3 năm", "km_KH": "3 ឆ្នាំ", "my_MM": "3 နှစ်"},
    "One-time": {"zh_CN": "一次性", "zh_TW": "一次性", "ru_RU": "Единоразово", "fa_IR": "یک‌بار", "vi_VN": "Một lần", "km_KH": "មួយដង", "my_MM": "တစ်ကြိမ်"},
    "Plan #%1": {"zh_CN": "套餐 #%1", "zh_TW": "方案 #%1", "ru_RU": "План #%1", "fa_IR": "طرح #%1", "vi_VN": "Gói #%1", "km_KH": "គម្រោង #%1", "my_MM": "အစီအစဉ် #%1"},
    "Select Subscription Period": {"zh_CN": "选择订阅周期", "zh_TW": "選擇訂閱週期", "ru_RU": "Выберите период подписки", "fa_IR": "دوره اشتراک را انتخاب کنید", "vi_VN": "Chọn chu kỳ đăng ký", "km_KH": "ជ្រើសរើសរយៈពេលការជាវ", "my_MM": "စာရင်းသွင်းကာလရွေး"},
    "Plan: %1": {"zh_CN": "套餐：%1", "zh_TW": "方案：%1", "ru_RU": "План: %1", "fa_IR": "طرح: %1", "vi_VN": "Gói: %1", "km_KH": "គម្រោង: %1", "my_MM": "အစီအစဉ်: %1"},
    "Choose your billing cycle:": {"zh_CN": "选择您的计费周期：", "zh_TW": "選擇您的計費週期：", "ru_RU": "Выберите период оплаты:", "fa_IR": "چرخه صورتحساب خود را انتخاب کنید:", "vi_VN": "Chọn chu kỳ thanh toán:", "km_KH": "ជ្រើសរើសវដ្តវិក្កយបត្រ:", "my_MM": "ငွေပေးချေမှုစက်ဝန်းရွေးပါ:"},
    "Unknown Period": {"zh_CN": "未知周期", "zh_TW": "未知週期", "ru_RU": "Неизвестный период", "fa_IR": "دوره نامشخص", "vi_VN": "Chu kỳ không xác định", "km_KH": "រយៈពេលមិនស្គាល់", "my_MM": "မသိသောကာလ"},
    "≈ %1%2/mo": {"zh_CN": "≈ %1%2/月", "zh_TW": "≈ %1%2/月", "ru_RU": "≈ %1%2/мес", "fa_IR": "≈ %1%2/ماه", "vi_VN": "≈ %1%2/tháng", "km_KH": "≈ %1%2/ខែ", "my_MM": "≈ %1%2/လ"},
    "No pricing options available": {"zh_CN": "暂无可用的价格选项", "zh_TW": "暫無可用的價格選項", "ru_RU": "Нет доступных вариантов цен", "fa_IR": "گزینه قیمتی موجود نیست", "vi_VN": "Không có tùy chọn giá", "km_KH": "គ្មានជម្រើសតម្លៃ", "my_MM": "စျေးနှုန်းရွေးချယ်မှုမရှိ"},
    "Continue": {"zh_CN": "继续", "zh_TW": "繼續", "ru_RU": "Продолжить", "fa_IR": "ادامه", "vi_VN": "Tiếp tục", "km_KH": "បន្ត", "my_MM": "ဆက်သွား"},

    # Profile
    "Users": {"zh_CN": "用户", "zh_TW": "使用者", "ru_RU": "Пользователи", "fa_IR": "کاربران", "vi_VN": "Người dùng", "km_KH": "អ្នកប្រើប្រាស់", "my_MM": "အသုံးပြုသူများ"},
    "Account ID: ": {"zh_CN": "账户ID：", "zh_TW": "帳戶ID：", "ru_RU": "ID аккаунта: ", "fa_IR": "شناسه حساب: ", "vi_VN": "ID tài khoản: ", "km_KH": "លេខសម្គាល់គណនី: ", "my_MM": "အကောင့် ID: "},
    "Monthly Traffic": {"zh_CN": "月流量", "zh_TW": "月流量", "ru_RU": "Месячный трафик", "fa_IR": "ترافیک ماهانه", "vi_VN": "Lưu lượng tháng", "km_KH": "ចរាចរប្រចាំខែ", "my_MM": "လစဉ်အသွားအလာ"},
    "Days Used": {"zh_CN": "已用天数", "zh_TW": "已用天數", "ru_RU": "Использовано дней", "fa_IR": "روزهای استفاده شده", "vi_VN": "Số ngày đã dùng", "km_KH": "ថ្ងៃបានប្រើ", "my_MM": "အသုံးပြုပြီးရက်"},
    "Active": {"zh_CN": "活跃", "zh_TW": "活躍", "ru_RU": "Активен", "fa_IR": "فعال", "vi_VN": "Hoạt động", "km_KH": "សកម្ម", "my_MM": "အသက်ဝင်"},
    "Account Actions": {"zh_CN": "账户操作", "zh_TW": "帳戶操作", "ru_RU": "Действия с аккаунтом", "fa_IR": "عملیات حساب", "vi_VN": "Thao tác tài khoản", "km_KH": "សកម្មភាពគណនី", "my_MM": "အကောင့်လုပ်ဆောင်ချက်"},
    "Reconnecting...": {"zh_CN": "正在重新连接...", "zh_TW": "正在重新連接...", "ru_RU": "Переподключение...", "fa_IR": "در حال اتصال مجدد...", "vi_VN": "Đang kết nối lại...", "km_KH": "កំពុងភ្ជាប់ឡើងវិញ...", "my_MM": "ပြန်ချိတ်ဆက်နေ..."},
    "Connection Error": {"zh_CN": "连接错误", "zh_TW": "連接錯誤", "ru_RU": "Ошибка соединения", "fa_IR": "خطای اتصال", "vi_VN": "Lỗi kết nối", "km_KH": "កំហុសការភ្ជាប់", "my_MM": "ချိတ်ဆက်အမှား"},

    # Chinese UI strings (for translation from Chinese source)
    "授权提示": {"zh_CN": "授权提示", "zh_TW": "授權提示", "ru_RU": "Уведомление о лицензии", "fa_IR": "اعلان مجوز", "vi_VN": "Thông báo bản quyền", "km_KH": "ការជូនដំណឹងអាជ្ញាប័ណ្ណ", "my_MM": "လိုင်စင်အကြောင်းကြား"},
    "稍后提醒": {"zh_CN": "稍后提醒", "zh_TW": "稍後提醒", "ru_RU": "Напомнить позже", "fa_IR": "بعدا یادآوری کن", "vi_VN": "Nhắc sau", "km_KH": "រំលឹកពេលក្រោយ", "my_MM": "နောက်မှသတိပေး"},
    "我知道了": {"zh_CN": "我知道了", "zh_TW": "我知道了", "ru_RU": "Понятно", "fa_IR": "فهمیدم", "vi_VN": "Tôi hiểu", "km_KH": "ខ្ញុំយល់ហើយ", "my_MM": "နားလည်ပါပြီ"},
    "立即更新": {"zh_CN": "立即更新", "zh_TW": "立即更新", "ru_RU": "Обновить сейчас", "fa_IR": "الان به‌روزرسانی کن", "vi_VN": "Cập nhật ngay", "km_KH": "ធ្វើបច្ចុប្បន្នភាពឥឡូវ", "my_MM": "ယခုအပ်ဒိတ်လုပ်"},
    "确定": {"zh_CN": "确定", "zh_TW": "確定", "ru_RU": "ОК", "fa_IR": "تایید", "vi_VN": "Xác nhận", "km_KH": "យល់ព្រម", "my_MM": "အိုကေ"},
    "授权过期": {"zh_CN": "授权过期", "zh_TW": "授權過期", "ru_RU": "Лицензия истекла", "fa_IR": "مجوز منقضی شده", "vi_VN": "Bản quyền hết hạn", "km_KH": "អាជ្ញាប័ណ្ណផុតកំណត់", "my_MM": "လိုင်စင်သက်တမ်းကုန်"},
    "设备超限": {"zh_CN": "设备超限", "zh_TW": "裝置超限", "ru_RU": "Превышено кол-во устройств", "fa_IR": "تعداد دستگاه بیش از حد مجاز", "vi_VN": "Vượt giới hạn thiết bị", "km_KH": "ឧបករណ៍លើសកំណត់", "my_MM": "စက်ကိရိယာအရေအတွက်ကျော်"},
    "更新提示": {"zh_CN": "更新提示", "zh_TW": "更新提示", "ru_RU": "Уведомление об обновлении", "fa_IR": "اعلان به‌روزرسانی", "vi_VN": "Thông báo cập nhật", "km_KH": "ការជូនដំណឹងអាប់ដេត", "my_MM": "အပ်ဒိတ်အကြောင်းကြား"},
    "群组": {"zh_CN": "群组", "zh_TW": "群組", "ru_RU": "Группа", "fa_IR": "گروه", "vi_VN": "Nhóm", "km_KH": "ក្រុម", "my_MM": "အုပ်စု"},
    "安全错误": {"zh_CN": "安全错误", "zh_TW": "安全錯誤", "ru_RU": "Ошибка безопасности", "fa_IR": "خطای امنیتی", "vi_VN": "Lỗi bảo mật", "km_KH": "កំហុorg សុវត្ថិភាព", "my_MM": "လုံခြုံရေးအမှား"},
}


def process_ts_file(input_file, output_file, lang_code, zh_cn_translations=None):
    """Process a .ts file and add translations"""

    tree = ET.parse(input_file)
    root = tree.getroot()

    translated = 0
    untranslated = 0

    for context in root.findall('context'):
        for message in context.findall('message'):
            source = message.find('source')
            translation = message.find('translation')

            if source is None or translation is None:
                continue

            source_text = source.text or ""
            current_translation = translation.text or ""

            # For English (en_US), the translation equals the source text
            if lang_code == 'en_US':
                if source_text:
                    translation.text = source_text
                    # Remove unfinished marker if present
                    if 'type' in translation.attrib:
                        del translation.attrib['type']
                    translated += 1
                else:
                    untranslated += 1
            # Check if translation exists in our dictionary
            elif source_text in TRANSLATIONS and lang_code in TRANSLATIONS[source_text]:
                new_translation = TRANSLATIONS[source_text][lang_code]
                translation.text = new_translation
                # Remove unfinished marker if present
                if 'type' in translation.attrib:
                    del translation.attrib['type']
                translated += 1
            # For zh_TW, fallback to converting zh_CN
            elif lang_code == 'zh_TW' and source_text in TRANSLATIONS and 'zh_CN' in TRANSLATIONS[source_text]:
                new_translation = s2t(TRANSLATIONS[source_text]['zh_CN'])
                translation.text = new_translation
                if 'type' in translation.attrib:
                    del translation.attrib['type']
                translated += 1
            # For zh_TW, also try to convert from zh_CN file translations
            elif lang_code == 'zh_TW' and zh_cn_translations and source_text in zh_cn_translations:
                new_translation = s2t(zh_cn_translations[source_text])
                translation.text = new_translation
                if 'type' in translation.attrib:
                    del translation.attrib['type']
                translated += 1
            elif current_translation and 'type' not in translation.attrib:
                # Keep existing good translation
                translated += 1
            else:
                untranslated += 1

    # Write output
    tree.write(output_file, encoding='utf-8', xml_declaration=True)

    # Add proper DOCTYPE
    with open(output_file, 'r', encoding='utf-8') as f:
        content = f.read()

    content = content.replace(
        '<?xml version=\'1.0\' encoding=\'utf-8\'?>',
        '<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>'
    )

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"{lang_code}: {translated} translated, {untranslated} remaining")


def extract_translations(ts_file):
    """Extract existing translations from a .ts file"""
    translations = {}
    tree = ET.parse(ts_file)
    root = tree.getroot()

    for context in root.findall('context'):
        for message in context.findall('message'):
            source = message.find('source')
            translation = message.find('translation')

            if source is None or translation is None:
                continue

            source_text = source.text or ""
            trans_text = translation.text or ""

            # Only include if it has a translation and is not unfinished
            if trans_text and 'type' not in translation.attrib:
                translations[source_text] = trans_text

    return translations


def main():
    # scripts/build/translate_ts.py -> scripts/build -> scripts -> JinGo (project root)
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    trans_dir = os.path.join(base_dir, 'resources', 'translations')

    # First process zh_CN
    zh_cn_file = os.path.join(trans_dir, 'jingo_zh_CN.ts')
    if os.path.exists(zh_cn_file):
        print("Processing zh_CN...")
        process_ts_file(zh_cn_file, zh_cn_file, 'zh_CN')
        # Extract zh_CN translations for zh_TW fallback
        zh_cn_translations = extract_translations(zh_cn_file)
    else:
        zh_cn_translations = {}
        print(f"File not found: {zh_cn_file}")

    # Process zh_TW with zh_CN fallback
    zh_tw_file = os.path.join(trans_dir, 'jingo_zh_TW.ts')
    if os.path.exists(zh_tw_file):
        print("Processing zh_TW...")
        process_ts_file(zh_tw_file, zh_tw_file, 'zh_TW', zh_cn_translations)
    else:
        print(f"File not found: {zh_tw_file}")

    # Process en_US (English - source text equals translation)
    en_us_file = os.path.join(trans_dir, 'jingo_en_US.ts')
    if os.path.exists(en_us_file):
        print("Processing en_US...")
        process_ts_file(en_us_file, en_us_file, 'en_US')
    else:
        print(f"File not found: {en_us_file}")

    # Process other languages
    for lang in ['ru_RU', 'fa_IR', 'vi_VN', 'km_KH', 'my_MM']:
        input_file = os.path.join(trans_dir, f'jingo_{lang}.ts')
        if os.path.exists(input_file):
            print(f"Processing {lang}...")
            process_ts_file(input_file, input_file, lang)
        else:
            print(f"File not found: {input_file}")


if __name__ == '__main__':
    main()
