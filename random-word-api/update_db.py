'''
Program    : update_db.py
Decription : Python based program for creating data on dynanoDB table
             Full Mode ==> Drop and recreate data from source S3 file
             Delta Mode ==> Import changes from source data file
'''

import boto3
import botocore
import csv
import json
import time
from io import BytesIO, TextIOWrapper

import botocore.exceptions

def full_table_load():
    '''
    Data Destructive Operation - Truncate and Reload from S3 Source File
    '''

    pass

def delta_table_load():
    '''
    Review Changes in Source Data File and Update DynamoDB Table
    '''
    
    pass

REGION_NAME = 'ap-southeast-1'
BUCKET_NAME = 'hello-word-random-apic'
OBJECT_KEY = 'random_words_api_data.csv'
TABLE_NAME = 'helloword-random-word-api-db'

# S3 initialisation
s3_resource = boto3.resource('s3', region_name=REGION_NAME)
bucket = s3_resource.Bucket(BUCKET_NAME)

# DynamoDB initialisation
dynamodb_resource = boto3.resource('dynamodb', region_name=REGION_NAME)
table = dynamodb_resource.Table(TABLE_NAME)
        

#print(dynamodb_resource.meta.client.exceptions.__dict__)
'''
for item in dynamodb_resource.meta.client.exceptions.__dict__['_code_to_exception']:
    print(item)
    print()
exit()'''

def read_csv_from_s3_resource(bucket_obj, object_key):
    """
    Reads a CSV file directly from S3 using the resource interface and parses its content.
    """
    try:
        # Get the object from S3 using the resource interface
        s3_object = bucket_obj.Object(object_key)
        
        # Get the object's body (returns a dictionary from .get())
        csv_bytes = s3_object.get()['Body'].read()
        
        # Wrap BytesIO with TextIOWrapper to treat it as a text file
        csv_file_like_object = TextIOWrapper(BytesIO(csv_bytes), encoding='utf-8')
        
        # Use csv.DictReader to parse the content
        dict_reader = csv.DictReader(csv_file_like_object)
        
        print("Generating import data for dynamoDB table")
        for row_dict in dict_reader:
            print(f'Processing category: {row_dict["Category"]} and difficulty: {row_dict["Difficulty"]}')
            data_dict = {
                'Category': row_dict["Category"],
                'Difficulty': row_dict["Difficulty"],
                'GameWords' : row_dict["GameWords"].split('|')            
            }
            print(f'Preparing to import item into DynamoDB table {TABLE_NAME}')
            response = table.put_item(Item=data_dict)
            #print(response)
            print('Import completed')

    except botocore.exceptions.ClientError as err:
        print('*** Error encountered during the data import operation. ***')
        print(f'*** Error code: {err.__dict__.get("response").get("Error").get("Code")} ***')
        print(f'*** Error message: {err.__dict__.get("response").get("Error").get("Message")} ***')
        exit(1)

if __name__ == "__main__":
    read_csv_from_s3_resource(bucket, OBJECT_KEY)