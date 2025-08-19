'''
Program    : exec_random_word_api.py
Author     : Hrithvik Saseendran
Decription : Python based program for creating data on dynanoDB table
             Full Mode ==> Drop and recreate data from source S3 file
             Delta Mode ==> Import changes from source data file
'''

import requests
from requests_aws4auth import AWS4Auth
import boto3

# AWS Configuration
AWS_REGION = "ap-southeast-1"
AWS_API_GATEWAY_ENDPOINT = "https://1xsup1oijk.execute-api.ap-southeast-1.amazonaws.com/dev/helloword/"
AWS_RANDOM_WORD_API = "getRandomWord"
TEST_PARAMS_MEDIUM = {'category': 'animals', 'difficulty': 'medium'}
TEST_PARAMS_HARD = {'category': 'birds', 'difficulty': 'hard'}

# Generate AWS credentials to sign using AWS4Auth
session = boto3.Session()
credentials = session.get_credentials()

def invoke_api_gateway(method, path, headers=None, params=None, data=None, json=None):
    """
    Invokes an AWS API Gateway endpoint with AWS4Auth.
    """

    url = f"{AWS_API_GATEWAY_ENDPOINT}{path}"
    auth = AWS4Auth(credentials.access_key, credentials.secret_key, AWS_REGION, 'execute-api', session_token=credentials.token)

    with requests.Session() as session:
        try:
            response = session.request(
                method,
                url,
                auth=auth,
                headers=headers,
                params=params,
                data=data,
                json=json
            )
            response.raise_for_status()
            return response
        except requests.exceptions.RequestException as e:
            print(f"Error invoking API Gateway: {e}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"Response content: {e.response.text}")

if __name__ == "__main__":
    print("*** Testing API Gateway Invocation ***")

    # 1. Test Medium Difficulty for Animals Category
    print("*** Requesting 'animals' (medium) ***")
    
    response_medium = invoke_api_gateway('GET',
                                          AWS_RANDOM_WORD_API,
                                          params=TEST_PARAMS_MEDIUM)
    if response_medium:
        print(f"Status Code: {response_medium.status_code}")
        print(f"Response Body: {response_medium.json()}")

    # 2. Test Hard Difficuly for Birds Category
    print("*** Requesting 'birds' (medium) ***")
    response_hard = invoke_api_gateway('GET',
                                       AWS_RANDOM_WORD_API,
                                       params=TEST_PARAMS_HARD)
    if response_hard:
        print(f"Status Code: {response_hard.status_code}")
        print(f"Response Body: {response_hard.json()}")