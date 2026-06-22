import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../services/receipt_store.dart';
import '../theme/app_theme.dart';
import 'review_receipt_screen.dart';

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key, required this.store});

  final ReceiptStore store;

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _mimeType = 'image/jpeg';
  bool _extracting = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
      _error = null;
    });
  }

  Future<void> _extract() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() {
      _extracting = true;
      _error = null;
    });
    try {
      final receipt = await widget.store.api.extract(
        imageBytes: bytes,
        mimeType: _mimeType,
      );
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ReviewReceiptScreen(
            receipt: receipt,
            imageBytes: bytes,
            mimeType: _mimeType,
            store: widget.store,
          ),
        ),
      );
      if (saved == true && mounted) setState(() => _imageBytes = null);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Add a receipt',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Take a clear photo or choose an existing image.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          Container(
            height: 260,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD8D5CD), width: 1.5),
            ),
            child: _imageBytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.paleGold,
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 34,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Receipt preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your selected image will appear here',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  )
                : Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _extracting
                      ? null
                      : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _extracting
                      ? null
                      : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.coral),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _imageBytes == null || _extracting ? null : _extract,
            icon: _extracting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _extracting ? 'Reading receipt...' : 'Extract transaction',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Review AI-extracted details before anything is saved.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
