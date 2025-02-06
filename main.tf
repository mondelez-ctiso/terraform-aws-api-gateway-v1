# Resource    : API Gateway
# Description : Terraform resource to create an API Gateway REST API on AWS.
resource "aws_api_gateway_rest_api" "default" {
  for_each = var.api_gateway != null ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  api_key_source           = each.value["api_key_source"]
  binary_media_types       = each.value["binary_media_types"]
  description              = each.value["description"]
  minimum_compression_size = each.value["minimum_compression_size"]
  name                     = each.value["name"]
  policy                   = each.value["policy"]
  body                     = var.api_specification

  dynamic "endpoint_configuration" {
    for_each = each.value["endpoint_configuration"] == null ? [] : [each.value["endpoint_configuration"]]
    content {
      types            = endpoint_configuration.value.types
      vpc_endpoint_ids = lookup(endpoint_configuration.value, "vpc_endpoint_ids", null)
    }
  }

  tags = var.tags
}

# Resource    : Api Gateway Client Certificate
# Description : Terraform resource to create Api Gateway Client Certificate on AWS.
resource "aws_api_gateway_client_certificate" "default" {
  for_each = var.api_gateway != null && local.api_gateway.client_cert_enabled == true ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  description = each.value["client_cert_description"]
  tags        = var.tags
}

# Resource    : EDGE Api Gateway Custom Domain Name
# Description : Terraform resource to create Api Gateway Custom Domain on AWS at EDGE
resource "aws_api_gateway_domain_name" "api_domain_edge" {
  for_each = var.api_gateway != null && local.api_gateway.custom_domain != null && !local.is_regional ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  certificate_arn = each.value["acm_cert_arn"]
  domain_name     = each.value["custom_domain"]

  dynamic "endpoint_configuration" {
    for_each = each.value["endpoint_configuration"] == null ? [] : [each.value["endpoint_configuration"]]
    content {
      types = endpoint_configuration.value.types
    }
  }
}

# Resource    : REGIONAL Api Gateway Custom Domain Name
# Description : Terraform resource to create Api Gateway Custom Domain on AWS at REGIONAL
resource "aws_api_gateway_domain_name" "api_domain_regional" {
  for_each = var.api_gateway != null && local.api_gateway.custom_domain != null && local.is_regional ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  regional_certificate_arn = each.value["acm_cert_arn"]
  domain_name              = each.value["custom_domain"]

  dynamic "endpoint_configuration" {
    for_each = each.value["endpoint_configuration"] == null ? [] : [each.value["endpoint_configuration"]]
    content {
      types = endpoint_configuration.value.types
    }
  }
}

# Resource    : Api Gateway Base Path Mapping
# Description : Terraform resource to create Api Gateway base path mapping on AWS.
resource "aws_api_gateway_base_path_mapping" "mapping" {
  for_each = { for stage in local.api_gateway_stages : stage.stage_name == "main" && var.remap_main_to_prod ? "prod" : stage.stage_name => stage if local.api_gateway.custom_domain != null }

  api_id      = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  stage_name  = each.key
  domain_name = local.api_gateway.custom_domain
  base_path   = each.key == "prod" ? "" : each.key

  depends_on = [aws_api_gateway_deployment.default, aws_api_gateway_stage.default]
}

# Resource    : DNS record using Route53.
# Description : Route53 is not specifically required; any DNS host can be used.
resource "aws_route53_record" "api_dns" {
  for_each = var.api_gateway != null && local.api_gateway.custom_domain != null ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  name    = local.is_regional ? aws_api_gateway_domain_name.api_domain_regional[local.api_gateway.name].domain_name : aws_api_gateway_domain_name.api_domain_edge[local.api_gateway.name].domain_name
  type    = "A"
  zone_id = each.value["hosted_zone_id"]

  alias {
    evaluate_target_health = true
    name                   = local.is_regional ? aws_api_gateway_domain_name.api_domain_regional[local.api_gateway.name].regional_domain_name : aws_api_gateway_domain_name.api_domain_edge[local.api_gateway.name].cloudfront_domain_name
    zone_id                = local.is_regional ? aws_api_gateway_domain_name.api_domain_regional[local.api_gateway.name].regional_zone_id : aws_api_gateway_domain_name.api_domain_edge[local.api_gateway.name].cloudfront_zone_id
  }
}

# Resource    : Api Gateway Deployment
# Description : Terraform resource to create Api Gateway Deployment on AWS.
resource "aws_api_gateway_deployment" "default" {
  for_each = var.api_gateway != null && local.api_gateway.default_deployment_name != null ? { for gw in [local.api_gateway] : gw.name => gw } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  description = each.value["default_deployment_description"]
  variables   = each.value["default_deployment_variables"]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.default,
      aws_api_gateway_integration.options_integration,
      aws_api_gateway_method.default,
      aws_api_gateway_method.options_method,
      aws_api_gateway_model.default
    ]))
  }

  depends_on = [aws_api_gateway_method.default, aws_api_gateway_integration.default, aws_api_gateway_model.default]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_account" "this" {
  count = local.any_api_method_with_settings ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gw_cw_role[0].arn
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api_gw_cw_role" {
  count = local.any_api_method_with_settings ? 1 : 0

  name               = "APIGWCloudwatchrole-${data.aws_region.current.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "api_gw_cw_role_policy_attachment" {
  count = local.any_api_method_with_settings ? 1 : 0

  role       = aws_iam_role.api_gw_cw_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Resource    : Api Gateway Stage
# Description : Terraform resource to create Api Gateway Stage on AWS
resource "aws_api_gateway_stage" "default" {
  depends_on = [aws_api_gateway_account.this[0]]

  for_each = { for stage in local.api_gateway_stages : stage.stage_name == "main" && var.remap_main_to_prod ? "prod" : stage.stage_name => stage }

  rest_api_id           = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  deployment_id         = aws_api_gateway_deployment.default[local.api_gateway.name].id
  stage_name            = each.value["stage_name"]
  cache_cluster_enabled = each.value["cache_cluster_enabled"]
  cache_cluster_size    = each.value["cache_cluster_size"]
  client_certificate_id = each.value["client_certificate_id"] != null ? each.value["client_certificate_id"] : (local.api_gateway.client_cert_enabled ? aws_api_gateway_client_certificate.default[local.api_gateway.name].id : "")
  description           = each.value["stage_description"]
  documentation_version = each.value["documentation_version"]
  variables             = each.value["stage_variables"]
  xray_tracing_enabled  = each.value["xray_tracing_enabled"]

  dynamic "access_log_settings" {
    for_each = each.value["access_log_settings"]
    content {
      destination_arn = access_log_settings.value["destination_arn"]
      format          = access_log_settings.value["format"]
    }
  }

  tags = var.tags
}

# Resource    : Api Gateway WAF Association
# Description : Terraform resource to associate a WAF to the API Gateway.
resource "aws_wafv2_web_acl_association" "association" {
  for_each     = { for stage in local.api_gateway_stages : stage.stage_name == "main" && var.remap_main_to_prod ? "prod" : stage.stage_name => stage if stage.web_acl_enabled }
  resource_arn = aws_api_gateway_stage.default[each.key].arn
  web_acl_arn  = each.value["web_acl_arn"]
}

# Resource    : Api Gateway Model
# Description : Terraform resource to create Api Gateway model on AWS.
resource "aws_api_gateway_model" "default" {
  for_each = { for model in local.api_gateway_models : model.name => model }

  rest_api_id  = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  name         = each.value["name"]
  description  = each.value["description"]
  content_type = each.value["content_type"]
  schema       = each.value["schema"]
}

# Resource    : Api Gateway Api Key
# Description : Terraform resource to create Api Gateway Api Key on AWS.
resource "aws_api_gateway_api_key" "default" {
  for_each = { for key in local.api_keys : key.key_name => key }

  name        = each.value["key_name"]
  description = each.value["key_description"]
  enabled     = each.value["enabled"]
  value       = each.value["value"]

  tags = var.tags
}

# Resource    : Api Gateway VPC Link
# Description : Terraform resource to create Api Gateway VPC Link on AWS.
resource "aws_api_gateway_vpc_link" "default" {
  for_each = { for link in local.vpc_links : link.vpc_link_name => link }

  name        = each.value["vpc_link_name"]
  description = each.value["vpc_link_description"]
  target_arns = each.value["target_arns"]

  tags = var.tags
}

# Resource    : Api Gateway Authorizer
# Description : Terraform resource to create Api Gateway Authorizer on AWS.
resource "aws_api_gateway_authorizer" "default" {
  for_each = { for auth in local.authorizer_definitions : auth.authorizer_name => auth }

  rest_api_id                      = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  name                             = each.value["authorizer_name"]
  authorizer_uri                   = each.value["authorizer_uri"]
  authorizer_credentials           = each.value["authorizer_credentials"]
  authorizer_result_ttl_in_seconds = each.value["authorizer_result_ttl_in_seconds"]
  identity_source                  = each.value["identity_source"]
  type                             = each.value["authorizer_type"]
  identity_validation_expression   = each.value["identity_validation_expression"]
  provider_arns                    = each.value["provider_arns"]
}

# Resource    : Api Gateway Resources (curently supporting up to 5 nested levels)
# Description : Terraform resource to create Api Gateway Resources on AWS
resource "aws_api_gateway_resource" "first_paths" {
  for_each = local.max_number_of_levels > 0 ? toset(flatten(local.length_path_segments_map[1])) : []

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_rest_api.default[local.api_gateway.name].root_resource_id
  path_part   = each.value
}

resource "aws_api_gateway_resource" "second_paths" {
  for_each = local.max_number_of_levels > 1 ? { for path in local.length_path_segments_map[2] : join("/", path) => { segment = path[1], parent = join("/", slice(path, 0, 1)) } } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_resource.first_paths[each.value.parent].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "third_paths" {
  for_each = local.max_number_of_levels > 2 ? { for path in local.length_path_segments_map[3] : join("/", path) => { segment = path[2], parent = join("/", slice(path, 0, 2)) } } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_resource.second_paths[each.value.parent].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "fourth_paths" {
  for_each = local.max_number_of_levels > 3 ? { for path in local.length_path_segments_map[4] : join("/", path) => { segment = path[3], parent = join("/", slice(path, 0, 3)) } } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_resource.third_paths[each.value.parent].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "fifth_paths" {
  for_each = local.max_number_of_levels > 4 ? { for path in local.length_path_segments_map[5] : join("/", path) => { segment = path[4], parent = join("/", slice(path, 0, 4)) } } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_resource.fourth_paths[each.value.parent].id
  path_part   = each.value.segment
}

resource "aws_api_gateway_resource" "sixth_paths" {
  for_each = local.max_number_of_levels > 5 ? { for path in local.length_path_segments_map[6] : join("/", path) => { segment = path[5], parent = join("/", slice(path, 0, 5)) } } : {}

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  parent_id   = aws_api_gateway_resource.fifth_paths[each.value.parent].id
  path_part   = each.value.segment
}

########################
## API Gateway Method ##
########################

# Resource    : Api Gateway Method
# Description : Terraform resource to create Api Gateway Method on AWS.
resource "aws_api_gateway_method" "default" {
  for_each = { for method in local.api_gateway_methods : method.key => method }

  rest_api_id   = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id   = lookup(local.resource_method_map, each.value["resource_path"])
  http_method   = each.value["api_method"]["http_method"]
  authorization = each.value["api_method"]["authorization"]
  authorizer_id = (each.value["api_method"]["authorizer_id"] != null ?
    each.value["api_method"]["authorizer_id"] :
    each.value["api_method"]["authorizer_name"] != null ?
  aws_api_gateway_authorizer.default[each.value["api_method"]["authorizer_name"]].id : null)
  authorization_scopes = each.value["api_method"]["authorization_scopes"]
  api_key_required     = each.value["api_method"]["api_key_required"]
  request_models       = each.value["api_method"]["request_models"]
  request_validator_id = each.value["api_method"]["request_validator_id"]
  request_parameters   = each.value["api_method"]["request_parameters"]
}

# Resource    : AWS API Gateway method settings.
# Description : Added settings
resource "aws_api_gateway_method_settings" "method_settings" {
  for_each = { for method in local.stage_api_methods : method.key => method if contains(keys(method["api_method"]), "settings") }

  rest_api_id = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  stage_name  = aws_api_gateway_stage.default[each.value["stage_name"]].stage_name
  method_path = "${each.value["resource_path"]}/${each.value["api_method"]["http_method"]}"

  dynamic "settings" {
    for_each = [each.value["api_method"]["settings"]]
    content {
      metrics_enabled                            = lookup(settings.value, "metrics_enabled", false)
      logging_level                              = lookup(settings.value, "logging_level", "ERROR")
      caching_enabled                            = lookup(settings.value, "caching_enabled", false)
      cache_data_encrypted                       = lookup(settings.value, "cache_data_encrypted", true)
      cache_ttl_in_seconds                       = lookup(settings.value, "cache_ttl_in_seconds", null)
      data_trace_enabled                         = lookup(settings.value, "data_trace_enabled", false)
      require_authorization_for_cache_control    = lookup(settings.value, "require_authorization_for_cache_control", false)
      throttling_burst_limit                     = lookup(settings.value, "throttling_burst_limit", -1)
      throttling_rate_limit                      = lookup(settings.value, "throttling_rate_limit", -1)
      unauthorized_cache_control_header_strategy = lookup(settings.value, "unauthorized_cache_control_header_strategy", null)
    }
  }
}

# Resource    : Api Gateway Method Response
# Description : Terraform resource to create Api Gateway Method Response on AWS.
resource "aws_api_gateway_method_response" "default" {
  for_each = { for method in local.api_gateway_methods : method.key => method }

  rest_api_id         = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id         = lookup(local.resource_method_map, each.value["resource_path"])
  http_method         = each.value["api_method"]["http_method"]
  status_code         = each.value["api_method"]["response"]["status_code"]
  response_models     = each.value["api_method"]["response"]["response_models"]
  response_parameters = each.value["api_method"]["response"]["response_parameters"]

  depends_on = [aws_api_gateway_method.default, aws_api_gateway_model.default]
}

# Resource    : Api Gateway Integration
# Description : Terraform resource to create Api Gateway Integration on AWS.
resource "aws_api_gateway_integration" "default" {
  for_each = { for method in local.api_gateway_methods : method.key => method }

  rest_api_id             = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id             = lookup(local.resource_method_map, each.value["resource_path"])
  http_method             = each.value["api_method"]["http_method"]
  integration_http_method = each.value["api_method"]["integration"]["integration_http_method"]
  type                    = each.value["api_method"]["integration"]["type"]
  connection_type         = each.value["api_method"]["integration"]["connection_type"]
  connection_id           = each.value["api_method"]["integration"]["connection_id"]
  uri                     = each.value["api_method"]["integration"]["uri"]
  credentials             = each.value["api_method"]["integration"]["credentials"]
  request_parameters      = each.value["api_method"]["integration"]["request_parameters"]
  request_templates       = each.value["api_method"]["integration"]["request_templates"]
  passthrough_behavior    = each.value["api_method"]["integration"]["passthrough_behavior"]
  cache_key_parameters    = each.value["api_method"]["integration"]["cache_key_parameters"]
  cache_namespace         = each.value["api_method"]["integration"]["cache_namespace"]
  content_handling        = each.value["api_method"]["integration"]["content_handling"]
  timeout_milliseconds    = each.value["api_method"]["integration"]["timeout_milliseconds"]

  depends_on = [aws_api_gateway_method.default]
}

# Resource    : Api Gateway Integration Response
# Description : Terraform resource to create Api Gateway Integration Response on AWS for creating api.
resource "aws_api_gateway_integration_response" "default" {
  for_each = { for method in local.api_gateway_methods : method.key => method }

  rest_api_id         = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id         = lookup(local.resource_method_map, each.value["resource_path"])
  http_method         = each.value["api_method"]["http_method"]
  status_code         = each.value["api_method"]["integration_response"]["status_code"]
  response_parameters = each.value["api_method"]["integration_response"]["response_parameters"]
  response_templates  = each.value["api_method"]["integration_response"]["response_template"]
  content_handling    = each.value["api_method"]["integration_response"]["content_handling"]
  selection_pattern   = each.value["api_method"]["integration_response"]["selection_pattern"]

  depends_on = [
    aws_api_gateway_integration.default,
  ]
}

####################
## Options Method ##
####################

# Resource    : Api Gateway Options Method
# Description : Terraform resource to create Api Gateway Options Method on AWS.
resource "aws_api_gateway_method" "options_method" {
  for_each = { for method in local.api_gateway_methods : method.resource_path => method... }

  rest_api_id   = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id   = lookup(local.resource_method_map, each.value[0]["resource_path"])
  http_method   = each.value[0]["options_method"]["http_method"]
  authorization = each.value[0]["options_method"]["authorization"]
  authorizer_id = (each.value[0]["options_method"]["authorizer_id"] != null ?
    each.value[0]["options_method"]["authorizer_id"] :
    each.value[0]["options_method"]["authorizer_name"] != null ?
    aws_api_gateway_authorizer.default[each.value["options_method"]["authorizer_name"]].id :
  null)
  authorization_scopes = each.value[0]["options_method"]["authorization_scopes"]
  api_key_required     = each.value[0]["options_method"]["api_key_required"]
  request_models       = each.value[0]["options_method"]["request_models"]
  request_validator_id = each.value[0]["options_method"]["request_validator_id"]
  request_parameters   = each.value[0]["options_method"]["request_parameters"]
}

# Resource    : Api Gateway Method Options Response
# Description : Terraform resource to create Api Gateway Method Options Response on AWS.
resource "aws_api_gateway_method_response" "options_200" {
  for_each = { for method in local.api_gateway_methods : method.resource_path => method... }

  rest_api_id         = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id         = lookup(local.resource_method_map, each.value[0]["resource_path"])
  http_method         = each.value[0]["options_method"]["http_method"]
  status_code         = each.value[0]["options_method"]["response"]["status_code"]
  response_models     = each.value[0]["options_method"]["response"]["response_models"]
  response_parameters = each.value[0]["options_method"]["response"]["response_parameters"]

  depends_on = [aws_api_gateway_method.options_method]
}

# Resource    : Api Gateway Options Integration
# Description : Terraform resource to create Api Gateway Options Integration on AWS.
resource "aws_api_gateway_integration" "options_integration" {
  for_each = { for method in local.api_gateway_methods : method.resource_path => method... }

  rest_api_id             = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id             = lookup(local.resource_method_map, each.value[0]["resource_path"])
  http_method             = each.value[0]["options_method"]["http_method"]
  integration_http_method = each.value[0]["options_method"]["integration"]["integration_http_method"]
  type                    = each.value[0]["options_method"]["integration"]["type"]
  connection_type         = each.value[0]["options_method"]["integration"]["connection_type"]
  connection_id           = each.value[0]["options_method"]["integration"]["connection_id"]
  uri                     = each.value[0]["options_method"]["integration"]["uri"]
  credentials             = each.value[0]["options_method"]["integration"]["credentials"]
  request_parameters      = each.value[0]["options_method"]["integration"]["request_parameters"]
  request_templates       = each.value[0]["options_method"]["integration"]["request_templates"]
  passthrough_behavior    = each.value[0]["options_method"]["integration"]["passthrough_behavior"]
  cache_key_parameters    = each.value[0]["options_method"]["integration"]["cache_key_parameters"]
  cache_namespace         = each.value[0]["options_method"]["integration"]["cache_namespace"]
  content_handling        = each.value[0]["options_method"]["integration"]["content_handling"]
  timeout_milliseconds    = each.value[0]["options_method"]["integration"]["timeout_milliseconds"]

  depends_on = [aws_api_gateway_method.options_method]
}

# Resource    : Api Gateway Integration Response
# Description : Terraform resource to create Api Gateway Integration Response on AWS for creating api.
resource "aws_api_gateway_integration_response" "options_integration_response" {
  for_each = { for method in local.api_gateway_methods : method.resource_path => method... }

  rest_api_id         = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  resource_id         = lookup(local.resource_method_map, each.value[0]["resource_path"])
  http_method         = each.value[0]["options_method"]["http_method"]
  status_code         = each.value[0]["options_method"]["integration_response"]["status_code"]
  response_parameters = each.value[0]["options_method"]["integration_response"]["response_parameters"]
  response_templates  = each.value[0]["options_method"]["integration_response"]["response_template"]
  content_handling    = each.value[0]["options_method"]["integration_response"]["content_handling"]
  selection_pattern   = each.value[0]["options_method"]["integration_response"]["selection_pattern"]

  depends_on = [
    aws_api_gateway_integration.options_integration,
  ]
}

resource "aws_api_gateway_gateway_response" "cors" {
  for_each = { for response in local.api_gateway_responses : response.response_type => response }

  rest_api_id   = aws_api_gateway_rest_api.default[local.api_gateway.name].id
  response_type = each.value["response_type"]

  response_parameters = each.value["response_parameters"]
  status_code         = each.value["status_code"]
  response_templates  = each.value["response_templates"]
}
