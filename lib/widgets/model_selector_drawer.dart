import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/ai_model.dart';

class ModelSelectorDrawer extends StatelessWidget {
  const ModelSelectorDrawer({super.key});

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
              "AI Models",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            accountEmail: const Text("Select Intelligence or Creativity"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                "AI",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Obx(() => ListView(
              padding: EdgeInsets.zero,
              children: AIModels.availableModels.map((model) {
                final isSelected = controller.currentModel.value.id == model.id;
                return ListTile(
                  leading: Text(
                    model.iconAsset,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    model.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Text(
                    model.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    controller.setModel(model);
                    Get.back(); // Close drawer
                  },
                );
              }).toList(),
            )),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Powered by Pollinations.ai",
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
