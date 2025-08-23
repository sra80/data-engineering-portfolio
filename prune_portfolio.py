#!/usr/bin/env python3
"""
Delete all files NOT on a keep-list.

Modes:
  A) Keep by current paths/patterns:
     python3 prune_portfolio.py --keep keep_list.txt --apply

  B) Keep by original repo (handles renames via content hash):
     python3 prune_portfolio.py --original-repo /path/to/original/repo \
                                --original-list original_keep.txt --apply

Defaults to dry-run (no deletions) unless --apply is provided.
"""

import argparse, os, sys, subprocess, hashlib, fnmatch, shlex
from pathlib import Path

# ---------- helpers ----------

def is_git_repo(path: Path) -> bool:
    return (path / ".git").is_dir()

def git_ls_files(repo: Path):
    try:
        out = subprocess.check_output(["git", "ls-files", "-z"], cwd=repo, text=False)
        files = [Path(p.decode("utf-8", "replace")) for p in out.split(b"\x00") if p]
        return [repo / f for f in files]
    except Exception:
        return None  # fall back to filesystem walk

def all_files_in_tree(root: Path):
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # skip .git folder
        if ".git" in dirnames:
            dirnames.remove(".git")
        for n in filenames:
            files.append(Path(dirpath) / n)
    return files

def load_lines(path: Path):
    lines = []
    with open(path, encoding="utf-8") as f:
        for raw in f:
            s = raw.strip()
            if not s or s.startswith("#"):
                continue
            lines.append(s)
    return lines

def sha1_file(p: Path, chunk=1024*1024):
    h = hashlib.sha1()
    with open(p, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b: break
            h.update(b)
    return h.hexdigest()

def get_repo_files(repo_root: Path):
    tracked = git_ls_files(repo_root)
    if tracked is not None:
        return tracked
    # fallback to full tree
    return all_files_in_tree(repo_root)

def stage_or_delete(paths, repo_root: Path, apply: bool):
    deleted = []
    if not apply:
        return deleted
    if is_git_repo(repo_root):
        # try git rm in batches to handle spaces
        for p in paths:
            rel = p.relative_to(repo_root).as_posix()
            try:
                subprocess.check_call(["git", "rm", "-f", "--", rel], cwd=repo_root)
                deleted.append(p)
            except subprocess.CalledProcessError:
                # if git rm fails (e.g., untracked), fall back to os.remove
                if p.exists():
                    p.unlink()
                    deleted.append(p)
    else:
        for p in paths:
            if p.exists():
                p.unlink()
                deleted.append(p)
    return deleted

# ---------- core logic ----------

def build_keep_set_by_patterns(repo_root: Path, patterns):
    """
    patterns can be exact paths (relative to repo) or globs.
    """
    repo_files = get_repo_files(repo_root)
    keep = set()

    # Normalize patterns to POSIX-style for consistent matching
    norm_patterns = []
    for pat in patterns:
        # make relative posix path for comparison
        norm_patterns.append(pat.replace("\\", "/"))
    for f in repo_files:
        rel = f.relative_to(repo_root).as_posix()
        for pat in norm_patterns:
            if rel == pat or fnmatch.fnmatch(rel, pat):
                keep.add(f)
                break
    return keep

def build_keep_set_by_content_hash(repo_root: Path, original_repo: Path, original_list_file: Path):
    """
    Match files by content hash between original repo (list of original paths)
    and current repo. Any current file whose content hash matches any original
    keep-file hash will be KEPT (so renames/moves don't matter).
    """
    orig_paths = load_lines(original_list_file)
    # compute hashes of originals
    keep_hashes = set()
    for rel in orig_paths:
        p = (original_repo / rel).resolve()
        if not p.exists():
            # Allow patterns in original list as well
            # Expand glob relative to original repo
            matches = list(original_repo.glob(rel))
            if not matches:
                print(f"⚠️  Original not found: {rel}", file=sys.stderr)
                continue
            for m in matches:
                if m.is_file():
                    keep_hashes.add(sha1_file(m))
        else:
            if p.is_file():
                keep_hashes.add(sha1_file(p))

    if not keep_hashes:
        print("No hashes derived from original list; nothing to keep.", file=sys.stderr)

    # compute current repo file hashes and keep those that match
    keep = set()
    for f in get_repo_files(repo_root):
        try:
            if f.is_file():
                h = sha1_file(f)
                if h in keep_hashes:
                    keep.add(f)
        except Exception:
            pass
    return keep

def main():
    ap = argparse.ArgumentParser(description="Prune files not on keep list.")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--keep", help="Text file with current repo paths/globs to KEEP (one per line).")
    g.add_argument("--original-repo", help="Path to ORIGINAL repo (for hash-based keep).")

    ap.add_argument("--original-list", help="When using --original-repo, a text file with original paths/globs to keep.")
    ap.add_argument("--apply", action="store_true", help="Actually delete files (default is dry-run).")
    ap.add_argument("--include-untracked", action="store_true", help="Consider untracked files (filesystem walk) as well.")
    ap.add_argument("--keep-always", nargs="*", default=["README.md", "README", ".gitignore"],
                    help="Extra files to always keep by name (relative at repo root).")
    args = ap.parse_args()

    repo_root = Path.cwd()

    # source of truth list of current files
    if args.include_untracked:
        repo_files = all_files_in_tree(repo_root)
    else:
        repo_files = get_repo_files(repo_root)

    # build keep set
    keep_set = set()
    if args.keep:
        keep_patterns = load_lines(Path(args.keep))
        # always keep safety files
        keep_patterns += args.keep_always
        keep_set = build_keep_set_by_patterns(repo_root, keep_patterns)
    else:
        if not args.original_list:
            print("Error: --original-list is required when using --original-repo", file=sys.stderr)
            sys.exit(2)
        keep_set = build_keep_set_by_content_hash(repo_root, Path(args.original_repo), Path(args.original_list))
        # also always keep safety files (by simple name match at root)
        for name in args.keep_always:
            p = repo_root / name
            if p.exists():
                keep_set.add(p)

    # compute delete set
    repo_files = [f for f in repo_files if f.is_file()]
    to_delete = [f for f in repo_files if f not in keep_set]

    # never touch .git dir (already excluded), and never touch this script itself
    me = Path(__file__).resolve()
    to_delete = [f for f in to_delete if f.resolve() != me]

    # summary
    print(f"Found {len(repo_files)} files in repo.")
    print(f"Will KEEP {len(keep_set)} files.")
    print(f"Will DELETE {len(to_delete)} files. (dry-run={not args.apply})")
    for f in sorted(to_delete):
        print(f"DELETE: {f.relative_to(repo_root)}")

    # apply
    deleted = stage_or_delete(to_delete, repo_root, args.apply)
    if args.apply:
        print(f"✅ Deleted {len(deleted)} files.")
        if is_git_repo(repo_root):
            print("Tip: review with `git status` and then commit the removals.")

if __name__ == "__main__":
    main()