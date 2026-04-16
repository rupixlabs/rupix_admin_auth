/// Defines the authentication role for the rupix_auth package.
/// This determines which authentication flow and UI to display.
enum AuthRole {
  /// Admin role - Shows only Email/Password login (no sign-up options).
  /// Used by partner admin apps like ashapura_admin_app.
  admin,

  /// User role - Shows full onboarding flow with Google, Email, and Phone options.
  /// Used by consumer apps like ashapura_user_app.
  user,
}

