#!/usr/bin/env bash
set -euo pipefail

# Ensure required dirs exist
mkdir -p /var/lib/op-reth/ee-secret
mkdir -p /var/lib/op-reth/snapshot

# Generate JWT secret (must match op-node volume)
if [[ ! -f /var/lib/op-reth/ee-secret/jwtsecret ]]; then
  echo "Generating JWT secret for op-reth"
  __secret1=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  __secret2=$(head -c 8 /dev/urandom | od -A n -t u8 | tr -d '[:space:]' | sha256sum | head -c 32)
  echo -n "${__secret1}${__secret2}" > /var/lib/op-reth/ee-secret/jwtsecret
fi

# Make readable (mirrors geth behavior)
if [[ -O "/var/lib/op-reth/ee-secret/jwtsecret" ]]; then
  chmod 666 /var/lib/op-reth/ee-secret/jwtsecret
fi

__get_snapshot() {
  __dont_rm=0
  cd /var/lib/op-reth/snapshot
#  eval "__url=$1"

# assign argument to local var (avoid eval & SC2154)
  local __url="$1"

  if [[ "${__url}" == "https://storage.cloud.google.com/"* ]]; then
    echo "Google Cloud URL detected, using gsutil"
    __path="gs://${__url#https://storage.cloud.google.com/}"
    gsutil -m cp "${__path}" .
  else
    aria2c -c -x6 -s6 --auto-file-renaming=false --conditional-get=true --allow-overwrite=true "${__url}"
  fi

  echo "Copy completed, extracting"

  if ! __final_url=$(curl -s -I -L -o /dev/null -w '%{url_effective}' "$__url"); then
    printf "Error: Failed to retrieve final URL for %s\n" "$__url" >&2
    return 1
  fi

  __filename=$(basename "$__final_url")
  __filename="${__filename%%\?*}"

  # Extract supported formats into /var/lib/op-reth
  if [[ "${__filename}" =~ \.tar\.zst$ ]]; then
    pzstd -c -d "${__filename}" | tar xvf - -C /var/lib/op-reth
  elif [[ "${__filename}" =~ \.tar\.gz$ || "${__filename}" =~ \.tgz$ ]]; then
    tar xzvf "${__filename}" -C /var/lib/op-reth
  elif [[ "${__filename}" =~ \.tar$ ]]; then
    tar xvf "${__filename}" -C /var/lib/op-reth
  elif [[ "${__filename}" =~ \.lz4$ ]]; then
    lz4 -c -d "${__filename}" | tar xvf - -C /var/lib/op-reth
  else
    __dont_rm=1
    echo "The snapshot file has a format that Optimism Docker can't handle."
    echo "Please come to CryptoManufaktur Discord to work through this."
  fi

  if [ "${__dont_rm}" -eq 0 ]; then
    rm -f "${__filename}"
  fi

  # -----------------------------
  # Normalize snapshot layout for reth
  # -----------------------------
  # Reth typically stores data under a "db" directory in the datadir, e.g.:
  #   /var/lib/op-reth/db
  #
  # Snapshots may contain:
  #   - db/ at root
  #   - a nested op-reth/ directory with db/
  #   - other layouts (we try to locate and move)
  __search_dir="db"
  __base_dir="/var/lib/op-reth/"
  __found_path=$(find "$__base_dir" -type d -name "$__search_dir" -print -quit)

  if [ -z "${__found_path}" ]; then
    echo "Could not find a 'db' directory after extracting snapshot."
    echo "This snapshot likely isn't for reth/op-reth, or the layout is unexpected."
    exit 1
  fi

  # If db is already at /var/lib/op-reth/db, good.
  if [ "${__found_path}" = "${__base_dir}db" ]; then
    echo "Found db in expected location: ${__found_path}"
    return 0
  fi

  # Otherwise, move the directory that contains db/ into the base dir
  __parent_dir=$(dirname "${__found_path}")

  echo "Found db at ${__found_path}, normalizing into ${__base_dir}db"

  # If the found db is nested (e.g. /var/lib/op-reth/op-reth/db), move it up
  if [ -d "${__base_dir}db" ]; then
    echo "WARNING: ${__base_dir}db already exists, not overwriting."
    echo "Please clear the datadir and try again."
    exit 1
  fi

  mv "${__found_path}" "${__base_dir}db"

  # Try to cleanup empty parent dirs but don’t be destructive
  rmdir "${__parent_dir}" 2>/dev/null || true
}

# Prep datadir:
# Only fetch snapshot if SNAPSHOT is set and db doesn't already exist.
if [ -n "${SNAPSHOT:-}" ] && [ ! -d "/var/lib/op-reth/db" ]; then
  __get_snapshot "${SNAPSHOT}"
  if [ -n "${SNAPSHOT_PART:-}" ]; then
    __get_snapshot "${SNAPSHOT_PART}"
  fi
else
  echo "No snapshot fetch necessary"
fi