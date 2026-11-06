import { SQSClient } from "@aws-sdk/client-sqs";
import { S3Client } from "@aws-sdk/client-s3";

const endpoint = process.env.AWS_ENDPOINT_URL || "http://localhost:4566";
const region = process.env.AWS_REGION || "us-east-1";
const credentials = {
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || "test",
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "test",
};

export const sqs = new SQSClient({ endpoint, region, credentials });
export const s3 = new S3Client({ endpoint, region, credentials, forcePathStyle: true });