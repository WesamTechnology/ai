import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../models/ai_model.dart';
import '../widgets/chat_history_drawer.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controller
    final ChatController controller = Get.put(ChatController());
    
    final TextEditingController textController = TextEditingController();
    final FocusNode focusNode = FocusNode();
    final ScrollController scrollController = ScrollController();

    void handleSubmitted(String text) {
      if (text.trim().isEmpty) return;
      textController.clear();
      focusNode.requestFocus(); // Keep focus
      
      // Scroll to bottom
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      controller.sendMessage(text);
    }

    void showModelSelector() {
      Get.bottomSheet(
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Select AI Model",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: AIModels.availableModels.map((model) {
                    return Obx(() {
                      final isSelected = controller.currentModel.value.id == model.id;
                      return ListTile(
                        leading: Text(model.iconAsset, style: const TextStyle(fontSize: 24)),
                        title: Text(model.name),
                        subtitle: Text(model.description, style: const TextStyle(fontSize: 12)),
                        trailing: isSelected 
                            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) 
                            : null,
                        onTap: () => controller.setModel(model),
                      );
                    });
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        isScrollControlled: true,
      );
    }

    return Scaffold(
      drawer: const ChatHistoryDrawer(),
      appBar: AppBar(
        title: GestureDetector(
          onTap: showModelSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => Text(
                  controller.currentModel.value.name,
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down, 
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => controller.startNewChat(),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: showModelSelector,
                          child: Column(
                            children: [
                              Text(controller.currentModel.value.iconAsset, style: const TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text(
                                'Using ${controller.currentModel.value.name}',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap here to change model',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  return _MessageBubble(message: message);
                },
              );
            }),
          ),
          Obx(() => controller.isLoading.value 
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : const SizedBox.shrink()
          ),
          _buildTextComposer(context, controller, textController, focusNode, handleSubmitted),
        ],
      ),
    );
  }

  Widget _buildTextComposer(
      BuildContext context, 
      ChatController controller, 
      TextEditingController textController, 
      FocusNode focusNode, 
      Function(String) onSubmitted
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                onSubmitted: onSubmitted,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type or use voice...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => CircleAvatar(
            radius: 24,
            backgroundColor: controller.isListening.value 
                ? Colors.redAccent 
                : Theme.of(context).colorScheme.secondaryContainer,
            child: IconButton(
              icon: Icon(
                controller.isListening.value ? Icons.mic : Icons.mic_none, 
                size: 24, 
                color: controller.isListening.value ? Colors.white : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              onPressed: () {
                if (controller.isListening.value) {
                  controller.stopListening();
                } else {
                  controller.startListening((text) {
                    textController.text = text;
                    onSubmitted(text);
                  });
                }
              },
            ),
          )),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
              onPressed: () => onSubmitted(textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 1),
              blurRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.modelName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  message.modelName!,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            if (!isUser)
              MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
                  code: TextStyle(
                    backgroundColor: colorScheme.surface,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
              )
            else
              Text(
                message.text,
                style: TextStyle(color: colorScheme.onPrimary, fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }
}
