import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:velotask/models/tag.dart';
import 'package:velotask/models/todo.dart';
import 'package:velotask/utils/logger.dart';

class TagAlreadyExistsException implements Exception {
  final String name;
  TagAlreadyExistsException(this.name);
  @override
  String toString() => 'Tag "$name" already exists';
}

class TodoStorage {
  static TodoStorage? _instance;
  final String? directoryPath;

  factory TodoStorage({String? directoryPath}) {
    if (_instance == null || _instance!.directoryPath != directoryPath) {
      _instance = TodoStorage._internal(directoryPath: directoryPath);
    }
    return _instance!;
  }

  TodoStorage._internal({this.directoryPath});

  static Isar? _isar;
  static Completer<void>? _initCompleter;
  static List<Tag>? _tagCache;
  static String? _openedDirectoryPath;
  static final Logger _logger = AppLogger.getLogger('TodoStorage');

  Future<void> _init() async {
    Directory dir;
    if (directoryPath != null) {
      dir = Directory(directoryPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _logger.info('Using custom directory: ${dir.path}');
    } else {
      dir = await getApplicationDocumentsDirectory();
      _logger.info('Using default directory: ${dir.path}');
    }

    final targetPath = dir.path;
    if (_isar != null && _isar!.isOpen) {
      if (_openedDirectoryPath == targetPath) {
        return;
      }
      await _isar!.close();
      _isar = null;
      _initCompleter = null;
      _tagCache = null;
      _openedDirectoryPath = null;
      _logger.info('Reopening Isar for directory switch: $targetPath');
    }

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();
    try {
      _isar = await Isar.open([TodoSchema, TagSchema], directory: targetPath);
      _openedDirectoryPath = targetPath;
      _logger.info('Isar database initialized');
      _initCompleter!.complete();
    } catch (e, stack) {
      _initCompleter!.completeError(e, stack);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<List<Todo>> loadTodos() async {
    await _init();
    final todos = await _isar!.todos.where().findAll();
    // Pre-load tags for all todos to avoid lazy-loading during UI build
    for (final todo in todos) {
      await todo.tags.load();
    }
    _logger.info('Loaded ${todos.length} todos with tags pre-loaded');
    return todos;
  }

  Future<List<Tag>> loadTags() async {
    if (_tagCache != null) {
      _logger.fine('Returning cached tags (${_tagCache!.length})');
      return _tagCache!;
    }
    await _init();
    final tags = await _isar!.tags.where().findAll();
    _tagCache = tags;
    _logger.info('Loaded ${tags.length} tags from DB');
    return tags;
  }

  Future<void> addTag(Tag tag) async {
    await _init();
    // Prevent unique index violation by checking for existing tag name first
    final existing = await _isar!.tags
        .filter()
        .nameEqualTo(tag.name)
        .findFirst();
    if (existing != null) {
      // If tag exists, update its color if different and return
      if (existing.color != tag.color) {
        existing.color = tag.color;
        await _isar!.writeTxn(() async {
          await _isar!.tags.put(existing);
        });
        _tagCache = null; // Invalidate cache
        _logger.info('Updated existing tag: ${tag.name}');
      } else {
        _logger.info('Tag already exists: ${tag.name}');
        throw TagAlreadyExistsException(tag.name);
      }
      return;
    }

    await _isar!.writeTxn(() async {
      await _isar!.tags.put(tag);
    });
    _tagCache = null; // Invalidate cache
    _logger.info('Added new tag: ${tag.name}');
  }

  Future<void> deleteTag(Id id) async {
    await _init();
    await _isar!.writeTxn(() async {
      await _isar!.tags.delete(id);
    });
    _tagCache = null; // Invalidate cache
    _logger.info('Deleted tag with id: $id');
  }

  Future<void> addTodo(Todo todo) async {
    await _init();
    await _isar!.writeTxn(() async {
      await _isar!.todos.put(todo);
      await todo.tags.save();
    });
    _logger.info('Added new todo: ${todo.title}');
  }

  Future<void> updateTodo(Todo todo, {bool saveLinks = true}) async {
    await _init();
    await _isar!.writeTxn(() async {
      await _isar!.todos.put(todo);
      if (saveLinks) {
        await todo.tags.save();
      }
    });
    _logger.info('Updated todo: ${todo.title} (saveLinks: $saveLinks)');
  }

  Future<void> deleteTodo(Id id) async {
    await _init();
    await _isar!.writeTxn(() async {
      await _isar!.todos.delete(id);
    });
    _logger.info('Deleted todo with id: $id');
  }

  /// Close the shared Isar instance. Useful for tests to cleanup.
  static Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
    _initCompleter = null;
    _tagCache = null;
    _openedDirectoryPath = null;
    _instance = null;
  }
}
