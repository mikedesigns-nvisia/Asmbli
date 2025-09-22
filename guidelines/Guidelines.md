# Asmbli Design System Guidelines

## Layout & Width Constraints

### Maximum Width Guidelines
* The entire application must fit within a **1440px maximum width** container
* Use `max-w-[1440px]` for the main layout container
* Content should be responsive and work well on screens from 320px to 1440px

### Three-Panel Layout Structure
* **Left Sidebar**: 240px wide (`w-60`) - Hidden on mobile (`hidden lg:block`)
* **Main Content**: Flexible width with max-width constraints (`max-w-4xl mx-auto`)
* **Right Panel**: 320px wide (`w-80`) - Hidden on mobile and tablet (`hidden xl:block`)

### Responsive Breakpoints
* **Mobile**: < 768px - Single column, collapsible panels
* **Tablet**: 768px - 1024px - Show sidebar, hide right panel
* **Desktop**: 1024px - 1440px - Show all three panels
* **Large Desktop**: > 1440px - Center the 1440px container

## Content Width Guidelines

### Main Content Area
* Maximum content width: 1024px (`max-w-4xl`)
* Use responsive padding: `px-4 lg:px-8`
* Grid layouts should use responsive classes:
  - `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`
  - Never exceed the container width

### Card and Component Sizing
* Cards should use responsive grids to prevent overflow
* Use `gap-4 lg:gap-6` for consistent spacing
* Text content should wrap properly with `max-w-2xl` for readability

## Mobile-First Responsive Design

### Navigation
* Use mobile overlay panels for sidebar and right panel
* Include hamburger menu button for mobile navigation
* Implement proper z-index stacking (z-50 for overlays)

### Interactive Elements
* Touch-friendly button sizes (minimum 44px tap targets)
* Proper spacing between interactive elements
* Use hover states only on devices that support them

### Typography
* Use responsive text sizes: `text-sm lg:text-base`
* Maintain readable line heights and letter spacing
* Scale font sizes appropriately for different screen sizes

## Component Guidelines

### Grids and Layouts
* Always use responsive grid classes
* Prefer CSS Grid and Flexbox over absolute positioning
* Use utility classes like `.responsive-grid-2`, `.responsive-grid-3`

### Spacing
* Use consistent spacing scale from globals.css
* Apply responsive spacing: `space-y-6 lg:space-y-8`
* Use responsive padding: `p-4 lg:p-6`

### Animations and Transitions
* Keep animations subtle and performant
* Use `transition-all duration-300` for smooth interactions
* Ensure animations don't cause layout shift

## Accessibility & Performance

### Screen Reader Support
* Use semantic HTML elements
* Provide proper ARIA labels for interactive elements
* Ensure proper heading hierarchy

### Performance Considerations
* Lazy load content below the fold
* Use efficient CSS selectors
* Minimize layout thrashing with proper CSS
<!--

System Guidelines

Use this file to provide the AI with rules and guidelines you want it to follow.
This template outlines a few examples of things you can add. You can add your own sections and format it to suit your needs

TIP: More context isn't always better. It can confuse the LLM. Try and add the most important rules you need

# General guidelines

Any general rules you want the AI to follow.
For example:

* Only use absolute positioning when necessary. Opt for responsive and well structured layouts that use flexbox and grid by default
* Refactor code as you go to keep code clean
* Keep file sizes small and put helper functions and components in their own files.

--------------

# Design system guidelines
Rules for how the AI should make generations look like your company's design system

Additionally, if you select a design system to use in the prompt box, you can reference
your design system's components, tokens, variables and components.
For example:

* Use a base font-size of 14px
* Date formats should always be in the format “Jun 10”
* The bottom toolbar should only ever have a maximum of 4 items
* Never use the floating action button with the bottom toolbar
* Chips should always come in sets of 3 or more
* Don't use a dropdown if there are 2 or fewer options

You can also create sub sections and add more specific details
For example:


## Button
The Button component is a fundamental interactive element in our design system, designed to trigger actions or navigate
users through the application. It provides visual feedback and clear affordances to enhance user experience.

### Usage
Buttons should be used for important actions that users need to take, such as form submissions, confirming choices,
or initiating processes. They communicate interactivity and should have clear, action-oriented labels.

### Variants
* Primary Button
  * Purpose : Used for the main action in a section or page
  * Visual Style : Bold, filled with the primary brand color
  * Usage : One primary button per section to guide users toward the most important action
* Secondary Button
  * Purpose : Used for alternative or supporting actions
  * Visual Style : Outlined with the primary color, transparent background
  * Usage : Can appear alongside a primary button for less important actions
* Tertiary Button
  * Purpose : Used for the least important actions
  * Visual Style : Text-only with no border, using primary color
  * Usage : For actions that should be available but not emphasized
-->
