import json
import random
import os

# مسار ملف الـ 100 بيت الأصلية
original_file = 'assets/data/verses.json' 
# مسار ملف الـ 1100 بيت المدمجة
combined_file = 'assets/data/verses_combined.json'

print("⏳ جاري قراءة البيانات وتجهيز المستويات...")

# 1. قراءة الـ 100 بيت الأصلية
with open(original_file, 'r', encoding='utf-8') as f:
    original_100 = json.load(f)

# 2. قراءة البيانات المدمجة لاستخراج أبيات كاجل
with open(combined_file, 'r', encoding='utf-8') as f:
    all_verses = json.load(f)

# نستخرج أبيات كاجل (نتخطى أول 100 بيت لأنها الأصلية)
kaggle_pool = all_verses[100:]
random.shuffle(kaggle_pool) # نخلطها لضمان العشوائية

# دالة لإعادة ترتيب الأرقام التسلسلية (ID)
def reassign_ids(verses):
    for i, v in enumerate(verses):
        v['id'] = i + 1
    return verses

# 3. إنشاء المستويات
# المبتدئين: 100 بيت فقط
beginner = reassign_ids(original_100.copy())

# المتوسطين: 100 بيت + 100 من كاجل = 200 بيت
intermediate = reassign_ids(original_100.copy() + kaggle_pool[:100])

# المحترفين: 100 بيت + 200 من كاجل = 300 بيت (الحد الأقصى)
expert = reassign_ids(original_100.copy() + kaggle_pool[:200])

# 4. حفظ الملفات
with open('assets/data/verses_beginner.json', 'w', encoding='utf-8') as f:
    json.dump(beginner, f, ensure_ascii=False, indent=2)

with open('assets/data/verses_intermediate.json', 'w', encoding='utf-8') as f:
    json.dump(intermediate, f, ensure_ascii=False, indent=2)

with open('assets/data/verses_expert.json', 'w', encoding='utf-8') as f:
    json.dump(expert, f, ensure_ascii=False, indent=2)

print("✅ تم إنشاء المستويات بنجاح!")
print(f"👶 المبتدئين: {len(beginner)}")
print(f"🧑 المتوسطين: {len(intermediate)}")
print(f"🧙‍♂️ المحترفين: {len(expert)}")