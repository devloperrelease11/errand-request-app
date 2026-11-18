import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../providers/errand_provider.dart';

class CreateErrandScreen extends StatefulWidget {
  const CreateErrandScreen({super.key});

  @override
  State<CreateErrandScreen> createState() => _CreateErrandScreenState();
}

class _CreateErrandScreenState extends State<CreateErrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  String? _validate(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (text.length < 3) return '$label is too short';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      await context.read<ErrandProvider>().createErrand(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errand created')),
      );
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      _pickupController.clear();
      _dropoffController.clear();
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException
          ? error.message
          : 'Could not create the errand. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                validator: (value) => _validate(value, 'Title'),
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) => _validate(value, 'Description'),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pickupController,
                textInputAction: TextInputAction.next,
                validator: (value) => _validate(value, 'Pickup address'),
                decoration: const InputDecoration(labelText: 'Pickup address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dropoffController,
                textInputAction: TextInputAction.done,
                validator: (value) => _validate(value, 'Drop-off address'),
                decoration: const InputDecoration(labelText: 'Drop-off address'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Post errand'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
