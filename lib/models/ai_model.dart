class AIModel {
  final String id;
  final String name;
  final String description;
  final String iconAsset; // We will use emojis for simplicity or icons

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
  });
}

class AIModels {
  static const List<AIModel> availableModels = [
    AIModel(
      id: 'openai',
      name: 'GPT-4o (Free)',
      description: 'Smartest model, great for general tasks and coding.',
      iconAsset: '🧠',
    ),
    AIModel(
      id: 'mistral',
      name: 'Mistral Large',
      description: 'High performance open-source model.',
      iconAsset: '🌪️',
    ),
    AIModel(
      id: 'llama',
      name: 'Llama 3',
      description: 'Meta\'s latest powerful model.',
      iconAsset: '🦙',
    ),
    AIModel(
      id: 'searchgpt',
      name: 'Search GPT',
      description: 'Has access to real-time internet data.',
      iconAsset: '🌐',
    ),
  ];
}
