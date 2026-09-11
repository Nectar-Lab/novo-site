#!/bin/sh
# Smoke test for Is-Agentic readiness fixes. Run against a live base URL:
#   ./verify_agentic.sh http://localhost:8099
set -e
BASE="${1:-http://localhost:8099}"
fail=0

check() { echo "-- $1"; }
assert_code() {
  code=$(curl -s -o /dev/null -w "%{http_code}" "$1")
  if [ "$code" != "$2" ]; then echo "FAIL: $1 expected $2 got $code"; fail=1; else echo "ok: $1 -> $code"; fi
}
assert_header() {
  val=$(curl -s -D- -o /dev/null "$1" -H "$3" 2>/dev/null | tr -d '\r' | grep -i "^$2:" || true)
  echo "$val" | grep -qi "$4" && echo "ok: $1 [$2: $4]" || { echo "FAIL: $1 missing $2: $4 (got: $val)"; fail=1; }
}

assert_code "$BASE/does-not-exist-xyz" 404
assert_header "$BASE/" "content-type" "Accept: text/markdown" "text/markdown"
assert_header "$BASE/" "vary" "Accept: text/markdown" "accept"
assert_header "$BASE/does-not-exist-xyz" "content-type" "Accept: text/markdown" "text/markdown"
assert_code "$BASE/does-not-exist-xyz" 404
curl -s "$BASE/does-not-exist-xyz" -H "Accept: text/markdown" | grep -q "^# 404" && echo "ok: 404 markdown body has heading" || { echo "FAIL: 404 markdown body missing heading"; fail=1; }
curl -s "$BASE/does-not-exist-xyz" -H "Accept: text/markdown" | grep -q "sitemap.xml" && echo "ok: 404 markdown body links sitemap" || { echo "FAIL: 404 markdown body missing sitemap link"; fail=1; }
assert_code "$BASE/sitemap.xml" 200
assert_code "$BASE/llms.txt" 200
assert_code "$BASE/robots.txt" 200
assert_code "$BASE/about/" 200
assert_code "$BASE/contact/" 200
assert_code "$BASE/privacy/" 200
curl -s "$BASE/" | grep -q "application/ld+json" && echo "ok: JSON-LD present" || { echo "FAIL: JSON-LD missing"; fail=1; }
curl -s "$BASE/" | grep -q 'rel="canonical"' && echo "ok: canonical present" || { echo "FAIL: canonical missing"; fail=1; }
curl -s "$BASE/" | grep -q 'og:image' && echo "ok: og:image present" || { echo "FAIL: og:image missing"; fail=1; }

# www -> apex canonicalization (only meaningful when hitting the real vhost, e.g. -H "Host: www.nectarlab.com.br")
if [ -n "$2" ]; then
  loc=$(curl -s -D- -o /dev/null -H "Host: $2" "$BASE/" | tr -d '\r' | grep -i '^location:')
  echo "$loc" | grep -qi "https://nectarlab.com.br/" && echo "ok: www host redirects to apex" || { echo "FAIL: www host does not redirect to apex (got: $loc)"; fail=1; }
fi

exit $fail
