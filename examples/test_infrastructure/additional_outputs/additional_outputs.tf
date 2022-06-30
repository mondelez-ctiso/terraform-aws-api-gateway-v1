resource "local_file" "outputs" {
  content  = jsonencode(local.value)
  filename = "${path.module}/locals.json"
}

locals {
  value = {
    api_gateway                          = local.api_gateway
    api_gateway_stages                   = local.api_gateway_stages
    api_gateway_models                   = local.api_gateway_models
    api_keys                             = local.api_keys
    vpc_links                            = local.vpc_links
    authorizer_definitions               = local.authorizer_definitions
    response_parameters                  = local.response_parameters
    gateway_response_parameters          = local.gateway_response_parameters
    response_templates                   = local.response_templates
    options_integration_response_default = local.options_integration_response_default
    api_gateway_methods                  = local.api_gateway_methods
    api_gateway_responses                = local.api_gateway_responses
    paths                                = local.paths
    paths_as_segments                    = local.paths_as_segments
    unique_paths                         = local.unique_paths
    length_paths_map                     = local.length_paths_map
    length_path_segments_map             = local.length_path_segments_map
    max_number_of_levels                 = local.max_number_of_levels
    resource_method_map                  = local.resource_method_map
  }
}
