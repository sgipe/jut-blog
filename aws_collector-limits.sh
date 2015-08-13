#!/bin/bash

## Samuel Gipe 20150812
## Query AWS EC2 for resource limits.  Only 5 are available via the cli, and we're mostly interest in max-instances.
## Use JQ to parse, then curl to Jut's http receiver.
## Designed for cron (or single one-offs). Assumes AWS keys are in the user's env. 

JQ='/Users/sam/local/bin/jq-osx-x86_64' 
## jq5 is at rc2 and has features required below.
## ./configure --prefix=/usr/local --disable-maintainer-mode
## requires oniguruma-dev (deb) or oniguruma-devel (rh) for regex matching. Install with apt/yum/brew

JUT_SERVER=<IP.IP.IP.IP>
HTTP_PORT=<http-recvr-portnum>

HTTP_RCVR_URL="http://${JUT_SERVER}:${HTTP_PORT}/?type=metric"

aws ec2 describe-account-attributes \
  | $JQ '[.[][] | select(.AttributeName | test(".*max.*")) | {AttributeName: .AttributeName , value: ( .AttributeValues[0].AttributeValue | tonumber ), time: now }]'\
  | curl -X POST -H 'Content-Type: application/json' -d @- $HTTP_RCVR_URL

