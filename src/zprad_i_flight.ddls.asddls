@AbapCatalog.sqlViewName: 'ZPRAD_V_FLT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'connections information'
@Search.searchable: true
define view zprad_i_flight_con
  as select from /dmo/connection as Connection
  association [1..*] to /DMO/I_Flight_R   as _Flight   on  $projection.AirlineID    = _Flight.AirlineID
                                                       and $projection.ConnectionID = _Flight.ConnectionID
  association [1]    to /DMO/I_Carrier    as _Airline  on  $projection.AirlineID = _Airline.AirlineID
  association [1]    to zprad_airport_cds as _Airports on  $projection.DepartureAirport = _Airports.airport_id
{
        @UI.facet: [ { id: 'Connection',
                        purpose: #STANDARD,
                        type:#IDENTIFICATION_REFERENCE,
                        label: 'Connection',
                        position: 10 },
                      { id:     'Flight',
                        purpose:  #STANDARD,
                        type:     #LINEITEM_REFERENCE,
                        label:    'Flight',
                        position: 20,
                        targetElement: '_Flight'},
                      { id:     'Airport',
                        purpose:  #STANDARD,
                        type:      #LINEITEM_REFERENCE,
                        label:    'Aiport',
                        position: 30,
                        targetElement: '_Airports'}
                        ]
        @UI.lineItem: [ { position: 10, label: 'Airline'} ]
        @ObjectModel.text.association: '_Airline'
        @Search.defaultSearchElement: true
  key   Connection.carrier_id      as AirlineID,
        @UI.lineItem: [ { position: 20, label:'Connection Number' } ]
  key   Connection.connection_id   as ConnectionID,
        @UI.lineItem: [ { position: 30, label: 'Departure Airport Code' } ]
        @UI.selectionField: [{position: 10 }]
        @ObjectModel.text.association: '_Airports'
        @Consumption.valueHelpDefinition: [{  entity: {   name: '/DMO/I_Airport',
                                    element:    'AirportID' } }]
        @Search.defaultSearchElement: true
        @Search.fuzzinessThreshold: 0.5
        Connection.airport_from_id as DepartureAirport,
        @UI.lineItem: [ { position: 40, label: 'Destination Airport Code' } ]
        @Consumption.valueHelpDefinition: [{  entity: {   name: '/DMO/I_Airport',
                                    element:    'AirportID' } }]
        @UI.selectionField: [{position: 20 }]
        Connection.airport_to_id   as DestinationAirport,
//        @Search.defaultSearchElement: true
//        @Search.fuzzinessThreshold: 0.8
//        _Airports.Name,
        @UI.lineItem: [ { position: 50 , label: 'Departure Time'} ]
        Connection.departure_time  as DepartureTime,
        @UI.lineItem: [ { position: 60 ,  label: 'Arrival Time' } ]
        Connection.arrival_time    as ArrivalTime,
        @Semantics.quantity.unitOfMeasure: 'DistanceUnit'
        @UI: { identification:[ { position: 70, label: 'Distance' } ] }
        Connection.distance        as Distance,
        @Semantics.unitOfMeasure: true
        Connection.distance_unit   as DistanceUnit,
        /* Associations */
        @Search.defaultSearchElement: true
        _Flight,
        _Airline,
        @Search.defaultSearchElement: true
        _Airports
}
