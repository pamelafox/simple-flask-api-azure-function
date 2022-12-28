[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&repo=pamelafox%2Fsimple-flask-api-azure-function)

This repository includes a very simple Python Flask HTTP API, made for demonstration purposes only.

## Local development

1. Open this repository in Github Codespaces or VS Code with Remote Devcontainers extension.
2. Run API v1:

```console
python3 api/flask_app.py
```

3. Click 'http://127.0.0.1:5000' in the terminal, which should open the website in a new tab.
4. Append `/v1/generate_name` to the end of the URL.
5. Run API v2:

```console
python3 api2/flask_app.py
```

6. Click 'http://127.0.0.1:5000' in the terminal.
7. Append `/v2/generate_name?starts_with=n` to the end of the URL.

## Deployment

Run `azd up`.

Navigate to the endpoint displayed in the terminal.

To try API v1, append `/v1/generate_name` to the end of the URL.
To try API v2, append `/v2/generate_name` to the end of the URL.