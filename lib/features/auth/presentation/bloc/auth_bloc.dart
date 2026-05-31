import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  AuthBloc({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn(),
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);

    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthResetPasswordRequested>(_onResetPassword);

    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onCheck(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(email: user.email ?? ''));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password.trim(),
      );

      emit(AuthAuthenticated(email: cred.user?.email ?? event.email.trim()));
    } on FirebaseAuthException catch (e) {
      //  Better messages
      final code = e.code;

      String msg;
      if (code == 'user-not-found') {
        msg = 'No Account found. Pehle Sign Up create new account.';
      } else if (code == 'wrong-password' || code == 'invalid-credential') {
        msg = 'Wrong Password . Forgot password try again.';
      } else if (code == 'invalid-email') {
        msg = 'Wrong  Email format please try again.';
      } else if (code == 'too-many-requests') {
        msg = 'Too many attempts. Please try again later.';
      } else {
        msg = e.message ?? e.code;
      }

      emit(AuthError(msg));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Something went wrong: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password.trim(),
      );
      emit(AuthAuthenticated(email: cred.user?.email ?? event.email.trim()));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? e.code));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Something went wrong: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onResetPassword(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email.trim());
      emit(const AuthPasswordResetSent());
      emit(const AuthUnauthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? e.code));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Something went wrong: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final googleUser = await _google.signIn();

      if (googleUser == null) {
        // user cancelled -> stop loader
        emit(const AuthUnauthenticated());
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);

      emit(AuthAuthenticated(email: cred.user?.email ?? ''));
    } on FirebaseAuthException catch (e) {
      emit(AuthError(e.message ?? e.code));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Google Sign-In failed: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _google.signOut();
    } catch (_) {}

    try {
      await _auth.signOut();
    } catch (_) {}

    emit(const AuthUnauthenticated());
  }
}
