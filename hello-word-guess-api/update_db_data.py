'''
Program    : create_data.py
Author     : Hrithvik Saseendran
Decription : Python based program for creating data on dynanoDB table
             Full Mode ==> Drop and recreate data from source S3 file
             Delta Mode ==> Import changes from source data file
'''

import boto3

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