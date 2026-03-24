# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class AccessibilityDefaultaccessibility(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    feature = models.TextField(blank=True, null=True)
    filter = models.TextField(blank=True, null=True)
    exclude_all = models.BooleanField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'accessibility_defaultaccessibility'


class AccessibilityDefaultaccessibilityEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    defaultaccessibility_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'accessibility_defaultaccessibility_employees'
        unique_together = (('defaultaccessibility_id', 'employee_id'),)


class AiCostBudgets(models.Model):
    id = models.BigAutoField(unique=True)
    module = models.TextField(blank=True, null=True)
    monthly_budget_usd = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    alert_threshold_percent = models.BigIntegerField(blank=True, null=True)
    month = models.DateField(blank=True, null=True)
    current_spend_usd = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_requests = models.BigIntegerField(blank=True, null=True)
    cached_requests = models.BigIntegerField(blank=True, null=True)
    alert_sent_at = models.DateTimeField(blank=True, null=True)
    budget_exceeded_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'ai_cost_budgets'
        unique_together = (('company_id', 'module', 'month'),)


class AiResponseCache(models.Model):
    id = models.BigAutoField(unique=True)
    cache_key = models.TextField(unique=True, blank=True, null=True)
    module = models.TextField(blank=True, null=True)
    feature = models.TextField(blank=True, null=True)
    prompt_hash = models.TextField(blank=True, null=True)
    response_data = models.TextField(blank=True, null=True)
    hit_count = models.BigIntegerField(blank=True, null=True)
    tokens_saved = models.BigIntegerField(blank=True, null=True)
    cost_saved = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)
    last_accessed = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'ai_response_cache'


class AiSettings(models.Model):
    id = models.BigAutoField(unique=True)
    ai_enabled = models.BooleanField(blank=True, null=True)
    leave_ai_enabled = models.BooleanField(blank=True, null=True)
    timesheet_ai_enabled = models.BooleanField(blank=True, null=True)
    performance_ai_enabled = models.BooleanField(blank=True, null=True)
    subscription_ai_enabled = models.BooleanField(blank=True, null=True)
    recruitment_ai_enabled = models.BooleanField(blank=True, null=True)
    ai_disabled_message = models.TextField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    updated_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'ai_settings'


class AiUsageLogs(models.Model):
    id = models.BigAutoField(unique=True)
    request_id = models.TextField(unique=True, blank=True, null=True)
    module = models.TextField(blank=True, null=True)
    feature = models.TextField(blank=True, null=True)
    model_name = models.TextField(blank=True, null=True)
    prompt_tokens = models.BigIntegerField(blank=True, null=True)
    completion_tokens = models.BigIntegerField(blank=True, null=True)
    total_tokens = models.BigIntegerField(blank=True, null=True)
    estimated_cost = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    response_time_ms = models.BigIntegerField(blank=True, null=True)
    cache_hit = models.BooleanField(blank=True, null=True)
    success = models.BooleanField(blank=True, null=True)
    error_message = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    user_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'ai_usage_logs'


class AssetAsset(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    asset_name = models.TextField(blank=True, null=True)
    asset_description = models.TextField(blank=True, null=True)
    asset_tracking_id = models.TextField(unique=True, blank=True, null=True)
    asset_purchase_date = models.DateField(blank=True, null=True)
    asset_purchase_cost = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    asset_status = models.TextField(blank=True, null=True)
    expiry_date = models.DateField(blank=True, null=True)
    notify_before = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    owner_id = models.BigIntegerField(blank=True, null=True)
    asset_category_id_id = models.BigIntegerField(blank=True, null=True)
    asset_lot_number_id_id = models.BigIntegerField(blank=True, null=True)
    depreciation_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    enable_depreciation = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_asset'


class AssetAssetassignment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    assigned_date = models.DateField(blank=True, null=True)
    return_date = models.DateField(blank=True, null=True)
    return_condition = models.TextField(blank=True, null=True)
    return_status = models.TextField(blank=True, null=True)
    return_request = models.BooleanField(blank=True, null=True)
    asset_id_id = models.BigIntegerField(blank=True, null=True)
    assigned_by_employee_id_id = models.BigIntegerField(blank=True, null=True)
    assigned_to_employee_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetassignment'


class AssetAssetassignmentAssignImages(models.Model):
    id = models.BigAutoField(unique=True)
    assetassignment_id = models.BigIntegerField(blank=True, null=True)
    returnimages_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetassignment_assign_images'
        unique_together = (('assetassignment_id', 'returnimages_id'),)


class AssetAssetassignmentReturnImages(models.Model):
    id = models.BigAutoField(unique=True)
    assetassignment_id = models.BigIntegerField(blank=True, null=True)
    returnimages_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetassignment_return_images'
        unique_together = (('assetassignment_id', 'returnimages_id'),)


class AssetAssetcategory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    asset_category_name = models.TextField(unique=True, blank=True, null=True)
    asset_category_description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetcategory'


class AssetAssetdocuments(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    file = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    asset_report_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetdocuments'


class AssetAssetlot(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    lot_number = models.TextField(unique=True, blank=True, null=True)
    lot_description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetlot'


class AssetAssetlotCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    assetlot_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetlot_company_id'
        unique_together = (('assetlot_id', 'company_id'),)


class AssetAssetreport(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    asset_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetreport'


class AssetAssetrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    asset_request_date = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    asset_request_status = models.TextField(blank=True, null=True)
    asset_category_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    requested_employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_assetrequest'


class AssetBudgetalert(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    alert_date = models.DateTimeField(blank=True, null=True)
    spending_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    spending_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    alert_sent = models.BooleanField(blank=True, null=True)
    budget_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_budgetalert'


class AssetBudgetalertRecipients(models.Model):
    id = models.BigAutoField(unique=True)
    budgetalert_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_budgetalert_recipients'
        unique_together = (('budgetalert_id', 'employee_id'),)


class AssetBudgetsoftwareitem(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    included = models.BooleanField(blank=True, null=True)
    assigned_licenses = models.BigIntegerField(blank=True, null=True)
    cost_per_license = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    monthly_cost = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    budget_report_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    software_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_budgetsoftwareitem'
        unique_together = (('budget_report_id', 'software_id'),)


class AssetEmployeesoftwareaccess(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    assigned_date = models.DateField(blank=True, null=True)
    revoked_date = models.DateField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    username = models.TextField(blank=True, null=True)
    access_level = models.TextField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    assigned_by_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    software_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_employeesoftwareaccess'
        unique_together = (('employee_id', 'software_id'),)


class AssetFinancebudgetlineitem(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    category = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    line_order = models.BigIntegerField(blank=True, null=True)
    budget_report_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_financebudgetlineitem'


class AssetFinancebudgetmiscitem(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    item_name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    category = models.TextField(blank=True, null=True)
    budget_report_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_financebudgetmiscitem'


class AssetFinancebudgetplannedpurchase(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    software_name = models.TextField(blank=True, null=True)
    vendor = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    license_type = models.TextField(blank=True, null=True)
    estimated_users = models.BigIntegerField(blank=True, null=True)
    priority = models.TextField(blank=True, null=True)
    budget_report_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_financebudgetplannedpurchase'


class AssetFinancebudgetreport(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    report_name = models.TextField(blank=True, null=True)
    report_month = models.DateField(blank=True, null=True)
    created_date = models.DateTimeField(blank=True, null=True)
    updated_date = models.DateTimeField(blank=True, null=True)
    emailed_to = models.TextField(blank=True, null=True)
    emailed_cc = models.TextField(blank=True, null=True)
    last_emailed_date = models.DateTimeField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    approval_notes = models.TextField(blank=True, null=True)
    approved_date = models.DateTimeField(blank=True, null=True)
    approver_id = models.BigIntegerField(blank=True, null=True)
    budget_type = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_financebudgetreport'


class AssetReturnimages(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    image = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_returnimages'


class AssetSoftware(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    website_url = models.TextField(blank=True, null=True)
    logo = models.TextField(blank=True, null=True)
    license_type = models.TextField(blank=True, null=True)
    total_licenses = models.BigIntegerField(blank=True, null=True)
    cost_per_license = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    billing_cycle = models.TextField(blank=True, null=True)
    purchase_date = models.DateField(blank=True, null=True)
    renewal_date = models.DateField(blank=True, null=True)
    auto_renew = models.BooleanField(blank=True, null=True)
    notify_before_expiry = models.BigIntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    contract_document = models.TextField(blank=True, null=True)
    license_key = models.TextField(blank=True, null=True)
    admin_url = models.TextField(blank=True, null=True)
    category_id = models.BigIntegerField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    vendor_id = models.BigIntegerField(blank=True, null=True)
    bandwidth = models.TextField(blank=True, null=True)
    connection_type = models.TextField(blank=True, null=True)
    service_location = models.TextField(blank=True, null=True)
    service_type = models.TextField(blank=True, null=True)
    static_ips = models.BigIntegerField(blank=True, null=True)
    additional_accounts_details = models.TextField(blank=True, null=True)
    additional_licenses = models.BigIntegerField(blank=True, null=True)
    primary = models.TextField(blank=True, null=True)
    secondary = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_software'


class AssetSoftwareNotificationRecipients(models.Model):
    id = models.BigAutoField(unique=True)
    software_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_software_notification_recipients'
        unique_together = (('software_id', 'employee_id'),)


class AssetSoftwareaccessrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    requested_date = models.DateTimeField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    requested_access_level = models.TextField(blank=True, null=True)
    requested_username = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reviewed_date = models.DateTimeField(blank=True, null=True)
    review_notes = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    reviewed_by_id = models.BigIntegerField(blank=True, null=True)
    software_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_softwareaccessrequest'


class AssetSoftwarebudget(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    budget_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    budget_period = models.TextField(blank=True, null=True)
    alert_threshold_percentage = models.BigIntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    category_id = models.BigIntegerField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_softwarebudget'


class AssetSoftwarebudgetAlertRecipients(models.Model):
    id = models.BigAutoField(unique=True)
    softwarebudget_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_softwarebudget_alert_recipients'


class AssetSoftwarecategory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(unique=True, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    icon = models.TextField(blank=True, null=True)
    color_code = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_softwarecategory'


class AssetVendor(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    website = models.TextField(blank=True, null=True)
    primary_contact_name = models.TextField(blank=True, null=True)
    primary_contact_email = models.TextField(blank=True, null=True)
    primary_contact_phone = models.TextField(blank=True, null=True)
    support_email = models.TextField(blank=True, null=True)
    support_phone = models.TextField(blank=True, null=True)
    support_portal_url = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    logo = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'asset_vendor'


class AttendanceAttendance(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    attendance_date = models.DateField(blank=True, null=True)
    attendance_clock_in_date = models.DateField(blank=True, null=True)
    attendance_clock_in = models.TimeField(blank=True, null=True)
    attendance_clock_out_date = models.DateField(blank=True, null=True)
    attendance_clock_out = models.TimeField(blank=True, null=True)
    attendance_worked_hour = models.TextField(blank=True, null=True)
    minimum_hour = models.TextField(blank=True, null=True)
    attendance_overtime = models.TextField(blank=True, null=True)
    attendance_overtime_approve = models.BooleanField(blank=True, null=True)
    attendance_validated = models.BooleanField(blank=True, null=True)
    at_work_second = models.BigIntegerField(blank=True, null=True)
    overtime_second = models.BigIntegerField(blank=True, null=True)
    approved_overtime_second = models.BigIntegerField(blank=True, null=True)
    is_validate_request = models.BooleanField(blank=True, null=True)
    is_bulk_request = models.BooleanField(blank=True, null=True)
    is_validate_request_approved = models.BooleanField(blank=True, null=True)
    request_description = models.TextField(blank=True, null=True)
    request_type = models.TextField(blank=True, null=True)
    is_holiday = models.BooleanField(blank=True, null=True)
    requested_data = models.TextField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    attendance_day_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    batch_attendance_id_id = models.BigIntegerField(blank=True, null=True)
    excluded_seconds = models.BigIntegerField(blank=True, null=True)
    excluded_gaps = models.TextField(blank=True, null=True)
    expected_check_in = models.TimeField(blank=True, null=True)
    expected_check_out = models.TimeField(blank=True, null=True)
    attendance_attachment = models.TextField(blank=True, null=True)
    attendance_request_status = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendance'


class AttendanceAttendanceactivity(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    attendance_date = models.DateField(blank=True, null=True)
    in_datetime = models.DateTimeField(blank=True, null=True)
    clock_in_date = models.DateField(blank=True, null=True)
    clock_in = models.TimeField(blank=True, null=True)
    clock_out_date = models.DateField(blank=True, null=True)
    out_datetime = models.DateTimeField(blank=True, null=True)
    clock_out = models.TimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_day_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendanceactivity'


class AttendanceAttendancegeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    time_runner = models.BooleanField(blank=True, null=True)
    enable_check_in = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancegeneralsetting'


class AttendanceAttendancelatecomeearlyout(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    attendance_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancelatecomeearlyout'
        unique_together = (('attendance_id_id', 'type'),)


class AttendanceAttendanceovertime(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    month = models.TextField(blank=True, null=True)
    month_sequence = models.SmallIntegerField(blank=True, null=True)
    worked_hours = models.TextField(blank=True, null=True)
    pending_hours = models.TextField(blank=True, null=True)
    overtime = models.TextField(blank=True, null=True)
    hour_account_second = models.BigIntegerField(blank=True, null=True)
    hour_pending_second = models.BigIntegerField(blank=True, null=True)
    overtime_second = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    year = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendanceovertime'
        unique_together = (('employee_id_id', 'month', 'year'),)


class AttendanceAttendancerequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancerequestcomment'


class AttendanceAttendancerequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    attendancerequestcomment_id = models.BigIntegerField(blank=True, null=True)
    attendancerequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancerequestcomment_files'


class AttendanceAttendancerequestfile(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    file = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancerequestfile'


class AttendanceAttendancevalidationcondition(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    validation_at_work = models.TextField(blank=True, null=True)
    minimum_overtime_to_approve = models.TextField(blank=True, null=True)
    overtime_cutoff = models.TextField(blank=True, null=True)
    auto_approve_ot = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancevalidationcondition'


class AttendanceAttendancevalidationconditionCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    attendancevalidationcondition_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendancevalidationcondition_company_id'


class AttendanceAttendanceweeklyemailsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    send_to_employee = models.BooleanField(blank=True, null=True)
    cc_reporting_manager = models.BooleanField(blank=True, null=True)
    additional_cc_emails = models.TextField(blank=True, null=True)
    bcc_emails = models.TextField(blank=True, null=True)
    adjust_for_leaves = models.BooleanField(blank=True, null=True)
    adjust_for_holidays = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendanceweeklyemailsetting'


class AttendanceAttendanceweeklyemailsettingExcludedEmployees(models.Model):
    id = models.BigAutoField()
    attendanceweeklyemailsetting_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_attendanceweeklyemailsetting_excluded_employees'


class AttendanceBatchattendance(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_batchattendance'


class AttendanceBiometricpunchlog(models.Model):
    id = models.BigAutoField(unique=True)
    punch_datetime = models.DateTimeField(blank=True, null=True)
    punch_type = models.TextField(blank=True, null=True)
    device_id = models.TextField(blank=True, null=True)
    is_processed = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_biometricpunchlog'


class AttendanceBiometricpunchrecord(models.Model):
    id = models.BigAutoField(unique=True)
    device_id = models.TextField(blank=True, null=True)
    biometric_user_id = models.TextField(blank=True, null=True)
    punch_datetime = models.DateTimeField(blank=True, null=True)
    punch_type = models.BigIntegerField(blank=True, null=True)
    punch_direction = models.TextField(blank=True, null=True)
    device_direction = models.TextField(blank=True, null=True)
    sync_timestamp = models.DateTimeField(blank=True, null=True)
    is_processed_for_attendance = models.BooleanField(blank=True, null=True)
    is_processed_for_breaks = models.BooleanField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_biometricpunchrecord'
        unique_together = (('employee_id_id', 'punch_datetime', 'device_id'),)


class AttendanceGracetime(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    allowed_time = models.TextField(blank=True, null=True)
    allowed_time_in_secs = models.BigIntegerField(blank=True, null=True)
    allowed_clock_in = models.BooleanField(blank=True, null=True)
    allowed_clock_out = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_gracetime'


class AttendanceGracetimeCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    gracetime_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_gracetime_company_id'
        unique_together = (('gracetime_id', 'company_id'),)


class AttendanceHistoricalattendance(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    attendance_date = models.DateField(blank=True, null=True)
    attendance_clock_in_date = models.DateField(blank=True, null=True)
    attendance_clock_in = models.TimeField(blank=True, null=True)
    attendance_clock_out_date = models.DateField(blank=True, null=True)
    attendance_clock_out = models.TimeField(blank=True, null=True)
    attendance_worked_hour = models.TextField(blank=True, null=True)
    minimum_hour = models.TextField(blank=True, null=True)
    attendance_overtime = models.TextField(blank=True, null=True)
    attendance_overtime_approve = models.BooleanField(blank=True, null=True)
    attendance_validated = models.BooleanField(blank=True, null=True)
    at_work_second = models.BigIntegerField(blank=True, null=True)
    overtime_second = models.BigIntegerField(blank=True, null=True)
    approved_overtime_second = models.BigIntegerField(blank=True, null=True)
    is_validate_request = models.BooleanField(blank=True, null=True)
    is_bulk_request = models.BooleanField(blank=True, null=True)
    is_validate_request_approved = models.BooleanField(blank=True, null=True)
    request_description = models.TextField(blank=True, null=True)
    request_type = models.TextField(blank=True, null=True)
    is_holiday = models.BooleanField(blank=True, null=True)
    requested_data = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    attendance_day_id = models.BigIntegerField(blank=True, null=True)
    batch_attendance_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    excluded_seconds = models.BigIntegerField(blank=True, null=True)
    excluded_gaps = models.TextField(blank=True, null=True)
    expected_check_in = models.TimeField(blank=True, null=True)
    expected_check_out = models.TimeField(blank=True, null=True)
    attendance_attachment = models.TextField(blank=True, null=True)
    attendance_request_status = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_historicalattendance'


class AttendanceHistoricalattendanceHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalattendance_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_historicalattendance_history_tags'


class AttendanceHistoricalpermissionrequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    from_time = models.TimeField(blank=True, null=True)
    to_time = models.TimeField(blank=True, null=True)
    duration_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    approved_date = models.DateTimeField(blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_historicalpermissionrequest'


class AttendancePermissionComment(models.Model):
    id = models.BigAutoField(unique=True)
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    permission_request_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_permission_comment'


class AttendancePermissionRequest(models.Model):
    id = models.BigAutoField(unique=True)
    requested_date = models.DateField(blank=True, null=True)
    from_time = models.TimeField(blank=True, null=True)
    to_time = models.TimeField(blank=True, null=True)
    duration_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    approved_date = models.DateTimeField(blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_permission_request'


class AttendanceWorkrecords(models.Model):
    id = models.BigAutoField(unique=True)
    record_name = models.TextField(blank=True, null=True)
    work_record_type = models.TextField(blank=True, null=True)
    date = models.DateField(blank=True, null=True)
    at_work = models.TextField(blank=True, null=True)
    min_hour = models.TextField(blank=True, null=True)
    at_work_second = models.BigIntegerField(blank=True, null=True)
    min_hour_second = models.BigIntegerField(blank=True, null=True)
    note = models.TextField(blank=True, null=True)
    message = models.TextField(blank=True, null=True)
    is_attendance_record = models.BooleanField(blank=True, null=True)
    is_leave_record = models.BooleanField(blank=True, null=True)
    day_percentage = models.FloatField(blank=True, null=True)
    last_update = models.DateTimeField(blank=True, null=True)
    attendance_id_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    leave_request_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'attendance_workrecords'


class AuditlogLogentry(models.Model):
    id = models.BigAutoField(unique=True)
    object_pk = models.TextField(blank=True, null=True)
    object_id = models.BigIntegerField(blank=True, null=True)
    object_repr = models.TextField(blank=True, null=True)
    action = models.SmallIntegerField(blank=True, null=True)
    timestamp = models.DateTimeField(blank=True, null=True)
    actor_id = models.BigIntegerField(blank=True, null=True)
    content_type_id = models.BigIntegerField(blank=True, null=True)
    remote_addr = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    serialized_data = models.TextField(blank=True, null=True)
    cid = models.TextField(blank=True, null=True)
    changes_text = models.TextField(blank=True, null=True)
    changes = models.TextField(blank=True, null=True)
    remote_port = models.IntegerField(blank=True, null=True)
    actor_email = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'auditlog_logentry'


class AuthGroup(models.Model):
    id = models.BigAutoField(unique=True)
    name = models.TextField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    id = models.BigAutoField(unique=True)
    group_id = models.BigIntegerField(blank=True, null=True)
    permission_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group_id', 'permission_id'),)


class AuthPermission(models.Model):
    id = models.BigAutoField(unique=True)
    content_type_id = models.BigIntegerField(blank=True, null=True)
    codename = models.TextField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type_id', 'codename'),)


class AuthtokenToken(models.Model):
    key = models.TextField(unique=True, blank=True, null=True)
    created = models.DateTimeField(blank=True, null=True)
    user_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'authtoken_token'


class BaseAnnouncement(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    expire_date = models.DateField(blank=True, null=True)
    disable_comments = models.BooleanField(blank=True, null=True)
    public_comments = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement'


class BaseAnnouncementAttachments(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    attachment_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_attachments'
        unique_together = (('announcement_id', 'attachment_id'),)


class BaseAnnouncementCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_company_id'
        unique_together = (('announcement_id', 'company_id'),)


class BaseAnnouncementDepartment(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_department'
        unique_together = (('announcement_id', 'department_id'),)


class BaseAnnouncementEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_employees'
        unique_together = (('announcement_id', 'employee_id'),)


class BaseAnnouncementFilteredEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_filtered_employees'


class BaseAnnouncementJobPosition(models.Model):
    id = models.BigAutoField(unique=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    jobposition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcement_job_position'
        unique_together = (('announcement_id', 'jobposition_id'),)


class BaseAnnouncementcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    announcement_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcementcomment'


class BaseAnnouncementexpire(models.Model):
    id = models.BigAutoField(unique=True)
    days = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcementexpire'


class BaseAnnouncementview(models.Model):
    id = models.BigAutoField(unique=True)
    viewed = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    user_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_announcementview'


class BaseAttachment(models.Model):
    id = models.BigAutoField(unique=True)
    file = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_attachment'


class BaseAttendanceallowedip(models.Model):
    id = models.BigAutoField(unique=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_attendanceallowedip'


class BaseBaserequestfile(models.Model):
    id = models.BigAutoField(unique=True)
    file = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_baserequestfile'


class BaseBiometricattendance(models.Model):
    id = models.BigAutoField(unique=True)
    is_installed = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_biometricattendance'


class BaseCompany(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company = models.TextField(blank=True, null=True)
    hq = models.BooleanField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    zip = models.TextField(blank=True, null=True)
    icon = models.TextField(blank=True, null=True)
    date_format = models.TextField(blank=True, null=True)
    time_format = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_company'
        unique_together = (('company', 'address'),)


class BaseCompanygroup(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    group_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_companygroup'
        unique_together = (('group_id', 'company_id'),)


class BaseCompanyleaves(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    based_on_week = models.TextField(blank=True, null=True)
    based_on_week_day = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_companyleaves'
        unique_together = (('based_on_week', 'based_on_week_day'),)


class BaseDashboardemployeecharts(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    charts = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_dashboardemployeecharts'


class BaseDashboardwidgetpreference(models.Model):
    id = models.BigAutoField(unique=True)
    dashboard_role = models.TextField(blank=True, null=True)
    widget_order = models.TextField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_dashboardwidgetpreference'
        unique_together = (('employee_id', 'dashboard_role'),)


class BaseDefaultgrouppermission(models.Model):
    id = models.BigAutoField(unique=True)
    permission_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_defaultgrouppermission'


class BaseDepartment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    department = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_department'


class BaseDepartmentCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_department_company_id'
        unique_together = (('department_id', 'company_id'),)


class BaseDriverviewed(models.Model):
    id = models.BigAutoField(unique=True)
    viewed = models.TextField(blank=True, null=True)
    user_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_driverviewed'


class BaseDynamicemailconfiguration(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    host = models.TextField(blank=True, null=True)
    port = models.SmallIntegerField(blank=True, null=True)
    from_email = models.TextField(blank=True, null=True)
    username = models.TextField(blank=True, null=True)
    display_name = models.TextField(blank=True, null=True)
    password = models.TextField(blank=True, null=True)
    use_tls = models.BooleanField(blank=True, null=True)
    use_ssl = models.BooleanField(blank=True, null=True)
    fail_silently = models.BooleanField(blank=True, null=True)
    is_primary = models.BooleanField(blank=True, null=True)
    use_dynamic_display_name = models.BooleanField(blank=True, null=True)
    timeout = models.SmallIntegerField(blank=True, null=True)
    company_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_dynamicemailconfiguration'


class BaseDynamicpagination(models.Model):
    id = models.BigAutoField(unique=True)
    pagination = models.BigIntegerField(blank=True, null=True)
    user_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_dynamicpagination'


class BaseEmaillog(models.Model):
    id = models.BigAutoField(unique=True)
    subject = models.TextField(blank=True, null=True)
    body = models.TextField(blank=True, null=True)
    from_email = models.TextField(blank=True, null=True)
    to = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_emaillog'


class BaseEmployeeshift(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    employee_shift = models.TextField(blank=True, null=True)
    weekly_full_time = models.TextField(blank=True, null=True)
    full_time = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    grace_time_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    overtime_buffer_hours = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshift'


class BaseEmployeeshiftCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    employeeshift_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshift_company_id'
        unique_together = (('employeeshift_id', 'company_id'),)


class BaseEmployeeshiftday(models.Model):
    id = models.BigAutoField(unique=True)
    day = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshiftday'


class BaseEmployeeshiftdayCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    employeeshiftday_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshiftday_company_id'
        unique_together = (('employeeshiftday_id', 'company_id'),)


class BaseEmployeeshiftschedule(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    minimum_working_hour = models.TextField(blank=True, null=True)
    start_time = models.TimeField(blank=True, null=True)
    end_time = models.TimeField(blank=True, null=True)
    is_night_shift = models.BooleanField(blank=True, null=True)
    is_auto_punch_out_enabled = models.BooleanField(blank=True, null=True)
    auto_punch_out_time = models.TimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    day_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshiftschedule'
        unique_together = (('shift_id_id', 'day_id'),)


class BaseEmployeeshiftscheduleCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    employeeshiftschedule_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeeshiftschedule_company_id'
        unique_together = (('employeeshiftschedule_id', 'company_id'),)


class BaseEmployeetype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    employee_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeetype'


class BaseEmployeetypeCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    employeetype_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_employeetype_company_id'
        unique_together = (('employeetype_id', 'company_id'),)


class BaseHistoricalrotatingshiftassign(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    next_change_date = models.DateField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rotate_after_day = models.BigIntegerField(blank=True, null=True)
    rotate_every_weekend = models.TextField(blank=True, null=True)
    rotate_every = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    current_shift_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    next_shift_id = models.BigIntegerField(blank=True, null=True)
    rotating_shift_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalrotatingshiftassign'


class BaseHistoricalrotatingshiftassignHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalrotatingshiftassign_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalrotatingshiftassign_history_tags'
        unique_together = (('historicalrotatingshiftassign_id', 'audittag_id'),)


class BaseHistoricalrotatingworktypeassign(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    next_change_date = models.DateField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rotate_after_day = models.BigIntegerField(blank=True, null=True)
    rotate_every_weekend = models.TextField(blank=True, null=True)
    rotate_every = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    rotating_work_type_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    current_work_type_id = models.BigIntegerField(blank=True, null=True)
    next_work_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalrotatingworktypeassign'


class BaseHistoricalrotatingworktypeassignHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalrotatingworktypeassign_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalrotatingworktypeassign_history_tags'


class BaseHistoricalshiftrequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    reallocate_approved = models.BooleanField(blank=True, null=True)
    reallocate_canceled = models.BooleanField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_permanent_shift = models.BooleanField(blank=True, null=True)
    approved = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    shift_changed = models.BooleanField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    previous_shift_id_id = models.BigIntegerField(blank=True, null=True)
    reallocate_to_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalshiftrequest'


class BaseHistoricalshiftrequestHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalshiftrequest_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalshiftrequest_history_tags'
        unique_together = (('historicalshiftrequest_id', 'audittag_id'),)


class BaseHistoricalworktyperequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_permanent_work_type = models.BooleanField(blank=True, null=True)
    approved = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    work_type_changed = models.BooleanField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    previous_work_type_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalworktyperequest'


class BaseHistoricalworktyperequestHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalworktyperequest_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_historicalworktyperequest_history_tags'
        unique_together = (('historicalworktyperequest_id', 'audittag_id'),)


class BaseHolidays(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    recurring = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_holidays'


class BaseHorillamailtemplate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(unique=True, blank=True, null=True)
    body = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    bcc_emails = models.TextField(blank=True, null=True)
    cc_emails = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    module = models.TextField(blank=True, null=True)
    subject = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_horillamailtemplate'


class BaseIntegrationapps(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    app_label = models.TextField(unique=True, blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_integrationapps'


class BaseJobposition(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    job_position = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_jobposition'


class BaseJobpositionCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    jobposition_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_jobposition_company_id'
        unique_together = (('jobposition_id', 'company_id'),)


class BaseJobrole(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    job_role = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_jobrole'
        unique_together = (('job_position_id_id', 'job_role'),)


class BaseJobroleCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    jobrole_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_jobrole_company_id'
        unique_together = (('jobrole_id', 'company_id'),)


class BaseModulesettings(models.Model):
    id = models.BigAutoField(unique=True)
    module_name = models.TextField(unique=True, blank=True, null=True)
    display_name = models.TextField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    icon = models.TextField(blank=True, null=True)
    order = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_modulesettings'


class BaseMultipleapprovalcondition(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    condition_field = models.TextField(blank=True, null=True)
    condition_operator = models.TextField(blank=True, null=True)
    condition_value = models.TextField(blank=True, null=True)
    condition_start_value = models.TextField(blank=True, null=True)
    condition_end_value = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_multipleapprovalcondition'


class BaseMultipleapprovalmanagers(models.Model):
    id = models.BigAutoField(unique=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager = models.TextField(blank=True, null=True)
    condition_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_multipleapprovalmanagers'


class BaseNotificationsound(models.Model):
    id = models.BigAutoField(unique=True)
    sound_enabled = models.BooleanField(blank=True, null=True)
    employee_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_notificationsound'


class BasePenaltyaccounts(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    minus_leaves = models.FloatField(blank=True, null=True)
    deduct_from_carry_forward = models.BooleanField(blank=True, null=True)
    penalty_amount = models.FloatField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    late_early_id_id = models.BigIntegerField(blank=True, null=True)
    leave_request_id_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_penaltyaccounts'


class BaseRotatingshift(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift1_id = models.BigIntegerField(blank=True, null=True)
    shift2_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_rotatingshift'


class BaseRotatingshiftassign(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    next_change_date = models.DateField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rotate_after_day = models.BigIntegerField(blank=True, null=True)
    rotate_every_weekend = models.TextField(blank=True, null=True)
    rotate_every = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    current_shift_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    next_shift_id = models.BigIntegerField(blank=True, null=True)
    rotating_shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_rotatingshiftassign'


class BaseRotatingworktype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    work_type1_id = models.BigIntegerField(blank=True, null=True)
    work_type2_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_rotatingworktype'


class BaseRotatingworktypeassign(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    next_change_date = models.DateField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rotate_after_day = models.BigIntegerField(blank=True, null=True)
    rotate_every_weekend = models.TextField(blank=True, null=True)
    rotate_every = models.TextField(blank=True, null=True)
    additional_data = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    rotating_work_type_id_id = models.BigIntegerField(blank=True, null=True)
    current_work_type_id = models.BigIntegerField(blank=True, null=True)
    next_work_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_rotatingworktypeassign'


class BaseShiftrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    reallocate_approved = models.BooleanField(blank=True, null=True)
    reallocate_canceled = models.BooleanField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_permanent_shift = models.BooleanField(blank=True, null=True)
    approved = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    shift_changed = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    previous_shift_id_id = models.BigIntegerField(blank=True, null=True)
    reallocate_to_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_shiftrequest'


class BaseShiftrequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_shiftrequestcomment'


class BaseShiftrequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    shiftrequestcomment_id = models.BigIntegerField(blank=True, null=True)
    baserequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_shiftrequestcomment_files'


class BaseSubmenusettings(models.Model):
    id = models.BigAutoField(unique=True)
    module_name = models.TextField(blank=True, null=True)
    submenu_name = models.TextField(blank=True, null=True)
    submenu_url = models.TextField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    order = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_submenusettings'
        unique_together = (('module_name', 'submenu_url'),)


class BaseSystemgroup(models.Model):
    id = models.BigAutoField(unique=True)
    group_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_systemgroup'


class BaseTags(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_tags'


class BaseTracklatecomeearlyout(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_enable = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_tracklatecomeearlyout'


class BaseWorktype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    work_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktype'


class BaseWorktypeCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    worktype_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktype_company_id'
        unique_together = (('worktype_id', 'company_id'),)


class BaseWorktyperequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    requested_till = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_permanent_work_type = models.BooleanField(blank=True, null=True)
    approved = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    work_type_changed = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    previous_work_type_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktyperequest'


class BaseWorktyperequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktyperequestcomment'


class BaseWorktyperequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    worktyperequestcomment_id = models.BigIntegerField(blank=True, null=True)
    baserequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'base_worktyperequestcomment_files'
        unique_together = (('worktyperequestcomment_id', 'baserequestfile_id'),)


class BiometricBiometricdevices(models.Model):
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    id = models.TextField(unique=True, blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    machine_type = models.TextField(blank=True, null=True)
    machine_ip = models.TextField(blank=True, null=True)
    port = models.BigIntegerField(blank=True, null=True)
    zk_password = models.TextField(blank=True, null=True)
    bio_username = models.TextField(blank=True, null=True)
    bio_password = models.TextField(blank=True, null=True)
    anviz_request_id = models.TextField(blank=True, null=True)
    api_url = models.TextField(blank=True, null=True)
    api_key = models.TextField(blank=True, null=True)
    api_secret = models.TextField(blank=True, null=True)
    api_token = models.TextField(blank=True, null=True)
    api_expires = models.TextField(blank=True, null=True)
    is_live = models.BooleanField(blank=True, null=True)
    is_scheduler = models.BooleanField(blank=True, null=True)
    scheduler_duration = models.TextField(blank=True, null=True)
    last_fetch_date = models.DateField(blank=True, null=True)
    last_fetch_time = models.TimeField(blank=True, null=True)
    device_direction = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'biometric_biometricdevices'


class BiometricBiometricemployees(models.Model):
    id = models.TextField(unique=True, blank=True, null=True)
    uid = models.BigIntegerField(blank=True, null=True)
    ref_user_id = models.BigIntegerField(blank=True, null=True)
    user_id = models.TextField(blank=True, null=True)
    dahua_card_no = models.TextField(blank=True, null=True)
    device_id_id = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'biometric_biometricemployees'


class BiometricCosecattendancearguments(models.Model):
    id = models.TextField(unique=True, blank=True, null=True)
    last_fetch_roll_ovr_count = models.TextField(blank=True, null=True)
    last_fetch_seq_number = models.TextField(blank=True, null=True)
    device_id_id = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'biometric_cosecattendancearguments'


class DjangoAdminLog(models.Model):
    id = models.BigAutoField(unique=True)
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.TextField(blank=True, null=True)
    action_flag = models.SmallIntegerField(blank=True, null=True)
    change_message = models.TextField(blank=True, null=True)
    content_type_id = models.BigIntegerField(blank=True, null=True)
    user_id = models.BigIntegerField(blank=True, null=True)
    action_time = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoApschedulerDjangojob(models.Model):
    id = models.TextField(unique=True, blank=True, null=True)
    next_run_time = models.DateTimeField(blank=True, null=True)
    job_state = models.BinaryField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_apscheduler_djangojob'


class DjangoApschedulerDjangojobexecution(models.Model):
    id = models.BigAutoField(unique=True)
    status = models.TextField(blank=True, null=True)
    run_time = models.DateTimeField(blank=True, null=True)
    duration = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    finished = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    exception = models.TextField(blank=True, null=True)
    traceback = models.TextField(blank=True, null=True)
    job_id = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_apscheduler_djangojobexecution'
        unique_together = (('job_id', 'run_time'),)


class DjangoContentType(models.Model):
    id = models.BigAutoField(unique=True)
    app_label = models.TextField(blank=True, null=True)
    model = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    id = models.BigAutoField(unique=True)
    app = models.TextField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    applied = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.TextField(unique=True, blank=True, null=True)
    session_data = models.TextField(blank=True, null=True)
    expire_date = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_session'


class DjangoSite(models.Model):
    id = models.BigAutoField(unique=True)
    name = models.TextField(blank=True, null=True)
    domain = models.TextField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'django_site'


class EmployeeActiontype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    action_type = models.TextField(blank=True, null=True)
    block_option = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_actiontype'


class EmployeeBonuspoint(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    points = models.BigIntegerField(blank=True, null=True)
    encashment_condition = models.TextField(blank=True, null=True)
    redeeming_points = models.BigIntegerField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_bonuspoint'


class EmployeeDisciplinaryaction(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    unit_in = models.TextField(blank=True, null=True)
    days = models.BigIntegerField(blank=True, null=True)
    hours = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    action_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_disciplinaryaction'


class EmployeeDisciplinaryactionEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    disciplinaryaction_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_disciplinaryaction_employee_id'


class EmployeeDocumentRequestsDocumentcategory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    head = models.TextField(blank=True, null=True)
    sub_category = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_document_requests_documentcategory'
        unique_together = (('head', 'sub_category'),)


class EmployeeDocumentRequestsEmployeedocumentrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    document_head = models.TextField(blank=True, null=True)
    document_sub = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    uploaded_document = models.TextField(blank=True, null=True)
    hr_comments = models.TextField(blank=True, null=True)
    requested_date = models.DateTimeField(blank=True, null=True)
    processed_date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    processed_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_document_requests_employeedocumentrequest'


class EmployeeEmployee(models.Model):
    id = models.BigAutoField(unique=True)
    badge_id = models.TextField(unique=True, blank=True, null=True)
    employee_first_name = models.TextField(blank=True, null=True)
    employee_last_name = models.TextField(blank=True, null=True)
    employee_profile = models.TextField(blank=True, null=True)
    email = models.TextField(unique=True, blank=True, null=True)
    phone = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    zip = models.TextField(blank=True, null=True)
    dob = models.DateField(blank=True, null=True)
    gender = models.TextField(blank=True, null=True)
    qualification = models.TextField(blank=True, null=True)
    marital_status = models.TextField(blank=True, null=True)
    children = models.BigIntegerField(blank=True, null=True)
    emergency_contact = models.TextField(blank=True, null=True)
    emergency_contact_name = models.TextField(blank=True, null=True)
    emergency_contact_relation = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    is_from_onboarding = models.BooleanField(blank=True, null=True)
    is_directly_converted = models.BooleanField(blank=True, null=True)
    employee_user_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    experience = models.FloatField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employee'
        unique_together = (('employee_first_name', 'employee_last_name', 'email'),)


class EmployeeEmployeebankdetails(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    bank_name = models.TextField(blank=True, null=True)
    account_number = models.TextField(blank=True, null=True)
    branch = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    any_other_code1 = models.TextField(blank=True, null=True)
    any_other_code2 = models.TextField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeebankdetails'


class EmployeeEmployeegeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    badge_id_prefix = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    employee_document_request_enabled = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeegeneralsetting'


class EmployeeEmployeenote(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    updated_by_id = models.BigIntegerField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeenote'


class EmployeeEmployeenoteNoteFiles(models.Model):
    id = models.BigAutoField(unique=True)
    employeenote_id = models.BigIntegerField(blank=True, null=True)
    notefiles_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeenote_note_files'
        unique_together = (('employeenote_id', 'notefiles_id'),)


class EmployeeEmployeetag(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeetag'


class EmployeeEmployeeworkinformation(models.Model):
    id = models.BigAutoField(unique=True)
    location = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    mobile = models.TextField(blank=True, null=True)
    date_joining = models.DateField(blank=True, null=True)
    contract_end_date = models.DateField(blank=True, null=True)
    basic_salary = models.BigIntegerField(blank=True, null=True)
    salary_hour = models.BigIntegerField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    experience = models.FloatField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    department_id_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    employee_type_id_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    job_role_id_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    performance_role_id = models.BigIntegerField(blank=True, null=True)
    ai_recruitment_role = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeeworkinformation'


class EmployeeEmployeeworkinformationTags(models.Model):
    id = models.BigAutoField(unique=True)
    employeeworkinformation_id = models.BigIntegerField(blank=True, null=True)
    employeetag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_employeeworkinformation_tags'


class EmployeeHistoricalbonuspoint(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    points = models.BigIntegerField(blank=True, null=True)
    encashment_condition = models.TextField(blank=True, null=True)
    redeeming_points = models.BigIntegerField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_historicalbonuspoint'


class EmployeeHistoricalbonuspointHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalbonuspoint_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_historicalbonuspoint_history_tags'


class EmployeeHistoricalemployeeworkinformation(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    location = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    mobile = models.TextField(blank=True, null=True)
    date_joining = models.DateField(blank=True, null=True)
    contract_end_date = models.DateField(blank=True, null=True)
    basic_salary = models.BigIntegerField(blank=True, null=True)
    salary_hour = models.BigIntegerField(blank=True, null=True)
    additional_info = models.TextField(blank=True, null=True)
    experience = models.FloatField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    department_id_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    employee_type_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    job_role_id_id = models.BigIntegerField(blank=True, null=True)
    reporting_manager_id_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    performance_role_id = models.BigIntegerField(blank=True, null=True)
    ai_recruitment_role = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_historicalemployeeworkinformation'


class EmployeeHistoricalemployeeworkinformationHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalemployeeworkinformation_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_historicalemployeeworkinformation_history_tags'


class EmployeeNotefiles(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    files = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_notefiles'


class EmployeePolicy(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    body = models.TextField(blank=True, null=True)
    is_visible_to_all = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    category_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policy'


class EmployeePolicyAttachments(models.Model):
    id = models.BigAutoField(unique=True)
    policy_id = models.BigIntegerField(blank=True, null=True)
    policymultiplefile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policy_attachments'
        unique_together = (('policy_id', 'policymultiplefile_id'),)


class EmployeePolicyCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    policy_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policy_company_id'
        unique_together = (('policy_id', 'company_id'),)


class EmployeePolicySpecificEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    policy_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policy_specific_employees'
        unique_together = (('policy_id', 'employee_id'),)


class EmployeePolicycategory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policycategory'


class EmployeePolicycategoryCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    policycategory_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policycategory_company_id'
        unique_together = (('policycategory_id', 'company_id'),)


class EmployeePolicymultiplefile(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_policymultiplefile'


class EmployeeProfileeditfeature(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'employee_profileeditfeature'


class FacedetectionEmployeefacedetection(models.Model):
    id = models.BigAutoField(unique=True)
    image = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'facedetection_employeefacedetection'


class FacedetectionFacedetection(models.Model):
    id = models.BigAutoField(unique=True)
    start = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'facedetection_facedetection'


class GeofencingGeofencing(models.Model):
    id = models.BigAutoField(unique=True)
    latitude = models.FloatField(blank=True, null=True)
    longitude = models.FloatField(blank=True, null=True)
    radius_in_meters = models.BigIntegerField(blank=True, null=True)
    start = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'geofencing_geofencing'


class HelpdeskAttachment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    file = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    format = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    comment_id = models.BigIntegerField(blank=True, null=True)
    ticket_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_attachment'


class HelpdeskClaimrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_approved = models.BooleanField(blank=True, null=True)
    is_rejected = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    ticket_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_claimrequest'
        unique_together = (('ticket_id_id', 'employee_id_id'),)


class HelpdeskComment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    ticket_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_comment'


class HelpdeskDepartmentmanager(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    manager_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_departmentmanager'
        unique_together = (('department_id', 'manager_id'),)


class HelpdeskFaq(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    question = models.TextField(blank=True, null=True)
    answer = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    category_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_faq'


class HelpdeskFaqTags(models.Model):
    id = models.BigAutoField(unique=True)
    faq_id = models.BigIntegerField(blank=True, null=True)
    tags_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_faq_tags'
        unique_together = (('faq_id', 'tags_id'),)


class HelpdeskFaqcategory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_faqcategory'


class HelpdeskHistoricalticket(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    priority = models.TextField(blank=True, null=True)
    created_date = models.DateField(blank=True, null=True)
    resolved_date = models.DateField(blank=True, null=True)
    assigning_type = models.TextField(blank=True, null=True)
    raised_on = models.TextField(blank=True, null=True)
    deadline = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    ticket_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_historicalticket'


class HelpdeskHistoricalticketHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalticket_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_historicalticket_history_tags'
        unique_together = (('historicalticket_id', 'audittag_id'),)


class HelpdeskTicket(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    priority = models.TextField(blank=True, null=True)
    created_date = models.DateField(blank=True, null=True)
    resolved_date = models.DateField(blank=True, null=True)
    assigning_type = models.TextField(blank=True, null=True)
    raised_on = models.TextField(blank=True, null=True)
    deadline = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    ticket_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket'


class HelpdeskTicketAssignedTo(models.Model):
    id = models.BigAutoField(unique=True)
    ticket_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket_assigned_to'
        unique_together = (('ticket_id', 'employee_id'),)


class HelpdeskTicketCcTo(models.Model):
    id = models.BigAutoField(unique=True)
    ticket_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket_cc_to'
        unique_together = (('ticket_id', 'employee_id'),)


class HelpdeskTicketTags(models.Model):
    id = models.BigAutoField(unique=True)
    ticket_id = models.BigIntegerField(blank=True, null=True)
    tags_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_ticket_tags'
        unique_together = (('ticket_id', 'tags_id'),)


class HelpdeskTickettype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(unique=True, blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    prefix = models.TextField(unique=True, blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'helpdesk_tickettype'


class HorillaAuditAccountblockunblock(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_audit_accountblockunblock'


class HorillaAuditAudittag(models.Model):
    id = models.BigAutoField(unique=True)
    title = models.TextField(blank=True, null=True)
    highlight = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_audit_audittag'


class HorillaAuditHistorytrackingfields(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    tracking_fields = models.TextField(blank=True, null=True)
    work_info_track = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_audit_historytrackingfields'


class HorillaAuthHorillauser(models.Model):
    id = models.BigAutoField(unique=True)
    password = models.TextField(blank=True, null=True)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.BooleanField(blank=True, null=True)
    username = models.TextField(unique=True, blank=True, null=True)
    first_name = models.TextField(blank=True, null=True)
    last_name = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    is_staff = models.BooleanField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    date_joined = models.DateTimeField(blank=True, null=True)
    is_new_employee = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_auth_horillauser'


class HorillaAuthHorillauserGroups(models.Model):
    id = models.BigAutoField(unique=True)
    horillauser_id = models.BigIntegerField(blank=True, null=True)
    group_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_auth_horillauser_groups'
        unique_together = (('horillauser_id', 'group_id'),)


class HorillaAuthHorillauserUserPermissions(models.Model):
    id = models.BigAutoField(unique=True)
    horillauser_id = models.BigIntegerField(blank=True, null=True)
    permission_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_auth_horillauser_user_permissions'
        unique_together = (('horillauser_id', 'permission_id'),)


class HorillaAutomationsMailautomation(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(unique=True, blank=True, null=True)
    method_title = models.TextField(blank=True, null=True)
    model = models.TextField(blank=True, null=True)
    mail_to = models.TextField(blank=True, null=True)
    mail_details = models.TextField(blank=True, null=True)
    mail_detail_choice = models.TextField(blank=True, null=True)
    trigger = models.TextField(blank=True, null=True)
    delivery_channel = models.TextField(blank=True, null=True)
    condition_html = models.TextField(blank=True, null=True)
    condition_querystring = models.TextField(blank=True, null=True)
    condition = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    mail_template_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_automations_mailautomation'


class HorillaAutomationsMailautomationAlsoSentTo(models.Model):
    id = models.BigAutoField(unique=True)
    mailautomation_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_automations_mailautomation_also_sent_to'
        unique_together = (('mailautomation_id', 'employee_id'),)


class HorillaAutomationsMailautomationTemplateAttachments(models.Model):
    id = models.BigAutoField()
    mailautomation_id = models.BigIntegerField(blank=True, null=True)
    horillamailtemplate_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_automations_mailautomation_template_attachments'


class HorillaBackupGoogledrivebackup(models.Model):
    id = models.BigAutoField(unique=True)
    service_account_file = models.TextField(blank=True, null=True)
    gdrive_folder_id = models.TextField(blank=True, null=True)
    backup_media = models.BooleanField(blank=True, null=True)
    backup_db = models.BooleanField(blank=True, null=True)
    interval = models.BooleanField(blank=True, null=True)
    fixed = models.BooleanField(blank=True, null=True)
    seconds = models.BigIntegerField(blank=True, null=True)
    hour = models.BigIntegerField(blank=True, null=True)
    minute = models.BigIntegerField(blank=True, null=True)
    active = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_backup_googledrivebackup'


class HorillaBackupLocalbackup(models.Model):
    id = models.BigAutoField(unique=True)
    backup_path = models.TextField(blank=True, null=True)
    backup_media = models.BooleanField(blank=True, null=True)
    backup_db = models.BooleanField(blank=True, null=True)
    interval = models.BooleanField(blank=True, null=True)
    fixed = models.BooleanField(blank=True, null=True)
    seconds = models.BigIntegerField(blank=True, null=True)
    hour = models.BigIntegerField(blank=True, null=True)
    minute = models.BigIntegerField(blank=True, null=True)
    active = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_backup_localbackup'


class HorillaDocumentsDocument(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    document = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    issue_date = models.DateField(blank=True, null=True)
    expiry_date = models.DateField(blank=True, null=True)
    notify_before = models.BigIntegerField(blank=True, null=True)
    is_digital_asset = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    document_request_id_id = models.BigIntegerField(blank=True, null=True)
    uploaded_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_documents_document'


class HorillaDocumentsDocumentrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    format = models.TextField(blank=True, null=True)
    max_size = models.BigIntegerField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_documents_documentrequest'


class HorillaDocumentsDocumentrequestEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    documentrequest_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_documents_documentrequest_employee_id'


class HorillaDocumentsDocumenttype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_documents_documenttype'
        unique_together = (('name', 'company_id_id'),)


class HorillaLdapLdapsettings(models.Model):
    id = models.BigAutoField(unique=True)
    ldap_server = models.TextField(blank=True, null=True)
    bind_dn = models.TextField(blank=True, null=True)
    bind_password = models.TextField(blank=True, null=True)
    base_dn = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_ldap_ldapsettings'


class HorillaLdapMicrosoftssosettings(models.Model):
    id = models.BigAutoField(unique=True)
    client_id = models.TextField(blank=True, null=True)
    client_secret = models.TextField(blank=True, null=True)
    tenant_id = models.TextField(blank=True, null=True)
    enabled = models.BooleanField(blank=True, null=True)
    auto_create_users = models.BooleanField(blank=True, null=True)
    redirect_uri = models.TextField(blank=True, null=True)
    require_verified_email = models.BooleanField(blank=True, null=True)
    allowed_domains = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    default_company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_ldap_microsoftssosettings'


class HorillaMeetGooglecloudcredential(models.Model):
    id = models.BigAutoField(unique=True)
    project_id = models.TextField(blank=True, null=True)
    client_id = models.TextField(blank=True, null=True)
    client_secret = models.TextField(blank=True, null=True)
    redirect_uris = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_meet_googlecloudcredential'
        unique_together = (('project_id', 'company_id_id'),)


class HorillaMeetGooglecredential(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    token = models.TextField(blank=True, null=True)
    refresh_token = models.TextField(blank=True, null=True)
    token_uri = models.TextField(blank=True, null=True)
    client_id = models.TextField(blank=True, null=True)
    client_secret = models.TextField(blank=True, null=True)
    scopes = models.TextField(blank=True, null=True)
    expires_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_meet_googlecredential'


class HorillaMeetGooglemeeting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    start_time = models.DateTimeField(blank=True, null=True)
    meet_url = models.TextField(blank=True, null=True)
    event_id = models.TextField(blank=True, null=True)
    duration = models.IntegerField(blank=True, null=True)
    attendees = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_meet_googlemeeting'


class HorillaMeetInterviewmeetinglink(models.Model):
    id = models.BigAutoField(unique=True)
    interview_id = models.BigIntegerField(unique=True, blank=True, null=True)
    meeting_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_meet_interviewmeetinglink'


class HorillaMeetPmsmeetinglink(models.Model):
    id = models.BigAutoField(unique=True)
    google_meeting_id = models.BigIntegerField(unique=True, blank=True, null=True)
    meeting_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_meet_pmsmeetinglink'


class HorillaViewsActivegroup(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    path = models.TextField(blank=True, null=True)
    group_target = models.TextField(blank=True, null=True)
    group_by_field = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_views_activegroup'


class HorillaViewsActivetab(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    path = models.TextField(blank=True, null=True)
    tab_target = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_views_activetab'


class HorillaViewsActiveview(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    path = models.TextField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_views_activeview'


class HorillaViewsSavedfilter(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    filter = models.TextField(blank=True, null=True)
    urlencode = models.TextField(blank=True, null=True)
    path = models.TextField(blank=True, null=True)
    referrer = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_views_savedfilter'


class HorillaViewsTogglecolumn(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    path = models.TextField(blank=True, null=True)
    excluded_columns = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    user_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'horilla_views_togglecolumn'


class LeaveAvailableleave(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    available_days = models.FloatField(blank=True, null=True)
    carryforward_days = models.FloatField(blank=True, null=True)
    total_leave_days = models.FloatField(blank=True, null=True)
    assigned_date = models.DateField(blank=True, null=True)
    reset_date = models.DateField(blank=True, null=True)
    expired_date = models.DateField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    last_accrual_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_availableleave'
        unique_together = (('leave_type_id_id', 'employee_id_id'),)


class LeaveCompanyleave(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    based_on_week = models.TextField(blank=True, null=True)
    based_on_week_day = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_companyleave'
        unique_together = (('based_on_week', 'based_on_week_day'),)


class LeaveCompensatoryleaverequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_compensatoryleaverequest'


class LeaveCompensatoryleaverequestAttendanceId(models.Model):
    id = models.BigAutoField(unique=True)
    compensatoryleaverequest_id = models.BigIntegerField(blank=True, null=True)
    attendance_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_compensatoryleaverequest_attendance_id'
        unique_together = (('compensatoryleaverequest_id', 'attendance_id'),)


class LeaveCompensatoryleaverequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_compensatoryleaverequestcomment'


class LeaveCompensatoryleaverequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    compensatoryleaverequestcomment_id = models.BigIntegerField(blank=True, null=True)
    leaverequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_compensatoryleaverequestcomment_files'


class LeaveEmployeepastleaverestrict(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    enabled = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_employeepastleaverestrict'


class LeaveHistoricalavailableleave(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    available_days = models.FloatField(blank=True, null=True)
    carryforward_days = models.FloatField(blank=True, null=True)
    total_leave_days = models.FloatField(blank=True, null=True)
    assigned_date = models.DateField(blank=True, null=True)
    reset_date = models.DateField(blank=True, null=True)
    expired_date = models.DateField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    last_accrual_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalavailableleave'


class LeaveHistoricalavailableleaveHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalavailableleave_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalavailableleave_history_tags'
        unique_together = (('historicalavailableleave_id', 'audittag_id'),)


class LeaveHistoricalcompensatoryleaverequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalcompensatoryleaverequest'


class LeaveHistoricalcompensatoryleaverequestHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalcompensatoryleaverequest_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalcompensatoryleaverequest_history_tags'


class LeaveHistoricalleaveallocationrequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalleaveallocationrequest'


class LeaveHistoricalleaveallocationrequestHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalleaveallocationrequest_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalleaveallocationrequest_history_tags'


class LeaveHistoricalleaverequest(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    start_date_breakdown = models.TextField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    end_date_breakdown = models.TextField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    leave_clashes_count = models.BigIntegerField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    approved_available_days = models.FloatField(blank=True, null=True)
    approved_carryforward_days = models.FloatField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    compensatory_work_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalleaverequest'


class LeaveHistoricalleaverequestHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalleaverequest_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_historicalleaverequest_history_tags'


class LeaveHoliday(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    recurring = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_holiday'


class LeaveLeaveallocationrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaveallocationrequest'


class LeaveLeaveallocationrequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaveallocationrequestcomment'


class LeaveLeaveallocationrequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    leaveallocationrequestcomment_id = models.BigIntegerField(blank=True, null=True)
    leaverequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaveallocationrequestcomment_files'
        unique_together = (('leaveallocationrequestcomment_id', 'leaverequestfile_id'),)


class LeaveLeavegeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    compensatory_leave = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    reset_based = models.TextField(blank=True, null=True)
    reset_day = models.TextField(blank=True, null=True)
    reset_month = models.TextField(blank=True, null=True)
    reset_weekend = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leavegeneralsetting'


class LeaveLeaverequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    start_date_breakdown = models.TextField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    end_date_breakdown = models.TextField(blank=True, null=True)
    requested_days = models.FloatField(blank=True, null=True)
    leave_clashes_count = models.BigIntegerField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    requested_date = models.DateField(blank=True, null=True)
    approved_available_days = models.FloatField(blank=True, null=True)
    approved_carryforward_days = models.FloatField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    compensatory_work_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequest'


class LeaveLeaverequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequestcomment'


class LeaveLeaverequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    leaverequestcomment_id = models.BigIntegerField(blank=True, null=True)
    leaverequestfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequestcomment_files'
        unique_together = (('leaverequestcomment_id', 'leaverequestfile_id'),)


class LeaveLeaverequestconditionapproval(models.Model):
    id = models.BigAutoField(unique=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    is_approved = models.BooleanField(blank=True, null=True)
    is_rejected = models.BooleanField(blank=True, null=True)
    leave_request_id_id = models.BigIntegerField(blank=True, null=True)
    manager_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequestconditionapproval'


class LeaveLeaverequestfile(models.Model):
    id = models.BigAutoField(unique=True)
    file = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leaverequestfile'


class LeaveLeavetype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    icon = models.TextField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    color = models.TextField(blank=True, null=True)
    payment = models.TextField(blank=True, null=True)
    count = models.FloatField(blank=True, null=True)
    period_in = models.TextField(blank=True, null=True)
    limit_leave = models.BooleanField(blank=True, null=True)
    total_days = models.FloatField(blank=True, null=True)
    reset = models.BooleanField(blank=True, null=True)
    is_encashable = models.BooleanField(blank=True, null=True)
    reset_based = models.TextField(blank=True, null=True)
    reset_month = models.TextField(blank=True, null=True)
    reset_day = models.TextField(blank=True, null=True)
    reset_weekend = models.TextField(blank=True, null=True)
    carryforward_type = models.TextField(blank=True, null=True)
    carryforward_max = models.FloatField(blank=True, null=True)
    carryforward_expire_in = models.BigIntegerField(blank=True, null=True)
    carryforward_expire_period = models.TextField(blank=True, null=True)
    carryforward_expire_date = models.DateField(blank=True, null=True)
    require_approval = models.TextField(blank=True, null=True)
    require_attachment = models.TextField(blank=True, null=True)
    exclude_company_leave = models.TextField(blank=True, null=True)
    exclude_holiday = models.TextField(blank=True, null=True)
    is_compensatory_leave = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    allow_new_employee = models.BooleanField(blank=True, null=True)
    for_probation_employee = models.BooleanField(blank=True, null=True)
    is_monthly_based = models.BooleanField(blank=True, null=True)
    requires_one_year_service = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_leavetype'


class LeaveOverrideleaverequests(models.Model):
    leaverequest_ptr_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_overrideleaverequests'


class LeaveRestrictleave(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    include_all = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_restrictleave'


class LeaveRestrictleaveExcluedLeaveTypes(models.Model):
    id = models.BigAutoField(unique=True)
    restrictleave_id = models.BigIntegerField(blank=True, null=True)
    leavetype_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_restrictleave_exclued_leave_types'
        unique_together = (('restrictleave_id', 'leavetype_id'),)


class LeaveRestrictleaveJobPosition(models.Model):
    id = models.BigAutoField(unique=True)
    restrictleave_id = models.BigIntegerField(blank=True, null=True)
    jobposition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_restrictleave_job_position'
        unique_together = (('restrictleave_id', 'jobposition_id'),)


class LeaveRestrictleaveSpesificLeaveTypes(models.Model):
    id = models.BigAutoField(unique=True)
    restrictleave_id = models.BigIntegerField(blank=True, null=True)
    leavetype_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'leave_restrictleave_spesific_leave_types'


class MicrosoftAuthMicrosoftaccount(models.Model):
    id = models.BigAutoField(unique=True)
    microsoft_id = models.TextField(blank=True, null=True)
    user_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'microsoft_auth_microsoftaccount'


class MicrosoftAuthXboxliveaccount(models.Model):
    id = models.BigAutoField(unique=True)
    xbox_id = models.TextField(unique=True, blank=True, null=True)
    gamertag = models.TextField(blank=True, null=True)
    user_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'microsoft_auth_xboxliveaccount'


class MonthlyPerformanceEmployeekraresponse(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    self_rating = models.IntegerField(blank=True, null=True)
    weighted_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    kra_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    monthly_review_id = models.BigIntegerField(blank=True, null=True)
    employee_comments = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_employeekraresponse'


class MonthlyPerformanceManagerkrareview(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    manager_rating = models.IntegerField(blank=True, null=True)
    weighted_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    review_date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    kra_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    monthly_review_id = models.BigIntegerField(blank=True, null=True)
    reviewed_by_id = models.BigIntegerField(blank=True, null=True)
    manager_comments = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_managerkrareview'
        unique_together = (('monthly_review_id', 'kra_id'),)


class MonthlyPerformanceMonthlyreview(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    review_month = models.IntegerField(blank=True, null=True)
    review_year = models.IntegerField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    submission_date = models.DateTimeField(blank=True, null=True)
    manager_review_date = models.DateTimeField(blank=True, null=True)
    completion_date = models.DateTimeField(blank=True, null=True)
    employee_total_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    manager_total_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    performance_role_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_monthlyreview'
        unique_together = (('employee_id', 'review_month', 'review_year'),)


class MonthlyPerformancePerformancekra(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    kra_title = models.TextField(blank=True, null=True)
    kra_description = models.TextField(blank=True, null=True)
    weightage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    order = models.IntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    role_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_performancekra'
        unique_together = (('role_id', 'kra_title'),)


class MonthlyPerformancePerformancekraCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    performancekra_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_performancekra_company_id'


class MonthlyPerformancePerformancerole(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    role_name = models.TextField(unique=True, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_performancerole'


class MonthlyPerformancePerformanceroleCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    performancerole_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_performancerole_company_id'


class MonthlyPerformanceYearendconsolidation(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    year = models.IntegerField(blank=True, null=True)
    average_self_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    average_manager_score = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    months_completed = models.IntegerField(blank=True, null=True)
    completion_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    generated_date = models.DateTimeField(blank=True, null=True)
    updated_date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    performance_role_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'monthly_performance_yearendconsolidation'
        unique_together = (('employee_id', 'year'),)


class NotificationsNotification(models.Model):
    id = models.BigAutoField(unique=True)
    level = models.TextField(blank=True, null=True)
    unread = models.BooleanField(blank=True, null=True)
    actor_object_id = models.TextField(blank=True, null=True)
    verb = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    target_object_id = models.TextField(blank=True, null=True)
    action_object_object_id = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(blank=True, null=True)
    public = models.BooleanField(blank=True, null=True)
    deleted = models.BooleanField(blank=True, null=True)
    emailed = models.BooleanField(blank=True, null=True)
    data = models.TextField(blank=True, null=True)
    verb_en = models.TextField(blank=True, null=True)
    verb_ar = models.TextField(blank=True, null=True)
    verb_de = models.TextField(blank=True, null=True)
    verb_es = models.TextField(blank=True, null=True)
    verb_fr = models.TextField(blank=True, null=True)
    action_object_content_type_id = models.BigIntegerField(blank=True, null=True)
    actor_content_type_id = models.BigIntegerField(blank=True, null=True)
    recipient_id = models.BigIntegerField(blank=True, null=True)
    target_content_type_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'notifications_notification'


class OffboardingEmployeetask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    task_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_employeetask'
        unique_together = (('employee_id_id', 'task_id_id'),)


class OffboardingExitreason(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    offboarding_employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_exitreason'


class OffboardingExitreasonAttachments(models.Model):
    id = models.BigAutoField(unique=True)
    exitreason_id = models.BigIntegerField(blank=True, null=True)
    offboardingstagemultiplefile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_exitreason_attachments'
        unique_together = (('exitreason_id', 'offboardingstagemultiplefile_id'),)


class OffboardingHistoricalemployeetask(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    task_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_historicalemployeetask'


class OffboardingHistoricalemployeetaskHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalemployeetask_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_historicalemployeetask_history_tags'


class OffboardingOffboarding(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboarding'


class OffboardingOffboardingManagers(models.Model):
    id = models.BigAutoField(unique=True)
    offboarding_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboarding_managers'
        unique_together = (('offboarding_id', 'employee_id'),)


class OffboardingOffboardingemployee(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    notice_period = models.BigIntegerField(blank=True, null=True)
    unit = models.TextField(blank=True, null=True)
    notice_period_starts = models.DateField(blank=True, null=True)
    notice_period_ends = models.DateField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingemployee'


class OffboardingOffboardinggeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    resignation_request = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardinggeneralsetting'


class OffboardingOffboardingnote(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    note_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingnote'


class OffboardingOffboardingnoteAttachments(models.Model):
    id = models.BigAutoField(unique=True)
    offboardingnote_id = models.BigIntegerField(blank=True, null=True)
    offboardingstagemultiplefile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingnote_attachments'


class OffboardingOffboardingstage(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    offboarding_id_id = models.BigIntegerField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingstage'


class OffboardingOffboardingstageManagers(models.Model):
    id = models.BigAutoField(unique=True)
    offboardingstage_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingstage_managers'


class OffboardingOffboardingstagemultiplefile(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingstagemultiplefile'


class OffboardingOffboardingtask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingtask'
        unique_together = (('title', 'stage_id_id'),)


class OffboardingOffboardingtaskManagers(models.Model):
    id = models.BigAutoField(unique=True)
    offboardingtask_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_offboardingtask_managers'
        unique_together = (('offboardingtask_id', 'employee_id'),)


class OffboardingResignationletter(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    planned_to_leave_on = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    offboarding_employee_id_id = models.BigIntegerField(blank=True, null=True)
    withdrawal_reason = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'offboarding_resignationletter'


class OnboardingCandidatestage(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    onboarding_end_date = models.DateField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    onboarding_stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_candidatestage'


class OnboardingCandidatetask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)
    onboarding_task_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_candidatetask'


class OnboardingHistoricalcandidatetask(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)
    onboarding_task_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_historicalcandidatetask'


class OnboardingHistoricalcandidatetaskHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalcandidatetask_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_historicalcandidatetask_history_tags'


class OnboardingOnboardingportal(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    token = models.TextField(blank=True, null=True)
    used = models.BooleanField(blank=True, null=True)
    count = models.BigIntegerField(blank=True, null=True)
    profile = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingportal'


class OnboardingOnboardingstage(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    stage_title = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    is_final_stage = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingstage'


class OnboardingOnboardingstageEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    onboardingstage_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingstage_employee_id'


class OnboardingOnboardingtask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    task_title = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingtask'


class OnboardingOnboardingtaskCandidates(models.Model):
    id = models.BigAutoField(unique=True)
    onboardingtask_id = models.BigIntegerField(blank=True, null=True)
    candidate_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingtask_candidates'


class OnboardingOnboardingtaskEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    onboardingtask_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'onboarding_onboardingtask_employee_id'


class PayrollAllowance(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    one_time_date = models.DateField(blank=True, null=True)
    include_active_employees = models.BooleanField(blank=True, null=True)
    is_taxable = models.BooleanField(blank=True, null=True)
    is_condition_based = models.BooleanField(blank=True, null=True)
    field = models.TextField(blank=True, null=True)
    condition = models.TextField(blank=True, null=True)
    value = models.TextField(blank=True, null=True)
    is_fixed = models.BooleanField(blank=True, null=True)
    amount = models.FloatField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rate = models.FloatField(blank=True, null=True)
    per_attendance_fixed_amount = models.FloatField(blank=True, null=True)
    per_children_fixed_amount = models.FloatField(blank=True, null=True)
    shift_per_attendance_amount = models.FloatField(blank=True, null=True)
    amount_per_one_hr = models.FloatField(blank=True, null=True)
    work_type_per_attendance_amount = models.FloatField(blank=True, null=True)
    has_max_limit = models.BooleanField(blank=True, null=True)
    maximum_amount = models.FloatField(blank=True, null=True)
    maximum_unit = models.TextField(blank=True, null=True)
    if_choice = models.TextField(blank=True, null=True)
    if_condition = models.TextField(blank=True, null=True)
    if_amount = models.FloatField(blank=True, null=True)
    start_range = models.FloatField(blank=True, null=True)
    end_range = models.FloatField(blank=True, null=True)
    only_show_under_employee = models.BooleanField(blank=True, null=True)
    is_loan = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id_id = models.BigIntegerField(blank=True, null=True)
    work_type_id_id = models.BigIntegerField(blank=True, null=True)
    is_processed = models.BooleanField(blank=True, null=True)
    processed_at = models.DateTimeField(blank=True, null=True)
    processed_in_payslip_id = models.BigIntegerField(blank=True, null=True)
    is_incentive = models.BooleanField(blank=True, null=True)
    is_component_type = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_allowance'
        unique_together = (('title', 'is_taxable', 'is_condition_based', 'field', 'condition', 'value', 'is_fixed', 'amount', 'based_on', 'rate', 'per_attendance_fixed_amount', 'shift_id_id', 'shift_per_attendance_amount', 'amount_per_one_hr', 'work_type_id_id', 'work_type_per_attendance_amount'),)


class PayrollAllowanceExcludeEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    allowance_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_allowance_exclude_employees'
        unique_together = (('allowance_id', 'employee_id'),)


class PayrollAllowanceOtherConditions(models.Model):
    id = models.BigAutoField(unique=True)
    allowance_id = models.BigIntegerField(blank=True, null=True)
    multiplecondition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_allowance_other_conditions'
        unique_together = (('allowance_id', 'multiplecondition_id'),)


class PayrollAllowanceSpecificEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    allowance_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_allowance_specific_employees'
        unique_together = (('allowance_id', 'employee_id'),)


class PayrollContract(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    contract_name = models.TextField(blank=True, null=True)
    contract_start_date = models.DateField(blank=True, null=True)
    contract_end_date = models.DateField(blank=True, null=True)
    wage_type = models.TextField(blank=True, null=True)
    pay_frequency = models.TextField(blank=True, null=True)
    wage = models.FloatField(blank=True, null=True)
    contract_status = models.TextField(blank=True, null=True)
    notice_period_in_days = models.BigIntegerField(blank=True, null=True)
    contract_document = models.TextField(blank=True, null=True)
    deduct_leave_from_basic_pay = models.BooleanField(blank=True, null=True)
    calculate_daily_leave_amount = models.BooleanField(blank=True, null=True)
    deduction_for_one_leave_amount = models.FloatField(blank=True, null=True)
    note = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    filing_status_id = models.BigIntegerField(blank=True, null=True)
    job_position_id = models.BigIntegerField(blank=True, null=True)
    job_role_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id = models.BigIntegerField(blank=True, null=True)
    work_type_id = models.BigIntegerField(blank=True, null=True)
    enable_tds_calculation = models.BooleanField(blank=True, null=True)
    professional_tax_state = models.TextField(blank=True, null=True)
    tds_regime_id = models.BigIntegerField(blank=True, null=True)
    ctc = models.FloatField(blank=True, null=True)
    payroll_structure_id = models.BigIntegerField(blank=True, null=True)
    variable_pay = models.FloatField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_contract'
        unique_together = (('employee_id_id', 'contract_start_date', 'contract_end_date'),)


class PayrollCountry(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    code = models.TextField(unique=True, blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    currency_code = models.TextField(blank=True, null=True)
    has_regional_tax = models.BooleanField(blank=True, null=True)
    regional_tax_name = models.TextField(blank=True, null=True)
    tax_calculation_module = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_country'


class PayrollDeduction(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    one_time_date = models.DateField(blank=True, null=True)
    include_active_employees = models.BooleanField(blank=True, null=True)
    is_tax = models.BooleanField(blank=True, null=True)
    is_pretax = models.BooleanField(blank=True, null=True)
    is_condition_based = models.BooleanField(blank=True, null=True)
    field = models.TextField(blank=True, null=True)
    condition = models.TextField(blank=True, null=True)
    value = models.TextField(blank=True, null=True)
    update_compensation = models.TextField(blank=True, null=True)
    is_fixed = models.BooleanField(blank=True, null=True)
    amount = models.FloatField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    rate = models.FloatField(blank=True, null=True)
    employer_rate = models.FloatField(blank=True, null=True)
    has_max_limit = models.BooleanField(blank=True, null=True)
    maximum_amount = models.FloatField(blank=True, null=True)
    maximum_unit = models.TextField(blank=True, null=True)
    if_choice = models.TextField(blank=True, null=True)
    if_condition = models.TextField(blank=True, null=True)
    if_amount = models.FloatField(blank=True, null=True)
    start_range = models.FloatField(blank=True, null=True)
    end_range = models.FloatField(blank=True, null=True)
    only_show_under_employee = models.BooleanField(blank=True, null=True)
    is_installment = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    is_processed = models.BooleanField(blank=True, null=True)
    processed_at = models.DateTimeField(blank=True, null=True)
    processed_in_payslip_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_deduction'


class PayrollDeductionExcludeEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_deduction_exclude_employees'
        unique_together = (('deduction_id', 'employee_id'),)


class PayrollDeductionOtherConditions(models.Model):
    id = models.BigAutoField(unique=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)
    multiplecondition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_deduction_other_conditions'
        unique_together = (('deduction_id', 'multiplecondition_id'),)


class PayrollDeductionSpecificEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_deduction_specific_employees'
        unique_together = (('deduction_id', 'employee_id'),)


class PayrollEmployeetaxdeclaration(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    region_code = models.TextField(blank=True, null=True)
    deductions = models.TextField(blank=True, null=True)
    is_locked = models.BooleanField(blank=True, null=True)
    locked_at = models.DateTimeField(blank=True, null=True)
    country_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    locked_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    selected_regime_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_employeetaxdeclaration'
        unique_together = (('employee_id_id', 'financial_year'),)


class PayrollEmployeetdsdeclaration(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    section_80c_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    is_locked = models.BooleanField(blank=True, null=True)
    declaration_date = models.DateField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    selected_regime_id = models.BigIntegerField(blank=True, null=True)
    approval_date = models.DateTimeField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    state_code = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_employeetdsdeclaration'
        unique_together = (('employee_id_id', 'financial_year'),)


class PayrollEncashmentgeneralsettings(models.Model):
    id = models.BigAutoField(unique=True)
    bonus_amount = models.BigIntegerField(blank=True, null=True)
    leave_amount = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_encashmentgeneralsettings'


class PayrollFilingstatus(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    filing_status = models.TextField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    use_py = models.BooleanField(blank=True, null=True)
    python_code = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_filingstatus'


class PayrollHistoricalcontract(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    contract_name = models.TextField(blank=True, null=True)
    contract_start_date = models.DateField(blank=True, null=True)
    contract_end_date = models.DateField(blank=True, null=True)
    wage_type = models.TextField(blank=True, null=True)
    pay_frequency = models.TextField(blank=True, null=True)
    wage = models.FloatField(blank=True, null=True)
    contract_status = models.TextField(blank=True, null=True)
    notice_period_in_days = models.BigIntegerField(blank=True, null=True)
    contract_document = models.TextField(blank=True, null=True)
    deduct_leave_from_basic_pay = models.BooleanField(blank=True, null=True)
    calculate_daily_leave_amount = models.BooleanField(blank=True, null=True)
    deduction_for_one_leave_amount = models.FloatField(blank=True, null=True)
    note = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    department_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    filing_status_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    job_position_id = models.BigIntegerField(blank=True, null=True)
    job_role_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    shift_id = models.BigIntegerField(blank=True, null=True)
    work_type_id = models.BigIntegerField(blank=True, null=True)
    enable_tds_calculation = models.BooleanField(blank=True, null=True)
    professional_tax_state = models.TextField(blank=True, null=True)
    tds_regime_id = models.BigIntegerField(blank=True, null=True)
    ctc = models.FloatField(blank=True, null=True)
    payroll_structure_id = models.BigIntegerField(blank=True, null=True)
    variable_pay = models.FloatField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_historicalcontract'


class PayrollHistoricalcontractHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalcontract_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_historicalcontract_history_tags'


class PayrollHistoricalpayslip(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    group_name = models.TextField(blank=True, null=True)
    reference = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    pay_head_data = models.TextField(blank=True, null=True)
    contract_wage = models.FloatField(blank=True, null=True)
    basic_pay = models.FloatField(blank=True, null=True)
    gross_pay = models.FloatField(blank=True, null=True)
    deduction = models.FloatField(blank=True, null=True)
    net_pay = models.FloatField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    sent_to_employee = models.BooleanField(blank=True, null=True)
    generation_type = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_historicalpayslip'


class PayrollHistoricalpayslipHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalpayslip_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_historicalpayslip_history_tags'


class PayrollIndiantdsregime(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    regime_name = models.TextField(blank=True, null=True)
    regime_code = models.TextField(unique=True, blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    standard_deduction = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    is_proof_required = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    apply_section_87a = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_indiantdsregime'


class PayrollIndiantdstaxslab(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    min_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tax_rate = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    regime_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_indiantdstaxslab'


class PayrollLoanaccount(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    loan_amount = models.FloatField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_fixed = models.BooleanField(blank=True, null=True)
    rate = models.FloatField(blank=True, null=True)
    installment_amount = models.FloatField(blank=True, null=True)
    installments = models.BigIntegerField(blank=True, null=True)
    installment_start_date = models.DateField(blank=True, null=True)
    apply_on = models.TextField(blank=True, null=True)
    settled = models.BooleanField(blank=True, null=True)
    settled_date = models.DateTimeField(blank=True, null=True)
    allowance_id_id = models.BigIntegerField(blank=True, null=True)
    asset_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    provided_date = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_loanaccount'


class PayrollLoanaccountDeductionIds(models.Model):
    id = models.BigAutoField(unique=True)
    loanaccount_id = models.BigIntegerField(blank=True, null=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_loanaccount_deduction_ids'
        unique_together = (('loanaccount_id', 'deduction_id'),)


class PayrollMultiplecondition(models.Model):
    id = models.BigAutoField(unique=True)
    field = models.TextField(blank=True, null=True)
    condition = models.TextField(blank=True, null=True)
    value = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_multiplecondition'


class PayrollOverrideattendance(models.Model):
    attendance_ptr_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_overrideattendance'


class PayrollOverrideleaverequest(models.Model):
    leaverequest_ptr_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_overrideleaverequest'


class PayrollPayrollattachment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    file = models.TextField(blank=True, null=True)
    file_name = models.TextField(blank=True, null=True)
    attachment_type = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    uploaded_at = models.DateTimeField(blank=True, null=True)
    file_size = models.IntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)
    uploaded_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollattachment'


class PayrollPayrollcomment(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment_type = models.TextField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_private = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollcomment'


class PayrollPayrollcomponentv2(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    component_name = models.TextField(blank=True, null=True)
    component_type = models.TextField(blank=True, null=True)
    section = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_taxable = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollcomponentv2'
        unique_together = (('component_name', 'component_type', 'company_id'),)


class PayrollPayrolldata(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    employee_name = models.TextField(blank=True, null=True)
    employee_code = models.TextField(blank=True, null=True)
    bank_account_number = models.TextField(blank=True, null=True)
    bank_code = models.TextField(blank=True, null=True)
    department = models.TextField(blank=True, null=True)
    designation = models.TextField(blank=True, null=True)
    basic_salary = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    hra = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    transport_allowance = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    medical_allowance = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    special_allowance = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    other_allowances = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    gross_salary = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    arrear = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    overtime_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    bonus = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    loss_of_pay = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    professional_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    income_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_employee = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_employer = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    esi_employee = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    esi_employer = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    loan_deduction = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    other_deductions = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_deductions = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    net_payable = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    earned_leave = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    casual_leave = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    sick_leave = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_working_days = models.BigIntegerField(blank=True, null=True)
    present_days = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    absent_days = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    remarks = models.TextField(blank=True, null=True)
    is_final_settlement = models.BooleanField(blank=True, null=True)
    is_hold = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)
    updated_by_id = models.BigIntegerField(blank=True, null=True)
    contract_id_at_creation_id = models.BigIntegerField(blank=True, null=True)
    is_locked = models.BooleanField(blank=True, null=True)
    locked_at = models.DateTimeField(blank=True, null=True)
    locked_by_id = models.BigIntegerField(blank=True, null=True)
    da = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    other_incentives = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    calculation_pending = models.BooleanField(blank=True, null=True)
    lop_breakdown = models.TextField(blank=True, null=True)
    ceo_validated = models.BooleanField(blank=True, null=True)
    ceo_validated_at = models.DateTimeField(blank=True, null=True)
    ceo_validated_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldata'
        unique_together = (('payroll_period_id', 'employee_id'),)


class PayrollPayrolldataAllowancesApplied(models.Model):
    id = models.BigAutoField(unique=True)
    payrolldata_id = models.BigIntegerField(blank=True, null=True)
    allowance_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldata_allowances_applied'
        unique_together = (('payrolldata_id', 'allowance_id'),)


class PayrollPayrolldataDeductionsApplied(models.Model):
    id = models.BigAutoField(unique=True)
    payrolldata_id = models.BigIntegerField(blank=True, null=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldata_deductions_applied'
        unique_together = (('payrolldata_id', 'deduction_id'),)


class PayrollPayrolldataIncentivesApplied(models.Model):
    id = models.BigAutoField(unique=True)
    payrolldata_id = models.BigIntegerField(blank=True, null=True)
    allowance_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldata_incentives_applied'
        unique_together = (('payrolldata_id', 'allowance_id'),)


class PayrollPayrolldataLoanInstallmentsApplied(models.Model):
    id = models.BigAutoField(unique=True)
    payrolldata_id = models.BigIntegerField(blank=True, null=True)
    loanaccount_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldata_loan_installments_applied'


class PayrollPayrolldatalineitem(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    component_name = models.TextField(blank=True, null=True)
    component_type = models.TextField(blank=True, null=True)
    section = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    calculation_base = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_data_id = models.BigIntegerField(blank=True, null=True)
    component_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrolldatalineitem'
        unique_together = (('payroll_data_id', 'component_id'),)


class PayrollPayrollemaillog(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    email_type = models.TextField(blank=True, null=True)
    recipient_email = models.TextField(blank=True, null=True)
    recipient_name = models.TextField(blank=True, null=True)
    subject = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    sent_at = models.DateTimeField(blank=True, null=True)
    delivered_at = models.DateTimeField(blank=True, null=True)
    error_message = models.TextField(blank=True, null=True)
    attachment_name = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollemaillog'


class PayrollPayrollemailtemplate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    template_type = models.TextField(unique=True, blank=True, null=True)
    subject = models.TextField(blank=True, null=True)
    html_content = models.TextField(blank=True, null=True)
    text_content = models.TextField(blank=True, null=True)
    cc_hr = models.BooleanField(blank=True, null=True)
    cc_finance = models.BooleanField(blank=True, null=True)
    cc_ceo = models.BooleanField(blank=True, null=True)
    cc_custom_emails = models.TextField(blank=True, null=True)
    bcc_hr = models.BooleanField(blank=True, null=True)
    bcc_finance = models.BooleanField(blank=True, null=True)
    bcc_ceo = models.BooleanField(blank=True, null=True)
    bcc_custom_emails = models.TextField(blank=True, null=True)
    is_enabled = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollemailtemplate'


class PayrollPayrollemployeevalidation(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    overall_status = models.TextField(blank=True, null=True)
    attendance_status = models.TextField(blank=True, null=True)
    attendance_total_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_required_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_deficit_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_working_days = models.BigIntegerField(blank=True, null=True)
    attendance_daily_breakdown = models.TextField(blank=True, null=True)
    timesheet_status = models.TextField(blank=True, null=True)
    timesheet_total_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    timesheet_required_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    timesheet_deficit_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    timesheet_daily_breakdown = models.TextField(blank=True, null=True)
    leave_status = models.TextField(blank=True, null=True)
    leave_days_taken = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    leave_exceeded_balance = models.BooleanField(blank=True, null=True)
    leave_breakdown = models.TextField(blank=True, null=True)
    permission_status = models.TextField(blank=True, null=True)
    permission_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    permission_breakdown = models.TextField(blank=True, null=True)
    requires_manager_approval = models.BooleanField(blank=True, null=True)
    manager_approved = models.BooleanField(blank=True, null=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    approval_notes = models.TextField(blank=True, null=True)
    validated_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)
    attendance_reporting_days = models.BigIntegerField(blank=True, null=True)
    leave_available_balance = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_checkin_days = models.BigIntegerField(blank=True, null=True)
    attendance_approved_leave_days = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_absent_days = models.BigIntegerField(blank=True, null=True)
    attendance_lop_days = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    attendance_payable_days = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollemployeevalidation'


class PayrollPayrollgeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    notice_period = models.BigIntegerField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollgeneralsetting'


class PayrollPayrollperiod(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    period_name = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    total_employees = models.BigIntegerField(blank=True, null=True)
    total_gross_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_deductions = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_net_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    submitted_at = models.DateTimeField(blank=True, null=True)
    finance_reviewed_at = models.DateTimeField(blank=True, null=True)
    finance_comments = models.TextField(blank=True, null=True)
    ceo_approved_at = models.DateTimeField(blank=True, null=True)
    ceo_comments = models.TextField(blank=True, null=True)
    executive_override = models.BooleanField(blank=True, null=True)
    generation_errors = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    ceo_approved_by_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    finance_reviewed_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    validation_completed = models.BooleanField(blank=True, null=True)
    calculation_pending = models.BooleanField(blank=True, null=True)
    period_month = models.BigIntegerField(blank=True, null=True)
    period_year = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollperiod'
        unique_together = (('period_name', 'company_id'),)


class PayrollPayrollrole(models.Model):
    id = models.BigAutoField(unique=True)
    role_name = models.TextField(unique=True, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    permissions = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollrole'


class PayrollPayrollruleconfig(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    basic_salary_min_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    basic_salary_max_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    hra_metro_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    hra_non_metro_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    da_max_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_threshold_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_employee_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_employer_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    pf_fixed_amount_above_threshold = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    esi_threshold_gross = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    esi_employee_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    esi_employer_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    company_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollruleconfig'


class PayrollPayrollrulevalidationlog(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    validation_context = models.TextField(blank=True, null=True)
    severity = models.TextField(blank=True, null=True)
    rule_name = models.TextField(blank=True, null=True)
    rule_message = models.TextField(blank=True, null=True)
    expected_value = models.TextField(blank=True, null=True)
    actual_value = models.TextField(blank=True, null=True)
    validation_data = models.TextField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    contract_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    structure_id = models.BigIntegerField(blank=True, null=True)
    validated_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollrulevalidationlog'


class PayrollPayrollsettings(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    currency_symbol = models.TextField(blank=True, null=True)
    position = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollsettings'


class PayrollPayrollstatutorysettings(models.Model):
    id = models.BigAutoField(unique=True)
    enable_tds = models.BooleanField(blank=True, null=True)
    enable_professional_tax = models.BooleanField(blank=True, null=True)
    enable_pf = models.BooleanField(blank=True, null=True)
    enable_esi = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    default_required_hours_per_day = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    enable_validation_wizard = models.BooleanField(blank=True, null=True)
    cutoff_date = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollstatutorysettings'


class PayrollPayrollstructurelinev2(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    component_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    structure_id = models.BigIntegerField(blank=True, null=True)
    pf_config_mode = models.TextField(blank=True, null=True)
    pf_custom_percentage = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    is_unified_pf = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollstructurelinev2'
        unique_together = (('structure_id', 'component_id'),)


class PayrollPayrollstructurev2(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    structure_title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollstructurev2'
        unique_together = (('structure_title', 'company_id'),)


class PayrollPayrollvalidationconfig(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    require_validation = models.BooleanField(blank=True, null=True)
    deviation_threshold_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    company_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    attendance_required_hours_per_day = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    blocking_mode = models.TextField(blank=True, null=True)
    enable_attendance_validation = models.BooleanField(blank=True, null=True)
    enable_leave_validation = models.BooleanField(blank=True, null=True)
    enable_permission_validation = models.BooleanField(blank=True, null=True)
    enable_timesheet_validation = models.BooleanField(blank=True, null=True)
    timesheet_matches_attendance = models.BooleanField(blank=True, null=True)
    use_shift_based_hours = models.BooleanField(blank=True, null=True)
    send_email_to_managers = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollvalidationconfig'


class PayrollPayrollvalidationrecord(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    validated_at = models.DateTimeField(blank=True, null=True)
    total_employees = models.BigIntegerField(blank=True, null=True)
    valid_count = models.BigIntegerField(blank=True, null=True)
    deviation_count = models.BigIntegerField(blank=True, null=True)
    missing_data_count = models.BigIntegerField(blank=True, null=True)
    validation_data = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    validated_by_id = models.BigIntegerField(blank=True, null=True)
    approval_notes = models.TextField(blank=True, null=True)
    reviewed_at = models.DateTimeField(blank=True, null=True)
    reviewed_by_id = models.BigIntegerField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollvalidationrecord'


class PayrollPayrollwizardprogress(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    current_step = models.BigIntegerField(blank=True, null=True)
    period_name = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    employee_ids = models.TextField(blank=True, null=True)
    validation_results = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollwizardprogress'


class PayrollPayrollworkflowhistory(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    action = models.TextField(blank=True, null=True)
    timestamp = models.DateTimeField(blank=True, null=True)
    old_status = models.TextField(blank=True, null=True)
    new_status = models.TextField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    ip_address = models.TextField(blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)
    performed_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payrollworkflowhistory'


class PayrollPayslip(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    group_name = models.TextField(blank=True, null=True)
    reference = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    pay_head_data = models.TextField(blank=True, null=True)
    contract_wage = models.FloatField(blank=True, null=True)
    basic_pay = models.FloatField(blank=True, null=True)
    gross_pay = models.FloatField(blank=True, null=True)
    deduction = models.FloatField(blank=True, null=True)
    net_pay = models.FloatField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    sent_to_employee = models.BooleanField(blank=True, null=True)
    generation_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_period_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payslip'


class PayrollPayslipInstallmentIds(models.Model):
    id = models.BigAutoField(unique=True)
    payslip_id = models.BigIntegerField(blank=True, null=True)
    deduction_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payslip_installment_ids'
        unique_together = (('payslip_id', 'deduction_id'),)


class PayrollPayslipautogenerate(models.Model):
    id = models.BigAutoField(unique=True)
    generate_day = models.TextField(blank=True, null=True)
    auto_generate = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_payslipautogenerate'


class PayrollPaysliptemplate(models.Model):
    id = models.BigAutoField(unique=True)
    template_name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)
    layout_type = models.TextField(blank=True, null=True)
    primary_color = models.TextField(blank=True, null=True)
    accent_color = models.TextField(blank=True, null=True)
    text_color = models.TextField(blank=True, null=True)
    background_color = models.TextField(blank=True, null=True)
    header_background_color = models.TextField(blank=True, null=True)
    logo_position = models.TextField(blank=True, null=True)
    logo_width = models.BigIntegerField(blank=True, null=True)
    logo_height = models.BigIntegerField(blank=True, null=True)
    show_employee_badge = models.BooleanField(blank=True, null=True)
    show_employee_name = models.BooleanField(blank=True, null=True)
    show_department = models.BooleanField(blank=True, null=True)
    show_designation = models.BooleanField(blank=True, null=True)
    show_joining_date = models.BooleanField(blank=True, null=True)
    show_bank_details = models.BooleanField(blank=True, null=True)
    show_bank_name = models.BooleanField(blank=True, null=True)
    show_pay_period = models.BooleanField(blank=True, null=True)
    show_paid_days = models.BooleanField(blank=True, null=True)
    show_lop_days = models.BooleanField(blank=True, null=True)
    show_actual_basic_pay = models.BooleanField(blank=True, null=True)
    show_taxable_gross = models.BooleanField(blank=True, null=True)
    show_net_pay_in_words = models.BooleanField(blank=True, null=True)
    show_company_address = models.BooleanField(blank=True, null=True)
    font_family = models.TextField(blank=True, null=True)
    header_font_size = models.BigIntegerField(blank=True, null=True)
    body_font_size = models.BigIntegerField(blank=True, null=True)
    page_size = models.TextField(blank=True, null=True)
    margin_top = models.BigIntegerField(blank=True, null=True)
    margin_bottom = models.BigIntegerField(blank=True, null=True)
    margin_left = models.BigIntegerField(blank=True, null=True)
    margin_right = models.BigIntegerField(blank=True, null=True)
    orientation = models.TextField(blank=True, null=True)
    custom_css = models.TextField(blank=True, null=True)
    custom_header_html = models.TextField(blank=True, null=True)
    custom_footer_html = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    company_logo = models.TextField(blank=True, null=True)
    signature_image = models.TextField(blank=True, null=True)
    line_items_config = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_paysliptemplate'
        unique_together = (('company_id_id', 'template_name'),)


class PayrollProfessionaltaxslab(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    state_name = models.TextField(blank=True, null=True)
    state_code = models.TextField(blank=True, null=True)
    min_monthly_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_monthly_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    monthly_tax_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_annual_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    is_default = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_professionaltaxslab'


class PayrollRegionaltaxslab(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    region_code = models.TextField(blank=True, null=True)
    region_name = models.TextField(blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    min_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tax_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_annual_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    country_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_regionaltaxslab'
        unique_together = (('country_id', 'region_code', 'financial_year', 'min_income'),)


class PayrollReimbursement(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    allowance_on = models.DateField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    ad_to_encash = models.FloatField(blank=True, null=True)
    cfd_to_encash = models.FloatField(blank=True, null=True)
    bonus_to_encash = models.BigIntegerField(blank=True, null=True)
    amount = models.FloatField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    allowance_id_id = models.BigIntegerField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    leave_type_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursement'


class PayrollReimbursementOtherAttachments(models.Model):
    id = models.BigAutoField(unique=True)
    reimbursement_id = models.BigIntegerField(blank=True, null=True)
    reimbursementmultipleattachment_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursement_other_attachments'


class PayrollReimbursementfile(models.Model):
    id = models.BigAutoField(unique=True)
    file = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursementfile'


class PayrollReimbursementmultipleattachment(models.Model):
    id = models.BigAutoField(unique=True)
    attachment = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursementmultipleattachment'


class PayrollReimbursementrequestcomment(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursementrequestcomment'


class PayrollReimbursementrequestcommentFiles(models.Model):
    id = models.BigAutoField(unique=True)
    reimbursementrequestcomment_id = models.BigIntegerField(blank=True, null=True)
    reimbursementfile_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_reimbursementrequestcomment_files'
        unique_together = (('reimbursementrequestcomment_id', 'reimbursementfile_id'),)


class PayrollSection80Cproof(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    category = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    proof_document = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    verification_status = models.TextField(blank=True, null=True)
    verification_date = models.DateTimeField(blank=True, null=True)
    verification_comments = models.TextField(blank=True, null=True)
    submission_date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    declaration_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    verified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_section80cproof'


class PayrollTaxbracket(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    min_income = models.FloatField(blank=True, null=True)
    max_income = models.FloatField(blank=True, null=True)
    tax_rate = models.FloatField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    filing_status_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_taxbracket'


class PayrollTaxregime(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    regime_name = models.TextField(blank=True, null=True)
    regime_code = models.TextField(blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    standard_deduction = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    country_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_taxregime'
        unique_together = (('country_id', 'regime_code', 'financial_year'),)


class PayrollTaxslab(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    min_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    max_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tax_rate = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    regime_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_taxslab'


class PayrollTdscalculationcache(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    gross_annual_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    standard_deduction = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    professional_tax_annual = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    section_80c_deduction = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    taxable_income = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    base_income_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    surcharge_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    cess_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_annual_tax = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tds_for_period = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tax_breakdown = models.TextField(blank=True, null=True)
    calculation_date = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_data_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_tdscalculationcache'


class PayrollTdsglobalconfig(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    enable_monthly_edit_window = models.BooleanField(blank=True, null=True)
    edit_window_start_day = models.IntegerField(blank=True, null=True)
    edit_window_end_day = models.IntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    cess_tax_percentage = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_tdsglobalconfig'


class PayrollTdsreconciliation(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    declared_80c_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    verified_80c_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    shortfall_amount = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    tax_on_shortfall = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reconciliation_date = models.DateTimeField(blank=True, null=True)
    notes = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    declaration_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    reconciled_by_id = models.BigIntegerField(blank=True, null=True)
    recovery_period_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_tdsreconciliation'


class PayrollTdssettings(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    financial_year = models.TextField(blank=True, null=True)
    enable_auto_lock = models.BooleanField(blank=True, null=True)
    declaration_lock_date = models.DateField(blank=True, null=True)
    enable_declaration_reminders = models.BooleanField(blank=True, null=True)
    declaration_reminder_days = models.IntegerField(blank=True, null=True)
    enable_proof_reminders = models.BooleanField(blank=True, null=True)
    proof_submission_deadline = models.DateField(blank=True, null=True)
    proof_reminder_days = models.IntegerField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_tdssettings'
        unique_together = (('company_id_id', 'financial_year'),)


class PayrollUserpayrollrole(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    assigned_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    assigned_by_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    payroll_role_id = models.BigIntegerField(blank=True, null=True)
    user_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_userpayrollrole'
        unique_together = (('user_id', 'payroll_role_id', 'company_id'),)


class PayrollWorkrecord(models.Model):
    id = models.BigAutoField(unique=True)
    record_name = models.TextField(blank=True, null=True)
    work_record_type = models.TextField(blank=True, null=True)
    date = models.DateField(blank=True, null=True)
    at_work = models.TextField(blank=True, null=True)
    min_hour = models.TextField(blank=True, null=True)
    at_work_second = models.BigIntegerField(blank=True, null=True)
    min_hour_second = models.BigIntegerField(blank=True, null=True)
    note = models.TextField(blank=True, null=True)
    message = models.TextField(blank=True, null=True)
    is_attendance_record = models.BooleanField(blank=True, null=True)
    is_leave_record = models.BooleanField(blank=True, null=True)
    day_percentage = models.FloatField(blank=True, null=True)
    last_update = models.DateTimeField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'payroll_workrecord'


class PmsAnonymousfeedback(models.Model):
    id = models.BigAutoField(unique=True)
    feedback_subject = models.TextField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_at = models.DateField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    anonymous_feedback_id = models.TextField(blank=True, null=True)
    feedback_description = models.TextField(blank=True, null=True)
    department_id_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_anonymousfeedback'


class PmsAnswer(models.Model):
    id = models.BigAutoField(unique=True)
    answer = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    feedback_id_id = models.BigIntegerField(blank=True, null=True)
    question_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_answer'


class PmsBonuspointsetting(models.Model):
    id = models.BigAutoField(unique=True)
    model = models.TextField(blank=True, null=True)
    applicable_for = models.TextField(blank=True, null=True)
    bonus_for = models.TextField(blank=True, null=True)
    field_1 = models.TextField(blank=True, null=True)
    conditions = models.TextField(blank=True, null=True)
    field_2 = models.TextField(blank=True, null=True)
    points = models.BigIntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_bonuspointsetting'


class PmsComment(models.Model):
    id = models.BigAutoField(unique=True)
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    employee_objective_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_comment'


class PmsEmployeebonuspoint(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    bonus_point = models.BigIntegerField(blank=True, null=True)
    instance = models.TextField(blank=True, null=True)
    based_on = models.TextField(blank=True, null=True)
    bonus_point_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_employeebonuspoint'


class PmsEmployeekeyresult(models.Model):
    id = models.BigAutoField(unique=True)
    key_result = models.TextField(blank=True, null=True)
    key_result_description = models.TextField(blank=True, null=True)
    progress_type = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_at = models.DateField(blank=True, null=True)
    updated_at = models.DateField(blank=True, null=True)
    start_value = models.BigIntegerField(blank=True, null=True)
    current_value = models.BigIntegerField(blank=True, null=True)
    target_value = models.BigIntegerField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    progress_percentage = models.BigIntegerField(blank=True, null=True)
    employee_objective_id_id = models.BigIntegerField(blank=True, null=True)
    key_result_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_employeekeyresult'


class PmsEmployeeobjective(models.Model):
    id = models.BigAutoField(unique=True)
    is_active = models.BooleanField(blank=True, null=True)
    objective = models.TextField(blank=True, null=True)
    objective_description = models.TextField(blank=True, null=True)
    created_at = models.DateField(blank=True, null=True)
    updated_at = models.DateField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    progress_percentage = models.BigIntegerField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    objective_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_employeeobjective'
        unique_together = (('employee_id_id', 'objective_id_id'),)


class PmsEmployeeobjectiveKeyResultId(models.Model):
    id = models.BigAutoField(unique=True)
    employeeobjective_id = models.BigIntegerField(blank=True, null=True)
    keyresult_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_employeeobjective_key_result_id'


class PmsFeedback(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    review_cycle = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    cyclic_feedback = models.BooleanField(blank=True, null=True)
    cyclic_feedback_days_count = models.BigIntegerField(blank=True, null=True)
    cyclic_feedback_period = models.TextField(blank=True, null=True)
    cyclic_next_start_date = models.DateField(blank=True, null=True)
    cyclic_next_end_date = models.DateField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    manager_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    question_template_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_feedback'


class PmsFeedbackColleagueId(models.Model):
    id = models.BigAutoField(unique=True)
    feedback_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_feedback_colleague_id'
        unique_together = (('feedback_id', 'employee_id'),)


class PmsFeedbackEmployeeKeyResultsId(models.Model):
    id = models.BigAutoField(unique=True)
    feedback_id = models.BigIntegerField(blank=True, null=True)
    employeekeyresult_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_feedback_employee_key_results_id'
        unique_together = (('feedback_id', 'employeekeyresult_id'),)


class PmsFeedbackOthersId(models.Model):
    id = models.BigAutoField(unique=True)
    feedback_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_feedback_others_id'
        unique_together = (('feedback_id', 'employee_id'),)


class PmsFeedbackSubordinateId(models.Model):
    id = models.BigAutoField(unique=True)
    feedback_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_feedback_subordinate_id'
        unique_together = (('feedback_id', 'employee_id'),)


class PmsHistoricalcomment(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    employee_objective_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalcomment'


class PmsHistoricalcommentHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalcomment_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalcomment_history_tags'


class PmsHistoricalemployeekeyresult(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    key_result = models.TextField(blank=True, null=True)
    key_result_description = models.TextField(blank=True, null=True)
    progress_type = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    created_at = models.DateField(blank=True, null=True)
    updated_at = models.DateField(blank=True, null=True)
    start_value = models.BigIntegerField(blank=True, null=True)
    current_value = models.BigIntegerField(blank=True, null=True)
    target_value = models.BigIntegerField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    progress_percentage = models.BigIntegerField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    employee_objective_id_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    key_result_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalemployeekeyresult'


class PmsHistoricalemployeekeyresultHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalemployeekeyresult_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalemployeekeyresult_history_tags'


class PmsHistoricalemployeeobjective(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    objective = models.TextField(blank=True, null=True)
    objective_description = models.TextField(blank=True, null=True)
    created_at = models.DateField(blank=True, null=True)
    updated_at = models.DateField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    progress_percentage = models.BigIntegerField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    objective_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalemployeeobjective'


class PmsHistoricalemployeeobjectiveHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalemployeeobjective_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalemployeeobjective_history_tags'


class PmsHistoricalkeyresult(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    progress_type = models.TextField(blank=True, null=True)
    target_value = models.BigIntegerField(blank=True, null=True)
    duration = models.BigIntegerField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalkeyresult'


class PmsHistoricalkeyresultHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalkeyresult_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalkeyresult_history_tags'


class PmsHistoricalobjective(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    duration_unit = models.TextField(blank=True, null=True)
    duration = models.BigIntegerField(blank=True, null=True)
    add_assignees = models.BooleanField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    self_employee_progress_update = models.BooleanField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalobjective'


class PmsHistoricalobjectiveHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalobjective_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_historicalobjective_history_tags'


class PmsKeyresult(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    progress_type = models.TextField(blank=True, null=True)
    target_value = models.BigIntegerField(blank=True, null=True)
    duration = models.BigIntegerField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_keyresult'


class PmsKeyresultfeedback(models.Model):
    id = models.BigAutoField(unique=True)
    answer = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    feedback_id_id = models.BigIntegerField(blank=True, null=True)
    key_result_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_keyresultfeedback'


class PmsMeetings(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    date = models.DateTimeField(blank=True, null=True)
    response = models.TextField(blank=True, null=True)
    show_response = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    question_template_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_meetings'


class PmsMeetingsAnswerEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    meetings_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_meetings_answer_employees'
        unique_together = (('meetings_id', 'employee_id'),)


class PmsMeetingsEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    meetings_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_meetings_employee_id'
        unique_together = (('meetings_id', 'employee_id'),)


class PmsMeetingsManager(models.Model):
    id = models.BigAutoField(unique=True)
    meetings_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_meetings_manager'
        unique_together = (('meetings_id', 'employee_id'),)


class PmsMeetingsanswer(models.Model):
    id = models.BigAutoField(unique=True)
    answer = models.TextField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    meeting_id_id = models.BigIntegerField(blank=True, null=True)
    question_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_meetingsanswer'


class PmsObjective(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    duration_unit = models.TextField(blank=True, null=True)
    duration = models.BigIntegerField(blank=True, null=True)
    add_assignees = models.BooleanField(blank=True, null=True)
    archive = models.BooleanField(blank=True, null=True)
    self_employee_progress_update = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_objective'


class PmsObjectiveAssignees(models.Model):
    id = models.BigAutoField(unique=True)
    objective_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_objective_assignees'
        unique_together = (('objective_id', 'employee_id'),)


class PmsObjectiveKeyResultId(models.Model):
    id = models.BigAutoField(unique=True)
    objective_id = models.BigIntegerField(blank=True, null=True)
    keyresult_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_objective_key_result_id'
        unique_together = (('objective_id', 'keyresult_id'),)


class PmsObjectiveManagers(models.Model):
    id = models.BigAutoField(unique=True)
    objective_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_objective_managers'
        unique_together = (('objective_id', 'employee_id'),)


class PmsPeriod(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    period_name = models.TextField(unique=True, blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_period'


class PmsPeriodCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    period_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_period_company_id'
        unique_together = (('period_id', 'company_id'),)


class PmsQuestion(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    question = models.TextField(blank=True, null=True)
    question_type = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    template_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_question'


class PmsQuestionoptions(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    option_a = models.TextField(blank=True, null=True)
    option_b = models.TextField(blank=True, null=True)
    option_c = models.TextField(blank=True, null=True)
    option_d = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    question_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_questionoptions'


class PmsQuestiontemplate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    question_template = models.TextField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_questiontemplate'


class PmsQuestiontemplateCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    questiontemplate_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pms_questiontemplate_company_id'
        unique_together = (('questiontemplate_id', 'company_id'),)


class ProjectProject(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(unique=True, blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    document = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_project'


class ProjectProjectManagers(models.Model):
    id = models.BigAutoField(unique=True)
    project_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_project_managers'
        unique_together = (('project_id', 'employee_id'),)


class ProjectProjectMembers(models.Model):
    id = models.BigAutoField(unique=True)
    project_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_project_members'
        unique_together = (('project_id', 'employee_id'),)


class ProjectProjectstage(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    is_end_stage = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_projectstage'
        unique_together = (('project_id', 'title'),)


class ProjectTask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    document = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id = models.BigIntegerField(blank=True, null=True)
    stage_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_task'
        unique_together = (('project_id', 'title'),)


class ProjectTaskTaskManagers(models.Model):
    id = models.BigAutoField(unique=True)
    task_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_task_task_managers'
        unique_together = (('task_id', 'employee_id'),)


class ProjectTaskTaskMembers(models.Model):
    id = models.BigAutoField(unique=True)
    task_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_task_task_members'
        unique_together = (('task_id', 'employee_id'),)


class ProjectTimesheet(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    date = models.DateField(blank=True, null=True)
    time_spent = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id_id = models.BigIntegerField(blank=True, null=True)
    task_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'project_timesheet'


class RecruitmentCandidate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    profile = models.TextField(blank=True, null=True)
    portfolio = models.TextField(blank=True, null=True)
    schedule_date = models.DateTimeField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    mobile = models.TextField(blank=True, null=True)
    resume = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    dob = models.DateField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    zip = models.TextField(blank=True, null=True)
    gender = models.TextField(blank=True, null=True)
    source = models.TextField(blank=True, null=True)
    start_onboard = models.BooleanField(blank=True, null=True)
    hired = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    converted = models.BooleanField(blank=True, null=True)
    joining_date = models.DateField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    probation_end = models.DateField(blank=True, null=True)
    offer_letter_status = models.TextField(blank=True, null=True)
    last_updated = models.DateField(blank=True, null=True)
    hired_date = models.DateField(blank=True, null=True)
    converted_employee_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    referral_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_candidate'
        unique_together = (('email', 'recruitment_id_id'),)


class RecruitmentCandidatedocument(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    document = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    reject_reason = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    document_request_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_candidatedocument'


class RecruitmentCandidatedocumentrequest(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    format = models.TextField(blank=True, null=True)
    max_size = models.BigIntegerField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_candidatedocumentrequest'


class RecruitmentCandidatedocumentrequestCandidateId(models.Model):
    id = models.BigAutoField(unique=True)
    candidatedocumentrequest_id = models.BigIntegerField(blank=True, null=True)
    candidate_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_candidatedocumentrequest_candidate_id'


class RecruitmentCandidaterating(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    rating = models.BigIntegerField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_candidaterating'
        unique_together = (('employee_id_id', 'candidate_id_id'),)


class RecruitmentHistoricalcandidate(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    profile = models.TextField(blank=True, null=True)
    portfolio = models.TextField(blank=True, null=True)
    schedule_date = models.DateTimeField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    mobile = models.TextField(blank=True, null=True)
    resume = models.TextField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    country = models.TextField(blank=True, null=True)
    dob = models.DateField(blank=True, null=True)
    state = models.TextField(blank=True, null=True)
    city = models.TextField(blank=True, null=True)
    zip = models.TextField(blank=True, null=True)
    gender = models.TextField(blank=True, null=True)
    source = models.TextField(blank=True, null=True)
    start_onboard = models.BooleanField(blank=True, null=True)
    hired = models.BooleanField(blank=True, null=True)
    canceled = models.BooleanField(blank=True, null=True)
    converted = models.BooleanField(blank=True, null=True)
    joining_date = models.DateField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    probation_end = models.DateField(blank=True, null=True)
    offer_letter_status = models.TextField(blank=True, null=True)
    last_updated = models.DateField(blank=True, null=True)
    hired_date = models.DateField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    converted_employee_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    referral_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_historicalcandidate'


class RecruitmentHistoricalcandidateHistoryTags(models.Model):
    id = models.BigAutoField(unique=True)
    historicalcandidate_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_historicalcandidate_history_tags'
        unique_together = (('historicalcandidate_id', 'audittag_id'),)


class RecruitmentHistoricalrejectedcandidate(models.Model):
    id = models.BigIntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    history_title = models.TextField(blank=True, null=True)
    history_description = models.TextField(blank=True, null=True)
    history_highlight = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    history_id = models.BigAutoField(unique=True)
    history_date = models.DateTimeField(blank=True, null=True)
    history_change_reason = models.TextField(blank=True, null=True)
    history_type = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    history_user_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    history_relation_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_historicalrejectedcandidate'


class RecruitmentHistoricalrejectedcandidateHistoryTags(models.Model):
    id = models.BigAutoField()
    historicalrejectedcandidate_id = models.BigIntegerField(blank=True, null=True)
    audittag_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_historicalrejectedcandidate_history_tags'


class RecruitmentInterviewschedule(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    interview_date = models.DateField(blank=True, null=True)
    interview_time = models.TimeField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    completed = models.BooleanField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_interviewschedule'


class RecruitmentInterviewscheduleEmployeeId(models.Model):
    id = models.BigAutoField(unique=True)
    interviewschedule_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_interviewschedule_employee_id'
        unique_together = (('interviewschedule_id', 'employee_id'),)


class RecruitmentLinkedinaccount(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    username = models.TextField(blank=True, null=True)
    email = models.TextField(blank=True, null=True)
    api_token = models.TextField(blank=True, null=True)
    sub_id = models.TextField(unique=True, blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_linkedinaccount'


class RecruitmentQuestionordering(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)
    question_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_questionordering'


class RecruitmentRecruitment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_event_based = models.BooleanField(blank=True, null=True)
    closed = models.BooleanField(blank=True, null=True)
    is_published = models.BooleanField(blank=True, null=True)
    vacancy = models.BigIntegerField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    linkedin_post_id = models.TextField(blank=True, null=True)
    publish_in_linkedin = models.BooleanField(blank=True, null=True)
    optional_profile_image = models.BooleanField(blank=True, null=True)
    optional_resume = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    linkedin_account_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitment'
        unique_together = (('job_position_id_id', 'start_date', 'company_id_id'),)


class RecruitmentRecruitmentOpenPositions(models.Model):
    id = models.BigAutoField(unique=True)
    recruitment_id = models.BigIntegerField(blank=True, null=True)
    jobposition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitment_open_positions'


class RecruitmentRecruitmentRecruitmentManagers(models.Model):
    id = models.BigAutoField(unique=True)
    recruitment_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitment_recruitment_managers'


class RecruitmentRecruitmentSkills(models.Model):
    id = models.BigAutoField(unique=True)
    recruitment_id = models.BigIntegerField(blank=True, null=True)
    skill_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitment_skills'
        unique_together = (('recruitment_id', 'skill_id'),)


class RecruitmentRecruitmentSurveyTemplates(models.Model):
    id = models.BigAutoField(unique=True)
    recruitment_id = models.BigIntegerField(blank=True, null=True)
    surveytemplate_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitment_survey_templates'
        unique_together = (('recruitment_id', 'surveytemplate_id'),)


class RecruitmentRecruitmentgeneralsetting(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    candidate_self_tracking = models.BooleanField(blank=True, null=True)
    show_overall_rating = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentgeneralsetting'


class RecruitmentRecruitmentsurvey(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_mandatory = models.BooleanField(blank=True, null=True)
    question = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    type = models.TextField(blank=True, null=True)
    options = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentsurvey'


class RecruitmentRecruitmentsurveyJobPositionIds(models.Model):
    id = models.BigAutoField(unique=True)
    recruitmentsurvey_id = models.BigIntegerField(blank=True, null=True)
    jobposition_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentsurvey_job_position_ids'
        unique_together = (('recruitmentsurvey_id', 'jobposition_id'),)


class RecruitmentRecruitmentsurveyRecruitmentIds(models.Model):
    id = models.BigAutoField(unique=True)
    recruitmentsurvey_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentsurvey_recruitment_ids'


class RecruitmentRecruitmentsurveyTemplateId(models.Model):
    id = models.BigAutoField(unique=True)
    recruitmentsurvey_id = models.BigIntegerField(blank=True, null=True)
    surveytemplate_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentsurvey_template_id'
        unique_together = (('recruitmentsurvey_id', 'surveytemplate_id'),)


class RecruitmentRecruitmentsurveyanswer(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    answer_json = models.TextField(blank=True, null=True)
    attachment = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    job_position_id_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_recruitmentsurveyanswer'


class RecruitmentRejectedcandidate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_rejectedcandidate'


class RecruitmentRejectedcandidateRejectReasonId(models.Model):
    id = models.BigAutoField(unique=True)
    rejectedcandidate_id = models.BigIntegerField(blank=True, null=True)
    rejectreason_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_rejectedcandidate_reject_reason_id'


class RecruitmentRejectreason(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_rejectreason'


class RecruitmentResume(models.Model):
    id = models.BigAutoField(unique=True)
    file = models.TextField(blank=True, null=True)
    is_candidate = models.BooleanField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_resume'


class RecruitmentSkill(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_skill'


class RecruitmentSkillzone(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_skillzone'


class RecruitmentSkillzonecandidate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    added_on = models.DateField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    skill_zone_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_skillzonecandidate'


class RecruitmentStage(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    stage = models.TextField(blank=True, null=True)
    stage_type = models.TextField(blank=True, null=True)
    sequence = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    recruitment_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_stage'
        unique_together = (('recruitment_id_id', 'stage'),)


class RecruitmentStageStageManagers(models.Model):
    id = models.BigAutoField(unique=True)
    stage_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_stage_stage_managers'
        unique_together = (('stage_id', 'employee_id'),)


class RecruitmentStagefiles(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    files = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_stagefiles'


class RecruitmentStagenote(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    candidate_can_view = models.BooleanField(blank=True, null=True)
    candidate_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    stage_id_id = models.BigIntegerField(blank=True, null=True)
    updated_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_stagenote'


class RecruitmentStagenoteStageFiles(models.Model):
    id = models.BigAutoField(unique=True)
    stagenote_id = models.BigIntegerField(blank=True, null=True)
    stagefiles_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_stagenote_stage_files'
        unique_together = (('stagenote_id', 'stagefiles_id'),)


class RecruitmentSurveytemplate(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(unique=True, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    is_general_template = models.BooleanField(blank=True, null=True)
    company_id_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'recruitment_surveytemplate'


class SimpleTimesheetCalendarConnection(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    provider = models.TextField(blank=True, null=True)
    access_token = models.TextField(blank=True, null=True)
    refresh_token = models.TextField(blank=True, null=True)
    token_expiry = models.DateTimeField(blank=True, null=True)
    calendar_email = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    last_synced = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_calendar_connection'
        unique_together = (('employee_id', 'provider'),)


class SimpleTimesheetComment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    comment = models.TextField(blank=True, null=True)
    comment_type = models.TextField(blank=True, null=True)
    commented_by_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    timesheet_period_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_comment'


class SimpleTimesheetEntry(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    date = models.DateField(blank=True, null=True)
    activity_name = models.TextField(blank=True, null=True)
    hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    work_location = models.TextField(blank=True, null=True)
    comments = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id = models.BigIntegerField(blank=True, null=True)
    timesheet_period_id = models.BigIntegerField(blank=True, null=True)
    timesheet_project_id = models.BigIntegerField(blank=True, null=True)
    timesheet_task_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_entry'


class SimpleTimesheetPeriod(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    period_start = models.DateField(blank=True, null=True)
    period_end = models.DateField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    total_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_wfo_days = models.BigIntegerField(blank=True, null=True)
    total_wfh_days = models.BigIntegerField(blank=True, null=True)
    total_wfo_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    total_wfh_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    submitted_at = models.DateTimeField(blank=True, null=True)
    approved_at = models.DateTimeField(blank=True, null=True)
    rejection_reason = models.TextField(blank=True, null=True)
    rejected_at = models.DateTimeField(blank=True, null=True)
    approved_by_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_period'
        unique_together = (('employee_id', 'period_start'),)


class SimpleTimesheetTimesheetnotificationsettings(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    daily_enabled = models.BooleanField(blank=True, null=True)
    daily_trigger_time = models.TimeField(blank=True, null=True)
    daily_minimum_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    weekly_enabled = models.BooleanField(blank=True, null=True)
    weekly_trigger_day = models.BigIntegerField(blank=True, null=True)
    weekly_trigger_time = models.TimeField(blank=True, null=True)
    weekly_working_days = models.BigIntegerField(blank=True, null=True)
    weekly_minimum_hours = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    weekly_daily_hours_for_calc = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    adjust_for_leaves = models.BooleanField(blank=True, null=True)
    adjust_for_holidays = models.BooleanField(blank=True, null=True)
    hours_adjustment_per_leave_day = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    hours_adjustment_per_holiday = models.DecimalField(max_digits=65535, decimal_places=65535, blank=True, null=True)
    email_cc_addresses = models.TextField(blank=True, null=True)
    email_bcc_addresses = models.TextField(blank=True, null=True)
    daily_employee_email_subject = models.TextField(blank=True, null=True)
    daily_manager_email_subject = models.TextField(blank=True, null=True)
    daily_employee_email_template = models.TextField(blank=True, null=True)
    daily_manager_email_template = models.TextField(blank=True, null=True)
    weekly_employee_email_subject = models.TextField(blank=True, null=True)
    weekly_manager_email_subject = models.TextField(blank=True, null=True)
    weekly_employee_email_template = models.TextField(blank=True, null=True)
    weekly_manager_email_template = models.TextField(blank=True, null=True)
    excluded_departments = models.TextField(blank=True, null=True)
    excluded_job_positions = models.TextField(blank=True, null=True)
    enable_email_logging = models.BooleanField(blank=True, null=True)
    test_email_addresses = models.TextField(blank=True, null=True)
    company_id = models.BigIntegerField(unique=True, blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    attendance_hours_validation = models.BooleanField(blank=True, null=True)
    weekly_submission_reminder_enabled = models.BooleanField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_timesheetnotificationsettings'


class SimpleTimesheetTimesheetnotificationsettingsExcludedEmploye(models.Model):
    id = models.BigAutoField()
    timesheetnotificationsettings_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'simple_timesheet_timesheetnotificationsettings_excluded_employe'


class TeamsNotificationsAnnouncementacknowledgment(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    announcement_id = models.BigIntegerField(blank=True, null=True)
    acknowledged_at = models.DateTimeField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_announcementacknowledgment'
        unique_together = (('employee_id', 'announcement_id'),)


class TeamsNotificationsBotconversation(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    user_aad_id = models.TextField(blank=True, null=True)
    conversation_id = models.TextField(blank=True, null=True)
    service_url = models.TextField(blank=True, null=True)
    bot_id = models.TextField(blank=True, null=True)
    tenant_id = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(unique=True, blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_botconversation'


class TeamsNotificationsCardaction(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    action_type = models.TextField(blank=True, null=True)
    action_data = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    error_message = models.TextField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_cardaction'


class TeamsNotificationsNotificationtype(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    code = models.TextField(unique=True, blank=True, null=True)
    display_name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    card_template = models.TextField(blank=True, null=True)
    text_template = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_notificationtype'


class TeamsNotificationsTeamsconnection(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    tenant_id = models.TextField(blank=True, null=True)
    client_id = models.TextField(blank=True, null=True)
    client_secret = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    access_token = models.TextField(blank=True, null=True)
    token_expires_at = models.DateTimeField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_teamsconnection'


class TeamsNotificationsTeamsnotification(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    message = models.TextField(blank=True, null=True)
    adaptive_card_json = models.TextField(blank=True, null=True)
    context_data = models.TextField(blank=True, null=True)
    status = models.TextField(blank=True, null=True)
    teams_message_id = models.TextField(blank=True, null=True)
    teams_chat_id = models.TextField(blank=True, null=True)
    error_message = models.TextField(blank=True, null=True)
    scheduled_at = models.DateTimeField(blank=True, null=True)
    sent_at = models.DateTimeField(blank=True, null=True)
    retry_count = models.BigIntegerField(blank=True, null=True)
    max_retries = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    notification_type_id = models.BigIntegerField(blank=True, null=True)
    recipient_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'teams_notifications_teamsnotification'


class TimesheetProject(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    project_code = models.TextField(unique=True, blank=True, null=True)
    client_name = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    is_billable = models.BooleanField(blank=True, null=True)
    start_date = models.DateField(blank=True, null=True)
    end_date = models.DateField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'timesheet_project'


class TimesheetTask(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    name = models.TextField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    task_code = models.TextField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)
    project_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'timesheet_task'
        unique_together = (('project_id', 'name'),)


class TimesheetTaskAssignedEmployees(models.Model):
    id = models.BigAutoField(unique=True)
    timesheettask_id = models.BigIntegerField(blank=True, null=True)
    employee_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'timesheet_task_assigned_employees'
        unique_together = (('timesheettask_id', 'employee_id'),)


class UserNavbarPreference(models.Model):
    id = models.BigAutoField(unique=True)
    selected_apps = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    user_id = models.BigIntegerField(unique=True, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'user_navbar_preference'


class WhatsappProcessedwhatsappmessage(models.Model):
    id = models.BigAutoField(unique=True)
    message_id = models.TextField(unique=True, blank=True, null=True)
    processed_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'whatsapp_processedwhatsappmessage'


class WhatsappWhatsappcredientials(models.Model):
    id = models.BigAutoField(unique=True)
    created_at = models.DateTimeField(blank=True, null=True)
    is_active = models.BooleanField(blank=True, null=True)
    meta_token = models.TextField(blank=True, null=True)
    meta_business_id = models.TextField(blank=True, null=True)
    meta_phone_number_id = models.TextField(blank=True, null=True)
    meta_phone_number = models.TextField(blank=True, null=True)
    created_templates = models.BooleanField(blank=True, null=True)
    meta_webhook_token = models.TextField(blank=True, null=True)
    is_primary = models.BooleanField(blank=True, null=True)
    created_by_id = models.BigIntegerField(blank=True, null=True)
    modified_by_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'whatsapp_whatsappcredientials'


class WhatsappWhatsappcredientialsCompanyId(models.Model):
    id = models.BigAutoField(unique=True)
    whatsappcredientials_id = models.BigIntegerField(blank=True, null=True)
    company_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'whatsapp_whatsappcredientials_company_id'


class WhatsappWhatsappflowdetails(models.Model):
    id = models.BigAutoField(unique=True)
    template = models.TextField(blank=True, null=True)
    flow_id = models.TextField(blank=True, null=True)
    whatsapp_id_id = models.BigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'whatsapp_whatsappflowdetails'
