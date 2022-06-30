variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to add to all resources."

  validation {
    condition     = can([for key, value in var.tags : length(key) <= 128])
    error_message = "AWS Tag Keys must be 128 characters or less in length."
  }

  validation {
    condition     = can([for key, value in var.tags : length(value) <= 256])
    error_message = "AWS Tag Values must be 256 characters or less in length."
  }

  validation {
    condition     = can([for key, value in var.tags : regex("^[\\w\\d\\s\\+\\-\\=\\.\\_\\:\\/\\@]+$", "${key} ${value}")])
    error_message = "AWS Tag Keys and Values must match RegExp ^[\\w\\d\\s\\+\\-\\=\\.\\_\\:\\/\\@]+$ ."
  }
}

variable "api_gateway_default" {
  description = "AWS API Gateway Settings default."
  type        = any
  default = {
    name                                = null
    api_key_source                      = null
    binary_media_types                  = null
    description                         = "Managed by terraform-aws-api-gateway-v1 module"
    endpoint_configuration              = null
    minimum_compression_size            = null
    policy                              = null
    hosted_zone_id                      = null
    custom_domain                       = null
    acm_cert_arn                        = null
    base_path_mapping_active_stage_name = null
    default_deployment_name             = "default"
    default_deployment_description      = null
    default_deployment_variables        = null
    client_cert_enabled                 = false
    client_cert_description             = "Managed by terraform-aws-api-gateway-v1 module"
  }
}

variable "api_gateway" {
  description = "AWS API Gateway Settings."
  type        = any
  default     = null
  /*
  type = object({
    api_key_source                      = any # "The source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER."
    binary_media_types                  = set(string) # "The list of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads."
    description                         = string # "The description of the REST API "
    endpoint_configuration              = object({
      types = set(string) This resource currently only supports managing a single value. Valid values: EDGE, REGIONAL or PRIVATE
      vpc_endpoint_ids = set(string) (Optional) A list of VPC Endpoint Ids.
    })
    minimum_compression_size            = any # "Minimum response size to compress for the REST API. Integer between -1 and 10485760 (10MB). Setting a value greater than -1 will enable compression, -1 disables compression (default)."
    name                                = string # "The name of the API Gateway."
    policy                              = string
  })
  */

  // api_gateway not null
  validation {
    condition     = var.api_gateway != null
    error_message = "Variable object 'api_gateway' must be provided."
  }

  // name
  validation {
    condition     = try(length(tostring(var.api_gateway.name)) > 1)
    error_message = "Attribute 'name' of 'api_gateway' must be provided."
  }

  // description
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "description", "")))
    error_message = "Optional attribute 'description' of 'api_gateway' must be a string if specified."
  }

  // base_path_mapping_active_stage_name
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "base_path_mapping_active_stage_name", "")))
    error_message = "Optional attribute 'base_path_mapping_active_stage_name' of 'api_gateway' must be a string if specified."
  }

  // default_deployment_name
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "default_deployment_name", "")))
    error_message = "Optional attribute 'default_deployment_name' of 'api_gateway' must be a string if specified."
  }

  // default_deployment_description
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "default_deployment_description", "")))
    error_message = "Optional attribute 'default_deployment_description' of 'api_gateway' must be a string if specified."
  }

  // default_deployment_variables
  validation {
    condition     = var.api_gateway != null ? can(tomap(lookup(var.api_gateway, "default_deployment_variables", null))) : true
    error_message = "Optional attribute 'default_deployment_variables' of 'api_gateway' must be an object map."
  }

  // client_cert_enabled
  validation {
    condition     = can(tobool(lookup(var.api_gateway, "client_cert_enabled", false)))
    error_message = "Optional attribute 'client_cert_enabled' of 'api_gateway' must be a boolean if specified."
  }

  // client_cert_description
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "client_cert_description", "")))
    error_message = "Optional attribute 'client_cert_description' of 'api_gateway' must be a string if specified."
  }

  // binary_media_types
  validation {
    condition = can(toset([
      for binary_media_type in lookup(var.api_gateway, "binary_media_types", []) : regex("^[\\-\\w\\.]+/[\\-\\w\\.]+$", binary_media_type)
    ]))
    error_message = "Optional attribute 'binary_media_types' of 'api_gateway' must be a set of valid MIME types if specified."
  }

  // minimum_compression_size
  validation {
    condition     = tonumber(lookup(var.api_gateway, "minimum_compression_size", 0)) >= 0 && tonumber(lookup(var.api_gateway, "minimum_compression_size", 0)) <= 10485760
    error_message = "Optional attribute 'minimum_compression_size' of 'api_gateway' must be non-negative between 0 and 10485760 (inclusive) if specified."
  }

  // api_key_source
  validation {
    condition     = contains(["HEADER", "AUTHORIZER"], tostring(lookup(var.api_gateway, "api_key_source", "HEADER")))
    error_message = "Optional attribute 'api_key_source' of 'api_gateway' must be one of:\n\t- HEADER\n\t- AUTHORIZER\n if specified."
  }

  // hosted_zone_id
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "hosted_zone_id", "")))
    error_message = "Optional attribute 'hosted_zone_id' of 'api_gateway' must be a string if specified."
  }


  // custom_domain
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "custom_domain", "")))
    error_message = "Optional attribute 'custom_domain' of 'api_gateway' must be a string if specified."
  }

  // acm_cert_arn
  validation {
    condition     = can(tostring(lookup(var.api_gateway, "acm_cert_arn", "")))
    error_message = "Optional attribute 'acm_cert_arn' of 'api_gateway' must be a string if specified."
  }
  // endpoint_configuration
  validation {
    condition     = can(var.api_gateway.endpoint_configuration) ? length(try(toset(var.api_gateway.endpoint_configuration.types), [])) == 1 : true
    error_message = "Optional attribute 'endpoint_configuration' of 'api_gateway' must be an object with a 'types' attribute of type set(string) and length 1."
  }

  // endpoint_configuration.types
  validation {
    condition     = can(var.api_gateway.endpoint_configuration.types[0]) ? contains(["EDGE", "REGIONAL", "PRIVATE"], var.api_gateway.endpoint_configuration.types[0]) : true
    error_message = "Attribute types of 'api_gateway.endpoint_configuration' must be of type set(string) and only include the following values:\n\t- EDGE\n\t- REGIONAL\n\t- PRIVATE\n."
  }

  // endpoint_configuration.vpc_endpoint_ids
  validation {
    condition = (
      try(var.api_gateway.endpoint_configuration.types[0], "") == "PRIVATE" ?
      can([
        for vpc_endpoint_id in var.api_gateway.endpoint_configuration.vpc_endpoint_ids :
        regex("^vpce-[a-z0-9]+$", vpc_endpoint_id)
      ]) :
      length(try(var.api_gateway.endpoint_configuration.vpc_endpoint_ids, [])) == 0
    )
    error_message = "Attribute types of 'api_gateway.endpoint_configuration.vpc_endpoint_ids' must: \n\t- only be specified when api_gateway.endpoint_configuration.types is PRIVATE\n\t- be a set of VPC Endpoint IDs\n."
  }
}

variable "api_gateway_stage_default" {
  description = "AWS API Gateway stage default."
  type        = any
  default = {
    stage_name            = null
    access_log_settings   = []
    cache_cluster_enabled = false
    cache_cluster_size    = null
    client_certificate_id = null
    documentation_version = null
    stage_description     = "Managed by terraform-aws-api-gateway-v1 module"
    stage_variables       = null
    xray_tracing_enabled  = false
    waf_id                = null
  }
}

variable "api_gateway_stages" {
  description = "AWS API Gateway stage."
  default     = []
  type        = any
  /*
  type = list(object({
    stage_name            = string (required) - The name of the stage. If the specified stage already exists, it will be updated to point to the new deployment. If the stage does not exist, a new one will be created and point to this deployment.
    stage_description     = string (optional) - The description of the stage.
    stage_variables       = map (optional) - A map that defines variables for the stage.
    cache_cluster_enabled = bool (optional) - Specifies whether a cache cluster is enabled for the stage.
    cache_cluster_size    = number (optional) - The size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237.
    client_certificate_id = string (optional) - The identifier of a client certificate for the stage
    documentation_version = string (optional) - The version of the associated API documentation.
    xray_tracing_enabled  = bool (optional) - Whether to enable xray_tracing.
    access_log_settings = list(object({ - optional block
      destination_arn = string (required) - ARN of the log group to send the logs to. Automatically removes trailing :* if present.
      format          = string (optional) - The formatting and values recorded in the logs.
    }))
  }))
  */

  // stage_name
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : can(lookup(stage, "stage_name")) ? length(lookup(stage, "stage_name")) > 1 : false], false)) : true
    error_message = "If the set of 'api_gateway_stages' is provided, each value must contain an attribute 'stage_name' with length > 1."
  }

  // description
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : length(lookup(stage, "stage_description")) > 1], false)) : true
    error_message = "Optional attribute 'stage_description' of 'api_gateway_stages' must be a string if specified with length > 1."
  }

  // stage_variables
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : can(lookup(stage, "stage_variables")) ? can(tomap(lookup(stage, "stage_variables"))) : true], false)) : true
    error_message = "Optional attribute 'stage_variables' of 'api_gateway_stages' must be an object map."
  }

  // cache_cluster_enabled
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : can(lookup(stage, "cache_cluster_enabled")) ? can(tobool(lookup(stage, "cache_cluster_enabled"))) : true], false)) : true
    error_message = "Optional attribute 'cache_cluster_enabled' of 'api_gateway_stages' must be 'true' or 'false'."
  }

  // cache_cluster_size
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : can(lookup(stage, "cache_cluster_size")) ? can(tonumber(lookup(stage, "cache_cluster_size"))) && contains([0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237], lookup(stage, "cache_cluster_size")) : true], false)) : true
    error_message = "Optional attribute 'cache_cluster_size' of 'api_gateway_stages' must be a number in the following set [0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237]."
  }

  // client_certificate_id
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : length(lookup(stage, "client_certificate_id")) > 1], false)) : true
    error_message = "Optional attribute 'client_certificate_id' of 'api_gateway_stages' must be a string if specified with length > 1."
  }

  // documentation_version
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : length(lookup(stage, "documentation_version")) > 1], false)) : true
    error_message = "Optional attribute 'documentation_version' of 'api_gateway_stages' must be a string if specified with length > 1."
  }

  // xray_tracing_enabled
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : can(lookup(stage, "xray_tracing_enabled")) ? can(tobool(lookup(stage, "xray_tracing_enabled"))) : true], false)) : true
    error_message = "Optional attribute 'xray_tracing_enabled' of 'api_gateway_stages' must be 'true' or 'false'."
  }

  // waf_id
  validation {
    condition     = var.api_gateway_stages != [] ? !can(index([for stage in var.api_gateway_stages : length(lookup(stage, "waf_id")) > 1], false)) : true
    error_message = "Optional attribute 'waf_id' of 'api_gateway_stages' must be a string if specified with length > 1."
  }

  // TODO: access_log_settings
}

variable "api_gateway_model_default" {
  description = "AWS API Gateway model default."
  type        = any
  default = {
    name         = null
    description  = "Managed by terraform-aws-api-gateway-v1 module"
    content_type = "application/json"
    schema       = "{\"type\":\"object\"}"
  }
}

variable "api_gateway_models" {
  description = "AWS API Gateway models."
  default     = []
  type        = set(any)
  /*
  type = list(object({
      name         = string (required) - The name of the model.
      description  = string (optional) - The description of the model.
      content_type = string (optional) - The content_type of the model. defaults to "application/json"
      schema       = string (required) - The schea of the model. defaults to "{\"type\":\"object\"}"
  }))
  */

  // name
  validation {
    condition     = var.api_gateway_models != [] ? !can(index([for model in var.api_gateway_models : can(lookup(model, "name")) ? length(lookup(model, "name")) > 1 : false], false)) : true
    error_message = "If the set of 'api_gateway_models' is provided, each value must contain an attribute 'name' with length > 1."
  }

  // description
  validation {
    condition     = var.api_gateway_models != [] ? !can(index([for model in var.api_gateway_models : length(lookup(model, "description")) > 1], false)) : true
    error_message = "Optional attribute 'description' of 'api_gateway_models' must be a string if specified with length > 1."
  }

  // content_type
  validation {
    condition     = var.api_gateway_models != [] ? !can(index([for model in var.api_gateway_models : length(lookup(model, "content_type")) > 1], false)) : true
    error_message = "Optional attribute 'content_type' of 'api_gateway_models' must be a string if specified with length > 1."
  }

  // schema
  validation {
    condition     = var.api_gateway_models != [] ? !can(index([for model in var.api_gateway_models : length(lookup(model, "schema")) > 1], false)) : true
    error_message = "Optional attribute 'schema' of 'api_gateway_models' must be a string if specified with length > 1."
  }
}

variable "api_keys_default" {
  description = "AWS API Gateway API Keys default"
  type        = any
  default = {
    key_name        = null
    key_description = "Managed by terraform-aws-api-gateway-v1 module"
    enabled         = true
    value           = null
  }
}

variable "api_keys" {
  description = "AWS API Gateway API Keys."
  default     = []
  type        = any
  /*
  type = list(object({
    key_name        = string (required) - The name of the API key.
    key_description = string (optional) - The API key description. Defaults to \"Managed by Terraform\".
    enabled         = string (optional) - Whether the API Key is enabled
    value           = string (optional) - The value of the key (if not auto generated)
  }))
  */

  // key_name
  validation {
    condition     = var.api_keys != [] ? !can(index([for api_key in var.api_keys : can(lookup(api_key, "key_name")) ? length(lookup(api_key, "key_name")) > 1 : false], false)) : true
    error_message = "If the set of 'api_keys' is provided, each value must contain an attribute 'key_name' with length > 1."
  }

  // key_description
  validation {
    condition     = var.api_keys != [] ? !can(index([for api_key in var.api_keys : length(lookup(api_key, "key_description")) > 1], false)) : true
    error_message = "Optional attribute 'key_description' of 'api_keys' must be a string if specified with length > 1."
  }

  // enabled
  validation {
    condition     = var.api_keys != [] ? !can(index([for api_key in var.api_keys : can(lookup(api_key, "enabled")) ? can(tobool(lookup(api_key, "enabled"))) : true], false)) : true
    error_message = "Optional attribute 'enabled' of 'api_keys' must be 'true' or 'false'."
  }

  // value
  validation {
    condition     = var.api_keys != [] ? !can(index([for api_key in var.api_keys : length(lookup(api_key, "value")) > 1], false)) : true
    error_message = "Optional attribute 'value' of 'api_keys' must be a string if specified with length > 1."
  }
}

variable "vpc_link_default" {
  description = "AWS API Gateway VPC link defaults."
  type        = any
  default = {
    vpc_link_name        = null
    vpc_link_description = "Managed by terraform-aws-api-gateway-v1 module"
    target_arns          = null
  }
}

variable "vpc_links" {
  description = "AWS API Gateway VPC links."
  default     = []
  type        = any
  /*
  type = list(object({
    vpc_link_name        = string (required) - The name used to label and identify the VPC link.
    vpc_link_description = string (optional) - The description of the VPC link.
    target_arns          = set(string) - The list of network load balancer arns in the VPC targeted by the VPC link. Currently AWS only supports 1 target.
  }))
  */

  // vpc_link_name
  validation {
    condition     = var.vpc_links != [] ? !can(index([for vpc_link in var.vpc_links : can(lookup(vpc_link, "vpc_link_name")) ? length(lookup(vpc_link, "vpc_link_name")) > 1 : false], false)) : true
    error_message = "If the set of 'vpc_links' is provided, each value must contain an attribute 'vpc_link_name' with length > 1."
  }

  // vpc_link_description
  validation {
    condition     = var.vpc_links != [] ? !can(index([for vpc_link in var.vpc_links : length(lookup(vpc_link, "vpc_link_description")) > 1], false)) : true
    error_message = "Optional attribute 'vpc_link_description' of 'vpc_links' must be a string if specified with length > 1."
  }

  // target_arns
  validation {
    condition     = var.vpc_links != [] ? !can(index([for vpc_link in var.vpc_links : length(try(toset(vpc_link.target_arns), [])) == 1], false)) : true
    error_message = "Required attribute 'target_arns' of 'vpc_links' must be a set of at least one string."
  }
}

variable "api_gateway_responses_default" {
  type = any
  default = [
    {
      response_type       = "DEFAULT_4XX"
      response_parameters = {}
      status_code         = null
      response_templates  = {}
    },
    {
      response_type       = "DEFAULT_5XX"
      response_parameters = {}
      status_code         = null
      response_templates  = {}
    },
  ]
}

variable "api_gateway_responses" {
  type    = any
  default = []
  // response_type
  validation {
    condition     = var.api_gateway_responses != [] ? !can(index([for api_gateway_response in var.api_gateway_responses : can(lookup(api_gateway_response, "response_type")) ? length(lookup(api_gateway_response, "response_type")) > 1 : false], false)) : true
    error_message = "If the set of 'api_gateway_responses' is provided, each value must contain an attribute 'response_type' with length > 1."
  }
  // response_parameters
  validation {
    condition     = var.api_gateway_responses != [] ? !can(index([for api_gateway_response in var.api_gateway_responses : length(lookup(api_gateway_response, "api_gateway_responses")) > 1], false)) : true
    error_message = "Optional attribute 'response_parameters' of 'api_gateway_responses' must be a map if specified with length > 1."
  }
  // status_code
  validation {
    condition     = var.api_gateway_responses != [] ? !can(index([for api_gateway_response in var.api_gateway_responses : length(lookup(api_gateway_response, "status_code")) > 1], false)) : true
    error_message = "Optional attribute 'status_code' of 'api_gateway_responses' must be a string if specified with length > 1."
  }
  // response_template
  validation {
    condition     = var.api_gateway_responses != [] ? !can(index([for api_gateway_response in var.api_gateway_responses : length(lookup(api_gateway_response, "response_template")) > 1], false)) : true
    error_message = "Optional attribute 'response_template' of 'api_gateway_responses' must be a map if specified with length > 1."
  }
}

variable "authorizer_definition_default" {
  description = "AWS API Gateway authorizer default."
  type        = any

  default = {
    authorizer_name                  = null
    authorizer_uri                   = null
    identity_source                  = "method.request.header.Authorization"
    identity_validation_expression   = null
    authorizer_result_ttl_in_seconds = 0
    authorizer_type                  = "REQUEST"
    authorizer_credentials           = null
    provider_arns                    = null
  }
}

variable "authorizer_definitions" {
  description = "AWS API Gateway authorizer."
  default     = []
  type        = any

  /*
  type = list(object({
    authorizer_name                  = string (required) - The name of the authorizer.
    authorizer_uri                   = string (required) - The authorizer's Uniform Resource Identifier (URI). This must be a well-formed Lambda function URI in the form of arn:aws:apigateway:{region}:lambda:path/{service_api}, e.g. arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:012345678912:function:my-function/invocations.
    identity_source                  = string (optional) - The source of the identity in an incoming request. Defaults to method.request.header.Authorization. For REQUEST type, this may be a comma-separated list of values, including headers, query string parameters and stage variables - e.g. \"method.request.header.SomeHeaderName,method.request.querystring.SomeQueryStringName\".
    authorizer_type                  = string (optional) - The type of the authorizer. Possible values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, or COGNITO_USER_POOLS for using an Amazon Cognito user pool. Defaults to TOKEN.
    authorizer_credentials           = string (optional) - The credentials required for the authorizer. To specify an IAM Role for API Gateway to assume, use the IAM Role ARN.
    authorizer_result_ttl_in_seconds = number (optional) - The TTL of cached authorizer results in seconds. Defaults to 0.
    identity_validation_expression   = string (optional) - A validation expression for the incoming identity. For TOKEN type, this value should be a regular expression. The incoming token from the client is matched against this expression, and will proceed if the token matches. If the token doesn't match, the client receives a 401 Unauthorized response.
    provider_arns                    = string (optional) - Required for type COGNITO_USER_POOLS) A list of the Amazon Cognito user pool ARNs. Each element is of this format: arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}.
  }))
  */

  // authoizer_name
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : can(lookup(auth, "authorizer_name")) ? length(lookup(auth, "authorizer_name")) > 1 : false], false)) : true
    error_message = "If the set of 'authorizer_definitions' is provided, each value must contain an attribute 'authorizer_name' with length > 1."
  }

  // authoizer_uri
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : can(lookup(auth, "authorizer_uri")) ? length(lookup(auth, "authorizer_uri")) > 1 : false], false)) : true
    error_message = "If the set of 'authorizer_definitions' is provided, each value must contain an attribute 'authorizer_uri' with length > 1."
  }

  // identity_source
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : length(lookup(auth, "identity_source")) > 1], false)) : true
    error_message = "Optional attribute 'identity_source' of 'authorizer_definitions' must be a string if specified with length > 1."
  }

  // authorizer_type
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : can(lookup(auth, "authorizer_type")) ? !contains(["TOKEN", "REQUEST"], lookup(auth, "authorizer_type")) : false], true)) : true
    error_message = "Optional attribute 'authorizer_type' of 'authorizer_definitions' must be a string equal to 'TOKEN' or 'REQUEST'."
  }

  // authorizer_credentials
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : length(lookup(auth, "authorizer_credentials")) > 1], false)) : true
    error_message = "Optional attribute 'authorizer_credentials' of 'authorizer_definitions' must be a string if specified with length > 1."
  }

  // authorizer_result_ttl_in_seconds
  validation {

    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : can(lookup(auth, "authorizer_result_ttl_in_seconds")) ? tonumber(lookup(auth, "authorizer_result_ttl_in_seconds")) >= 0 && tonumber(lookup(auth, "authorizer_result_ttl_in_seconds")) <= 3600 : true], false)) : true
    error_message = "Optional attribute 'authorizer_result_ttl_in_seconds' of 'authorizer_definitions' must be a number in range 0 - 3600."
  }

  // identity_validation_expression
  validation {
    condition     = var.authorizer_definitions != [] ? !can(index([for auth in var.authorizer_definitions : length(lookup(auth, "identity_validation_expression")) > 1], false)) : true
    error_message = "Optional attribute 'identity_validation_expression' of 'authorizer_definitions' must be a string if specified with length > 1."
  }

  // provider_arns
  validation {
    condition = (var.authorizer_definitions != [] ?
      !can(index(
        [for auth in var.authorizer_definitions :
          can(auth.provider_arns) ?
        can(toset(auth.provider_arns)) : true]
      , false)) : # if authorizer_definitions are provided validate provider_arns
    true)         # authorizer_definitions is optional, so return true
    error_message = "Optional attribute 'provider_arns' of 'authorizer_definitions' must be a set of at least one string."
  }
}

variable "api_gateway_method_default" {
  description = "AWS API Gateway methods default."
  type        = any

  default = {
    http_method          = "GET"
    api_key_required     = false
    request_models       = null
    request_validator_id = null
    request_parameters   = {}
    authorization        = "CUSTOM"
    authorizer_id        = null
    authorizer_name      = null
    authorization_scopes = null

    integration = {}

    response = {}

    integration_response = {}
  }
}

variable "method_integration_default" {
  type = any
  default = {
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    connection_type         = "INTERNET"
    connection_id           = null
    uri                     = null
    credentials             = null
    request_templates = {
      "application/json" = "{ \"statusCode\": 200 }"
    }
    request_parameters = {
    }
    content_handling     = null # Null == Passthrough
    passthrough_behavior = null
    cache_key_parameters = null
    cache_namespace      = null
    timeout_milliseconds = 29000
  }
}

variable "method_response_default" {
  type = any
  default = {
    status_code   = "200"
    response_type = null
    response_models = {
      "application/json" = "Empty"
    }

    response_template = null
    response_parameters = {
    }
  }
}

variable "method_integration_response_default" {
  type = any
  default = {
    status_code       = "200"
    selection_pattern = null
    response_template = null
    response_parameters = {
    }
    content_handling = null # Null == Passthrough
  }
}

variable "api_gateway_options_default" {
  description = "AWS API Gateway options default."
  type        = any
  default = {
    http_method          = "OPTIONS"
    api_key_required     = false
    request_models       = null
    request_validator_id = null
    request_parameters   = null
    authorization        = "NONE"
    authorizer_id        = null
    authorizer_name      = null
    authorization_scopes = null

    integration = {}

    response = {}

    integration_response = {}
  }
}

variable "options_integration_default" {
  type = any
  default = {
    integration_http_method = null
    type                    = "MOCK"
    connection_type         = null
    connection_id           = null
    uri                     = null
    credentials             = null
    request_templates = {
      "application/json" = "{ \"statusCode\": 200 }"
    }
    request_parameters = {
    }
    content_handling     = "CONVERT_TO_TEXT"
    passthrough_behavior = null
    cache_key_parameters = null
    cache_namespace      = null
    timeout_milliseconds = 29000
  }
}

variable "options_response_default" {
  type = any
  default = {
    status_code = "200"
    response_models = {
    }
    response_parameters = {
      "method.response.header.Access-Control-Allow-Credentials" = true
      "method.response.header.Access-Control-Allow-Origin"      = true
      "method.response.header.Access-Control-Allow-Headers"     = true
      "method.response.header.Access-Control-Allow-Methods"     = true
    }
  }
}

variable "options_integration_response_default" {
  type = any
  default = {
    status_code       = "200"
    selection_pattern = null
    response_template = {
      "application/json" = ""
    }
    response_parameters = {
    }
    content_handling = null # Null == Passthrough
  }
}

variable "api_gateway_methods" {
  description = "AWS API Gateway methods."
  default     = []
  type        = any

  // resource_path
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method, "resource_path")) ? length(lookup(method, "resource_path")) > 1 && lookup(method, "resource_path") : false], false)) : true
    error_message = "If the set of 'api_gateway_methods' is provided, each value must contain an attribute 'resource_path' with length > 1."
  }

  // api_method.http_method
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(lookup(method.api_method, "http_method")) ?
          contains(["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "ANY"], lookup(method.api_method, "http_method")) : # if can find http_method true
        true]                                                                                                              # Optional so result should be false - http_method not found
      , false))                                                                                                            # index function lookup value
    : true)                                                                                                                # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "Optional attribute 'http_method' of 'api_gateway_methods.api_method' must be a string equal to GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY."
  }

  // api_method.authorization     
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.api_method.authorization) ? contains(["NONE", "CUSTOM", "AWS_IAM", "COGNITO_USER_POOLS"], lookup(method.api_method, "authorization")) : true], false)) : true
    error_message = "Optional attribute 'authorization' of 'api_gateway_methods.api_method' must be a string equal to NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS."
  }

  // api_method.authorizer_id
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.api_method.authorizer_id) ? length(lookup(method.api_method, "authorizer_id")) > 1 : true], false)) : true
    error_message = "Optional attribute 'authorizer_id' of 'api_gateway_methods.api_method' must be a string with length > 1."
  }

  // api_method.authorization_scopes
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.api_method.authorization_scopes) ? length(try(toset(method.api_method.authorization_scopes), [])) == 1 : true], false)) : true
    error_message = "Optional attribute 'authorization_scopes' of 'api_gateway_methods.api_method' must be a set of string with length > 1."
  }

  // api_method.api_key_required
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.api_method.api_key_required) ? can(tobool(lookup(method.api_method, "api_key_required"))) : true], false)) : true
    error_message = "Optional attribute 'api_key_required' of 'api_gateway_methods.api_method' must be 'true' or 'false'."
  }

  // api_method.request_models
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.api_method, "request_models")) ? can(tomap(lookup(method.api_method, "request_models"))) : true], false)) : true
    error_message = "Optional attribute 'request_models' of 'api_gateway_methods.api_method' must be an object map."
  }

  // api_method.request_validator_id
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.api_method, "request_validator_id")) ? length(lookup(method.api_method, "request_validator_id")) > 1 : true], false)) : true
    error_message = "Optional attribute 'request_validator_id' of 'api_gateway_methods.api_method' must be a string with length > 1."
  }

  // api_method.request_parameters
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.api_method, "request_parameters")) ? can(tomap(lookup(method.api_method, "request_parameters"))) : true], false)) : true
    error_message = "Optional attribute 'request_parameters' of 'api_gateway_methods.api_method' must be an object map."
  }

  // api_method.authorizer_name
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.api_method, "authorizer_name")) ? length(lookup(method.api_method, "authorizer_name")) > 1 : true], false)) : true
    error_message = "Optional attribute 'authorizer_name' of 'api_gateway_methods.api_method' must be a string with length > 1."
  }

  // api_method.integration.integration_http_method
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.integration_http_method) ?
          contains(["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "ANY", "PATCH"], method.api_method.integration.integration_http_method) : # if integration_http_method found... validate it
          true :                                                                                                                                 # Optional - If not specified, the module assumes "POST" for lambda integrations in locals
        true]                                                                                                                                    # integration is not required, so return true
      , false))                                                                                                                                  # index function lookup value
    : true)                                                                                                                                      # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'integration_http_method' must be a string equal to GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY, PATCH."
  }

  // api_method.integration.integration_type
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.integration_type) ?
          contains(["HTTP", "MOCK", "AWS", "AWS_PROXY", "HTTP_PROXY"], method.api_method.integration.integration_type) : # if type found... validate it
          true :                                                                                                         # Optional - If not specified, the module assumes "AWS_PROXY" for lambda integrations in locals
        true]                                                                                                            # integration is not required, so return true
      , false))                                                                                                          # index function lookup value
    : true)                                                                                                              # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.integration' is specified, optional attribute 'integration_type' must be a string equal to HTTP, MOCK, AWS, AWS_PROXY, HTTP_PROXY."
  }

  // api_method.integration.connection_type
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.connection_type) ?
          contains(["INTERNET", "VPC_LINK"], method.api_method.integration.connection_type) : # if type found... validate it
          true :                                                                              # Optional 
        true]                                                                                 # integration is not required, so return true
      , false))                                                                               # index function lookup value
    : true)                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'connection_type' must be a string equal to INTERNET, VPC_LINK."
  }

  // api_method.integration.connection_id
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.connection_id) ?
          can(tostring(method.api_method.integration.connection_id)) && length(method.api_method.integration.connection_id) > 1 : # if type found... validate it
          true :                                                                                                                  # Optional 
        true]                                                                                                                     # integration is not required, so return true
      , false))                                                                                                                   # index function lookup value
    : true)                                                                                                                       # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'connection_id' must be a string with length > 1."
  }

  // api_method.integration.uri
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.integration.uri) ?
          can(tostring(method.api_method.integration.uri)) && length(method.api_method.integration.uri) > 1 : # if type found... validate it
          true :                                                                                              # Optional 
        true]                                                                                                 # integration is not required, so return true
      , false))                                                                                               # index function lookup value
    : true)                                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'uri' must be a string with length > 1."
  }

  // api_method.integration.credentials
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.credentials) ?
          can(tostring(method.api_method.integration.credentials)) && length(method.api_method.integration.credentials) > 1 : # if type found... validate it
          true :                                                                                                              # Optional 
        true]                                                                                                                 # integration is not required, so return true
      , false))                                                                                                               # index function lookup value
    : true)                                                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'credentials' must be a string with length > 1."
  }

  // api_method.integration.request_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.request_parameters) ?
          can(tomap(method.api_method.integration.request_parameters)) && length(method.api_method.integration.request_parameters) >= 1 : # if type found... validate it
          true :                                                                                                                          # Optional 
        true]                                                                                                                             # integration is not required, so return true
      , false))                                                                                                                           # index function lookup value
    : true)                                                                                                                               # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'request_parameters' must be a map with attributes > 1."
  }

  // api_method.integration.request_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.request_templates) ?
          can(tomap(method.api_method.integration.request_templates)) && length(method.api_method.integration.request_templates) >= 1 : # if type found... validate it
          true :                                                                                                                        # Optional 
        true]                                                                                                                           # integration is not required, so return true
      , false))                                                                                                                         # index function lookup value
    : true)                                                                                                                             # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'request_templates' must be a map with attributes > 1."
  }

  // api_method.integration.passthrough_behavior
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.passthrough_behavior) ?
          contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], method.api_method.integration.passthrough_behavior) : # if type found... validate it
          true :                                                                                                          # Optional 
        true]                                                                                                             # integration is not required, so return true
      , false))                                                                                                           # index function lookup value
    : true)                                                                                                               # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'passthrough_behavior' must be a string equal to WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER."
  }

  // api_method.integration.cache_key_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.cache_key_parameters) ?
          can(toset(method.api_method.integration.cache_key_parameters)) && length(method.api_method.integration.cache_key_parameters) >= 1 : # if type found... validate it
          true :                                                                                                                              # Optional 
        true]                                                                                                                                 # integration is not required, so return true
      , false))                                                                                                                               # index function lookup value
    : true)                                                                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'cache_key_parameters' must be a set of string > 1."
  }

  // api_method.integration.cache_namespace
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.cache_namespace) ?
          can(tostring(method.api_method.integration.cache_namespace)) && length(method.api_method.integration.cache_namespace) > 1 : # if type found... validate it
          true :                                                                                                                      # Optional 
        true]                                                                                                                         # integration is not required, so return true
      , false))                                                                                                                       # index function lookup value
    : true)                                                                                                                           # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'cache_namespace' must be a string with length > 1."
  }

  // api_method.integration.content_handling
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.integration.content_handling) ?
          contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], method.api_method.integration.content_handling) : # if type found... validate it
          true :                                                                                               # Optional 
        true]                                                                                                  # integration is not required, so return true
      , false))                                                                                                # index function lookup value
    : true)                                                                                                    # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'content_handling' must be a string equal to CONVERT_TO_BINARY, CONVERT_TO_TEXT."
  }

  // api_method.integration.timeout_milliseconds
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration) ?
          can(method.api_method.integration.timeout_milliseconds) ?
          can(tonumber(method.api_method.integration.timeout_milliseconds)) && method.api_method.integration.timeout_milliseconds >= 50 && method.api_method.integration.timeout_milliseconds <= 29000 : # if type found... validate it
          true :                                                                                                                                                                                         # Optional 
        true]                                                                                                                                                                                            # integration is not required, so return true
      , false))                                                                                                                                                                                          # index function lookup value
    : true)                                                                                                                                                                                              # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration' is specified, optional attribute 'timeout_milliseconds' must be a number >= 50 and <= 29,000."
  }

  // api_method.integration_response.response_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration_response) ?
          can(method.api_method.integration_response.response_parameters) ?
          can(tomap(method.api_method.integration_response.response_parameters)) && length(method.api_method.integration_response.response_parameters) > 0 : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration_response' is specified, optional attribute 'response_parameters' must be a map with attributes > 0."
  }

  // api_method.integration_response.response_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration_response) ?
          can(method.api_method.integration_response.response_templates) ?
          can(tomap(method.api_method.integration_response.response_templates)) && length(method.api_method.integration_response.response_templates) > 0 : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration_response' is specified, optional attribute 'response_templates' must be a map with attributes > 0."
  }

  // api_method.integration_response.response_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.api_method.integration_response) ?
          can(method.api_method.integration_response.content_handling) ?
          contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], method.api_method.integration_response.content_handling) : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.api_method.integration_response' is specified, optional attribute 'content_handling' must be a map with attributes > 0."
  }

  // api_method.response.status_code
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.api_method.response) ?
          can(method.api_method.response.status_code) ?
          can(tostring(method.api_method.response.status_code)) && length(method.api_method.response.status_code) > 1 : # the validation
          true :                                                                                                        # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.api_method.response.status_code' of 'api_gateway_methods' must be a string with length > 1."
  }

  // api_method.response.response_models
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.api_method.response) ?
          can(method.api_method.response.response_models) ?
          can(tomap(method.api_method.response.response_models)) && length(method.api_method.response.response_models) > 0 : # the validation
          true :                                                                                                             # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.api_method.response.response_models' of 'api_gateway_methods' must be a string with length > 1."
  }

  // api_method.response.response_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.api_method.response) ?
          can(method.api_method.response.response_parameters) ?
          can(tomap(method.api_method.response.response_parameters)) && length(method.api_method.response.response_parameters) > 0 : # the validation
          true :                                                                                                                     # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.api_method.response.response_parameters' of 'api_gateway_methods' must be a string with length > 1."
  }

  #######################################
  ## Repeated below for options_method ##
  #######################################
  // options_method.http_method
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(lookup(method.options_method, "http_method")) ?
          contains(["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "ANY"], lookup(method.options_method, "http_method")) : # if can find http_method true
        true]                                                                                                                  # Optional so result should be false - http_method not found
      , false))                                                                                                                # index function lookup value
    : true)                                                                                                                    # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "Optional attribute 'http_method' of 'api_gateway_methods.options_method' must be a string equal to GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY."
  }

  // options_method.authorization     
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.options_method.authorization) ? contains(["NONE", "CUSTOM", "AWS_IAM", "COGNITO_USER_POOLS"], lookup(method.options_method, "authorization")) : true], false)) : true
    error_message = "Optional attribute 'authorization' of 'api_gateway_methods.options_method' must be a string equal to NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS."
  }

  // options_method.authorizer_id
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.options_method.authorizer_id) ? length(lookup(method.options_method, "authorizer_id")) > 1 : true], false)) : true
    error_message = "Optional attribute 'authorizer_id' of 'api_gateway_methods.options_method' must be a string with length > 1."
  }

  // options_method.authorization_scopes
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.options_method.authorization_scopes) ? length(try(toset(method.options_method.authorization_scopes), [])) == 1 : true], false)) : true
    error_message = "Optional attribute 'authorization_scopes' of 'api_gateway_methods.options_method' must be a set of string with length > 1."
  }

  // options_method.api_key_required
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(method.options_method.api_key_required) ? can(tobool(lookup(method.options_method, "api_key_required"))) : true], false)) : true
    error_message = "Optional attribute 'api_key_required' of 'api_gateway_methods.options_method' must be 'true' or 'false'."
  }

  // options_method.request_models
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.options_method, "request_models")) ? can(tomap(lookup(method.options_method, "request_models"))) : true], false)) : true
    error_message = "Optional attribute 'request_models' of 'api_gateway_methods.options_method' must be an object map."
  }

  // options_method.request_validator_id
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.options_method, "request_validator_id")) ? length(lookup(method.options_method, "request_validator_id")) > 1 : true], false)) : true
    error_message = "Optional attribute 'request_validator_id' of 'api_gateway_methods.options_method' must be a string with length > 1."
  }

  // options_method.request_parameters
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.options_method, "request_parameters")) ? can(tomap(lookup(method.options_method, "request_parameters"))) : true], false)) : true
    error_message = "Optional attribute 'request_parameters' of 'api_gateway_methods.options_method' must be an object map."
  }

  // options_method.authorizer_name
  validation {
    condition     = var.api_gateway_methods != [] ? !can(index([for method in var.api_gateway_methods : can(lookup(method.options_method, "authorizer_name")) ? length(lookup(method.options_method, "authorizer_name")) > 1 : true], false)) : true
    error_message = "Optional attribute 'authorizer_name' of 'api_gateway_methods.options_method' must be a string with length > 1."
  }

  // options_method.integration.integration_http_method
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.integration_http_method) ?
          contains(["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS", "ANY", "PATCH"], method.options_method.integration.integration_http_method) : # if integration_http_method found... validate it
          true :                                                                                                                                     # Optional - If not specified, the module assumes "POST" for lambda integrations in locals
        true]                                                                                                                                        # integration is not required, so return true
      , false))                                                                                                                                      # index function lookup value
    : true)                                                                                                                                          # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'integration_http_method' must be a string equal to GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY, PATCH."
  }

  // options_method.integration.integration_type
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.integration_type) ?
          contains(["HTTP", "MOCK", "AWS", "AWS_PROXY", "HTTP_PROXY"], method.options_method.integration.integration_type) : # if type found... validate it
          true :                                                                                                             # Optional - If not specified, the module assumes "AWS_PROXY" for lambda integrations in locals
        true]                                                                                                                # integration is not required, so return true
      , false))                                                                                                              # index function lookup value
    : true)                                                                                                                  # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.integration' is specified, optional attribute 'integration_type' must be a string equal to HTTP, MOCK, AWS, AWS_PROXY, HTTP_PROXY."
  }

  // options_method.integration.connection_type
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.connection_type) ?
          contains(["INTERNET", "VPC_LINK"], method.options_method.integration.connection_type) : # if type found... validate it
          true :                                                                                  # Optional 
        true]                                                                                     # integration is not required, so return true
      , false))                                                                                   # index function lookup value
    : true)                                                                                       # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'connection_type' must be a string equal to INTERNET, VPC_LINK."
  }

  // options_method.integration.connection_id
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.connection_id) ?
          can(tostring(method.options_method.integration.connection_id)) && length(method.options_method.integration.connection_id) > 1 : # if type found... validate it
          true :                                                                                                                          # Optional 
        true]                                                                                                                             # integration is not required, so return true
      , false))                                                                                                                           # index function lookup value
    : true)                                                                                                                               # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'connection_id' must be a string with length > 1."
  }

  // options_method.integration.uri
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.integration.uri) ?
          can(tostring(method.options_method.integration.uri)) && length(method.options_method.integration.uri) > 1 : # if type found... validate it
          true :                                                                                                      # Optional 
        true]                                                                                                         # integration is not required, so return true
      , false))                                                                                                       # index function lookup value
    : true)                                                                                                           # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'uri' must be a string with length > 1."
  }

  // options_method.integration.credentials
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.credentials) ?
          can(tostring(method.options_method.integration.credentials)) && length(method.options_method.integration.credentials) > 1 : # if type found... validate it
          true :                                                                                                                      # Optional 
        true]                                                                                                                         # integration is not required, so return true
      , false))                                                                                                                       # index function lookup value
    : true)                                                                                                                           # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'credentials' must be a string with length > 1."
  }

  // options_method.integration.request_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.request_parameters) ?
          can(tomap(method.options_method.integration.request_parameters)) && length(method.options_method.integration.request_parameters) >= 1 : # if type found... validate it
          true :                                                                                                                                  # Optional 
        true]                                                                                                                                     # integration is not required, so return true
      , false))                                                                                                                                   # index function lookup value
    : true)                                                                                                                                       # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'request_parameters' must be a map with attributes > 1."
  }

  // options_method.integration.request_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.request_templates) ?
          can(tomap(method.options_method.integration.request_templates)) && length(method.options_method.integration.request_templates) >= 1 : # if type found... validate it
          true :                                                                                                                                # Optional 
        true]                                                                                                                                   # integration is not required, so return true
      , false))                                                                                                                                 # index function lookup value
    : true)                                                                                                                                     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'request_templates' must be a map with attributes > 1."
  }

  // options_method.integration.passthrough_behavior
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.passthrough_behavior) ?
          contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], method.options_method.integration.passthrough_behavior) : # if type found... validate it
          true :                                                                                                              # Optional 
        true]                                                                                                                 # integration is not required, so return true
      , false))                                                                                                               # index function lookup value
    : true)                                                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'passthrough_behavior' must be a string equal to WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER."
  }

  // options_method.integration.cache_key_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.cache_key_parameters) ?
          can(toset(method.options_method.integration.cache_key_parameters)) && length(method.options_method.integration.cache_key_parameters) >= 1 : # if type found... validate it
          true :                                                                                                                                      # Optional 
        true]                                                                                                                                         # integration is not required, so return true
      , false))                                                                                                                                       # index function lookup value
    : true)                                                                                                                                           # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'cache_key_parameters' must be a set of string > 1."
  }

  // options_method.integration.cache_namespace
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.cache_namespace) ?
          can(tostring(method.options_method.integration.cache_namespace)) && length(method.options_method.integration.cache_namespace) > 1 : # if type found... validate it
          true :                                                                                                                              # Optional 
        true]                                                                                                                                 # integration is not required, so return true
      , false))                                                                                                                               # index function lookup value
    : true)                                                                                                                                   # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'cache_namespace' must be a string with length > 1."
  }

  // options_method.integration.content_handling
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.integration.content_handling) ?
          contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], method.options_method.integration.content_handling) : # if type found... validate it
          true :                                                                                                   # Optional 
        true]                                                                                                      # integration is not required, so return true
      , false))                                                                                                    # index function lookup value
    : true)                                                                                                        # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'content_handling' must be a string equal to CONVERT_TO_BINARY, CONVERT_TO_TEXT."
  }

  // options_method.integration.timeout_milliseconds
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration) ?
          can(method.options_method.integration.timeout_milliseconds) ?
          can(tonumber(method.options_method.integration.timeout_milliseconds)) && method.options_method.integration.timeout_milliseconds >= 50 && method.options_method.integration.timeout_milliseconds <= 29000 : # if type found... validate it
          true :                                                                                                                                                                                                     # Optional 
        true]                                                                                                                                                                                                        # integration is not required, so return true
      , false))                                                                                                                                                                                                      # index function lookup value
    : true)                                                                                                                                                                                                          # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration' is specified, optional attribute 'timeout_milliseconds' must be a number >= 50 and <= 29,000."
  }

  // options_method.integration_response.response_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration_response) ?
          can(method.options_method.integration_response.response_parameters) ?
          can(tomap(method.options_method.integration_response.response_parameters)) && length(method.options_method.integration_response.response_parameters) > 0 : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration_response' is specified, optional attribute 'response_parameters' must be a map with attributes > 0."
  }

  // options_method.integration_response.response_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration_response) ?
          can(method.options_method.integration_response.response_templates) ?
          can(tomap(method.options_method.integration_response.response_templates)) && length(method.options_method.integration_response.response_templates) > 0 : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration_response' is specified, optional attribute 'response_templates' must be a map with attributes > 0."
  }

  // options_method.integration_response.response_templates
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        # build an array of true/false values describing if the validation is passed for each record...  if 'false' found via the index function, return false
        [for method in var.api_gateway_methods : can(method.options_method.integration_response) ?
          can(method.options_method.integration_response.content_handling) ?
          contains(["CONVERT_TO_BINARY", "CONVERT_TO_TEXT"], method.options_method.integration_response.content_handling) : # if type found... validate it
          true
        : true] # integration_responses are not required, so return true
      , false)) # did any falses return in the outer list?
    : true)     # if var.api_gateway_methods == [] it wasn't passed at all.  Since this is optional, pass validation
    error_message = "If 'api_gateway_methods.options_method.integration_response' is specified, optional attribute 'content_handling' must be a map with attributes > 0."
  }

  // options_method.response.status_code
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.options_method.response) ?
          can(method.options_method.response.status_code) ?
          can(tostring(method.options_method.response.status_code)) && length(method.options_method.response.status_code) > 1 : # the validation
          true :                                                                                                                # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.options_method.response.status_code' of 'api_gateway_methods' must be a string with length > 1."
  }

  // options_method.response.response_models
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.options_method.response) ?
          can(method.options_method.response.response_models) ?
          can(tomap(method.options_method.response.response_models)) && length(method.options_method.response.response_models) > 0 : # the validation
          true :                                                                                                                     # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.options_method.response.response_models' of 'api_gateway_methods' must be a string with length > 1."
  }

  // options_method.response.response_parameters
  validation {
    condition = (var.api_gateway_methods != [] ?
      !can(index(
        [for method in var.api_gateway_methods : can(method.options_method.response) ?
          can(method.options_method.response.response_parameters) ?
          can(tomap(method.options_method.response.response_parameters)) && length(method.options_method.response.response_parameters) > 0 : # the validation
          true :                                                                                                                             # did any falses return in the list?
        true]
      , false)) :
    true)
    error_message = "Optional attribute 'method.options_method.response.response_parameters' of 'api_gateway_methods' must be a string with length > 1."
  }
}

variable "cors_origin_domain" {
  type        = string
  description = "The domain of the site that is calling this api.  e.g. https://bitlocker.pgcloud.com"
  default     = ""
}
