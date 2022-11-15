import json
import logging
import random

from flask import Flask, request


app = Flask(__name__)


@app.route('/generate_name')
def generate_name():
    random_name = random.choice(["Minnie", "Margaret", "Myrtle"])
    result = {"name": random_name}
    return json.dumps(result)


if __name__ == "__main__":
    app.run()