#!/usr/bin/env bash
# build.sh — narration.md -> Piper WAVs -> timing map -> Playwright frames -> ffmpeg MP4.
# POC scope: scenes 1-2. Usage: video/build.sh [workdir]   (VOICE=<piper voice> to override)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="${1:-$HERE/build}"
VOICE="${VOICE:-en_US-hfc_male-medium}"
PIPER="$HOME/.local/share/piper/piper/piper"
ESPEAK="$HOME/.local/share/piper/piper/espeak-ng-data"
MODEL="$HOME/.local/share/piper/voices/$VOICE.onnx"
PAD=0.4   # inter-scene silence, seconds
FIXTURE="$ROOT/tasks/b-01-write-e2e/fixture"

mkdir -p "$WORK/audio"

# 1) narration.md -> one text file per scene (paragraphs under "## Scene N" headers)
python3 - "$HERE/narration.md" "$WORK" <<'EOF'
import re, sys, os, json
src, work = sys.argv[1], sys.argv[2]
body = open(src).read()
scenes = re.findall(r'^## Scene (\d+)[^\n]*\n\n(.+?)(?=\n## |\Z)', body, re.S | re.M)
for num, text in scenes:
    open(os.path.join(work, f'audio/scene-{num}.txt'), 'w').write(' '.join(text.split()))
print(f"{len(scenes)} scene paragraphs")
EOF

# 2) Piper TTS per scene
for txt in "$WORK"/audio/scene-*.txt; do
  wav="${txt%.txt}.wav"
  "$PIPER" --model "$MODEL" --quiet --espeak_data "$ESPEAK" --output_file "$wav" < "$txt"
  echo "tts: $(basename "$wav") $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$wav")s"
done

# 3) timing map + SRT captions (sentence-level, proportional to char length)
python3 - "$WORK" "$PAD" <<'EOF'
import json, re, subprocess, sys, os, glob
work, pad = sys.argv[1], float(sys.argv[2])
scenes = []
for txt in sorted(glob.glob(os.path.join(work, 'audio/scene-*.txt'))):
    wav = txt[:-4] + '.wav'
    dur = float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0', wav]).strip())
    scenes.append({'txt': txt, 'wav': wav, 'audio_s': dur, 'video_s': dur + pad,
                   'text': open(txt).read().strip()})
json.dump({'scenes': scenes, 'pad': pad}, open(os.path.join(work, 'timing.json'), 'w'), indent=1)

def fmt(t):
    h, r = divmod(t, 3600); m, s = divmod(r, 60)
    return f"{int(h):02d}:{int(m):02d}:{int(s):02d},{int((s%1)*1000):03d}"

idx, t0, out = 1, 0.0, []
for sc in scenes:
    sents = re.split(r'(?<=[.!?])\s+', sc['text'])
    total_chars = sum(len(s) for s in sents)
    t = t0
    for s in sents:
        d = sc['audio_s'] * len(s) / total_chars
        out.append(f"{idx}\n{fmt(t)} --> {fmt(min(t + d, t0 + sc['audio_s']))}\n{s}\n")
        t += d; idx += 1
    t0 += sc['video_s']
open(os.path.join(work, 'captions.srt'), 'w').write('\n'.join(out))
print(f"timing.json + captions.srt: {idx-1} captions, total {t0:.1f}s")
EOF

# 4) frames via Playwright (chromium from the b-01 fixture install)
NODE_PATH="$FIXTURE/node_modules" node "$HERE/render_frames.js" "$WORK"

# 5) narration track: scene WAVs with PAD silence after each
python3 - "$WORK" <<'EOF'
import json, subprocess, sys, os
work = sys.argv[1]
t = json.load(open(os.path.join(work, 'timing.json')))
inputs, filters = [], []
for i, sc in enumerate(t['scenes']):
    inputs += ['-i', sc['wav']]
    filters.append(f"[{i}:a]apad=pad_dur={t['pad']}[a{i}]")
chain = ''.join(f'[a{i}]' for i in range(len(t['scenes'])))
fc = ';'.join(filters) + f";{chain}concat=n={len(t['scenes'])}:v=0:a=1[out]"
subprocess.run(['ffmpeg','-y','-v','error'] + inputs +
               ['-filter_complex', fc, '-map', '[out]', os.path.join(work, 'narration.wav')], check=True)
print('narration.wav assembled')
EOF

# 6) final assembly: frames + narration + burned captions
ffmpeg -y -v error -framerate 30 -i "$WORK/frames/f%06d.png" -i "$WORK/narration.wav" \
  -vf "subtitles=$WORK/captions.srt:force_style='FontSize=11,PrimaryColour=&HE6E9ED&,OutlineColour=&H0E1116&,BorderStyle=1,Outline=1,Shadow=0,MarginV=20'" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -b:a 128k -shortest \
  "$WORK/poc.mp4"
ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of compact "$WORK/poc.mp4"
echo "wrote $WORK/poc.mp4"
