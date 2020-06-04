CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS validateAgency FOR VALIDATION travel~validateAgency
      IMPORTING keys FOR travel.

    METHODS validateCustomer FOR VALIDATION travel~validateCustomer
      IMPORTING keys FOR travel.

    METHODS validateDates FOR VALIDATION travel~validateDates
      IMPORTING keys FOR travel.

    METHODS validateStatus FOR VALIDATION travel~validateStatus
      IMPORTING keys FOR travel.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~acceptTravel RESULT result.

    METHODS createTravelByTemplate FOR MODIFY
      IMPORTING keys FOR ACTION travel~createTravelByTemplate  RESULT result  .

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejectTravel RESULT result.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.


ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD validateAgency.

*    DATA wa_key LIKE LINE OF keys.
    DATA it_key LIKE keys.
    it_key = keys.
    READ ENTITIES OF zprad_i_travel_m IN LOCAL MODE
    ENTITY travel
    FIELDS ( agency_id ) WITH  VALUE #( FOR wa IN keys ( %key-travel_id = wa-%key-travel_id ) )
    RESULT DATA(lt_travel)
    FAILED DATA(it_failed).

    DATA(wa_travel) = lt_travel[ 1 ] .

    SELECT SINGLE 'X' FROM /DMO/I_Agency
    WHERE AgencyID = @wa_travel-agency_id
    INTO @DATA(lv_dummy).
    IF lv_dummy IS INITIAL.
      failed = VALUE #( ( %key-travel_id = wa_travel-travel_id )  ).
      reported = VALUE #( ( travel_id = wa_travel-travel_id
                             %msg = new_message( id = '/DMO/CM_FLIGHT_LEGAC'
                                                number = '001'
                                                 severity = if_abap_behv_message=>severity-error
                                                 v1 = wa_travel-agency_id  )
                             %element-agency_id = if_abap_behv=>mk-on ) ).

    ENDIF.

  ENDMETHOD.

  METHOD validateCustomer.

    READ ENTITIES OF  zprad_I_Travel_M  IN LOCAL MODE
    ENTITY travel
    FIELDS ( customer_id )
    WITH CORRESPONDING #(  keys )
    RESULT DATA(lt_travel).

    DATA lt_customer TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.

    READ TABLE lt_travel INTO DATA(wa_travel) INDEX 1.
    SELECT SINGLE 'X' FROM /dmo/customer
    WHERE customer_id =   @wa_travel-customer_id
    INTO @DATA(lv_dummy).

    IF lv_dummy IS INITIAL.
      failed = VALUE #(  ( %key-travel_id = wa_travel-travel_id ) ).
      reported = VALUE #( ( travel_id = wa_travel-travel_id
                            %msg =  new_message( id = '/DMO/CM_FLIGHT_LEGAC'
                                                  number    = '002'
                                                   v1       = wa_travel-customer_id
                                                   severity = if_abap_behv_message=>severity-error )
                             %element-customer_id = if_abap_behv=>mk-on )  ) .
    ENDIF.
  ENDMETHOD.

  METHOD validateDates.

    READ ENTITIES OF zprad_I_Travel_M
    ENTITY travel
    FIELDS ( begin_date end_date ) WITH VALUE #( FOR wa IN keys ( %key-travel_id = wa-%key-travel_id ) )
    RESULT DATA(lt_travel)
    FAILED DATA(it_failed).

    LOOP AT lt_travel INTO DATA(ls_travel_result).

      " Check if end_date is not before begin_date
      IF ls_travel_result-end_date < ls_travel_result-begin_date.
        APPEND VALUE #( %key        = ls_travel_result-%key
                        travel_id   = ls_travel_result-travel_id ) TO failed.
        APPEND VALUE #( %key     = ls_travel_result-%key
                        %msg     = new_message( id       = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgid
                                                number   = /dmo/cx_flight_legacy=>end_date_before_begin_date-msgno
                                                v1       = ls_travel_result-begin_date
                                                v2       = ls_travel_result-end_date
                                                v3       = ls_travel_result-travel_id
                                                    severity = if_abap_behv_message=>severity-error )
                            %element-begin_date = if_abap_behv=>mk-on
                            %element-end_date   = if_abap_behv=>mk-on ) TO reported.
      ELSEIF ls_travel_result-begin_date < cl_abap_context_info=>get_system_date( ).

        APPEND VALUE #( %key        = ls_travel_result-%key
                        travel_id   = ls_travel_result-travel_id ) TO failed.

        APPEND VALUE #( %key = ls_travel_result-%key
                        %msg = new_message( id       = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgid
                                            number   = /dmo/cx_flight_legacy=>begin_date_before_system_date-msgno
                                            severity = if_abap_behv_message=>severity-error )
                        %element-begin_date = if_abap_behv=>mk-on
                        %element-end_date   = if_abap_behv=>mk-on ) TO reported.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITY zprad_I_Travel_M\\travel FIELDS ( overall_status ) WITH
         VALUE #( FOR <root_key> IN keys ( %key = <root_key> ) )
         RESULT DATA(lt_travel_result).

    LOOP AT lt_travel_result INTO DATA(ls_travel_result).
      CASE ls_travel_result-overall_status.
        WHEN 'O'.  " Open
        WHEN 'X'.  " Cancelled
        WHEN 'A'.  " Accepted

        WHEN OTHERS.
          APPEND VALUE #( %key = ls_travel_result-%key ) TO failed.

          APPEND VALUE #( %key = ls_travel_result-%key
                          %msg = new_message( id       = /dmo/cx_flight_legacy=>status_is_not_valid-msgid
                                              number   = /dmo/cx_flight_legacy=>status_is_not_valid-msgno
                                              v1       = ls_travel_result-overall_status
                                              severity = if_abap_behv_message=>severity-error )
                          %element-overall_status = if_abap_behv=>mk-on )
                 TO reported.
      ENDCASE.

    ENDLOOP.
  ENDMETHOD.

  METHOD acceptTravel.

    MODIFY ENTITIES OF zprad_i_travel_m IN LOCAL MODE
         ENTITY travel
            UPDATE FIELDS ( overall_status )
               WITH VALUE #( FOR key IN keys ( travel_id      = key-travel_id
                                               overall_status = 'A' ) ) " Accepted
         FAILED   failed
         REPORTED reported.
    " Read changed data for action result
    READ ENTITIES OF zprad_I_Travel_M IN LOCAL MODE
         ENTITY travel
           FIELDS ( agency_id
                    customer_id
                    begin_date
                    end_date
                    booking_fee
                    total_price
                    currency_code
                    overall_status
                    description
                    created_by
                    created_at
                    last_changed_at
                    last_changed_by )
             WITH VALUE #( FOR key IN keys ( travel_id = key-travel_id ) )
         RESULT DATA(lt_travel).
    result = VALUE #( FOR travel IN lt_travel ( travel_id = travel-travel_id
                                                  %param    = travel ) ).

  ENDMETHOD.

  METHOD createTravelByTemplate.

    SELECT MAX( travel_id ) FROM /dmo/travel_m INTO @DATA(lv_travel_id).

    READ ENTITY /dmo/i_travel_m

          FIELDS ( travel_id
                   agency_id
                   customer_id
                   booking_fee
                   total_price
                  currency_code
                      )
            WITH VALUE #( FOR travel IN keys (  %key = travel-%key ) )
          RESULT    DATA(lt_read_result)
          FAILED    DATA(it_failed)
          REPORTED  DATA(it_reported).
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    DATA lt_create TYPE TABLE FOR CREATE zprad_I_Travel_M\\travel.

    lt_create = VALUE #( FOR row IN  lt_read_result INDEX INTO idx
                             ( travel_id      = lv_travel_id + idx
                               agency_id      = row-agency_id
                               customer_id    = row-customer_id
                               begin_date     = lv_today
                               end_date       = lv_today + 30
                               booking_fee    = row-booking_fee
                               total_price    = row-total_price
                               currency_code  = row-currency_code
                               description    = 'Enter your comments here'
                               overall_status = 'O' ) ). " Open
    MODIFY ENTITIES OF zprad_i_travel_m IN LOCAL MODE
          ENTITY travel
             CREATE FIELDS (    travel_id
                                agency_id
                                customer_id
                                begin_date
                                end_date
                                booking_fee
                                total_price
                                currency_code
                                description
                                overall_status )
             WITH lt_create
           MAPPED   mapped
           FAILED   failed
           REPORTED reported.
    result = VALUE #( FOR create IN  lt_create INDEX INTO idx
                             ( %cid_ref = keys[ idx ]-%cid_ref
                               %key     = keys[ idx ]-travel_id
                               %param   = CORRESPONDING #(  create ) ) ) .
  ENDMETHOD.

  METHOD rejectTravel.
    MODIFY ENTITIES OF zprad_i_travel_m IN LOCAL MODE
             ENTITY travel
                UPDATE FIELDS ( overall_status )
                   WITH VALUE #( FOR key IN keys ( travel_id      = key-travel_id
                                                   overall_status = 'X' ) ) " Rejected
             FAILED   failed
             REPORTED reported.
    " Read changed data for action result
    READ ENTITIES OF zprad_I_Travel_M IN LOCAL MODE
         ENTITY travel
           FIELDS ( agency_id
                    customer_id
                    begin_date
                    end_date
                    booking_fee
                    total_price
                    currency_code
                    overall_status
                    description
                    created_by
                    created_at
                    last_changed_at
                    last_changed_by )
             WITH VALUE #( FOR key IN keys ( travel_id = key-travel_id ) )
         RESULT DATA(lt_travel).
    result = VALUE #( FOR travel IN lt_travel ( travel_id = travel-travel_id
                                                  %param    = travel ) ).
  ENDMETHOD.

  METHOD get_features.
    READ ENTITY zprad_i_travel_m FROM VALUE #( FOR keyval IN keys
                                    (  %key                    = keyval-%key
                                       %control-travel_id      = if_abap_behv=>mk-on ) )
                                 RESULT DATA(lt_travel_result).

    result = VALUE #( FOR ls_travel IN lt_travel_result
                       ( %key                           = ls_travel-%key
                         %field-travel_id               = if_abap_behv=>fc-f-read_only
                         %features-%action-rejectTravel = COND #( WHEN ls_travel-overall_status = 'X'
                                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled  )
                         %features-%action-acceptTravel = COND #( WHEN ls_travel-overall_status = 'A'
                                                                    THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled  )
                      ) ).

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M IMPLEMENTATION.

  METHOD save_modified.
    DATA: it_log_travel TYPE STANDARD TABLE OF /dmo/log_travel.
    " additional save for create
    IF create-travel IS NOT INITIAL.
      LOOP AT create-travel INTO DATA(ls_travel).
        IF ls_travel-%control-overall_status = cl_abap_behv=>flag_changed.
          TRY.
              DATA(lv_guid) = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          GET TIME STAMP FIELD  DATA(lv_created_at) .
          it_log_travel   = VALUE #( ( travel_id = ls_travel-travel_id
                                       changing_operation = 'Create'
                                       change_id = lv_guid
                                       changed_field_name = 'overall_status'
                                       changed_value = ls_travel-overall_status
                                       created_at = lv_created_at ) ).

        ENDIF.

        IF ls_travel-%control-booking_fee = cl_abap_behv=>flag_changed.
          TRY.
              lv_guid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          GET TIME STAMP FIELD  lv_created_at.
          it_log_travel   = VALUE #( ( travel_id = ls_travel-travel_id
                                       changing_operation = 'Create'
                                       change_id = lv_guid
                                       changed_field_name = 'booking_fee'
                                       changed_value = ls_travel-booking_fee
                                       created_at = lv_created_at ) ).

        ENDIF.

      ENDLOOP.
      INSERT /dmo/log_travel FROM TABLE @it_log_travel.
    ENDIF.
    " additional save for update
    IF update-travel IS NOT INITIAL.
      LOOP AT update-travel INTO ls_travel.
        IF ls_travel-%control-overall_status = if_abap_behv=>mk-on.
          TRY.
              lv_guid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          GET TIME STAMP FIELD  lv_created_at .
          it_log_travel   = VALUE #( ( travel_id = ls_travel-travel_id
                                       changing_operation = 'Update'
                                       change_id = lv_guid
                                       changed_field_name = 'overall_status'
                                       changed_value = ls_travel-overall_status
                                       created_at = lv_created_at ) ).

        ENDIF.

        IF ls_travel-%control-booking_fee = if_abap_behv=>mk-on.
          TRY.
              lv_guid = cl_system_uuid=>create_uuid_x16_static( ).
            CATCH cx_uuid_error.
          ENDTRY.
          GET TIME STAMP FIELD  lv_created_at.
          it_log_travel   = VALUE #( ( travel_id = ls_travel-travel_id
                                       changing_operation = 'Update'
                                       change_id = lv_guid
                                       changed_field_name = 'booking_fee'
                                       changed_value = ls_travel-booking_fee
                                       created_at = lv_created_at ) ).

        ENDIF.

      ENDLOOP.
      INSERT /dmo/log_travel FROM TABLE @it_log_travel.
    ENDIF.
    " additional save for delete
    IF delete-travel IS NOT INITIAL.
      LOOP AT delete-travel INTO DATA(ls_travel_del).
        TRY.
            lv_guid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.
        GET TIME STAMP FIELD  lv_created_at.
        it_log_travel   = VALUE #( ( travel_id = ls_travel_del-travel_id
                                     changing_operation = 'Delete'
                                     change_id = lv_guid
                                     created_at = lv_created_at ) ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
