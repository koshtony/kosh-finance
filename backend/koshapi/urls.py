from django.contrib import admin
from django.urls import include, path
from rest_framework.authtoken.views import obtain_auth_token
from rest_framework.routers import DefaultRouter

from tenants.api import MeView, TenantViewSet

from .health import health

tenants_router = DefaultRouter()
tenants_router.register("tenants", TenantViewSet, basename="tenant")

urlpatterns = [
    path("health/", health, name="health"),
    path("admin/", admin.site.urls),
    path("api/auth/token/", obtain_auth_token, name="api-token-auth"),
    path("api/me/", MeView.as_view(), name="api-me"),
    path("api/", include(tenants_router.urls)),
    path("api/tenants/<int:tenant_pk>/", include("finance.urls")),
]
