import boto3

SNS_TOPIC_ARN = 'arn:aws:sns:us-east-1:123456789012:s3-upload-topic'  # replace with your topic ARN

def lambda_handler(event, context):
    s3_event = event['Records'][0]['s3']
    bucket = s3_event['bucket']['name']
    key = s3_event['object']['key']

    message = f"New object uploaded:\nBucket: {bucket}\nKey: {key}"

    sns = boto3.client('sns')
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject='S3 Upload Notification',
        Message=message
    )

    return {
        'statusCode': 200,
        'body': 'Notification sent.'
    }
