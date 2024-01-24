locals {

  ##################
  ## Set defaults ##
  ##################

  // api_gateway
  api_gateway = merge(var.api_gateway_default, var.api_gateway)

  // api_gateway_stages defaults
  api_gateway_stages = var.api_gateway_stages != null ? [for stage in var.api_gateway_stages : merge(var.api_gateway_stage_default, stage)] : null

  // api_gateway_models defaults
  api_gateway_models = var.api_gateway_models != null ? [for model in var.api_gateway_models : merge(var.api_gateway_model_default, model)] : null

  // api_keys
  api_keys = var.api_keys != null ? [for api_key in var.api_keys : merge(var.api_keys_default, api_key)] : null

  // vpc_links
  vpc_links = var.vpc_links != null ? [for vpc_link in var.vpc_links : merge(var.vpc_link_default, vpc_link)] : null

  // authorizer_definitions
  authorizer_definitions = var.authorizer_definitions != null ? [for auth in var.authorizer_definitions : merge(var.authorizer_definition_default, auth)] : null

  // if cors_origin_domain is specified, add it to the options gateway response
  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
    "method.response.header.Access-Control-Allow-Origin"      = "'${var.cors_origin_domain}'"
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent'"
    "method.response.header.Access-Control-Allow-Methods"     = "'OPTIONS,GET,POST'"
  }

  gateway_response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"      = "'${var.cors_origin_domain}'"
    "gatewayresponse.header.Access-Control-Allow-Headers"     = "'${var.cors_origin_domain}'"
    "gatewayresponse.header.Access-Control-Allow-Credentials" = "'true'"
  }

  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }

  options_integration_response_default = var.cors_origin_domain != "" ? merge(var.options_integration_response_default, { response_parameters = local.response_parameters }) : var.options_integration_response_default

  // api_gateway_methods
  api_gateway_methods = [for method in var.api_gateway_methods :
    merge(method,
      { api_method = merge(
        var.api_gateway_method_default,
        try(method.api_method, {}),
        try({ integration = merge(var.method_integration_default, method.api_method.integration) }, { integration = var.method_integration_default }),
        try({ integration_response = merge(var.method_integration_response_default, method.api_method.integration_response) }, { integration_response = var.method_integration_response_default }),
        try({ response = merge(var.method_response_default, method.api_method.response) }, { response = var.method_response_default }),
      ) },
      { options_method = merge(
        var.api_gateway_options_default,
        try(method.options_method, {}),
        try({ integration = merge(var.options_integration_default, method.options_method.integration) }, { integration = var.options_integration_default }),
        try({ integration_response = merge(local.options_integration_response_default, method.options_method.integration_response) }, { integration_response = local.options_integration_response_default }),
        try({ response = merge(var.options_response_default, method.options_method.response) }, { response = var.options_response_default }),
      ) },
  )]

  // api_gateway_methods
  api_gateway_responses = [for api_gateway_response in merge({ for api_gateway_response in var.api_gateway_responses_default : api_gateway_response.response_type => api_gateway_response }, { for api_gateway_response in var.api_gateway_responses : api_gateway_response.response_type => api_gateway_response }) :
    merge(
      api_gateway_response,
      {
        response_type       = api_gateway_response.response_type
        response_parameters = try(merge(local.gateway_response_parameters, api_gateway_response.response_parameters), local.gateway_response_parameters)
        status_code         = try(api_gateway_response.status_code, null)
        response_templates  = try(merge(local.response_templates, api_gateway_response.response_templates), local.response_templates)
      }
    )
  ]

  ###########################
  ## Resource path parsing ##
  ###########################

  paths = [for method in local.api_gateway_methods : method.resource_path]

  paths_as_segments = [for path in local.paths : split("/", path)]

  unique_paths = (toset(
    flatten(
      [for path_segments in local.paths_as_segments :
        [for end_index in range(length(path_segments), 0) :
  join("/", slice(path_segments, 0, end_index))]])))

  length_paths_map = (transpose({ for path in local.unique_paths : path => [length(split("/", path))] }))

  length_path_segments_map = ({ for quantity, paths in local.length_paths_map : quantity => [for path in paths : split("/", path)] })

  max_number_of_levels = can(local.length_path_segments_map) ? length(local.length_path_segments_map) : 0

  resource_method_map = (
    merge(
      { for item in aws_api_gateway_resource.first_paths : trimprefix(item.path, "/") => item.id },
      { for item in aws_api_gateway_resource.second_paths : trimprefix(item.path, "/") => item.id },
      { for item in aws_api_gateway_resource.third_paths : trimprefix(item.path, "/") => item.id },
      { for item in aws_api_gateway_resource.fourth_paths : trimprefix(item.path, "/") => item.id },
      { for item in aws_api_gateway_resource.fifth_paths : trimprefix(item.path, "/") => item.id }
    )
  )
}
