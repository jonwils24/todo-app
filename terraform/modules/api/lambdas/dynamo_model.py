import os
from pynamodb.models import Model
from pynamodb.attributes import UnicodeAttribute


class TodoModel(Model):
    class Meta:
        table_name = os.environ.get("DYNAMO_TABLE_NAME")

    id = UnicodeAttribute(hash_key=True)
    name = UnicodeAttribute(default=None)
    created_at = UnicodeAttribute(null=False)
    status = UnicodeAttribute(default="open")
    completed_at = UnicodeAttribute(null=True)
