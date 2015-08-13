#!/bin/bash 

## Samuel Gipe 20150812
## Query AWS EC2 for instances by type, regional, running state. Use JQ to count 'em, then curl to Jut's http receiver.
## Designed for cron (or single one-offs).  Assumes AWS keys are in the user's env

JQ='/Users/sam/local/bin/jq-osx-x86_64' 
## jq5 is at rc2 and has features required below.
## ./configure --prefix=/usr/local --disable-maintainer-mode
## requires oniguruma-dev (deb) or oniguruma-devel (rh) for regex matching. Install with apt/yum/brew

JUT_SERVER=<IP.IP.IP.IP>
HTTP_PORT=<http-recvr-portum>

HTTP_RCVR_URL="http://${JUT_SERVER}:${HTTP_PORT}/?type=metric"

## The jq command below: 
## select...test..."running" finds running instances only. 
## 'group_by' instance_type and region-az
## {} builds json with appropriate values for submission to Jut as a point
aws ec2 describe-instances  --query 'Reservations[].Instances[].[InstanceType,Placement.AvailabilityZone,State.Name]' \
  | $JQ '[.[] | select(.[2] | test("running")) ]| [ group_by(.[1])[] | group_by(.[0])[] | {instance_type: unique[0][0], "region_az": unique[0][1], value: length, time: now} ]'\
  | curl -X POST -H 'Content-Type: application/json' -d @- $HTTP_RCVR_URL

