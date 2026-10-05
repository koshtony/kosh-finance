from django.contrib.auth import get_user_model
from rest_framework import exceptions, permissions, serializers, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Membership, Tenant
from .scoping import is_tenant_member, tenant_ids_for_user
from .serializers import MemberSerializer, MembershipSerializer, TenantSerializer

User = get_user_model()


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


class MemberViewSet(viewsets.ModelViewSet):
    """Manages who has access to one tenant and what they can see
    (`role` + `allowed_pages`). Nested under /api/tenants/<tenant_pk>/members/.

    Any tenant member can list; only an owner/admin member (or superuser)
    can create, update, or remove a membership.
    """

    serializer_class = MemberSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_tenant_id(self):
        return self.kwargs["tenant_pk"]

    def get_queryset(self):
        tenant_id = self.get_tenant_id()
        if not is_tenant_member(self.request.user, tenant_id):
            return Membership.objects.none()
        return Membership.objects.filter(tenant_id=tenant_id).select_related("user")

    def _require_tenant_admin(self):
        if self.request.user.is_superuser:
            return
        if not is_tenant_member(self.request.user, self.get_tenant_id()):
            raise exceptions.PermissionDenied("Not a member of this tenant.")
        membership = Membership.objects.filter(
            tenant_id=self.get_tenant_id(), user=self.request.user
        ).first()
        if membership is None or not membership.is_admin:
            raise exceptions.PermissionDenied("Only tenant admins can manage users.")

    def _admin_count(self, exclude_pk=None):
        qs = Membership.objects.filter(
            tenant_id=self.get_tenant_id(), role__in=[Membership.ROLE_OWNER, Membership.ROLE_ADMIN]
        )
        if exclude_pk is not None:
            qs = qs.exclude(pk=exclude_pk)
        return qs.count()

    def perform_create(self, serializer):
        self._require_tenant_admin()
        data = serializer.validated_data
        username = (data.get("username") or "").strip()
        if not username:
            raise serializers.ValidationError({"username": "Username is required."})
        tenant_id = self.get_tenant_id()
        user, created = User.objects.get_or_create(username=username)
        if created:
            user.set_password(data.get("password") or User.objects.make_random_password())
            user.save()
        elif Membership.objects.filter(tenant_id=tenant_id, user=user).exists():
            raise serializers.ValidationError({"username": "That user already has access to this tenant."})
        serializer.instance = Membership.objects.create(
            tenant_id=tenant_id,
            user=user,
            role=data.get("role", Membership.ROLE_MEMBER),
            allowed_pages=data.get("allowed_pages", ""),
        )

    def perform_update(self, serializer):
        self._require_tenant_admin()
        instance = serializer.instance
        data = serializer.validated_data
        new_role = data.get("role", instance.role)
        if instance.is_admin and new_role not in (Membership.ROLE_OWNER, Membership.ROLE_ADMIN):
            if self._admin_count(exclude_pk=instance.pk) < 1:
                raise serializers.ValidationError({"role": "At least one admin account must remain."})
        password = data.get("password")
        if password:
            instance.user.set_password(password)
            instance.user.save()
        instance.role = new_role
        if "allowed_pages" in data:
            instance.allowed_pages = data["allowed_pages"]
        instance.save()

    def perform_destroy(self, instance):
        self._require_tenant_admin()
        if instance.user_id == self.request.user.id:
            raise serializers.ValidationError("You cannot delete the account you are logged in as.")
        if instance.is_admin and self._admin_count(exclude_pk=instance.pk) < 1:
            raise serializers.ValidationError("At least one admin account must remain.")
        instance.delete()


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
