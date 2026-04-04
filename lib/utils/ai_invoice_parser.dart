import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// MIME gần đúng cho Gemini (ảnh từ camera/gallery).
String mimeTypeForXFile(XFile f) {
  final name = f.name.toLowerCase();
  final path = f.path.toLowerCase();
  for (final ext in ['.png', '.webp', '.gif', '.bmp']) {
    if (name.endsWith(ext) || path.endsWith(ext)) {
      return 'image/${ext.substring(1)}';
    }
  }
  return 'image/jpeg';
}

/// Lấy object JSON đầu tiên từ phản hồi AI (hỗ trợ khối ```json ... ```).
String? extractJsonObjectFromAiText(String text) {
  var s = text.trim();
  final fenced = RegExp(
    r'```(?:json)?\s*([\s\S]*?)```',
    multiLine: true,
    caseSensitive: false,
  );
  final fm = fenced.firstMatch(s);
  if (fm != null) {
    s = fm.group(1)!.trim();
  }
  final start = s.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        return s.substring(start, i + 1);
      }
    }
  }
  return null;
}

const _amountKeys = [
  'amount',
  'total',
  'total_amount',
  'tong',
  'tong_cong',
  'tong_tien',
  'Tổng',
  'tổng',
  'thanh_tien',
  'so_tien',
  'so_tien_thanh_toan',
];

const _titleKeys = [
  'title',
  'merchant',
  'ten_cua_hang',
  'ten',
  'noi_dung',
  'dich_vu',
  'ten_dich_vu',
];

const _categoryKeys = [
  'category',
  'loai',
  'phan_loai',
  'danh_muc',
];

dynamic _firstKey(Map<dynamic, dynamic> map, List<String> keys) {
  for (final k in keys) {
    if (map.containsKey(k) && map[k] != null) {
      return map[k];
    }
  }
  return null;
}

Map<String, dynamic> _asStringKeyedMap(dynamic m) {
  if (m is! Map) return {};
  return m.map((k, v) => MapEntry(k.toString(), v));
}

Map<dynamic, dynamic> _asDynamicMap(dynamic m) {
  if (m is! Map) return {};
  return Map<dynamic, dynamic>.from(m);
}

/// Số tiền VND: hỗ trợ int/double JSON, "27.256.680 đ", v.v.
int? parseVndAmount(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  final str = raw.toString().trim();
  final compact = str.replaceAll(RegExp(r'\s'), '');
  final n = num.tryParse(compact);
  if (n != null) return n.round();
  final digitsOnly = str.replaceAll(RegExp(r'[^\d]'), '');
  if (digitsOnly.isEmpty) return null;
  return int.tryParse(digitsOnly);
}

dynamic pickAmount(Map<String, dynamic> data) {
  final map = _asDynamicMap(data);
  final direct = _firstKey(map, _amountKeys);
  if (direct != null) return direct;
  for (final v in map.values) {
    if (v is Map) {
      final nested = _firstKey(_asDynamicMap(v), _amountKeys);
      if (nested != null) return nested;
    }
  }
  return null;
}

dynamic pickTitle(Map<String, dynamic> data) {
  final map = _asDynamicMap(data);
  final direct = _firstKey(map, _titleKeys);
  if (direct != null) return direct;
  for (final v in map.values) {
    if (v is Map) {
      final nested = _firstKey(_asDynamicMap(v), _titleKeys);
      if (nested != null) return nested;
    }
  }
  return null;
}

dynamic pickCategory(Map<String, dynamic> data) {
  final map = _asDynamicMap(data);
  final direct = _firstKey(map, _categoryKeys);
  if (direct != null) return direct;
  for (final v in map.values) {
    if (v is Map) {
      final nested = _firstKey(_asDynamicMap(v), _categoryKeys);
      if (nested != null) return nested;
    }
  }
  return null;
}

/// Gộp root + object `transaction` để không mất field nằm ở ngoài.
Map<String, dynamic> unwrapInvoicePayload(dynamic decoded) {
  if (decoded is! Map) {
    return {};
  }
  final root = _asStringKeyedMap(decoded);
  final inner = root['transaction'];
  if (inner is Map) {
    final out = Map<String, dynamic>.from(root);
    out.remove('transaction');
    out.addAll(_asStringKeyedMap(inner));
    return out;
  }
  return root;
}

/// Ghép title + note từ nhiều key có thể có trên hóa đơn.
String buildNoteFromInvoice(Map<String, dynamic> data) {
  final title = pickTitle(data)?.toString().trim() ?? '';
  final note = (data['note'] ?? data['ghi_chu'] ?? data['mo_ta'])?.toString().trim() ?? '';
  return [title, note].where((e) => e.isNotEmpty).join(' - ');
}

/// Khớp tên danh mục AI với danh sách cố định (không phân biệt hoa thường, bỏ khoảng trắng dư).
String? resolveCategoryName(String? raw, List<String> allowedNames) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  for (final n in allowedNames) {
    if (n.toLowerCase() == t.toLowerCase()) return n;
  }
  final flat = t.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  for (final n in allowedNames) {
    if (n.toLowerCase().replaceAll(RegExp(r'\s+'), '') == flat) return n;
  }
  return null;
}

/// decode an toàn sau khi trích chuỗi JSON.
Map<String, dynamic>? decodeInvoiceJson(String jsonStr) {
  final extracted = extractJsonObjectFromAiText(jsonStr) ?? jsonStr;
  try {
    final decoded = json.decode(extracted);
    if (decoded is! Map) return null;
    return unwrapInvoicePayload(decoded);
  } catch (_) {
    return null;
  }
}
