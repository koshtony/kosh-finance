from rest_framework import serializers

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


class IncomeSourceSerializer(serializers.ModelSerializer):
    class Meta:
        model = IncomeSource
        fields = ["id", "name"]


class BusinessSerializer(serializers.ModelSerializer):
    class Meta:
        model = Business
        fields = ["id", "name"]


class EmploymentIncomeSerializer(serializers.ModelSerializer):
    source_name = serializers.CharField(source="source.name", read_only=True)

    class Meta:
        model = EmploymentIncome
        fields = ["id", "source", "source_name", "year", "month", "type", "expected", "actual"]

    def validate_source(self, source):
        tenant_id = self.context["view"].get_tenant_id()
        if str(source.tenant_id) != str(tenant_id):
            raise serializers.ValidationError("Income source belongs to a different tenant.")
        return source


class EmploymentExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmploymentExpense
        fields = ["id", "year", "month", "item", "estimated", "actual"]


class BusinessRevenueSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source="business.name", read_only=True)

    class Meta:
        model = BusinessRevenue
        fields = ["id", "business", "business_name", "year", "month", "expected", "actual"]

    def validate_business(self, business):
        tenant_id = self.context["view"].get_tenant_id()
        if str(business.tenant_id) != str(tenant_id):
            raise serializers.ValidationError("Business belongs to a different tenant.")
        return business


class BusinessExpenseSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source="business.name", read_only=True)

    class Meta:
        model = BusinessExpense
        fields = ["id", "business", "business_name", "year", "month", "item", "estimated", "actual"]

    def validate_business(self, business):
        tenant_id = self.context["view"].get_tenant_id()
        if str(business.tenant_id) != str(tenant_id):
            raise serializers.ValidationError("Business belongs to a different tenant.")
        return business


class DailySaleSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source="business.name", read_only=True)

    class Meta:
        model = DailySale
        fields = ["id", "business", "business_name", "date", "amount", "note"]

    def validate_business(self, business):
        tenant_id = self.context["view"].get_tenant_id()
        if str(business.tenant_id) != str(tenant_id):
            raise serializers.ValidationError("Business belongs to a different tenant.")
        return business


class InvestmentEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = InvestmentEntry
        fields = ["id", "year", "month", "closing_value", "total_interest", "current_month_income"]


class CustomerCheckinSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerCheckin
        fields = ["id", "customer", "month", "week", "status"]


class CustomerSerializer(serializers.ModelSerializer):
    checkins = CustomerCheckinSerializer(many=True, read_only=True)

    class Meta:
        model = Customer
        fields = ["id", "name", "phone", "category", "avg_spending", "checkins"]


class RevenueTargetSerializer(serializers.ModelSerializer):
    class Meta:
        model = RevenueTarget
        fields = ["id", "month", "target", "actual"]
