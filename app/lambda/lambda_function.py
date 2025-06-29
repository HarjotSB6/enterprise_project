import boto3
import os

def lambda_handler(event, context):
    try:
        s3_event = event['Records'][0]['s3']
        bucket = s3_event['bucket']['name']
        key = s3_event['object']['key']

        message = f"New object uploaded:\nBucket: {bucket}\nKey: {key}"

        sns = boto3.client('sns')
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject='S3 Upload Notification',
            Message=message
        )

        return {
            'statusCode': 200,
            'body': 'Notification sent.'
        }
    except Exception as e:
        print(e)
        raise
