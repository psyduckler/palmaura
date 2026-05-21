import SwiftUI

/// Converts model-returned inline Markdown into SwiftUI-renderable attributed text.
///
/// The palm-reading API sometimes returns emphasis as `*text*`. Showing those
/// literal delimiters makes the report feel raw, so app copy should render the
/// emphasis while preserving non-Markdown stars like `5 * 3`.
enum InlineMarkdownFormatter {
    static func bodyAttributedString(
        from markdown: String,
        size: CGFloat = 15,
        baseItalic: Bool = false
    ) -> AttributedString {
        attributedString(
            from: markdown,
            baseFont: DesignSystem.FontToken.body(size, italic: baseItalic),
            emphasizedFont: DesignSystem.FontToken.body(size, italic: true),
            stronglyEmphasizedFont: DesignSystem.FontToken.body(size, italic: baseItalic).weight(.semibold),
            stronglyEmphasizedAndEmphasizedFont: DesignSystem.FontToken.body(size, italic: true).weight(.semibold)
        )
    }

    static func attributedString(
        from markdown: String,
        baseFont: Font = DesignSystem.FontToken.body(15),
        emphasizedFont: Font = DesignSystem.FontToken.body(15, italic: true),
        stronglyEmphasizedFont: Font = DesignSystem.FontToken.body(15).weight(.semibold),
        stronglyEmphasizedAndEmphasizedFont: Font = DesignSystem.FontToken.body(15, italic: true).weight(.semibold)
    ) -> AttributedString {
        let parsed = (try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )) ?? AttributedString(markdown)

        return applyingFonts(
            to: parsed,
            baseFont: baseFont,
            emphasizedFont: emphasizedFont,
            stronglyEmphasizedFont: stronglyEmphasizedFont,
            stronglyEmphasizedAndEmphasizedFont: stronglyEmphasizedAndEmphasizedFont
        )
    }

    private static func applyingFonts(
        to parsed: AttributedString,
        baseFont: Font,
        emphasizedFont: Font,
        stronglyEmphasizedFont: Font,
        stronglyEmphasizedAndEmphasizedFont: Font
    ) -> AttributedString {
        var output = parsed
        let runs = output.runs.map { run in
            (range: run.range, intent: run.inlinePresentationIntent)
        }

        for run in runs {
            let isEmphasized = run.intent?.contains(.emphasized) == true
            let isStrong = run.intent?.contains(.stronglyEmphasized) == true

            switch (isEmphasized, isStrong) {
            case (true, true):
                output[run.range].font = stronglyEmphasizedAndEmphasizedFont
            case (true, false):
                output[run.range].font = emphasizedFont
            case (false, true):
                output[run.range].font = stronglyEmphasizedFont
            case (false, false):
                output[run.range].font = baseFont
            }
        }

        return output
    }
}
