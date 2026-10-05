from django.contrib import admin

from .models import Membership, Tenant
from .scoping import tenant_ids_for_user


class TenantScopedAdmin(admin.ModelAdmin):
    """Base admin class for any model with a `tenant` FK (directly, or via
    `tenant_lookup` for one hop away, e.g. CustomerCheckin -> customer__tenant).
    Non-superusers only ever see rows for tenants they're a member of.
    """

    tenant_lookup = "tenant_id"

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        ids = tenant_ids_for_user(request.user)
        if ids is None:
            return qs
        return qs.filter(**{f"{self.tenant_lookup}__in": ids})

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        """Restrict FK dropdowns (tenant, business, customer, ...) to the
        current user's tenants so a non-superuser can't attach a row to a
        tenant they don't belong to."""
        ids = tenant_ids_for_user(request.user)
        if ids is not None:
            if db_field.name == "tenant":
                kwargs["queryset"] = Tenant.objects.filter(id__in=ids)
            elif db_field.related_model is not None and hasattr(
                db_field.related_model, "tenant_id"
            ):
                kwargs["queryset"] = db_field.related_model.objects.filter(tenant_id__in=ids)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "created_at")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        ids = tenant_ids_for_user(request.user)
        if ids is None:
            return qs
        return qs.filter(id__in=ids)


@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = ("user", "tenant", "role", "created_at")
    list_filter = ("role", "tenant")
    search_fields = ("user__username", "user__email", "tenant__name")
    autocomplete_fields = ("user", "tenant")

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        ids = tenant_ids_for_user(request.user)
        if ids is None:
            return qs
        return qs.filter(tenant_id__in=ids)

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "tenant":
            ids = tenant_ids_for_user(request.user)
            if ids is not None:
                kwargs["queryset"] = Tenant.objects.filter(id__in=ids)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)
