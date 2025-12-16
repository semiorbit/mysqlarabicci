# SEMIORBIT MYSQL UTF8 ARABIC CI COLLATION

**utf8_arabic_ci [1029] collation will help ignoring Arabic (Hamza & Tashkīl) on applied field in MySQL.**

---

## What is this project?

This project provides a **custom MySQL collation** that improves Arabic text comparison by normalizing:
- Alef forms (أ إ آ ا)
- Teh Marbuta (ة ↔ ه)
- Arabic Tashkīl ( َ ِ ُ ً ٍ ٌ ّ ْ )

It also includes a **safe installer and automation tool** that reinjects the collation automatically after MySQL updates.

---

## ما هو هذا المشروع؟

يوفّر هذا المشروع **ترتيب (Collation) مخصص لـ MySQL** لتحسين مقارنة (البحث في) النصوص العربية من خلال:
- توحيد أشكال الألف (أ إ آ ا)
- معالجة التاء المربوطة (ة ↔ ه)
- تجاهل التشكيل العربي (الفتحة، الضمة، الكسرة، السكون، الشدة…)

كما يحتوي على **أداة تثبيت وأتمتة** تعيد إضافة الترتيب تلقائياً بعد تحديث MySQL.

---

## Why is this needed?

Default MySQL Arabic collations do **not** treat different Alef forms or Tashkīl as equal.  
This causes incorrect results in searches, comparisons, and filters.

Example problems:
- أحمد ≠ احمد
- إسلام ≠ اسلام
- عَلِمَ ≠ علم

---

## لماذا نحتاج هذا الحل؟

ترتيبات MySQL الافتراضية **لا تتعامل بشكل صحيح** مع اختلافات الألف أو التشكيل،  
مما يؤدي إلى نتائج بحث غير دقيقة.

أمثلة على المشاكل:
- أحمد ≠ احمد
- إسلام ≠ اسلام
- عَلِمَ ≠ علم

---

## How it works (concept)

The collation works by **resetting multiple Unicode code points** to a single normalized form before comparison.

For example:
- أ إ آ → ا
- All Tashkīl → ignored
- ة → ه

This makes comparisons semantic instead of literal.

---

## كيف يعمل الترتيب (الفكرة العامة)

يعتمد الترتيب على **توحيد عدة رموز Unicode** إلى شكل واحد قبل المقارنة.

مثال:
- أ إ آ → ا
- تجاهل جميع التشكيل
- ة → ه

وبذلك تصبح المقارنة دلالية وليست حرفية.

---

## Example SQL behavior

```sql
SELECT * FROM users
WHERE name LIKE '%احمد%';
```

This query will correctly match:
- احمد
- أحمد
- أَحْمَد

---

## مثال عملي في SQL

```sql
SELECT * FROM users
WHERE name LIKE '%احمد%';
```

سيطابق هذا الاستعلام:
- احمد
- أحمد
- أَحْمَد

---

## Manual approach (without this tool)

Manually, this requires:
1. Editing MySQL `Index.xml`
2. Adding a custom `<collation>` block
3. Repeating the process after every MySQL update
4. Restarting MySQL

This project automates all of that safely.

---

## الطريقة اليدوية (بدون هذه الأداة)

يدوياً يتطلب الأمر:
1. تعديل ملف `Index.xml` الخاص بـ MySQL
2. إضافة ترتيب مخصص
3. إعادة العملية بعد كل تحديث MySQL
4. إعادة تشغيل MySQL

هذه الأداة تقوم بكل ذلك تلقائياً وبشكل آمن.

---

## Full collation XML

The complete XML snippet used by this project can be found in the repository:

```
src/snippets/utf8_arabic_ci.xml
```

```xml
<!-- mysqlarabicci BEGIN -->

<collation name="utf8_arabic_ci" id="1029">
    <rules>
        <reset>\u0627</reset>   <!-- Alef 'ا' -->
        <i>\u0623</i>           <!-- Alef With Hamza Above 'أ' -->
        <i>\u0625</i>           <!-- Alef With Hamza Below 'إ' -->
        <i>\u0622</i>           <!-- Alef With Madda Above 'آ' -->
    </rules>
    <rules>
        <reset>\u0629</reset>   <!-- Teh Marbuta 'ة' -->
        <i>\u0647</i>           <!-- Heh 'ه' -->
    </rules>
    <rules>
        <reset>\u0000</reset>   <!-- Unicode value of NULL  -->
        <i>\u064E</i>           <!-- Fatha 'َ' -->
        <i>\u064F</i>           <!-- Damma 'ُ' -->
        <i>\u0650</i>           <!-- Kasra 'ِ' -->
        <i>\u0651</i>           <!-- Shadda 'ّ' -->
        <i>\u064F</i>           <!-- Sukun 'ْ' -->
        <i>\u064B</i>           <!-- Fathatan 'ً' -->
        <i>\u064C</i>           <!-- Dammatan 'ٌ' -->
        <i>\u064D</i>           <!-- Kasratan 'ٍ' -->
    </rules>
</collation>

<!-- mysqlarabicci END -->
```

It is injected safely between clear markers and can be removed at any time.
NB.(For **Windows & Mac**) You still can copy and paste this xml snippet into MySQL charset file Index.xml under utf8.
But on **Linux** production server (RHEL based distro), this tool helps automating the process and keeping it working after MySQL updates automatically. 
---

## Installation (English)

```bash
cd /opt
git clone https://github.com/semiorbit/mysqlarabicci
cd mysqlarabicci
sudo bash install.sh
```

### Important note

The installer **does NOT inject xml snippet automatically**.

After installation, run:

```bash
mysqlarabicci --inject --restart
mysqlarabicci --check
```

---

## Available commands

```text
mysqlarabicci --inject
  Inject the collation without restarting MySQL

mysqlarabicci --inject --restart
  Inject and restart MySQL

mysqlarabicci --reject
  Remove the injected collation

mysqlarabicci --reject --restart
  Remove and restart MySQL

mysqlarabicci --check
  Check if the collation is currently injected

mysqlarabicci --update
  Re-detect MySQL version and update configuration

mysqlarabicci --help
  Show help
```

---

## Safety & design notes

- No schema changes
- No data modification
- Fully reversible
- Safe across MySQL upgrades
- systemd watcher re-injects automatically after updates

---

## Credits

Inspired by the research and explanation in this article:  
https://ahmadessamdev.medium.com/arabic-case-insensitive-in-database-systems-how-to-solve-alef-with-and-without-hamza-problem-c54ee6d40bed

---

## License

MIT License  
© Semiorbit Solutions
