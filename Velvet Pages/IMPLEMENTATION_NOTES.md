# Velvet Pages — Implementation Notes

These notes capture the decisions made while reviewing `IMPLEMENTATION_PLAN.md` so future sessions do not need to rediscover them.

## Confirmed implementation decisions

- **Scope boundary:** the refactor should go all the way through the UI changes. There is no value in introducing the new model/provider architecture without also moving the app to the library-first UI.
- **Legacy data:** existing legacy data can be discarded. The app is moving forward with a fresh dataset and does not need migration compatibility.
- **Source identification:** source detection should be automatic.
- **AO3 v1 scope:** implement AO3 work fetch/parsing, chapter navigation, summary HTML rendering, metadata display, and search/browse/import.
- **AO3 metadata parity:** use best judgment and current best practices when mapping AO3 metadata into the shared model.
- **Chapter model:** the current source has no true chapter structure, so it should be flattened into a single chapter representing the whole story when needed.
- **UI priority:** the existing library page should become the entrypoint and take priority over the browse-first flow.
- **Reader behavior:** changes can be made wherever needed; backward compatibility with the current reader flow is not required.
- **Update checks:** manual refresh is sufficient for the first pass.
- **Storage approach:** no strong preference was given, so implementation can choose the most practical path.
- **AO3 access assumptions:** AO3 should be implemented for anonymous/public access only for now. Auth can be added later if needed.

## Practical interpretation

The implementation should be optimized for:

1. a library-first application structure,
2. a shared source-agnostic model layer,
3. an AO3 provider that matches the real AO3 data shape as closely as practical,
4. a clean break from the old single-source assumptions.

## Notes for future sessions

- If the app needs authenticated AO3 access later, that should be treated as a separate enhancement rather than a prerequisite for the current refactor.
- Any leftover single-source assumptions in UI, storage, or reader code should be considered refactor targets rather than preserved behaviors.
- The current source may be represented as a flattened single-chapter work in the unified model.

## Recent commit log

- `4efb7cf` — `Refactor toward library-first multi-source architecture`
  - Added shared foundation models: `SourceType`, `Chapter`, `WorkMetadata`, `LibraryItem`
  - Added provider abstraction: `StorySourceProvider`, `CurrentSourceProvider`, `AO3Provider`, `SourceRegistry`
  - Began shifting the app entry/router toward a library-first shell
  - Added a bridge from legacy `Story` data into the unified model

- `fb31ca9` — `Continue library-first app refactor`
  - Added a `libraryItems` path to `ScrapperViewModel`
  - Added `loadLibraryIfNeeded(forceRefresh:)`
  - Added a filtered library bridge for the new unified model
  - Updated `ContentView` so the app can surface a basic library state when browse/section states are absent

- `7ec003b` — `Wire library view to unified model`
  - Reworked `LibraryView` to render `LibraryItem` data instead of legacy cached snapshots
  - Added unified library filtering in `ScrapperViewModel`
  - Deduped unified library items before display
  - Updated category aggregation to prefer unified metadata when available
  - Added the new shared model/provider files to the Xcode project so the refactor compiles as part of the app target
