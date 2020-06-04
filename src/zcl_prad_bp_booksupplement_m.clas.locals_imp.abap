CLASS lhc_booksuppl DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateTotalSupplmPrice FOR DETERMINATION booksuppl~calculateTotalSupplmPrice
      IMPORTING keys FOR booksuppl.

    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR booksuppl RESULT result.

ENDCLASS.

CLASS lhc_booksuppl IMPLEMENTATION.

  METHOD calculateTotalSupplmPrice.
    IF keys IS NOT INITIAL.
      zcl_prad_travel_auxiliary_m=>calculate_price(
                                    it_travel_id = VALUE #( FOR GROUPS <travel_id> OF  wa IN keys
                                    GROUP BY wa-travel_id WITHOUT MEMBERS
                                    ( <travel_id> ) )  ).
    ENDIF.
  ENDMETHOD.

  METHOD get_features.
    READ ENTITY zprad_I_BookSuppl_M FROM VALUE #( FOR wa_key IN keys
                                                 ( %key = wa_key-%key
                                                    %control-booking_supplement_id = if_Abap_behv=>mk-on ) )
                                                    RESULT DATA(lt_book_suppl_result).
    result = VALUE #( FOR wa_book_suppl_result IN lt_book_suppl_result
                           ( %key = wa_book_suppl_result-%key
                                %field-booking_supplement_id = if_abap_behv=>fc-f-read_only ) )     .
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zprad_I_Travel_M IMPLEMENTATION.

  METHOD save_modified.
    DATA lt_booksuppl_db TYPE STANDARD TABLE OF /dmo/booksuppl_m.

    IF create-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( create-booksuppl ).

      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_C' EXPORTING values = lt_booksuppl_db .

    ENDIF.

    IF update-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( update-booksuppl ).

      " Read all field values from database
      SELECT * FROM /dmo/booksuppl_m FOR ALL ENTRIES IN @lt_booksuppl_db
               WHERE booking_supplement_id = @lt_booksuppl_db-booking_supplement_id
               INTO TABLE @lt_booksuppl_db .
      LOOP AT update-booksuppl ASSIGNING FIELD-SYMBOL(<ls_unmanaged_booksuppl>).
        ASSIGN lt_booksuppl_db[ travel_id  = <ls_unmanaged_booksuppl>-travel_id
                                booking_id = <ls_unmanaged_booksuppl>-booking_id
                     booking_supplement_id = <ls_unmanaged_booksuppl>-booking_supplement_id
                       ] TO FIELD-SYMBOL(<ls_booksuppl_db>).

        IF <ls_unmanaged_booksuppl>-%control-supplement_id = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-supplement_id = <ls_unmanaged_booksuppl>-supplement_id.
        ENDIF.

        IF <ls_unmanaged_booksuppl>-%control-price = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-price = <ls_unmanaged_booksuppl>-price.
        ENDIF.

        IF <ls_unmanaged_booksuppl>-%control-currency_code = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-currency_code = <ls_unmanaged_booksuppl>-currency_code.
        ENDIF.

      ENDLOOP.
      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_U' EXPORTING values = lt_booksuppl_db .
    ENDIF.

     IF delete-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( delete-booksuppl ).

      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_D' EXPORTING values = lt_booksuppl_db .

    ENDIF.

  ENDMETHOD.

ENDCLASS.
