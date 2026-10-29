import json
import re

# مسار الملف الذي قمنا بدمجه
input_file = "assets/data/verses_combined.json"

def check_and_clean():
    print("⏳ جاري فحص الأبيات...")
    with open(input_file, 'r', encoding='utf-8') as f:
        verses = json.load(f)

    clean_verses = []
    current_id = 1
    removed_count = 0

    for v in verses:
        sadr = v.get('sadr', '').strip()
        ajz = v.get('ajz', '').strip()

        # 1. التأكد من عدم وجود فراغات
        if not sadr or not ajz:
            removed_count += 1
            continue

        # 2. التأكد من التوازن (الفرق بين طول الصدر والعجز لا يتجاوز 20 حرفاً)
        if abs(len(sadr) - len(ajz)) > 20:
            print(f"⚠️ حذف بيت غير متوازن: {sadr} || {ajz}")
            removed_count += 1
            continue

        # 3. التأكد من عدم وجود أرقام أو حروف إنجليزية
        if re.search(r'[a-zA-Z0-9]', sadr) or re.search(r'[a-zA-Z0-9]', ajz):
            print(f"⚠️ حذف بيت يحتوي رموزاً غريبة: {sadr} || {ajz}")
            removed_count += 1
            continue

        # إذا تجاوز البيت كل الفحوصات، نعيد ترتيب الـ id ونحفظه
        v['id'] = current_id
        clean_verses.append(v)
        current_id += 1

    # حفظ الملف بعد التنظيف (سنستبدل الملف القديم مباشرة)
    with open(input_file, 'w', encoding='utf-8') as f:
        json.dump(clean_verses, f, ensure_ascii=False, indent=2)

    print("-" * 30)
    print(f"✅ اكتمل الفحص! الأبيات السليمة المتبقية: {len(clean_verses)}")
    print(f"🗑️ عدد الأبيات التي تم حذفها: {removed_count}")

if __name__ == "__main__":
    check_and_clean()