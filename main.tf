
##################################################################################################
## Modules
##################################################################################################

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.0.5"

  cluster_name = "cluster-test-notifications"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/cluster-test-notifications"
      }
    }
  }

  cluster_setting = [
    {
      "name" : "containerInsights",
      "value" : "enabled"
    }
  ]
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 10
    }
    FARGATE_SPOT = {
      weight = 90
    }
  }
}

module "test_task_definition_false" {
  source = "github.com/mongodb/terraform-aws-ecs-task-definition"

  family                   = "call-to-fail"
  image                    = "alpine:3.21.3"
  memory                   = 512
  name                     = "alpine"
  command                  = ["false"]
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
}

##################################################################################################

module "test_task_definition_true" {
  source = "github.com/mongodb/terraform-aws-ecs-task-definition"

  family                   = "call-to-success"
  image                    = "alpine:3.21.3"
  memory                   = 512
  name                     = "alpine"
  command                  = ["true"]
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
}

##################################################################################################

module "test-step-functions" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = "5.0.1"

  name = "test-notifications"

  type    = "STANDARD"
  publish = true

  create_role = true

  definition = local.test_state_machine_definition

  service_integrations = {
    ecs_Sync = {
      ecs = [
        module.test_task_definition_false.arn,
        module.test_task_definition_true.arn
      ]

      events = true
    }
    sns = {
      sns = [
        var.sns_topic_arn
      ]
    }
  }

  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }

  cloudwatch_log_group_retention_in_days = 30
}
