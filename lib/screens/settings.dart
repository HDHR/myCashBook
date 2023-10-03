import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:myCashBook/models/user.dart';
import 'package:myCashBook/services/authentication_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({
    Key? key,
    required this.authService,
  }) : super(key: key);
  static const String routeName = '/settings';
  final AuthenticationService authService;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late User user = User(username: '', password: '');
  late bool _isFormEnabled = false;

  Future<void> loadUser() async {
    try {
      final loadedUser = await widget.authService.getCurrentUser();
      if (loadedUser != null) {
        setState(() {
          user = loadedUser;
          _isFormEnabled = true;
        });
      } else {
        setState(() {
          _isFormEnabled = false;
        });
      }
    } catch (e) {
      // Handle error loading transactions
    }
  }

  final _key = GlobalKey<FormState>();
  late ChangePasswordFormState _state;
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;

  void _onOldPasswordChanged() {
    setState(() {
      _state = _state.copyWith(
          oldPassword: OldPassword.dirty(_oldPasswordController.text));
    });
  }

  void _onNewPasswordChanged() {
    setState(() {
      _state = _state.copyWith(
        newPassword: NewPassword.dirty(_newPasswordController.text),
      );
    });
  }

  Future<void> _onSubmit() async {
    if (!_key.currentState!.validate()) return;

    setState(() {
      _state = _state.copyWith(status: FormzSubmissionStatus.inProgress);
    });

    late String passwordWrongMessage = '';

    try {
      await _submitForm();
      _state = _state.copyWith(status: FormzSubmissionStatus.success);
    } catch (e) {
      _state = _state.copyWith(status: FormzSubmissionStatus.failure);
      if (e.toString().contains('Wrong password')) {
        passwordWrongMessage = 'Old password is wrong';
      }
    }

    if (!mounted) return;

    setState(() {});

    FocusScope.of(context)
      ..nextFocus()
      ..unfocus();

    const successSnackBar = SnackBar(
      content: Text('Password changed successfully! 🎉'),
    );

    SnackBar failureSnackBar = SnackBar(
      content: Text('Failed to change password! 😢 $passwordWrongMessage'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      _state.status.isSuccess ? successSnackBar : failureSnackBar,
    );

    if (_state.status.isSuccess) {
      _resetForm();
    }
  }

  Future<void> _submitForm() async {
    final username = user.username;
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    final checkPasswordResult =
        await widget.authService.checkUserPassword(username, oldPassword);

    if (!checkPasswordResult) {
      setState(() {
        _state = _state.copyWith(
          oldPassword: OldPassword.dirty(_oldPasswordController.text),
          status: FormzSubmissionStatus.failure,
        );
      });
      throw Exception('Wrong password');
    }

    final changePasswordResult =
        await widget.authService.changePassword(username, newPassword);

    if (!changePasswordResult) {
      setState(() {
        _state = _state.copyWith(
          newPassword: NewPassword.dirty(_newPasswordController.text),
          status: FormzSubmissionStatus.failure,
        );
      });
      throw Exception('Failed to change password');
    }

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  void _resetForm() {
    _key.currentState!.reset();
    _oldPasswordController.clear();
    _newPasswordController.clear();
    setState(() => _state = const ChangePasswordFormState());
  }

  @override
  void initState() {
    super.initState();
    _state = const ChangePasswordFormState();
    _oldPasswordController =
        TextEditingController(text: _state.oldPassword.value)
          ..addListener(_onOldPasswordChanged);
    _newPasswordController =
        TextEditingController(text: _state.newPassword.value)
          ..addListener(_onNewPasswordChanged);
    loadUser().whenComplete(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
          icon: const Icon(Icons.home),
        ),
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: _key,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('changePasswordForm_oldPasswordInput'),
                      controller: _oldPasswordController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.lock),
                        labelText: 'Old Password',
                        errorMaxLines: 2,
                      ),
                      validator: (value) =>
                          _state.oldPassword.validator(value ?? '')?.text(),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('changePasswordForm_newPasswordInput'),
                      controller: _newPasswordController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.lock),
                        labelText: 'New Password',
                        errorMaxLines: 2,
                      ),
                      validator: (value) =>
                          _state.newPassword.validator(value ?? '')?.text(),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    if (_state.status.isInProgress)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        key: const Key('changePasswordForm_submit'),
                        onPressed: _isFormEnabled ? _onSubmit : null,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            _isFormEnabled ? Colors.yellow : Colors.grey,
                          ),
                        ),
                        child: const Text('Change Password'),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                ),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/profile.png'),
                      radius: 40,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Made with 💖 by:\n'
                        'Name: Harist Dani Hisyam R.\n'
                        'NIM: 1941720034\n'
                        'Date: 23 Sep 2023',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordFormState with FormzMixin {
  const ChangePasswordFormState({
    this.oldPassword = const OldPassword.pure(),
    this.newPassword = const NewPassword.pure(),
    this.status = FormzSubmissionStatus.initial,
  });

  final OldPassword oldPassword;
  final NewPassword newPassword;
  final FormzSubmissionStatus status;

  ChangePasswordFormState copyWith({
    OldPassword? oldPassword,
    NewPassword? newPassword,
    FormzSubmissionStatus? status,
  }) {
    return ChangePasswordFormState(
      oldPassword: oldPassword ?? this.oldPassword,
      newPassword: newPassword ?? this.newPassword,
      status: status ?? this.status,
    );
  }

  @override
  List<FormzInput<dynamic, dynamic>> get inputs => [oldPassword, newPassword];
}

enum OldPasswordValidationError { invalid, empty }

class OldPassword extends FormzInput<String, OldPasswordValidationError> {
  const OldPassword.pure([super.value = '']) : super.pure();

  const OldPassword.dirty([super.value = '']) : super.dirty();

  @override
  OldPasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return OldPasswordValidationError.empty;
    }
    return null;
  }
}

enum NewPasswordValidationError { invalid, empty }

class NewPassword extends FormzInput<String, NewPasswordValidationError> {
  const NewPassword.pure([super.value = '']) : super.pure();

  const NewPassword.dirty([super.value = '']) : super.dirty();

  @override
  NewPasswordValidationError? validator(String value) {
    if (value.isEmpty) {
      return NewPasswordValidationError.empty;
    }
    return null;
  }
}

extension on OldPasswordValidationError {
  String text() {
    switch (this) {
      case OldPasswordValidationError.invalid:
        return 'Old Invalid password, must be at least 8 characters';
      case OldPasswordValidationError.empty:
        return 'Old Password is required';
    }
  }
}

extension on NewPasswordValidationError {
  String text() {
    switch (this) {
      case NewPasswordValidationError.invalid:
        return 'New Invalid password, must be at least 8 characters';
      case NewPasswordValidationError.empty:
        return 'New Password is required';
    }
  }
}
