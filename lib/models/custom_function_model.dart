import 'package:get_storage/get_storage.dart';

class CustomFunctionModel {
  final String id;
  final String name;
  final String code;
  final int createdAt;
  final int updatedAt;

  CustomFunctionModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory CustomFunctionModel.fromJson(Map<String, dynamic> json) =>
      CustomFunctionModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        createdAt: json['created_at'] as int,
        updatedAt: json['updated_at'] as int,
      );
}

class CustomFunctionService {
  static final CustomFunctionService _instance = CustomFunctionService._();
  static CustomFunctionService get to => _instance;
  CustomFunctionService._();

  static const _key = '__DEUP_CUSTOM_FUNCTIONS__';
  static const _seenKey = '__DEUP_CUSTOM_FUNCTIONS_SEEN__';
  final _box = GetStorage();

  bool get hasSeen => _box.read<bool>(_seenKey) == true;

  void markSeen() {
    _box.write(_seenKey, true);
  }

  List<CustomFunctionModel> getAll() {
    final data = _box.read<List>(_key) ?? [];
    return data
        .map((e) => CustomFunctionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<CustomFunctionModel> list) async {
    await _box.write(_key, list.map((e) => e.toJson()).toList());
  }

  Future<void> add(CustomFunctionModel func) async {
    final list = getAll();
    list.add(func);
    await _save(list);
  }

  Future<void> update(CustomFunctionModel func) async {
    final list = getAll();
    final index = list.indexWhere((f) => f.id == func.id);
    if (index != -1) {
      list[index] = func;
      await _save(list);
    }
  }

  Future<void> remove(String id) async {
    final list = getAll()..removeWhere((f) => f.id == id);
    await _save(list);
  }

  CustomFunctionModel? findByName(String name) {
    final list = getAll();
    try {
      return list.firstWhere((f) => f.name == name);
    } catch (_) {
      return null;
    }
  }

  String generateScript() {
    final functions = getAll();
    if (functions.isEmpty) return '';
    return functions
        .map((f) => '${f.code}\n\$custom.${f.name} = ${f.name};')
        .join('\n\n');
  }

  void clear() {
    _box.remove(_key);
  }

  Future<void> seedDefaults() async {
    if (hasSeen) return;

    final existing = getAll();
    if (existing.any((f) => f.name == 'alert')) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    await add(CustomFunctionModel(
      id: 'default_alert',
      name: 'alert',
      code: 'function alert(message) {\n  \$alert(message);\n}',
      createdAt: now,
      updatedAt: now,
    ));
  }
}
