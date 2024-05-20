output "rest_api_id" {
  value       = values(aws_api_gateway_rest_api.default)[0]["id"]
  description = "The ID of the REST API."
}

output "rest_api_execution_arn" {
  value       = values(aws_api_gateway_rest_api.default)[0]["execution_arn"]
  description = "The Execution ARN of the REST API."
}

output "api_gateway_stage_invoke_urls" {
  value = {
    for stage, details in aws_api_gateway_stage.default :
    stage => details.invoke_url
  }
  description = "A map of invoke_urls for a given key (stage_name)."
}
