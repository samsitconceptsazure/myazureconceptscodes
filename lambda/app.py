import json, os, boto3
client = boto3.client('bedrock-runtime')
HEADERS = {'Content-Type': 'application/json'}
def reply(status, payload):
    return {'statusCode': status, 'headers': HEADERS, 'body': json.dumps(payload)}
def handler(event, context):
    try:
        body = json.loads(event.get('body') or '{}')
        question = body.get('message', '')
        if not isinstance(question, str) or not question.strip() or len(question) > 2000:
            return reply(400, {'error': 'Message must be 1-2000 characters'})
        history = body.get('history', [])
        if not isinstance(history, list):
            return reply(400, {'error': 'History must be a list'})
        messages = []
        for item in history[-10:]:
            if not isinstance(item, dict) or item.get('role') not in ('user', 'assistant') or not isinstance(item.get('text'), str):
                return reply(400, {'error': 'Invalid history'})
            if not item['text'] or len(item['text']) > 2000:
                return reply(400, {'error': 'Invalid history text'})
            if messages and messages[-1]['role'] == item['role']:
                continue
            messages.append({'role': item['role'], 'content': [{'text': item['text']}]})
        if messages and messages[-1]['role'] != 'assistant':
            messages = []  # avoid invalid role ordering
        messages.append({'role': 'user', 'content': [{'text': question}]})
        result = client.converse(modelId=os.environ['MODEL_ID'], messages=messages,
            system=[{'text': 'You are a friendly cloud technology learning assistant. Be accurate and concise. Do not invent course prices or schedules.'}],
            inferenceConfig={'maxTokens': 500, 'temperature': 0.3})
        answer = ''.join(c.get('text', '') for c in result['output']['message']['content'])
        return reply(200, {'answer': answer})
    except Exception as exc:
        print('Chat failure:', repr(exc))
        return reply(502, {'error': 'AI service unavailable. Check Lambda CloudWatch logs and Bedrock model access.'})
