@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Billing Root View 22CB060'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define root view entity ZR_BILL_22CB060
  as select from zbill_22cb060
{
  key billing_uuid         as BillingUUID,
      billing_id           as BillingID,
      customer_name        as CustomerName,
      customer_email       as CustomerEmail,
      billing_date         as BillingDate,
      due_date             as DueDate,
      item_description     as ItemDescription,
      quantity             as Quantity,
      unit_price           as UnitPrice,
      total_amount         as TotalAmount,
      tax_amount           as TaxAmount,
      discount_amount      as DiscountAmount,
      net_amount           as NetAmount,
      payment_status       as PaymentStatus,
      payment_method       as PaymentMethod,
      created_by           as CreatedBy,
      created_at           as CreatedAt,
      last_changed_by      as LastChangedBy,
      last_changed_at      as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt
}
