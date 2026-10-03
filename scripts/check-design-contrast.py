#!/usr/bin/env python3
"""Check semantic text/control color pairs using the WCAG sRGB formula."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def luminance(color: str) -> float:
    channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in channels]
    return sum(v * weight for v, weight in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(foreground: str, background: str) -> float:
    lighter, darker = sorted((luminance(foreground), luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


failures = []
for mode in ('base', 'dark'):
    path = ROOT / 'entry/src/main/resources' / mode / 'element/color.json'
    tokens = {item['name']: item['value'] for item in json.loads(path.read_text())['color']}
    pairs = []
    for surface in ('page_background', 'surface', 'senior_tint', 'guardian_tint',
                    'success_tint', 'warning_tint', 'sos_tint'):
        pairs.extend((text, surface, 4.5) for text in ('text_primary', 'text_secondary'))
    for accent, tint in (('senior_accent', 'senior_tint'), ('guardian_accent', 'guardian_tint'),
                         ('success', 'success_tint'), ('warning', 'warning_tint'), ('sos', 'sos_tint')):
        pairs.extend((accent, surface, 4.5) for surface in ('surface', 'page_background', tint))
    pairs.extend((('#FFFFFF', 'action_primary', 4.5), ('#FFFFFF', 'action_danger', 4.5),
                  ('control_border', 'surface', 3.0), ('focus_ring', 'surface', 3.0),
                  ('watch_text', 'watch_background', 4.5), ('watch_secondary', 'watch_background', 4.5)))
    for foreground, background, minimum in pairs:
        ratio = contrast(tokens.get(foreground, foreground), tokens[background])
        print(f'{mode:4} {foreground:20} / {background:18} {ratio:.2f}:1 (minimum {minimum}:1)')
        if ratio < minimum:
            failures.append(f'{mode}: {foreground}/{background} = {ratio:.2f}:1')

watch_path = ROOT / 'watch/src/main/resources/base/element/color.json'
watch_tokens = {item['name']: item['value'] for item in json.loads(watch_path.read_text())['color']}
watch_pairs = (
    ('watch_text', 'watch_background', 4.5),
    ('watch_text_secondary', 'watch_background', 4.5),
    ('watch_accent', 'watch_background', 4.5),
    ('watch_sos', 'watch_background', 3.0),
    ('watch_warning', 'watch_background', 4.5),
    ('#000000', 'watch_accent', 4.5),
    ('#FFFFFF', 'watch_sos', 4.5),
    ('#000000', 'watch_warning', 4.5),
)
for foreground, background, minimum in watch_pairs:
    ratio = contrast(watch_tokens.get(foreground, foreground), watch_tokens[background])
    print(f'watch {foreground:20} / {background:18} {ratio:.2f}:1 (minimum {minimum}:1)')
    if ratio < minimum:
        failures.append(f'watch: {foreground}/{background} = {ratio:.2f}:1')

if failures:
    raise SystemExit('Contrast check failed:\n' + '\n'.join(failures))
print('All configured semantic text and control pairs pass. Runtime composition still needs target review.')
