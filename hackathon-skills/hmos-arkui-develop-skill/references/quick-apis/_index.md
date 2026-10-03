# ArkUI API Parameter Quick Reference Index

Each category is stored in a separate file for on-demand reading. Component cards normally include a constructor, parameter table, properties, methods, and events.

## Category Files

| File | Category |
|---|---|
| [01-layout.md](01-layout.md) | Layout containers |
| [02-basic-components.md](02-basic-components.md) | Basic components |
| [03-data-display.md](03-data-display.md) | Data display components |
| [04-selectors.md](04-selectors.md) | Selector components |
| [05-media.md](05-media.md) | Media and drawing components |
| [06-advanced.md](06-advanced.md) | Advanced and composite components |
| [07-security.md](07-security.md) | Security components |
| [08-state-decorators.md](08-state-decorators.md) | State-management decorators |
| [09-animation.md](09-animation.md) | Animation APIs |
| [10-gesture.md](10-gesture.md) | Gestures and events |
| [11-dialog-menu.md](11-dialog-menu.md) | Dialogs, menus, and modals |
| [12-navigation.md](12-navigation.md) | Navigation and routing |
| [13-rendering.md](13-rendering.md) | Rendering control |
| [14-extension.md](14-extension.md) | Custom extensions |
| [15-theme-style.md](15-theme-style.md) | Themes and styles |
| [16-enums.md](16-enums.md) | Enum quick reference |
| [17-resources.md](17-resources.md) | System resource names |

## Component Lookup

Use `rg "^### ComponentName" <file>` to locate a component card. The primary component groups are:

- Layout: Row, Column, Flex, Stack, List, Grid, WaterFlow, Scroll, Tabs, Swiper, RelativeContainer, SideBarContainer, Panel, Refresh, Badge, Counter, and AlphabetIndexer.
- Basic components: Text, Span, ImageSpan, SymbolSpan, SymbolGlyph, TextInput, TextArea, Button, Image, Slider, Toggle, Radio, Checkbox, CheckboxGroup, Progress, Rating, LoadingProgress, Search, Select, and RichEditor.
- Data display: Gauge, DataPanel, QRCode, CalendarPicker, TextClock, and TextTimer.
- Selectors: DatePicker, TimePicker, TextPicker, and PatternLock.
- Media: Video, Canvas, and Shape.
- Security: SaveButton and PasteButton.
- Dialogs and menus: dialog APIs, CustomDialogController, Menus, Popup, and Modals.
- Navigation: Navigation, NavPathStack, NavDestination, and Router.

For the large layout, basic-component, and resource files, search for the specific component or resource name instead of reading the entire file.
