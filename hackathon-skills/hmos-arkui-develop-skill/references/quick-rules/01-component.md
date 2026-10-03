## 1. Basic Custom Component Constraints

| Rule | Description |
|------|------|
| No struct inheritance | Custom components use struct and **cannot inherit** |
| No name conflicts | Custom component, class, and function names **must not duplicate system component names** |
| One @Entry | A single UI page **may contain only one** custom component decorated with @Entry |
| @Component and @ComponentV2 are exclusive | **Cannot use both** @ComponentV2 and @Component on the same struct |
| @ComponentV2 uses V2 decorators only | @ComponentV2 **only supports** V2 decorators such as @Local, @Param, @Once, @Event, @Provider, and @Consumer; V1 features such as LocalStorage are unsupported |
| build() is required | A custom component **must define** a build() function |
| Avoid static members | Member functions and variables are accessed inside the component; **do not declare them static** |
| V1 does not support static blocks | In @Component or @CustomDialog components, static blocks **are not executed** (compile warning from API version 22). @ComponentV2 supports them |
| Components do not require new | **Do not use the new keyword** when creating components |
| Arrow-function this rule | **Use arrow functions** for event binding; anonymous functions are not allowed in ArkTS |
| Member properties must avoid built-in method names | @Component/@ComponentV2 struct properties **must not use** ArkUI chain method names (`id`/`width`/`height`/`margin`/`padding`/`offset`/`position`, etc.). They conflict with `CustomComponent` base methods -> **10505001**; use names such as `xxxId`/`xxxWidth` |
