#!/usr/bin/env python3

from importlib.machinery import SourceFileLoader

workload_readiness = SourceFileLoader('workload_readiness', '/opt/workload-readiness.py').load_module()

import workload_readiness, os

workload_type_env = os.getenv('WORKLOAD_TYPE')
workload_name_env = os.getenv('WORKLOAD_NAME')
workload_namespace_env = os.getenv('WORKLOAD_NAMESPACE')
check_timeout_env = os.getenv('CHECK_TIMEOUT')
check_retries_env = os.getenv('CHECK_RETRIES')

workload_readiness.check(workload_type=workload_type_env, workload_name=workload_name_env, workload_namespace=workload_namespace_env, check_timeout=check_timeout_env, check_retries=check_retries_env)