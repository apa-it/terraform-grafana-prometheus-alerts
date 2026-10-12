variable "prometheus_alerts_file_path" {
  description = "Path to the Prometheus Alerting rules file"
  type        = string
}

variable "folder_uid" {
  description = "The UID of the Grafana folder that the alerts belongs to."
  type        = string
}

variable "datasource_uid" {
  description = "The UID of the Grafana datasource being queried with the expressions inside the Alerting rule file"
  type        = string
}

variable "overrides" {
  description = "Overrides per Alert rule"
  type = map(object({
    alert_threshold      = optional(number)
    alert_threshold_type = optional(string)
    exec_err_state       = optional(string)
    expr                 = optional(string)
    is_paused            = optional(bool)
    no_data_state        = optional(string)
    labels               = optional(map(string))
    annotations          = optional(map(string))
    for                  = optional(string)
  }))
  default = {}
}

variable "default_evaluation_interval_duration" {
  description = "How often is the rule evaluated by default. (When not defined inside your Alerting rules file)"
  type        = string
  default     = "5m"
}

variable "default_exec_err_state" {
  description = "Describes what state to enter when the rule's query is invalid and the rule cannot be executed. Options are `OK`, `Error`, `KeepLast`, and `Alerting`."
  type        = string
  default     = "Error"
}

variable "default_alert_threshold" {
  description = "The default threshold for alerting rules."
  type        = number
  default     = 0
}

variable "org_id" {
  description = "The Organization ID of of the Grafana Alerting rule groups. (Only supported with basic auth, API keys are already org-scoped)"
  type        = string
  default     = null
}

variable "disable_provenance" {
  description = "Allow modifying the rule group from other sources than Terraform or the Grafana API."
  type        = bool
  default     = false
}

variable "alert_relative_time_range_from" {
  description = "Relative time range (seconds) for alert evaluation window"
  type        = number
  default     = 600
}

variable "notification_settings" {
  description = <<-EOT
    Routes notifications for every rule in this file through Grafana's
    simplified routing. Set `policy` to the metadata.uid of a named routing
    tree, or `contact_point` to a contact point name - exactly one of the two.
    `policy` is mutually exclusive with all other fields in the block.
    Requires Grafana 10.4+ with feature flag `alertingSimplifiedRouting`
    (named routing trees additionally require Grafana 13.1+ with the
    `alertingMultiplePolicies` feature flag).
    Leave `null` (default) to keep the previous behaviour, i.e. rules are
    routed through the default notification policy tree.
  EOT
  type = object({
    policy          = optional(string)
    contact_point   = optional(string)
    group_by        = optional(list(string))
    group_wait      = optional(string)
    group_interval  = optional(string)
    repeat_interval = optional(string)
    mute_timings    = optional(list(string))
    active_timings  = optional(list(string))
  })
  default = null

  validation {
    condition = var.notification_settings == null ? true : (
      (try(var.notification_settings.policy, null) != null) !=
      (try(var.notification_settings.contact_point, null) != null)
    )
    error_message = "Exactly one of notification_settings.policy or notification_settings.contact_point must be set."
  }

  validation {
    condition = try(var.notification_settings.policy, null) == null ? true : alltrue([
      for f in ["contact_point", "group_by", "group_wait", "group_interval", "repeat_interval", "mute_timings", "active_timings"] :
      try(var.notification_settings[f], null) == null
    ])
    error_message = "notification_settings.policy is mutually exclusive with all other fields in the block."
  }
}
