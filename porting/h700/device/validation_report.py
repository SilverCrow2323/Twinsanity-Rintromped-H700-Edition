#!/usr/bin/env python3
"""Build a reproducible, hash-linked H700 device validation report from probe logs."""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, re, sys
from pathlib import Path
REQUIRED = {
    "system": ("muos-device-report.txt", "System inventory complete."),
    "egl": ("egl-gles-report.txt", "Twinsanity Rintromped - H700 EGL/GLES probe"),
    "sdl": ("sdl-window-report.txt", "Twinsanity Rintromped - H700 SDL/GLES window probe"),
}
class ReportError(ValueError): pass
def sha256(path: Path) -> str:
    digest=hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024*1024), b""): digest.update(chunk)
    return digest.hexdigest()
def inspect_evidence(folder: Path) -> dict:
    evidence={}; content={}
    for key,(filename,marker) in REQUIRED.items():
        path=folder/filename
        if not path.is_file(): raise ReportError(f"Missing evidence file: {filename}")
        raw=path.read_bytes(); text=raw.decode("utf-8",errors="replace")
        if marker not in text: raise ReportError(f"{filename} does not contain its expected probe marker")
        evidence[key]={"file":filename,"bytes":len(raw),"sha256":sha256(path)}
        content[key]=text
    egl,sdl=content["egl"],content["sdl"]
    for marker in ("[EGL] version=","[GL] renderer=","[GL] version="):
        if marker not in egl: raise ReportError(f"EGL report is missing {marker}")
    for marker in ("[SDL] video_driver=","[GL] renderer=","[GL] version="):
        if marker not in sdl: raise ReportError(f"SDL report is missing {marker}")
    if "[RESULT] PASS:" not in sdl: raise ReportError("SDL probe did not record a PASS result")
    def capture(pattern,text):
        match=re.search(pattern,text,re.MULTILINE)
        return match.group(1).strip() if match else None
    return {"files":evidence,"observed":{
        "egl_version":capture(r"^\[EGL\] version=(.+)$",egl),
        "gpu_vendor":capture(r"^\[GL\] vendor=(.+)$",egl),
        "gpu_renderer":capture(r"^\[GL\] renderer=(.+)$",egl),
        "gles_version":capture(r"^\[GL\] version=(.+)$",egl),
        "sdl_video_driver":capture(r"^\[SDL\] video_driver=(.+)$",sdl),
        "sdl_renderer":capture(r"^\[GL\] renderer=(.+)$",sdl),
        "sdl_gles_version":capture(r"^\[GL\] version=(.+)$",sdl),
        "sdl_result":"PASS"}}
def build_report(evidence_dir:Path,device:str,firmware:str,build_commit:str,package:Path|None=None)->dict:
    if not device.strip() or not firmware.strip() or not re.fullmatch(r"[0-9a-fA-F]{7,40}",build_commit):
        raise ReportError("Device, firmware and a 7-40 character Git commit are required")
    report={"schema_version":1,"collected_at_utc":dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
      "device":{"model":device.strip(),"firmware":firmware.strip()},"build":{"commit":build_commit.lower()},
      "evidence":inspect_evidence(evidence_dir)}
    if package is not None:
        if not package.is_file(): raise ReportError(f"Package does not exist: {package}")
        report["package"]={"file":package.name,"bytes":package.stat().st_size,"sha256":sha256(package)}
    return report
def markdown(report:dict)->str:
    observed=report["evidence"]["observed"]
    lines=["# H700 device validation report","",f"- **Device:** {report['device']['model']}",
      f"- **Firmware:** {report['device']['firmware']}",f"- **Build commit:** `{report['build']['commit']}`",
      f"- **Collected:** {report['collected_at_utc']}",f"- **SDL/GLES probe:** {observed['sdl_result']}","",
      "## Observed graphics stack","","| Field | Result |","|---|---|"]
    for key in ("egl_version","gpu_vendor","gpu_renderer","gles_version","sdl_video_driver","sdl_renderer","sdl_gles_version"):
        lines.append(f"| {key} | {observed.get(key) or 'Not reported'} |")
    if "package" in report:
        lines += ["","## Diagnostic package","",f"- **File:** {report['package']['file']}",f"- **SHA-256:** `{report['package']['sha256']}`"]
    lines += ["","## Evidence hashes","","| File | Bytes | SHA-256 |","|---|---:|---|"]
    for item in report["evidence"]["files"].values():
        lines.append(f"| {item['file']} | {item['bytes']} | `{item['sha256']}` |")
    lines += ["","> This report validates collected diagnostics only. It does not certify game rendering, gameplay, performance or release readiness.",""]
    return "\n".join(lines)
def main()->int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence-dir",type=Path,required=True)
    parser.add_argument("--device",required=True); parser.add_argument("--firmware",required=True)
    parser.add_argument("--build-commit",required=True); parser.add_argument("--package",type=Path)
    parser.add_argument("--output",type=Path,default=Path("h700-validation-report.json"))
    args=parser.parse_args()
    try:
        report=build_report(args.evidence_dir,args.device,args.firmware,args.build_commit,args.package)
        args.output.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
        args.output.with_suffix(".md").write_text(markdown(report),encoding="utf-8")
    except (OSError,ReportError) as exc:
        print(f"ERROR: {exc}",file=sys.stderr); return 1
    print(f"Validation report written: {args.output} and {args.output.with_suffix('.md')}")
    return 0
if __name__=="__main__": raise SystemExit(main())
