import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final String? selectedEmoji;
  final ValueChanged<String> onEmojiSelected;

  static const emojis = [
    '🍕', '🍔', '🥗', '🍜', '☕', '🍺', '🎮', '👕', '👟',
    '🏠', '⚡', '📱', '🚗', '⛽', '✈️', '🏥', '📚', '💼',
    '🎬', '🎵', '💊', '🐾', '💇', '🏋️', '🎂', '🎁', '💻',
    '📦', '🏦', '💰', '💳', '📈', '🏆', '🎯', '💡', '❤️',
  ];

  const EmojiPicker({
    super.key,
    this.selectedEmoji,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: emojis.map((emoji) {
        final isSelected = selectedEmoji == emoji;

        return GestureDetector(
          onTap: () => onEmojiSelected(emoji),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
        );
      }).toList(),
    );
  }
}
