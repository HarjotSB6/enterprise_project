import json
import boto3
import os

sns = boto3.client('sns')
topic_arn = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    message = {
        'Records': event['Records']
    }
    sns.publish(
        TopicArn=topic_arn,
        Message=json.dumps(message),
        Subject='S3 Object Created Notification'
    )
    return {
        'statusCode': 200,
        'body': json.dumps('Notification sent')
    }
