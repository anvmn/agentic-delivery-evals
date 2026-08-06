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

# 1-3) narration.md -> per-SENTENCE Piper synthesis -> scene WAVs + exact cue map + SRT
python3 - "$HERE/narration.md" "$WORK" "$PAD" "$PIPER" "$MODEL" "$ESPEAK" <<'EOF'
import re, sys, os, json, subprocess
src, work, pad, piper, model, espeak = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4], sys.argv[5], sys.argv[6]
GAP = 0.18   # silence between sentences, seconds
adir = os.path.join(work, 'audio')
os.makedirs(adir, exist_ok=True)

def dur(w):
    return float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0', w]).strip())

body = open(src).read()
found = re.findall(r'^## Scene (\d+)[^\n]*\n\n(.+?)(?=\n## |\n---|\Z)', body, re.S | re.M)
scenes = []
for num, text in found:
    text = ' '.join(text.split())
    sents = re.split(r'(?<=[.!?])\s+', text)
    cues, sdurs, wavs, t = [], [], [], 0.0
    for i, sent in enumerate(sents):
        w = os.path.join(adir, f'sent-{num}-{i}.wav')
        subprocess.run([piper, '--model', model, '--quiet', '--espeak_data', espeak, '--output_file', w],
                       input=sent.encode(), check=True, stderr=subprocess.DEVNULL)
        d = dur(w)
        cues.append(round(t, 3)); sdurs.append(round(d, 3)); wavs.append(w)
        t += d + GAP
    audio_s = t - GAP
    scene_wav = os.path.join(adir, f'scene-{num}.wav')
    inputs, filters = [], []
    for i, w in enumerate(wavs):
        inputs += ['-i', w]
        filters.append(f'[{i}:a]apad=pad_dur={GAP}[a{i}]')
    chain = ''.join(f'[a{i}]' for i in range(len(wavs)))
    fc = ';'.join(filters) + f';{chain}concat=n={len(wavs)}:v=0:a=1,atrim=0:{audio_s}[out]'
    subprocess.run(['ffmpeg','-y','-v','error'] + inputs + ['-filter_complex', fc, '-map','[out]', scene_wav], check=True)
    scenes.append({'wav': scene_wav, 'audio_s': round(audio_s,3), 'video_s': round(audio_s + pad,3),
                   'cues': cues, 'sent_durs': sdurs, 'sentences': sents})
    print(f'scene {num}: {len(sents)} sentences, {audio_s:.1f}s')
json.dump({'scenes': scenes, 'pad': pad}, open(os.path.join(work, 'timing.json'), 'w'), indent=1)

def fmt(t):
    h, r = divmod(t, 3600); m, sec = divmod(r, 60)
    return f"{int(h):02d}:{int(m):02d}:{int(sec):02d},{int((sec%1)*1000):03d}"
idx, t0, out = 1, 0.0, []
for sc in scenes:
    for sent, c, d in zip(sc['sentences'], sc['cues'], sc['sent_durs']):
        out.append(f"{idx}\n{fmt(t0+c)} --> {fmt(t0+c+d)}\n{sent}\n")
        idx += 1
    t0 += sc['video_s']
open(os.path.join(work, 'captions.srt'), 'w').write('\n'.join(out))
print(f'captions.srt: {idx-1} cues (exact)')
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
  -vf "subtitles=$WORK/captions.srt:force_style='FontSize=11,PrimaryColour=&H30241F&,OutlineColour=&HFFFFFF&,BorderStyle=1,Outline=2,Shadow=0,MarginV=20'" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -b:a 128k -shortest \
  "$WORK/poc.mp4"
ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of compact "$WORK/poc.mp4"
echo "wrote $WORK/poc.mp4"
