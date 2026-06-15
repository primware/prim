![Primware Logo](https://primware.net/wp-content/uploads/2025/02/PW_Logo.webp)

# Primware

`primware` is a Flutter sales application fully integrated with **iDempiere ERP** through the iDempiere REST API.

It is designed for sales teams and POS users who need a responsive application for customer lookup, product lookup, sales order creation, POS document flows, close cash operations, reporting, and organization-level configuration.

The app centralizes iDempiere endpoints, stores the selected client/role/organization context, and adapts available sales documents based on the ERP configuration.

## Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/josianascanio">
        <img src="https://github.com/josianascanio.png" width="80" alt="Josian Ascanio" />
        <br />
        <sub><b>Josian Ascanio</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/moisesgagil">
        <img src="https://github.com/moisesgagil.png" width="80" alt="Moises Gil" />
        <br />
        <sub><b>Moises Gil</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/egil0902">
        <img src="https://github.com/egil0902.png" width="80" alt="Eduardo Gil" />
        <br />
        <sub><b>Eduardo Gil</b></sub>
      </a>
    </td>
  </tr>
</table>

> [!NOTE]
> Primware depends on a correctly configured iDempiere environment. The Flutter app does not replace iDempiere setup; it consumes the ERP configuration, user access, POS records, document types, price lists, taxes, and processes exposed through the REST API.

## Current Features

- iDempiere REST authentication.
- Client, role, and organization selection after login.
- Optional remembered login context per user.
- Dynamic sales document creation based on iDempiere document type configuration.
- Sales order and POS order flows.
- Customer catalog, customer creation, and customer details.
- Product catalog and product details.
- Dashboard cards and charts backed by iDempiere chart endpoints.
- POS close cash flow and close cash history.
- PDF and printing support for sales documents and reports.
- Organization settings and logo configuration.
- Password change flow.
- Yappy payment endpoint integration.
- Spanish and English localization support.
- Shared UI components for buttons, dropdowns, containers, toasts, loading states, and forms.

## Quick Start

Install Flutter dependencies:

```bash
flutter pub get
```

Run the app on the selected platform:

```bash
flutter run
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Requirements

- Flutter SDK `>=3.9.0 <4.0.0`.
- Dart SDK compatible with the configured Flutter version.
- Access to an iDempiere server with REST API enabled.
- `posintegration` plugin installed and active in iDempiere.
- A valid iDempiere user with client, role, organization, and warehouse access.
- POS configuration in iDempiere when POS mode is required.
- Platform-specific tooling for Android, iOS, macOS, Windows, Linux, or Web.

## iDempiere Setup

At minimum, the target iDempiere instance should include:

- `posintegration` plugin imported and active.
- POS master role assigned to the user role.
- User access to the required client, role, organization, and warehouse.
- POS record configured when POS mode is required.
- Price list and price list version configured for sales documents.
- Sales document types configured for the role and organization.
- Tax, tax category, payment term, and tender type records configured according to the sales flow.
- Close cash processes available for POS users when cash closing is required.
- Chart records configured when dashboard metrics are expected.
- Yappy configuration records when Yappy payments are enabled.

## Configuration

Application endpoints are centralized in:

```text
lib/API/endpoint.dart
```

The base iDempiere URL is stored in `Base.baseURL` and is used to build REST endpoints such as:

- `/api/v1/auth/tokens`
- `/api/v1/auth/roles`
- `/api/v1/auth/organizations`
- `/api/v1/auth/warehouses`
- `/api/v1/models/C_Order`
- `/api/v1/models/C_OrderLine`
- `/api/v1/models/C_BPartner`
- `/api/v1/models/M_Product`
- `/api/v1/processes/...`
- `/api/v1/charts/.../data`

Yappy service URLs are built from `Base.yappyURL`.

Before using the app in production, make sure the API base URL, Yappy URL, and environment mode are configured for the intended deployment.

## Main Modules

| Module | Purpose |
| --- | --- |
| `Auth` | Login, token generation, and post-login client/role/organization selection. |
| `Dashboard` | Sales charts and ERP-backed metrics. |
| `Order` | Sales order/POS document creation, order listing, details, and printing. |
| `Product` | Product catalog and product detail views. |
| `BPartner` | Customer catalog, customer creation, and customer detail views. |
| `Report` | Close cash and report-related flows. |
| `Settings` | Organization settings, password changes, debug console, and POS-related configuration. |

## Project Structure

```text
lib/
  API/              API endpoints, token state, user state, POS state
  localization/     English and Spanish localization keys
  shared/           Reusable widgets and helpers
  theme/            Application colors, themes, and formatters
  views/
    Auth/           Login and post-login configuration flow
    Home/           Dashboard, orders, products, customers, reports, settings
assets/
  img/              Logos, icons, and image assets
```

## Common Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk
flutter build ios
flutter build web
```

## Troubleshooting

### Login fails

Verify the configured iDempiere base URL, REST API availability, user credentials, and whether the user has access to at least one active client, role, and organization.

### Roles or organizations do not load

Check role access in iDempiere and confirm that the REST endpoints `/api/v1/auth/roles` and `/api/v1/auth/organizations` return data for the authenticated user.

### POS options do not appear

Confirm that the user role has POS access, the POS record is configured, and the required warehouse, price list, document types, taxes, and tender types exist in iDempiere.

### Dashboard metrics are empty

Verify that chart IDs are configured, chart records exist in iDempiere, and the corresponding `/api/v1/charts/.../data` endpoints return values.

### Printing or PDF output fails

Check the target platform configuration and confirm that the required print/PDF dependencies are supported on that platform.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
