# Thailand Weather App

แอปพลิเคชัน Flutter สำหรับแสดงสภาพอากาศในประเทศไทย โดยใช้ข้อมูลจาก Open-Meteo API


## ฟีเจอร์หลัก (Features)

1.  **สภาพอากาศปัจจุบัน (Current Weather)**
    *   แสดงอุณหภูมิปัจจุบัน (Temperature)
    *   แสดงรหัสสภาพอากาศ (Weather Code)

2.  **พยากรณ์อากาศ 10 วันล่วงหน้า (10-Day Forecast)**
    *   แสดงวันที่ (Date)
    *   แสดงอุณหภูมิสูงสุดและต่ำสุด (Max/Min Temperature)
    *   แสดงรหัสสภาพอากาศ (Weather Code)

## เทคโนโลยีที่ใช้ (Tech Stack)

*   **Flutter**: Framework สำหรับสร้างแอปพลิเคชัน
*   **Provider**: สำหรับการจัดการสถานะภายในแอป (State Management)
*   **HTTP**: สำหรับการเรียกใช้งาน API

## แหล่งข้อมูล (API Source)

ใช้บริการฟรีจาก [Open-Meteo API](https://open-meteo.com/):
`https://api.open-meteo.com/v1/forecast?latitude=15.5&longitude=101&current=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=10&timezone=Asia%2FBangkok`


- ![](./img/home.png)
- ![](./img/10day.png)