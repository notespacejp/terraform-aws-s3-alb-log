terraform {
    required_version = ">= 1.0.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = ">= 4.0.0"
        }
    }
}

data "aws_elb_service_account" "this" {}
data "aws_caller_identity" "this" {}

resource "aws_s3_bucket" "this" {
    bucket = var.bucket_name
}

data "aws_iam_policy_document" "this" {
    statement {
        effect = "Allow"
        actions = ["s3:PutObject"]
        principals {
            type = "AWS"
            identifiers = ["arn:aws:iam::${data.aws_elb_service_account.this.id}:root"]
        }
        resources = ["arn:aws:s3:::${aws_s3_bucket.this.bucket}/AWSLogs/${data.aws_caller_identity.this.account_id}/*"]
    }

    statement {
        effect = "Allow"
        actions = ["s3:PutObject"]
        principals {
            type = "Service"
            identifiers = ["delivery.logs.amazonaws.com"]
        }
        resources = [
            "arn:aws:s3:::${aws_s3_bucket.this.bucket}/AWSLogs/${data.aws_caller_identity.this.account_id}/*"
        ]
        condition {
            test = "StringEquals"
            variable = "s3:x-amz-acl"
            values = ["bucket-owner-full-control"]
        }
    }

    statement {
        effect = "Allow"
        actions = ["s3:GetBucketAcl"]
        principals {
            type = "Service"
            identifiers = ["delivery.logs.amazonaws.com"]
        }
        resources = ["arn:aws:s3:::${aws_s3_bucket.this.bucket}"]
    }
}

resource "aws_s3_bucket_policy" "this" {
    bucket = aws_s3_bucket.this.id
    policy = data.aws_iam_policy_document.this.json
}