const SPREADSHEET_ID = '1Drhcf3oLNYRR3qXfb5Jy15kmTVF6baaumTkO6BZpLCs';
const RECEIPTS_FOLDER_NAME = 'receipts';
const JSON_FOLDER_NAME = 'json';
const SHEET_HEADERS = [
  'user_email', 'receipt_id', 'image_file', 'uploaded_at', 'amount',
  'transaction_type', 'merchant_name', 'transaction_date',
  'transaction_time', 'trx_id', 'category', 'latitude', 'longitude',
  'place_name', 'receipt_drive_file_id', 'receipt_drive_url',
  'json_drive_file_id', 'json_drive_url'
];

function doGet() {
  return jsonResponse({ok: true, service: 'hishabAI mobile API'});
}

function doPost(e) {
  try {
    const body = JSON.parse((e.postData && e.postData.contents) || '{}');
    const user = verifyGoogleUser(body.id_token);

    switch (body.action) {
      case 'extract':
        return jsonResponse({ok: true, transaction: extractTransaction(body)});
      case 'save':
        return jsonResponse({ok: true, receipt: saveTransaction(body, user.email)});
      case 'list':
        return jsonResponse({ok: true, receipts: listTransactions(user.email)});
      case 'detail':
        return jsonResponse(getTransactionDetail(body, user.email));
      default:
        throw new Error('Unknown API action.');
    }
  } catch (error) {
    console.error(error.stack || error);
    return jsonResponse({ok: false, error: String(error.message || error)});
  }
}

function verifyGoogleUser(idToken) {
  if (!idToken) throw new Error('Google sign-in is required.');

  const properties = PropertiesService.getScriptProperties();
  const expectedClientId = properties.getProperty('GOOGLE_WEB_CLIENT_ID');
  if (!expectedClientId) throw new Error('GOOGLE_WEB_CLIENT_ID is not configured.');

  const response = UrlFetchApp.fetch(
    'https://oauth2.googleapis.com/tokeninfo?id_token=' + encodeURIComponent(idToken),
    {muteHttpExceptions: true}
  );
  if (response.getResponseCode() !== 200) throw new Error('Invalid or expired Google sign-in.');

  const token = JSON.parse(response.getContentText());
  if (token.aud !== expectedClientId || token.email_verified !== 'true') {
    throw new Error('Google account could not be verified.');
  }
  return {email: token.email, name: token.name || '', picture: token.picture || ''};
}

function extractTransaction(body) {
  if (!body.image_base64 || !body.mime_type) throw new Error('Receipt image is missing.');

  const apiKey = PropertiesService.getScriptProperties().getProperty('GEMINI_API_KEY');
  if (!apiKey) throw new Error('GEMINI_API_KEY is not configured.');

  const prompt = [
    'Analyze this receipt or payment transaction image.',
    'Return only valid JSON with these keys:',
    'is_transaction, transaction_type, merchant_name, amount,',
    'transaction_date, transaction_time, trx_id.',
    'Use an empty string when a value is not visible.',
    'If this is not a receipt or payment transaction, set is_transaction to false.'
  ].join(' ');
  const endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/' +
    'gemini-2.5-flash:generateContent?key=' + encodeURIComponent(apiKey);
  const payload = {
    contents: [{parts: [
      {text: prompt},
      {inline_data: {mime_type: body.mime_type, data: body.image_base64}}
    ]}],
    generationConfig: {responseMimeType: 'application/json'}
  };
  const response = UrlFetchApp.fetch(endpoint, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  });
  if (response.getResponseCode() < 200 || response.getResponseCode() >= 300) {
    console.error(response.getContentText());
    throw new Error('Gemini could not analyze this image.');
  }

  const gemini = JSON.parse(response.getContentText());
  const text = gemini.candidates[0].content.parts[0].text;
  const transaction = JSON.parse(text);
  if (transaction.is_transaction === false) throw new Error('This does not look like a receipt or payment.');
  transaction.receipt_id = Utilities.getUuid();
  transaction.uploaded_at = new Date().toISOString();
  transaction.category = transaction.category || 'Other';
  return transaction;
}

function saveTransaction(body, userEmail) {
  const transaction = body.transaction || {};
  const receiptId = String(transaction.receipt_id || '');
  if (!receiptId || !body.image_base64 || !body.mime_type) throw new Error('Receipt data is incomplete.');

  const root = getRootFolder();
  const receiptsFolder = getChildFolder(root, RECEIPTS_FOLDER_NAME);
  const jsonFolder = getChildFolder(root, JSON_FOLDER_NAME);
  const extension = extensionForMime(body.mime_type);
  const imageName = receiptId + extension;
  const imageBlob = Utilities.newBlob(
    Utilities.base64Decode(body.image_base64), body.mime_type, imageName
  );
  const receiptFile = upsertFile(receiptsFolder, imageName, imageBlob);

  const record = {
    user_email: userEmail,
    receipt_id: receiptId,
    image_file: imageName,
    uploaded_at: String(transaction.uploaded_at || new Date().toISOString()),
    amount: clean(transaction.amount),
    transaction_type: clean(transaction.transaction_type),
    merchant_name: clean(transaction.merchant_name),
    transaction_date: clean(transaction.transaction_date),
    transaction_time: clean(transaction.transaction_time),
    trx_id: clean(transaction.trx_id),
    category: clean(transaction.category || 'Other'),
    latitude: null,
    longitude: null,
    place_name: null,
    receipt_drive_file_id: receiptFile.getId(),
    receipt_drive_url: receiptFile.getUrl()
  };

  const jsonName = receiptId + '.json';
  const jsonBlob = Utilities.newBlob(JSON.stringify(record, null, 2), 'application/json', jsonName);
  const jsonFile = upsertFile(jsonFolder, jsonName, jsonBlob);
  record.json_drive_file_id = jsonFile.getId();
  record.json_drive_url = jsonFile.getUrl();

  const sheet = getTransactionSheet();
  appendUniqueRow(sheet, record);
  return publicRecord(record);
}

function listTransactions(userEmail) {
  const sheet = getTransactionSheet();
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) return [];

  const headers = values[0];
  return values.slice(1).map(row => {
    const record = {};
    headers.forEach((header, index) => record[header] = row[index]);
    return record;
  }).filter(record => String(record.user_email).toLowerCase() === userEmail.toLowerCase())
    .slice(-100).reverse().map(publicRecord);
}

function getTransactionDetail(body, userEmail) {
  const receiptId = String(body.receipt_id || '');
  if (!receiptId) throw new Error('Receipt ID is required.');

  const record = findTransactionForUser(receiptId, userEmail);
  const fileId = String(record.receipt_drive_file_id || '');
  if (!fileId) throw new Error('Receipt image is missing.');

  const file = DriveApp.getFileById(fileId);
  const blob = file.getBlob();
  return {
    ok: true,
    receipt: publicRecord(record),
    image_base64: Utilities.base64Encode(blob.getBytes()),
    mime_type: file.getMimeType() || blob.getContentType() || 'image/jpeg'
  };
}

function findTransactionForUser(receiptId, userEmail) {
  const sheet = getTransactionSheet();
  const values = sheet.getDataRange().getValues();
  if (values.length < 2) throw new Error('Receipt was not found.');

  const headers = values[0];
  for (let index = 1; index < values.length; index++) {
    const record = {};
    headers.forEach((header, column) => record[header] = values[index][column]);
    if (
      String(record.receipt_id) === receiptId &&
      String(record.user_email).toLowerCase() === userEmail.toLowerCase()
    ) {
      return record;
    }
  }
  throw new Error('Receipt was not found.');
}

function getRootFolder() {
  const id = PropertiesService.getScriptProperties().getProperty('ROOT_FOLDER_ID');
  if (!id) throw new Error('ROOT_FOLDER_ID is not configured.');
  return DriveApp.getFolderById(id);
}

function getChildFolder(root, name) {
  const folders = root.getFoldersByName(name);
  if (!folders.hasNext()) throw new Error("The '" + name + "' Drive folder was not found.");
  return folders.next();
}

function getTransactionSheet() {
  const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
  const sheet = spreadsheet.getSheets()[0];
  if (sheet.getLastRow() === 0) sheet.appendRow(SHEET_HEADERS);
  return sheet;
}

function upsertFile(folder, name, blob) {
  const files = folder.getFilesByName(name);
  while (files.hasNext()) files.next().setTrashed(true);
  return folder.createFile(blob);
}

function appendUniqueRow(sheet, record) {
  const values = sheet.getDataRange().getValues();
  const idColumn = SHEET_HEADERS.indexOf('receipt_id');
  if (values.slice(1).some(row => String(row[idColumn]) === record.receipt_id)) return;
  sheet.appendRow(SHEET_HEADERS.map(header => record[header] == null ? '' : record[header]));
}

function publicRecord(record) {
  return {
    receipt_id: String(record.receipt_id || ''),
    uploaded_at: String(record.uploaded_at || ''),
    amount: String(record.amount || ''),
    transaction_type: String(record.transaction_type || ''),
    merchant_name: String(record.merchant_name || ''),
    transaction_date: String(record.transaction_date || ''),
    transaction_time: String(record.transaction_time || ''),
    trx_id: String(record.trx_id || ''),
    category: String(record.category || 'Other')
  };
}

function extensionForMime(mime) {
  if (mime === 'image/png') return '.png';
  if (mime === 'image/webp') return '.webp';
  return '.jpg';
}

function clean(value) {
  return value == null ? '' : String(value).trim();
}

function jsonResponse(value) {
  return ContentService.createTextOutput(JSON.stringify(value))
    .setMimeType(ContentService.MimeType.JSON);
}
