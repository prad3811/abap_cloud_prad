@AbapCatalog.sqlViewName: 'ZPR_AIRPRT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'airports table'
define view zprad_airport_cds
  as select from /dmo/airport
{
 @ObjectModel.text.element: ['Name']
 @Search.defaultSearchElement: true
 @Search.fuzzinessThreshold: 0.7
  key airport_id,
  @Semantics.text: true
      name as Name,
      city,
      country
}
