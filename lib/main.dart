import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}

@immutable
class Person {
  final String uuid;
  final String name;
  final int age;

  Person({
    String? uuid,
    required this.name,
    required this.age,
  }) : uuid = uuid ?? const Uuid().v4();

  Person updated([String? name, int? age]) => Person(
        name: name ?? this.name,
        age: age ?? this.age,
        uuid: uuid,
      );

  String get displayName => '$name ($age years old)';

  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'Person(name: $name, age: $age, uuid: $uuid)';
}

class DataModel extends ChangeNotifier {
  final List<Person> _persons = [];

  int get count => _persons.length;

  UnmodifiableListView<Person> get persons => UnmodifiableListView(_persons);

  void add({required Person person}) {
    _persons.add(person);
    notifyListeners();
  }

  void remove({required Person person}) {
    _persons.remove(person);
    notifyListeners();
  }

  void update({required Person updatedPerson}) {
    final index = _persons.indexOf(updatedPerson);
    final oldPerson = _persons[index];

    if (oldPerson.name != updatedPerson.name || oldPerson.age != updatedPerson.age) {
      _persons[index] = oldPerson.updated(updatedPerson.name, updatedPerson.age);
      notifyListeners();
    }
  }
}

final personsProvider = ChangeNotifierProvider((_) => DataModel());

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Persons')),
    );
  }
}
