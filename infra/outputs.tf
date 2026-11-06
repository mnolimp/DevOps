output "s3_bucket_name" {
  value = aws_s3_bucket.results.bucket
}

output "sqs_queue_url" {
  value = aws_sqs_queue.jobs.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.jobs.arn
}