from django.db import connection
from django.http import JsonResponse


def health(request):
    """Liveness/readiness probe: confirms the process is up and the
    database connection actually works (not just that Django booted)."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        return JsonResponse({"status": "ok"})
    except Exception as exc:  # noqa: BLE001 — deliberately broad for a healthcheck
        return JsonResponse({"status": "error", "detail": str(exc)}, status=503)
