from rest_framework import serializers

from .models import Membership, Tenant


class TenantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tenant
        fields = ["id", "name", "slug", "created_at"]


class MembershipSerializer(serializers.ModelSerializer):
    """Used by /api/me/ — the current user's own memberships."""

    tenant = TenantSerializer(read_only=True)
    is_admin = serializers.BooleanField(read_only=True)

    class Meta:
        model = Membership
        fields = ["id", "tenant", "role", "allowed_pages", "is_admin"]


class MemberSerializer(serializers.ModelSerializer):
    """Used by /api/tenants/<id>/members/ to manage who has access to one
    tenant. `username`/`password` are write-only inputs for creating or
    resetting the underlying Django user; they aren't persisted on
    Membership itself (the view handles that part of the write)."""

    username = serializers.CharField(required=False)
    password = serializers.CharField(write_only=True, required=False, allow_blank=True)
    is_admin = serializers.BooleanField(read_only=True)

    class Meta:
        model = Membership
        fields = ["id", "username", "password", "role", "allowed_pages", "is_admin"]

    def to_representation(self, instance):
        rep = super().to_representation(instance)
        rep["username"] = instance.user.username
        return rep
