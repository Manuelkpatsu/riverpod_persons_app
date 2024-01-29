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
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(personsProvider);

          return dataModel.persons.isNotEmpty
              ? ListView.builder(
                  itemCount: dataModel.count,
                  itemBuilder: (context, index) {
                    final person = dataModel.persons[index];
                    return ListTile(
                      onTap: () async {
                        final updatedPerson = await createOrUpdatePersonDialog(context, person);
                        if (updatedPerson != null) {
                          dataModel.update(updatedPerson: updatedPerson);
                        }
                      },
                      title: Text(person.displayName),
                      trailing: IconButton(
                        splashRadius: 20,
                        onPressed: () => dataModel.remove(person: person),
                        icon: const Icon(Icons.delete_rounded, color: Colors.red),
                      ),
                    );
                  },
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.people_alt_rounded, size: 60),
                    SizedBox(height: 10),
                    Text(
                      'There are no persons.\nClick on the button to add one.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final person = await createOrUpdatePersonDialog(context);
          if (person != null) {
            ref.read(personsProvider).add(person: person);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePersonDialog(BuildContext context, [Person? existingPerson]) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;

  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';

  return showDialog<Person?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create a person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Enter name here...'),
              onChanged: (value) => name = value,
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter age here...'),
              onChanged: (value) => age = int.tryParse(value),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (name != null && age != null) {
                if (existingPerson != null) {
                  // have existing person, update it
                  final newPerson = existingPerson.updated(name, age);
                  Navigator.of(context).pop(newPerson);
                } else {
                  // no existing person, create a new one
                  Navigator.of(context).pop(Person(name: name!, age: age!));
                }
              } else {
                // no name, or age or both
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
