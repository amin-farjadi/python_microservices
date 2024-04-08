import os, requests

def token(request):
    if not "Authorization" in request.headers:
        return None, ("Missing credentials", 401)

    token = request.headers["Authorization"]

    if not token:
        return None, ("Missing credentials", 401)

    reponse = requests.post(
        f"http://{os.environ.get('AUTH_SVC_ADDRESS')}/validate",
        headers={"Authorization": token},
    )

    if reponse.status_code == 200:
        return reponse.text, None
    else:
        return None, (reponse.text, reponse.status_code)

