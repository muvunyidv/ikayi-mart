# UBMS Migration & Implementation Blueprint

## Universal Authentication (Login, Registration, Google Sign-In)

**Source:** IKAYIMART (`d:\Projects\Ikayi-mart`)  
**Target:** UBMS (sister application)  
**Purpose:** Replicate the complete auth stack — Flutter UI widgets, form validation, Provider state, JWT persistence, and NestJS/Prisma APIs — as a clean, self-contained module.

This document describes **what is actually implemented in IKAYIMART today**, not a hypothetical design. Adaptation notes for UBMS (naming, branding, optional vendor flows) are called out in each section and summarized in the replication checklist.

---

## 0. Architecture at a glance

```
┌─────────────────────────────────────────────────────────────────┐
│ Flutter (UBMS / IKAYIMART)                                      │
│  AuthScreen  ──►  AuthState (Provider / ChangeNotifier)         │
│  ShopHeader  ──►  IkayiApi.login / register / google / me       │
│  GIS button  ──►  GoogleSignIn ──► ID token                     │
│  SharedPreferences: ikayi_jwt + avatar keys                     │
│  ApiClient attaches Authorization: Bearer <token>               │
└────────────────────────────┬────────────────────────────────────┘
                             │  POST /api/v1/auth/*
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ NestJS  (global prefix api/v1, global JwtAuthGuard + RolesGuard)│
│  AuthController  →  AuthService                                 │
│    register        bcrypt.hash(password, 12) + role CUSTOMER    │
│    register-vendor bcrypt.hash + role VENDOR + Vendor row       │
│    login           bcrypt.compare, issue JWT                    │
│    google          OAuth2Client.verifyIdToken (native)          │
│    me              JWT required, return public profile          │
│  JwtStrategy  ExtractJwt.fromAuthHeaderAsBearerToken()          │
│  Prisma User.password is nullable (Google-only accounts)        │
└─────────────────────────────────────────────────────────────────┘
```

**Global API prefix:** `api/v1` (set in `backend/src/main.ts`).  
**Auth controller path:** `@Controller('auth')`.  
**Full paths:** `/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/google`, `/api/v1/auth/me`.

**Auth UI is a full-page screen at `/login`**, not a Flutter `Dialog`. Header, checkout sheet, and vendor shell all navigate to that screen (or reuse `AuthScreen` inline). Treat `/login` as the universal auth surface.

---

## 1. File inventory (copy these first)

### 1.1 Flutter — core auth module (required)

| Path | Role |
|------|------|
| `frontend/lib/features/auth/screens/auth_screen.dart` | Universal Login / Register screen (shopper + vendor toggle) |
| `frontend/lib/features/vendor/screens/vendor_login_screen.dart` | Thin wrapper: `AuthScreen(vendorContext: true)` |
| `frontend/lib/state/auth_state.dart` | Provider `ChangeNotifier` — restore, login, register, Google, logout |
| `frontend/lib/core/utils/rwanda_phone.dart` | Regex, normalize to `+2507XXXXXXXX`, `FormField` validator |
| `frontend/lib/core/utils/password_rules.dart` | Live strength rules + `FormField` validator |
| `frontend/lib/core/widgets/password_strength_meter.dart` | Visual checklist widget |
| `frontend/lib/core/widgets/widgets.dart` | Barrel export (includes password meter) |
| `frontend/lib/features/vendor/widgets/google_sign_in_button.dart` | Cross-platform Google button + G logo painter |
| `frontend/lib/features/vendor/widgets/gis_sign_in_button.dart` | Non-web stub (`gisWebSignInButton` → `null`) |
| `frontend/lib/features/vendor/widgets/gis_sign_in_button_web.dart` | Official GIS button (Flutter web) |
| `frontend/lib/core/api/api_client.dart` | HTTP client, Bearer header |
| `frontend/lib/core/api/api_config.dart` | `API_BASE_URL`, `GOOGLE_CLIENT_ID` dart-defines |
| `frontend/lib/core/api/api_exception.dart` | Typed API error |
| `frontend/lib/core/api/ikayi_api.dart` | Auth methods (`login`, `register`, `loginWithGoogle`, `me`, …) |
| `frontend/lib/core/models/models.dart` | `VendorUser` profile model (`fromJson`, `isVendorStaff`) |
| `frontend/lib/core/router/app_router.dart` | `/login` route |
| `frontend/lib/main.dart` | `AuthState.restore()` before `runApp`, `ChangeNotifierProvider` |

### 1.2 Flutter — auth consumers (copy if UBMS has the same surfaces)

| Path | Role |
|------|------|
| `frontend/lib/features/shop/widgets/shop_header.dart` | Universal header icon: Sign-in vs Account dropdown |
| `frontend/lib/features/shop/widgets/checkout_choice_sheet.dart` | Checkout chooser: email login, Google, guest |
| `frontend/lib/features/shop/screens/order_success_screen.dart` | Post-checkout convert-guest + Google claim |
| `frontend/lib/features/shop/screens/checkout_screen.dart` | Prefills saved profile; normalizes phone on submit |
| `frontend/lib/features/shop/screens/my_orders_screen.dart` | Redirects to `/login?next=/orders` if logged out |
| `frontend/lib/features/vendor/screens/vendor_shell.dart` | Role gate: logged-out → vendor login; non-vendor → shop home |
| `frontend/lib/features/vendor/widgets/vendor_sidebar.dart` | Signed-in vendor profile footer |
| `frontend/web/index.html` | GIS / `GOOGLE_CLIENT_ID` comment (no extra script tag required) |

### 1.3 NestJS — auth module (required)

| Path | Role |
|------|------|
| `backend/src/auth/auth.module.ts` | JWT + Passport wiring |
| `backend/src/auth/auth.controller.ts` | Public + protected HTTP endpoints |
| `backend/src/auth/auth.service.ts` | Hashing, Google verify, JWT issue, role assignment |
| `backend/src/auth/dto/create-user.dto.ts` | Register shopper |
| `backend/src/auth/dto/login.dto.ts` | Email/password login |
| `backend/src/auth/dto/google-auth.dto.ts` | Google ID token (+ optional `orderId`) |
| `backend/src/auth/dto/register-vendor.dto.ts` | Extends `CreateUserDto` + `storeName` |
| `backend/src/auth/dto/convert-guest.dto.ts` | Guest-order → account (optional for UBMS) |
| `backend/src/auth/types/jwt-payload.ts` | `{ sub, email, role, vendorId }` |
| `backend/src/auth/strategies/jwt.strategy.ts` | Bearer JWT validation |
| `backend/src/common/constants/validation.ts` | Password + Rwanda phone regex |
| `backend/src/common/utils/rwanda-phone.ts` | Server-side normalize to `+2507XXXXXXXX` |
| `backend/src/common/decorators/is-rwanda-phone.decorator.ts` | Optional custom validator |
| `backend/src/common/decorators/public.decorator.ts` | Skip JWT on public routes |
| `backend/src/common/decorators/current-user.decorator.ts` | Inject `JwtPayload` |
| `backend/src/common/decorators/roles.decorator.ts` | `@Roles(UserRole.…)` |
| `backend/src/common/guards/jwt-auth.guard.ts` | Global JWT guard (honors `@Public()`) |
| `backend/src/common/guards/roles.guard.ts` | Global role guard |
| `backend/src/config/configuration.ts` | `googleClientId` from env |
| `backend/src/app.module.ts` | Registers `APP_GUARD` Jwt + Roles |
| `backend/src/main.ts` | `api/v1` prefix, `ValidationPipe`, CORS, Swagger |
| `backend/prisma/schema.prisma` | `User`, `UserRole`, nullable `password` |
| `backend/prisma/migrations/20260820120000_google_auth/migration.sql` | `CUSTOMER` role + nullable password |

### 1.4 Pub / npm packages that auth depends on

**Flutter (`frontend/pubspec.yaml`):**

```yaml
dependencies:
  provider: ^6.1.5+1
  http: ^1.5.0
  shared_preferences: ^2.5.3
  go_router: ^17.5.0
  google_sign_in: ^6.2.1
  google_sign_in_web: ^0.12.4
```

IKAYIMART does **not** use `flutter_secure_storage`. JWT + avatar URL are stored in `SharedPreferences`.

**NestJS (`backend/package.json`):**

```json
{
  "@nestjs/jwt": "^11.0.0",
  "@nestjs/passport": "^11.0.5",
  "passport": "^0.7.0",
  "passport-jwt": "^4.0.1",
  "bcrypt": "^6.0.0",
  "google-auth-library": "^11.0.2",
  "class-validator": "^0.14.2",
  "class-transformer": "^0.5.1",
  "libphonenumber-js": "^1.12.15"
}
```

---

## 2. Frontend widgets & UI components (Flutter)

### 2.1 Universal Login / Register screen

**File:** `frontend/lib/features/auth/screens/auth_screen.dart`  
**Route:** `/login` (`frontend/lib/core/router/app_router.dart`)  
**Vendor reuse:** `VendorLoginScreen` → `AuthScreen(vendorContext: true)`

This is a **centered card on a full page** (`ImigongoBackground` + `Scaffold` + `Card`, max width 420). It is not a `showDialog` / `AlertDialog`.

#### Widget tree

```
ImigongoBackground
 └─ Scaffold (transparent)
     ├─ AppBar?          // only when vendorContext == true ("Vendor Central")
     └─ Center
         └─ SingleChildScrollView
             └─ ConstrainedBox(maxWidth: 420)
                 └─ Card
                     └─ AutofillGroup
                         └─ Form
                             ├─ Title + subtitle
                             ├─ [register only] Name
                             ├─ [vendor register] Store name
                             ├─ [register only] Phone (Rwanda)
                             ├─ Email
                             ├─ Password
                             ├─ [register only] PasswordStrengthMeter
                             ├─ [register only] Confirm password
                             ├─ [shopper register] "I want to sell" checkbox + store name
                             ├─ ElevatedButton  Create account / Sign in
                             ├─ Divider "or"
                             ├─ GoogleSignInButton
                             └─ Toggle: Sign in ↔ Create an account
```

#### Mode flags

| Flag | Meaning |
|------|---------|
| `_registering` | `false` = login, `true` = register |
| `_vendorRegister` | Register creates a vendor store (`POST /auth/register-vendor`) |
| `widget.vendorContext` | Vendor Central chrome; hides the shopper “I want to sell” checkbox |
| `_busy` / `_googleBusy` | Disable form while email or Google request is in flight |

#### Post-auth routing

```dart
void _routeAfterAuth(AuthState auth) {
  final next = GoRouterState.of(context).uri.queryParameters['next'];
  if (auth.user?.isVendorStaff == true) {
    context.read<NavigationState>().setMode(AppMode.vendor);
    context.go('/vendor');
    return;
  }
  context.read<NavigationState>().setMode(AppMode.shopper);
  if (next != null && next.startsWith('/') && next != '/login') {
    context.go(next); // e.g. /login?next=/checkout or /login?next=/orders
    return;
  }
  context.go('/');
}
```

**UBMS:** keep the `?next=` deep-link pattern. Point vendor/admin users at the UBMS dashboard instead of `/vendor`.

---

### 2.2 Custom Rwandan phone number field

**Files:**

- `frontend/lib/core/utils/rwanda_phone.dart` — regex, normalize, validator
- Used in `auth_screen.dart` (register) and `checkout_screen.dart` (checkout)

#### Canonical regex

```dart
final rwandaPhonePattern = RegExp(r'^(?:\+250|250|0)?(7[2389]\d{7})$');
```

Accepted prefixes: `+250`, `250`, `0`, or none.  
Local mobile: `7` + **2, 3, 8, or 9** + 7 more digits (MTN 78/79, Airtel 72/73).

#### Canonical stored format

Always persist **`+2507XXXXXXXX`** (E.164 Rwanda mobile).

```dart
String compactRwandaPhone(String input) =>
    input.replaceAll(RegExp(r'[\s-]'), '');

String? normalizeRwandaPhone(String input) {
  final compact = compactRwandaPhone(input.trim());
  final match = rwandaPhonePattern.firstMatch(compact);
  if (match == null) return null;
  return '+250${match.group(1)}';
}

String? rwandaPhoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone is required';
  if (!isValidRwandaPhone(value)) {
    return 'Enter a valid Rwandan number (+250 7XX XXX XXX or 07XXXXXXXX)';
  }
  return null;
}
```

#### Field wiring on the auth form

```dart
TextFormField(
  controller: _phone,
  keyboardType: TextInputType.phone,
  textInputAction: TextInputAction.next,
  autofillHints: const [AutofillHints.telephoneNumber],
  decoration: const InputDecoration(
    labelText: 'Phone number',
    hintText: '+250 7XX XXX XXX',
    helperText: 'Rwandan mobile (MTN 78/79, Airtel 72/73)',
  ),
  validator: rwandaPhoneValidator,
),
```

On submit, IKAYIMART normalizes before the API call:

```dart
phone: normalizeRwandaPhone(_phone.text) ?? _phone.text.trim(),
```

The NestJS DTO also `@Transform`s the same way, so either client is sufficient. **Do both.**

#### Live auto-format (recommended for UBMS)

IKAYIMART currently normalizes **on submit**, not while typing (there is no `TextInputFormatter`). For UBMS, attach this formatter so the field snaps to `+2507XXXXXXXX` as soon as the number is valid:

```dart
import 'package:flutter/services.dart';
import 'rwanda_phone.dart';

class RwandaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizeRwandaPhone(newValue.text);
    if (normalized == null) return newValue;
    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }
}

// usage:
inputFormatters: [RwandaPhoneFormatter()],
```

Copy `rwanda_phone.dart` verbatim into UBMS (`lib/core/utils/rwanda_phone.dart`).

---

### 2.3 Live password strength meter

**Files:**

- `frontend/lib/core/utils/password_rules.dart`
- `frontend/lib/core/widgets/password_strength_meter.dart`

#### Policy (must match backend `STRONG_PASSWORD_REGEX`)

| Rule | Check |
|------|--------|
| Length | `password.length >= 8` |
| Uppercase | `[A-Z]` |
| Lowercase | `[a-z]` |
| Digit | `[0-9]` |
| Special | `[@$!%*?&]` |

Backend regex:

```ts
/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/
```

#### Evaluation + form validator

```dart
abstract final class PasswordRules {
  static final _upper = RegExp(r'[A-Z]');
  static final _lower = RegExp(r'[a-z]');
  static final _digit = RegExp(r'[0-9]');
  static final _special = RegExp(r'[@$!%*?&]');

  static PasswordStrength evaluate(String password) {
    return PasswordStrength([
      PasswordRule(label: 'At least 8 characters', met: password.length >= 8),
      PasswordRule(label: 'At least 1 uppercase letter (A-Z)', met: _upper.hasMatch(password)),
      PasswordRule(label: 'At least 1 lowercase letter (a-z)', met: _lower.hasMatch(password)),
      PasswordRule(label: 'At least 1 number (0-9)', met: _digit.hasMatch(password)),
      PasswordRule(label: 'At least 1 special character (@\$!%*?&)', met: _special.hasMatch(password)),
    ]);
  }

  static String? validator(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (!evaluate(value).isStrong) {
      return 'Password does not meet all requirements';
    }
    return null;
  }
}
```

#### Visual checklist

Green `Icons.check_circle` (`AppColors.success` `#28A745`) when met; red `Icons.cancel` (`AppColors.error` `#BA1A1A`) when not.

Auth screen rebuilds the meter on every keystroke:

```dart
_password.addListener(_onPasswordChanged);

void _onPasswordChanged() {
  if (_registering) setState(() {});
}

// in the Form:
TextFormField(
  controller: _password,
  obscureText: true,
  validator: _registering
      ? PasswordRules.validator
      : (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
),
if (_registering) PasswordStrengthMeter(password: _password.text),
```

Login only requires 8+ characters. Register requires the **full** strength policy, plus confirm-password match.

---

### 2.4 Google Sign-In button

IKAYIMART uses a **conditional import** so web gets the official Google Identity Services (GIS) button and mobile/desktop get a custom outlined button that calls `GoogleSignIn.signIn()`.

**Why two implementations:** on Flutter web, `GoogleSignIn.signIn()` hits the People API and fails when that API is disabled. The GIS button returns an ID token without People API.

```
google_sign_in_button.dart
  import gis_sign_in_button.dart
    if (dart.library.js_util) gis_sign_in_button_web.dart
```

#### Shared widget (`google_sign_in_button.dart`)

```dart
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.label = 'Sign in with Google',
  });

  final VoidCallback? onPressed;
  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final gis = gisWebSignInButton(onPressed: onPressed, busy: busy);
    if (gis != null) return gis; // web: official GIS button

    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      // white bg, custom G logo painter, label
      child: busy ? CircularProgressIndicator() : Row(children: [GLogo, Text(label)]),
    );
  }
}
```

#### Web GIS button (`gis_sign_in_button_web.dart`)

```dart
Widget? gisWebSignInButton({VoidCallback? onPressed, bool busy = false}) {
  return _GisWebSignInButton(onPressed: onPressed, busy: busy);
}

// Listens to AuthState.googleAccountChanges.
// When GIS returns an account, it calls onPressed → AuthState.loginWithGoogle().
gsi.renderButton(
  configuration: gsi.GSIButtonConfiguration(
    type: gsi.GSIButtonType.standard,
    theme: gsi.GSIButtonTheme.outline,
    size: gsi.GSIButtonSize.large,
    text: gsi.GSIButtonText.signinWith,
    shape: gsi.GSIButtonShape.rectangular,
    logoAlignment: gsi.GSIButtonLogoAlignment.left,
    minimumWidth: 320,
  ),
);
```

#### Client construction (`auth_state.dart`)

```dart
AuthState(this._api)
    : _googleSignIn = GoogleSignIn(
        scopes: kIsWeb ? const <String>[] : const ['email', 'profile'],
        clientId: kIsWeb && resolveGoogleClientId().isNotEmpty
            ? resolveGoogleClientId()
            : null,
        serverClientId: resolveGoogleClientId().isEmpty
            ? null
            : resolveGoogleClientId(),
      );
```

| Platform | How the ID token is obtained |
|----------|------------------------------|
| **Web** | GIS button → `onCurrentUserChanged` → `account.authentication.idToken` |
| **Android / iOS / desktop** | `_googleSignIn.signIn()` → same `idToken` |

The ID token is posted to `POST /api/v1/auth/google`. See §3.3.

**Google Cloud setup (must match backend `GOOGLE_CLIENT_ID`):**

1. Create an OAuth 2.0 **Web** client ID.
2. Pass it to Flutter: `--dart-define=GOOGLE_CLIENT_ID=….apps.googleusercontent.com`
3. Set the same value as NestJS `GOOGLE_CLIENT_ID` (token audience).
4. Authorized JavaScript origins: UBMS web origin (and `http://localhost:…` for local).
5. Authorized redirect URIs: GIS default (no custom redirect needed for the GIS button).
6. Do **not** add extra OAuth scopes on web (People API).

---

### 2.5 Universal auth header icon

**File:** `frontend/lib/features/shop/widgets/shop_header.dart`  
**Logic:** `context.watch<AuthState>()` then branch on `auth.isLoggedIn`.

```
ShopHeader (persistent storefront header)
 ├─ Brand
 ├─ Search
 ├─ Cart
 ├─ Track order
 └─ Auth control:
     ├─ NOT logged in → IconButton(Icons.person_outline) → context.go('/login')
     └─ Logged in     → PopupMenuButton (_AccountMenuButton)
                         ├─ Disabled header: user.name + user.email
                         ├─ My Orders        → /orders
                         ├─ Vendor dashboard → /vendor  (only if isVendorStaff)
                         └─ Log out          → auth.logout() then go('/')
```

#### Logged-out branch

```dart
if (auth.isLoggedIn)
  _AccountMenuButton(auth: auth)
else
  IconButton(
    tooltip: 'Sign in / Register',
    onPressed: () => context.go('/login'),
    icon: const Icon(Icons.person_outline),
  ),
```

#### Logged-in branch (avatar + dropdown)

The trigger is a circular avatar (`_UserAvatar`): Google photo URL from `auth.avatarUrl` if present, otherwise a person icon on `AppColors.primaryLight`.

```dart
enum _AccountAction { myOrders, vendorDashboard, logout }

PopupMenuButton<_AccountAction>(
  tooltip: 'Account',
  offset: const Offset(0, 40),
  onSelected: (action) async {
    switch (action) {
      case _AccountAction.myOrders:
        context.go('/orders');
      case _AccountAction.vendorDashboard:
        context.read<NavigationState>().setMode(AppMode.vendor);
        context.go('/vendor');
      case _AccountAction.logout:
        await auth.logout();
        if (!context.mounted) return;
        context.read<NavigationState>().setMode(AppMode.shopper);
        context.go('/');
    }
  },
  // items: name/email header, My Orders, optional Vendor dashboard, Log out
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: _UserAvatar(photoUrl: auth.avatarUrl),
  ),
);
```

**UBMS mapping:** keep the same switch. Replace “My Orders” / “Vendor dashboard” with UBMS destinations (e.g. Profile, My requests, Admin console). Keep logout identical.

---

## 3. State management & API integration (Flutter)

### 3.1 Strategy: Provider + `ChangeNotifier` (not Bloc / Riverpod / GetX)

`AuthState` is registered once in `main.dart` and restored **before** `runApp`:

```dart
final api = IkayiApi();
final auth = AuthState(api);
await auth.restore();
runApp(IkayiMartApp(api: api, auth: auth, catalog: catalog));

// inside IkayiMartApp:
ChangeNotifierProvider<AuthState>.value(value: widget.auth),
Provider<IkayiApi>.value(value: widget.api),
```

There is **no explicit enum**. Map IKAYIMART fields onto the four logical states:

| Logical state | How to detect | What is true |
|---------------|----------------|--------------|
| **Unauthenticated** | `!restoring && user == null` | No JWT, header shows person icon |
| **Authenticating** | UI `_busy` / `_googleBusy`, or `restore()` with `restoring == true` | Request in flight; `error` cleared |
| **Authenticated** | `isLoggedIn` (`user != null` && token non-empty) | JWT in memory + SharedPreferences |
| **AuthError** | `error != null` after a failed login/register/Google | SnackBar shows `auth.error` |

```dart
bool get isLoggedIn =>
    user != null && (_api.client.token?.isNotEmpty ?? false);
```

**UBMS:** you may add an explicit enum without changing behavior:

```dart
enum AuthStatus { unauthenticated, authenticating, authenticated, error }

AuthStatus get status {
  if (restoring) return AuthStatus.authenticating;
  if (user != null && (_api.client.token?.isNotEmpty ?? false)) {
    return AuthStatus.authenticated;
  }
  if (error != null) return AuthStatus.error;
  return AuthStatus.unauthenticated;
}
```

### 3.2 HTTP payload contracts

Base URL: `resolveApiBaseUrl()` → `{origin}/api/v1`.  
All bodies are JSON. Success shape is identical for register, login, Google, convert-guest.

#### Shared success response (`201`/`200`)

```json
{
  "accessToken": "<jwt>",
  "tokenType": "Bearer",
  "user": {
    "id": "uuid",
    "email": "aline.uwase@gmail.com",
    "name": "Aline Uwase",
    "role": "CUSTOMER",
    "phone": "+250788123456",
    "district": null,
    "sector": null,
    "landmark": null,
    "vendorId": null,
    "storeName": null,
    "isVerified": null,
    "isOnline": null,
    "vendor": null,
    "createdAt": "2026-08-20T12:00:00.000Z"
  }
}
```

`role` is `CUSTOMER` | `VENDOR` | `ADMIN`.  
Vendor register / vendor login fills `vendorId`, `storeName`, `isVerified`, `isOnline`, and nested `vendor`.

JWT claims (`JwtPayload`):

```ts
{ sub: userId, email, role, vendorId: string | null }
```

Default expiry: `JWT_EXPIRES_IN` or `7d`.

---

#### `POST /api/v1/auth/register`

**Purpose:** Create a shopper (`UserRole.CUSTOMER`).  
**Auth:** `@Public()`.

Request:

```json
{
  "name": "Aline Uwase",
  "email": "aline.uwase@gmail.com",
  "phone": "+250788123456",
  "password": "ShopperPass123!"
}
```

| Field | Validation |
|-------|------------|
| `name` | string, 2–80 chars |
| `email` | valid email (lowercased + trimmed server-side) |
| `phone` | Rwanda mobile; transformed to `+2507XXXXXXXX` |
| `password` | 8–72 chars, must match `STRONG_PASSWORD_REGEX` |

Flutter call:

```dart
await client.post('/auth/register', body: {
  'email': email,
  'password': password,
  'name': name,
  'phone': phone,
});
```

Errors: `409 Email is already registered`, `400` validation / invalid phone.

---

#### `POST /api/v1/auth/login`

**Purpose:** Email + password. Works for CUSTOMER, VENDOR, and ADMIN. Role is read from the existing `User` row (not chosen by the client).  
**Auth:** `@Public()`.

Request:

```json
{
  "email": "jean.paul@kigalitech.rw",
  "password": "VendorPass123!"
}
```

| Field | Validation |
|-------|------------|
| `email` | valid email |
| `password` | string, min 8 (strength **not** re-checked on login) |

Flutter call:

```dart
await client.post('/auth/login', body: {
  'email': email,
  'password': password,
});
```

Errors: `401 Invalid credentials` — also returned when `user.password` is `null` (Google-only account). Prompt those users to use Google Sign-In.

---

#### `POST /api/v1/auth/google`

**Purpose:** Verify Google ID token; find-or-create user; issue JWT.  
**Auth:** `@Public()`.

Request:

```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
  "orderId": "optional-uuid-of-guest-order"
}
```

| Field | Validation |
|-------|------------|
| `idToken` | non-empty string (Google Sign-In ID token) |
| `orderId` | optional UUID — attach a guest order after sign-in |

Flutter call:

```dart
await client.post('/auth/google', body: {
  'idToken': idToken,
  if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
});
```

Errors: `500 GOOGLE_CLIENT_ID is not configured`, `401 Invalid or expired Google token` (includes unverified email).

New Google users are created as `CUSTOMER` with `password: null`. Existing users **keep their current role** (see §4.4).

---

#### Related endpoints (copy if UBMS needs them)

| Method | Path | Body | Notes |
|--------|------|------|--------|
| `POST` | `/api/v1/auth/register-vendor` | `CreateUserDto` + `storeName` | Role `VENDOR`, creates `Vendor` row |
| `POST` | `/api/v1/auth/convert-guest` | `{ orderId, email, password }` | Guest order → account |
| `GET` | `/api/v1/auth/me` | Bearer JWT | Current public profile |
| `POST` | `/api/v1/orders/:id/claim` | Bearer JWT | Attach guest order when emails match |

---

### 3.3 Persist JWT + profile, attach Bearer header

#### Storage (SharedPreferences, not secure storage)

| Key | Value |
|-----|--------|
| `ikayi_jwt` | Access token string |
| `ikayi_avatar_url` | Google photo URL (optional) |
| `ikayi_avatar_user` | User id that owns the avatar (avoids leaking a photo across accounts) |

**UBMS:** rename keys to `ubms_jwt`, `ubms_avatar_url`, `ubms_avatar_user`.

#### Write path (`AuthState._authenticate`)

```dart
final result = await request(); // { user, accessToken }
_api.setToken(result.accessToken);
user = result.user;
this.avatarUrl = _nonEmpty(avatarUrl);
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_tokenKey, result.accessToken);
await _persistAvatar(prefs, result.user.id, this.avatarUrl);
```

#### Restore path (`AuthState.restore`, called in `main()`)

```
1. restoring = true
2. Read ikayi_jwt
3. If missing → Unauthenticated
4. api.setToken(token)
5. GET /auth/me → user
6. Restore avatar if saved user id matches
7. On any failure → clear token + prefs (treat as Unauthenticated)
8. restoring = false
```

#### Logout

```
api.setToken(null)
user = null
googleSignIn.signOut()
prefs.remove(token, avatar keys)
```

#### Header attachment (`ApiClient`)

```dart
Map<String, String> _headers({bool jsonBody = false}) {
  return {
    'Accept': 'application/json',
    if (jsonBody) 'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
```

`IkayiApi.setToken` writes `client.token`. Every subsequent `get/post/put/patch/delete` includes the Bearer header.

---

### 3.4 `VendorUser` profile model (Flutter)

Defined in `frontend/lib/core/models/models.dart`. Parse both flattened fields and nested `vendor`.

```dart
bool get isVendorStaff {
  final normalized = role.toUpperCase();
  return normalized == 'VENDOR' || normalized == 'ADMIN';
}
```

This single getter drives:

- Auth screen post-login route (`/vendor` vs `/` or `next`)
- Header “Vendor dashboard” item
- `VendorShell` gate (non-staff users are bounced to shop home)

**UBMS:** rename to `AuthUser` / `UbmsUser`. Map staff via whatever roles UBMS uses (`ADMIN`, `STAFF`, …).

---

## 4. Backend authentication architecture (NestJS & Prisma)

### 4.1 Prisma `User` model (auth-relevant)

```prisma
enum UserRole {
  ADMIN
  VENDOR
  CUSTOMER
}

model User {
  id        String    @id @default(uuid())
  email     String    @unique
  password  String?   // null = Google-only account
  name      String
  role      UserRole  @default(VENDOR)
  phone     String?
  district  String?
  sector    String?
  landmark  String?
  vendor    Vendor?
  orders    CustomerOrder[]
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
}
```

Google-auth migration (`backend/prisma/migrations/20260820120000_google_auth/migration.sql`):

```sql
ALTER TYPE "UserRole" ADD VALUE 'CUSTOMER';
ALTER TABLE "User" ALTER COLUMN "password" DROP NOT NULL;
```

**UBMS:** keep `password` nullable and a `CUSTOMER`-equivalent role (or a generic `USER`). Do not default new Google users to `VENDOR`/`ADMIN`.

### 4.2 DTOs with class-validator

Global pipe (`main.ts`):

```ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,
  transform: true,
  forbidNonWhitelisted: true,
  transformOptions: { enableImplicitConversion: true },
}));
```

#### `CreateUserDto`

```ts
export class CreateUserDto {
  @IsString() @MinLength(2) @MaxLength(80)
  name!: string;

  @IsEmail()
  email!: string;

  @Transform(({ value }) =>
    typeof value === 'string' ? normalizeRwandaPhone(value) ?? value.trim() : value,
  )
  @IsString()
  @IsPhoneNumber('RW')
  @Matches(RWANDA_PHONE_REGEX, { message: RWANDA_PHONE_MESSAGE })
  phone!: string;

  @IsString() @MinLength(8) @MaxLength(72)
  @Matches(STRONG_PASSWORD_REGEX, { message: STRONG_PASSWORD_MESSAGE })
  password!: string;
}
```

#### `LoginDto`

```ts
export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString() @MinLength(8)
  password!: string;
}
```

#### `GoogleAuthDto`

```ts
export class GoogleAuthDto {
  @IsString() @IsNotEmpty()
  idToken!: string;

  @IsOptional() @IsUUID()
  orderId?: string;
}
```

#### `RegisterVendorDto` (optional for UBMS)

```ts
export class RegisterVendorDto extends CreateUserDto {
  @IsString() @MinLength(2) @MaxLength(120)
  storeName!: string;
}
```

Shared constants (`backend/src/common/constants/validation.ts`):

```ts
export const STRONG_PASSWORD_REGEX =
  /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/;

export const RWANDA_PHONE_REGEX = /^(?:\+250|250|0)?(7[2389]\d{7})$/;
```

Server-side phone normalize (`backend/src/common/utils/rwanda-phone.ts`): strip non-digits, drop `250` or leading `0`, require `7[2389]\d{7}`, return `+250${local}`.

### 4.3 AuthService — hashing, Google verify, JWT

#### Password hashing (`bcrypt`, cost 12)

```ts
const password = await bcrypt.hash(dto.password, 12);
// login:
const ok = await bcrypt.compare(dto.password, user.password);
```

Never log or return the hash. `toPublicProfile` omits `password`.

#### Native Google ID token verification

```ts
async loginWithGoogle(idToken: string, orderId?: string) {
  const audience =
    this.config.get<string>('googleClientId') ||
    this.config.get<string>('GOOGLE_CLIENT_ID');
  if (!audience) {
    throw new InternalServerErrorException('GOOGLE_CLIENT_ID is not configured');
  }

  const client = new OAuth2Client(audience);
  let payload: TokenPayload | undefined;
  try {
    const ticket = await client.verifyIdToken({ idToken, audience });
    payload = ticket.getPayload();
  } catch {
    throw new UnauthorizedException('Invalid or expired Google token');
  }

  if (!payload?.email || payload.email_verified === false) {
    throw new UnauthorizedException('Invalid or expired Google token');
  }

  const email = payload.email.toLowerCase().trim();
  const name = (payload.name?.trim() || email.split('@')[0]).trim();

  let user = await this.prisma.user.findUnique({
    where: { email },
    include: { vendor: true },
  });
  if (!user) {
    user = await this.prisma.user.create({
      data: {
        email,
        name,
        password: null,
        role: UserRole.CUSTOMER,
      },
      include: { vendor: true },
    });
  }

  if (orderId) {
    await this.linkGuestOrder(user.id, email, orderId);
  }

  return this.issueAuthResponse(user);
}
```

This uses **`google-auth-library` `OAuth2Client.verifyIdToken`** — not a client-trusted email field. The Flutter client only sends `idToken`.

#### JWT issue

```ts
private async issueAuthResponse(user: AuthUser) {
  const payload: JwtPayload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    vendorId: user.vendor?.id ?? null,
  };
  const accessToken = await this.jwt.signAsync(payload);
  return {
    accessToken,
    tokenType: 'Bearer',
    user: this.toPublicProfile(user),
  };
}
```

`JwtModule` secret: `JWT_SECRET`. Expiry: `JWT_EXPIRES_IN` (default `7d`).

### 4.4 Dynamic role handling on login

There is **no background worker** that reassigns roles. Role is:

1. **Assigned at write time**
   - `register` → `CUSTOMER`
   - `register-vendor` → `VENDOR` + `Vendor` row (`isVerified: false`, `isOnline: true`)
   - Google **new** user → `CUSTOMER`
   - Google **existing** user → **unchanged** (VENDOR stays VENDOR)
   - Seed / ops → `ADMIN`

2. **Re-read from the database on every login**  
   `login()` and `loginWithGoogle()` load `user` with `include: { vendor: true }` and put `user.role` + `vendor.id` into the JWT. The client cannot pick a role.

3. **Enforced on every request**  
   Global `JwtAuthGuard` + `RolesGuard`. Controllers declare `@Roles(UserRole.VENDOR, UserRole.ADMIN)` etc. JWT `role` must match.

4. **Enforced again on the Flutter side**  
   `VendorUser.isVendorStaff` gates `/vendor` and the header dashboard item. A CUSTOMER JWT that hits `/vendor` is redirected home.

**UBMS pattern to copy:** never trust a `role` field from the client body. On Google sign-in, look up by verified email and reuse the stored role so an admin who later taps “Sign in with Google” does not get demoted to a basic user.

### 4.5 Global guards & module wiring

`AuthModule`:

```ts
PassportModule.register({ defaultStrategy: 'jwt' }),
JwtModule.registerAsync({
  inject: [ConfigService],
  useFactory: (config: ConfigService) => ({
    secret: config.getOrThrow<string>('JWT_SECRET'),
    signOptions: {
      expiresIn: (config.get<string>('JWT_EXPIRES_IN') ?? '7d') as `${number}${'s'|'m'|'h'|'d'}`,
    },
  }),
}),
```

`AppModule` providers:

```ts
{ provide: APP_GUARD, useClass: JwtAuthGuard },
{ provide: APP_GUARD, useClass: RolesGuard },
```

`JwtAuthGuard` allows `@Public()` routes through. If a public route still sends `Authorization: Bearer …`, the guard **does** validate the token so optional auth (e.g. checkout) can attach the user.

`configuration.ts`:

```ts
export default () => ({
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
});
```

### 4.6 Controller surface

```
POST /api/v1/auth/register         @Public()  CreateUserDto
POST /api/v1/auth/register-vendor  @Public()  RegisterVendorDto
POST /api/v1/auth/login            @Public()  LoginDto
POST /api/v1/auth/google           @Public()  GoogleAuthDto
POST /api/v1/auth/convert-guest    @Public()  ConvertGuestDto
GET  /api/v1/auth/me               JWT        CurrentUser
```

Swagger: `http://localhost:3000/api/docs` (Bearer auth enabled).

---

## 5. End-to-end flows (copy these test cases)

### 5.1 Email register → authenticated header

1. Header person icon → `/login`
2. Toggle “Create an account”
3. Fill name, Rwanda phone, email, strong password, confirm
4. Strength meter turns all-green; submit
5. `POST /auth/register` → JWT stored → `context.go('/')` (or `/vendor` if vendor checkbox)
6. Header now shows avatar + My Orders / Log out

### 5.2 Email login (existing VENDOR)

1. `POST /auth/login` with vendor credentials
2. JWT `role=VENDOR`, `vendorId` set
3. Flutter `isVendorStaff == true` → `/vendor`

### 5.3 Google Sign-In (web)

1. GIS button → Google account picker
2. `onCurrentUserChanged` fires → `loginWithGoogle()`
3. ID token → `POST /auth/google`
4. New email → CUSTOMER created with `password: null`
5. Existing vendor email → same VENDOR user, new JWT
6. Avatar URL persisted from Google `photoUrl` or ID-token `picture` claim

### 5.4 Google-only account + password login

1. User registered via Google (`password` is null)
2. Email/password login → `401 Invalid credentials`
3. UI should keep offering Google Sign-In (do not invent a password-reset unless UBMS adds one)

### 5.5 Session restore

1. Cold start → `auth.restore()`
2. Valid JWT → `GET /auth/me` → Authenticated before first frame
3. Expired / garbage JWT → keys cleared → Unauthenticated

---

## 6. Environment variables

### Backend `.env`

```
JWT_SECRET="replace-with-a-long-random-secret"
JWT_EXPIRES_IN="7d"
GOOGLE_CLIENT_ID="xxxxx.apps.googleusercontent.com"
```

`GOOGLE_CLIENT_ID` **must** be the OAuth **Web** client ID (token audience). Android client IDs will fail `verifyIdToken` unless you also pass that Android ID as audience — IKAYIMART uses one Web client ID for both Flutter `serverClientId` and NestJS verification.

### Flutter dart-defines

```
--dart-define=API_BASE_URL=https://<ubms-api>/api/v1
--dart-define=GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
```

Local defaults (`api_config.dart`): Android emulator `http://10.0.2.2:3000/api/v1`, others `http://localhost:3000/api/v1`. Web/release currently hardcode the IKAYIMART Render host — **change this for UBMS**.

---

## 7. Step-by-step replication checklist for UBMS

Work in this order. Do not skip the shared validation constants — frontend and backend regexes must stay identical.

### Backend

1. **Prisma**
   - Add `User` with unique `email`, nullable `password`, `name`, `role` enum, optional `phone`.
   - Add `CUSTOMER` (or UBMS equivalent) to `UserRole`.
   - Run a migration equivalent to `20260820120000_google_auth`.

2. **Shared validation**
   - Copy `backend/src/common/constants/validation.ts`.
   - Copy `backend/src/common/utils/rwanda-phone.ts`.
   - Copy `IsRwandaPhone` decorator if you prefer it over `@Matches`.

3. **Auth module files**
   - Copy the entire `backend/src/auth/` folder.
   - Copy guards + decorators: `public`, `current-user`, `roles`, `jwt-auth.guard`, `roles.guard`.
   - Copy `jwt.strategy.ts` and `jwt-payload.ts`.
   - Rename `vendorId` in the JWT only if UBMS has no vendor concept (use `null` or an org id).

4. **Wire the app**
   - `ConfigModule.forRoot` with `googleClientId: process.env.GOOGLE_CLIENT_ID`.
   - `AuthModule` imported in `AppModule`.
   - `APP_GUARD` → `JwtAuthGuard` then `RolesGuard`.
   - Global prefix `api/v1`.
   - `ValidationPipe` with `whitelist`, `transform`, `forbidNonWhitelisted`.

5. **Dependencies**
   - `npm i @nestjs/jwt @nestjs/passport passport passport-jwt bcrypt google-auth-library class-validator class-transformer libphonenumber-js`
   - `npm i -D @types/bcrypt @types/passport-jwt`

6. **Env**
   - Set `JWT_SECRET`, `JWT_EXPIRES_IN`, `GOOGLE_CLIENT_ID`.
   - Confirm Swagger `POST /api/v1/auth/register` and `/login` against a local DB.

7. **Strip marketplace-only pieces if UBMS does not need them**
   - `register-vendor`, `convert-guest`, `linkGuestOrder` / `orderId` on Google.
   - Keep `loginWithGoogle(idToken)` even if you drop `orderId`.

### Frontend

8. **Packages**
   - `flutter pub add provider http shared_preferences go_router google_sign_in google_sign_in_web`

9. **Copy core files** (adjust package/import prefixes)
   - `rwanda_phone.dart`, `password_rules.dart`, `password_strength_meter.dart`
   - `api_client.dart`, `api_exception.dart`, `api_config.dart` (change production host)
   - Auth methods from `ikayi_api.dart` (or a slimmer `ubms_api.dart`)
   - `VendorUser` → `UbmsUser` from `models.dart`
   - `auth_state.dart` — rename preference keys to `ubms_*`
   - `auth_screen.dart`
   - `google_sign_in_button.dart` + both GIS files (keep the conditional import)

10. **Add the live phone formatter** from §2.2 to the register `TextFormField`.

11. **Bootstrap**
    - `await auth.restore()` before `runApp`.
    - `ChangeNotifierProvider<AuthState>.value`.
    - Route `/login` → `AuthScreen`.
    - Honor `?next=` after success.

12. **Header icon**
    - Copy the `auth.isLoggedIn` branch from `shop_header.dart`.
    - Logged out → `/login`.
    - Logged in → profile dropdown (map menu items to UBMS screens).
    - Logout → `auth.logout()` + navigate home.

13. **Google Cloud**
    - Same Web client ID on Flutter dart-define and NestJS env.
    - Authorized JS origins = UBMS web URLs.
    - Web: empty Google scopes (GIS button). Mobile: `email`, `profile`.
    - `GoogleSignIn.serverClientId` = that Web client ID so Android ID tokens pass `verifyIdToken`.

14. **Branding / copy**
    - Replace “IKAYIMART”, “Vendor Central”, “I want to sell on IKAYIMART”.
    - Point `isVendorStaff` at UBMS staff roles.

15. **Verify**
    - Register with `0788…` and confirm DB stores `+250788…`.
    - Weak password blocked by meter **and** by `400` from NestJS.
    - Login, refresh the app, still authenticated (`GET /auth/me`).
    - Google web button → JWT; Google-only user cannot password-login.
    - Header switches person icon ↔ avatar menu.
    - `Authorization: Bearer` present on a protected call (DevTools / proxy).
    - Expired JWT clears prefs and returns to Unauthenticated.

---

## 8. IKAYIMART → UBMS rename map

| IKAYIMART | Suggested UBMS |
|-----------|----------------|
| `IkayiApi` | `UbmsApi` |
| `VendorUser` | `UbmsUser` / `AuthUser` |
| `ikayi_jwt` | `ubms_jwt` |
| `AuthScreen` vendor checkbox | Drop, or retarget to UBMS org/tenant signup |
| `/vendor` | UBMS dashboard route |
| `UserRole.CUSTOMER` | `USER` / `STAFF` as needed — keep Google defaults **non-admin** |
| Production API host in `api_config.dart` | UBMS API origin |

Do **not** rename the HTTP paths unless both apps must diverge. Keeping `/api/v1/auth/*` identical lets you share the NestJS auth module as a package later.

---

## 9. What not to copy

- `ImigongoBackground` and IKAYIMART color tokens — optional chrome, not auth.
- Cart, catalog, payments, Cloudinary, BullMQ — unrelated.
- `flutter_secure_storage` — not used; adding it is a UBMS enhancement, not a port requirement.
- People API / extra Google scopes on web.
- Client-supplied `role` on register/login bodies — the server assigns role.

---

## 10. Source-of-truth snippets (complete small files)

These files are short enough to paste as-is. Larger files (`auth_screen.dart`, `auth_state.dart`, `auth.service.ts`, `shop_header.dart`, `ikayi_api.dart`) are already quoted by section above — copy them from the IKAYIMART tree rather than retyping.

### `backend/src/auth/dto/login.dto.ts`

```ts
import { IsEmail, IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: 'jean.paul@kigalitech.rw' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'VendorPass123!' })
  @IsString()
  @MinLength(8)
  password!: string;
}
```

### `backend/src/auth/dto/google-auth.dto.ts`

```ts
import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GoogleAuthDto {
  @ApiProperty({
    description: 'Google Sign-In ID token from the Flutter client',
  })
  @IsString()
  @IsNotEmpty()
  idToken!: string;

  @ApiPropertyOptional({
    description: 'Guest order to attach after Google sign-in',
  })
  @IsOptional()
  @IsUUID()
  orderId?: string;
}
```

### `backend/src/auth/types/jwt-payload.ts`

```ts
import { UserRole } from '@prisma/client';

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  vendorId: string | null;
}
```

### Flutter `resolveGoogleClientId`

```dart
String resolveGoogleClientId() {
  const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID');
  return fromEnv;
}
```

---

*End of blueprint. Implement in the order of §7; keep phone regex, password regex, JWT shape, and Google audience identical between Flutter and NestJS.*
