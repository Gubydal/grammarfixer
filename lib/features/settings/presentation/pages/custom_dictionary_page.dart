import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design/app_colors.dart';
import '../../../../design/app_icons.dart';
import '../../../../design/components/app_button.dart';
import '../../../correction/presentation/cubits/custom_dictionary_cubit.dart';

class CustomDictionaryPage extends StatefulWidget {
  const CustomDictionaryPage({super.key});

  @override
  State<CustomDictionaryPage> createState() => _CustomDictionaryPageState();
}

class _CustomDictionaryPageState extends State<CustomDictionaryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddWordDialog(BuildContext context) {
    final wordController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Add Custom Word'),
          content: TextField(
            controller: wordController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Mogate, ChatGPT, Kubernetes',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final word = wordController.text.trim();
                if (word.isNotEmpty) {
                  context.read<CustomDictionaryCubit>().addWord(word);
                  Navigator.of(dialogCtx).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Dictionary'),
        actions: [
          IconButton(
            icon: const AppIcon(AppIcons.trash, size: 20),
            tooltip: 'Clear All Words',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text('Clear Custom Dictionary?'),
                  content: const Text('This will remove all custom words. This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        context.read<CustomDictionaryCubit>().clearAll();
                        Navigator.pop(dCtx);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (q) => context.read<CustomDictionaryCubit>().search(q),
                decoration: InputDecoration(
                  hintText: 'Search custom words…',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppIcon(AppIcons.search, size: 18),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const AppIcon(AppIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CustomDictionaryCubit>().search('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<CustomDictionaryCubit, CustomDictionaryState>(
                  builder: (context, state) {
                    final words = state.filteredWords;

                    if (words.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.bookmark, size: 36, color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(
                              state.searchQuery.isEmpty
                                  ? 'No custom words added yet.'
                                  : 'No matching words found.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Words added to your dictionary are stored locally and will never be flagged as spelling errors.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: words.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final word = words[index];
                        return ListTile(
                          title: Text(
                            word,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const AppIcon(AppIcons.trash, size: 18),
                            onPressed: () {
                              context.read<CustomDictionaryCubit>().removeWord(word);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Add New Word',
                icon: AppIcons.edit,
                onPressed: () => _showAddWordDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
