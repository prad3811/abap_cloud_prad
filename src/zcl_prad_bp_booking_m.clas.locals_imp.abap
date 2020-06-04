CLASS lhc_booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalFlightPrice FOR DETERMINATION booking~calculateTotalFlightPrice
      IMPORTING keys FOR booking.

    METHODS validateStatus FOR VALIDATION booking~validateStatus
      IMPORTING keys FOR booking.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR booking RESULT result.

ENDCLASS.

CLASS lhc_booking IMPLEMENTATION.

  METHOD calculateTotalFlightPrice.

  if keys is NOT INITIAL.
  zcl_prad_travel_auxiliary_m=>calculate_price(
              it_travel_id = VALUE #( for GROUPS <booking> of booking_keys in keys
                                        GROUP BY booking_keys-travel_id WITHOUT MEMBERS
                                        ( <booking> ) ) ).
  endif.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITY zprad_I_Travel_M\\booking
    FIELDS ( booking_status ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_result)
    FAILED DATA(lt_failed).

    LOOP AT lt_result INTO DATA(wa_result).
      CASE wa_result-booking_status.
        WHEN 'N'.  " New
        WHEN 'X'.  " Canceled
        WHEN 'B'.  " Booked
        WHEN OTHERS.
          APPEND VALUE #( %key = wa_result-%key ) TO failed.

          APPEND VALUE #( %key = wa_result-%key
                          %msg = new_message( id       = /dmo/cx_flight_legacy=>status_is_not_valid-msgid
                                              number   = /dmo/cx_flight_legacy=>status_is_not_valid-msgno
                                              v1       = wa_result-booking_status
                                              severity = if_abap_behv_message=>severity-error )
                          %element-booking_status = if_abap_behv=>mk-on ) TO reported.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_features.

    READ ENTITY zprad_I_Booking_M FROM VALUE #( FOR wa_key IN keys
                                                      ( %key = wa_key-%key
                                                      %control-booking_id = if_abap_behv=>mk-on
                                                      %control-booking_date = if_abap_behv=>mk-on
                                                      %control-customer_id = if_abap_behv=>mk-on ) )
                                                    RESULT DATA(lt_booking_result).
    result = VALUE #(  FOR ls_booking_result IN lt_booking_result
                            (  %key = ls_booking_result-%key
                                %field-booking_id = if_abap_behv=>fc-f-read_only
                                %field-booking_date = if_abap_behv=>fc-f-read_only
                                %field-customer_id = if_abap_behv=>fc-f-read_only ) )        .
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

ENDCLASS.
