'''
Program    : get_random_word.py
Author     : Hrithvik Saseendran
Decription : Python based program for Lambda function to generate a 
             random word,  based on the category and difficulty
'''

import os
import json
import random
import logging
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

'''
Extract Environment Variables and Define Logger
'''

# Get the Dynamo DB table name to obtain the categories
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')
if not DYNAMODB_TABLE_NAME:
    raise ValueError("DYNAMODB_TABLE_NAME environment variable is not set.")

# Set default difficulty to medium, if None selected during invocation
DEFAULT_DIFFICULTY = os.environ.get('DEFAULT_DIFFICULTY', 'medium').lower()

# Get allowed categories and difficulty levels
ALLOWED_CATEGORIES_STR = os.environ.get('ALLOWED_CATEGORIES', '').lower()
ALLOWED_DIFFICULTIES_STR = os.environ.get('ALLOWED_DIFFICULTIES', '').lower()

# Convert comma-separated strings to lists
ALLOWED_CATEGORIES = [
    cat.strip() for cat in ALLOWED_CATEGORIES_STR.split(',') if cat.strip()
] if ALLOWED_CATEGORIES_STR else []

ALLOWED_DIFFICULTIES = [
    diff.strip() for diff in ALLOWED_DIFFICULTIES_STR.split(',') if diff.strip()
] if ALLOWED_DIFFICULTIES_STR else []

# Logger Setup
logger = logging.getLogger(__name__)
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO').upper())

'''
AWS DynamoDB Table Initialization
'''

dynamodb = None
words_table = None
init_error = None

try:
    # Raise exception if the environment variable is unavailable
    if not DYNAMODB_TABLE_NAME:
            raise ValueError('DYNAMODB_TABLE_NAME env variable is unset')
    
    # Create the DB object and try to load the table
    dynamodb = boto3.resource('dynamodb')
    words_table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    words_table.load()
    logger.info(f'Successfully connected to DynamoDB table: {DYNAMODB_TABLE_NAME}')
except Exception as err:

    # Set an init error for standardizing the response
    logger.critical(f'Failed to connect to DynamoDB table {DYNAMODB_TABLE_NAME}: {err}')
    init_error = str(err)

'''
Custom functions for the lambda
'''

# Response build function
def build_response(status_code, body):
    '''
    Function to generate JSON Response for API Gateway, based on Lambda Event
    '''

    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
        },
        'body': json.dumps(body)
    }

# Log generator function
def console_log(request_id, log_string, log_level="info"):
    '''
    Function to generate log information during function execution
    '''
    pass

# Main lambda event handler function
def lambda_handler(event, context):
    '''
    Main handler function for the Lamdba
    Generate a random word from the defined category and difficuly
    '''

    # Get unique request id
    request_id = context.aws_request_id
    logger.info(f'Lambda invocation START (Request ID: {request_id})')
    logger.debug(f'Event received (Request ID: {request_id}): {json.dumps(event)}')
    
    # Handle CORS Pre-Flight/OPTIONS request
    if event.get('httpMethod') == 'OPTIONS':
        logger.debug(f'Handling CORS options request (Request ID: {request_id})')

        # Setting empty body for OPTIONS request
        return build_response(200, {})

    try:
        # Check initialization status
        if init_error:
            return build_response(500, {"error": f"Internal server error: {init_error}"})

        # Extract query string parameters from API request
        query_params = event.get('queryStringParameters', {}) or {}

        # Extract "category" and "difficuly" parameter from the request
        category = query_params.get('category', '').lower().strip()
        difficulty = query_params.get('difficulty', DEFAULT_DIFFICULTY).lower().strip()

        logger.debug(f"Request (Request ID: {request_id}) - category: '{category}', difficulty: '{difficulty}'")

        # Input parameter validation
        validation_errors = []
        if category and category not in ALLOWED_CATEGORIES:
            validation_errors.append(f"Invalid category: '{category}'. Allowed categories: {', '.join(ALLOWED_CATEGORIES)}")
        
        if difficulty and difficulty not in ALLOWED_DIFFICULTIES:
            validation_errors.append(f"Invalid difficulty: '{difficulty}'. Allowed difficulties: {', '.join(ALLOWED_DIFFICULTIES)}")

        if validation_errors:
            logger.warning(f"Validation failed (Request ID: {request_id}): {validation_errors}")
            return build_response(400, {"error": "Invalid request parameters", "details": validation_errors})

        if not category:
            logger.warning(f"Missing 'category' parameter for query (Request ID: {request_id}).")
            return build_response(400, {"error": "Category parameter is required to retrieve a word."})

        # Build KeyConditionExpression to query DynamoDB
        key_condition_expression = Key('Category').eq(category) & Key('Difficulty').eq(difficulty)
        
        logger.info(f"Querying DynamoDB for Category: {category}, Difficulty: {difficulty} (Request ID: {request_id})")

        response = words_table.query(
            KeyConditionExpression=key_condition_expression,
            ProjectionExpression="GameWords, Category, Difficulty" # Only retrieve necessary attributes
        )

        items = response.get('Items', [])

        # If no items returned from DB
        if not items:
            logger.warning(f"No words found for category '{category}' and difficulty '{difficulty}' (Request ID: {request_id})")
            return build_response(404, {
                "error": f"No words found for category '{category}' and difficulty '{difficulty}'."
            })
        
        # More than one items returned from DB. This is not expected ideally, by design
        if len(items) > 1:
            logger.warning(f"Multiple entries found for category '{category}' and difficulty '{difficulty}' (Request ID: {request_id})")
            return build_response(404, {
                "error": f"Multiple entries found for category '{category}' and difficulty '{difficulty}'."
            })

        game_words = items[0].get('GameWords', [])
        logger.info(f"Found {len(game_words)} items for category '{category}', difficulty '{difficulty}' (Request ID: {request_id})")

        # Select a random word from the retrieved items
        random_selected_item = random.choice(game_words)
        
        if not random_selected_item:
            logger.error(f"Random word not obtained for category '{category}' and difficulty '{difficulty}' (Request ID: {request_id})")
            return build_response(500, {"error": "Internal server error: Retrieved word data is malformed."})

        logger.info(f"Successfully retrieved word: '{random_selected_item}' for category '{category}', difficulty '{difficulty}' (Request ID: {request_id})")

        return build_response(200, {
            "word": random_selected_item,
            "category": category,
            "difficulty": difficulty
        })

    except ClientError as aws_err: # Handle all AWS SDK errors
        error_code = aws_err.response.get('Error', {}).get('Code', 'UnknownError')
        error_message = aws_err.response.get('Error', {}).get('Message', 'An AWS service error occurred.')
        logger.error(f"DynamoDB Client Error (Request ID: {request_id}, Code: {error_code}): {error_message}")
        return build_response(500, {"error": "Failed to retrieve word due to a database error."})
    except json.JSONDecodeError: # Malformed JSON msg in incoming request
        logger.error(f"Invalid JSON in event body (Request ID: {request_id}).")
        return build_response(400, {"error": "Invalid JSON in request body."})
    except Exception as all_err: # All unhanlded errors in the function
        logger.exception(f"An unexpected error occurred (Request ID: {request_id}): {all_err}")
        return build_response(500, {"error": "Internal server error."})
    finally:
        logger.info(f"Lambda Invocation END (Request ID: {request_id})")