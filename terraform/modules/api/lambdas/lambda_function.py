import json
from datetime import datetime
from dynamo_model import TodoModel

print("Loading function")


def respond(err, res=None):
    return {
        "statusCode": "400" if err else "200",
        "body": err.message if err else json.dumps(res),
        "headers": {
            "Content-Type": "application/json",
        },
    }


def parse_item(pynamodb_item):
    return {
        "id": pynamodb_item.id,
        "name": pynamodb_item.name,
        "created_at": pynamodb_item.created_at,
        "status": pynamodb_item.status,
        "completed_at": pynamodb_item.completed_at,
    }


def generate_timestamp():
    now = datetime.now()
    return now.strftime("%Y-%m-%dT%H:%M:%SZ")


def list_items():
    return [parse_item(pynamodb_item) for pynamodb_item in TodoModel.scan()]


def create_item(item_id, payload):
    todo = TodoModel(item_id)
    todo.name = payload.get("name")
    todo.created_at = generate_timestamp()
    todo.save()
    return parse_item(todo)


def update_item(item_id, payload):
    todo = TodoModel.get(item_id)
    todo.name = payload.get("name") or todo.name
    if payload.get("status"):
        todo.status = payload.get("status")
        todo.completed_at = generate_timestamp()
    todo.save()
    return parse_item(todo)


def delete_item(item_id):
    todo = TodoModel.get(item_id)
    todo.delete()
    return parse_item(todo)


def cors_preflight_request():
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Headers": "*",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
        },
        "body": json.dumps("Hello from Lambda!"),
    }


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    operations = {
        "GET": list_items,
        "POST": create_item,
        "PUT": update_item,
        "DELETE": delete_item,
    }

    operation = event["httpMethod"]

    if operation == "OPTIONS":
        return cors_preflight_request()

    if operation == "GET":
        return respond(None, operations[operation]())

    item_id = event["pathParameters"].get("proxy")
    if operation == "DELETE":
        return respond(None, operations[operation](item_id))
    elif operation in ["POST", "PUT"]:
        payload = json.loads(event["body"])
        return respond(None, operations[operation](item_id, payload))
    else:
        return respond(ValueError('Unsupported method "{}"'.format(operation)))
