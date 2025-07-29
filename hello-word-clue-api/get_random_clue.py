'''
Program    : get_random_clue.py
Author     : Hrithvik Saseendran
Decription : Python based program for Lambda function to generate clue
             by querying Google Generative AI
'''
import os
import json
import logging
import google.generativeai as gemini_ai
from google.generativeai.types import HarmCategory, HarmBlockThreshold

'''
Extract Environment Variables and Define Logger
'''

# Get the Google API Key
GOOGLE_API_KEY = os.environ.get('GEMINI_API_KEY')
if not GOOGLE_API_KEY:
    raise ValueError("GEMINI_API_KEY environment variable is not set.")

# Configure the Google Generative AI
gemini_ai.configure(api_key=GOOGLE_API_KEY)

# Logger Setup
logger = logging.getLogger(__name__)
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO').upper())

'''
Custom functions for the lambda
'''

# Prompt build function for Gemini GenAI
def build_gemini_prompt(word, category, difficulty="easy"):
    '''
    Function to generate the prompt text for the Generative Model
    '''

    return f'''
    Give me a short, concise, and tricky clue to guess the word: {word}.
    The word belongs to the category: {category}.
    The clue text should be able to meet difficulty level: {difficulty}.
    The clue should not contain the word itself or any part of it.
    The clue should avoid robotic sounding words.
    The clue should have interesting and engaging phrases.
    The clue should not be repetitive in nature.

    A simple example for a word: "dog", category: "animals", difficulty: "easy"

    "You'll often find me right there with people. 
    My kind has been around forever, and I usually get around on four legs, 
    but sometimes three, or even two when I'm really hyped up. 
    Words aren't my thing, but my tail? That's my main way of chatting. 
    
    A good ear scratch pretty much seals our bond. 
    It's all about loyalty, and 
    I do my bit guarding the place with my own unique sounds."
    '''
# Build safety settings for Gemini GenAI
def build_gemini_safety_setting():
    '''
    Function to generate the safety settings for the Generative Model
    '''

    return {
        HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE, 
        HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE
    }

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

# Main lambda event handler function
def lambda_handler(event, context):
    '''
    Main handler function for the Lamdba
    Generate a random clue for the given word and category
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
        # Extract query string parameters from API request
        query_params = event.get('queryStringParameters', {}) or {}

        # Extract required "word" and "category" parameter from the request
        word = query_params.get('word', '').strip()
        category = query_params.get('category', '').strip()

        # Extract "difficulty" parameter, default is "medium"
        difficulty = query_params.get('difficulty', 'medium').strip()


        logger.debug(f"Request (Request ID: {request_id}) - word: '{word}', difficulty: '{difficulty}'")

        # Input parameter validation
        if not word:
            logger.warning(f"Missing 'word' parameter for query (Request ID: {request_id}).")
            return build_response(400, {"error": "Word parameter is required to retrieve a clue."})
        
        if not category:
            logger.warning(f"Missing 'category' parameter for query (Request ID: {request_id}).")
            return build_response(400, {"error": "Category parameter is required to retrieve a clue."})

        # Initialize the Generative Model
        model = gemini_ai.GenerativeModel('gemini-pro')
        logger.info(f"Generating clue for word: '{word}', difficulty: '{difficulty}' (Request ID: {request_id})")
        prompt = build_gemini_prompt(word, category, difficulty)
        response = model.generate_content(prompt, 
                                          safety_settings=build_gemini_safety_setting())
        clue = response.text.strip()

        # Check the response from Gemini
        if not clue:
            logger.error(f"Failed to generate clue for word '{word}' and difficulty '{difficulty}' (Request ID: {request_id})")
            return build_response(500, {"error": "Failed to generate a clue. Please try again."})
        logger.info(f"Successfully generated clue for word '{word}', difficulty '{difficulty}' (Request ID: {request_id})")

        return build_response(200, {
            "word": word,
            "category": category,
            "clue": clue
        })

    # All unhandled errors in the function
    except Exception as all_err:
        logger.exception(f"An unexpected error occurred (Request ID: {request_id}): {all_err}")
        return build_response(500, {"error": "Internal server error."})
    finally:
        logger.info(f"Lambda Invocation END (Request ID: {request_id})")

if __name__ == '__main__':
    '''
    Testing Lambda Function on Console
    '''
    logger.debug('Testing Lambda Function')
    genai_model = gemini_ai.GenerativeModel('gemini-1.5-flash')
    generation_config = {"temperature": 0.9}
    prompt = build_gemini_prompt("tripunithura", "town", "easy")
    response = genai_model.generate_content(prompt, 
                                            safety_settings=build_gemini_safety_setting(),
                                            generation_config=generation_config)
    print(response.text)