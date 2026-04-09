#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 --file <targets.csv> --template <alias> --from <address> [--function-name <name>]"
  echo ""
  echo "targets.csv format: name,email (one per line, no header)"
  exit 1
}

FUNCTION_NAME="RoySPFSender"
FILE=""
TEMPLATE=""
FROM=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --file) FILE="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --from) FROM="$2"; shift 2 ;;
    --function-name) FUNCTION_NAME="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$FILE" || -z "$TEMPLATE" || -z "$FROM" ]] && usage
[[ ! -f "$FILE" ]] && echo "Error: file $FILE not found" && exit 1

TARGETS="["
FIRST=true
while IFS=, read -r name email; do
  [[ -z "$email" ]] && continue
  $FIRST || TARGETS+=","
  FIRST=false
  TARGETS+="{\"address\":\"${name} <${email}>\",\"template_model\":{\"name\":\"${name}\"}}"
done < "$FILE"
TARGETS+="]"

PAYLOAD=$(cat <<EOF
{
  "targets": ${TARGETS},
  "postmark_template_alias": "${TEMPLATE}",
  "from": "${FROM}"
}
EOF
)

echo "Sending to $(grep -c ',' "$FILE") targets..."
aws lambda invoke \
  --function-name "$FUNCTION_NAME" \
  --cli-binary-format raw-in-base64-out \
  --payload "$PAYLOAD" \
  /dev/stdout
