import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({
    super.key,
  });

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'grocery-list-c6490-default-rtdb.firebaseio.com', 'grocery-list.json');

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later';
        });
      }
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (catItem) => catItem.value.title == item.value['category'],
            )
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItem = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went Wrong.\nCheck for Internet connection';
        _isLoading = false;
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removeGroceryItem(GroceryItem groceryItem) async {
    final groceryIndex = _groceryItem.indexOf(groceryItem);
    setState(() {
      _groceryItem.remove(groceryItem);
    });

    final url = Uri.https(
      'grocery-list-c6490-default-rtdb.firebaseio.com',
      'grocery-list/${groceryItem.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // If the delete request failed, add the item back to the list
      setState(() {
        _groceryItem.insert(groceryIndex, groceryItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete the item.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: const Text('Item deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final undoUrl = Uri.https(
                'grocery-list-c6490-default-rtdb.firebaseio.com',
                'grocery-list/${groceryItem.id}.json',
              );

              final response = await http.put(
                undoUrl,
                body: json.encode({
                  'name': groceryItem.name,
                  'quantity': groceryItem.quantity,
                  'category': groceryItem.category.title,
                }),
              );

              if (response.statusCode >= 400) {
                // If the re-insertion request failed, show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to undo the deletion.'),
                  ),
                );
              } else {
                // Re-add the item to the list if the re-insertion is successful
                setState(() {
                  _groceryItem.insert(groceryIndex, groceryItem);
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text('Nothing found. Start adding some!'),
    );

    if (_isLoading) {
      mainContent = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItem.isNotEmpty) {
      mainContent = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItem[index].id),
          onDismissed: (direction) {
            _removeGroceryItem(_groceryItem[index]);
          },
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(
              _groceryItem[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      mainContent = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: mainContent,
    );
  }
}


/*import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({
    super.key,
  });

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  late Future<List<GroceryItem>> _loadedItems;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'grocery-list-c6490-default-rtdb.firebaseio.com', 'grocery-list.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch data. Please try again later');
    }
    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removeGroceryItem(GroceryItem groceryItem) async {
    final groceryIndex = _groceryItem.indexOf(groceryItem);
    setState(() {
      _groceryItem.remove(groceryItem);
    });

    final url = Uri.https(
      'grocery-list-c6490-default-rtdb.firebaseio.com',
      'grocery-list/${groceryItem.id}.json',
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // If the delete request failed, add the item back to the list
      setState(() {
        _groceryItem.insert(groceryIndex, groceryItem);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete the item.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: const Text('Item deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final undoUrl = Uri.https(
                'grocery-list-c6490-default-rtdb.firebaseio.com',
                'grocery-list/${groceryItem.id}.json',
              );

              final response = await http.put(
                undoUrl,
                body: json.encode({
                  'name': groceryItem.name,
                  'quantity': groceryItem.quantity,
                  'category': groceryItem.category.title,
                }),
              );

              if (response.statusCode >= 400) {
                // If the re-insertion request failed, show an error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to undo the deletion.'),
                  ),
                );
              } else {
                // Re-add the item to the list if the re-insertion is successful
                setState(() {
                  _groceryItem.insert(groceryIndex, groceryItem);
                });
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nothing found. Start adding some!'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              onDismissed: (direction) {
                _removeGroceryItem(snapshot.data![index]);
              },
              child: ListTile(
                title: Text(snapshot.data![index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: snapshot.data![index].category.color,
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
*/