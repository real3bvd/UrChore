import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/avatar_choice.dart';
import '../../data/profile_avatar_options.dart';
import '../widgets/app_notification.dart';
import '../widgets/profile_avatar.dart';

class AvatarPickerScreen extends StatefulWidget {
  final String displayName;
  final AvatarChoice initialChoice;

  const AvatarPickerScreen({
    super.key,
    required this.displayName,
    this.initialChoice = const AvatarChoice(),
  });

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  late String _type;
  late String? _value;
  late String _colorHex;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialChoice.type;
    _value = widget.initialChoice.value;
    _colorHex = widget.initialChoice.colorHex;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _isPickingPhoto = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        imageQuality: 78,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _type = 'photo';
        _value = base64Encode(bytes);
      });
    } catch (error) {
      if (!mounted) return;
      showAppNotification(context, 'Could not open photos: $error');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose profile picture')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPickingPhoto
                ? null
                : () {
                    Navigator.pop(
                      context,
                      AvatarChoice(
                        type: _type,
                        value: _value,
                        colorHex: _colorHex,
                      ),
                    );
                  },
            child: const Text('Use this picture'),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ProfileAvatar(
                  name: widget.displayName,
                  avatarType: _type,
                  avatarValue: _value,
                  colorHex: _colorHex,
                  size: 112,
                  showBorder: true,
                ),
              ),
              const SizedBox(height: 28),
              Text('Default', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _AvatarOption(
                selected: _type == 'default',
                onTap: () => setState(() {
                  _type = 'default';
                  _value = null;
                }),
                child: Row(
                  children: [
                    ProfileAvatar(
                      name: widget.displayName,
                      size: 46,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Default profile',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (_type == 'default')
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Colored initial',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: ProfileAvatarOptions.colors.map((hex) {
                  final selected = _type == 'initials' && _colorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _type = 'initials';
                      _value = null;
                      _colorHex = hex;
                    }),
                    child: ProfileAvatar(
                      name: widget.displayName,
                      avatarType: 'initials',
                      colorHex: hex,
                      size: 52,
                      showBorder: selected,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              Text(
                'Your photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPickingPhoto
                          ? null
                          : () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPickingPhoto
                          ? null
                          : () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Hedgehog icons',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: ProfileAvatarOptions.hedgehogs.length,
                itemBuilder: (context, index) {
                  final asset = ProfileAvatarOptions.hedgehogs[index];
                  final selected = _type == 'hedgehog' && _value == asset;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _type = 'hedgehog';
                      _value = asset;
                    }),
                    child: ProfileAvatar(
                      name: widget.displayName,
                      avatarType: 'hedgehog',
                      avatarValue: asset,
                      size: 66,
                      showBorder: selected,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _AvatarOption({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
