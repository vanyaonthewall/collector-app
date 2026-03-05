# Collector's App - Vision & Strategy

## Core Feature
App for collectors to organize items by removing backgrounds and sorting them into folders.

## User Flow
1. Empty State: Show "Take Photo" button.
2. Active State: List of Folders (Grid).
3. Capture: Custom Camera -> Vision Subject Lifting -> Preview (Cutout).
4. Organization: Prompt to select folder or create new one.
5. Management: Move/Delete items, rename by tapping label.

## Technical Constraints (Strict)
- Persistence: SwiftData (Models: Folder, Item).
- Image Processing: Apple Vision Framework (Native Subject Lifting).
- Storage: Store images as PNGs in FileSystem, store UUID paths in SwiftData.
- Naming: Automatic "Item #[number]", editable via TextField.
- UI: Native SwiftUI, Material Design-like feel but using SF Symbols.