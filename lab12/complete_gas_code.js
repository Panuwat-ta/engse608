// ════════════════════════════════════════════════════════════════
//  Community Tool Sharing — Google Apps Script Backend
//  วิธีใช้:
//  1. เปิด Google Sheet → Extensions → Apps Script
//  2. ลบโค้ดเดิมทั้งหมด แล้ววางโค้ดนี้
//  3. กด Deploy → New Deployment → Web App
//     • Execute as: Me
//     • Who has access: Anyone
//  4. คัดลอก Web App URL แล้วนํากลับไปวางในแอป
// ════════════════════════════════════════════════════════════════

const SPREADSHEET_ID = '1xi3nN0tvjX2SKxlMM5bS3yJo0CKsFft22jPAdgiudcI';

// Sheet names
const SHEET_NAMES = {
  EQUIPMENT: 'Equipment',
  TRANSACTIONS: 'Transactions',
  USERS: 'Users',
  ADMINS: 'Admins'
};

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const ss = SpreadsheetApp.openById(SPREADSHEET_ID);
    
    // Initialize sheets on first run
    _initializeSheets(ss);
    
    // Get the appropriate sheet based on action
    let sheet;
    if (data.action === 'register' || data.action === 'initTable' || 
        data.action === 'getAll' || data.action === 'updateStatus' || 
        data.action === 'checkUser') {
      sheet = ss.getSheetByName(SHEET_NAMES.USERS);
    }

    // ── Initialize empty table (headers only) ──────────────────
    if (data.action === 'initTable') {
      // Create header row if sheet is empty
      if (sheet.getLastRow() === 0) {
        sheet.appendRow(data.headers);
        return _jsonResponse({ status: 'ok', message: 'Table initialized' });
      }
      return _jsonResponse({ status: 'ok', message: 'Table already exists' });
    }

    // ── Register new member ─────────────────────────────────────
    if (data.action === 'register') {
      // Create header row if sheet is empty
      if (sheet.getLastRow() === 0) {
        sheet.appendRow(data.headers);
      }
      sheet.appendRow(data.values);
      return _jsonResponse({ status: 'ok', message: 'Registered successfully' });
    }

    // ── Fetch all members ───────────────────────────────────────
    if (data.action === 'getAll') {
      const rows = sheet.getDataRange().getValues();
      if (rows.length <= 1) {
        return _jsonResponse({ status: 'ok', members: [] });
      }
      const headers = rows[0];
      const members = rows.slice(1).map(row => {
        const obj = {};
        headers.forEach((h, i) => obj[h] = row[i]);
        return obj;
      });
      return _jsonResponse({ status: 'ok', members: members });
    }

    // ── Update member status ────────────────────────────────────
    if (data.action === 'updateStatus') {
      const rows = sheet.getDataRange().getValues();
      const headers = rows[0];
      const gmailIdx = headers.indexOf('Gmail');
      const statusIdx = headers.indexOf('Status');

      if (gmailIdx === -1 || statusIdx === -1) {
        return _jsonResponse({ status: 'error', message: 'Headers not found' });
      }

      let updated = false;
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][gmailIdx] === data.gmail) {
          sheet.getRange(i + 1, statusIdx + 1).setValue(data.newStatus);
          updated = true;
          break;
        }
      }
      return _jsonResponse({
        status: updated ? 'ok' : 'not_found',
        message: updated ? 'Status updated' : 'User not found',
      });
    }

    // ── Check member by Gmail ───────────────────────────────────
    if (data.action === 'checkUser') {
      const rows = sheet.getDataRange().getValues();
      const headers = rows[0];
      const gmailIdx = headers.indexOf('Gmail');

      for (let i = 1; i < rows.length; i++) {
        if (rows[i][gmailIdx] === data.gmail) {
          const obj = {};
          headers.forEach((h, idx) => obj[h] = rows[i][idx]);
          return _jsonResponse({ status: 'ok', found: true, user: obj });
        }
      }
      return _jsonResponse({ status: 'ok', found: false });
    }

    // ── Add Admin to Admins sheet ───────────────────────────────
    if (data.action === 'addAdmin') {
      const adminSheet = ss.getSheetByName(SHEET_NAMES.ADMINS);
      if (!adminSheet) {
        return _jsonResponse({ status: 'error', message: 'Admins sheet not found' });
      }

      // Check if admin already exists
      const rows = adminSheet.getDataRange().getValues();
      if (rows.length > 1) {
        const headers = rows[0];
        const gmailIdx = headers.indexOf('Gmail');
        for (let i = 1; i < rows.length; i++) {
          if (rows[i][gmailIdx] === data.gmail) {
            return _jsonResponse({ status: 'ok', message: 'Admin already exists' });
          }
        }
      }

      // Add new admin
      adminSheet.appendRow([
        data.name,
        data.gmail,
        data.passwordHash,
        data.role,
        data.villageCode || '',
        _toThailandTime()
      ]);
      return _jsonResponse({ status: 'ok', message: 'Admin added successfully' });
    }

    // ── Get all admins from Admins sheet ────────────────────────
    if (data.action === 'getAllAdmins') {
      const adminSheet = ss.getSheetByName(SHEET_NAMES.ADMINS);
      if (!adminSheet) {
        return _jsonResponse({ status: 'error', message: 'Admins sheet not found' });
      }

      const rows = adminSheet.getDataRange().getValues();
      if (rows.length <= 1) {
        return _jsonResponse({ status: 'ok', admins: [] });
      }
      const headers = rows[0];
      const admins = rows.slice(1).map(row => {
        const obj = {};
        headers.forEach((h, i) => obj[h] = row[i]);
        return obj;
      });
      return _jsonResponse({ status: 'ok', admins: admins });
    }

    // ── Delete admin from Admins sheet ──────────────────────────
    if (data.action === 'deleteAdmin') {
      const adminSheet = ss.getSheetByName(SHEET_NAMES.ADMINS);
      if (!adminSheet) {
        return _jsonResponse({ status: 'error', message: 'Admins sheet not found' });
      }

      const rows = adminSheet.getDataRange().getValues();
      const headers = rows[0];
      const gmailIdx = headers.indexOf('Gmail');

      if (gmailIdx === -1) {
        return _jsonResponse({ status: 'error', message: 'Gmail column not found' });
      }

      let deleted = false;
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][gmailIdx] === data.gmail) {
          adminSheet.deleteRow(i + 1);
          deleted = true;
          break;
        }
      }
      return _jsonResponse({
        status: deleted ? 'ok' : 'not_found',
        message: deleted ? 'Admin deleted successfully' : 'Admin not found',
      });
    }

    return _jsonResponse({ status: 'error', message: 'Unknown action' });
  } catch (err) {
    return _jsonResponse({ status: 'error', message: err.toString() });
  }
}

// Initialize all required sheets
function _initializeSheets(ss) {
  const requiredSheets = [
    { name: SHEET_NAMES.TRANSACTIONS, headers: ['ID', 'EquipmentID', 'UserGmail', 'BorrowDate', 'ReturnDate', 'ActualReturnDate', 'Status', 'Notes'] },
    { name: SHEET_NAMES.EQUIPMENT, headers: ['ID', 'Name', 'Description', 'Category', 'Quantity', 'Available', 'Status', 'CreatedAt'] },
    { name: SHEET_NAMES.USERS, headers: ['Name', 'Gmail', 'Address', 'VillageCode', 'PasswordHash', 'Latitude', 'Longitude', 'Status', 'RegisteredAt'] },
    { name: SHEET_NAMES.ADMINS, headers: ['Name', 'Gmail', 'PasswordHash', 'Role', 'VillageCode', 'CreatedAt'] }
  ];

  requiredSheets.forEach((sheetConfig, index) => {
    let sheet = ss.getSheetByName(sheetConfig.name);
    if (!sheet) {
      // Create new sheet
      sheet = ss.insertSheet(sheetConfig.name, index);
      // Add headers
      sheet.appendRow(sheetConfig.headers);
      // Format header row
      const headerRange = sheet.getRange(1, 1, 1, sheetConfig.headers.length);
      headerRange.setFontWeight('bold');
      headerRange.setBackground('#4285f4');
      headerRange.setFontColor('#ffffff');
    }
  });

  // Delete default "Sheet1" if it exists and is empty
  const defaultSheet = ss.getSheetByName('ชีต1') || ss.getSheetByName('Sheet1');
  if (defaultSheet && defaultSheet.getLastRow() === 0) {
    ss.deleteSheet(defaultSheet);
  }
}

function _jsonResponse(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}

// Convert to Thailand timezone (GMT+7)
function _toThailandTime() {
  const now = new Date();
  const thailandTime = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Bangkok' }));
  return Utilities.formatDate(thailandTime, 'Asia/Bangkok', 'yyyy-MM-dd HH:mm:ss');
}