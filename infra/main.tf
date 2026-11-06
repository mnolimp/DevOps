resource "aws_s3_bucket" "results" {
  bucket        = "scraper-results"
  force_destroy = true
}

resource "aws_sqs_queue" "jobs" {
  name = "scraper-jobs"
}