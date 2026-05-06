## 0.0.5+12

- Improved pub.dev scoring metadata and API documentation.
- Added a package example for REST, GraphQL, and cache setup.
- Updated dependency constraints for latest supported package versions.
- Removed an unnecessary direct `http_parser` dependency.

## 0.0.4+11

- Removed hard-coded token fallbacks from REST and GraphQL clients.
- Made bad-certificate handling opt-in and scoped to the package HTTP clients.
- Added injectable HTTP and secure-storage clients for deterministic tests.
- Hardened HTTP URI handling and GraphQL error mapping.
- Replaced live endpoint tests with mocked client tests.
- Updated README usage examples.

## 0.0.1

- Initial package release.
