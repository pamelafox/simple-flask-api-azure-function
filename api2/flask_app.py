import json
import random

from flask import Flask, request

app = Flask(__name__)

@app.route('/v2/generate_name')
def generate_name():
    starts_with = request.args.get("starts_with")
    names = ["Minnie", "Margaret", "Myrtle", "Noa", "Nadia"]
    if starts_with:
        names = [name for name in names if name.lower().startswith(starts_with)]
    random_name = random.choice(names)
    result = {"name": random_name}
    return json.dumps(result)


if __name__ == "__main__":
    app.run()