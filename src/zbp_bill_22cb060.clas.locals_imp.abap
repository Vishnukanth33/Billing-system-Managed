*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type definitions
CLASS lhc_billing DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS:
      " Actions
      approvebill FOR MODIFY
        IMPORTING keys FOR ACTION Billing~ApproveBill RESULT result,

      markaspaid FOR MODIFY
        IMPORTING keys FOR ACTION Billing~MarkAsPaid RESULT result,

      cancelbill FOR MODIFY
        IMPORTING keys FOR ACTION Billing~CancelBill RESULT result,

      " Determinations
      setbillingid FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Billing~SetBillingID,

      calculateamounts FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Billing~CalculateAmounts,

      " Validations
      validatecustomer FOR VALIDATE ON SAVE
        IMPORTING keys FOR Billing~ValidateCustomer,

      validateduedate FOR VALIDATE ON SAVE
        IMPORTING keys FOR Billing~ValidateDueDate,

      " Authorization
      get_instance_authorizations FOR INSTANCE AUTHORIZATION
        IMPORTING keys REQUEST requested_authorizations FOR Billing RESULT result.

ENDCLASS.

CLASS lhc_billing IMPLEMENTATION.

* ─── ACTION: Approve Bill ───────────────────────────────────────────
  METHOD approvebill.
    MODIFY ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        UPDATE FIELDS ( PaymentStatus )
        WITH VALUE #( FOR key IN keys
                       ( %tky          = key-%tky
                         PaymentStatus = 'Approved' ) )
      REPORTED DATA(update_reported).

    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing ALL FIELDS WITH
        CORRESPONDING #( keys )
      RESULT DATA(billings).

    result = VALUE #( FOR billing IN billings
                       ( %tky   = billing-%tky
                         %param = billing ) ).
  ENDMETHOD.

* ─── ACTION: Mark As Paid ───────────────────────────────────────────
  METHOD markaspaid.
    MODIFY ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        UPDATE FIELDS ( PaymentStatus )
        WITH VALUE #( FOR key IN keys
                       ( %tky          = key-%tky
                         PaymentStatus = 'Paid' ) )
      REPORTED DATA(update_reported).

    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing ALL FIELDS WITH
        CORRESPONDING #( keys )
      RESULT DATA(billings).

    result = VALUE #( FOR billing IN billings
                       ( %tky   = billing-%tky
                         %param = billing ) ).
  ENDMETHOD.

* ─── ACTION: Cancel Bill ────────────────────────────────────────────
  METHOD cancelbill.
    MODIFY ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        UPDATE FIELDS ( PaymentStatus )
        WITH VALUE #( FOR key IN keys
                       ( %tky          = key-%tky
                         PaymentStatus = 'Cancelled' ) )
      REPORTED DATA(update_reported).

    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing ALL FIELDS WITH
        CORRESPONDING #( keys )
      RESULT DATA(billings).

    result = VALUE #( FOR billing IN billings
                       ( %tky   = billing-%tky
                         %param = billing ) ).
  ENDMETHOD.

* ─── DETERMINATION: Set Billing ID ─────────────────────────────────
  METHOD setbillingid.
    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        FIELDS ( BillingID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(billings).

    DATA max_id TYPE i.
    SELECT MAX( billing_id ) FROM zbill_22cb060
      INTO @DATA(lv_max).

    LOOP AT billings INTO DATA(billing)
      WHERE BillingID IS INITIAL.
      max_id = max_id + 1.
      DATA(lv_billing_id) = |BL{ max_id WIDTH = 4 ALIGN = RIGHT PAD = '0' }|.

      MODIFY ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
        ENTITY Billing
          UPDATE FIELDS ( BillingID )
          WITH VALUE #( ( %tky      = billing-%tky
                          BillingID = lv_billing_id ) ).
    ENDLOOP.
  ENDMETHOD.

* ─── DETERMINATION: Calculate Amounts ──────────────────────────────
  METHOD calculateamounts.
    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        FIELDS ( Quantity UnitPrice TaxAmount DiscountAmount )
        WITH CORRESPONDING #( keys )
      RESULT DATA(billings).

    LOOP AT billings INTO DATA(billing).
      DATA(lv_total)    = billing-Quantity * billing-UnitPrice.
      DATA(lv_tax)      = lv_total * billing-TaxAmount / 100.
      DATA(lv_discount) = billing-DiscountAmount.
      DATA(lv_net)      = lv_total + lv_tax - lv_discount.

      MODIFY ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
        ENTITY Billing
          UPDATE FIELDS ( TotalAmount NetAmount )
          WITH VALUE #( ( %tky        = billing-%tky
                          TotalAmount = lv_total
                          NetAmount   = lv_net ) ).
    ENDLOOP.
  ENDMETHOD.

* ─── VALIDATION: Validate Customer ─────────────────────────────────
  METHOD validatecustomer.
    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        FIELDS ( CustomerName CustomerEmail )
        WITH CORRESPONDING #( keys )
      RESULT DATA(billings).

    LOOP AT billings INTO DATA(billing).
      IF billing-CustomerName IS INITIAL.
        APPEND VALUE #(
          %tky        = billing-%tky
          %state_area = 'VALIDATE_CUSTOMER'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Customer Name cannot be empty' )
          %element-CustomerName = if_abap_behv=>mk-on
        ) TO reported-billing.

        APPEND VALUE #( %tky = billing-%tky ) TO failed-billing.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

* ─── VALIDATION: Validate Due Date ─────────────────────────────────
  METHOD validateduedate.
    READ ENTITIES OF ZR_BILL_22CB060 IN LOCAL MODE
      ENTITY Billing
        FIELDS ( BillingDate DueDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(billings).

    LOOP AT billings INTO DATA(billing).
      IF billing-DueDate < billing-BillingDate.
        APPEND VALUE #(
          %tky        = billing-%tky
          %state_area = 'VALIDATE_DUEDATE'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Due Date cannot be earlier than Billing Date' )
          %element-DueDate = if_abap_behv=>mk-on
        ) TO reported-billing.

        APPEND VALUE #( %tky = billing-%tky ) TO failed-billing.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

* ─── AUTHORIZATION ──────────────────────────────────────────────────
  METHOD get_instance_authorizations.
  ENDMETHOD.

ENDCLASS.
