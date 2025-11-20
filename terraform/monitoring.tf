# Monitoring and Logging Configuration for GCP

# Log-based metrics for application monitoring
resource "google_logging_metric" "http_request_count" {
  name   = "healthcare-http-request-count"
  filter = "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"healthcare\""
  
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
    
    labels {
      key         = "service"
      value_type  = "STRING"
      description = "Service name"
    }
    
    labels {
      key         = "status_code"
      value_type  = "STRING"
      description = "HTTP status code"
    }
  }
  
  label_extractors = {
    "service"     = "EXTRACT(resource.labels.container_name)"
    "status_code" = "EXTRACT(jsonPayload.status)"
  }
}

# Uptime check for patient service
resource "google_monitoring_uptime_check_config" "patient_service" {
  display_name = "Patient Service Health Check"
  timeout      = "10s"
  period       = "60s"
  
  http_check {
    path         = "/health"
    port         = 3000
    use_ssl      = false
    validate_ssl = false
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "patient-service.healthcare.svc.cluster.local"
    }
  }
}

# Alert policy for high error rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate - Healthcare Services"
  combiner     = "OR"
  
  conditions {
    display_name = "HTTP 5xx error rate > 5%"
    
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/healthcare-http-request-count\" AND metric.label.status_code=~\"5.*\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Alert policy for pod restarts
resource "google_monitoring_alert_policy" "pod_restarts" {
  display_name = "Frequent Pod Restarts"
  combiner     = "OR"
  
  conditions {
    display_name = "Pod restart count > 3"
    
    condition_threshold {
      filter          = "resource.type=\"k8s_pod\" AND resource.labels.namespace_name=\"healthcare\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 3
      
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.pod_name"]
      }
    }
  }
  
  notification_channels = []
  
  alert_strategy {
    auto_close = "1800s"
  }
}

# Dashboard for healthcare services
resource "google_monitoring_dashboard" "healthcare_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Healthcare Services Dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "HTTP Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/healthcare-http-request-count\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          widget = {
            title = "Pod CPU Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" AND resource.namespace_name=\"healthcare\" AND metric.type=\"kubernetes.io/pod/cpu/core_usage_time\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          yPos   = 4
          widget = {
            title = "Pod Memory Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_pod\" AND resource.namespace_name=\"healthcare\" AND metric.type=\"kubernetes.io/pod/memory/used_bytes\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          xPos   = 6
          yPos   = 4
          widget = {
            title = "Error Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/healthcare-http-request-count\" AND metric.label.status_code=~\"[45].*\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
