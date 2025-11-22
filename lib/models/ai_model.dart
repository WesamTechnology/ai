class AIModel {
  final String id;
  final String name;
  final String description;
  final String iconAsset;
  final bool isImageGenerator;

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconAsset,
    this.isImageGenerator = false,
  });
}

class AIModels {
  static const List<AIModel> availableModels = [
    AIModel(
      id: 'openai',
      name: 'GPT-4o (Free)',
      description: 'Smartest model for chat & code.',
      iconAsset: '🧠',
    ),
    AIModel(
      id: 'mistral',
      name: 'Mistral Large',
      description: 'Fast and reliable.',
      iconAsset: '🌪️',
    ),
    AIModel(
      id: 'llama',
      name: 'Llama 3',
      description: 'Meta\'s latest model.',
      iconAsset: '🦙',
    ),
    AIModel(
      id: 'searchgpt',
      name: 'Search GPT',
      description: 'Web browsing capability.',
      iconAsset: '🌐',
    ),
    AIModel(
      id: 'flux', // Using flux for image generation
      name: 'Flux Image Gen',
      description: 'Generate amazing images.',
      iconAsset: '🎨',
      isImageGenerator: true,
    ),
  ];
}
