#!/usr/bin/env bash
# build.sh — narration.md -> Piper WAVs -> timing map -> Playwright frames -> ffmpeg MP4.
# POC scope: scenes 1-2. Usage: video/build.sh [workdir]   (VOICE=<piper voice> to override)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="${1:-$HERE/build}"
ENGINE="${ENGINE:-elevenlabs}"                       # elevenlabs | piper
VOICE="${VOICE:-en_US-hfc_male-medium}"             # piper voice (ENGINE=piper)
VOICE_ID="${VOICE_ID:-1SM7GgM6IMuvQlz2BwM3}"        # ElevenLabs voice (Mark - Casual, Relaxed and Light)
TTS_SPEED="${TTS_SPEED:-0.92}"                      # ElevenLabs speed (0.7-1.2)
LEAD="${LEAD:-1.0}"                                 # silence before the first sentence, seconds
PIPER="$HOME/.local/share/piper/piper/piper"
ESPEAK="$HOME/.local/share/piper/piper/espeak-ng-data"
MODEL="$HOME/.local/share/piper/voices/$VOICE.onnx"
PAD=0.4   # inter-scene silence, seconds
FIXTURE="$ROOT/tasks/b-01-write-e2e/fixture"
CACHE="$HERE/tts-cache"                             # sentence-level TTS cache (gitignored)
if [ "$ENGINE" = "elevenlabs" ] && [ -z "${ELEVENLABS_API_KEY:-}" ]; then
  eval "$(grep '^export ELEVENLABS_API_KEY=' "$HOME/.bashrc" | tail -1)" || true
fi
export ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-}"

mkdir -p "$WORK/audio"

# 1-3) narration.md -> per-SENTENCE synthesis (cached) -> scene WAVs + exact cue map + SRT
python3 - "$HERE/narration.md" "$WORK" "$PAD" "$PIPER" "$MODEL" "$ESPEAK" "$ENGINE" "$VOICE_ID" "$TTS_SPEED" "$CACHE" "$LEAD" <<'EOF'
import re, sys, os, json, subprocess, hashlib, urllib.request
src, work, pad, piper, model, espeak = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4], sys.argv[5], sys.argv[6]
engine, voice_id, tts_speed, cache, lead = sys.argv[7], sys.argv[8], float(sys.argv[9]), sys.argv[10], float(sys.argv[11])
GAP = 0.18   # silence between sentences, seconds
adir = os.path.join(work, 'audio')
os.makedirs(adir, exist_ok=True)
os.makedirs(cache, exist_ok=True)

def dur(w):
    return float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','csv=p=0', w]).strip())

def synth(sent, w):
    # em-dashes make the v2 model emit breathy artifacts; commas read as the same pause
    tts_text = sent.replace(' \u2014 ', ', ').replace('\u2014', ',')
    if engine == 'elevenlabs':
        key = hashlib.sha256(f'11l|{voice_id}|eleven_multilingual_v2|{tts_speed}|{tts_text}'.encode()).hexdigest()[:24]
        cached = os.path.join(cache, key + '.wav')
        if not os.path.exists(cached):
            req = urllib.request.Request(
                f'https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128',
                data=json.dumps({'text': tts_text, 'model_id': 'eleven_multilingual_v2',
                                 'voice_settings': {'speed': tts_speed}}).encode(),
                headers={'xi-api-key': os.environ['ELEVENLABS_API_KEY'], 'Content-Type': 'application/json'})
            mp3 = cached + '.mp3'
            with urllib.request.urlopen(req, timeout=120) as r, open(mp3, 'wb') as f:
                f.write(r.read())
            subprocess.run(['ffmpeg','-y','-v','error','-i', mp3, '-ar','44100','-ac','1', cached], check=True)
            os.remove(mp3)
        subprocess.run(['cp', cached, w], check=True)
    else:
        subprocess.run([piper, '--model', model, '--quiet', '--espeak_data', espeak, '--output_file', w],
                       input=sent.encode(), check=True, stderr=subprocess.DEVNULL)

body = open(src).read()
found = re.findall(r'^## Scene (\d+)[^\n]*\n\n(.+?)(?=\n## |\n---|\Z)', body, re.S | re.M)
scenes = []
for num, text in found:
    text = ' '.join(text.split())
    sents = re.split(r'(?<=[.!?])\s+', text)
    cues, sdurs, wavs, t = [], [], [], 0.0
    for i, sent in enumerate(sents):
        w = os.path.join(adir, f'sent-{num}-{i}.wav')
        synth(sent, w)
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
    is_first = len(scenes) == 0
    head = f'adelay={int(lead*1000)}:all=1,' if is_first and lead > 0 else ''
    if is_first and lead > 0:
        cues = [round(c + lead, 3) for c in cues]
        audio_s += lead
    fc = ';'.join(filters) + f';{chain}concat=n={len(wavs)}:v=0:a=1,{head}atrim=0:{audio_s}[out]'
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

# 4) frames via Playwright — one chromium PER SCENE, in parallel
NSCENES=$(python3 -c "import json;print(len(json.load(open('$WORK/timing.json'))['scenes']))")
pids=()
for i in $(seq 0 $((NSCENES-1))); do
  NODE_PATH="$FIXTURE/node_modules" node "$HERE/render_frames.js" "$WORK" "$i" &
  pids+=($!)
done
for p in "${pids[@]}"; do wait "$p"; done

# 4b) per-scene clips (parallel), then lossless concat into one stream
clip_pids=()
for i in $(seq 0 $((NSCENES-1))); do
  ffmpeg -y -v error -framerate 30 -i "$WORK/frames-$i/f%06d.png" \
    -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$WORK/clip-$i.mp4" &
  clip_pids+=($!)
done
for p in "${clip_pids[@]}"; do wait "$p"; done
: > "$WORK/concat.txt"
for i in $(seq 0 $((NSCENES-1))); do echo "file 'clip-$i.mp4'" >> "$WORK/concat.txt"; done
ffmpeg -y -v error -f concat -safe 0 -i "$WORK/concat.txt" -c copy "$WORK/video-nocap.mp4"

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

# 6) final assembly: concat video + narration + burned captions
ffmpeg -y -v error -i "$WORK/video-nocap.mp4" -i "$WORK/narration.wav" \
  -vf "subtitles=$WORK/captions.srt:force_style='FontSize=11,PrimaryColour=&H30241F&,OutlineColour=&HFFFFFF&,BorderStyle=1,Outline=2,Shadow=0,MarginV=20'" \
  -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -c:a aac -b:a 128k -shortest \
  "$WORK/poc.mp4"
ffprobe -v error -show_entries format=duration:stream=codec_type,width,height -of compact "$WORK/poc.mp4"
mkdir -p "$HOME/Videos" && cp "$WORK/poc.mp4" "$HOME/Videos/agentic-delivery-evals-draft.mp4"
echo "wrote $WORK/poc.mp4 (durable copy: ~/Videos/agentic-delivery-evals-draft.mp4)"
