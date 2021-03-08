import base64
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials
from pprint import pprint
import os

def gather_zones(project, service):
    try:
        zones = service.zones().list(project=project).execute()
        zone_list = [zone['name'] for zone in zones['items']]
        return zone_list
    except Exception as error:
        return error

def disable_vm(project, service, instance, zone):
    try:
        service.instances().stop(project=project, zone=zone, instance=instance).execute()
        print(f"Successfully disabled vm {instance} in project {project}, zone {zone}.")
    except Exception as error:
        return error

def enable_vm(project, service, instance, zone):
    try:
        service.instances().start(project=project, zone=zone, instance=instance).execute()
        print(f"Successfully enabled vm {instance} in project {project}, zone {zone}.")
    except Exception as error:
        return error

def locate_instances(project, service, zones, label_key, label_value, should_disable):
    """
    locates and does the action with a vm. If parameter flag should_disable is True then
    the VM will be disabled (stop will be called), otherwise it will be enabled (start will be called)
    """
    try:
        full_instance_list = []
        for zone in zones:
            instances = service.instances().list(project=project, zone=zone, filter=f"labels.{label_key}={label_value}").execute()
            if 'items' in instances:
                for instance in instances['items']:
                    if instance['status'] == "RUNNING" and should_disable:
                        disable_vm(project, service, instance['name'], zone)
                    elif not should_disable: # should not disable = enable
                        enable_vm(project, service, instance['name'], zone)

    except Exception as error:
        return error

def scheduler_common():
    # env variables
    project = os.environ.get('PROJECT')
    label_key = os.environ.get('LABEL_KEY')
    label_value = os.environ.get('LABEL_VALUE')
    # authentication
    credentials = GoogleCredentials.get_application_default()
    service = discovery.build('compute', 'v1', credentials=credentials, cache_discovery=False)
    # zones
    zones = gather_zones(project, service)
    return project, service, zones, label_key, label_value

def scheduler_start(event, context):
    project, service, zones, label_key, label_value = scheduler_common()
    # instances
    locate_instances(project, service, zones, label_key, label_value, False)

def scheduler_stop(event, context):
    project, service, zones, label_key, label_value = scheduler_common()
    # instances
    locate_instances(project, service, zones, label_key, label_value, True)

