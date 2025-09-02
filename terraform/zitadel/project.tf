resource "zitadel_project" "minikube" {
  name                     = "minikube"
  org_id                   = data.zitadel_org.default.id
  project_role_assertion   = true
  project_role_check       = true
  has_project_check        = true
  private_labeling_setting = "PRIVATE_LABELING_SETTING_ENFORCE_PROJECT_RESOURCE_OWNER_POLICY"
}

resource "zitadel_project_role" "roles" {
  for_each = toset(var.roles)
  org_id       = data.zitadel_org.default.id
  project_id   = data.zitadel_project.default.id
  role_key     = each.value
  display_name = each.value
  group        = format("%s Group", each.value)
}
