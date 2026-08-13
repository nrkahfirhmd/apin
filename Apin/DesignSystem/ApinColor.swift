// ApinColor.swift
// Apin
//
// T1 — design-token color layer, translated from `design_handoff_apin/apin-green.css`'s
// `:root` block ("Apin — Nocturne retuned to a green ground"). This is a namespace of
// constants (`enum ApinColor` with no cases, per Swift's standard "uninstantiable
// namespace" idiom), not a type with instance state — grouping these constants in one file
// does not conflict with `memory/coding-standards.md`'s one-primary-type-per-file rule,
// which is about types with real identity/behavior, not flat constant namespaces.
//
// Verified this session (Xcode 26, iPhoneOS 26.5 SDK): neither `SwiftUICore`'s
// `Color.RGBColorSpace` (`case sRGB`, `case sRGBLinear`, `case displayP3` only, confirmed by
// reading `SwiftUICore.swiftinterface` directly) nor `UIKit.swiftinterface` contains any
// OKLCH-related initializer or case — grep for "oklch" (case-insensitive) returns zero
// matches in both. This confirms `planning/engineering-plan.md`'s Architecture Decisions
// assumption ("No SwiftUI/UIKit OKLCH initializer is known to exist as of iOS 26") as a
// directly-checked fact, not carried forward as an assumption.
//
// Every color below is therefore pre-converted from `oklch(...)` to sRGB component values
// at token-definition time (OKLab -> linear sRGB -> gamma-encoded sRGB, Björn Ottosson's
// public OKLab conversion matrices, D65 sRGB primaries; standard piecewise sRGB transfer
// function for the gamma step), constructed via `Color(.sRGB, red:green:blue:opacity:)` so
// there is no ambiguity about which color space the stored components are already in. The
// source `oklch(...)` string is kept as a comment directly above every constant so a future
// re-tune of `apin-green.css` (its own header: "retune it here") can be re-derived from the
// same source values, not reverse-engineered from an sRGB triple.
//
// `--color-accent-2` and its `-100...-900` ramp are numerically identical to `--color-accent`
// and its ramp in `apin-green.css` (same L/C, same hue 152) -- named `accentSecondary*` here
// (clearer in Swift than a literal `accent2`) but intentionally kept as their own constants,
// mirroring the CSS source's own duplication, rather than aliased to `accent*`, so a future
// re-tune that diverges the two ramps doesn't require restructuring this file.
//
// `deckSection*` corresponds to `--color-section`/`-glow`/`-ghost`, which `apin-green.css`'s
// own comment marks "Deck-scale fills only — not interface colors" (i.e. used by the design
// system's own documentation deck, not by Apin's app UI). Included here only because
// T1's acceptance criteria requires coverage of every color `apin-green.css`'s `:root` block
// names; no `Features/*` call site is expected to reach for these.

import SwiftUI

/// Namespace for Apin's design-token colors, translated from `apin-green.css`'s `:root`
/// block. No cases -- `case`-less enum used purely as an uninstantiable constant namespace.
enum ApinColor {

    // MARK: - Base surfaces & text

    // oklch(0.220 0.030 155). Named `bg` (not e.g. `background`) to match
    // apin-green.css's `--color-bg` token exactly.
    // swiftlint:disable:next identifier_name
    static let bg = Color(.sRGB, red: 0.0573, green: 0.1205, blue: 0.0800, opacity: 1.0)

    /// oklch(0.282 0.028 155)
    static let surface = Color(.sRGB, red: 0.1183, green: 0.1787, blue: 0.1384, opacity: 1.0)

    /// oklch(0.925 0.014 155)
    static let text = Color(.sRGB, red: 0.8758, green: 0.9142, blue: 0.8867, opacity: 1.0)

    /// oklch(0.925 0.014 155 / 0.16)
    static let divider = Color(.sRGB, red: 0.8758, green: 0.9142, blue: 0.8867, opacity: 0.16)

    // MARK: - Accent (primary)

    /// oklch(0.660 0.125 152)
    static let accent = Color(.sRGB, red: 0.3076, green: 0.6580, blue: 0.4201, opacity: 1.0)

    /// oklch(0.972 0.020 152)
    static let accent100 = Color(.sRGB, red: 0.9273, green: 0.9802, blue: 0.9383, opacity: 1.0)

    /// oklch(0.925 0.045 152)
    static let accent200 = Color(.sRGB, red: 0.8197, green: 0.9390, blue: 0.8462, opacity: 1.0)

    /// oklch(0.858 0.070 152)
    static let accent300 = Color(.sRGB, red: 0.6855, green: 0.8712, blue: 0.7298, opacity: 1.0)

    /// oklch(0.766 0.100 152)
    static let accent400 = Color(.sRGB, red: 0.5060, green: 0.7748, blue: 0.5784, opacity: 1.0)

    /// oklch(0.660 0.125 152) -- identical to `accent` (the ramp's own 500 step).
    static let accent500 = Color(.sRGB, red: 0.3076, green: 0.6580, blue: 0.4201, opacity: 1.0)

    /// oklch(0.560 0.115 152)
    static let accent600 = Color(.sRGB, red: 0.2113, green: 0.5307, blue: 0.3201, opacity: 1.0)

    /// oklch(0.455 0.095 152)
    static let accent700 = Color(.sRGB, red: 0.1452, green: 0.3976, blue: 0.2324, opacity: 1.0)

    /// oklch(0.355 0.075 152)
    static let accent800 = Color(.sRGB, red: 0.0889, green: 0.2773, blue: 0.1547, opacity: 1.0)

    /// oklch(0.255 0.055 152)
    static let accent900 = Color(.sRGB, red: 0.0367, green: 0.1653, blue: 0.0824, opacity: 1.0)

    // MARK: - Accent secondary (`--color-accent-2` in apin-green.css)

    /// oklch(0.734 0.083 152)
    static let accentSecondary = Color(.sRGB, red: 0.5060, green: 0.7231, blue: 0.5619, opacity: 1.0)

    /// oklch(0.972 0.020 152) -- identical to `accent100`, see file header.
    static let accentSecondary100 = Color(.sRGB, red: 0.9273, green: 0.9802, blue: 0.9383, opacity: 1.0)

    /// oklch(0.925 0.045 152) -- identical to `accent200`, see file header.
    static let accentSecondary200 = Color(.sRGB, red: 0.8197, green: 0.9390, blue: 0.8462, opacity: 1.0)

    /// oklch(0.858 0.070 152) -- identical to `accent300`, see file header.
    static let accentSecondary300 = Color(.sRGB, red: 0.6855, green: 0.8712, blue: 0.7298, opacity: 1.0)

    /// oklch(0.766 0.100 152) -- identical to `accent400`, see file header.
    static let accentSecondary400 = Color(.sRGB, red: 0.5060, green: 0.7748, blue: 0.5784, opacity: 1.0)

    /// oklch(0.660 0.125 152) -- identical to `accent500`, see file header.
    static let accentSecondary500 = Color(.sRGB, red: 0.3076, green: 0.6580, blue: 0.4201, opacity: 1.0)

    /// oklch(0.560 0.115 152) -- identical to `accent600`, see file header.
    static let accentSecondary600 = Color(.sRGB, red: 0.2113, green: 0.5307, blue: 0.3201, opacity: 1.0)

    /// oklch(0.455 0.095 152) -- identical to `accent700`, see file header.
    static let accentSecondary700 = Color(.sRGB, red: 0.1452, green: 0.3976, blue: 0.2324, opacity: 1.0)

    /// oklch(0.355 0.075 152) -- identical to `accent800`, see file header.
    static let accentSecondary800 = Color(.sRGB, red: 0.0889, green: 0.2773, blue: 0.1547, opacity: 1.0)

    /// oklch(0.255 0.055 152) -- identical to `accent900`, see file header.
    static let accentSecondary900 = Color(.sRGB, red: 0.0367, green: 0.1653, blue: 0.0824, opacity: 1.0)

    // MARK: - Neutral ramp

    /// oklch(0.965 0.010 155)
    static let neutral100 = Color(.sRGB, red: 0.9352, green: 0.9628, blue: 0.9430, opacity: 1.0)

    /// oklch(0.918 0.014 155)
    static let neutral200 = Color(.sRGB, red: 0.8668, green: 0.9051, blue: 0.8777, opacity: 1.0)

    /// oklch(0.855 0.018 155)
    static let neutral300 = Color(.sRGB, red: 0.7791, green: 0.8276, blue: 0.7931, opacity: 1.0)

    /// oklch(0.762 0.020 155)
    static let neutral400 = Color(.sRGB, red: 0.6599, green: 0.7125, blue: 0.6752, opacity: 1.0)

    /// oklch(0.655 0.022 155)
    static let neutral500 = Color(.sRGB, red: 0.5280, green: 0.5839, blue: 0.5445, opacity: 1.0)

    /// oklch(0.550 0.024 155)
    static let neutral600 = Color(.sRGB, red: 0.4039, green: 0.4625, blue: 0.4215, opacity: 1.0)

    /// oklch(0.448 0.026 155)
    static let neutral700 = Color(.sRGB, red: 0.2889, green: 0.3498, blue: 0.3076, opacity: 1.0)

    /// oklch(0.352 0.026 155)
    static let neutral800 = Color(.sRGB, red: 0.1899, green: 0.2479, blue: 0.2083, opacity: 1.0)

    /// oklch(0.248 0.026 155)
    static let neutral900 = Color(.sRGB, red: 0.0902, green: 0.1448, blue: 0.1085, opacity: 1.0)

    // MARK: - Deck-only (not used by Apin's app UI -- see file header)

    /// oklch(0.320 0.080 155)
    static let deckSection = Color(.sRGB, red: 0.0000, green: 0.2440, blue: 0.1245, opacity: 1.0)

    /// oklch(0.400 0.090 155)
    static let deckSectionGlow = Color(.sRGB, red: 0.0653, green: 0.3351, blue: 0.1935, opacity: 1.0)

    /// oklch(0.520 0.080 155)
    static let deckSectionGhost = Color(.sRGB, red: 0.2508, green: 0.4650, blue: 0.3311, opacity: 1.0)
}
