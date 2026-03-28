import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/routes/app_routes.dart';

class AuthController {
  const AuthController();

  bool isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final pattern = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}");
    return pattern.hasMatch(value.trim());
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không đúng định dạng.';
      case 'user-disabled':
        return 'Tài khoản đã bị khóa.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';
      case 'wrong-password':
        return 'Mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'operation-not-allowed':
        return 'Đăng nhập chưa được bật.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (ít nhất 6 ký tự).';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Có lỗi xảy ra. Vui lòng thử lại.';
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
      return 'Vui lòng nhập email hợp lệ và mật khẩu.';
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
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  Future<String?> signup({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.trim().isEmpty || !isValidEmail(email) || password.isEmpty) {
      return 'Vui lòng nhập đầy đủ thông tin và email hợp lệ.';
    }

    if (password.length < 6) {
      return 'Mật khẩu phải ít nhất 6 ký tự.';
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
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  Future<String?> forgotPassword(String email) async {
    if (!isValidEmail(email)) {
      return 'Vui lòng nhập email hợp lệ.';
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  Future<String?> continueWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // Ensure the account chooser appears by signing out any previous
        // GoogleSignIn session first. This prevents automatic reuse of the
        // last-used account and lets the user pick a different one.
        await GoogleSignIn().signOut();
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          return 'Đăng nhập Google đã bị hủy.';
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return 'Có lỗi khi đăng nhập Google.';
    }
  }

  Future<String?> signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return 'Có lỗi khi đăng nhập ẩn danh.';
    }
  }

  Future<String?> resendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Không tìm thấy người dùng.';
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Gửi lại email xác minh thất bại.';
    } catch (_) {
      return 'Có lỗi khi gửi lại email xác minh.';
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<String?> updateProfile({String? displayName, String? photoUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Không tìm thấy người dùng.';
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
      return e.message ?? 'Cập nhật hồ sơ thất bại.';
    } catch (_) {
      return 'Có lỗi khi cập nhật hồ sơ.';
    }
  }

  Future<String?> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Không tìm thấy người dùng.';
    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Vui lòng đăng nhập lại trước khi xóa tài khoản.';
      }
      return e.message ?? 'Xóa tài khoản thất bại.';
    } catch (_) {
      return 'Có lỗi khi xóa tài khoản.';
    }
  }
}
