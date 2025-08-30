import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/thought.dart';

final thoughtsBoxProvider = Provider<Box<Thought>>((_) => throw UnimplementedError('Hive not ready'));

final searchQueryProvider = StateProvider<String>((_) => '');
final tagFilterProvider   = StateProvider<List<String>>((_) => <String>[]);

enum SortMode { newest, oldest, longest, bestMatch }
final sortModeProvider    = StateProvider<SortMode>((_) => SortMode.newest);

enum SearchMode { keyword, semantic }
final searchModeProvider = StateProvider<SearchMode>((_) => SearchMode.keyword);

final transcriptionKeyOverrideProvider = StateProvider<String?>((_) => null);
final embeddingKeyOverrideProvider     = StateProvider<String?>((_) => null);
