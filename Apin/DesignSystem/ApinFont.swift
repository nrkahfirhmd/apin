// ApinFont.swift
// Apin
//
// T1 — font/type-scale token layer. `design_handoff_apin/README.md`'s "Type." paragraph
// explicitly sanctions this substitution: "Inter throughout (headings and body), heading
// weight 500 -- never bolder... On iOS, substitute SF Pro if Inter isn't bundled, but keep
// the weights and sizes." No `.ttf`/`.otf` font asset exists anywhere in this repo (`Glob`
// for `**/*.ttf`/`**/*.otf` returns nothing, confirmed this session) -- bundling Inter would
// be new asset/licensing/maintenance surface the handoff itself waives, so every constant
// below uses `Font.system(size:weight:design:)`, which resolves to SF Pro (`.default`
// design) / the platform monospace (`.monospaced` design) on iOS. No bundled font file is
// referenced anywhere in this file.
//
// CSS `font-weight: 500` maps to SwiftUI's `Font.Weight.medium` (Apple's own documented
// numeric-weight-to-case mapping: 400 -> .regular, 500 -> .medium, 600 -> .semibold, 700 ->
// .bold); `apin-green.css`'s `--font-heading-weight: 500` and body's plain 400 weight are
// carried through as `headingWeight`/`bodyWeight` below.
//
// Only font **size and weight** are modeled as `Font` values here, matching this task's
// acceptance criteria ("Font helpers exist covering the handoff's specified type
// scale/weights"). Letter-spacing and line-height are documented per constant as comments
// (sourced from `apin-green.css` and `design_handoff_apin/README.md`'s per-component
// layout notes) for whichever Stage B call site applies them via `.tracking(_:)` /
// `.lineSpacing(_:)`, rather than baked into a conversion here -- CSS `letter-spacing`
// (em, relative to font size) and `line-height` (unitless multiplier or fixed px) do not
// map 1:1 onto SwiftUI's point-based `.tracking`/`.lineSpacing` modifiers, and guessing a
// conversion formula here (rather than letting the consuming view tune it against the
// actual rendered text) risked being a false-precision "drop-in" that reads as more
// authoritative than it is.

import SwiftUI

/// Namespace for Apin's design-token type scale. No cases -- `case`-less enum used purely
/// as an uninstantiable constant namespace (see `ApinColor.swift` for the same
/// pattern/rationale).
enum ApinFont {

    // MARK: - Weights (`apin-green.css` `--font-heading-weight` / body default)

    /// --font-heading-weight: 500
    static let headingWeight: Font.Weight = .medium

    /// Body default (unset in CSS = the UA/browser default, 400).
    static let bodyWeight: Font.Weight = .regular

    // MARK: - Base scale (`apin-green.css` global `h1`-`h6`/`body` rules)

    // h1: 42px / 500 / line-height 1.12 / letter-spacing -0.015em. Named `h1` (matching
    // apin-green.css's rule name exactly) rather than `heading1`.
    // swiftlint:disable:next identifier_name
    static let h1 = Font.system(size: 42, weight: headingWeight, design: .default)

    // h2: 32px / 500 / line-height 1.12 / letter-spacing -0.015em
    // swiftlint:disable:next identifier_name
    static let h2 = Font.system(size: 32, weight: headingWeight, design: .default)

    // h3: 25px / 500 / line-height 1.12 / letter-spacing -0.015em
    // swiftlint:disable:next identifier_name
    static let h3 = Font.system(size: 25, weight: headingWeight, design: .default)

    // h4: 20px / 500 / line-height 1.12 / letter-spacing -0.015em
    // swiftlint:disable:next identifier_name
    static let h4 = Font.system(size: 20, weight: headingWeight, design: .default)

    // h5: 16px / 500 / line-height 1.12 / letter-spacing -0.015em
    // swiftlint:disable:next identifier_name
    static let h5 = Font.system(size: 16, weight: headingWeight, design: .default)

    // h6: 13px / 500 / line-height 1.12 / letter-spacing 0.08em / uppercase (applied by
    // the consumer via `.textCase(.uppercase)`, not baked into the font itself).
    // swiftlint:disable:next identifier_name
    static let h6 = Font.system(size: 13, weight: headingWeight, design: .default)

    /// Body base: 15px / 400 / line-height 1.55 (`body { font-size: 15px; line-height:
    /// 1.55; font-weight: 400; }`).
    static let bodyBase = Font.system(size: 15, weight: bodyWeight, design: .default)

    // MARK: - Ask screen (`design_handoff_apin/README.md`, "Ask + answer" section)

    /// Wordmark "Apin": heading 500, 22px, line-height 1, letter-spacing -0.02em.
    static let wordmark = Font.system(size: 22, weight: headingWeight, design: .default)

    /// Offline marker ("THIS PHONE ONLY"): monospace 10px, uppercase, letter-spacing 0.1em.
    static let offlineMarker = Font.system(size: 10, weight: bodyWeight, design: .monospaced)

    /// Journal button live entry count: body font, 500, 12px.
    static let journalButtonCount = Font.system(size: 12, weight: headingWeight, design: .default)

    /// Empty-state greeting ("What are you wondering, Kv?"): heading 500, 27px, line-height
    /// 1.2, letter-spacing -0.02em.
    static let greeting = Font.system(size: 27, weight: headingWeight, design: .default)

    /// Empty-state subtitle: body 400, 14px, line-height 1.6.
    static let emptyStateSubtitle = Font.system(size: 14, weight: bodyWeight, design: .default)

    /// Empty-state suggestion buttons: body 400, 13px, line-height 1.35.
    static let suggestionButton = Font.system(size: 13, weight: bodyWeight, design: .default)

    /// Question message text: heading 500, 17px, line-height 1.4, letter-spacing -0.01em.
    static let questionMessage = Font.system(size: 17, weight: headingWeight, design: .default)

    /// Answer message body: body 400, 15px, line-height 1.62.
    static let answerBody = Font.system(size: 15, weight: bodyWeight, design: .default)

    /// Apin's follow-up question line: body 400, 14px, line-height 1.5.
    static let followUpQuestion = Font.system(size: 14, weight: bodyWeight, design: .default)

    /// Follow-up chip label: body 400, 12.5px.
    static let chip = Font.system(size: 12.5, weight: bodyWeight, design: .default)

    /// Meta row ("SAVED · TODAY · HH:MM"): monospace 10px, uppercase, letter-spacing 0.08em.
    static let metaRow = Font.system(size: 10, weight: bodyWeight, design: .monospaced)

    /// Topic tag pill label (Ask meta row + Journal entry row -- same style both places):
    /// monospace 10px.
    static let tagPill = Font.system(size: 10, weight: bodyWeight, design: .monospaced)

    /// Composer text field: body 15px, placeholder "Ask Apin…".
    static let composerField = Font.system(size: 15, weight: bodyWeight, design: .default)

    /// Composer caption ("every answer files itself · no network"): monospace 10.5px,
    /// letter-spacing 0.06em.
    static let composerCaption = Font.system(size: 10.5, weight: bodyWeight, design: .monospaced)

    // MARK: - Journal screen (`design_handoff_apin/README.md`, "Journal" section)

    /// Journal title "Journal": heading 500, 22px, letter-spacing -0.02em (same
    /// size/weight as `wordmark`, kept as a separate named constant since it's a distinct
    /// call site the handoff documents separately).
    static let journalTitle = Font.system(size: 22, weight: headingWeight, design: .default)

    /// "<n> entries · offline": monospace 11px.
    static let journalEntriesCount = Font.system(size: 11, weight: bodyWeight, design: .monospaced)

    /// Week-strip day letter (M/T/W/T/F/S/S): monospace 9px.
    static let weekStripDayLabel = Font.system(size: 9, weight: bodyWeight, design: .monospaced)

    /// Day header full date ("Wednesday 12 August"): heading 500, 13px.
    static let dayHeaderDate = Font.system(size: 13, weight: headingWeight, design: .default)

    /// Day header entry count ("3 entries"): monospace 10px, uppercase, letter-spacing
    /// 0.08em (same style as `metaRow`, kept separate as it's a distinct documented call
    /// site).
    static let dayHeaderCount = Font.system(size: 10, weight: bodyWeight, design: .monospaced)

    /// Entry row time gutter (e.g. "14:02"): monospace 10px.
    static let entryRowTime = Font.system(size: 10, weight: bodyWeight, design: .monospaced)

    /// Entry row question: heading 500, 15px, **fixed 26px line-height** (not a multiplier
    /// -- the ruled-page layout needs the text baseline to land on the page's 26px rule
    /// spacing; apply via `.lineSpacing(_:)` tuned against the actual rule graphic, not a
    /// generic multiplier).
    static let entryRowQuestion = Font.system(size: 15, weight: headingWeight, design: .default)

    /// Entry row excerpt (first sentence of the answer): body 400, 13px, **fixed 26px
    /// line-height** (same ruled-page constraint as `entryRowQuestion`).
    static let entryRowExcerpt = Font.system(size: 13, weight: bodyWeight, design: .default)
}
