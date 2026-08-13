// ApinRadius.swift
// Apin
//
// T1 — corner-radius token layer, translated from `design_handoff_apin/apin-green.css`'s
// `--radius-*` custom properties (`:root` block), plus the handoff README's "pills use
// 100px" convention (`design_handoff_apin/README.md`, "Design tokens" table) -- pill-shaped
// controls (composer field, follow-up chips, tag pills) use a radius at least half their
// height, so `pill` is a large-but-finite constant rather than a special "fully rounded"
// case; call sites should still prefer `Capsule()`/`.clipShape(.capsule)` where a true
// stadium shape (not a fixed-radius rounded rect) is what the handoff describes.

import CoreFoundation

/// Namespace for Apin's design-token corner radii. No cases -- `case`-less enum used
/// purely as an uninstantiable constant namespace (see `ApinColor.swift` for the same
/// pattern/rationale).
enum ApinRadius {

    /// --radius-sm: 4px
    static let small: CGFloat = 4

    /// --radius-md: 8px
    static let medium: CGFloat = 8

    /// --radius-lg: 14px
    static let large: CGFloat = 14

    /// Handoff README "Design tokens" table: "pills use 100px" (composer field, follow-up
    /// chips, tag pills). Not an `apin-green.css` `--radius-*` custom property itself, but
    /// documented as part of the same token table -- kept here rather than duplicated per
    /// call site once Stage B consumes it.
    static let pill: CGFloat = 100
}
