import 'package:basicshare/components/modals/manual_access_qrcode.dart';
import 'package:basicshare/state/saved_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sizer/sizer.dart';

class ManualAccessPage extends ConsumerStatefulWidget {
  const ManualAccessPage({super.key});

  @override
  ManualAccessPageState createState() => ManualAccessPageState();
}

class ManualAccessPageState extends ConsumerState<ManualAccessPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _deviceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _cardController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccess() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notifier = ref.read(savedAccessProvider.notifier);
    final cardNumber = _cardController.text.trim();
    final deviceId = _deviceController.text.trim();
    var didSave = false;
    try {
      await notifier.addAccess(
        cardNumber: cardNumber,
        deviceId: deviceId,
      );
      didSave = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Accès enregistré pour plus tard"),
          backgroundColor: Colors.deepOrange,
        ),
      );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Champs invalides"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }

    if (didSave && mounted) {
      await _showAccessQrCode(cardNumber: cardNumber, deviceId: deviceId);
    }
  }

  void _prefillAccess(SavedAccess access) {
    _cardController.text = access.cardNumber;
    _deviceController.text = access.deviceId;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Informations pour la carte ${access.cardNumber} chargées dans le formulaire"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> _deleteAccess(String id) async {
    final notifier = ref.read(savedAccessProvider.notifier);
    await notifier.deleteAccess(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Accès supprimé"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _copyToClipboard(SavedAccess access) {
    Clipboard.setData(ClipboardData(
        text: "Carte: ${access.cardNumber} | Device ID: ${access.deviceId}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copié dans le presse-papiers"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showAccessQrCode({
    required String cardNumber,
    required String deviceId,
  }) async {
    await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    try {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          return ManualAccessQrcodeModal(
            cardNumber: cardNumber,
            deviceId: deviceId,
          );
        },
      );
    } finally {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedAccesses = ref.watch(savedAccessProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Accès manuels 🔐",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                "Renseigne un numéro de carte et un device ID. Sauvegarde-les pour les réutiliser plus tard lors du partage.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.sp,
                ),
              ),
              SizedBox(height: 3.h),
              _buildForm(),
              SizedBox(height: 4.h),
              Text(
                "Accès enregistrés",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.5.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              if (savedAccesses.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedAccesses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final access = savedAccesses[index];
                    return _buildAccessCard(access);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Numéro de carte",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          TextFormField(
            controller: _cardController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Le numéro de carte est requis";
              }
              if (value.trim().length < 6) {
                return "Le numéro semble trop court";
              }
              return null;
            },
            decoration: _inputDecoration("Ex: 1234567890"),
          ),
          SizedBox(height: 2.h),
          Text(
            "Device ID",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          TextFormField(
            controller: _deviceController,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Le device ID est requis";
              }
              if (value.trim().length < 8) {
                return "Le device ID semble trop court";
              }
              return null;
            },
            decoration: _inputDecoration("Ex: ABCD-1234"),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt, color: Colors.white),
              label: Text(
                _isSaving ? "Enregistrement..." : "Sauvegarder pour plus tard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(SavedAccess access) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAccessQrCode(
          cardNumber: access.cardNumber,
          deviceId: access.deviceId,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: Colors.deepOrange,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Carte ${access.cardNumber}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          access.deviceId,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(access),
                      icon: const Icon(Icons.copy),
                      label: const Text("Copier"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteAccess(access.id),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Supprimer"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 7.w,
            color: Colors.white38,
          ),
          SizedBox(height: 1.h),
          Text(
            "Aucun accès enregistré pour le moment.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.5.h),
          Text(
            "Crée ton premier duo carte/device pour l'avoir toujours sous la main.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
