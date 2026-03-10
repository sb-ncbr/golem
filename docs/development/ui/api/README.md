# Api Module

The `api` module handles all communication with the backend. It provides a HTTP client and data models returned by each endpoint.

## Api Service (api_service.dart)

The central HTTP client. All backend calls go through here.

- Implemented as a **singleton** (`ApiService.instance`) so the same configured client is reused everywhere.
- Wraps [Dio](https://pub.dev/packages/dio) and exposes some HTTP methods.
- Every method returns an `ApiResponse<T>`, which is either a success (with `data`) or an error (with `message`).
- `download` is a special case that reads raw bytes (e.g. for FASTA/JSON files) and manually decodes error responses since the response type is `bytes`.
- The base URL is read from the `GOLEM_API_URL` environment variable.
- `withCredentials = true` is set on the browser adapter, meaning session cookies are forwarded automatically (used for auth).

## Auth (auth.dart)

Models and helpers related to the logged-in user.

- **`User`** - represents an authenticated user with an ID, username, group memberships, and per-organism stage color preferences.
- **`UserGroup`** - an id/name pair representing a permission group that controls access to organisms.
- **`StagePreference`** - stores a user's preferred display color for a given developmental stage within an organism. Provides:
  - `updatePreference()` - PUTs the updated color to `/preferences`.
  - `getDefaults()` - GETs the default stage preferences from `/preferences/default`.

## Motif (motif.dart)

Provides operations on saved motifs.

All functions accept an optional `onError` callback so callers can handle failures as needed (e.g. show a snackbar).

### Organism (organism.dart)

Models and API calls for organisms and their associated sequence data.

- **`Organism`** - the top-level entity. Holds metadata like which FASTA/JSON files to load, access control (public flag + groups).
  - `Organism.fromFile(filename)` used when user loads a custom FASTA file.
- **`OrganismMetadata`** - loaded from the organism's JSON metadata file. Contains:
  - `stages` - map of stage name - `StageMetadata` (SRR, URL)
  - `genes` - map of gene ID - `SequenceMetadata` (marker positions + transcription rates)
  - Supports both an old format (genes only) and a new format (stages + genes) for backwards compatibility.
- **`fetchOrganisms()`** - GETs the list of available organisms from `/organisms`.
- **`fetchMetadata()`** - downloads the JSON metadata file for an organism via the `download`.

## API Module Data Flow

```
App startup
    ↓
fetchOrganisms() → List<Organism>
    ↓
User selects organism
    ↓
fetchMetadata(organism) → OrganismMetadata
    (marker positions, transcription rates per gene)
    ↓
fetchMotifs() → List<Motif>
    ↓
Analysis
```
