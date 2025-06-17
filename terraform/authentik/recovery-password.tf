data "authentik_stage" "default-password-change-prompt" {
  name = "default-password-change-prompt"
}

data "authentik_stage" "default-password-change-write" {
  name = "default-password-change-write"
}

data "authentik_stage" "default-authentication-identification" {
  name = "default-authentication-identification"
}

resource "authentik_stage_identification" "recovery" {
  name           = "recovery-authentification-identification"
  user_fields    = ["username", "email"]
}

resource "authentik_stage_email" "recovery" {
  name    = "recovery-email"
  subject = "Password Recovery"
}

resource "authentik_flow" "recovery" {
  name        = "recovery-flow"
  title       = "Recovery flow"
  slug        = "recovery-flow"
  designation = "recovery"
}

resource "authentik_flow_stage_binding" "recovery-flow-identification" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_identification.recovery.id
  order  = 0
}

resource "authentik_flow_stage_binding" "recovery-flow-email" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_email.recovery.id
  order  = 10
}

resource "authentik_flow_stage_binding" "recovery-flow-password-change" {
  target = authentik_flow.recovery.uuid
  stage  = data.authentik_stage.default-password-change-prompt.id
  order  = 20
}

resource "authentik_flow_stage_binding" "recovery-flow-password-write" {
  target = authentik_flow.recovery.uuid
  stage  = data.authentik_stage.default-password-change-write.id
  order  = 30
}

# data "authentik_flow" "default-authentication-flow"
# data "authentik_stage" "default-authentication-identification" {

#resource "authentik_stage_identification" "default_authentication_identification" {
#  name           = "default-authentication-identification"
#  user_fields    = ["username", "email"]
#  password_stage = data.authentik_stage.default-authentication-identification.id
#  case_insensitive_matching = true
#  recovery_flow = authentik_flow.recovery.uuid
#}
#
