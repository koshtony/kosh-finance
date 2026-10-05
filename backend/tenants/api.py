from rest_framework import permissions, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Tenant
from .scoping import is_tenant_member, tenant_ids_for_user
from .serializers import MembershipSerializer, TenantSerializer


class TenantScopedViewSetMixin:
    """Mixin for any ModelViewSet whose model has a `tenant` FK (directly,
    or one hop away via `tenant_field`, e.g. "customer__tenant") and whose
    URL is nested under /tenants/<tenant_pk>/...

    Scopes the queryset to the tenant in the URL, requires the requesting
    user to be a member of that tenant, and auto-fills `tenant` on create.
    """

    permission_classes = [permissions.IsAuthenticated]
    tenant_field = "tenant_id"

    def get_tenant_id(self):
        return self.kwargs["tenant_pk"]

    def get_queryset(self):
        tenant_id = self.get_tenant_id()
        if not is_tenant_member(self.request.user, tenant_id):
            return self.queryset.model.objects.none()
        return super().get_queryset().filter(**{self.tenant_field: tenant_id})

    def perform_create(self, serializer):
        serializer.save(tenant_id=self.get_tenant_id())


class TenantViewSet(viewsets.ReadOnlyModelViewSet):
    """Tenants the current user belongs to (all of them, for a superuser)."""

    serializer_class = TenantSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        ids = tenant_ids_for_user(self.request.user)
        if ids is None:
            return Tenant.objects.all()
        return Tenant.objects.filter(id__in=ids)


class MeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        memberships = user.memberships.select_related("tenant").all()
        return Response(
            {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_superuser": user.is_superuser,
                "memberships": MembershipSerializer(memberships, many=True).data,
            }
        )
