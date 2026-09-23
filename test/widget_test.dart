import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rena_flow/controllers/auth_controller.dart';
import 'package:rena_flow/main.dart';

void main() {
  testWidgets('shows splash and navigates to sign in', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RenalFlowApp()));

    expect(find.text('RenalFlow'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email or Medical ID'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  test('validates credentials and toggles password visibility', () {
    final controller = AuthController();

    expect(controller.validate(), isFalse);
    expect(controller.state.identifierError, 'Email or Medical ID is required');
    expect(controller.state.passwordError, 'Password is required');

    controller.setIdentifier('MED-12345');
    controller.setPassword('secure-password');
    expect(controller.validate(), isTrue);

    expect(controller.state.isPasswordVisible, isFalse);
    controller.togglePasswordVisibility();
    expect(controller.state.isPasswordVisible, isTrue);
    controller.dispose();
  });
}
