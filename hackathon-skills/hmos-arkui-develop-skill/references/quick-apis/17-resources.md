# 17. System Resource Name Reference

This reference covers the `sys.symbol` and `sys.color` resources supplied by the HarmonyOS SDK. Resource names must match the SDK exactly; an invalid name can cause compilation to fail.

## System Symbols

System symbols are accessed with `$r('sys.symbol.<name>')`. Common groups include:

| Group | Examples |
|---|---|
| Navigation | `chevron_left`, `chevron_right`, `arrow_left`, `arrow_right`, `arrow_up`, `arrow_down`, `back`, `menu` |
| Actions | `plus`, `minus`, `xmark`, `checkmark`, `share`, `download`, `upload`, `trash`, `link`, `save`, `undo`, `redo`, `repeat`, `shuffle` |
| People and communication | `person`, `group`, `bell`, `envelope`, `message`, `phone`, `heart`, `hand`, `face`, `eye`, `ear` |
| Media | `play`, `pause`, `stop_circle`, `music`, `speaker`, `headphones`, `mic`, `camera`, `video`, `picture`, `film`, `movie`, `radio`, `tv_and_rectangle_portrait` |
| Documents | `doc`, `doc_text`, `folder`, `archivebox`, `clipboard_sharing`, `tray` |
| Commerce | `cart`, `bag`, `creditcard`, `coins`, `gift`, `ticket_fill`, `coupon`, `briefcase`, `tag`, `wallet` |
| Connectivity | `wifi`, `bluetooth`, `signal`, `battery`, `keyboard`, `mouse`, `display`, `printer`, `watch`, `desktop`, `laptop`, `airpods` |
| Weather and nature | `sun`, `moon`, `cloud`, `wind`, `snowflake`, `drop`, `thermometer`, `flame`, `umbrella`, `rainbow`, `leaf`, `flower`, `tree` |
| Places and travel | `house`, `building`, `store`, `hospital`, `school`, `factory`, `car`, `bus_fill`, `bicycle`, `airplane`, `train_ticket`, `road`, `rocket`, `boat` |
| Editing and formatting | `bold`, `italic`, `underline`, `strikethrough`, `text_alignleft`, `text_aligncenter`, `text_alignright`, `pencil_line`, `eraser_line`, `crop`, `code`, `list_bullet`, `list_number` |
| Status and security | `info_circle`, `exclamationmark`, `warning`, `questionmark_circle`, `shield_checkered`, `lock`, `key`, `bolt`, `medal`, `trophy` |
| Shapes and controls | `circle`, `square`, `diamond`, `triangle`, `hexagon`, `star`, `gearshape`, `magnifyingglass`, `qrcode`, `slider_horizontal_2`, `switch_square`, `power` |

Many symbols also have `_fill`, `_circle`, `_square`, or badge variants. Confirm the exact variant in the SDK resource table before using it.

## System Colors

System colors are accessed with `$r('sys.color.<name>')`. Common resource names include:

| Category | Resources |
|---|---|
| Brand colors | `ohos_id_color_primary`, `ohos_id_color_primary_contrary`, `ohos_id_color_secondary`, `ohos_id_color_tertiary`, `ohos_id_color_emphasize`, `ohos_id_color_warning`, `ohos_id_color_alert`, `ohos_id_color_connected` |
| Text colors | `ohos_id_color_text_primary`, `ohos_id_color_text_secondary`, `ohos_id_color_text_tertiary`, `ohos_id_color_text_hint`, `ohos_id_color_text_hyperlink`, `ohos_id_color_text_highlight_bg` |
| Surfaces | `ohos_id_color_background`, `ohos_id_color_sub_background`, `ohos_id_color_foreground`, `ohos_id_color_card_bg`, `ohos_id_color_list_card_bg` |
| Navigation and tabs | `ohos_id_color_navigationbar_bg`, `ohos_id_color_statusbar_bg`, `ohos_id_color_bottom_tab_bg`, `ohos_id_color_bottom_tab_icon`, `ohos_id_color_bottom_tab_text_on`, `ohos_id_color_subtab_bg` |
| Dialogs and controls | `ohos_id_color_dialog_bg`, `ohos_id_color_panel_bg`, `ohos_id_color_button_normal`, `ohos_id_color_switch_bg_off`, `ohos_id_color_floating_button_bg_normal` |
| Feedback | `ohos_id_color_progress`, `ohos_id_color_click_effect`, `ohos_id_color_hover`, `ohos_id_color_focused_bg`, `ohos_id_color_badge`, `ohos_id_color_badge_red`, `ohos_id_color_emergency`, `ohos_id_color_success`, `ohos_id_color_error`, `ohos_id_color_info` |

Color resources may have `_dark` and `_transparent` variants when provided by the SDK.

## Examples

```typescript
SymbolGlyph($r('sys.symbol.house'))
  .fontSize(24)
  .fontColor([Color.Blue])

Text('Settings')
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
```
