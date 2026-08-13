// ApinSpacing.swift
// Apin
//
// T1 — spacing-token layer, translated from `design_handoff_apin/apin-green.css`'s
// `--space-*` custom properties (`:root` block). Values are plain `CGFloat` point sizes --
// CSS px and SwiftUI/UIKit points are 1:1 for this project (no separate device-pixel-ratio
// concern at the design-token level), so no conversion beyond unit-stripping is needed here.

import CoreFoundation

/// Namespace for Apin's design-token spacing scale. No cases -- `case`-less enum used
/// purely as an uninstantiable constant namespace (see `ApinColor.swift` for the same
/// pattern/rationale).
enum ApinSpacing {

    /// --space-1: 2.8px
    static let space1: CGFloat = 2.8

    /// --space-2: 5.6px
    static let space2: CGFloat = 5.6

    /// --space-3: 8.4px
    static let space3: CGFloat = 8.4

    /// --space-4: 11.2px
    static let space4: CGFloat = 11.2

    /// --space-6: 16.8px
    static let space6: CGFloat = 16.8

    /// --space-8: 22.4px
    static let space8: CGFloat = 22.4
}
