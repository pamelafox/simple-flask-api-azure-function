# Simple Flask API on Azure Functions + APIM

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&repo=pamelafox%2Fsimple-flask-api-azure-function)

This repository includes a very simple Python Flask HTTP API, made for demonstration purposes only.

## Local development

1. Open this repository in Github Codespaces or VS Code with Remote Devcontainers extension.
2. Run API v1:

    ```console
    python3 -m flask --app api/flask_app.py run --port 50505 --debug
    ```

3. Click 'http://127.0.0.1:50505' in the terminal, which should open the website in a new tab.
4. Append `/v1/generate_name` to the end of the URL.
5. Run API v2:

    ```console
    python3 -m flask --app api2/flask_app.py run --port 50505 --debug
    ```

6. Click 'http://127.0.0.1:50505' in the terminal.
7. Append `/v2/generate_name?starts_with=n` to the end of the URL.

## Deployment

This repo is set up for deployment to Azure Functions plus Azure API Management,
using `azure.yaml` and the configuration files in the `infra` folder.

Steps for deployment:

1. Sign up for a [free Azure account](https://azure.microsoft.com/free/)
2. Install the [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd). (If you open this repository in Codespaces or with the VS Code Dev Containers extension, that part will be done for you.)
3. Login to Azure:

    ```shell
    azd auth login
    ```

4. Provision and deploy all the resources:

    ```shell
    azd up
    ```

    It will prompt you to provide an `azd` environment name (like "django-app"), select a subscription from your Azure account, and select a location (like "eastus"). Then it will provision the resources in your account and deploy the latest code.

5. Once it finishes deploying, navigate to the endpoint URL displayed in the terminal.

    To try API v1, append `/v1/generate_name` to the end of the URL.

    To try API v2, append `/v2/generate_name` to the end of the URL.

6. When you've made any changes to the app code, you can just run:

    ```shell
    azd deploy
    ```
