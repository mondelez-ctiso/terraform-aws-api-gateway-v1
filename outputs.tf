output "rest_api_id" {
  value       = values(aws_api_gateway_rest_api.default)[0]["id"]
  description = "The ID of the REST API."
}

output "rest_api_execution_arn" {
  value       = values(aws_api_gateway_rest_api.default)[0]["execution_arn"]
  description = "The Execution ARN of the REST API."
}
