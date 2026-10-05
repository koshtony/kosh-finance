from rest_framework import serializers, viewsets

from tenants.api import TenantScopedViewSetMixin

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
from .serializers import (
    BusinessExpenseSerializer,
    BusinessRevenueSerializer,
    BusinessSerializer,
    CustomerCheckinSerializer,
    CustomerSerializer,
    DailySaleSerializer,
    EmploymentExpenseSerializer,
    EmploymentIncomeSerializer,
    IncomeSourceSerializer,
    InvestmentEntrySerializer,
    RevenueTargetSerializer,
)


class IncomeSourceViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = IncomeSource.objects.all()
    serializer_class = IncomeSourceSerializer


class BusinessViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = Business.objects.all()
    serializer_class = BusinessSerializer


class EmploymentIncomeViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = EmploymentIncome.objects.select_related("source").all()
    serializer_class = EmploymentIncomeSerializer


class EmploymentExpenseViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = EmploymentExpense.objects.all()
    serializer_class = EmploymentExpenseSerializer


class BusinessRevenueViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = BusinessRevenue.objects.select_related("business").all()
    serializer_class = BusinessRevenueSerializer


class BusinessExpenseViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = BusinessExpense.objects.select_related("business").all()
    serializer_class = BusinessExpenseSerializer


class DailySaleViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = DailySale.objects.select_related("business").all()
    serializer_class = DailySaleSerializer


class InvestmentEntryViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = InvestmentEntry.objects.all()
    serializer_class = InvestmentEntrySerializer


class CustomerViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = Customer.objects.prefetch_related("checkins").all()
    serializer_class = CustomerSerializer


class CustomerCheckinViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = CustomerCheckin.objects.select_related("customer").all()
    serializer_class = CustomerCheckinSerializer
    tenant_field = "customer__tenant_id"

    def perform_create(self, serializer):
        customer = serializer.validated_data.get("customer")
        if customer is None or str(customer.tenant_id) != str(self.get_tenant_id()):
            raise serializers.ValidationError({"customer": "Customer belongs to a different tenant."})
        serializer.save()


class RevenueTargetViewSet(TenantScopedViewSetMixin, viewsets.ModelViewSet):
    queryset = RevenueTarget.objects.all()
    serializer_class = RevenueTargetSerializer
