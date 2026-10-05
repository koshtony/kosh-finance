from django.contrib import admin

from tenants.admin import TenantScopedAdmin

from .models import (
    Business,
    BusinessExpense,
    BusinessRevenue,
    Customer,
    CustomerCheckin,
    DailySale,
    EmploymentExpense,
    EmploymentIncome,
    IncomeSource,
    InvestmentEntry,
    RevenueTarget,
)


@admin.register(IncomeSource)
class IncomeSourceAdmin(TenantScopedAdmin):
    list_display = ("name", "tenant")
    list_filter = ("tenant",)
    search_fields = ("name",)


@admin.register(Business)
class BusinessAdmin(TenantScopedAdmin):
    list_display = ("name", "tenant")
    list_filter = ("tenant",)
    search_fields = ("name",)


@admin.register(EmploymentIncome)
class EmploymentIncomeAdmin(TenantScopedAdmin):
    list_display = ("tenant", "source", "type", "month", "year", "expected", "actual")
    list_filter = ("tenant", "source", "year", "month")
    search_fields = ("type",)


@admin.register(EmploymentExpense)
class EmploymentExpenseAdmin(TenantScopedAdmin):
    list_display = ("tenant", "item", "month", "year", "estimated", "actual")
    list_filter = ("tenant", "year", "month")
    search_fields = ("item",)


@admin.register(BusinessRevenue)
class BusinessRevenueAdmin(TenantScopedAdmin):
    list_display = ("tenant", "business", "month", "year", "expected", "actual")
    list_filter = ("tenant", "business", "year", "month")


@admin.register(BusinessExpense)
class BusinessExpenseAdmin(TenantScopedAdmin):
    list_display = ("tenant", "business", "item", "month", "year", "estimated", "actual")
    list_filter = ("tenant", "business", "year", "month")
    search_fields = ("item",)


@admin.register(DailySale)
class DailySaleAdmin(TenantScopedAdmin):
    list_display = ("tenant", "business", "date", "amount")
    list_filter = ("tenant", "business")
    date_hierarchy = "date"


@admin.register(InvestmentEntry)
class InvestmentEntryAdmin(TenantScopedAdmin):
    list_display = ("tenant", "month", "year", "closing_value", "total_interest")
    list_filter = ("tenant", "year", "month")


class CustomerCheckinInline(admin.TabularInline):
    model = CustomerCheckin
    extra = 0


@admin.register(Customer)
class CustomerAdmin(TenantScopedAdmin):
    list_display = ("name", "tenant", "category", "avg_spending")
    list_filter = ("tenant", "category")
    search_fields = ("name", "phone")
    inlines = [CustomerCheckinInline]


@admin.register(CustomerCheckin)
class CustomerCheckinAdmin(TenantScopedAdmin):
    tenant_lookup = "customer__tenant_id"
    list_display = ("customer", "month", "week", "status")
    list_filter = ("month", "status")

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        from tenants.scoping import tenant_ids_for_user

        if db_field.name == "customer":
            ids = tenant_ids_for_user(request.user)
            if ids is not None:
                kwargs["queryset"] = Customer.objects.filter(tenant_id__in=ids)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(RevenueTarget)
class RevenueTargetAdmin(TenantScopedAdmin):
    list_display = ("tenant", "month", "target", "actual")
    list_filter = ("tenant", "month")
