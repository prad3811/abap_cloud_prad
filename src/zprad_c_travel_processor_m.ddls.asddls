@EndUserText.label: 'projection view for Travel view'
@AccessControl.authorizationCheck: #CHECK

@UI.headerInfo: { typeName: 'Travel', typeNamePlural: 'Travels' , title: { type: #STANDARD , value: 'TravelId' } }
@Search.searchable: true
define root view entity zprad_C_TRAVEL_PROCESSOR_M as projection on zprad_I_Travel_M {
    
@UI.facet: [{ id:  'Tavel',
              purpose: #STANDARD ,
              type: #IDENTIFICATION_REFERENCE,
              label: 'Travel',
              position: 10 },
             { id: 'Booking' ,
                purpose: #STANDARD ,
                type: #IDENTIFICATION_REFERENCE,
                label: 'Booking',
                position: 20,
                targetElement: '_Booking' }]   
                 
@UI: { lineItem: [{ position:  10 , importance: #HIGH} ],
identification: [{ position: 10 , label: 'Travel Id [1,...,99999999]' }] }
@Search.defaultSearchElement: true
key travel_id as TravelId,

@UI: { lineItem: [ { position: 20 , importance: #HIGH }],
identification: [{ position: 20 }],
selectionField: [{ position: 20 }] }
@Consumption.valueHelpDefinition: [{ entity.name: '/DMO/I_Agency', entity.element: 'AgencyID' }]
@ObjectModel.text.element: ['AgencyName']
@Search.defaultSearchElement: true
agency_id as AgencyID,
_Agency.Name as AgencyName,

 @UI: {
          lineItem:       [ { position: 30, importance: #HIGH } ],
          identification: [ { position: 30 } ],
          selectionField: [ { position: 30 } ] }
@Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer', element: 'CustomerID'  } }]
@ObjectModel.text.element: ['CustomerName']   
@Search.defaultSearchElement: true      
customer_id as CustomerId,
_Customer.LastName as CustomerName,
 
      @UI: {
          lineItem:       [ { position: 40, importance: #MEDIUM } ],
          identification: [ { position: 40 } ] }
      begin_date         as BeginDate,
      @UI: {
          lineItem:       [ { position: 41, importance: #MEDIUM } ],
          identification: [ { position: 41 } ] }
      end_date           as EndDate,
      @UI: {
          identification: [ { position: 42 } ] }
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee        as BookingFee,
      @UI: {
          lineItem:       [ { position: 43, importance: #MEDIUM } ],
          identification: [ { position: 43, label: 'Total Price' } ] }
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price        as TotalPrice,
    @Consumption.valueHelpDefinition: [{entity: {name: 'I_Currency', element: 'Currency' }}]
      currency_code      as CurrencyCode,
   @UI: { lineItem:[ { position: 50 , importance: #HIGH ,
                        type: #FOR_ACTION , dataAction: 'createTravelByTemplate' ,label: 'Create Travel by Template' }],
          identification: [{ position: 45 , label: 'Status [O(Open)|A(Accepted)|X(Canceled)]' }] }
overall_status as TravelStatus,
     @UI: {
          identification:[ { position: 46 } ]  }
      description        as Description,
            @UI.hidden: true
      last_changed_at    as LastChangedAt,
      _Booking : redirected to composition child zprad_C_BOOKING_PROCESSOR_M,
      _Agency,
      _Customer               

}
