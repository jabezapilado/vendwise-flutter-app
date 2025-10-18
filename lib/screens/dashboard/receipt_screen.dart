import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vendwise/services/receipt_store.dart';
import 'package:vendwise/utils/app_haptics.dart';
import 'package:vendwise/widgets/app_navigation_drawer.dart';
import 'package:vendwise/widgets/app_overlays.dart';
import 'package:vendwise/widgets/primary_app_bar.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  Future<void> _downloadReceiptAsJpg(TransactionReceipt receipt) async {
    try {
      AppHaptics.selectionChanged();
      final renderObject = _receiptKey.currentContext?.findRenderObject();
      if (renderObject == null) {
        if (!mounted) return;
        showQuickMessage(context, 'Unable to capture receipt');
        return;
      }
      if (renderObject is! RenderRepaintBoundary) {
        if (!mounted) return;
        showQuickMessage(context, 'Unable to capture receipt');
        return;
      }

      final boundary = renderObject;
      // If the receipt is scrollable or taller than the screen, render it off-screen
      final ui.Image image = await _captureFullReceipt(boundary, receipt);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (!mounted) return;
        showQuickMessage(context, 'Failed to capture image');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final decoded = img_pkg.decodePng(pngBytes);
      if (decoded == null) {
        if (!mounted) return;
        showQuickMessage(context, 'Failed to convert image');
        return;
      }

      final jpgBytes = img_pkg.encodeJpg(decoded, quality: 90);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/receipt_${receipt.id}.jpg');
      await file.writeAsBytes(jpgBytes);

      // Try to save a persistent copy in the user's Downloads folder.
      String? savedPath;
      try {
        if (Platform.isAndroid) {
          // Save directly to the device's Downloads folder by copying the file.
          final status = await Permission.storage.request();
          if (status.isGranted) {
            savedPath = await _saveToDownloads(file, receipt.id);
          } else {
            savedPath = null;
          }
        } else if (Platform.isIOS) {
          // On iOS: open the share sheet to allow the user to save to Photos
          // (avoids adding a platform plugin that can cause Gradle issues).
          try {
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(file.path)],
                text: 'VendWise Receipt #${receipt.id}',
              ),
            );
            // Indicate the user can save from the share sheet; we don't have a
            // programmatic persistent path here.
            savedPath = null;
          } catch (_) {
            savedPath = null;
          }
        } else {
          // Desktop or other platforms: copy to Downloads if possible
          savedPath = await _saveToDownloads(file, receipt.id);
        }
      } catch (_) {
        savedPath = null;
      }

      if (!mounted) return;

      // Show a brief confirmation when the file is saved to a persistent location.
      if (savedPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Receipt saved to: $savedPath')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved to temporary folder')),
        );
      }

      // Also show a small 'Saved' confirmation even when opening the share sheet
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt ready to share')));

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'VendWise Receipt #${receipt.id}',
        ),
      );
    } catch (err, st) {
      // ignore: avoid_print
      print('Receipt capture error: $err\n$st');
      if (!mounted) return;
      showQuickMessage(context, 'An error occurred while saving the receipt');
    }
  }

  /// Captures the full receipt, even if it's larger than the on-screen boundary.
  /// If the on-screen boundary already contains the full content, this will
  /// simply return the rendered image from the existing boundary.
  Future<ui.Image> _captureFullReceipt(
    RenderRepaintBoundary boundary,
    TransactionReceipt receipt,
  ) async {
    // Simpler approach: use a higher pixelRatio to improve quality. Full
    // off-screen capture (including off-screen scrollable content) requires
    // rendering the widget to an offscreen pipeline which is more complex.
    try {
      final size = boundary.size;
      // If the receipt is tall, increase pixelRatio for better capture
      final pixelRatio = size.height > 1600 ? 2.0 : 3.0;
      return await boundary.toImage(pixelRatio: pixelRatio);
    } catch (_) {
      return await boundary.toImage(pixelRatio: 3.0);
    }
  }

  /// Attempts to copy [source] into a user-visible Downloads folder.
  /// Returns the saved file path on success, or null on failure.
  Future<String?> _saveToDownloads(File source, String receiptId) async {
    try {
      // Desktop platforms (macOS, linux, windows) have a downloads directory helper.
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final dest = File('${downloadsDir.path}/receipt_$receiptId.jpg');
          await source.copy(dest.path);
          return dest.path;
        }
      } catch (_) {
        // ignore and try platform-specific paths
      }

      // Android: try external storage 'Download' directory
      if (Platform.isAndroid) {
        try {
          final ext = await getExternalStorageDirectory();
          if (ext != null) {
            // On many Android devices the external storage root contains 'Download'
            final downloadDir = Directory('${ext.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            final dest = File('${downloadDir.path}/receipt_$receiptId.jpg');
            await source.copy(dest.path);
            return dest.path;
          }
        } catch (_) {
          // fallthrough
        }
      }

      // Fallback: no persistent save available
      return null;
    } catch (_) {
      return null;
    }
  }

  // Use a platform channel to request Android MediaStore saving (handles scoped storage)
  // (MediaStore path removed) Android now copies directly to Downloads.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Process Payment',
        section: AppSection.transactions,
      ),
      drawer: AppNavigationDrawer(
        current: AppSection.transactions,
        rootContext: context,
      ),
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: ValueListenableBuilder<TransactionReceipt?>(
          valueListenable: ReceiptStore.instance.currentReceipt,
          builder: (context, receipt, _) {
            if (receipt == null) {
              return _EmptyReceiptState(
                onReturn: () => Navigator.of(context).pop(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackBreadcrumb(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(height: 8),
                  const Text(
                    'Receipt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: _receiptKey,
                    child: _ReceiptCard(receipt: receipt),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _downloadReceiptAsJpg(receipt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111C51),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Download Receipt (JPG)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        AppHaptics.selectionChanged();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111C51),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Back to Transaction',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt});

  final TransactionReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
    final timestamp = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(receipt.timestamp.toLocal());
    final customerName = (receipt.customerName ?? '').trim().isEmpty
        ? 'Walk-in customer'
        : receipt.customerName!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'VendWise',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '#1 Holy Angels Street, 2009',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
            const Text(
              'Pampanga',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'Receipt #${receipt.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              timestamp,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            const Text(
              'CASH RECEIPT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            _KeyValueRow(label: 'Customer', value: customerName),
            const SizedBox(height: 16),
            const _SectionHeader(),
            ...receipt.items.map(
              (item) => _ReceiptLineRow(
                description: item.quantity > 1
                    ? '${item.name} ×${item.quantity}'
                    : item.name,
                amount: currency.format(item.lineTotal),
              ),
            ),
            if (receipt.addons.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Add-ons',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ...receipt.addons.map(
                (addon) => _ReceiptLineRow(
                  description: addon.name,
                  amount: currency.format(addon.price),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 12),
            _ReceiptTotalRow(
              label: 'Subtotal',
              amount: currency.format(receipt.subtotal),
            ),
            _ReceiptTotalRow(
              label: 'Tax (12%)',
              amount: currency.format(receipt.tax),
            ),
            const Divider(color: Colors.black87, thickness: 1),
            _ReceiptTotalRow(
              label: 'Total',
              amount: currency.format(receipt.total),
              emphasize: true,
            ),
            const SizedBox(height: 8),
            _ReceiptTotalRow(
              label: 'Cash',
              amount: currency.format(receipt.cashTendered),
            ),
            _ReceiptTotalRow(
              label: 'Change',
              amount: currency.format(receipt.change),
            ),
            const SizedBox(height: 16),
            const _DottedDivider(),
            const SizedBox(height: 16),
            const Text(
              'THANK YOU!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBreadcrumb extends StatelessWidget {
  const _BackBreadcrumb({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selectionChanged();
        onPressed();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_back_ios_new, color: Color(0xFFADADAD), size: 20),
          SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              color: Color(0xFFADADAD),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Description',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'Price',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReceiptLineRow extends StatelessWidget {
  const _ReceiptLineRow({required this.description, required this.amount});

  final String description;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReceiptTotalRow extends StatelessWidget {
  const _ReceiptTotalRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(amount, style: style),
        ],
      ),
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashWidth = 4.0;
        final dashHeight = 1.4;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black87),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyReceiptState extends StatelessWidget {
  const _EmptyReceiptState({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No receipt to show',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete a transaction to generate a receipt.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onReturn,
              child: const Text('Back to transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
