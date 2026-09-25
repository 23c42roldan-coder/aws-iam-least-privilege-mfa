terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Corrected Policy Document with Valid MFA Enforcement Structure
data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "AllowViewAccountInfoIfMFAExists"
    effect = "Allow"
    actions = [
      "iam:ListVirtualMFADevices",
      "iam:ListMFADevices",
      "iam:ListUsers",
      "iam:ListAccountAliases",
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ChangePassword"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DenyAllExceptMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "iam:ChangePassword"
    ]
    resources = ["*"]

    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "enforce_mfa" {
  name        = "EnforceMFAPolicy"
  description = "Explicitly denies actions without active MFA session"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
}

resource "aws_iam_group" "developers" {
  name = "DevelopersGroup"
}

resource "aws_iam_group_policy_attachment" "attach_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}
