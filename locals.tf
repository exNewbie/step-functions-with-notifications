##################################################################################################
## Local Variables
##################################################################################################

locals {
  test_state_machine_definition = jsonencode({
    Comment = "Intentionally failing Step Function to test notifications"
    StartAt = "Prepare"
    States = {
      # State Prepare
      Prepare = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = module.ecs_cluster.cluster_arn
          TaskDefinition = module.test_task_definition_false.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = data.aws_subnets.private_subnets.ids
              SecurityGroups = [data.aws_security_group.default.id]
              AssignPublicIp = "DISABLED"
            }
          }
        }
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ParseErrorCause"
          }
        ]
        Next = "Seed"
      }

      # State Seed
      Seed = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = module.ecs_cluster.cluster_arn
          TaskDefinition = module.test_task_definition_true.arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = data.aws_subnets.private_subnets.ids
              SecurityGroups = [data.aws_security_group.default.id]
              AssignPublicIp = "DISABLED"
            }
          }
        }
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "ParseErrorCause"
          }
        ]
        Next = "SuccessState"
      }

      # Parse error message
      ParseErrorCause = {
        Type = "Pass"
        Parameters = {
          "ParsedCause.$" = "States.StringToJson($.Cause)"
        }
        Next = "NotifyFailure"
      },


      # State NotifyFailure
      NotifyFailure = {
        Type     = "Task"
        Resource = "arn:aws:states:::sns:publish"
        Parameters = {
          TopicArn = var.sns_topic_arn
          Message = {
            "AlarmName"           = "Test Step Functions Failure"
            "TaskDefinitionArn.$" = "$.ParsedCause.TaskDefinitionArn"
            "StoppedReason.$"     = "$.ParsedCause.StoppedReason"
            "Trigger"             = { "Namespace" : "AWS/States" }
          }
          Subject = "ECS Task Failure"
        }
        End = true
      }

      # State Success
      SuccessState = {
        Type = "Pass"
        End  = true
      }

    }
    QueryLanguage = "JSONPath"
  })
}
