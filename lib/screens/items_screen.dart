import 'package:flutter/material.dart';

import '../api_service.dart';
import '../models/items.dart';

class ItemsScreen extends StatefulWidget {
  final String userId;

  const ItemsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late Future<List<Item>> futureItems;

  @override
  void initState() {
    super.initState();

    futureItems = ApiService().fetchItems(widget.userId);
  }

  Future<void> _refreshItems() async {
    final newFuture = ApiService().fetchItems(widget.userId);

    setState(() {
      futureItems = newFuture;
    });

    // Wait until the new data has been fetched before ending the refresh.
    await newFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Life Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshItems,
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: futureItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(
              child: Text("No reminders found"),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshItems,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(item: items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({
    super.key,
    required this.item,
  });

  Color get statusColor {
    switch (item.status) {
      case "completed":
        return Colors.green;

      case "pending":
        return Colors.orange;

      default:
        return Colors.blueGrey;
    }
  }

  IconData get icon {
    switch (item.type) {
      case "bill":
        return Icons.receipt_long;

      case "subscription":
        return Icons.subscriptions;

      case "payment":
        return Icons.payments;

      case "booking":
        return Icons.flight;

      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [

            CircleAvatar(
              radius: 26,
              child: Icon(icon),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item.billerName ?? "",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (item.amount != null)
                    Text(
                      "₹${item.amount}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                  const SizedBox(height: 8),

                  Text(
                    "Due : ${item.dueDate ?? "-"}",
                  ),
                ],
              ),
            ),

            Column(
              children: [

                Chip(
                  label: Text(item.status),
                  backgroundColor:
                  statusColor.withValues(alpha: .15),
                  labelStyle: TextStyle(
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  item.type.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}