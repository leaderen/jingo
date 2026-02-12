#!/usr/bin/env python3
"""Fill all missing translations across all languages"""
import xml.etree.ElementTree as ET
import os
import sys

# All missing translations organized by source text
TRANSLATIONS = {
    # === LoginViewModel ===
    "Enter new password": {
        "zh_CN": "输入新密码",
        "ru_RU": "Введите новый пароль",
        "fa_IR": "رمز عبور جدید را وارد کنید",
        "vi_VN": "Nhập mật khẩu mới",
        "km_KH": "បញ្ចូលពាក្យសម្ងាត់ថ្មី",
        "my_MM": "စကားဝှက်အသစ်ရိုက်ထည့်ပါ",
    },
    "Password reset successfully! Please login with new password.": {
        "zh_CN": "密码重置成功！请使用新密码登录。",
        "ru_RU": "Пароль успешно сброшен! Пожалуйста, войдите с новым паролем.",
        "fa_IR": "رمز عبور با موفقیت بازنشانی شد! لطفاً با رمز عبور جدید وارد شوید.",
        "vi_VN": "Đặt lại mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.",
        "km_KH": "កំណត់ពាក្យសម្ងាត់ឡើងវិញដោយជោគជ័យ! សូមចូលដោយប្រើពាក្យសម្ងាត់ថ្មី។",
        "my_MM": "စကားဝှက်ပြန်လည်သတ်မှတ်ခြင်းအောင်မြင်ပါပြီ! စကားဝှက်အသစ်ဖြင့်ဝင်ရောက်ပါ။",
    },
    # === SimpleBottomNavigationBar / SimpleConnectionPage / main ===
    "Dashboard": {
        "zh_CN": "仪表盘",
        "ru_RU": "Панель",
        "fa_IR": "داشبورد",
        "vi_VN": "Bảng điều khiển",
        "km_KH": "ផ្ទាំងគ្រប់គ្រង",
        "my_MM": "ဒက်ရှ်ဘုတ်",
    },
    "No Plan": {
        "zh_CN": "无套餐",
        "ru_RU": "Нет плана",
        "fa_IR": "بدون پلن",
        "vi_VN": "Không có gói",
        "km_KH": "គ្មានគម្រោង",
        "my_MM": "အစီအစဉ်မရှိပါ",
    },
    "Plan": {
        "zh_CN": "套餐",
        "ru_RU": "План",
        "fa_IR": "پلن",
        "vi_VN": "Gói",
        "km_KH": "គម្រោង",
        "my_MM": "အစီအစဉ်",
    },
    "Expires: %1": {
        "zh_CN": "到期：%1",
        "ru_RU": "Истекает: %1",
        "fa_IR": "انقضا: %1",
        "vi_VN": "Hết hạn: %1",
        "km_KH": "ផុតកំណត់: %1",
        "my_MM": "သက်တမ်းကုန်: %1",
    },
    "Traffic Used": {
        "zh_CN": "已用流量",
        "ru_RU": "Использовано трафика",
        "fa_IR": "ترافیک مصرفی",
        "vi_VN": "Lưu lượng đã dùng",
        "km_KH": "ចរាចរដែលបានប្រើ",
        "my_MM": "အသုံးပြုပြီးဒေတာ",
    },
    "%1% used": {
        "zh_CN": "已使用 %1%",
        "ru_RU": "Использовано %1%",
        "fa_IR": "%1% استفاده شده",
        "vi_VN": "Đã dùng %1%",
        "km_KH": "បានប្រើ %1%",
        "my_MM": "%1% အသုံးပြုပြီး",
    },
    "Tap to change server": {
        "zh_CN": "点击切换服务器",
        "ru_RU": "Нажмите для смены сервера",
        "fa_IR": "برای تغییر سرور ضربه بزنید",
        "vi_VN": "Nhấn để đổi máy chủ",
        "km_KH": "ចុចដើម្បីប្ដូរម៉ាស៊ីនមេ",
        "my_MM": "ဆာဗာပြောင်းရန် နှိပ်ပါ",
    },
    "Tap to select a server": {
        "zh_CN": "点击选择服务器",
        "ru_RU": "Нажмите для выбора сервера",
        "fa_IR": "برای انتخاب سرور ضربه بزنید",
        "vi_VN": "Nhấn để chọn máy chủ",
        "km_KH": "ចុចដើម្បីជ្រើសរើសម៉ាស៊ីនមេ",
        "my_MM": "ဆာဗာရွေးချယ်ရန် နှိပ်ပါ",
    },
    # === SimpleProfilePage ===
    "Subscription Overview": {
        "zh_CN": "订阅概览",
        "ru_RU": "Обзор подписки",
        "fa_IR": "نمای کلی اشتراک",
        "vi_VN": "Tổng quan đăng ký",
        "km_KH": "ទិដ្ឋភាពទូទៅនៃការជាវ",
        "my_MM": "စာရင်းသွင်းမှုအနှစ်ချုပ်",
    },
    "Inactive": {
        "zh_CN": "未激活",
        "ru_RU": "Неактивно",
        "fa_IR": "غیرفعال",
        "vi_VN": "Chưa kích hoạt",
        "km_KH": "មិនសកម្ម",
        "my_MM": "မဖွင့်ရသေး",
    },
    "Expiry Date": {
        "zh_CN": "到期日期",
        "ru_RU": "Дата истечения",
        "fa_IR": "تاریخ انقضا",
        "vi_VN": "Ngày hết hạn",
        "km_KH": "កាលបរិច្ឆេទផុតកំណត់",
        "my_MM": "သက်တမ်းကုန်ရက်",
    },
    "Used Traffic": {
        "zh_CN": "已用流量",
        "ru_RU": "Использованный трафик",
        "fa_IR": "ترافیک مصرف شده",
        "vi_VN": "Lưu lượng đã dùng",
        "km_KH": "ចរាចរដែលបានប្រើ",
        "my_MM": "အသုံးပြုပြီးဒေတာ",
    },
    "Expired": {
        "zh_CN": "已过期",
        "vi_VN": "Đã hết hạn",
        "km_KH": "ផុតកំណត់",
        "my_MM": "သက်တမ်းကုန်ပြီး",
    },
    " days": {
        "zh_CN": " 天",
        "ru_RU": " дн.",
        "fa_IR": " روز",
        "vi_VN": " ngày",
        "km_KH": " ថ្ងៃ",
        "my_MM": " ရက်",
    },
    # === SimpleStorePage / StorePage ===
    "Purchase successful!": {
        "zh_CN": "购买成功！",
        "ru_RU": "Покупка успешна!",
        "fa_IR": "خرید موفقیت‌آمیز!",
        "vi_VN": "Mua thành công!",
        "km_KH": "ការទិញជោគជ័យ!",
        "my_MM": "ဝယ်ယူမှုအောင်မြင်ပါပြီ!",
    },
    "Purchases restored successfully": {
        "zh_CN": "恢复购买成功",
        "ru_RU": "Покупки успешно восстановлены",
        "fa_IR": "خریدها با موفقیت بازیابی شدند",
        "vi_VN": "Khôi phục mua hàng thành công",
        "km_KH": "ស្ដារការទិញឡើងវិញដោយជោគជ័យ",
        "my_MM": "ဝယ်ယူမှုများပြန်လည်ရယူခြင်းအောင်မြင်ပါပြီ",
    },
    "No purchases to restore": {
        "zh_CN": "没有可恢复的购买",
        "ru_RU": "Нет покупок для восстановления",
        "fa_IR": "خریدی برای بازیابی وجود ندارد",
        "vi_VN": "Không có giao dịch mua để khôi phục",
        "km_KH": "គ្មានការទិញដើម្បីស្ដារឡើងវិញ",
        "my_MM": "ပြန်လည်ရယူရန်ဝယ်ယူမှုမရှိပါ",
    },
    "Restore failed: ": {
        "zh_CN": "恢复失败：",
        "ru_RU": "Ошибка восстановления: ",
        "fa_IR": "خطا در بازیابی: ",
        "vi_VN": "Khôi phục thất bại: ",
        "km_KH": "ការស្ដារឡើងវិញបរាជ័យ: ",
        "my_MM": "ပြန်လည်ရယူခြင်းမအောင်မြင်ပါ: ",
    },
    "Plan #": {
        "zh_CN": "套餐 #",
        "ru_RU": "План #",
        "fa_IR": "پلن #",
        "vi_VN": "Gói #",
        "km_KH": "គម្រោង #",
        "my_MM": "အစီအစဉ် #",
    },
    "IAP not available": {
        "zh_CN": "应用内购买不可用",
        "ru_RU": "Покупки в приложении недоступны",
        "fa_IR": "خرید درون‌برنامه‌ای در دسترس نیست",
        "vi_VN": "Mua hàng trong ứng dụng không khả dụng",
        "km_KH": "ការទិញក្នុងកម្មវិធីមិនអាចប្រើបាន",
        "my_MM": "အက်ပ်အတွင်းဝယ်ယူမှုမရရှိနိုင်ပါ",
    },
    "No matching IAP product for this plan": {
        "zh_CN": "此套餐没有匹配的应用内购买产品",
        "ru_RU": "Нет подходящего продукта для этого плана",
        "fa_IR": "محصول مطابقی برای این پلن وجود ندارد",
        "vi_VN": "Không có sản phẩm IAP phù hợp cho gói này",
        "km_KH": "គ្មានផលិតផល IAP ដែលត្រូវគ្នាសម្រាប់គម្រោងនេះ",
        "my_MM": "ဤအစီအစဉ်အတွက် IAP ထုတ်ကုန်မတွေ့ပါ",
    },
    "No subscription options available": {
        "zh_CN": "没有可用的订阅选项",
        "ru_RU": "Нет доступных вариантов подписки",
        "fa_IR": "گزینه اشتراکی در دسترس نیست",
        "vi_VN": "Không có tùy chọn đăng ký",
        "km_KH": "គ្មានជម្រើសការជាវដែលអាចប្រើបាន",
        "my_MM": "စာရင်းသွင်းမှုရွေးချယ်စရာမရှိပါ",
    },
    "No Subscription": {
        "zh_CN": "无订阅",
        "ru_RU": "Нет подписки",
        "fa_IR": "بدون اشتراک",
        "vi_VN": "Không có đăng ký",
        "km_KH": "គ្មានការជាវ",
        "my_MM": "စာရင်းသွင်းမှုမရှိပါ",
    },
    "Restore Purchases": {
        "zh_CN": "恢复购买",
        "ru_RU": "Восстановить покупки",
        "fa_IR": "بازیابی خریدها",
        "vi_VN": "Khôi phục mua hàng",
        "km_KH": "ស្ដារការទិញឡើងវិញ",
        "my_MM": "ဝယ်ယူမှုများပြန်လည်ရယူရန်",
    },
    "No Available Plans": {
        "zh_CN": "没有可用套餐",
        "ru_RU": "Нет доступных планов",
        "fa_IR": "پلنی در دسترس نیست",
        "vi_VN": "Không có gói khả dụng",
        "km_KH": "គ្មានគម្រោងដែលអាចប្រើបាន",
        "my_MM": "ရရှိနိုင်သောအစီအစဉ်မရှိပါ",
    },
    "Loading Plans...": {
        "zh_CN": "加载套餐中...",
        "ru_RU": "Загрузка планов...",
        "fa_IR": "در حال بارگذاری پلن‌ها...",
        "vi_VN": "Đang tải gói...",
        "km_KH": "កំពុងផ្ទុកគម្រោង...",
        "my_MM": "အစီအစဉ်များဖတ်နေသည်...",
    },
    "This period is not available for in-app purchase": {
        "zh_CN": "此周期不支持应用内购买",
        "ru_RU": "Этот период недоступен для покупки в приложении",
        "fa_IR": "این دوره برای خرید درون‌برنامه‌ای در دسترس نیست",
        "vi_VN": "Kỳ hạn này không khả dụng cho mua hàng trong ứng dụng",
        "km_KH": "រយៈពេលនេះមិនអាចទិញក្នុងកម្មវិធីបានទេ",
        "my_MM": "ဤကာလသည် အက်ပ်အတွင်းဝယ်ယူမှုအတွက်မရနိုင်ပါ",
    },
    "Billed monthly": {
        "vi_VN": "Thanh toán hàng tháng",
        "km_KH": "បង់ប្រចាំខែ",
        "my_MM": "လစဉ်ငွေတောင်းခံသည်",
    },
    "Billed every 3 months": {
        "vi_VN": "Thanh toán mỗi 3 tháng",
        "km_KH": "បង់រៀងរាល់ ៣ ខែ",
        "my_MM": "၃ လတစ်ကြိမ်ငွေတောင်းခံသည်",
    },
    "Billed every 6 months": {
        "vi_VN": "Thanh toán mỗi 6 tháng",
        "km_KH": "បង់រៀងរាល់ ៦ ខែ",
        "my_MM": "၆ လတစ်ကြိမ်ငွေတောင်းခံသည်",
    },
    "Yearly": {
        "vi_VN": "Hàng năm",
        "km_KH": "ប្រចាំឆ្នាំ",
        "my_MM": "နှစ်စဉ်",
    },
    "Billed annually - Best value!": {
        "vi_VN": "Thanh toán hàng năm - Giá trị tốt nhất!",
        "km_KH": "បង់ប្រចាំឆ្នាំ - តម្លៃល្អបំផុត!",
        "my_MM": "နှစ်စဉ်ငွေတောင်းခံသည် - အတန်ဆုံး!",
    },
    "Billed every 2 years": {
        "vi_VN": "Thanh toán mỗi 2 năm",
        "km_KH": "បង់រៀងរាល់ ២ ឆ្នាំ",
        "my_MM": "၂ နှစ်တစ်ကြိမ်ငွေတောင်းခံသည်",
    },
    "Billed every 3 years": {
        "vi_VN": "Thanh toán mỗi 3 năm",
        "km_KH": "បង់រៀងរាល់ ៣ ឆ្នាំ",
        "my_MM": "၃ နှစ်တစ်ကြိမ်ငွေတောင်းခံသည်",
    },
    "One-time payment, no renewal": {
        "vi_VN": "Thanh toán một lần, không gia hạn",
        "km_KH": "បង់ម្ដងគ្មានការបន្ត",
        "my_MM": "တစ်ကြိမ်ငွေပေးချေမှု၊ သက်တမ်းတိုးမလို",
    },
    "Unnamed Plan": {
        "vi_VN": "Gói chưa đặt tên",
        "km_KH": "គម្រោងគ្មានឈ្មោះ",
        "my_MM": "အမည်မရှိအစီအစဉ်",
    },
    "Exp: %1": {
        "vi_VN": "HH: %1",
        "km_KH": "ផុតកំណត់: %1",
        "my_MM": "ကုန်: %1",
    },
    "Rem: %1": {
        "vi_VN": "Còn: %1",
        "km_KH": "នៅសល់: %1",
        "my_MM": "ကျန်: %1",
    },
    "Select Plan": {
        "vi_VN": "Chọn gói",
        "km_KH": "ជ្រើសរើសគម្រោង",
        "my_MM": "အစီအစဉ်ရွေးချယ်ရန်",
    },
    "Month": {
        "vi_VN": "Tháng",
        "km_KH": "ខែ",
        "my_MM": "လ",
    },
    # === main ===
    "Switch to Professional Mode": {
        "zh_CN": "切换到专业模式",
        "ru_RU": "Профессиональный режим",
        "fa_IR": "تغییر به حالت حرفه‌ای",
        "vi_VN": "Chuyển sang chế độ chuyên nghiệp",
        "km_KH": "ប្ដូរទៅរបៀបជំនាញ",
        "my_MM": "ပရော်ဖက်ရှင်နယ်မုဒ်သို့ပြောင်းရန်",
    },
    "Switch to Simple Mode": {
        "zh_CN": "切换到简洁模式",
        "ru_RU": "Простой режим",
        "fa_IR": "تغییر به حالت ساده",
        "vi_VN": "Chuyển sang chế độ đơn giản",
        "km_KH": "ប្ដូរទៅរបៀបសាមញ្ញ",
        "my_MM": "ရိုးရှင်းမုဒ်သို့ပြောင်းရန်",
    },
    "JinGo": {
        "zh_CN": "JinGo", "ru_RU": "JinGo", "fa_IR": "JinGo",
        "vi_VN": "JinGo", "km_KH": "JinGo", "my_MM": "JinGo",
    },
    # === RegisterForm ===
    "Invite Code": {
        "ru_RU": "Код приглашения",
        "fa_IR": "کد دعوت",
        "vi_VN": "Mã mời",
        "km_KH": "កូដអញ្ជើញ",
        "my_MM": "ဖိတ်ခေါ်ကုဒ်",
    },
    "Enter invite code": {
        "ru_RU": "Введите код приглашения",
        "fa_IR": "کد دعوت را وارد کنید",
        "vi_VN": "Nhập mã mời",
        "km_KH": "បញ្ចូលកូដអញ្ជើញ",
        "my_MM": "ဖိတ်ခေါ်ကုဒ်ရိုက်ထည့်ပါ",
    },
    "I agree to the": {
        "ru_RU": "Я согласен с",
        "fa_IR": "من موافقم با",
        "vi_VN": "Tôi đồng ý với",
        "km_KH": "ខ្ញុំយល់ព្រមជាមួយ",
        "my_MM": "ကျွန်ုပ်သဘောတူပါသည်",
    },
    "I'm not a robot": {
        "ru_RU": "Я не робот",
        "fa_IR": "من ربات نیستم",
        "vi_VN": "Tôi không phải robot",
        "km_KH": "ខ្ញុំមិនមែនជារ៉ូបូទេ",
        "my_MM": "ကျွန်ုပ်ရိုဘော့မဟုတ်ပါ",
    },
    "Registration Successful": {
        "ru_RU": "Регистрация успешна",
        "fa_IR": "ثبت‌نام موفقیت‌آمیز",
        "vi_VN": "Đăng ký thành công",
        "km_KH": "ការចុះឈ្មោះជោគជ័យ",
        "my_MM": "စာရင်းသွင်းခြင်းအောင်မြင်ပါပြီ",
    },
    "Enter email address": {
        "vi_VN": "Nhập địa chỉ email",
        "km_KH": "បញ្ចូលអាសយដ្ឋានអ៊ីមែល",
        "my_MM": "အီးမေးလ်လိပ်စာရိုက်ထည့်ပါ",
    },
    "Enter password (min 6 chars)": {
        "vi_VN": "Nhập mật khẩu (tối thiểu 6 ký tự)",
        "km_KH": "បញ្ចូលពាក្យសម្ងាត់ (យ៉ាងហោចណាស់ ៦ តួអក្សរ)",
        "my_MM": "စကားဝှက်ရိုက်ထည့်ပါ (အနည်းဆုံး ၆ လုံး)",
    },
    "Signing up...": {
        "vi_VN": "Đang đăng ký...",
        "km_KH": "កំពុងចុះឈ្មោះ...",
        "my_MM": "စာရင်းသွင်းနေသည်...",
    },
    # === SettingsPage ===
    "Settings reset to default": {
        "ru_RU": "Настройки сброшены по умолчанию",
        "fa_IR": "تنظیمات به حالت پیش‌فرض بازنشانی شد",
        "vi_VN": "Đã đặt lại cài đặt về mặc định",
        "km_KH": "កំណត់ការកំណត់ឡើងវិញទៅលំនាំដើម",
        "my_MM": "ဆက်တင်များကို မူလအတိုင်းပြန်ထားပြီးပါပြီ",
    },
    "TCP ping, fast": {
        "ru_RU": "TCP пинг, быстрый",
        "fa_IR": "پینگ TCP، سریع",
        "vi_VN": "TCP ping, nhanh",
        "km_KH": "TCP ping, លឿន",
        "my_MM": "TCP ping, မြန်",
    },
    "HTTP ping, accurate": {
        "ru_RU": "HTTP пинг, точный",
        "fa_IR": "پینگ HTTP، دقیق",
        "vi_VN": "HTTP ping, chính xác",
        "km_KH": "HTTP ping, ត្រឹមត្រូវ",
        "my_MM": "HTTP ping, တိကျ",
    },
    "Per-App Proxy": {
        "fa_IR": "پراکسی هر برنامه",
        "vi_VN": "Proxy theo ứng dụng",
        "km_KH": "ប្រូកស៊ីតាមកម្មវិធី",
        "my_MM": "အက်ပ်အလိုက်ပရောက်စီ",
    },
    "Control which apps use VPN": {
        "fa_IR": "کنترل برنامه‌هایی که از VPN استفاده می‌کنند",
        "vi_VN": "Kiểm soát ứng dụng nào sử dụng VPN",
        "km_KH": "គ្រប់គ្រងកម្មវិធីណាដែលប្រើ VPN",
        "my_MM": "VPN သုံးမည့်အက်ပ်များကိုထိန်းချုပ်ရန်",
    },
    "TUN mode only": {
        "fa_IR": "فقط حالت TUN",
        "vi_VN": "Chỉ chế độ TUN",
        "km_KH": "របៀប TUN តែប៉ុណ្ណោះ",
        "my_MM": "TUN မုဒ်သာ",
    },
    "Per-App Proxy Mode": {
        "fa_IR": "حالت پراکسی هر برنامه",
        "vi_VN": "Chế độ Proxy theo ứng dụng",
        "km_KH": "របៀបប្រូកស៊ីតាមកម្មវិធី",
        "my_MM": "အက်ပ်အလိုက်ပရောက်စီမုဒ်",
    },
    "Disabled: All apps use VPN": {
        "fa_IR": "غیرفعال: همه برنامه‌ها از VPN استفاده می‌کنند",
        "vi_VN": "Tắt: Tất cả ứng dụng sử dụng VPN",
        "km_KH": "បិទ: កម្មវិធីទាំងអស់ប្រើ VPN",
        "my_MM": "ပိတ်ထားသည်: အက်ပ်အားလုံး VPN သုံးမည်",
    },
    "Allow List: Only selected apps use VPN": {
        "fa_IR": "لیست مجاز: فقط برنامه‌های انتخاب‌شده از VPN استفاده کنند",
        "vi_VN": "Danh sách cho phép: Chỉ ứng dụng được chọn sử dụng VPN",
        "km_KH": "បញ្ជីអនុញ្ញាត: មានតែកម្មវិធីដែលបានជ្រើសរើសប្រើ VPN",
        "my_MM": "ခွင့်ပြုစာရင်း: ရွေးချယ်ထားသောအက်ပ်များသာ VPN သုံးမည်",
    },
    "Block List: Selected apps bypass VPN": {
        "fa_IR": "لیست مسدود: برنامه‌های انتخاب‌شده از VPN عبور کنند",
        "vi_VN": "Danh sách chặn: Ứng dụng được chọn bỏ qua VPN",
        "km_KH": "បញ្ជីទប់ស្កាត់: កម្មវិធីដែលបានជ្រើសរើសរំលង VPN",
        "my_MM": "ပိတ်ဆို့စာရင်း: ရွေးချယ်ထားသောအက်ပ်များ VPN ကိုကျော်ဖြတ်မည်",
    },
    "Allow List": {
        "fa_IR": "لیست مجاز",
        "vi_VN": "Danh sách cho phép",
        "km_KH": "បញ្ជីអនុញ្ញាត",
        "my_MM": "ခွင့်ပြုစာရင်း",
    },
    "Block List": {
        "fa_IR": "لیست مسدود",
        "vi_VN": "Danh sách chặn",
        "km_KH": "បញ្ជីទប់ស្កាត់",
        "my_MM": "ပိတ်ဆို့စာရင်း",
    },
    "Selected Apps": {
        "fa_IR": "برنامه‌های انتخاب‌شده",
        "vi_VN": "Ứng dụng đã chọn",
        "km_KH": "កម្មវិធីដែលបានជ្រើសរើស",
        "my_MM": "ရွေးချယ်ထားသောအက်ပ်များ",
    },
    "%1 app(s) selected": {
        "fa_IR": "%1 برنامه انتخاب شده",
        "vi_VN": "Đã chọn %1 ứng dụng",
        "km_KH": "បានជ្រើសរើស %1 កម្មវិធី",
        "my_MM": "အက်ပ် %1 ခုရွေးချယ်ထားသည်",
    },
    "Clear Selection": {
        "fa_IR": "پاک کردن انتخاب",
        "vi_VN": "Xóa lựa chọn",
        "km_KH": "សម្អាតការជ្រើសរើស",
        "my_MM": "ရွေးချယ်မှုရှင်းရန်",
    },
    "Remove all apps from the list": {
        "fa_IR": "حذف همه برنامه‌ها از لیست",
        "vi_VN": "Xóa tất cả ứng dụng khỏi danh sách",
        "km_KH": "លុបកម្មវិធីទាំងអស់ចេញពីបញ្ជី",
        "my_MM": "စာရင်းမှအက်ပ်အားလုံးဖယ်ရှားရန်",
    },
    "GeneralSettings": {
        "vi_VN": "Cài đặt chung",
        "km_KH": "ការកំណត់ទូទៅ",
        "my_MM": "အထွေထွေဆက်တင်များ",
    },
    "Application Basic Configuration": {
        "vi_VN": "Cấu hình cơ bản ứng dụng",
        "km_KH": "ការកំណត់រចនាសម្ព័ន្ធមូលដ្ឋានកម្មវិធី",
        "my_MM": "အက်ပ်အခြေခံဖွဲ့စည်းမှု",
    },
    "Start at Login": {
        "vi_VN": "Khởi động cùng hệ thống",
        "km_KH": "ចាប់ផ្ដើមនៅពេលចូល",
        "my_MM": "ဝင်ရောက်သည့်အခါစတင်ရန်",
    },
    "Launch at system startup": {
        "vi_VN": "Khởi chạy khi hệ thống khởi động",
        "km_KH": "ចាប់ផ្ដើមនៅពេលប្រព័ន្ធចាប់ផ្ដើម",
        "my_MM": "စနစ်စတင်သည့်အခါဖွင့်ရန်",
    },
    "Connect on Demand": {
        "vi_VN": "Kết nối theo yêu cầu",
        "km_KH": "ភ្ជាប់តាមតម្រូវការ",
        "my_MM": "လိုအပ်သည့်အခါချိတ်ဆက်ရန်",
    },
    "Auto-connect on startup": {
        "vi_VN": "Tự kết nối khi khởi động",
        "km_KH": "ភ្ជាប់ដោយស្វ័យប្រវត្តិនៅពេលចាប់ផ្ដើម",
        "my_MM": "စတင်သည့်အခါအလိုအလျောက်ချိတ်ဆက်ရန်",
    },
    "Automatically connect VPN when network changes": {
        "vi_VN": "Tự động kết nối VPN khi mạng thay đổi",
        "km_KH": "ភ្ជាប់ VPN ដោយស្វ័យប្រវត្តិនៅពេលបណ្ដាញផ្លាស់ប្ដូរ",
        "my_MM": "ကွန်ရက်ပြောင်းလဲသည့်အခါ VPN အလိုအလျောက်ချိတ်ဆက်ရန်",
    },
    "Automatically connect to last used server on startup": {
        "vi_VN": "Tự động kết nối đến máy chủ gần nhất khi khởi động",
        "km_KH": "ភ្ជាប់ទៅម៉ាស៊ីនមេដែលបានប្រើចុងក្រោយដោយស្វ័យប្រវត្តិ",
        "my_MM": "စတင်သည့်အခါနောက်ဆုံးသုံးခဲ့သောဆာဗာသို့အလိုအလျောက်ချိတ်ဆက်ရန်",
    },
    "Minimize to System Tray": {
        "vi_VN": "Thu nhỏ vào khay hệ thống",
        "km_KH": "បង្រួមទៅថាសប្រព័ន្ធ",
        "my_MM": "စနစ်ထရေးသို့ချုံ့ရန်",
    },
    "Minimize to system tray instead of quit when closing window": {
        "vi_VN": "Thu nhỏ vào khay hệ thống thay vì thoát khi đóng cửa sổ",
        "km_KH": "បង្រួមទៅថាសប្រព័ន្ធជំនួសឱ្យការចាកចេញនៅពេលបិទបង្អួច",
        "my_MM": "ဝင်းဒိုးပိတ်သည့်အခါ ထွက်မည့်အစား စနစ်ထရေးသို့ချုံ့ရန်",
    },
    "Select app display language": {
        "vi_VN": "Chọn ngôn ngữ hiển thị",
        "km_KH": "ជ្រើសរើសភាសាបង្ហាញកម្មវិធី",
        "my_MM": "အက်ပ်ပြသမည့်ဘာသာစကားရွေးချယ်ပါ",
    },
    "Select app theme style": {
        "vi_VN": "Chọn kiểu giao diện",
        "km_KH": "ជ្រើសរើសរចនាប័ទ្មស្បែកកម្មវិធី",
        "my_MM": "အက်ပ်အပြင်အဆင်ပုံစံရွေးချယ်ပါ",
    },
    "Bypass Countries": {
        "vi_VN": "Quốc gia bỏ qua",
        "km_KH": "ប្រទេសដែលរំលង",
        "my_MM": "ကျော်ဖြတ်မည့်နိုင်ငံများ",
    },
    "Select countries to bypass, their websites will connect directly": {
        "vi_VN": "Chọn quốc gia để bỏ qua, trang web của họ sẽ kết nối trực tiếp",
        "km_KH": "ជ្រើសរើសប្រទេសដើម្បីរំលង គេហទំព័ររបស់ពួកគេនឹងភ្ជាប់ដោយផ្ទាល់",
        "my_MM": "ကျော်ဖြတ်ရန်နိုင်ငံများရွေးချယ်ပါ၊ ၎င်းတို့၏ဝဘ်ဆိုက်များတိုက်ရိုက်ချိတ်ဆက်မည်",
    },
    "Overseas DNS 1": {
        "vi_VN": "DNS nước ngoài 1",
        "km_KH": "DNS ក្រៅប្រទេស 1",
        "my_MM": "ပြည်ပ DNS 1",
    },
    "Overseas DNS 2": {
        "vi_VN": "DNS nước ngoài 2",
        "km_KH": "DNS ក្រៅប្រទេស 2",
        "my_MM": "ပြည်ပ DNS 2",
    },
    "DNS Query Strategy": {
        "vi_VN": "Chiến lược truy vấn DNS",
        "km_KH": "យុទ្ធសាស្ត្រសំណួរ DNS",
        "my_MM": "DNS မေးမြန်းမှုနည်းဗျူဟာ",
    },
    "IPv4/IPv6 Query Strategy": {
        "vi_VN": "Chiến lược truy vấn IPv4/IPv6",
        "km_KH": "យុទ្ធសាស្ត្រសំណួរ IPv4/IPv6",
        "my_MM": "IPv4/IPv6 မေးမြန်းမှုနည်းဗျူဟာ",
    },
    "Local Proxy": {
        "vi_VN": "Proxy cục bộ",
        "km_KH": "ប្រូកស៊ីមូលដ្ឋាន",
        "my_MM": "ပြည်တွင်းပရောက်စီ",
    },
    "Local SOCKS/HTTP proxy server settings": {
        "vi_VN": "Cài đặt máy chủ proxy SOCKS/HTTP cục bộ",
        "km_KH": "ការកំណត់ម៉ាស៊ីនមេប្រូកស៊ី SOCKS/HTTP មូលដ្ឋាន",
        "my_MM": "ပြည်တွင်း SOCKS/HTTP ပရောက်စီဆာဗာဆက်တင်များ",
    },
    "SOCKS Proxy Port": {
        "vi_VN": "Cổng Proxy SOCKS",
        "km_KH": "ច្រកប្រូកស៊ី SOCKS",
        "my_MM": "SOCKS ပရောက်စီပို့တ်",
    },
    "Local SOCKS5 proxy listen port - requires reconnecting after modification": {
        "vi_VN": "Cổng lắng nghe proxy SOCKS5 - cần kết nối lại sau khi thay đổi",
        "km_KH": "ច្រកស្ដាប់ប្រូកស៊ី SOCKS5 - ត្រូវភ្ជាប់ឡើងវិញបន្ទាប់ពីកែប្រែ",
        "my_MM": "SOCKS5 ပရောက်စီနားထောင်ပို့တ် - ပြင်ပြီးနောက်ပြန်ချိတ်ဆက်ရန်လိုအပ်",
    },
    "HTTP Proxy Port": {
        "vi_VN": "Cổng Proxy HTTP",
        "km_KH": "ច្រកប្រូកស៊ី HTTP",
        "my_MM": "HTTP ပရောက်စီပို့တ်",
    },
    "Local HTTP proxy listen port - requires reconnecting after modification": {
        "vi_VN": "Cổng lắng nghe proxy HTTP - cần kết nối lại sau khi thay đổi",
        "km_KH": "ច្រកស្ដាប់ប្រូកស៊ី HTTP - ត្រូវភ្ជាប់ឡើងវិញបន្ទាប់ពីកែប្រែ",
        "my_MM": "HTTP ပရောက်စီနားထောင်ပို့တ် - ပြင်ပြီးနောက်ပြန်ချိတ်ဆက်ရန်လိုအပ်",
    },
    "Allow LAN Connections": {
        "vi_VN": "Cho phép kết nối LAN",
        "km_KH": "អនុញ្ញាតការភ្ជាប់ LAN",
        "my_MM": "LAN ချိတ်ဆက်မှုများခွင့်ပြုရန်",
    },
    "Allow other devices in LAN to connect to this proxy": {
        "vi_VN": "Cho phép các thiết bị khác trong LAN kết nối đến proxy này",
        "km_KH": "អនុញ្ញាតឱ្យឧបករណ៍ផ្សេងក្នុង LAN ភ្ជាប់ទៅប្រូកស៊ីនេះ",
        "my_MM": "LAN ရှိအခြားစက်များဤပရောက်စီသို့ချိတ်ဆက်ခွင့်ပြုရန်",
    },
    "Transport Layer Settings": {
        "vi_VN": "Cài đặt tầng vận chuyển",
        "km_KH": "ការកំណត់ស្រទាប់ដឹកជញ្ជូន",
        "my_MM": "ပို့ဆောင်ရေးအလွှာဆက်တင်များ",
    },
    "Protocol transport related configuration": {
        "vi_VN": "Cấu hình liên quan đến vận chuyển giao thức",
        "km_KH": "ការកំណត់ទាក់ទងនឹងការដឹកជញ្ជូនពិធីការ",
        "my_MM": "ပရိုတိုကောပို့ဆောင်ရေးဆိုင်ရာဖွဲ့စည်းမှု",
    },
    "Enable Mux multiplexing": {
        "vi_VN": "Bật ghép kênh Mux",
        "km_KH": "បើក Mux multiplexing",
        "my_MM": "Mux multiplexing ဖွင့်ရန်",
    },
    "Transfer multiple data streams through single connection, may reduce latency": {
        "vi_VN": "Truyền nhiều luồng dữ liệu qua một kết nối, có thể giảm độ trễ",
        "km_KH": "ផ្ទេរស្ទ្រីមទិន្នន័យច្រើនតាមការភ្ជាប់តែមួយ អាចកាត់បន្ថយភាពយឺត",
        "my_MM": "ချိတ်ဆက်မှုတစ်ခုမှတဆင့်ဒေတာစီးကြောင်းများပို့ရန်၊ လေတင်စီကျဆင်းနိုင်သည်",
    },
    "Mux concurrent connections": {
        "vi_VN": "Kết nối đồng thời Mux",
        "km_KH": "ការភ្ជាប់ Mux ក្នុងពេលតែមួយ",
        "my_MM": "Mux တစ်ပြိုင်နက်ချိတ်ဆက်မှုများ",
    },
    "Maximum concurrent multiplexed connections": {
        "vi_VN": "Số kết nối ghép kênh đồng thời tối đa",
        "km_KH": "ចំនួនអតិបរមានៃការភ្ជាប់ក្នុងពេលតែមួយ",
        "my_MM": "အများဆုံးတစ်ပြိုင်နက်ချိတ်ဆက်မှုများ",
    },
    "TCP Fast Open": {
        "vi_VN": "TCP Fast Open", "km_KH": "TCP Fast Open", "my_MM": "TCP Fast Open",
    },
    "Enable TFO to reduce latency (requires system support)": {
        "vi_VN": "Bật TFO để giảm độ trễ (yêu cầu hệ thống hỗ trợ)",
        "km_KH": "បើក TFO ដើម្បីកាត់បន្ថយភាពយឺត (ត្រូវការការគាំទ្រប្រព័ន្ធ)",
        "my_MM": "လေတင်စီကျဆင်းစေရန် TFO ဖွင့်ပါ (စနစ်ပံ့ပိုးမှုလိုအပ်)",
    },
    "Enable traffic sniffing": {
        "vi_VN": "Bật phát hiện lưu lượng",
        "km_KH": "បើកការត្រួតពិនិត្យចរាចរ",
        "my_MM": "ဒေတာအသွားအလာစစ်ဆေးခြင်းဖွင့်ရန်",
    },
    "Auto identify traffic type for routing": {
        "vi_VN": "Tự động nhận dạng loại lưu lượng để định tuyến",
        "km_KH": "កំណត់ប្រភេទចរាចរដោយស្វ័យប្រវត្តិសម្រាប់ការដឹកនាំ",
        "my_MM": "လမ်းကြောင်းသတ်မှတ်ရန်ဒေတာအမျိုးအစားအလိုအလျောက်ခွဲခြားရန်",
    },
    "Log Settings": {
        "vi_VN": "Cài đặt nhật ký",
        "km_KH": "ការកំណត់កំណត់ត្រា",
        "my_MM": "မှတ်တမ်းဆက်တင်များ",
    },
    "Application and core log configuration": {
        "vi_VN": "Cấu hình nhật ký ứng dụng và lõi",
        "km_KH": "ការកំណត់កំណត់ត្រាកម្មវិធីនិងស្នូល",
        "my_MM": "အက်ပ်နှင့်အဓိကမှတ်တမ်းဖွဲ့စည်းမှု",
    },
    "Log Level": {
        "vi_VN": "Mức nhật ký",
        "km_KH": "កម្រិតកំណត់ត្រា",
        "my_MM": "မှတ်တမ်းအဆင့်",
    },
    "Set log verbosity level": {
        "vi_VN": "Đặt mức chi tiết nhật ký",
        "km_KH": "កំណត់កម្រិតលម្អិតនៃកំណត់ត្រា",
        "my_MM": "မှတ်တမ်းအသေးစိတ်အဆင့်သတ်မှတ်ရန်",
    },
    "Enable access log": {
        "vi_VN": "Bật nhật ký truy cập",
        "km_KH": "បើកកំណត់ត្រាចូលប្រើប្រាស់",
        "my_MM": "ဝင်ရောက်မှုမှတ်တမ်းဖွင့်ရန်",
    },
    "Log all connection requests": {
        "vi_VN": "Ghi lại tất cả yêu cầu kết nối",
        "km_KH": "កត់ត្រាសំណើភ្ជាប់ទាំងអស់",
        "my_MM": "ချိတ်ဆက်မှုတောင်းဆိုမှုအားလုံးမှတ်တမ်းတင်ရန်",
    },
    "Log retention days": {
        "vi_VN": "Số ngày lưu nhật ký",
        "km_KH": "ថ្ងៃរក្សាទុកកំណត់ត្រា",
        "my_MM": "မှတ်တမ်းသိမ်းဆည်းရက်",
    },
    "Documentation": {
        "vi_VN": "Tài liệu",
        "km_KH": "ឯកសារ",
        "my_MM": "စာရွက်စာတမ်း",
    },
    "ConnectTimeout": {
        "vi_VN": "Thời gian chờ kết nối",
        "km_KH": "អស់ពេលភ្ជាប់",
        "my_MM": "ချိတ်ဆက်မှုအချိန်ကုန်",
    },
    "Connection establishment timeout": {
        "vi_VN": "Thời gian chờ thiết lập kết nối",
        "km_KH": "អស់ពេលបង្កើតការភ្ជាប់",
        "my_MM": "ချိတ်ဆက်မှုတည်ဆောက်ခြင်းအချိန်ကုန်",
    },
    "Test Timeout": {
        "vi_VN": "Thời gian chờ kiểm tra",
        "km_KH": "អស់ពេលតេស្ត",
        "my_MM": "စမ်းသပ်ခြင်းအချိန်ကုန်",
    },
    "Server latency test timeout duration": {
        "vi_VN": "Thời gian chờ kiểm tra độ trễ máy chủ",
        "km_KH": "រយៈពេលអស់ពេលធ្វើតេស្តភាពយឺតម៉ាស៊ីនមេ",
        "my_MM": "ဆာဗာလေတင်စီစမ်းသပ်ခြင်းအချိန်ကုန်ကြာချိန်",
    },
    "Account management and data operations": {
        "vi_VN": "Quản lý tài khoản và thao tác dữ liệu",
        "km_KH": "ការគ្រប់គ្រងគណនីនិងប្រតិបត្តិការទិន្នន័យ",
        "my_MM": "အကောင့်စီမံခန့်ခွဲမှုနှင့်ဒေတာလုပ်ဆောင်ချက်များ",
    },
    "Reset all settings": {
        "vi_VN": "Đặt lại tất cả cài đặt",
        "km_KH": "កំណត់ការកំណត់ទាំងអស់ឡើងវិញ",
        "my_MM": "ဆက်တင်အားလုံးပြန်လည်သတ်မှတ်ရန်",
    },
    "Restore default settings (does not affect account data)": {
        "vi_VN": "Khôi phục cài đặt mặc định (không ảnh hưởng dữ liệu tài khoản)",
        "km_KH": "ស្ដារការកំណត់លំនាំដើម (មិនប៉ះពាល់ទិន្នន័យគណនី)",
        "my_MM": "မူလဆက်တင်များပြန်ထားရန် (အကောင့်ဒေတာအပေါ်သက်ရောက်မှုမရှိ)",
    },
    "Network test": {
        "vi_VN": "Kiểm tra mạng",
        "km_KH": "ធ្វើតេស្តបណ្ដាញ",
        "my_MM": "ကွန်ရက်စမ်းသပ်ခြင်း",
    },
    "Latency Test Method": {
        "vi_VN": "Phương pháp kiểm tra độ trễ",
        "km_KH": "វិធីសាស្ត្រធ្វើតេស្តភាពយឺត",
        "my_MM": "လေတင်စီစမ်းသပ်နည်း",
    },
    "Speed Test File Size": {
        "vi_VN": "Kích thước file kiểm tra tốc độ",
        "km_KH": "ទំហំឯកសារធ្វើតេស្តល្បឿន",
        "my_MM": "အမြန်နှုန်းစမ်းသပ်ဖိုင်အရွယ်အစား",
    },
    "Core Version": {
        "vi_VN": "Phiên bản lõi",
        "km_KH": "កំណែស្នូល",
        "my_MM": "အဓိကဗားရှင်း",
    },
    "Open Source License": {
        "vi_VN": "Giấy phép mã nguồn mở",
        "km_KH": "អាជ្ញាប័ណ្ណកូដបើកចំហ",
        "my_MM": "အိုပင်ဆောစ်လိုင်စင်",
    },
    "View": {
        "vi_VN": "Xem",
        "km_KH": "មើល",
        "my_MM": "ကြည့်ရန်",
    },
    # === ServerListPage ===
    "Test All Speed": {
        "fa_IR": "تست سرعت همه",
        "vi_VN": "Kiểm tra tốc độ tất cả",
        "km_KH": "ធ្វើតេស្តល្បឿនទាំងអស់",
        "my_MM": "အားလုံးအမြန်နှုန်းစမ်းသပ်ရန်",
    },
    "Speed": {
        "fa_IR": "سرعت",
        "vi_VN": "Tốc độ",
        "km_KH": "ល្បឿន",
        "my_MM": "အမြန်နှုန်း",
    },
    "Test": {
        "fa_IR": "تست",
        "vi_VN": "Kiểm tra",
        "km_KH": "តេស្ត",
        "my_MM": "စမ်းသပ်",
    },
    "Batch test completed": {
        "fa_IR": "تست دسته‌ای تکمیل شد",
        "vi_VN": "Kiểm tra hàng loạt hoàn tất",
        "km_KH": "ការធ្វើតេស្តជាបាច់បានបញ្ចប់",
        "my_MM": "အစုလိုက်စမ်းသပ်ခြင်းပြီးပါပြီ",
    },
    "Speed: %1 Mbps": {
        "fa_IR": "سرعت: %1 مگابیت",
        "vi_VN": "Tốc độ: %1 Mbps",
        "km_KH": "ល្បឿន: %1 Mbps",
        "my_MM": "အမြန်နှုန်း: %1 Mbps",
    },
    "Speed test failed": {
        "fa_IR": "تست سرعت ناموفق",
        "vi_VN": "Kiểm tra tốc độ thất bại",
        "km_KH": "ការធ្វើតេស្តល្បឿនបរាជ័យ",
        "my_MM": "အမြန်နှုန်းစမ်းသပ်ခြင်းမအောင်မြင်ပါ",
    },
    "No servers to test": {
        "fa_IR": "سروری برای تست وجود ندارد",
        "vi_VN": "Không có máy chủ để kiểm tra",
        "km_KH": "គ្មានម៉ាស៊ីនមេដើម្បីធ្វើតេស្ត",
        "my_MM": "စမ်းသပ်ရန်ဆာဗာမရှိပါ",
    },
    "Latency Testing": {
        "fa_IR": "تست تأخیر",
        "vi_VN": "Đang kiểm tra độ trễ",
        "km_KH": "កំពុងធ្វើតេស្តភាពយឺត",
        "my_MM": "လေတင်စီစစ်နေသည်",
    },
    "Testing latency...": {
        "fa_IR": "در حال تست تأخیر...",
        "vi_VN": "Đang kiểm tra độ trễ...",
        "km_KH": "កំពុងធ្វើតេស្តភាពយឺត...",
        "my_MM": "လေတင်စီစစ်နေသည်...",
    },
    "Speed Testing (%1/%2)": {
        "fa_IR": "تست سرعت (%1/%2)",
        "vi_VN": "Kiểm tra tốc độ (%1/%2)",
        "km_KH": "កំពុងធ្វើតេស្តល្បឿន (%1/%2)",
        "my_MM": "အမြန်နှုန်းစမ်းသပ်နေသည် (%1/%2)",
    },
    "Speed Testing": {
        "fa_IR": "تست سرعت",
        "vi_VN": "Đang kiểm tra tốc độ",
        "km_KH": "កំពុងធ្វើតេស្តល្បឿន",
        "my_MM": "အမြန်နှုန်းစမ်းသပ်နေသည်",
    },
    "Testing speed...": {
        "fa_IR": "در حال تست سرعت...",
        "vi_VN": "Đang kiểm tra tốc độ...",
        "km_KH": "កំពុងធ្វើតេស្តល្បឿន...",
        "my_MM": "အမြန်နှုန်းစမ်းသပ်နေသည်...",
    },
    "Test cancelled": {
        "fa_IR": "تست لغو شد",
        "vi_VN": "Đã hủy kiểm tra",
        "km_KH": "ការធ្វើតេស្តត្រូវបានបោះបង់",
        "my_MM": "စမ်းသပ်ခြင်းပယ်ဖျက်ပြီး",
    },
    "No Servers Available": {
        "vi_VN": "Không có máy chủ khả dụng",
        "km_KH": "គ្មានម៉ាស៊ីនមេដែលអាចប្រើបាន",
        "my_MM": "ရရှိနိုင်သောဆာဗာမရှိပါ",
    },
    "Click 'Refresh' button above to load servers": {
        "vi_VN": "Nhấn nút 'Làm mới' phía trên để tải máy chủ",
        "km_KH": "ចុចប៊ូតុង 'ធ្វើឱ្យស្រស់' ខាងលើដើម្បីផ្ទុកម៉ាស៊ីនមេ",
        "my_MM": "ဆာဗာများဖတ်ရန် အထက်ရှိ 'ပြန်လည်စတင်' ခလုတ်ကိုနှိပ်ပါ",
    },
    "Please add a subscription first": {
        "vi_VN": "Vui lòng thêm đăng ký trước",
        "km_KH": "សូមបន្ថែមការជាវមុនសិន",
        "my_MM": "ကျေးဇူးပြု၍ စာရင်းသွင်းမှုအရင်ထည့်ပါ",
    },
    # === ConnectionViewModel / CountryHelper / ServerListViewModel ===
    "Unknown Status": {
        "vi_VN": "Trạng thái không xác định",
        "km_KH": "ស្ថានភាពមិនស្គាល់",
        "my_MM": "အခြေအနေမသိ",
    },
    "None": {
        "vi_VN": "Không có",
        "km_KH": "គ្មាន",
        "my_MM": "မရှိ",
    },
    "Unknown": {
        "vi_VN": "Không xác định",
        "km_KH": "មិនស្គាល់",
        "my_MM": "မသိ",
    },
    "VPN not connected": {
        "vi_VN": "VPN chưa kết nối",
        "km_KH": "VPN មិនទាន់បានភ្ជាប់",
        "my_MM": "VPN မချိတ်ဆက်ရသေး",
    },
    # === LoginForm / LoginViewModel ===
    "Logging in...": {
        "vi_VN": "Đang đăng nhập...",
        "km_KH": "កំពុងចូល...",
        "my_MM": "ဝင်ရောက်နေသည်...",
    },
    "Please enterUsername": {
        "vi_VN": "Vui lòng nhập tên đăng nhập",
        "km_KH": "សូមបញ្ចូលឈ្មោះអ្នកប្រើប្រាស់",
        "my_MM": "အသုံးပြုသူအမည်ရိုက်ထည့်ပါ",
    },
    "Password reset email sent to %1": {
        "vi_VN": "Email đặt lại mật khẩu đã gửi đến %1",
        "km_KH": "អ៊ីមែលកំណត់ពាក្យសម្ងាត់ឡើងវិញបានផ្ញើទៅ %1",
        "my_MM": "စကားဝှက်ပြန်သတ်မှတ်ရန်အီးမေးလ် %1 သို့ပေးပို့ပြီး",
    },
    "Password must be at least 6 characters": {
        "vi_VN": "Mật khẩu phải có ít nhất 6 ký tự",
        "km_KH": "ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ",
        "my_MM": "စကားဝှက်တွင် အနည်းဆုံးစာလုံး ၆ လုံးရှိရမည်",
    },
    # === ServerCard ===
    "Plan Name": {
        "vi_VN": "Tên gói",
        "km_KH": "ឈ្មោះគម្រោង",
        "my_MM": "အစီအစဉ်အမည်",
    },
    "Price / Period": {
        "vi_VN": "Giá / Thời hạn",
        "km_KH": "តម្លៃ / រយៈពេល",
        "my_MM": "စျေးနှုန်း / ကာလ",
    },
    "Unlimited traffic, 5 devices": {
        "vi_VN": "Lưu lượng không giới hạn, 5 thiết bị",
        "km_KH": "ចរាចរគ្មានដែនកំណត់, ឧបករណ៍ ៥",
        "my_MM": "ဒေတာအကန့်အသတ်မရှိ, စက် ၅ လုံး",
    },
    "Purchase Now": {
        "vi_VN": "Mua ngay",
        "km_KH": "ទិញឥឡូវ",
        "my_MM": "ယခုဝယ်ယူရန်",
    },
    # === ServerGroupCard / ServerItem ===
    "%1 Servers": {
        "vi_VN": "%1 máy chủ",
        "km_KH": "ម៉ាស៊ីនមេ %1",
        "my_MM": "ဆာဗာ %1 ခု",
    },
    "UnknownServers": {
        "vi_VN": "Máy chủ không xác định",
        "km_KH": "ម៉ាស៊ីនមេមិនស្គាល់",
        "my_MM": "မသိဆာဗာများ",
    },
    "Load %1%": {
        "vi_VN": "Tải %1%",
        "km_KH": "បន្ទុក %1%",
        "my_MM": "ဝန် %1%",
    },
    "Not Tested": {
        "vi_VN": "Chưa kiểm tra",
        "km_KH": "មិនទាន់បានធ្វើតេស្ត",
        "my_MM": "မစမ်းသပ်ရသေး",
    },
    "Excellent": {
        "vi_VN": "Xuất sắc",
        "km_KH": "ល្អឥតខ្ចោះ",
        "my_MM": "အကောင်းဆုံး",
    },
    "Good": {
        "vi_VN": "Tốt",
        "km_KH": "ល្អ",
        "my_MM": "ကောင်း",
    },
    "General": {
        "vi_VN": "Bình thường",
        "km_KH": "ធម្មតា",
        "my_MM": "သာမန်",
    },
    "Poor": {
        "vi_VN": "Kém",
        "km_KH": "អន់",
        "my_MM": "ညံ့",
    },
    "Just now": {
        "vi_VN": "Vừa xong",
        "km_KH": "ទើបតែ",
        "my_MM": "ယခုလေးတင်",
    },
    "%1 minutes ago": {
        "vi_VN": "%1 phút trước",
        "km_KH": "%1 នាទីមុន",
        "my_MM": "%1 မိနစ်အကြာ",
    },
    "%1 hours ago": {
        "vi_VN": "%1 giờ trước",
        "km_KH": "%1 ម៉ោងមុន",
        "my_MM": "%1 နာရီအကြာ",
    },
    "%1 days ago": {
        "vi_VN": "%1 ngày trước",
        "km_KH": "%1 ថ្ងៃមុន",
        "my_MM": "%1 ရက်အကြာ",
    },
    # === ServerSelectDialog ===
    "No matching servers found": {
        "vi_VN": "Không tìm thấy máy chủ phù hợp",
        "km_KH": "រកមិនឃើញម៉ាស៊ីនមេដែលត្រូវគ្នា",
        "my_MM": "ကိုက်ညီသောဆာဗာမတွေ့ပါ",
    },
    "No Servers": {
        "vi_VN": "Không có máy chủ",
        "km_KH": "គ្មានម៉ាស៊ីនមេ",
        "my_MM": "ဆာဗာမရှိပါ",
    },
    "Refresh List": {
        "vi_VN": "Làm mới danh sách",
        "km_KH": "ធ្វើឱ្យបញ្ជីស្រស់",
        "my_MM": "စာရင်းပြန်ဖတ်ရန်",
    },
    "Total %1 servers": {
        "vi_VN": "Tổng cộng %1 máy chủ",
        "km_KH": "សរុប %1 ម៉ាស៊ីនមេ",
        "my_MM": "စုစုပေါင်းဆာဗာ %1 ခု",
    },
    # === StorePage ===
    "Traffic Reset Date:": {
        "vi_VN": "Ngày đặt lại lưu lượng:",
        "km_KH": "កាលបរិច្ឆេទកំណត់ចរាចរឡើងវិញ:",
        "my_MM": "ဒေတာပြန်စရက်:",
    },
    "Day %1 of each month": {
        "vi_VN": "Ngày %1 mỗi tháng",
        "km_KH": "ថ្ងៃទី %1 នៃខែនីមួយៗ",
        "my_MM": "လတိုင်း %1 ရက်",
    },
    "Device Limit:": {
        "vi_VN": "Giới hạn thiết bị:",
        "km_KH": "ដែនកំណត់ឧបករណ៍:",
        "my_MM": "စက်ကန့်သတ်ချက်:",
    },
    "%1 devices": {
        "vi_VN": "%1 thiết bị",
        "km_KH": "ឧបករណ៍ %1",
        "my_MM": "စက် %1 လုံး",
    },
    "Speed Limit:": {
        "vi_VN": "Giới hạn tốc độ:",
        "km_KH": "ដែនកំណត់ល្បឿន:",
        "my_MM": "အမြန်နှုန်းကန့်သတ်:",
    },
    "%1 Mbps": {
        "vi_VN": "%1 Mbps", "km_KH": "%1 Mbps", "my_MM": "%1 Mbps",
    },
    "NoneAvailablePlans": {
        "vi_VN": "Không có gói khả dụng",
        "km_KH": "គ្មានគម្រោងដែលអាចប្រើបាន",
        "my_MM": "ရရှိနိုင်သောအစီအစဉ်မရှိပါ",
    },
    "LoadingPlans...": {
        "vi_VN": "Đang tải gói...",
        "km_KH": "កំពុងផ្ទុកគម្រោង...",
        "my_MM": "အစီအစဉ်များဖတ်နေသည်...",
    },
    "Copied to clipboard": {
        "vi_VN": "Đã sao chép vào clipboard",
        "km_KH": "បានចម្លងទៅក្ដារតម្បៀតខ្ទាស់",
        "my_MM": "ကလစ်ဘုတ်သို့ကူးပြီးပါပြီ",
    },
    "Subscription link updated": {
        "vi_VN": "Đã cập nhật liên kết đăng ký",
        "km_KH": "បានធ្វើបច្ចុប្បន្នភាពតំណភ្ជាប់ការជាវ",
        "my_MM": "စာရင်းသွင်းမှုလင့်ခ်အပ်ဒိတ်ပြီးပါပြီ",
    },
    "UnknownPlans": {
        "vi_VN": "Gói không xác định",
        "km_KH": "គម្រោងមិនស្គាល់",
        "my_MM": "မသိအစီအစဉ်များ",
    },
    "Plans #": {
        "vi_VN": "Gói #",
        "km_KH": "គម្រោង #",
        "my_MM": "အစီအစဉ် #",
    },
    "Update Subscription Link?": {
        "vi_VN": "Cập nhật liên kết đăng ký?",
        "km_KH": "ធ្វើបច្ចុប្បន្នភាពតំណភ្ជាប់ការជាវ?",
        "my_MM": "စာရင်းသွင်းမှုလင့်ခ်အပ်ဒိတ်လုပ်မလား?",
    },
    "Warning: This action cannot be undone!": {
        "vi_VN": "Cảnh báo: Hành động này không thể hoàn tác!",
        "km_KH": "ព្រមាន: សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ!",
        "my_MM": "သတိပေးချက်: ဤလုပ်ဆောင်ချက်ကိုပြန်ဖြေမရပါ!",
    },
    "The old subscription URL will become invalid immediately.": {
        "vi_VN": "URL đăng ký cũ sẽ hết hiệu lực ngay lập tức.",
        "km_KH": "URL ការជាវចាស់នឹងក្លាយជាមិនត្រឹមត្រូវភ្លាមៗ។",
        "my_MM": "စာရင်းသွင်းမှု URL အဟောင်းသည်ချက်ချင်းအကျုံးမဝင်တော့ပါ။",
    },
    "You will need to re-import the new subscription link on all your devices after updating.": {
        "vi_VN": "Bạn sẽ cần nhập lại liên kết đăng ký mới trên tất cả thiết bị sau khi cập nhật.",
        "km_KH": "អ្នកនឹងត្រូវនាំចូលតំណភ្ជាប់ការជាវថ្មីនៅលើឧបករណ៍ទាំងអស់បន្ទាប់ពីធ្វើបច្ចុប្បន្នភាព។",
        "my_MM": "အပ်ဒိတ်ပြီးနောက်သင့်စက်အားလုံးတွင်စာရင်းသွင်းမှုလင့်ခ်အသစ်ပြန်တင်ရန်လိုအပ်မည်။",
    },
    "Update": {
        "vi_VN": "Cập nhật",
        "km_KH": "ធ្វើបច្ចុប្បន្នភាព",
        "my_MM": "အပ်ဒိတ်",
    },
    # === SubscriptionCard ===
    "Purchased": {
        "vi_VN": "Đã mua",
        "km_KH": "បានទិញ",
        "my_MM": "ဝယ်ယူပြီး",
    },
    "Recommended": {
        "vi_VN": "Được đề xuất",
        "km_KH": "បានណែនាំ",
        "my_MM": "အကြံပြုထားသည်",
    },
    "Popular": {
        "vi_VN": "Phổ biến",
        "km_KH": "ពេញនិយម",
        "my_MM": "လူကြိုက်များ",
    },
    "Traffic:": {
        "vi_VN": "Lưu lượng:",
        "km_KH": "ចរាចរ:",
        "my_MM": "ဒေတာ:",
    },
    "%1 GB": {
        "vi_VN": "%1 GB", "km_KH": "%1 GB", "my_MM": "%1 GB",
    },
    "Devices:": {
        "vi_VN": "Thiết bị:",
        "km_KH": "ឧបករណ៍:",
        "my_MM": "စက်များ:",
    },
    "%1 online": {
        "vi_VN": "%1 trực tuyến",
        "km_KH": "%1 អនឡាញ",
        "my_MM": "%1 အွန်လိုင်း",
    },
    "Speed:": {
        "vi_VN": "Tốc độ:",
        "km_KH": "ល្បឿន:",
        "my_MM": "အမြန်နှုန်း:",
    },
    # === SystemTrayManager ===
    "JinGo VPN": {
        "vi_VN": "JinGo VPN", "km_KH": "JinGo VPN", "my_MM": "JinGo VPN",
    },
    "Show Main Window": {
        "vi_VN": "Hiển thị cửa sổ chính",
        "km_KH": "បង្ហាញបង្អួចមេ",
        "my_MM": "ပင်မဝင်းဒိုးပြရန်",
    },
    "Quick Connect": {
        "vi_VN": "Kết nối nhanh",
        "km_KH": "ភ្ជាប់រហ័ស",
        "my_MM": "အမြန်ချိတ်ဆက်",
    },
    "Quit": {
        "vi_VN": "Thoát",
        "km_KH": "ចាកចេញ",
        "my_MM": "ထွက်ရန်",
    },
    "DisconnectConnect": {
        "vi_VN": "Ngắt kết nối",
        "km_KH": "ផ្ដាច់ការភ្ជាប់",
        "my_MM": "ချိတ်ဆက်မှုဖြတ်ရန်",
    },
    # === TicketListDialog ===
    "Select Attachment": {
        "vi_VN": "Chọn tệp đính kèm",
        "km_KH": "ជ្រើសរើសឯកសារភ្ជាប់",
        "my_MM": "ပူးတွဲဖိုင်ရွေးချယ်ရန်",
    },
    "Images": {
        "vi_VN": "Hình ảnh",
        "km_KH": "រូបភាព",
        "my_MM": "ပုံများ",
    },
    "Documents": {
        "vi_VN": "Tài liệu",
        "km_KH": "ឯកសារ",
        "my_MM": "စာရွက်စာတမ်းများ",
    },
    "All Files": {
        "vi_VN": "Tất cả tệp",
        "km_KH": "ឯកសារទាំងអស់",
        "my_MM": "ဖိုင်အားလုံး",
    },
    "Attachment": {
        "vi_VN": "Tệp đính kèm",
        "km_KH": "ឯកសារភ្ជាប់",
        "my_MM": "ပူးတွဲဖိုင်",
    },
    "Optional": {
        "vi_VN": "Tùy chọn",
        "km_KH": "ជម្រើស",
        "my_MM": "ရွေးချယ်နိုင်သည်",
    },
    "Click to select file": {
        "vi_VN": "Nhấn để chọn tệp",
        "km_KH": "ចុចដើម្បីជ្រើសរើសឯកសារ",
        "my_MM": "ဖိုင်ရွေးချယ်ရန်နှိပ်ပါ",
    },
    "No content": {
        "vi_VN": "Không có nội dung",
        "km_KH": "គ្មានមាតិកា",
        "my_MM": "အကြောင်းအရာမရှိပါ",
    },
    "Add attachment": {
        "vi_VN": "Thêm tệp đính kèm",
        "km_KH": "បន្ថែមឯកសារភ្ជាប់",
        "my_MM": "ပူးတွဲဖိုင်ထည့်ရန်",
    },
    # === TrafficDisplay ===
    "Traffic Statistics": {
        "vi_VN": "Thống kê lưu lượng",
        "km_KH": "ស្ថិតិចរាចរ",
        "my_MM": "ဒေတာအသွားအလာစာရင်းအင်း",
    },
    "Peak Upload": {
        "vi_VN": "Tải lên cao nhất",
        "km_KH": "ផ្ទុកឡើងខ្ពស់បំផុត",
        "my_MM": "အမြင့်ဆုံးအပ်လုဒ်",
    },
    "Avg Upload": {
        "vi_VN": "Tải lên trung bình",
        "km_KH": "ផ្ទុកឡើងជាមធ្យម",
        "my_MM": "ပျမ်းမျှအပ်လုဒ်",
    },
    "Peak Download": {
        "vi_VN": "Tải xuống cao nhất",
        "km_KH": "ទាញយកខ្ពស់បំផុត",
        "my_MM": "အမြင့်ဆုံးဒေါင်းလုဒ်",
    },
    "Avg Download": {
        "vi_VN": "Tải xuống trung bình",
        "km_KH": "ទាញយកជាមធ្យម",
        "my_MM": "ပျမ်းမျှဒေါင်းလုဒ်",
    },
    # === main (vi_VN/km_KH/my_MM specific) ===
    "Secure. Fast. Borderless.": {
        "vi_VN": "An toàn. Nhanh chóng. Không biên giới.",
        "km_KH": "សុវត្ថិភាព។ លឿន។ គ្មានព្រំដែន។",
        "my_MM": "လုံခြုံ။ မြန်ဆန်။ နယ်နိမိတ်မဲ့။",
    },
    "VPN ConnectSuccess": {
        "vi_VN": "Kết nối VPN thành công",
        "km_KH": "ភ្ជាប់ VPN ជោគជ័យ",
        "my_MM": "VPN ချိတ်ဆက်မှုအောင်မြင်",
    },
    "VPN Disconnected": {
        "vi_VN": "VPN đã ngắt kết nối",
        "km_KH": "VPN បានផ្ដាច់",
        "my_MM": "VPN ချိတ်ဆက်မှုဖြတ်ပြီး",
    },
    "ConnectFailed": {
        "vi_VN": "Kết nối thất bại",
        "km_KH": "ការភ្ជាប់បរាជ័យ",
        "my_MM": "ချိတ်ဆက်မှုမအောင်မြင်ပါ",
    },
    "File": {
        "vi_VN": "Tệp",
        "km_KH": "ឯកសារ",
        "my_MM": "ဖိုင်",
    },
    "Preferences": {
        "vi_VN": "Tùy chọn",
        "km_KH": "ចំណូលចិត្ត",
        "my_MM": "ဦးစားပေးချက်များ",
    },
    "Report Issue": {
        "vi_VN": "Báo cáo sự cố",
        "km_KH": "រាយការណ៍បញ្ហា",
        "my_MM": "ပြဿနာတင်ပြရန်",
    },
    "Login/Register": {
        "vi_VN": "Đăng nhập/Đăng ký",
        "km_KH": "ចូល/ចុះឈ្មោះ",
        "my_MM": "ဝင်ရောက်/စာရင်းသွင်း",
    },
    "Manage your VPN connection": {
        "vi_VN": "Quản lý kết nối VPN của bạn",
        "km_KH": "គ្រប់គ្រងការភ្ជាប់ VPN របស់អ្នក",
        "my_MM": "သင်၏ VPN ချိတ်ဆက်မှုကိုစီမံရန်",
    },
    "Select the best server": {
        "vi_VN": "Chọn máy chủ tốt nhất",
        "km_KH": "ជ្រើសរើសម៉ាស៊ីនមេល្អបំផុត",
        "my_MM": "အကောင်းဆုံးဆာဗာရွေးချယ်ရန်",
    },
    "Upgrade your subscription plan": {
        "vi_VN": "Nâng cấp gói đăng ký",
        "km_KH": "ធ្វើឱ្យប្រសើរគម្រោងការជាវរបស់អ្នក",
        "my_MM": "သင်၏စာရင်းသွင်းအစီအစဉ်ကိုအဆင့်မြှင့်ရန်",
    },
    "Application minimized to system tray, double-click the tray icon to reopen": {
        "vi_VN": "Ứng dụng đã thu nhỏ vào khay hệ thống, nhấp đúp biểu tượng để mở lại",
        "km_KH": "កម្មវិធីបានបង្រួមទៅថាសប្រព័ន្ធ ចុចពីរដងលើរូបតំណាងដើម្បីបើកឡើងវិញ",
        "my_MM": "အက်ပ်ကိုစနစ်ထရေးသို့ချုံ့ပြီး၊ ပြန်ဖွင့်ရန်ထရေးအိုင်ကွန်ကိုနှစ်ချက်နှိပ်ပါ",
    },
    # === StatusIndicator ===
    "Connecting": {
        "vi_VN": "Đang kết nối",
        "km_KH": "កំពុងភ្ជាប់",
        "my_MM": "ချိတ်ဆက်နေသည်",
    },
}


def process_ts_file(ts_file, lang_code):
    """Process a single .ts file and fill in missing translations"""
    tree = ET.parse(ts_file)
    root = tree.getroot()
    filled = 0
    still_missing = 0

    for context in root.findall('context'):
        for message in context.findall('message'):
            source = message.find('source')
            translation = message.find('translation')
            if source is None or translation is None:
                continue

            source_text = source.text or ""
            # Only process unfinished translations
            if translation.get('type') != 'unfinished':
                continue

            if source_text in TRANSLATIONS and lang_code in TRANSLATIONS[source_text]:
                translation.text = TRANSLATIONS[source_text][lang_code]
                if 'type' in translation.attrib:
                    del translation.attrib['type']
                filled += 1
            else:
                still_missing += 1

    # Write output
    tree.write(ts_file, encoding='utf-8', xml_declaration=True)

    # Fix DOCTYPE
    with open(ts_file, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(
        "<?xml version='1.0' encoding='utf-8'?>",
        '<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>'
    )
    with open(ts_file, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"  {lang_code}: filled {filled}, still missing {still_missing}")
    return filled, still_missing


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    trans_dir = os.path.join(base_dir, 'resources', 'translations')

    langs = ['zh_CN', 'ru_RU', 'fa_IR', 'vi_VN', 'km_KH', 'my_MM']
    total_filled = 0
    total_missing = 0

    for lang in langs:
        ts_file = os.path.join(trans_dir, f'jingo_{lang}.ts')
        if os.path.exists(ts_file):
            filled, missing = process_ts_file(ts_file, lang)
            total_filled += filled
            total_missing += missing

    # Handle zh_TW by converting from zh_CN
    zh_tw_file = os.path.join(trans_dir, 'jingo_zh_TW.ts')
    if os.path.exists(zh_tw_file):
        # Import s2t from the main translate script
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        from translate_ts import s2t

        tree = ET.parse(zh_tw_file)
        root = tree.getroot()
        filled = 0
        still_missing = 0

        for context in root.findall('context'):
            for message in context.findall('message'):
                source = message.find('source')
                translation = message.find('translation')
                if source is None or translation is None:
                    continue
                source_text = source.text or ""
                if translation.get('type') != 'unfinished':
                    continue

                if source_text in TRANSLATIONS and 'zh_CN' in TRANSLATIONS[source_text]:
                    zh_cn_text = TRANSLATIONS[source_text]['zh_CN']
                    translation.text = s2t(zh_cn_text)
                    if 'type' in translation.attrib:
                        del translation.attrib['type']
                    filled += 1
                else:
                    still_missing += 1

        tree.write(zh_tw_file, encoding='utf-8', xml_declaration=True)
        with open(zh_tw_file, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace(
            "<?xml version='1.0' encoding='utf-8'?>",
            '<?xml version="1.0" encoding="utf-8"?>\n<!DOCTYPE TS>'
        )
        with open(zh_tw_file, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"  zh_TW: filled {filled} (converted from zh_CN), still missing {still_missing}")
        total_filled += filled
        total_missing += still_missing

    print(f"\nTotal: filled {total_filled}, still missing {total_missing}")


if __name__ == '__main__':
    main()
