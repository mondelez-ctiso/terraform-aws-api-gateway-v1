<h1 align="center">
    terraform-aws-api-gateway-v1
</h1>

<p align="center" style="font-size: 1.2rem;"> 
    Terraform module to create an AWS API Gateway V1 and related objects.
</p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.1.0-green" alt="Terraform">
</a>

</p>

## Prerequisites

This module has the following dependencies: 

- [Terraform 1.1.0](https://learn.hashicorp.com/terraform/getting-started/install.html)
- Hashicorp AWS Provider ~> 4.0

## Limitations/TODOs

- Currently this module only supports resource paths nested 5 levels deep, e.g. "endpoint/one/two/three/four/five".  Adding additional levels is trivial if the use case ever arises.  Stopping at 5 for now to keep the code more concise.
- Terraform 0.14 introduced functions 'alltrue' and 'anytrue' functions which will be able to replace the 'index' calls in the validations.  This will make that section much easier to follow.  In addition, the experiment 'module_variable_optional_attrs' may allow us to type the complex variable objects which as of now are only type 'any'.  Terraform 0.15 will further enhance the 'module_variable_optional_attrs' experiment as follows:
    > EXPERIMENTS:
    > 
    > Continuing the module_variable_optional_attrs experiment started in v0.14.0, there is now an experimental defaults function intended for use with it, to allow for concisely defining and merging in default values for any unset optional attributes in a deep data structure. The function is callable only  when the module_variable_optional_attrs experiment is available, because it's intended for use only with incoming variable values that might have certain attributes unset.

## Examples

Here are some examples of how you can use this module in your inventory structure:
### Basic Example
```hcl
  module "api_gateway" {
    source  = "spacelift.io/mondelez-ctiso/terraform-aws-api-gateway-v1/aws"
    version = "1.0.0"
    
    providers = { aws = aws }

    api_gateway = {
      name = "api-gateway"
    }

    // look for "api_gateway_methods complete example" below for complete data structure
    api_gateway_methods = [
      {
        resource_path   = "myPath"
        api_method = {
          integration = {
            uri = "<valid_lambda_function_invoke_arn>"
          }
        }
      }
    ]

    tags = var.tags
  }
```

### Basic Example with Lambda Authorizers and a Custom Domain
```hcl
  ###################
  # API Gateway
  ###################
  module "api_gateway" {
    source  = "spacelift.io/mondelez-ctiso/terraform-aws-api-gateway-v1/aws"
    version = "1.0.0"
    
    providers = { aws = aws }

    tags = var.tags

    cors_origin_domain = var.cors_origin_domain

    api_gateway = {
      name                                = "my-api-gateway-name"
      hosted_zone_id                      = data.aws_ssm_parameter.hosted_zone.value
      custom_domain                       = "api.${var.domain}"
      acm_cert_arn                        = module.acm_cert.arn
      base_path_mapping_active_stage_name = var.spacelift_stack_branch
    }

    api_gateway_stages = [
      {
        stage_name        = var.spacelift_stack_branch
        stage_description = "The stage defined for ${var.spacelift_stack_branch}, tied to the default deployment."
      },
    ]

    authorizer_definitions = [
      {
        authorizer_name = "pingFedAuth"
        authorizer_uri  = module.ping_authorizer.this_lambda_function_invoke_arn
      }
    ]

    // look for "api_gateway_methods complete example" below for complete data structure
    api_gateway_methods = [
      {
        resource_path = "getSomethingGreat"
        api_method = {
          authorizer_name = "pingFedAuth"

          integration = {
            uri = module.app_lambda.this_lambda_function_invoke_arn
          }
        }
      }
    ]

    depends_on = [module.acm_cert]
  }
```

### Example creating the app lambda from source, a lambda authorizer from source, custom gateway responses, a custom certificate, a custom domain, and api gateway
```hcl
  ##############################
  # Custom Domain Certificate ##
  ##############################
  module "acm_cert" {
    source  = "terraform-aws-modules/acm/aws"
    version = "~> 3.0"

    providers      = { aws = aws }
    domain         = "api.${var.domain}"
    hosted_zone_id = data.aws_ssm_parameter.hosted_zone.value
    tags           = var.tags
  }

  ###################
  # API Gateway
  ###################
  module "api_gateway" {
    source  = "spacelift.io/mondelez-ctiso/terraform-aws-api-gateway-v1/aws"
    version = "1.0.0"
    
    providers = { aws = aws }

    tags = var.tags

    cors_origin_domain = var.cors_origin_domain

    api_gateway = {
      name                                = "my-api-gateway-name"
      hosted_zone_id                      = data.aws_ssm_parameter.hosted_zone.value
      custom_domain                       = "api.${var.domain}"
      acm_cert_arn                        = module.acm_cert.arn
      base_path_mapping_active_stage_name = var.spacelift_stack_branch
    }

    api_gateway_stages = [
      {
        stage_name        = var.spacelift_stack_branch
        stage_description = "The stage defined for ${var.spacelift_stack_branch}, tied to the default deployment."
      },
    ]

    authorizer_definitions = [
      {
        authorizer_name = "pingFedAuth"
        authorizer_uri  = module.ping_authorizer.this_lambda_function_invoke_arn
      }
    ]

    // look for "api_gateway_methods complete example" below for complete data structure
    api_gateway_methods = [
      {
        resource_path = "getSomethingGreat"
        api_method = {
          authorizer_name = "pingFedAuth"

          integration = {
            uri = module.app_lambda.this_lambda_function_invoke_arn
          }
        }
      }
    ]

    depends_on = [module.acm_cert]
  }

  # module "" 
  module "lambda_security_group" {
    source  = "terraform-aws-modules/security-group/aws"
    version = "~> 3.0"

    name        = "lambda-sg"
    description = "Lambda security group for something great"
    vpc_id      = module.aws_values.vpc.id

    # Does your lambda require any egress at all for an API call itself?
    egress_rules = ["https-443-tcp", "dns-tcp", "dns-udp"]

    tags = var.tags
  }

  #############################################
  # Build and Deploy Lambda module
  #############################################
  module "app_lambda" {
    source  = "terraform-aws-modules/lambda/aws"
    version = "3.3.1"

    function_name = "get-something-lambda"
    description   = "Lambda function to get something."
    handler       = "index.lambda_handler"
    runtime       = "python3.8"

    tags = var.tags

    publish = var.publish_lambdas

    create_package = true

    source_path = "${path.module}/../api_backend/python_lambdas"

    attach_network_policy = true
    vpc_subnet_ids        = ["subnet-id"]
    vpc_security_group_ids = [module.lambda_security_group.this_security_group_id]

    kms_key_arn = module.kms.arn 

    environment_variables = {
      ORIGIN = var.cors_origin_domain
    }
    
    ######################
    # Additional policies
    ######################

    attach_policy_json = true
    policy_json = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret",
              "secretsmanager:ListSecretVersionIds"
            ],
            "Resource" : [module.secret.arn] 
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "kms:Decrypt",
              "kms:DescribeKey",
            ],
            "Resource" : [module.kms.arn] 
          }
        ]
    })

    allowed_triggers = {
      AllowExecutionFromAPIGateway = {
        service = "apigateway"
        arn     = module.api_gateway.execution_arn
      }
    }
  }

  module "ping_authorizer" {
    source  = "terraform-aws-modules/lambda/aws"
    version = "3.3.1"
    
    function_name = "authorizer"
    description   = "Ping Federate authorizer for this app."
    handler       = "auth.lambda_handler"
    runtime       = "nodejs12.x"
    tags          = var.tags

    publish = var.publish_lambdas

    create_package = true

    source_path = [
      {
        path = "${path.module}/../api_backend/node_js_lambdas"
        commands = [
          "npm install",
          ":zip .",
        ]
        patterns = [
          "!.*/.*\\.txt",    # Skip all txt files recursively
          "node_modules/.+", # Include all node_modules
        ]
      }
    ]

    kms_key_arn = module.kms.arn 

    environment_variables = {
      PingClientID    = data.aws_ssm_parameter.ping_client_id.value
      Domain          = data.aws_ssm_parameter.ping_instance.value
      GroupAttributes = "{\"isAdmin\": \"SOME_AD_GROUP_NAME\"}"
      COOKIE_AUTH     = true
    }

    ######################
    # Additional policies
    ######################

    attach_policy_json = true
    policy_json = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "kms:Decrypt",
              "kms:DescribeKey",
            ],
            "Resource" : [module.kms.arn] 
          }
        ]
    })

    allowed_triggers = {
      AllowExecutionFromAPIGateway = {
        service = "apigateway"
        arn     = module.api_gateway.execution_arn
      }
    }
  }
```

## Inputs

This module has been implemented to allow the caller to specify as little as possible, and have any other required attributes filled in with sane defaults.  There are opinionated defaults in this module, but every setting can be set by the end user to override the default behavior.

Note:  If you choose to provide the optional objects below, you will have to reference the section below called "Detailed Input Structures" to find which attributes are required for the object.

| Name | Description | Type | Required | Default |
|------|-------------|------|---------|:--------:|
| cors_origin_domain | Providing this value will add the CORS origin to the Options Method Response | `string` | no | `""` |
| tags | Tags to be applied to the resource | `map(string)` | no | `{}` |
| api_gateway | AWS API Gateway Settings | `object` | yes | `{}` |
| api_gateway_stages | AWS API Gateway Stages | `set(object)` | no | `[]` |
| api_gateway_models | AWS API Gateway Models | `set(object)` | no | `[]` |
| api_keys | AWS API Keys | `set(any)` | no | `[]` |
| vpc_links | AWS API Gateway VPC Links | `set(object)` | no | `[]` |
| authorizer_definitions | AWS API Gateway Authorizers | `set(object)` | no | `[]` |
| api_gateway_methods | AWS API Gateway Methods | `set(object)` | no | `[]` |
| api_gateway_responses | AWS API Gateway Gateway Responses | `set(object)` | no | `[]` |
## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the REST API. |
| execution_arn | The Execution ARN of the REST API. | 

<hr>

## Detailed Input Data Structures

### Variable: api_gateway
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| name | Name of the REST API | `string` | yes | `null` |
| api_key_source | The source of the API key for requests. Valid values are HEADER (default) and AUTHORIZER. | `string` | no | `null` |
| binary_media_types | The set of binary media types supported by the RestApi. By default, the RestApi supports only UTF-8-encoded text payloads. | `set(string)` | no | `null` |
| description | The description of the REST API. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| endpoint_configuration types | This resource currently only supports managing a single value. Valid values: EDGE, REGIONAL or PRIVATE | `set(string)` | no | `null` |
| endpoint_configuration vpc_endpoint_ids | A list of VPC Endpoint Ids. | `list(string)` | no | `null` |
| minimum_compression_size | Minimum response size to compress for the REST API. Integer between -1 and 10485760 (10MB). Setting a value greater than -1 will enable compression, -1 disables compression (default). | `number` | no | `null` |
| custom_domain | The custom domain to associate to this REST API. | `string` | no | `null` |
| acm_cert_arn | The AWS ACM Certificate arn to associate to this REST API custom domain. | `string` | no | `null` |
| default_deployment_name | Name of the deployment. | `string` | yes | `null` |
| default_deployment_description | The description of the deployment. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| default_deployment_variables | A map that defines variables for the deployment. | `object` | no | `null` |
| client_cert_enabled | Whether or not to generate a client certificate for this REST API. | `string` | no | `false` |
| client_cert_description | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git | `string` | no | `null` |
| policy | The IAM Policy applied to the REST API. | `string` | no | `null` |

### Variable: api_gateway_stage
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| stage_name | The name of the stage. If the specified stage already exists, it will be updated to point to the new deployment. If the stage does not exist, a new one will be created and point to this deployment. | `string` | yes | `null` |
| stage_description | The description of the stage. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| stage_variables | A map that defines variables for the stage. | `object` | no | `null` |
| cache_cluster_enabled | Specifies whether a cache cluster is enabled for the stage. | `bool` | no | `false` |
| cache_cluster_size | The size of the cache cluster for the stage, if enabled. Allowed values include 0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118 and 237. | `number` | no | `null` |
| client_certificate_id | The identifier of a client certificate for the stage. | `string` | no | `null` |
| documentation_version | The version of the associated API documentation. | `string` | no | `null` |
| xray_tracing_enabled | Specifies whether to enable xray_tracing. | `bool` | no | `false` |
| waf_id | The WAF to associate to this stage. | `string` | no | `null` |
| access_log_settings destination_arn | ARN of the log group to send the logs to. Automatically removes trailing :* if present. | `string` | no | `null` |
| access_log_settings format | The formatting and values recorded in the logs. | `string` | no | `null` |

### Variable: api_gateway_models
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| name | The name of the model. | `string` | yes | `null` |
| description | The description of the model. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| content_type | The content_type of the model. | `string` | no | "application/json" |
| schema | The schea of the model. | `string` | no | "{\"type\":\"object\"}" |

### Variable: api_keys
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| key_name | The name of the API key. | `string` | yes | `null` |
| key_description | The description of the API key. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| enabled | Whether the API Key is enabled. | `bool` | no | true |
| value | The value of the key (if not auto generated) | `string` | no | `null` |

### Variable: vpc_links
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| vpc_link_name | The name used to label and identify the VPC link. | `string` | yes | `null` |
| vpc_link_description | The description of the VPC link. | `string` | no | Managed by the P&G AWS API Gateway Terraform Module https://github.com/procter-gamble/terraform-module-aws-api-gateway.git |
| target_arns | The list of network load balancer arns in the VPC targeted by the VPC link. Currently AWS only supports 1 target. | `set(string)` | no | `null` |

### Variable: authorizer_definitions
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| authorizer_name | The name of the authorizer. | `string` | yes | `null` |
| authorizer_uri | The authorizer's Uniform Resource Identifier (URI). This must be a well-formed Lambda function URI in the form of arn:aws:apigateway:{region}:lambda:path/{service_api}, e.g. arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/. | `string` | yes | `null` |
| identity_source | The source of the identity in an incoming request. | `string` | no | "method.request.header.Authorization" |
| identity_validation_expression | A validation expression for the incoming identity. For TOKEN type, this value should be a regular expression. The incoming token from the client is matched against this expression, and will proceed if the token matches. If the token doesn't match, the client receives a 401 Unauthorized response. | `string` | no | `null` |
| authorizer_result_ttl_in_seconds | The TTL of cached authorizer results in seconds. | `number` | no | 0 |
| authorizer_type | The type of the authorizer. Possible values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, or COGNITO_USER_POOLS for using an Amazon Cognito user pool. Defaults to TOKEN. | `string` | no | "TOKEN" |
| authorizer_credentials | The credentials required for the authorizer. To specify an IAM Role for API Gateway to assume, use the IAM Role ARN. | `string` | no | `null` |
| provider_arns | Required for type COGNITO_USER_POOLS) A list of the Amazon Cognito user pool ARNs. Each element is of this format: arn:aws:cognito-idp:{region}:{account_id}:userpool/{user_pool_id}. | `set(string)` | no | `null` |

## Variable: api_gateway_responses most basic use is not defining it. This will initialize DEFAULT_4XX and DEFAULT_5XX to work with CORS headers. 

## Variable: api_gateway_responses complete example with everything you can specify (with defaults specified). Provided values will override all defaults.
````hcl
    api_gateway_responses = [ 
      {
        response_type = "UNAUTHORIZED"
        response_parameters = {
          "gatewayresponse.header.Access-Control-Allow-Headers"  = "'${var.domain}'"
        }
        status_code   = 402
        response_templates = {
          "application/json" = "{ \"statusCode\": 400 }"
        }
      },
      ... another gateway response 
    ]
````

### Variable: api_gateway_responses
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| response_type | The name of the response type. | `string` | yes | `null` |
| response_parameters | List of response parameters. | `set(string)` | no | `{}` |
| status_code | Value for the status code. | `number` | no | `null` |
| response_templates | A map of the integration's response templates. | `object` | no | `{}` |

## Variable: api_gateway_methods most basic example (the defaults will fill out the other required values, including the options method settings.  See below to override any of them.)
````hcl
  api_gateway_methods = [
    {
      resource_path = "getBitlockerKey"
      api_method = {
        authorizer_name = "pingFedAuth"

        integration = {
          uri = module.app_lambda.this_lambda_function_invoke_arn
        }
      }
    }
  ]
````

## Variable: api_gateway_methods complete example with everything you can specify (with defaults specified).  Provided values will override all defaults.
````hcl
    api_gateway_methods = [
      {
        resource_path = "method1"
        api_method = {
          http_method          = "GET"
          api_key_required     = false
          request_models       = null
          request_validator_id = null
          request_parameters   = {}
          authorization        = "CUSTOM"
          authorizer_id        = null
          authorizer_name      = null
          authorization_scopes = null

          integration = {
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

          integration_response = {
            status_code       = "200"
            selection_pattern = null
            response_template = null
            response_parameters = {
            }
            content_handling = null # Null == Passthrough
          }

          response = {
            status_code   = "200"
            response_type = null
            response_models = {
              "application/json" = "Empty"
            }

            response_template = null
            response_parameters = {
              "method.response.header.Access-Control-Allow-Credentials" = true
              "method.response.header.Access-Control-Allow-Origin"      = true
              "method.response.header.Access-Control-Allow-Headers"     = true
              "method.response.header.Access-Control-Allow-Methods"     = true
            }
          }
        }
        options_method = {
          http_method          = "OPTIONS"
          api_key_required     = false
          request_models       = null
          request_validator_id = null
          request_parameters   = {}
          authorization        = "NONE"
          authorizer_id        = null
          authorizer_name      = null
          authorization_scopes = null

          integration = {
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

          integration_response = {
            status_code       = "200"
            selection_pattern = null
            response_template = null
            response_parameters = {
            }
            content_handling = null # Null == Passthrough
          }

          response = {
            status_code   = "200"
            response_type = null
            response_models = {
              "application/json" = "Empty"
            }

            response_template = null
            response_parameters = {
              "method.response.header.Access-Control-Allow-Credentials" = true
              "method.response.header.Access-Control-Allow-Origin"      = true
              "method.response.header.Access-Control-Allow-Headers"     = true
              "method.response.header.Access-Control-Allow-Methods"     = true
            }
          }
        }
      },
      ... another method
    }
  ]
````
### Variable: api_gateway_methods
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| resource_path | The resource path.  It can be up to 5 levels deep, and must not start with a '/'.  e.g. "path1/path2/path3/path4/path5" is ok. | `string` | yes | `null` |
| api_method | The settings for the method call. | `map` | yes | defaults below |
| options_method | The settings for the method options call. | `map` | no | defaults below |

### Variable: api_gateway_methods.api_method
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| http_method | The HTTP Method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY). | `string` | no | "POST" |
| authorizer_id | The authorizer id to be used when the authorization is CUSTOM or COGNITO_USER_POOLS. | `string` | no | `null` |
| authorization_scopes | The authorization scopes used when the authorization is COGNITO_USER_POOLS. | `string` | no | `null` |
| api_key_required | Specify if the method requires an API key. | `bool` | no | `false` |
| request_models | A map of the API models used for the request's content type where key is the content type (e.g. application/json) and value is either Error, Empty (built-in models) or aws_api_gateway_model's name. | `map` | no | `null` |
| request_validator_id | The ID of a aws_api_gateway_request_validator. | `string` | no | `null` |
| request_parameters | A map of request query string parameters and headers that should be passed to the integration. For example: request_parameters = {\"method.request.header.X-Some-Header\" = true \"method.request.querystring.some-query-param\" = true} would define that the header X-Some-Header and the query string some-query-param must be provided in the request. | `object` | no | `null` |
| authorization | The type of authorization used for the method (NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS). | `string` | no | "CUSTOM" |
| authorizer_id | The authorizer's Uniform Resource Identifier (URI). This must be a well-formed Lambda function URI in the form of arn:aws:apigateway:{region}:lambda:path/{service_api}, e.g. arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/. | `string` | no | `null` |
| authorizer_name | (Optional if not providing authorizer_uri).  The authorizer name that is being created as a part of this module in the authorizer definition. | `string` | no | `null` |
| authorization_scopes | The authorization scopes used when the authorization is COGNITO_USER_POOLS. | `set(string)` | no | `null` |
| integration | The settings for the method integration. | `map` | no | defaults below |
| integration_response | The settings for the method integration_response. | `map` | no | defaults below |
| response | The settings for the method response. | `map` | no | defaults below |

### Variable: api_gateway_methods.api_method.integration
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| integration_http_method |  | `string` | no | "POST" |
| type | The integration input's type. Valid values are HTTP (for HTTP backends), MOCK (not calling any real backend), AWS (for AWS services), AWS_PROXY (for Lambda proxy integration) and HTTP_PROXY (for HTTP proxy integration). An HTTP or HTTP_PROXY integration with a connection_type of VPC_LINK is referred to as a private integration and uses a VpcLink to connect API Gateway to a network load balancer of a VPC. | `string` | no | "AWS_PROXY" |
| connection_type | The integration input's connectionType. Valid values are INTERNET (default for connections through the public routable internet), and VPC_LINK (for private connections between API Gateway and a network load balancer in a VPC). | `string` | no | "INTERNET" |
| connection_id | The id of the VpcLink used for the integration. Required if connection_type is VPC_LINK. | `string` | no | `null` |
| uri | The input's URI. Required if type is AWS, AWS_PROXY, HTTP or HTTP_PROXY. For HTTP integrations, the URI must be a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification . For AWS integrations, the URI should be of the form arn:aws:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}. region, subdomain and service are used to determine the right endpoint. e.g. arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-west-1:012345678901:function:my-func/invocations. For private integrations, the URI parameter is not used for routing requests to your endpoint, but is used for setting the Host header and for certificate validation. | `string` | no | `null` |
| credentials | The credentials required for the integration. For AWS integrations, 2 options are available. To specify an IAM Role for Amazon API Gateway to assume, use the role's ARN. To require that the caller's identity be passed through from the request, specify the string arn:aws:iam::\*:user/\*. | `string` | no | `null` |
| request_templates | A map of the integration's request templates. | `object` | no | `null` |
| request_parameters | A map of request query string parameters and headers that should be passed to the backend responder. For example: request_parameters = { "integration.request.header.X-Some-Other-Header" = "method.request.header.X-Some-Header" } | `object` | no | `null` |
| passthrough_behavior | The integration passthrough behavior (WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER). Required if request_templates is used. | `string` | no | `null` |
| cache_key_parameters |  | `object` | no | `null` |
| cache_namespace | The integration's cache namespace. | `string` | no | `null` |
| content_handling | Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT. If this property is not defined, the request payload will be passed through from the method request to integration request without modification, provided that the passthroughBehaviors is configured to support payload pass-through. | `string` | no | `null` |
| timeout_milliseconds | Custom timeout between 50 and 29,000 milliseconds. The default value is 29,000 milliseconds. | `number` | no | 29000 |

### Variable: api_gateway_methods.api_method.integration_response
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| status_code | The HTTP status code | `string` | no | "200 |
| selection_pattern | Specifies the regular expression pattern used to choose an integration response based on the response from the backend. Setting this to - makes the integration the default one. If the backend is an AWS Lambda function, the AWS Lambda function error header is matched. For all other HTTP and AWS backends, the HTTP status code is matched. | `string` | no | `null` |
| response_templates | A map specifying the templates used to transform the integration response body. | `object` | no | `null` |
| response_parameters | A map of response parameters that can be read from the backend response. For example: response_parameters = { "method.response.header.X-Some-Header" = "integration.response.header.X-Some-Other-Header" } | `object` | no | `null` |
| content_handling | Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT. If this property is not defined, the response payload will be passed through from the integration response to the method response without modification. | `string` | no | `null` |

### Variable: api_gateway_methods.api_method.response
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| status_code | The HTTP status code of the Gateway Response. | `string` | no | "200" |
| response_type | The response type of the associated GatewayResponse. | `string` | no | `null` |
| response_models | A map of the API models used for the response's content type. | `object` | no | `null` |
| response_template | A map specifying the templates used to transform the response body. | `string` | no | `null` |
| response_parameters | A map specifying the parameters (paths, query strings and headers) of the Gateway Response. | `object` | no | `null` |

### Variable: api_gateway_methods.options_method
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| http_method | The HTTP Method (GET, POST, PUT, DELETE, HEAD, OPTIONS, ANY). | `string` | no | "OPTIONS" |
| authorizer_id | The authorizer id to be used when the authorization is CUSTOM or COGNITO_USER_POOLS. | `string` | no | `null` |
| authorization_scopes | The authorization scopes used when the authorization is COGNITO_USER_POOLS. | `string` | no | `null` |
| api_key_required | Specify if the method requires an API key. | `bool` | no | `false` |
| request_models | A map of the API models used for the request's content type where key is the content type (e.g. application/json) and value is either Error, Empty (built-in models) or aws_api_gateway_model's name. | `map` | no | `null` |
| request_validator_id | The ID of a aws_api_gateway_request_validator. | `string` | no | `null` |
| request_parameters | A map of request query string parameters and headers that should be passed to the integration. For example: request_parameters = {\"method.request.header.X-Some-Header\" = true \"method.request.querystring.some-query-param\" = true} would define that the header X-Some-Header and the query string some-query-param must be provided in the request. | `object` | no | `null` |
| authorization | The type of authorization used for the method (NONE, CUSTOM, AWS_IAM, COGNITO_USER_POOLS). | `string` | no | "NONE" |
| authorizer_id | The authorizer's Uniform Resource Identifier (URI). This must be a well-formed Lambda function URI in the form of arn:aws:apigateway:{region}:lambda:path/{service_api}, e.g. arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/. | `string` | no | `null` |
| authorizer_name | (Optional if not providing authorizer_uri).  The authorizer name that is being created as a part of this module in the authorizer definition. | `string` | no | `null` |
| authorization_scopes | The authorization scopes used when the authorization is COGNITO_USER_POOLS. | `set(string)` | no | `null` |
| integration | The settings for the method integration. | `map` | no | defaults below |
| integration_response | The settings for the method integration_response. | `map` | no | defaults below |
| response | The settings for the method response. | `map` | no | defaults below |

### Variable: api_gateway_methods.options_method.integration
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| integration_http_method |  | `string` | no | "POST" |
| type | The integration input's type. Valid values are HTTP (for HTTP backends), MOCK (not calling any real backend), AWS (for AWS services), AWS_PROXY (for Lambda proxy integration) and HTTP_PROXY (for HTTP proxy integration). An HTTP or HTTP_PROXY integration with a connection_type of VPC_LINK is referred to as a private integration and uses a VpcLink to connect API Gateway to a network load balancer of a VPC. | `string` | no | "AWS_PROXY" |
| connection_type | The integration input's connectionType. Valid values are INTERNET (default for connections through the public routable internet), and VPC_LINK (for private connections between API Gateway and a network load balancer in a VPC). | `string` | no | "INTERNET" |
| connection_id | The id of the VpcLink used for the integration. Required if connection_type is VPC_LINK. | `string` | no | `null` |
| uri | The input's URI. Required if type is AWS, AWS_PROXY, HTTP or HTTP_PROXY. For HTTP integrations, the URI must be a fully formed, encoded HTTP(S) URL according to the RFC-3986 specification . For AWS integrations, the URI should be of the form arn:aws:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}. region, subdomain and service are used to determine the right endpoint. e.g. arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-west-1:012345678901:function:my-func/invocations. For private integrations, the URI parameter is not used for routing requests to your endpoint, but is used for setting the Host header and for certificate validation. | `string` | no | `null` |
| credentials | The credentials required for the integration. For AWS integrations, 2 options are available. To specify an IAM Role for Amazon API Gateway to assume, use the role's ARN. To require that the caller's identity be passed through from the request, specify the string arn:aws:iam::\*:user/\*. | `string` | no | `null` |
| request_templates | A map of the integration's request templates. | `object` | no | `null` |
| request_parameters | A map of request query string parameters and headers that should be passed to the backend responder. For example: request_parameters = { "integration.request.header.X-Some-Other-Header" = "method.request.header.X-Some-Header" } | `object` | no | `null` |
| passthrough_behavior | The integration passthrough behavior (WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER). Required if request_templates is used. | `string` | no | `null` |
| cache_key_parameters |  | `object` | no | `null` |
| cache_namespace | The integration's cache namespace. | `string` | no | `null` |
| content_handling | Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT. If this property is not defined, the request payload will be passed through from the method request to integration request without modification, provided that the passthroughBehaviors is configured to support payload pass-through. | `string` | no | `null` |
| timeout_milliseconds | Custom timeout between 50 and 29,000 milliseconds. The default value is 29,000 milliseconds. | `number` | no | 29000 |

### Variable: api_gateway_methods.options_method.integration_response
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| status_code | The HTTP status code | `string` | no | "200 |
| selection_pattern | Specifies the regular expression pattern used to choose an integration response based on the response from the backend. Setting this to - makes the integration the default one. If the backend is an AWS Lambda function, the AWS Lambda function error header is matched. For all other HTTP and AWS backends, the HTTP status code is matched. | `string` | no | `null` |
| response_templates | A map specifying the templates used to transform the integration response body. | `object` | no | `null` |
| response_parameters | A map of response parameters that can be read from the backend response. For example: response_parameters = { "method.response.header.X-Some-Header" = "integration.response.header.X-Some-Other-Header" } | `object` | no | `null` |
| content_handling | Specifies how to handle request payload content type conversions. Supported values are CONVERT_TO_BINARY and CONVERT_TO_TEXT. If this property is not defined, the response payload will be passed through from the integration response to the method response without modification. | `string` | no | `null` |

### Variable: api_gateway_methods.options_method.response
| Name | Description | Type | Required  | Default|
|------|-------------|------|---------|:--------:|
| status_code | The HTTP status code of the Gateway Response. | `string` | no | "200" |
| response_type | The response type of the associated GatewayResponse. | `string` | no | `null` |
| response_models | A map of the API models used for the response's content type. | `object` | no | `null` |
| response_template | A map specifying the templates used to transform the response body. | `string` | no | `null` |
| response_parameters | A map specifying the parameters (paths, query strings and headers) of the Gateway Response. | `object` | no | `null` |
