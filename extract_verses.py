import json
import random
import os

# اسم ملف البيانات الكبير الذي قمتِ بتنزيله من Kaggle
INPUT_FILE = "poems_dataset.json" 
# اسم الملف الناتج الذي سيقرأه التطبيق
OUTPUT_FILE = "verses.json"

# عدد الأبيات التي نريد استخراجها (1000 بيت يعطي تنوعاً رائعاً)
TARGET_VERSES = 1000

def extract_verses():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ خطأ: لم يتم العثور على الملف {INPUT_FILE}. تأكدي من وضعه في نفس المجلد.")
        return

    print("⏳ جاري قراءة ملف البيانات الكبير (قد يستغرق بضع ثوانٍ)...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"✅ تم تحميل {len(data)} قصيدة. جاري خلطها لضمان التنوع...")
    # نخلط القصائد لكي لا تكون كل الأبيات من نفس الشاعر
    random.shuffle(data)
    
    extracted_verses = []
    verse_id = 1
    
    for poem in data:
        # التوقف إذا وصلنا للعدد المطلوب
        if verse_id > TARGET_VERSES:
            break
            
        text = poem.get('text', [])
        poet = poem.get('poet', 'غير معروف')
        sea = poem.get('sea', '')
        
        # التأكد من وجود النص وأن طوله يسمح باستخراج بيت (شطرين على الأقل)
        if not text or len(text) < 2:
            continue
            
        # استخراج الأبيات (كل شطرين متتاليين يشكلان بيتاً: صدر وعجز)
        for i in range(0, len(text) - 1, 2):
            if verse_id > TARGET_VERSES:
                break
                
            sadr = text[i].strip()
            ajz = text[i+1].strip()
            
            # تجاهل الأشطر الفارغة أو القصيرة جداً
            if not sadr or not ajz or len(sadr) < 5 or len(ajz) < 5:
                continue
                
            extracted_verses.append({
                "id": verse_id,
                "sadr": sadr,
                "ajz": ajz,
                "poet": poet,
                "sea": sea
            })
            verse_id += 1
            
    print(f"🎉 تم استخراج {len(extracted_verses)} بيت شعري بنجاح.")
    
    # حفظ الملف بصيغة JSON
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(extracted_verses, f, ensure_ascii=False, indent=2)
        
    print(f"💾 تم حفظ الملف الجديد في: {OUTPUT_FILE}")

if __name__ == "__main__":
    extract_verses()