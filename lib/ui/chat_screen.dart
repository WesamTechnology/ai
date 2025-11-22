import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../widgets/model_selector_drawer.dart';

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

    return Scaffold(
      drawer: const ModelSelectorDrawer(),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('AI Assistant', style: TextStyle(fontSize: 18)),
            Obx(() => Text(
              controller.currentModel.value.name,
              style: TextStyle(
                fontSize: 12, 
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold
              ),
            )),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => controller.clearChat(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(controller.currentModel.value.iconAsset, style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text(
                        'Start chatting with ${controller.currentModel.value.name}',
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
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
          // Voice Button
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
          // Send Button
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
            
            // Display Image if available
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
                      child: Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          Text("Failed to load image", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )),
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
