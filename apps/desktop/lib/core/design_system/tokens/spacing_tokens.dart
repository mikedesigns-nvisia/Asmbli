// Golden Ratio Spacing System (φ = 1.618)
// Base unit of 8px with golden ratio multipliers for harmonious proportions
class SpacingTokens {
 // Golden ratio constant
 static const double phi = 1.618;
 
 // Base unit (8px) - follows 8pt grid system
 static const double baseUnit = 8.0;
 
 // Golden ratio spacing scale
 static const double none = 0.0;
 static const double xs = baseUnit * 0.5; // 4px
 static const double sm = baseUnit; // 8px
 static const double md = baseUnit * phi * 0.5; // ~6.5px (rounded to 6)
 static const double lg = baseUnit * phi; // ~13px (rounded to 13)
 static const double xl = baseUnit * phi * phi; // ~21px (rounded to 21)
 static const double xxl = baseUnit * phi * phi * phi; // ~34px
 static const double xxxl = baseUnit * phi * phi * phi * phi; // ~55px
 static const double huge = baseUnit * phi * phi * phi * phi * phi; // ~89px
 
 // Rounded golden ratio values for practical use
 static const double xs_precise = 4.0;
 static const double sm_precise = 8.0;
 static const double md_precise = 13.0; // baseUnit * phi
 static const double lg_precise = 21.0; // baseUnit * phi²
 static const double xl_precise = 34.0; // baseUnit * phi³
 static const double xxl_precise = 55.0; // baseUnit * phi⁴
 static const double xxxl_precise = 89.0; // baseUnit * phi⁵
 
 // Layout specific golden ratio spacing
 static const double pageHorizontal = xl_precise; // 34px - page margins
 static const double pageVertical = xl_precise; // 34px - page vertical spacing
 static const double headerPadding = xl_precise; // 34px - header padding
 static const double sectionSpacing = xxl_precise; // 55px - between major sections
 static const double elementSpacing = lg_precise; // 21px - between elements
 static const double componentSpacing = md_precise; // 13px - within components
 
 // Component specific golden ratio spacing
 static const double buttonPadding = lg_precise; // 21px - button horizontal padding
 static const double buttonPaddingVertical = md_precise; // 13px - button vertical padding
 static const double cardPadding = lg_precise; // 21px - card internal padding
 static const double cardSpacing = md_precise; // 13px - card element spacing
 static const double iconSpacing = sm_precise; // 8px - icon to text spacing
 static const double listItemSpacing = md_precise; // 13px - list item spacing
 
 // Text spacing (golden ratio for typography)
 static const double textLineSpacing = sm_precise; // 8px - small line spacing
 static const double textParagraphSpacing = lg_precise; // 21px - paragraph spacing
 static const double textSectionSpacing = xl_precise; // 34px - section spacing
}

class BorderRadiusTokens {
 static const double none = 0.0;
 static const double sm = 4.0;
 static const double md = 6.0; // Your standard button radius
 static const double lg = 8.0; // Your input radius
 static const double xl = 12.0; // Your card radius
 static const double pill = 999.0;
}