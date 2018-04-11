#!/usr/bin/env bash
temp_yaml=$(mktemp)

cleanup () {
  if [ -n "$temp_yaml" ] ; then rm -rf "$temp_yaml"; fi
  if [ -n "$1" ]; then kill -$1 $$; fi
}

trap 'cleanup' EXIT
trap 'cleanup HUP' HUP
trap 'cleanup TERM' TERM
trap 'cleanup INT' INT

# Check if there are any files in secrets
count=$(find secrets/ -type f ! -name "*.gpg" | wc -l)
if [ $count -eq 0 ]; then echo "Failed to find any decrypted secrets in the secrets folder."; exit 1; fi

# Required yaml header for salt
echo -e "#!yaml|gpg" > $temp_yaml

for file in secrets/*; do
    [[ $file == *.gpg ]] && continue
    # Re-encrypt files with Salt masters public key
    file_pgp_ascii=$(cat $file | gpg --encrypt --text --armor -r salt-example@redventures.com)
    indented_ascii=$( echo -e "$file_pgp_ascii" | awk '{printf "  %s\n", $0}')
    echo -e "\n${file##*/}: |\n$indented_ascii" >> $temp_yaml
done

cat $temp_yaml > salt.yaml
