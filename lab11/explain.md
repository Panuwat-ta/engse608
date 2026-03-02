# เอกสารอธิบายฟังก์ชันของแอปพลิเคชัน Event & Reminder
> เขียนโดย: Antigravity AI | ภาษา: Dart (Flutter) | วันที่: 2 มีนาคม 2026

---

## 1. EventProvider (`lib/ui/state/event_provider.dart`)
จัดการสถานะ (State) ของ Event ทั้งหมดในแอป ประกอบด้วยฟังก์ชักดังนี้:

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `EventProvider()` | Constructor — เรียก `loadEvents()` ทันทีเมื่อสร้าง Provider |
| `loadEvents()` | โหลดรายการ Event ทั้งหมดจากฐานข้อมูล โดยนำ filter ที่ตั้งไว้มาใช้กรองด้วย |
| `setFilters({...})` | ตั้งค่าตัวกรอง เช่น วันที่ / หมวดหมู่ / สถานะ / คำค้นหา / การเรียงลำดับ แล้วโหลด Event ใหม่ |
| `clearFilters()` | ล้างตัวกรองทั้งหมดให้กลับเป็นค่าเริ่มต้น แล้วโหลด Event ใหม่ |
| `addEvent(event, reminders)` | เพิ่ม Event ใหม่ลงฐานข้อมูล พร้อมบันทึก Reminder และจัดกำหนดการแจ้งเตือนถ้าเปิดใช้งาน |
| `updateEvent(event, reminders)` | แก้ไขข้อมูล Event พร้อมยกเลิก Reminder เก่าและตั้ง Reminder ใหม่ใหม่ |
| `deleteEvent(eventId)` | ลบ Event ออกจากฐานข้อมูล พร้อมยกเลิกการแจ้งเตือนที่เกี่ยวข้องทั้งหมด |
| `changeEventStatus(eventId, newStatus)` | เปลี่ยนสถานะ Event เช่น pending → in_progress → completed; ถ้าสถานะเป็น completed/cancelled จะยกเลิกการแจ้งเตือนด้วย |
| `_scheduleNotification(event, reminder)` | (ใช้ภายใน) คำนวณเวลาแจ้งเตือนจากวันที่/เวลา Event แล้วส่งให้ NotificationService จัดกำหนดการ |
| `getRemindersForEvent(eventId)` | ดึงรายการ Reminder ทั้งหมดของ Event นั้น ๆ |

### ตัวกรองที่รองรับ:
- `dateFilter` — `"today"` / `"week"` / `"month"` / `null` (ทั้งหมด)
- `categoryIdFilter` — ID ของหมวดหมู่ที่ต้องการ
- `statusFilter` — `"pending"` / `"in_progress"` / `"completed"` / `"cancelled"`
- `searchQuery` — ค้นหาจากชื่อ Event
- `sortBy` — SQL ORDER BY เช่น `"event_date ASC, start_time ASC"`

---

## 2. CategoryProvider (`lib/ui/state/category_provider.dart`)
จัดการสถานะของ Category (หมวดหมู่)

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `CategoryProvider()` | Constructor — เรียก `loadCategories()` ทันที |
| `loadCategories()` | โหลด Category ทั้งหมดจากฐานข้อมูล; ถ้ายังไม่มีเลย จะสร้าง Category เริ่มต้น 3 อัน |
| `_addDefaultCategories()` | (ใช้ภายใน) สร้างหมวดหมู่เริ่มต้น: Work, Personal, Meeting |
| `addCategory(category)` | เพิ่ม Category ใหม่ลงฐานข้อมูล |
| `updateCategory(category)` | แก้ไขข้อมูล Category ที่มีอยู่ |
| `deleteCategory(id)` | ลบ Category; ถ้ามี Event ผูกอยู่จะ throw Exception ป้องกันการลบ |

---

## 3. EventRepository (`lib/data/repositories/event_repository.dart`)
ชั้น Data Access สำหรับ Event — ติดต่อกับ SQLite โดยตรง

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `insertEvent(event)` | บันทึก Event ใหม่ลงตาราง `events` คืนค่า ID ที่สร้าง |
| `getEvents({...})` | ดึง Event ตามเงื่อนไขกรอง: วันที่, หมวดหมู่, สถานะ, คำค้นหา, การเรียง |
| `getEventById(id)` | ดึง Event ตัวเดียวตาม ID; คืน `null` ถ้าไม่พบ |
| `updateEvent(event)` | อัปเดตข้อมูล Event พร้อมอัปเดต `updated_at` ให้เป็นเวลาปัจจุบัน |
| `deleteEvent(id)` | ลบ Event ออกจากตารางตาม ID |
| `updateEventStatus(id, newStatus)` | อัปเดตเฉพาะ field `status` และ `updated_at` ของ Event |

---

## 4. ReminderRepository (`lib/data/repositories/reminder_repository.dart`)
ชั้น Data Access สำหรับ Reminder

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `insertReminder(reminder)` | บันทึก Reminder ใหม่ลงตาราง `reminders` คืนค่า ID |
| `getRemindersByEventId(eventId)` | ดึง Reminder ทั้งหมดของ Event นั้น |
| `deleteRemindersByEventId(eventId)` | ลบ Reminder ทุกรายการของ Event นั้น |
| `disableRemindersByEventId(eventId)` | ปิดใช้งาน Reminder ของ Event (ตั้ง `is_enabled = 0`) |

---

## 5. NotificationService (`lib/services/notification_service.dart`)
บริการจัดการการแจ้งเตือนในเครื่อง (Local Notifications)

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `init()` | เริ่มต้น Plugin การแจ้งเตือน ตั้งค่า Timezone และขอสิทธิ์ Android 13+ |
| `scheduleNotification({id, title, body, scheduledDate})` | จัดกำหนดการแจ้งเตือนตามวันเวลาที่กำหนด; ถ้าเวลาผ่านไปแล้วจะไม่ทำอะไร |
| `cancelNotification(id)` | ยกเลิกการแจ้งเตือนตาม ID |

---

## 6. CategoryManageScreen (`lib/ui/screens/category_manage_screen.dart`)
หน้าจัดการหมวดหมู่

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `_showAddEditDialog(context, [category])` | แสดง Dialog เพิ่ม/แก้ไข Category พร้อม color picker และ icon selector |
| `_confirmDelete(context, category)` | แสดง Dialog ยืนยันการลบ Category; ป้องกันการลบถ้า Category มี Event ผูกอยู่ |
| `build(context)` | สร้าง UI รายการ Category พร้อมปุ่ม Edit/Delete และปุ่ม + เพิ่มใหม่ |

---

## 7. EventFormScreen (`lib/ui/screens/event_form_screen.dart`)
หน้าฟอร์มเพิ่ม/แก้ไข Event

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `initState()` | โหลดข้อมูล Event เดิม (กรณีแก้ไข) และดึง Reminder ที่บันทึกไว้ |
| `_loadReminders()` | โหลด Reminder ของ Event ที่กำลังแก้ไข เพื่อแสดงใน Toggle |
| `_selectDate(context)` | เปิด DatePicker ให้เลือกวันที่ |
| `_selectTime(context, isStart)` | เปิด TimePicker ให้เลือกเวลาเริ่มหรือสิ้นสุด |
| `_isEndTimeValid()` | ตรวจสอบว่าเวลาสิ้นสุดต้องมากกว่าเวลาเริ่มต้น |
| `_saveEvent()` | ตรวจสอบฟอร์ม สร้าง Event object และ Reminder แล้วบันทึกผ่าน EventProvider |
| `build(context)` | สร้าง UI ฟอร์มทั้งหมด พร้อม dropdown, date/time picker, toggle reminder |

---

## 8. EventDetailScreen (`lib/ui/screens/event_detail_screen.dart`)
หน้าแสดงรายละเอียด Event

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `_confirmDelete(context)` | แสดง Dialog ยืนยันการลบ Event |
| `_changeStatus(context, newStatus)` | เปลี่ยนสถานะ Event และแสดง SnackBar แจ้งผล |
| `_buildDetailRow(icon, label, value)` | สร้าง Widget แถวข้อมูลในรูปแบบ Icon + Label + Value |
| `_statusButton(context, statusKey, label, color)` | สร้างปุ่มเปลี่ยนสถานะตามสีที่กำหนด |
| `build(context)` | สร้าง UI รายละเอียด Event พร้อม Reminder และปุ่มเปลี่ยนสถานะ |

---

## 9. HomeScreen (`lib/ui/screens/home_screen.dart`)
หน้าหลักแสดงรายการ Event ทั้งหมด

| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `_buildFilterChips(...)` | สร้าง Chip กรองด่วน: Today / This Week / This Month |
| `_buildSearchBar(...)` | สร้าง SearchBar สำหรับค้นหา Event ตามชื่อ |
| `_buildSortDropdown(...)` | สร้าง Dropdown เลือกการเรียงลำดับ Event |
| `build(context)` | สร้าง UI หน้าหลักพร้อม AppBar, Filter, รายการ Event Card |

---

## 10. ฟังก์ชันใน Widget ย่อย

### CategoryBadge (`lib/ui/widgets/category_badge.dart`)
| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `_getColorFromHex(hexColor)` | แปลงรหัสสี Hex เช่น `#2196F3` เป็น Flutter `Color` พร้อม fallback สีเทาถ้า parse ไม่ได้ |
| `_getIconData(key)` | แปลงชื่อ icon key เป็น `IconData` ที่ใช้แสดงผล |

### StatusChip (`lib/ui/widgets/status_chip.dart`)
| ฟังก์ชัน | การทำงาน |
|---------|---------|
| `build(context)` | แสดง Chip สีตามสถานะ: pending=ส้ม, in_progress=น้ำเงิน, completed=เขียว, cancelled=แดง |

---

## สรุปโครงสร้างการทำงาน

```
main.dart
  └─ MultiProvider
       ├─ CategoryProvider ──► CategoryRepository ──► SQLite (categories)
       └─ EventProvider    ──► EventRepository    ──► SQLite (events)
                           ──► ReminderRepository ──► SQLite (reminders)
                           ──► NotificationService ──► flutter_local_notifications
```
