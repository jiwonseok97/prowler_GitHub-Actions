import argparse
import glob
import os
import shutil

parser = argparse.ArgumentParser()
parser.add_argument("--input", required=True, help="Input OCSF glob, e.g. output/*.ocsf.json")
parser.add_argument("--output", required=True, help="Output path for latest OCSF JSON")
args = parser.parse_args()

files = glob.glob(args.input)
if not files:
    raise SystemExit(f"No OCSF files matched: {args.input}")

latest = max(files, key=os.path.getmtime)
os.makedirs(os.path.dirname(args.output), exist_ok=True)
shutil.copyfile(latest, args.output)
