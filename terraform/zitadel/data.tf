data "zitadel_org" "default" {
  id = var.zorgid
}

data "zitadel_project" "default" {
  org_id     = data.zitadel_org.default.id
  project_id = var.pid
}
