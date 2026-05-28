"""Supabase Storage bucket backup.

Downloads every file from the configured Supabase Storage bucket and packages
them into a timestamped zip — workaround for Supabase free-tier giving DB
backups only (not Storage).

Usage:
    python scripts/backup_storage.py
    python scripts/backup_storage.py --bucket alsaeb-docs --out ./backups
    python scripts/backup_storage.py --keep 30   # rotate: delete zips older than 30 days

Env:
    SUPABASE_URL              required
    SUPABASE_SERVICE_KEY      required
    BACKUP_OUTPUT_DIR         optional (default ./backups)
    BACKUP_BUCKET             optional (default alsaeb-docs)

Cron example (Linux):
    0 3 * * * cd /opt/alsaeb && /opt/alsaeb/.venv/bin/python scripts/backup_storage.py --keep 14 >> /var/log/alsaeb-backup.log 2>&1
"""

from __future__ import annotations

import argparse
import datetime as dt
import logging
import os
import pathlib
import sys
import zipfile

from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger('backup_storage')


def _walk_bucket(client, bucket: str) -> list[str]:
    """Recursively list every file path in `bucket`. Directories are objects
    without an `id` in the Supabase Storage list response."""
    found: list[str] = []

    def _walk(prefix: str = '') -> None:
        try:
            items = client.storage.from_(bucket).list(path=prefix or None) or []
        except Exception as e:
            log.warning('list %r failed: %s', prefix, e)
            return
        for it in items:
            name = it.get('name')
            if not name:
                continue
            full = f'{prefix}/{name}' if prefix else name
            # A storage "file" has an id; a "folder" does not.
            if it.get('id'):
                found.append(full)
            else:
                _walk(full)

    _walk()
    return found


def _rotate(out_dir: str, bucket: str, keep_days: int) -> int:
    """Delete backup zips for `bucket` older than `keep_days`. Returns count deleted."""
    if keep_days <= 0:
        return 0
    cutoff = dt.datetime.utcnow() - dt.timedelta(days=keep_days)
    deleted = 0
    prefix = f'{bucket}_backup_'
    p = pathlib.Path(out_dir)
    if not p.exists():
        return 0
    for f in p.iterdir():
        if not (f.is_file() and f.name.startswith(prefix) and f.suffix == '.zip'):
            continue
        try:
            mtime = dt.datetime.utcfromtimestamp(f.stat().st_mtime)
            if mtime < cutoff:
                f.unlink()
                deleted += 1
                log.info('rotated out old backup: %s', f.name)
        except Exception as e:
            log.warning('rotate failed for %s: %s', f.name, e)
    return deleted


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--bucket', default=os.getenv('BACKUP_BUCKET', 'alsaeb-docs'))
    parser.add_argument('--out', default=os.getenv('BACKUP_OUTPUT_DIR', './backups'))
    parser.add_argument('--keep', type=int, default=int(os.getenv('BACKUP_KEEP_DAYS', '0')),
                        help='Delete zips older than this many days (0 = no rotation)')
    args = parser.parse_args(argv)

    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_KEY')
    if not url or not key:
        log.error('SUPABASE_URL and SUPABASE_SERVICE_KEY env vars are required')
        return 2

    try:
        from supabase import create_client
    except ImportError:
        log.error('supabase-py not installed — run: pip install -r requirements.txt')
        return 2

    client = create_client(url, key)

    log.info('Listing files in bucket %r ...', args.bucket)
    files = _walk_bucket(client, args.bucket)
    log.info('Found %d files', len(files))
    if not files:
        log.warning('Nothing to back up — exiting cleanly')
        return 0

    pathlib.Path(args.out).mkdir(parents=True, exist_ok=True)
    stamp = dt.datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    zippath = os.path.join(args.out, f'{args.bucket}_backup_{stamp}.zip')

    ok = fail = 0
    with zipfile.ZipFile(zippath, 'w', zipfile.ZIP_DEFLATED) as zf:
        for i, fp in enumerate(files, 1):
            try:
                data = client.storage.from_(args.bucket).download(fp)
                zf.writestr(fp, data)
                ok += 1
            except Exception as e:
                log.warning('download failed: %s (%s)', fp, e)
                fail += 1
            if i % 25 == 0:
                log.info('  progress: %d/%d', i, len(files))

    size = os.path.getsize(zippath)
    log.info('Backup written: %s (%s bytes, %d ok / %d failed)', zippath, f'{size:,}', ok, fail)

    if args.keep > 0:
        rotated = _rotate(args.out, args.bucket, args.keep)
        log.info('Rotation: removed %d old backup(s)', rotated)

    return 0 if fail == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
