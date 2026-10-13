"""Validate outputs made by um sprite; requires project-tool Pillow only."""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageOps


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--source-sha256', required=True)
    args = parser.parse_args()
    folder = args.output
    assert digest(folder / 'source.png') == args.source_sha256.lower(), 'Source backup mismatch'
    names = ['robot-64.png', 'robot-mirror-64.png', 'robot-pixel-64.png', 'robot-pixel-mirror-64.png']
    frames = [Image.open(folder / name).convert('RGBA') for name in names]
    for frame in frames:
        assert frame.size == (64, 64)
        assert frame.getchannel('A').getextrema() == (0, 255), 'Alpha is not transparent/opaque'
        assert set(frame.getchannel('A').tobytes()) == {0, 255}, 'Unexpected partial alpha'
        assert frame.getbbox(), 'Empty sprite'
        assert frame.getpixel((0, 0))[3] == 0, 'Frame corner is not transparent'
    cutout = Image.open(folder / 'robot-cutout.png').convert('RGBA')
    assert cutout.getchannel('A').getextrema() == (0, 255), 'Background not removed'
    pixel = Image.open(folder / 'robot-pixel-32.png').convert('RGBA')
    assert pixel.size == (32, 32)
    visible_colors = {rgb[:3] for _, rgb in pixel.getcolors(1024) if rgb[3]}
    assert len(visible_colors) <= 17, 'Quantized palette exceeds 16 colors plus outline'
    for original, mirror in [(frames[0], frames[1]), (frames[2], frames[3])]:
        assert ImageOps.mirror(original).tobytes() == mirror.tobytes(), 'Mirror differs'
    sheet = Image.open(folder / 'robot-sheet.png').convert('RGBA')
    assert sheet.size == (128, 128)
    for index, frame in enumerate(frames):
        x, y = index % 2 * 64, index // 2 * 64
        assert sheet.crop((x, y, x + 64, y + 64)).tobytes() == frame.tobytes(), 'Sheet cell differs'
        sliced = Image.open(folder / 'sliced' / f'frame_{index:03d}.png').convert('RGBA')
        assert sliced.tobytes() == frame.tobytes(), 'Slice roundtrip differs'
    files = {p.relative_to(folder).as_posix(): {'sha256': digest(p), 'size_bytes': p.stat().st_size}
             for p in folder.rglob('*.png')}
    result = {'source_sha256': args.source_sha256.lower(), 'status': 'PASS',
              'frame_size': [64, 64], 'sheet_size': [128, 128], 'frame_count': 4,
              'visible_pixel_colors': len(visible_colors), 'slice_roundtrip': 'exact RGBA bytes',
              'files': files, 'browser_scene': 'NOT_RUN', 'visual_review': 'NOT_RUN'}
    (folder / 'validation.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k != 'files'}, indent=2))


if __name__ == '__main__':
    main()
