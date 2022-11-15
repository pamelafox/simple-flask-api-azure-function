import azure.functions as func

from .flask_app import app

def main(req: func.HttpRequest, context) -> func.HttpResponse:
  return func.WsgiMiddleware(app.wsgi_app).handle(req, context)