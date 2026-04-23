# PhraseRise UI Refresh Wireframes

## Goal

PhraseRise should feel like a focused audio coaching tool rather than a file list with utility screens.

The redesign should make these actions feel immediate:

1. Open the app and know what to practice next.
2. Start phrase practice in one tap.
3. Understand improvement from recordings and history.

## Product Reading From Current Code

Current core flow from the existing app:

- Import a song or video source.
- Create phrase ranges from that source.
- Loop a phrase and adjust speed / pitch.
- Record performance takes.
- Compare takes.
- Save practice notes and review stats.

Main code touchpoints today:

- `PhraseRise/App/RootTabView.swift`
- `PhraseRise/Views/Songs/SongsView.swift`
- `PhraseRise/Views/Songs/SongDetailView.swift`
- `PhraseRise/Views/Practice/PhraseDetailView.swift`
- `PhraseRise/Views/Practice/PracticePlayerView.swift`
- `PhraseRise/Views/Practice/RecordingListView.swift`
- `PhraseRise/Views/Stats/StatsView.swift`
- `PhraseRise/Views/Settings/SettingsView.swift`

## Proposed Navigation

Keep navigation simple and stable while shifting emphasis toward practice.

### Tabs

1. `Today`
2. `Library`
3. `Progress`
4. `Settings`

### Why

- `Today` becomes the new default landing screen.
- `Library` keeps the current Songs area but reframes it as a source library.
- `Progress` is a stronger, more motivating version of the current Stats tab.
- `Settings` can stay as a tab for the first refresh to reduce implementation risk.

## Visual Direction

- Tone: premium audio coach / modern rehearsal studio.
- Base colors: deep graphite, navy-black, muted steel.
- Accent colors: petrol teal for action, amber for progress, coral red for recording.
- Surfaces: layered cards with soft glass and clearer elevation differences.
- Motion: restrained, tactile, focused on playback and recording state changes.
- Typography: confident rounded display moments plus cleaner body copy.

## Information Architecture

```text
Today
  Resume Practice
  Focus Phrases
  Recent Sources
  Weekly Progress

Library
  Sources
  Song Detail
  Phrase List
  Phrase Editor

Practice
  Playback / Loop / Speed / Pitch
  Recording
  Save Practice Record
  Jump to Takes

Progress
  Weekly Summary
  Mastery by Phrase
  Takes / Compare
  Filters

Settings
  Permissions
  Practice Defaults
  Recording Quality
  Premium
```

## Wireframes

### 1. Today

Purpose:

- Answer "what should I do now?"
- Shorten the path to actual practice.
- Surface momentum and streaks without opening Stats.

```text
+--------------------------------------------------+
| Today                           streak   Premium |
| Ready to keep your ear sharp?                   |
+--------------------------------------------------+
| Resume Practice                                  |
| Song Title                                       |
| Chorus high phrase                               |
| 00:48 - 01:06               [ Resume Practice ] |
+--------------------------------------------------+
| Focus Phrases                                    |
| [ Active ] [ Needs Work ] [ Mastered ]          |
| +----------------------------------------------+ |
| | Phrase name                                  | |
| | Song title            12 min this week       | |
| | status chip                 [ Practice ]     | |
| +----------------------------------------------+ |
| +----------------------------------------------+ |
| | Phrase name                                  | |
| | Song title             latest take yesterday | |
| | status chip                 [ Practice ]     | |
| +----------------------------------------------+ |
+--------------------------------------------------+
| Recent Sources                                   |
| Song / video thumbnail        updated recently  |
| Song / mic source             updated recently  |
+--------------------------------------------------+
| Weekly Progress                                  |
| [ streak ring ] [ sessions ] [ recordings ]     |
+--------------------------------------------------+
```

Key modules:

- Resume card
- Focus phrase cards
- Recent source list
- Weekly summary row

Data sources:

- `SongRepository`
- `PhraseRepository`
- `PracticeRecordRepository`
- `PerformanceRecordingRepository`

No schema change required for the first version.

### 2. Library

Purpose:

- Keep source management strong.
- Make songs feel like organized training materials, not only imported files.

```text
+--------------------------------------------------+
| Library                                 [+ Add] |
| 18 sources                                       |
| 4h 22m total practice material                   |
+--------------------------------------------------+
| Search / filter chips                            |
| [ All ] [ Video ] [ Audio ] [ Mic ]             |
+--------------------------------------------------+
| Source Card                                      |
| thumbnail    Song Title                          |
|            artist / duration / updated           |
|            5 phrases                     [ > ]   |
+--------------------------------------------------+
| Source Card                                      |
| dot         Mic Source                           |
|            duration / updated                    |
|            2 phrases                     [ > ]   |
+--------------------------------------------------+
```

Song detail should be reframed around training readiness:

```text
+--------------------------------------------------+
| Song Header                                      |
| title / artist / source type                     |
| waveform or video strip                          |
| 5 phrases   3 active   2 mastered                |
+--------------------------------------------------+
| [ Add Phrase ]  [ Play Source ]                  |
+--------------------------------------------------+
| Phrase List                                      |
| phrase card + status + quick play + chevron      |
| phrase card + status + quick play + chevron      |
+--------------------------------------------------+
```

### 3. Practice Player

Purpose:

- Turn the current practice screen into the emotional center of the app.
- Keep every high-value action inside one focused canvas.

```text
+--------------------------------------------------+
| Back                       Phrase Name    Status |
| Song title                                         |
+--------------------------------------------------+
| Video strip / waveform overview                    |
| ------------------------------------------------ |
|         A==========playhead===========B           |
| ------------------------------------------------ |
+--------------------------------------------------+
|                  [ Play / Pause ]                 |
|          -5s                         +5s          |
+--------------------------------------------------+
| Speed                     Pitch                   |
|   85%                     -2 key                  |
| [ - ] [ stepper ] [ + ]   [ - ] [ stepper ] [+ ]|
+--------------------------------------------------+
| Loop                                            |
| [ Loop On ]      A 00:48       B 01:06          |
+--------------------------------------------------+
| Recording                                         |
| [ big record button ]   input meter              |
| latest take: today                                |
| [ Save Practice Note ]   [ Open Takes ]          |
+--------------------------------------------------+
```

Key interaction upgrades:

- Stronger A/B selection visualization.
- Larger playback target.
- Recording block treated as a separate stateful panel.
- "Open Takes" surfaced directly from the practice screen.

### 4. Progress

Purpose:

- Replace passive statistics with visible improvement.
- Make Premium value easier to understand through comparison and all-time views.

```text
+--------------------------------------------------+
| Progress                                          |
| [ 7d ] [ 30d ] [ All Time ]                      |
| [ All Songs ] [ Selected Song ] [ Phrase ]       |
+--------------------------------------------------+
| Summary Row                                       |
| sessions | minutes | recordings | streak         |
+--------------------------------------------------+
| Phrase Mastery                                    |
| phrase name                 Active / Mastered     |
| progress bar                last practiced        |
| [ Practice ]                                      |
+--------------------------------------------------+
| Takes & Compare                                   |
| Slot A card                 Slot B card           |
| [ Compare Takes ]                                |
+--------------------------------------------------+
| Weekly Activity                                   |
| mini bars / heat blocks                           |
+--------------------------------------------------+
```

For the first refresh, `Progress` can still reuse the current Stats data model and grow visually first.

## Design System Notes

### Component Set To Introduce

- `HeroHeaderCard`
- `PrimaryActionCard`
- `PracticeControlPanel`
- `FilterChipRow`
- `ProgressSummaryTile`
- `PhraseStatusChip`
- `EmptyStateCard`

### Existing Components Worth Reusing

- `StudioCard`
- `ProgressPlayButton`
- `WaveformPlaceholderView`
- `VideoPlaybackDisplayView`
- `InputLevelMeterView`
- `MetricTile`

### Theme Refresh Scope

Update these first:

- `PhraseRise/Utilities/Theme/AppColors.swift`
- `PhraseRise/Utilities/Theme/AppTypography.swift`
- `PhraseRise/Utilities/StudioStyle.swift`
- `PhraseRise/Views/Components/StudioCard.swift`

## Recommended Implementation Order

The order below is optimized for maximum visible improvement with minimum navigation breakage.

### Phase 1: Foundation

Goal:

- Refresh the design language before changing screen hierarchy.

Work:

- Expand color tokens for panel states, chips, recording emphasis, success states.
- Tighten typography hierarchy for hero numbers, labels, and cards.
- Create shared card and chip components.
- Update tab bar tint, backgrounds, elevation, and spacing rhythm.

Likely files:

- `PhraseRise/Utilities/Theme/AppColors.swift`
- `PhraseRise/Utilities/Theme/AppTypography.swift`
- `PhraseRise/Utilities/Theme/AppSpacing.swift`
- `PhraseRise/Utilities/StudioStyle.swift`
- `PhraseRise/Views/Components/*`
- `PhraseRise/App/RootTabView.swift`

Why first:

- Every later screen benefits immediately.
- Reduces duplicate styling work inside each feature screen.

### Phase 2: Today Tab

Goal:

- Ship a new landing experience without breaking existing practice flows.

Work:

- Add `TodayView`.
- Add `TodayViewModel`.
- Make `Today` the default selected tab.
- Add resume practice card, focus phrase cards, recent source section, weekly summary row.

Likely files:

- `PhraseRise/App/RootTabView.swift`
- `PhraseRise/Views/Today/TodayView.swift`
- `PhraseRise/ViewModels/TodayViewModel.swift`
- shared components created in Phase 1

Why second:

- Biggest UX win for the least invasive data work.
- Gives the app a new identity immediately.

### Phase 3: Practice Player Refresh

Goal:

- Upgrade the highest-value screen before polishing deeper list screens.

Work:

- Re-layout `PracticePlayerView` into clearer control zones.
- Strengthen loop range visuals.
- Surface takes shortcut from the practice screen.
- Make recording state feel more premium and live.

Likely files:

- `PhraseRise/Views/Practice/PracticePlayerView.swift`
- `PhraseRise/ViewModels/PracticePlayerViewModel.swift`
- `PhraseRise/Views/Components/WaveformPlaceholderView.swift`
- `PhraseRise/Views/Practice/PracticeRecordSheet.swift`

Why third:

- This is the screen users remember.
- Makes the redesign feel real, not cosmetic.

### Phase 4: Library Refresh

Goal:

- Bring source browsing and phrase browsing up to the same quality level.

Work:

- Reframe `SongsView` as `Library`.
- Refresh song list cards and song detail summary.
- Improve phrase list hierarchy and quick actions.
- Align phrase editor with the new practice visual language.

Likely files:

- `PhraseRise/Views/Songs/SongsView.swift`
- `PhraseRise/Views/Songs/SongDetailView.swift`
- `PhraseRise/Views/Practice/PhraseEditorView.swift`
- `PhraseRise/ViewModels/SongDetailViewModel.swift`

Why fourth:

- After `Today` exists, Library becomes secondary.
- Good place to consolidate visual consistency once the new direction is proven.

### Phase 5: Progress Refresh

Goal:

- Transform Stats into a motivation screen.

Work:

- Replace plain metric rows with summary tiles and phrase progress cards.
- Promote compare takes section.
- Improve filters visually before changing analytics depth.
- Optionally rename `StatsView` to `ProgressView`.

Likely files:

- `PhraseRise/Views/Stats/StatsView.swift` or new `PhraseRise/Views/Progress/ProgressView.swift`
- `PhraseRise/ViewModels/StatsViewModel.swift`
- `PhraseRise/Views/Practice/RecordingListView.swift`

Why fifth:

- Reuses the same data model while delivering a much better story.
- Lower urgency than Today and Practice.

### Phase 6: Settings And Paywall Polish

Goal:

- Finish the experience with the same premium feel.

Work:

- Refresh Settings sections into cleaner cards.
- Make Premium explanation clearer and more benefit-led.
- Align Paywall with the new visual system.

Likely files:

- `PhraseRise/Views/Settings/SettingsView.swift`
- `PhraseRise/Views/Settings/PaywallView.swift`
- `PhraseRise/ViewModels/PaywallViewModel.swift`

Why last:

- Important, but not the part that defines daily use.

## Release Plan

If you want to break this into smaller shipments:

### Release A

- Phase 1 Foundation
- Phase 2 Today
- Phase 3 Practice Player

Result:

- The app feels new on day one.
- Practice flow gets meaningfully better.

### Release B

- Phase 4 Library
- Phase 5 Progress
- Phase 6 Settings / Paywall

Result:

- Full-system consistency.
- Better retention and premium storytelling.

## Build Notes

### What We Can Reuse Without Data Migration

- phrase counts
- recording counts
- recent activity
- latest take summary
- time range filters
- practice duration totals

### What Can Wait Until Later

- true mastery scoring model
- streak persistence beyond derived practice records
- personalized recommendations
- richer analytics charts

## First Implementation Ticket Breakdown

If starting immediately, this is the cleanest first batch:

1. Add design tokens and shared card/chip components.
2. Add `TodayView` and wire it into `RootTabView`.
3. Build resume card and focus phrase list from existing repositories.
4. Refresh `PracticePlayerView` layout without changing services.

That gives a visible redesign fast while preserving the current data and audio behavior.
