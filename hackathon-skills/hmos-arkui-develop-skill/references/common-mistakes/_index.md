# AI Common Mistakes Index

> **Document purpose: prevention tool, not a review tool.**
>
> When to use:
> 1. **Before coding**: Quickly scan Sections 1-2 (imports and UIContext); these errors occur most often.
> 2. **While coding**: Check Section 7 (attribute and parameter misuse) when writing attributes and parameters, and check other sections by feature type (state management: Sections 3-5; list rendering: Section 6; navigation: Section 8; @Builder reuse: Section 12; state not refreshing: Section 13).
> 3. **During review**: Check each item against the list; every item includes a constraint-rule section number for further reading.

| File | Section | Topic | When to use |
|------|------|------|----------|
| [01-import.md](common-mistakes/01-import.md) | Section 1 | Import path and module errors | Always scan before coding |
| [02-uicontext.md](common-mistakes/02-uicontext.md) | Section 2 | Global APIs not called through UIContext | Always scan before coding |
| [03-v1v2-mix.md](common-mistakes/03-v1v2-mix.md) | Section 3 | Mixing V1/V2 state management | While coding |
| [04-decorator-position.md](common-mistakes/04-decorator-position.md) | Section 4 | Decorators used in the wrong position | While coding |
| [05-build-violations.md](common-mistakes/05-build-violations.md) | Section 5 | Invalid operations inside build() | While coding |
| [06-foreach.md](common-mistakes/06-foreach.md) | Section 6 | ForEach / LazyForEach errors | While coding |
| [07-attribute-params.md](common-mistakes/07-attribute-params.md) | Section 7 | Attribute and API parameter misuse | While coding |
| [08-navigation.md](common-mistakes/08-navigation.md) | Section 8 | Navigation and routing errors | While coding |
| [09-nesting-naming.md](common-mistakes/09-nesting-naming.md) | Section 9 | Component nesting and naming conflicts | During review |
| [10-type-annotation.md](common-mistakes/10-type-annotation.md) | Section 10 | Omitted state variable types | During review |
| [11-deprecated.md](common-mistakes/11-deprecated.md) | Section 11 | Use of deprecated APIs | During review |
| [12-builder-params.md](common-mistakes/12-builder-params.md) | Section 12 | @Builder parameter passing errors (no refresh/parameter mismatch) | While coding |
| [13-observed-no-refresh.md](common-mistakes/13-observed-no-refresh.md) | Section 13 | @Observed/@ObjectLink refresh failures | While coding |
