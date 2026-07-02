#!/usr/bin/env bash
# Uploads the two demo videos to S3 (public-read) so they don't need to live in the git repo.
# Usage: ./scripts/upload-videos-to-s3.sh
set -euo pipefail

PROFILE="target-317877151524"
REGION="us-east-1"
BUCKET="arignar-ita-deck-media"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export AWS_PROFILE="$PROFILE"
export AWS_REGION="$REGION"

echo "== Creating bucket (skips if it already exists) =="
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
fi

echo "== Allowing public objects on this bucket only =="
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

cat > /tmp/ita-deck-bucket-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadVideos",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET}/videos/*"
    }
  ]
}
POLICY
aws s3api put-bucket-policy --bucket "$BUCKET" --policy file:///tmp/ita-deck-bucket-policy.json

echo "== Uploading videos =="
aws s3 cp "$DIR/ITA Announcement.mp4" "s3://$BUCKET/videos/ita-announcement.mp4" \
  --content-type video/mp4
aws s3 cp "$DIR/wordBank walkthrough.mp4" "s3://$BUCKET/videos/wordbank-walkthrough.mp4" \
  --content-type video/mp4

echo "== Done. Public URLs: =="
echo "https://${BUCKET}.s3.${REGION}.amazonaws.com/videos/ita-announcement.mp4"
echo "https://${BUCKET}.s3.${REGION}.amazonaws.com/videos/wordbank-walkthrough.mp4"
