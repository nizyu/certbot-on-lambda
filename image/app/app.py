import subprocess

def handler(event, context):
    result = subprocess.run(['./main.sh'])
    if result.returncode == 0:
        return {"statusCode": 200}
    else:
        raise Exception(f'Script failed. code: {result.returncode}')

