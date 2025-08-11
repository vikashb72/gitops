locals {
  oauth2Groups = merge(
    [for provider in var.oauth2_providers :
      { for group in provider.groups :
        format("%s-%s", provider.key, replace(group, " ", "-")) => {
          #"${provider.key}-${replace(group, ' ', '-')}" => {
          key   = provider.key
          pname = provider.name
          idx   = index(provider.groups, group)
        group = group }
      }
    ]
  ...)

  proxyGroups = merge(
    [for provider in var.proxy_providers :
      { for group in provider.groups :
        format("%s-%s", provider.key, replace(group, " ", "-")) => {
          #"${provider.key}-${replace(group, ' ', '-')}" => {
          key   = provider.key
          pname = provider.name
          idx   = index(provider.groups, group)
        group = group }
      }
    ]
  ...)

  samlGroups = merge(
    [for provider in var.saml_providers :
      { for group in provider.groups :
        format("%s-%s", provider.key, replace(group, " ", "-")) => {
          #"${provider.key}-${replace(group, ' ', '-')}" => {
          key   = provider.key
          pname = provider.name
          idx   = index(provider.groups, group)
        group = group }
      }
    ]
  ...)
}
