#!/bin/sh
# Builds the eSign release-gate runner image (job-evg-esign-gate) in Azure; nothing heavy runs on the PC.
# Usage: release/gate-runner/build.sh [estate-guards-ref] [casales-runner-ref]
# The runner itself (Dockerfile, entry.py, the read-only `gh` shim) is the estate's shared gate runner, taken at an EXACT commit of
# evergentic/casales release/gate-runner; the gate (release.py, release_gate.py, pillars_gate.py, image_stamp.py, isolation_evidence.py)
# at an EXACT commit of evergentic/estate-guards. /work holds THIS repo's release/ from git HEAD (never a working tree).
# Tag: gate-esign-<this repo sha>-eg<estate-guards sha>-<UTC timestamp>, in acrevergenticcasales/gate-runner (deploy_allow esign.gate_runner).
set -eu
REF="${1:-86983a3}"; RUNNER="${2:-7867cce}"
HERE="$(cd "$(dirname "$0")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"
[ -z "$(git -C "$REPO" status --porcelain -- release)" ] || { echo "REFUSED: release/ has uncommitted changes" >&2; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CTX="$TMP/ctx"; EG="$TMP/eg"; CS="$TMP/cs"; mkdir -p "$CTX/gate" "$CTX/work"
git clone -q https://github.com/evergentic/estate-guards.git "$EG" && git -C "$EG" checkout -q "$REF"
cp "$EG/release-gate/"release*.py "$EG/release-gate/image_stamp.py" "$EG/release-gate/pillars_gate.py" "$EG/release-gate/isolation_evidence.py" "$CTX/gate/"
mkdir -p "$CTX/standards"; cp "$EG/standards/CLIENTS.json" "$CTX/standards/" 2>/dev/null || true
for f in Dockerfile entry.py overflow_diag.py gh; do
  gh api "repos/evergentic/casales/contents/release/gate-runner/$f?ref=$RUNNER" --jq .content | base64 -d > "$CTX/$f"
done
# the shared entry.py regenerates isolation evidence for client casales; for eSign it must name eSign's own client
sed -i 's/"--client", "casales"/"--client", os.environ.get("ISOLATION_CLIENT", "esign")/' "$CTX/entry.py"
grep -q 'ISOLATION_CLIENT' "$CTX/entry.py" || { echo "REFUSED: could not set the isolation client in entry.py" >&2; exit 2; }
git -C "$REPO" archive HEAD release | tar -x -C "$CTX/work"
rm -rf "$CTX/work/release/gate-runner"
SHA="$(git -C "$REPO" rev-parse --short=7 HEAD)"
TAG="gate-esign-$SHA-eg$(echo "$REF" | cut -c1-7)-$(date -u +%Y%m%d-%H%M%S)"
RUN_ID="$(cd "$CTX" && PYTHONUTF8=1 az acr build -r acrevergenticcasales --subscription ddb45ff8-ec76-401f-a909-2e2e0298c43c -t "gate-runner:$TAG" --no-logs . --query runId -o tsv | tr -d '\r')"
[ -n "$RUN_ID" ] || { echo "REFUSED: az acr build returned no run id" >&2; exit 1; }
echo "IMAGE acrevergenticcasales.azurecr.io/gate-runner:$TAG (run $RUN_ID)"
