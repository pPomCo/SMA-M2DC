# Tasks

## GeoData

 - Add wells 
 - Add roads
 - Add integer id for activity (*market*)
 - Add subcategories 
     - *Restauration*
     - *Commerces de détail*
 - Add integer id for subcategories

## Behavior

 - Explicit customer behavior:
     - Population:
         - Fixed (initial placement and teleportation at wells)
         - Dynamic (birth/death at wells)
     - Buying (wrt needs)
     - Walk (path finding wrt density ?)
 - Explicit shop behavior
     - Health (funds)
     - Birth/death

## Implementation

 - Init shops from geoData
 - Init wells from geoData
 - Walk procedure
 - Buy procedure
 - Shop update procedure
 - Shop change procedure
