data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.env_bucket.arn,
      "${aws_s3_bucket.env_bucket.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}