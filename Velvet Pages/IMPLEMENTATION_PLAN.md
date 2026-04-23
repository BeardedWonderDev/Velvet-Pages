# Velvet Pages — AO3 + Multi-Source Implementation Plan

## Context: direction change
This plan reflects a deliberate shift in product direction.

Velvet Pages was originally built as a **single-source reader** centered on the current source website. The new direction is to turn it into a **multi-source personal reading library** that supports both the current source and **AO3** cleanly in one app.

This is not just an extra scraper. It requires a UI and architecture that treat each source as a provider feeding one unified library experience.

## Confirmed implementation decisions
- The refactor should go through the full UI, not stop at the data/model layer.
- Legacy data can be discarded; this is a fresh start.
- Source detection should be automatic.
- AO3 v1 scope includes work fetch/parsing, chapter navigation, summary HTML rendering, metadata display, and search/browse/import.
- AO3 metadata should be mapped with best judgment and practical best practices.
- The current source can be flattened into a single chapter when needed.
- The current library page should become the entrypoint and take priority over the browse-first flow.
- Reader behavior can change as needed; backward compatibility is not required.
- Update checks can remain manual for the first pass.
- AO3 should be implemented for anonymous/public access only for now.

## Goal
Refactor Velvet Pages from a single-source reader into a **multi-source personal reading library** that supports both the current source site and **AO3** cleanly in one app.

The app should become **library-first**, with source systems acting as interchangeable content providers rather than the center of the UI.

---

## Product direction

### Core principle
The user’s **personal library** should be the primary experience.

Sources should support:
- discovery / import
- metadata refresh
- chapter fetching
- update detection
- source-specific detail rendering

The UI should not force AO3 into the shape of the current source, or vice versa.

### Design outcome
The app should present:
- one unified library
- one unified reading experience
- source-aware metadata panels
- source-specific browse/import flows
- a single work detail shell with expandable metadata by source

---

## Current state summary

### Existing app shape
Velvet Pages currently uses:
- one `Story` model
- one source URL and parser path
- one `ScrapperViewModel` that owns network, parsing, filtering, and UI state
- a browse-first layout built around source sections and categories

### Main limitation
The current model assumes the source site:
- has a fairly consistent home page structure
- exposes a small, flat metadata set
- can be rendered with one generic card/layout

AO3 breaks those assumptions.

---

## AO3 requirements to support

AO3 needs richer handling for:
- rating
- warnings
- category
- language
- fandom(s)
- relationship tags
- character tags
- freeform tags
- stats: hits, kudos, bookmarks, comments, words
- chapter lists / chapter navigation
- summary markup / HTML
- work vs chapter distinction
- ongoing updates

This means AO3 should be treated as a **distinct source adapter**, not a variation of the current parser.

## Reference implementation: CO3
The `~/Development/BeardedWonder/CO3` codebase is the key implementation reference for AO3 behavior.

CO3 demonstrates what the AO3 client needs to be able to do in practice, including:
- AO3 work parsing
- metadata extraction
- chapter extraction and navigation
- summary rendering
- stats handling
- library storage patterns
- update / history workflows
- work detail presentation that acknowledges AO3’s richer data model

Relevant reference areas from CO3 include:
- `main/web/worksScreen/fetchWork.js` — AO3 work metadata and chapter parsing
- `main/screens/workScreen.jsx` — reader/work detail flow
- `main/storage/models/work.js` — normalized work model shape
- `main/components/Library/BookCard.jsx` — source-aware card presentation
- `main/screens/Library.jsx` — library-first organization

CO3 is especially useful for understanding the AO3-specific metadata breakdown that Velvet Pages should mirror in spirit, even if the UI and storage architecture are different.

---

## Recommended UI layout

### 1) Library
This should be the landing screen.

#### Purpose
Show the user’s saved works across all sources in one place.

#### Layout
- top search bar
- source filter chips
- metadata filter chips
- sort control
- saved works grid/list
- each work card includes a source badge

#### Work card behavior
Cards should share a base layout, then render source-specific metadata rows below.

Examples:
- **Current source**: title, author, description, themes, posted date
- **AO3**: title, author, fandom, rating, warnings, tags, chapter progress, word count, stats

### 2) Work detail
This should be the primary reading hub.

#### Layout sections
- header: title, author, source badge, favorite/download/update actions
- summary/description
- metadata panel
- chapter list
- reading controls
- related actions

#### Metadata panel approach
Use a shared shell with expandable source-specific blocks:
- shared fields
  - source
  - author
  - status
  - last updated
  - progress
- AO3 block
  - rating
  - warnings
  - category
  - language
  - fandoms
  - relationships
  - characters
  - freeform tags
  - stats
  - words
  - chapters
- current-source block
  - site categories/themes
  - source-specific counts
  - custom labels supported by the original site

### 3) Browse / Import
This screen should be for discovery and importing into the library, not as the main home.

#### Source split
- **AO3 browse/import**
  - fandom search
  - tag filtering
  - rating/warning filters
  - relationship / character filters
  - sort by updated, hits, kudos, bookmarks, words
- **Current source browse/import**
  - preserve the current browsing structure
  - sections / categories / themes if the source provides them

### 4) Updates
A dedicated updates view should show:
- new chapters
- updated works
- unread progress
- source label
- date last seen / last updated

### 5) History
A separate history view should track:
- recently opened works
- recently read chapters
- continue-reading items

### 6) Settings
Settings should include:
- default source
- import behavior
- theme
- reader font / spacing / layout
- metadata display options
- update refresh behavior

---

## Recommended architecture

### 1) Introduce a source provider protocol
Define a common interface so UI never talks to site-specific code directly.

Example responsibilities:
- search works
- fetch browse results
- fetch work detail
- fetch chapter content
- refresh metadata
- normalize results into shared app models

### 2) Split source implementations
Create one adapter per source:
- `CurrentSourceProvider`
- `AO3Provider`

Each provider owns:
- URL shape
- request logic
- parser logic
- pagination handling
- metadata mapping

### 3) Normalize into shared models
Use shared app models for the UI, with optional source-specific metadata.

Recommended model approach:
- `LibraryItem`
- `SourceType`
- `WorkMetadata`
- `Chapter`
- `ReadingProgress`
- `SourceExtras`

Shared fields should cover what all sources have in common.

Source extras should hold the rest.

### 4) Keep parsing and presentation separate
Do not let the UI decode site HTML or source-specific data directly.

Pipeline should be:
1. fetch source HTML/API data
2. parse into source-specific structs
3. map into shared library models
4. render in UI

---

## Proposed file organization

### Models
- `Models/LibraryItem.swift`
- `Models/WorkMetadata.swift`
- `Models/Chapter.swift`
- `Models/SourceType.swift`
- `Models/SourceExtras.swift`

### Source layer
- `Sources/StorySourceProvider.swift`
- `Sources/CurrentSourceProvider.swift`
- `Sources/AO3Provider.swift`
- `Sources/CurrentSourceParser.swift`
- `Sources/AO3Parser.swift`
- `Sources/SourceMapper.swift`

### Stores / managers
- `Services/LibraryStore.swift`
- `Services/ReadingProgressStore.swift`
- `Services/UpdateStore.swift`
- `Services/SourceRegistry.swift`

### UI
- `Views/Library/LibraryView.swift`
- `Views/Library/WorkCard.swift`
- `Views/WorkDetail/WorkDetailView.swift`
- `Views/WorkDetail/MetadataPanel.swift`
- `Views/WorkDetail/ChapterListView.swift`
- `Views/Browse/BrowseView.swift`
- `Views/Browse/SourcePickerView.swift`
- `Views/Updates/UpdatesView.swift`
- `Views/Settings/SettingsView.swift`

---

## AO3-specific metadata mapping

### AO3 fields to preserve
- title
- author
- summary
- rating
- warnings
- category
- language
- fandoms
- relationships
- characters
- freeform tags
- hits
- kudos
- bookmarks
- comments
- words
- chapters
- published / updated dates
- completion status

### Current source fields to preserve
- title
- author
- description
- themes/categories
- rating if present
- read count if present
- posted date
- any source-defined categories

### Mapping rule
If a field does not exist in one source, it should be omitted gracefully rather than forced into a fake equivalent.

---

## Implementation phases

### Phase 1 — Foundation
- create shared source-agnostic models
- create source provider protocol
- separate current-source logic from UI state
- add source type to library items
- introduce unified library storage structure

### Phase 2 — AO3 read support
- implement AO3 parser for search/browse/work detail/chapter content
- map AO3 metadata into the shared model
- support AO3 chapter navigation
- support AO3 summary rendering
- use CO3’s AO3 work parsing behavior as the benchmark for completeness and structure

### Phase 3 — UI refactor
- move app landing to Library
- create source-aware work cards
- add unified work detail screen
- add metadata panel with source-specific sections
- add browse/import source picker

### Phase 4 — Library and update polish
- unified updates screen
- source-aware history
- unread/update indicators
- filters by source, fandom/category, status, and progress

### Phase 5 — cleanup and hardening
- reduce parser duplication
- improve caching
- make fetch failures source-specific
- add tests for parsers and mapping

---

## Recommended development order

1. Define shared models
2. Add source abstraction
3. Port current source into a provider
4. Build AO3 provider using CO3 as the feature reference
5. Create unified library UI
6. Add source-aware detail view
7. Add browse/import source selection
8. Add updates and history polish

---

## Risks and design notes

### Risk: one model trying to represent both sources too aggressively
Avoid this by keeping source-specific metadata in an extension field rather than forcing everything into one rigid schema.

### Risk: UI becomes source-specific again
Avoid this by making the UI render shared reading concepts first, then injecting source-specific panels only where needed.

### Risk: parser sprawl
Avoid this by giving each source its own parser and keeping helper utilities small and reusable.

### Risk: AO3 is much richer than the current source
This is not a bug. It’s the reason the metadata panel must be modular.

---

## Immediate next steps

1. Refactor the app around a unified library model.
2. Add a source provider abstraction.
3. Implement an AO3 adapter using CO3 as the reference for metadata and chapter handling.
4. Rebuild the UI around Library → Work Detail → Browse/Import.
5. Keep the current source intact as a provider while AO3 is added alongside it.

---

## Success criteria

The refactor is successful when:
- the app opens into a library-first experience
- works from both sources appear in the same library
- AO3 metadata displays cleanly without breaking the current source layout
- source implementations can evolve independently
- the UI stays consistent even as source metadata differs
