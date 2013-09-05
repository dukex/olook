#
# Cookbook Name:: newrelic
# Attributes:: default
#
# Copyright 2012-2013, Escape Studios
#

#############
#BASIC CONFIG
#############
#license(s)
default['newrelic']['server_monitoring']['license'] = "CHANGE_ME"
default['newrelic']['application_monitoring']['license'] = "CHANGE_ME"

################
#ADVANCED CONFIG
################
#server monitoring
default['newrelic']['server_monitoring']['logfile'] = nil
default['newrelic']['server_monitoring']['loglevel'] = nil
default['newrelic']['server_monitoring']['proxy'] = nil
default['newrelic']['server_monitoring']['ssl'] = nil
default['newrelic']['server_monitoring']['ssl_ca_bundle'] = nil
default['newrelic']['server_monitoring']['ssl_ca_path'] = nil
default['newrelic']['server_monitoring']['pidfile'] = nil
default['newrelic']['server_monitoring']['collector_host'] = nil
default['newrelic']['server_monitoring']['timeout'] = nil
default['newrelic']['server_monitoring']['windows_version'] = "2.0.0.198"
default['newrelic']['server_monitoring']['windows64_checksum'] = "5a8f3f5e8f15997463430401756d377c321c8899c2790ca85e5587a5b643651e"
default['newrelic']['server_monitoring']['windows32_checksum'] = "ac2b65eecaad461fdd2e4386e3e4c9f96ea940b35bdf7a8c532c21dbd1c99ff0"

#application monitoring
default['newrelic']['application_monitoring']['enabled'] = nil
default['newrelic']['application_monitoring']['logfile'] = nil
default['newrelic']['application_monitoring']['loglevel'] = nil
default['newrelic']['application_monitoring']['appname'] = nil
default['newrelic']['application_monitoring']['daemon']['logfile'] = "/var/log/newrelic/newrelic-daemon.log"
default['newrelic']['application_monitoring']['daemon']['loglevel'] = nil
default['newrelic']['application_monitoring']['daemon']['port'] = nil
default['newrelic']['application_monitoring']['daemon']['max_threads'] = nil
default['newrelic']['application_monitoring']['daemon']['ssl'] = nil
default['newrelic']['application_monitoring']['daemon']['ssl_ca_path'] = nil
default['newrelic']['application_monitoring']['daemon']['ssl_ca_bundle'] = nil
default['newrelic']['application_monitoring']['daemon']['proxy'] = nil
default['newrelic']['application_monitoring']['daemon']['pidfile'] = nil
default['newrelic']['application_monitoring']['daemon']['location'] = nil
default['newrelic']['application_monitoring']['daemon']['collector_host'] = nil
default['newrelic']['application_monitoring']['daemon']['dont_launch'] = nil
default['newrelic']['application_monitoring']['capture_params'] = nil
default['newrelic']['application_monitoring']['ignored_params'] = nil
default['newrelic']['application_monitoring']['error_collector']['enable'] = nil
default['newrelic']['application_monitoring']['error_collector']['record_database_errors'] = nil
default['newrelic']['application_monitoring']['error_collector']['prioritize_api_errors'] = nil
default['newrelic']['application_monitoring']['browser_monitoring']['auto_instrument'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['enable'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['threshold'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['detail'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['slow_sql'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['stack_trace_threshold'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['explain_threshold'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['record_sql'] = nil
default['newrelic']['application_monitoring']['transaction_tracer']['custom'] = nil
default['newrelic']['application_monitoring']['framework'] = nil
default['newrelic']['application_monitoring']['webtransaction']['name']['remove_trailing_path'] = nil
default['newrelic']['application_monitoring']['webtransaction']['name']['functions'] = nil
default['newrelic']['application_monitoring']['webtransaction']['name']['files'] = nil
