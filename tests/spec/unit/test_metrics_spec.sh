#!/usr/bin/env shellspec
# Tests ShellSpec pour module Metrics

Describe 'Metrics Module - Complete Test Suite'

  setup_metrics() {
    source lib/logging/logger.sh
    source lib/metrics/metrics.sh
    export VERBOSE_LEVEL=0
    export QUIET_MODE=false
    export METRICS_ENABLED=true
  }

  Before setup_metrics

  # ===================================================================
  # Tests: metrics_init()
  # ===================================================================
  Describe 'metrics_init() - Metrics Initialization'

    It 'initializes successfully'
      When call metrics_init
      The status should be success
    End
  End

  # ===================================================================
  # Tests: metrics_start() / metrics_stop()
  # ===================================================================
  Describe 'metrics_start() / metrics_stop() - Metrics Lifecycle'

    It 'starts metrics collection'
      When call metrics_start
      The status should be success
    End

    It 'stops metrics collection'
      call metrics_start
      When call metrics_stop
      The status should be success
    End
  End

  # ===================================================================
  # Tests: metrics_record_repo()
  # ===================================================================
  Describe 'metrics_record_repo() - Repository Metrics'

    It 'records cloned repository'
      When call metrics_record_repo "testrepo" "cloned" "10" "5"
      The status should be success
    End

    It 'records updated repository'
      When call metrics_record_repo "testrepo" "updated" "10" "2"
      The status should be success
    End

    It 'records failed repository'
      When call metrics_record_repo "testrepo" "failed" "0" "1"
      The status should be success
    End
  End

  # ===================================================================
  # Tests: metrics_calculate()
  # ===================================================================
  Describe 'metrics_calculate() - Metrics Calculation'

    It 'calculates metrics correctly'
      call metrics_record_repo "repo1" "cloned" "10" "5"
      call metrics_record_repo "repo2" "cloned" "15" "3"
      When call metrics_calculate
      The output should include "|"
      The status should be success
    End

    It 'handles empty metrics'
      When call metrics_calculate
      The output should include "0|0|0|0"
    End
  End

  # ===================================================================
  # Tests: metrics_export_json()
  # ===================================================================
  Describe 'metrics_export_json() - JSON Export'

    It 'exports metrics to JSON'
      call metrics_start
      call metrics_record_repo "testrepo" "cloned" "10" "5"
      call metrics_stop
      When call metrics_export_json ""
      The status should be success
      The output should include "timestamp"
只用      The output should include "cloned"
    End

    It 'exports to file'
      local output_file="/tmp/test-metrics-$$.json"
      call metrics_record_repo "testrepo" "cloned" "10" "5"
      call metrics_export_json "$output_file"
      When call cat "$output_file"
      The status should be success
      The output should include "cloned"
      rm -f "$output_file"
    End
  End

  # ===================================================================
  # Tests: metrics_export_csv()
  # ===================================================================
  Describe 'metrics_export_csv() - CSV Export'

    It 'exports metrics to CSV'
      call metrics_record_repo "testrepo" "cloned" "10" "5"
      When call metrics_export_csv ""
      The status should be success
      The output should include "timestamp,"
      The output should include "testrepo,cloned"
    End

    It 'exports to file'
      local output_file="/tmp/test-metrics-$$.csv"
      call metrics_record_repo "testrepo" "cloned" "10" "5"
      call metrics_export_csv "$output_file"
      When call cat "$output_file"
      The status should be success
      The output should include "testrepo"
      rm -f "$output_file"
    End
  End

  # ===================================================================
  # Tests: metrics_cleanup()
  # ===================================================================
  Describe 'metrics_cleanup() - Metrics Cleanup'

    It 'cleans up metrics'
      call metrics_record_repo "testrepo" "cloned" "10" "5"
      When call metrics_cleanup
      The status should be success
    End
  End

  # ===================================================================
  # Tests: metrics_setup()
  # ===================================================================
  Describe 'metrics_setup() - Module Setup'

    It 'initializes successfully'
      When call metrics_setup
      The status should be success
    End
  End

End

