import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import 'package:intl/intl.dart';

class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: const Text(
              "Wesam Ai",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            accountEmail: const Text("Your conversations"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage("images/wesam.png"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                controller.startNewChat();
                Get.back(); // Close drawer
              },
              icon: const Icon(Icons.add),
              label: const Text("New Chat"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.sessions.isEmpty) {
                return const Center(
                  child: Text("No history yet", style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: controller.sessions.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = controller.sessions[index];
                  final isSelected = session.id == controller.currentSessionId.value;
                  
                  return ListTile(
                    tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(session.lastModified),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () {
                        Get.defaultDialog(
                          title: "Delete Chat",
                          middleText: "Are you sure you want to delete this conversation?",
                          textConfirm: "Delete",
                          textCancel: "Cancel",
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            controller.deleteSession(session.id);
                            Get.back(); // Close dialog
                          },
                        );
                      },
                    ),
                    onTap: () => controller.loadSession(session),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
