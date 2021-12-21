import os
import boto3
import datetime

client = boto3.client('sns')
topic_arn = os.environ['TOPIC_ARN']
param_secret = os.environ['PARAM_SECRET']

def handle(event, context):
    current_date_time = datetime.datetime.now()
    passed_params = event['queryStringParameters']

    if not passed_params:
        print('No secret sent to API')
        return {
            "statusCode": 401,
        }

    if not passed_params.get('PARAM_SECRET', None) == param_secret:
        print(f'Invalid secret sent to API, sent secret is {passed_params.get("PARAM_SECRET", None)}')
        return {
            "statusCode": 401,
        }

    response = client.publish(
        TopicArn=topic_arn,
        Message=f'Notification webhook triggered at {current_date_time.strftime("%d/%m/%Y %H:%M:%S")}',
        Subject='Webhook notification triggered'
    )

    if not response["MessageId"]:
        print(f'Message has not sent to SNS correctly')
        return {
            "statusCode": 500,
        }

    print(f'Submitted message id {response["MessageId"]}')

    return {
        "statusCode": 200,
    }
