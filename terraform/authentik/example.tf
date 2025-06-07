#resource "null_resource" "providers" {
#  for_each = { for p in var.oauth2_providers : p.name => p }
#
#  triggers = {
#    name          = each.key
#    client_id     = each.value.client_id
#    client_secret = each.value.client_secret
#  }
#}
#
#output "providers" {
#   value = null_resource.providers
#}
#
#resource "null_resource" "applications" {
#  for_each = { for p in var.oauth2_providers : p.name => p }
#
#  triggers = {
#    protocol_provider = null_resource.providers[each.key].id
#    name              = each.value.name
#    slug              = each.key
#    meta_launch_url   = each.value.launch_url
#    uuid              = format("%s-%s-%s-123", each.key, each.value.name, each.key)
#  }
#}
#
#output "applications" {
#   value = null_resource.applications
#}
#
#locals {
#  pgroups =  merge(
#    [ for provider in var.oauth2_providers :
#      { for group in provider.groups :
#          format("%s-%s", provider.key, replace(group, " ", "-")) => {
#          #"${provider.key}-${replace(group, ' ', '-')}" => {
#            key   = provider.key
#            pname = provider.name
#            idx   = index(provider.groups, group)
#            group = group }
#      }
#    ]
#  ...)
#}
#resource "null_resource" "groups" {
#  for_each = local.pgroups
#
#  triggers = {
#    key  = each.value.key
#    name = each.value.group
#    idx  = each.value.idx
#  }
#}
#
#output "groups" {
#   value = null_resource.groups
#}
#
#resource "null_resource" "policy_binding" {
#  for_each = local.pgroups
#
#  triggers = {
#    name = "policy_binding"
#    key = each.value.key
#    grp = each.value.group
#    order = each.value.idx
#    target = null_resource.applications[each.value.pname].id # uuid
#    group  = null_resource.groups[each.key].id
#  }
#}
#
#output "policy_binding" {
#   value = null_resource.policy_binding
#}
