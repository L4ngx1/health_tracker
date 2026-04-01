import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/localization/locale_service.dart';
import '../core/routes/app_routes.dart';
import '../l10n/app_localizations.dart';

class AuthController {
  const AuthController();

  AppLocalizations get _l10n =>
      lookupAppLocalizations(LocaleService.instance.locale.value);

  static bool _googleInitialized = false;

  // Web client ID from Firebase (see android/app/google-services.json -> oauth_client with client_type 3).
  // Needed on some Android setups to ensure an ID token is returned.
  static const String _googleServerClientId =
      '607294559860-4c9d2skv4vdd1rdffq42fovvtjketikd.apps.googleusercontent.com';

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }

  bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final pattern = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    return pattern.hasMatch(value.trim());
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return _l10n.authErrorInvalidEmailFormat;
      case 'user-disabled':
        return _l10n.authErrorUserDisabled;
      case 'user-not-found':
        return _l10n.authErrorUserNotFound;
      case 'wrong-password':
        return _l10n.authErrorWrongPassword;
      case 'email-already-in-use':
        return _l10n.authErrorEmailInUse;
      case 'operation-not-allowed':
        return _l10n.authErrorOperationNotAllowed;
      case 'weak-password':
        return _l10n.authErrorWeakPassword;
      case 'too-many-requests':
        return _l10n.authErrorTooManyRequests;
      default:
        return e.message ?? _l10n.authErrorGeneric;
    }
  }

  void toRegister(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  void toLogin(BuildContext context) {
    Navigator.of(context).pop();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    if (!isValidEmail(email) || password.isEmpty) {
      return _l10n.authErrorValidEmailPassword;
    }

    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (!(result.user?.emailVerified ?? false)) {
        // Keep the user authenticated and let MainNavigationScreen show UnverifiedScreen.
        return null;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return _l10n.authErrorGeneric;
    }
  }

  Future<String?> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.trim().isEmpty || !isValidEmail(email) || password.isEmpty) {
      return _l10n.authErrorCompleteInfo;
    }

    if (password.length < 6) {
      return _l10n.passwordTooShort;
    }

    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user?.updateDisplayName(fullName.trim());
      await result.user?.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return _l10n.authErrorGeneric;
    }
  }

  Future<String?> forgotPassword(String email) async {
    if (!isValidEmail(email)) {
      return _l10n.authErrorValidEmail;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return _l10n.authErrorGeneric;
    }
  }

  Future<String?> continueWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        if (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
          return _l10n.authErrorGoogleSupportedOnly;
        }
        await _ensureGoogleSignInInitialized();

        // Force account chooser to avoid silently reusing the previous account.
        await GoogleSignIn.instance.signOut();
        final googleUser = await GoogleSignIn.instance.authenticate();

        final googleAuth = googleUser.authentication;
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          return _l10n.authErrorGoogleNoIdToken;
        }
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      return null;
    } on GoogleSignInException catch (e) {
      debugPrint(
        _l10n.authLogGoogleSignInException(
          e.code.name,
          e.description ?? '',
          '${e.details ?? ''}',
        ),
      );
      switch (e.code) {
        case GoogleSignInExceptionCode.clientConfigurationError:
          return _l10n.authErrorGoogleConfig;
        case GoogleSignInExceptionCode.canceled:
          return _l10n.authErrorGoogleCanceled;
        case GoogleSignInExceptionCode.uiUnavailable:
          return _l10n.authErrorGoogleUiUnavailable;
        default:
          return _l10n.authErrorGoogleGeneral(e.description ?? e.code.name);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        _l10n.authLogGoogleFirebaseException(e.code, e.message ?? ''),
      );
      return _friendlyError(e);
    } on UnimplementedError {
      return _l10n.authErrorGoogleUnsupportedPlatform;
    } catch (e) {
      final raw = e.toString();
      debugPrint(_l10n.authLogGoogleSignInError(raw));
      if (raw.contains('INVALID_CERT_HASH') ||
          raw.contains('DEVELOPER_ERROR')) {
        return _l10n.authErrorGoogleShaMismatch;
      }
      if (raw.contains('canceled') || raw.contains('cancelled')) {
        return _l10n.authErrorGoogleCanceled;
      }
      return _l10n.authErrorGoogleGeneral(raw);
    }
  }

  Future<String?> signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return _l10n.authErrorAnonymous;
    }
  }

  Future<String?> resendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _l10n.authErrorUserMissing;
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? _l10n.authErrorResendVerificationFailed;
    } catch (_) {
      return _l10n.authErrorResendVerificationGeneric;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> updateProfile({String? displayName, String? photoUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _l10n.authErrorUserMissing;
    try {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? _l10n.authErrorUpdateProfileFailed;
    } catch (_) {
      return _l10n.authErrorUpdateProfileGeneric;
    }
  }

  Future<String?> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _l10n.authErrorUserMissing;
    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return _l10n.authErrorDeleteRequiresRelogin;
      }
      return e.message ?? _l10n.authErrorDeleteFailed;
    } catch (_) {
      return _l10n.authErrorDeleteGeneric;
    }
  }
}
