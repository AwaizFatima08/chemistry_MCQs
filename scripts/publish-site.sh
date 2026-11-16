#!/usr/bin/env bash
# Uploads website/ to https://igcse-chemistry.homilabs.org (Hostinger subdomain, document root
# public_html/igcse-chemistry) over SSH. Flush the CDN cache in hPanel if pages look stale afterwards.
set -euo pipefail
cd "$(dirname "$0")/../website"
tar czf - . | ssh -p 65002 u809141334@145.79.26.208 'cd domains/homilabs.org/public_html/igcse-chemistry && tar xzf -'
echo "Published website/ to igcse-chemistry.homilabs.org"
