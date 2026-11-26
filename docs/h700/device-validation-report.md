# H700 validation evidence report

Collect the three device-side logs into one directory:

- `muos-device-report.txt` from `device/collect-system-info.sh`
- `egl-gles-report.txt` from the EGL/GLES probe
- `sdl-window-report.txt` from the SDL/GLES probe

On the host, generate a JSON report, a Markdown summary and SHA-256 fingerprints:

```sh
python3 device/validation_report.py \
  --evidence-dir ./device-logs \
  --device "RG35XX H" \
  --firmware "muOS 2606.0_ANDROMEDA" \
  --build-commit "$(git rev-parse HEAD)" \
  --package ./Twinsanity-Rintromped-H700-Preflight.muxapp \
  --output ./h700-validation-report.json
```

The device and firmware labels are supplied explicitly; the collector does not infer a model from the SoC. The report hashes every raw evidence file and the optional package. Keep the original logs beside the generated report. Do not publish raw system inventory without reviewing it for private paths or identifiers.

A passing diagnostic report proves only the checks represented by the probes. It is not proof of the NativeEE renderer, game boot, gameplay, frame pacing or release readiness.

## Verify an existing evidence bundle

After moving the report and its three raw logs to another machine, verify that none of the evidence files changed:

```sh
python3 porting/h700/device/verify_report.py ./h700-validation-report.json \
  --evidence-dir ./device-logs
```

If the report includes a diagnostic package fingerprint, also pass the same package with `--package ./Twinsanity-Rintromped-H700-Preflight.muxapp`. Verification rejects missing files, symlinks, size mismatches and SHA-256 mismatches. It confirms evidence integrity, not hardware performance or gameplay.
