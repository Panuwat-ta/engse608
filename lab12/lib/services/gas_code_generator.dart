// lib/services/gas_code_generator.dart
// Generates the Google Apps Script code for Admin to deploy

class GasCodeGenerator {
  /// Returns a complete Apps Script doPost() function body
  /// pre-filled with the given [spreadsheetId].
  static String generate(String spreadsheetId) {
    return r"""
// ════════════════════════════════════════════════════════════════
//  Community Tool Sharing — Google Apps Script Backend
//  วิธีใช้:
//  1. เปิด Google Sheet → Extensions → Apps Script
//  2. ลบโค้ดเดิมทั้งหมด แล้ววางโค้ดนี้
//  3. กด Deploy → Manage Deployments
//  4. คลิก Edit (ไอคอนดินสอ) ที่ deployment เดิม
//  5. เปลี่ยน Version เป็น "New version"
//  6. คลิก Deploy
//  7. ใช้ Web App URL เดิม (ไม่ต้องเปลี่ยน URL ในแอป)
// ════════════════════════════════════════════════════════════════

const SPREADSHEET_ID = '""" +
        spreadsheetId +
        r"""';

// Sheet names in Thai
const SHEET_NAMES = {
  EQUIPMENT: 'อุปกรณ์',
  TRANSACTIONS: 'รายการยืม',
  RETURNS: 'รายการคืน',
  USERS: 'สมาชิก',
  ADMINS: 'ผู้ดูแล'
};

function doGet(e) {
  // Handle GET requests (for redirects)
  return doPost(e);
}

function doPost(e) {
  try {
    let data;
    
    // Parse request data
    if (e.postData && e.postData.contents) {
      data = JSON.parse(e.postData.contents);
    } else if (e.parameter) {
      data = e.parameter;
    } else {
      return _jsonResponse({ status: 'error', message: 'No data provided' });
    }
    
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

    // ── Get all equipment from Equipment sheet ──────────────────
    if (data.action === 'getAllEquipment') {
      const equipmentSheet = ss.getSheetByName(SHEET_NAMES.EQUIPMENT);
      if (!equipmentSheet) {
        return _jsonResponse({ status: 'error', message: 'Equipment sheet not found' });
      }

      const rows = equipmentSheet.getDataRange().getValues();
      if (rows.length <= 1) {
        return _jsonResponse({ status: 'ok', equipment: [] });
      }
      const headers = rows[0];
      const equipment = rows.slice(1).map(row => {
        const obj = {};
        headers.forEach((h, i) => obj[h] = row[i]);
        return obj;
      });
      return _jsonResponse({ status: 'ok', equipment: equipment });
    }

    // ── Add equipment to Equipment sheet ────────────────────────
    if (data.action === 'addEquipment') {
      const equipmentSheet = ss.getSheetByName(SHEET_NAMES.EQUIPMENT);
      if (!equipmentSheet) {
        return _jsonResponse({ status: 'error', message: 'Equipment sheet not found' });
      }

      // Generate new ID
      const lastRow = equipmentSheet.getLastRow();
      const newId = lastRow > 1 ? equipmentSheet.getRange(lastRow, 1).getValue() + 1 : 1;

      const now = _toThailandTime();
      equipmentSheet.appendRow([
        newId,
        data.name || '',
        data.description || '',
        data.category || 'ทั่วไป',
        data.quantity || 1,
        data.available || data.quantity || 1,
        data.status || 'Available',
        now,
        data.updatedAt || now
      ]);
      return _jsonResponse({ status: 'ok', message: 'Equipment added successfully', id: newId });
    }

    // ── Update equipment in Equipment sheet ─────────────────────
    if (data.action === 'updateEquipment') {
      const equipmentSheet = ss.getSheetByName(SHEET_NAMES.EQUIPMENT);
      if (!equipmentSheet) {
        return _jsonResponse({ status: 'error', message: 'Equipment sheet not found' });
      }

      const rows = equipmentSheet.getDataRange().getValues();
      const headers = rows[0];
      const idIdx = headers.indexOf('ID');

      if (idIdx === -1) {
        return _jsonResponse({ status: 'error', message: 'ID column not found' });
      }

      let updated = false;
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][idIdx] == data.id) {
          const nameIdx = headers.indexOf('Name');
          const descIdx = headers.indexOf('Description');
          const catIdx = headers.indexOf('Category');
          const qtyIdx = headers.indexOf('Quantity');
          const availIdx = headers.indexOf('Available');
          const statusIdx = headers.indexOf('Status');
          const updatedAtIdx = headers.indexOf('UpdatedAt');

          // Conflict resolution: Compare timestamps if provided
          if (data.updatedAt && updatedAtIdx !== -1) {
            const sheetUpdatedAt = rows[i][updatedAtIdx];
            if (sheetUpdatedAt && new Date(sheetUpdatedAt) > new Date(data.updatedAt)) {
              // Sheet data is newer, reject update
              return _jsonResponse({
                status: 'conflict',
                message: 'Sheet data is newer than local data',
                sheetUpdatedAt: sheetUpdatedAt
              });
            }
          }

          if (data.name !== undefined && nameIdx !== -1) equipmentSheet.getRange(i + 1, nameIdx + 1).setValue(data.name);
          if (data.description !== undefined && descIdx !== -1) equipmentSheet.getRange(i + 1, descIdx + 1).setValue(data.description);
          if (data.category !== undefined && catIdx !== -1) equipmentSheet.getRange(i + 1, catIdx + 1).setValue(data.category);
          if (data.quantity !== undefined && qtyIdx !== -1) equipmentSheet.getRange(i + 1, qtyIdx + 1).setValue(data.quantity);
          if (data.available !== undefined && availIdx !== -1) equipmentSheet.getRange(i + 1, availIdx + 1).setValue(data.available);
          if (data.status !== undefined && statusIdx !== -1) equipmentSheet.getRange(i + 1, statusIdx + 1).setValue(data.status);
          
          // Update timestamp
          if (updatedAtIdx !== -1) {
            equipmentSheet.getRange(i + 1, updatedAtIdx + 1).setValue(_toThailandTime());
          }

          updated = true;
          break;
        }
      }
      return _jsonResponse({
        status: updated ? 'ok' : 'not_found',
        message: updated ? 'Equipment updated successfully' : 'Equipment not found',
      });
    }

    // ── Delete equipment from Equipment sheet ───────────────────
    if (data.action === 'deleteEquipment') {
      const equipmentSheet = ss.getSheetByName(SHEET_NAMES.EQUIPMENT);
      if (!equipmentSheet) {
        return _jsonResponse({ status: 'error', message: 'Equipment sheet not found' });
      }

      const rows = equipmentSheet.getDataRange().getValues();
      const headers = rows[0];
      const idIdx = headers.indexOf('ID');

      if (idIdx === -1) {
        return _jsonResponse({ status: 'error', message: 'ID column not found' });
      }

      let deleted = false;
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][idIdx] == data.id) {
          equipmentSheet.deleteRow(i + 1);
          deleted = true;
          break;
        }
      }
      return _jsonResponse({
        status: deleted ? 'ok' : 'not_found',
        message: deleted ? 'Equipment deleted successfully' : 'Equipment not found',
      });
    }

    // ── Get all transactions from Transactions sheet ────────────
    if (data.action === 'getAllTransactions') {
      const transactionSheet = ss.getSheetByName(SHEET_NAMES.TRANSACTIONS);
      if (!transactionSheet) {
        return _jsonResponse({ status: 'error', message: 'Transactions sheet not found' });
      }

      const rows = transactionSheet.getDataRange().getValues();
      if (rows.length <= 1) {
        return _jsonResponse({ status: 'ok', transactions: [] });
      }
      const headers = rows[0];
      const transactions = rows.slice(1).map(row => {
        const obj = {};
        headers.forEach((h, i) => obj[h] = row[i]);
        return obj;
      });
      return _jsonResponse({ status: 'ok', transactions: transactions });
    }

    // ── Add transaction to Transactions sheet ───────────────────
    if (data.action === 'addTransaction') {
      const transactionSheet = ss.getSheetByName(SHEET_NAMES.TRANSACTIONS);
      if (!transactionSheet) {
        return _jsonResponse({ status: 'error', message: 'Transactions sheet not found' });
      }

      // Generate new ID
      const lastRow = transactionSheet.getLastRow();
      const newId = lastRow > 1 ? transactionSheet.getRange(lastRow, 1).getValue() + 1 : 1;

      transactionSheet.appendRow([
        newId,
        data.equipmentId || '',
        data.userGmail || '',
        data.borrowDate || _toThailandTime(),
        data.returnDate || '',
        data.actualReturnDate || '',
        data.status || 'Borrowed',
        data.notes || ''
      ]);
      return _jsonResponse({ status: 'ok', message: 'Transaction added successfully', id: newId });
    }

    // ── Update transaction in Transactions sheet ────────────────
    if (data.action === 'updateTransaction') {
      const transactionSheet = ss.getSheetByName(SHEET_NAMES.TRANSACTIONS);
      if (!transactionSheet) {
        return _jsonResponse({ status: 'error', message: 'Transactions sheet not found' });
      }

      const rows = transactionSheet.getDataRange().getValues();
      const headers = rows[0];
      const idIdx = headers.indexOf('ID');

      if (idIdx === -1) {
        return _jsonResponse({ status: 'error', message: 'ID column not found' });
      }

      let updated = false;
      for (let i = 1; i < rows.length; i++) {
        if (rows[i][idIdx] == data.id) {
          const statusIdx = headers.indexOf('Status');
          const actualReturnDateIdx = headers.indexOf('ActualReturnDate');
          const notesIdx = headers.indexOf('Notes');

          if (data.status !== undefined && statusIdx !== -1) {
            transactionSheet.getRange(i + 1, statusIdx + 1).setValue(data.status);
          }
          if (data.actualReturnDate !== undefined && actualReturnDateIdx !== -1) {
            transactionSheet.getRange(i + 1, actualReturnDateIdx + 1).setValue(data.actualReturnDate);
          }
          if (data.notes !== undefined && notesIdx !== -1) {
            transactionSheet.getRange(i + 1, notesIdx + 1).setValue(data.notes);
          }

          updated = true;
          break;
        }
      }
      return _jsonResponse({
        status: updated ? 'ok' : 'not_found',
        message: updated ? 'Transaction updated successfully' : 'Transaction not found',
      });
    }

    // ── Record return in Returns sheet ──────────────────────────
    if (data.action === 'recordReturn') {
      const returnsSheet = ss.getSheetByName(SHEET_NAMES.RETURNS);
      if (!returnsSheet) {
        return _jsonResponse({ status: 'error', message: 'Returns sheet not found' });
      }

      // Calculate if overdue
      const returnDate = new Date(data.returnDate);
      const actualReturnDate = new Date(data.actualReturnDate || _toThailandTime());
      const isOverdue = actualReturnDate > returnDate ? 'Yes' : 'No';

      // Add return record with admin approval info
      returnsSheet.appendRow([
        data.id || '',
        data.transactionId || '',
        data.equipmentId || '',
        data.equipmentName || '',
        data.userGmail || '',
        data.userName || '',
        data.borrowDate || '',
        data.returnDate || '',
        data.actualReturnDate || _toThailandTime(),
        isOverdue,
        data.notes || '',
        data.approvedBy || '', // Admin who approved the return
        data.approvedAt || _toThailandTime(), // When admin approved
        _toThailandTime() // When record was created
      ]);

      return _jsonResponse({ status: 'ok', message: 'Return recorded successfully' });
    }

    return _jsonResponse({ status: 'error', message: 'Unknown action: ' + data.action });

  } catch (err) {
    return _jsonResponse({ status: 'error', message: err.toString() });
  }
}

// Initialize all required sheets
function _initializeSheets(ss) {
  const requiredSheets = [
    { name: SHEET_NAMES.EQUIPMENT, headers: ['ID', 'Name', 'Description', 'Category', 'Quantity', 'Available', 'Status', 'CreatedAt', 'UpdatedAt'] },
    { name: SHEET_NAMES.TRANSACTIONS, headers: ['ID', 'EquipmentID', 'UserGmail', 'BorrowDate', 'ReturnDate', 'ActualReturnDate', 'Status', 'Notes'] },
    { name: SHEET_NAMES.RETURNS, headers: ['ID', 'TransactionID', 'EquipmentID', 'EquipmentName', 'UserGmail', 'UserName', 'BorrowDate', 'ReturnDate', 'ActualReturnDate', 'Overdue', 'Notes', 'ApprovedBy', 'ApprovedAt', 'ReturnedAt'] },
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
    } else if (sheet.getLastRow() === 0) {
      // Sheet exists but is empty, add headers
      sheet.appendRow(sheetConfig.headers);
      const headerRange = sheet.getRange(1, 1, 1, sheetConfig.headers.length);
      headerRange.setFontWeight('bold');
      headerRange.setBackground('#4285f4');
      headerRange.setFontColor('#ffffff');
    }
  });

  // Delete default "Sheet1" if it exists and is empty
  const defaultSheet = ss.getSheetByName('ชีต1') || ss.getSheetByName('Sheet1');
  if (defaultSheet && defaultSheet.getLastRow() === 0 && ss.getSheets().length > 1) {
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
""";
  }
}
