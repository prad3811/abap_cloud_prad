FUNCTION ZPRAD_FLIGHT_BOOKSUPPL_D.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VALUES) TYPE  /DMO/TT_BOOKSUPPL_M
*"----------------------------------------------------------------------
delete /dmo/booksuppl_m FROM TABLE @values.


ENDFUNCTION.
