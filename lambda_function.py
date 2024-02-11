import os
import json
import boto3
import requests

def get_lock_tokens(client, ip_set_ids):
    # Retrieve lock tokens for IP sets
    lock_tokens = {}
    for ip_set_name, ip_set_id in ip_set_ids.items():
        response = client.get_ip_set(
            Name=ip_set_name,
            Scope='REGIONAL',
            Id=ip_set_id
        )
        lock_tokens[ip_set_name] = response['LockToken']
    return lock_tokens

def fetch_ip_list_from_url(url):
    # Fetches and returns the IP address list from a URL
    response = requests.get(url)
    if response.status_code == 200:
        ip_data = response.text.strip()
        if ip_data:
            return [ip.strip() for ip in ip_data.split('\n') if ip.strip()]
    return None

def update_ip_set(client, ip_set_name, ip_set_id, ip_list, lock_token):
    # Updates the specified IP set with the provided IP list
    try:
        response = client.update_ip_set(
            Name=ip_set_name,
            Scope='REGIONAL',
            Id=ip_set_id,
            Addresses=ip_list,
            LockToken=lock_token
        )
        print(f"Added {len(ip_list)} IP addresses to {ip_set_name}.")
    except Exception as e:
        print(f"Error updating {ip_set_name}: {e}")

def lambda_handler(event, context):
    # Initialize AWS WAF client
    client = boto3.client('wafv2', region_name="us-east-1")
    
    # Retrieve WAF IP set IDs from environment variables
    ip_set_ids = {
        'Test-Ips1': os.environ['WAF_IP_SET_ID_1'],
        'Test-Ips2': os.environ['WAF_IP_SET_ID_2']
    }
    
    # Retrieve lock tokens for IP sets
    lock_tokens = get_lock_tokens(client, ip_set_ids)
   
    # Fetch and update IP addresses from the first GitHub file
    ip_list_1 = fetch_ip_list_from_url('https://raw.githubusercontent.com/Pasindu-Nuwanga/aws-lambda/main/WAFfeed.txt')
    if ip_list_1 is not None:
        update_ip_set(client, 'Test-Ips1', ip_set_ids['Test-Ips1'], ip_list_1, lock_tokens['Test-Ips1'])
    else:
        print("Failed to fetch or empty IP list from WAFfeed.txt. Skipped updating Test-Ips1.")
    
    # Fetch and update IP addresses from the second GitHub file
    ip_list_2 = fetch_ip_list_from_url('https://raw.githubusercontent.com/Pasindu-Nuwanga/aws-lambda/main/WAFfeed2.txt')
    if ip_list_2 is not None:
        update_ip_set(client, 'Test-Ips2', ip_set_ids['Test-Ips2'], ip_list_2, lock_tokens['Test-Ips2'])
    else:
        print("Failed to fetch or empty IP list from WAFfeed2.txt. Skipped updating Test-Ips2.")

    return {
        'statusCode': 200,
        'body': json.dumps('IP addresses added successfully!')
    }
