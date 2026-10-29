import json
import os

# مسار الملف القديم (100 بيت) الموجود في مجلد الأصول
old_file = "assets/data/verses.json"
# مسار الملف الجديد (1000 بيت) الذي استخرجناه للتو
new_file = "verses.json"
# اسم الملف النهائي الذي سيدخل التطبيق
output_file = "assets/data/verses_combined.json"

def merge_databases():
    print("⏳ جاري دمج قواعد البيانات...")
    
    # قراءة الملف القديم
    with open(old_file, 'r', encoding='utf-8') as f:
        old_verses = json.load(f)
        
    # قراءة الملف الجديد
    with open(new_file, 'r', encoding='utf-8') as f:
        new_verses = json.load(f)

    combined = []
    current_id = 1

    # إضافة الأبيات القديمة (الـ 100)
    for v in old_verses:
        combined.append({
            "id": current_id,
            "sadr": v["sadr"],
            "ajz": v["ajz"],
            "poet": v.get("poet", "غير معروف"),
            "sea": v.get("sea", "")
        })
        current_id += 1

    # إضافة الأبيات الجديدة (الـ 1000)
    for v in new_verses:
        combined.append({
            "id": current_id,
            "sadr": v["sadr"],
            "ajz": v["ajz"],
            "poet": v.get("poet", "غير معروف"),
            "sea": v.get("sea", "")
        })
        current_id += 1

    # حفظ الملف المدمج
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(combined, f, ensure_ascii=False, indent=2)

    print(f"🎉 تم الدمج بنجاح! المجموع الكلي: {len(combined)} بيت شعري.")
    print(f"💾 الملف الجديد محفوظ في: {output_file}")

if __name__ == "__main__":
    merge_databases()