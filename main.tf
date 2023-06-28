resource "aws_sqs_queue" "CSV_Queue" {
  name = "${var.common-name-value}s3-event-notification-queue"
  redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.dlq.arn}\",\"maxReceiveCount\":5}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "csv-queue-statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.account}:root"
      },
      "Action": "SQS:*",
      "Resource": "arn:aws:sqs:${var.region}:${var.account}:${var.common-name-value}s3-event-notification-queue"
    },
    {
      "Sid": "topic-subscription-arn:aws:sns:${var.region}:${var.account}:s3-sns-lab",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:${var.region}:${var.account}:${var.common-name-value}s3-event-notification-queue",
      "Condition": {
        "ArnLike": {
          "aws:SourceArn": "arn:aws:sns:${var.region}:${var.account}:s3-new-object"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sqs_queue" "dlq" {
    name = "${var.common-name-value}dlq-sqs"
    policy = jsonencode(
      {
        "Version": "2008-10-17",
        "Id": "dlq_policy_ID",
        "Statement": [
        {
          "Sid": "__owner_statement",
          "Effect": "Allow",
          "Principal": {
            "AWS": "${var.account}"
          },
          "Action": [
            "SQS:*"
          ],
        "Resource": "arn:aws:sqs:${var.region}:${var.account}:${var.common-name-value}s3-event-notification-queue"
        }
        ]
      })
}
# S3 bucket
resource "aws_s3_bucket" "SourceBucket" {
  bucket = "s3-${var.common-name-value}${var.suffix}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_access_to_objects" {
  bucket = aws_s3_bucket.SourceBucket.id
  policy = data.aws_iam_policy_document.allow_access_to_objects.json
}

data "aws_iam_policy_document" "allow_access_to_objects" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["${var.account}"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "${aws_s3_bucket.SourceBucket.arn}", "${aws_s3_bucket.SourceBucket.arn}/*",
    ]
  }
}
#sns topic
resource "aws_sns_topic" "SnsLabTopic" {
  name = "s3-sns-lab"

  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement": [
    {
      "Sid": "csv-sns-topic-statement-ID",
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "SNS:Publish",
      "Resource": "arn:aws:sns:${var.region}:${var.account}:s3-sns-lab",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${var.account}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:s3:*:*:s3-${var.common-name-value}${var.suffix}"
        }
      }
    }
  ]
}
POLICY

}

# S3 event filter
resource "aws_s3_bucket_notification" "SourceBucketNotification" {
  bucket = aws_s3_bucket.xxxxx.id
  
  topic{
    topic_arn = "${aws_sns_topic.xxxx.arn}"
    events = ["s3:ObjectCreated:*"]
  }
}

# Event source from SQS
resource "aws_sns_topic_subscription" "sns_events_updates_sqs_target" {
    topic_arn = "${aws_sns_topic.xxxx.arn}"
    protocol  = "sqs"
    endpoint  = "${aws_sqs_queue.xxxx.arn}"
    depends_on = [aws_sqs_queue.xxxx]
}
