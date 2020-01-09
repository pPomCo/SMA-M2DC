; Modifications
;
; 1. Les customers sont initialisés avec un need choisi au hasard parmi les markets des shops
;    -> tous les needs ont au moins un shop correspondant
;    -> les needs suivent la même distribution que les markets
;    (modif dans init-customers et leave-world)
;
; 1b.Les nouveaux shops sont créés avec le même market que le créateur
;    -> Aucun nouveau market n'est créé
;    -> Plus sensé ? Si un restaurant fonctionne, il ouvre un nouveau resto, pas une laverie :-)
;
; 2. Ajout de bruit dans la position des shops (à l'initialisation)
;    Même effet qu'un clic sur le bouton add-noise (qui devient inutile)
;    -> Permet de distinguer les shops multiples à la même adresse
;    -> Permet de ramener sur la route les shops trop loin
;
; 3. Ajout des sliders pour ne pas mettre des constantes arbitraires
;    en dur dans le code :
;    - customer-vision (à l'origine =0.8)
;    - delay-max (à l'origine =0) <<- j'aurai tendance à l'appeler delay-min.
;      Il est très bien à 2 * customer-vision : le customer ne revient pas dans la même boutique
;    - one-shop-over-n <<- affiche un shop sur n uniquement (à l'initialisation)
;
; 4. Nouveaux shops (duplicate) : ajout uniquement sur les patches 'road' (comme avec add-noise)
;    -> Les customers peuvent y accéder
;
; 5. Ajout d'une turtle 'dollar' qui apparaît seulement pendant un tick sur un shop,
;    lorsqu'un customer consomme (c'est pour moi pour comprendre ce qu'il se passe). C'est un cercle jaune
;
; 6. Retrait du random sur la queue / patience.
;    Peut-être est-il justifié, mais pas entre 0 et 100% de la patience, plutôt entre 75 et 100% par exemple
;    PS : pourquoi avoir une queue-per-customer et une queue-speed ?
;         on devrait pouvoir avoir queue-per-customer = 1 (un mec de plus dans la queue)
;         et tout régler avec queue-speed et patience
;
; 7. Ajout de 'add-well'
;    -> Permet de simuler l'ajout d'une station de bus, etc.
;    -> Positionnement aléatoire (c'est nul !)
;    -> Besoin de recalculer les distances des patches aux puits (c'est bof)
;
; 8. Trucs annexes :
;    - Utilisation de starting-funds à l'initialisation des shops
;    - Taille des shops en log(funds) -> on voit les petits, les gros sont raisonnables
;
; 9. try-to-buy : une version plus efficace (pour mon pauvre PC qui rame, qui rame...)
;
; 10.Les puits sont pondérés : on apparaît et on va plus fréquemment vers les puits de
;    fort poids
;
; 11.Label du shop 'onmouseover'
;
;
; Notes :
;  - il y a deux trucs que je trouve bizarre :
;    - Le coup de 'queue-per-customer' qui est redondant avec 'queue-speed' ou 'patience'.
;      On peut en mettre un à 1 (p.ex. queue-per-customer)
;    - Un customer qui apparaît fait perdre de l'argent à un shop aléatoire.
;      J'ai essayé de mettre une taxe à la place (pour tous les shops, à chaque tick),
;      puis je l'ai enlevée (pas su la paramétrer). Mais elle paraît plus réaliste :-)
;  - Avec certains réglages on arrive à avoir les effets qu'on veut simuler :
;    - Les shops se concentrent sur les entrées et voies principales
;    - Les shops de même type se retrouvent côte-à-côte (forte concurrence)
;    Pour cela j'utilise (au pif) :
;    - Patience = 100, queue-speed = 1, queue-per-customer = 10
;      i.e. si on fixe queue-per-customer à 1, on a patience = 10 et queue-speed = 0.1
;      pour le même résultat
;    - base-money = 3
;    - population = 180
;    - max-duplicate-distance = 5
;    Après quelques milliers de ticks pour faire disparaître les shops mal placés,
;    on observe le regroupement des shops autour des shops bien situés


extensions [ gis ]

breed [customers customer]
breed [shops shop]
breed [dollars dollar]

globals [
  blocks-dataset
  roads-dataset
  shops-dataset
  wells-dataset

  the-wells
  n-wells

  new-shops  ; Compteur
  dead-shops ; Compteur

  ponderated-well-list ; list of well for random ponderated choice
]

patches-own [
  is-road
  is-well
  well-weight

  well-num
  distance-to-wells
]

customers-own [
  need
  destination
  money
  delay
  closest-shop
]

shops-own [
  funds
  market
  queue
  label-text
]


;; =================================
;; Functions relative to THE WORLD
;; =================================


to setup
  clear-all

  load-datasets

  ;set delay-max 0; 3000 ;; délai d'achat, j'ai pas trouvé mieux
  set new-shops 0
  set dead-shops 0
  init-patches
  init-gis
  init-shops
  init-customers

  reset-ticks
end

to go
  ask dollars [die]
  ask customers [ customer-live ]
  ask shops [ shop-live ]
  ask patches [ patch-update ]
  tick
end


;; =================================
;; Functions relative to PATCHES
;; =================================


;; Initialize patches
to init-patches
  init-wells
  init-roads
  ask patches [patch-update]
end


;; Initialize well-related patch attibutes
to init-wells
  ;set the-wells (patch-set patch 5 -5 patch -7 7 patch 14 7 patch -9 -3)
  ;ask the-wells [ set pcolor blue ]

  ;; Default attrs
  ask patches [
    set is-well false
    set well-weight 0
    set well-num -1
  ]

  ;; Attrs from dataset
  set n-wells 0
  foreach gis:feature-list-of wells-dataset [ vector-feature ->
    let location gis:location-of (first (first (gis:vertex-lists-of vector-feature)))
    let p patch item 0 location item 1 location
    ask p [
      set well-weight gis:property-value vector-feature "W"
      set well-num n-wells
      set is-well true
    ]
    set n-wells (n-wells + 1)
  ]

  ;; Global agentset the-wells
  set the-wells patches with [is-well]
  set n-wells count the-wells

  init-ponderated-well-list
end

;; Initialize the ponderated well list
to init-ponderated-well-list
  set ponderated-well-list []
  let i 0
  while [i < n-wells] [
    let a-well one-of the-wells with [well-num = i]
    if a-well = nobody [ print (word i " " n-wells) ]
    let j 0
    let w 1
    if use-weighted-wells [ set w [well-weight] of a-well ]
    while [j < w] [
      set ponderated-well-list fput a-well ponderated-well-list
      set j j + 1
    ]
    set i i + 1
  ]
end



;; Add a new well to the road patches
to add-well
  ask one-of patches with [is-road and not is-well] [
    set is-well true
    set well-weight random 5
    set well-num n-wells
  ]
  set the-wells patches with [is-well]
  set n-wells count the-wells
  init-roads
end



;; Initialize road-related patch attributes
to init-roads

  ;; Default attrs
  ask patches [set is-road false]

  ;; Road patches from dataset
  ask patches gis:intersecting roads-dataset [set is-road true]

  ;; Compute distance to wells
  print "Compute distance to wells..."
  ask patches [
    set distance-to-wells (map [ _ -> 100000 ] (range n-wells))
  ]
  foreach range n-wells [i ->
    ask patches with [well-num = i] [
      set distance-to-wells (replace-item i distance-to-wells 1)
      ask neighbors [ propagate-distance-to-wells i ]
    ]
  ]
end

to propagate-distance-to-wells [i] ;patch procedure
  let ngs neighbors with [is-road]
  if any? ngs [
    let w item i distance-to-wells
    let w2 (min [item i distance-to-wells] of neighbors) + 2
    if w2 < w [
      set distance-to-wells (replace-item i distance-to-wells w2)
      ask neighbors with [is-road] [propagate-distance-to-wells i]
    ]
  ]
end



;; Update patch style wrt its attributes
to patch-update ; patch-procedure
  let draw-wells true
  let draw-roads true
  set pcolor white
  set plabel-color black
  if is-road [
    if display-roads = "plain"   [ set pcolor white - 1 ]
    if display-roads = "density" [ set pcolor white - ((count customers in-radius 5) / 5)]
    if display-roads = "funds"   [ set pcolor white - ((sum [funds] of shops in-radius 5) / 500) ]
    if display-roads = "well0" [ set pcolor white - ((item 0 distance-to-wells) / 15)  ]
    if display-roads = "well1" [ set pcolor white - ((item 1 distance-to-wells) / 15)  ]
    if display-roads = "well2" [ set pcolor white - ((item 2 distance-to-wells) / 15)  ]
  ]
  if draw-wells and is-well [ set pcolor blue ]
end







;; =================================
;; Functions relative to CUSTOMERS
;; =================================


to init-customers
  create-customers population [
    set shape "person"
    set color black
    set size 1.2
    ;set need random 17
    set need [market] of one-of shops ; need: au hasard parmi les 'market' proposés par les boutiques
    set money base-money  ;; il peut acheter qu'une seule fois avec base-money = 1
    set delay delay-max
    ;move-to one-of the-wells
    ;set destination one-of the-wells
    move-to one-of ponderated-well-list
    set destination one-of ponderated-well-list
    set closest-shop nobody
  ]
end

to customer-live  ;turtle procedure
  move-to-destination
  try-to-buy2
end

; Note: version "optimisée" en dessous (nommée try-to-buy2)
to try-to-buy ;turtle procedure
  set delay (delay + 1)
  if money > 0 and delay > delay-max [
    let tmp-need need
    let tmp-money money
    let bought false
    let the-shop one-of shops in-radius customer-vision with [market = tmp-need] ;small optimization
    if the-shop != nobody [
      ask the-shop [
        ;if random queue < patience [
        if queue < patience [
          set bought true
          set queue (queue + queue-per-customer)
          set funds (funds + 1)
          set tmp-money (tmp-money - 1)
          hatch-dollars 1 [
            set shape "circle"
            set size 2
            set color yellow
          ]
        ]
      ]
      if bought [
      set money tmp-money
      set delay 0
      ]
    ]
  ]
end

; Same as before, but faster
to try-to-buy2 ;turtle procedure
  set delay (delay + 1)
  if money > 0 and delay > delay-max [
    ; The close-enough shop of the good type with the shortest waiting lane.
    let the-shop min-one-of shops in-radius customer-vision with [market = [need] of myself] [queue]
    if the-shop != nobody [
      if [queue] of the-shop < patience [
        ask the-shop [
          set queue (queue + queue-per-customer)
          set funds (funds + 1)
          hatch-dollars 1 [
            set shape "circle"
            set size 2
            set color yellow
          ]
        ]
        set money money - 1
        set delay 0
      ]
    ]
  ]
end

;; Move to destination, trying to keep on roads
to move-to-destination ; turtle procedure
  let my-well-num [well-num] of destination
  face min-one-of neighbors with [is-road] [(item my-well-num distance-to-wells) + random-float 1]
  fd random-float 1
  if distance destination < 1 [ leave-world ]
end

;to move-to-destination ; turtle procedure
;  face destination
;  fd random-float 1
;  if distance destination < 1 [ leave-world ]
;end

;; Customer behavior when reaching its exit patch
to leave-world ; turtle-procedure
  ;move-to one-of the-wells
  ;set destination one-of the-wells
  move-to one-of ponderated-well-list
  set destination one-of ponderated-well-list
  let reste (base-money - money)
  set money base-money
  ;set need random 17
  set need [market] of one-of shops ; need: au hasard parmi les 'market' proposés par les boutiques

  ask one-of shops [ set funds (funds - reste) ]
end





;; =================================
;; Functions relative to SHOPS
;; =================================


;; Initialize shops
to init-shops

  ;; Create shops from dataset
  let i 0
  foreach gis:feature-list-of shops-dataset [ vector-feature ->
    if is-displayed vector-feature [
      if i mod one-shop-over-n = 0 [
        let location gis:location-of (first (first (gis:vertex-lists-of vector-feature)))
        create-shops 1 [
          set xcor item 0 location
          set ycor item 1 location
          set market gis:property-value vector-feature "MARKET"
          set label-text gis:property-value vector-feature "GROUPEETAB"
        ]
      ]
      set i  i + 1
    ]
  ]
  ask shops [
    set funds starting-funds
    set size 2
    set shape "house"
    set queue 0
    set label-color black
    shop-update
  ]
  add-noise
end


;; Noise shop locations
to add-noise
  let noise-strength 1
  ask shops [
    set xcor xcor + noise-strength - random-float (2 * noise-strength)
    set ycor ycor + noise-strength - random-float (2 * noise-strength)
    reach-a-road
  ]
end

;; Move misplaced shop on roads
to reach-a-road ;turtle procedure
  if not is-road [move-to min-one-of patches with [is-road] [distance myself]]
end

;; Displayness of a shop according to the 'display-shops' value
to-report is-displayed [vector-feature]

  ;; No filter
  if display-shops = "All" [
    report true
  ]

  ;; Restaurants: market=12
  if display-shops = "Relevant (?)" [
    let m gis:property-value vector-feature "market"
    report (m = 12) or (m = 9) or (m = 16)
  ]

  ;; Restaurants: market=12
  if display-shops = "Restaurants" [
    let m gis:property-value vector-feature "market"
    report (m = 12)
  ]

  ;; Restaurants: market=12
  if display-shops = "Retail stores" [
    let m gis:property-value vector-feature "market"
    report (m = 9)
  ]

  ;; Restaurants: market=12
  if display-shops = "Health" [
    let m gis:property-value vector-feature "market"
    report (m = 16)
  ]

  ;; Defaults -- no shop displayed
  report false
end


;; Update shop style wrt its values
to shop-update ; turtle procedure
  set color color-of-market market
  set size (log funds 2) / 2
  ; if size >= 5 [ set size 5 ]
  ifelse abs(xcor - mouse-xcor) < 1 and abs(ycor - mouse-ycor) < 1 [
    set label label-text
  ] [
    set label ""
  ]
end

;; expend a rich shop
to shop-duplicate ; turtle procedure
  hatch-shops 1 [
    ;set market (random 17)
    ;move-to one-of (patches in-radius max-duplicate-distance)
    set market [market] of myself ;expand with the same kind of shop
    set label-text [label-text] of myself
    move-to one-of (patches with [is-road] in-radius max-duplicate-distance) ;expand only on roads (reachable by customers)
    set funds starting-funds
    set new-shops new-shops + 1
  ]
end

to shop-live ; turtle procedure
;  if queue >= queue-speed [ set queue (queue - queue-speed) ]
  set queue max (list 0 (queue - queue-speed)) ;decrease queue to 0 at last
  if funds <= 1  [
    set dead-shops dead-shops + 1
    die
  ]
  if funds >= 2 * starting-funds [
    shop-duplicate
    set funds (funds - starting-funds)
  ]
  shop-update

  ; Decrease funds according to taxes
  ;set funds funds - taxes
end


;; =================================
;; Functions relative to GIS
;; =================================



to load-datasets

  ; Load dataset
  gis:load-coordinate-system (word "data/maps/" map-name "/blocks.prj")
  set blocks-dataset gis:load-dataset (word "data/maps/" map-name "/blocks.shp")

  gis:load-coordinate-system (word "data/maps/" map-name "/roads.prj")
  set roads-dataset gis:load-dataset (word "data/maps/" map-name "/roads.shp")

  gis:load-coordinate-system (word "data/maps/" map-name "/shops.prj")
  set shops-dataset gis:load-dataset (word "data/maps/" map-name "/shops.shp")

  gis:load-coordinate-system (word "data/maps/" map-name "/wells.prj")
  set wells-dataset gis:load-dataset (word "data/maps/" map-name "/wells.shp")

  ; Adapt sizes
  gis:set-world-envelope (gis:envelope-union-of
    (gis:envelope-of blocks-dataset)
    (gis:envelope-of shops-dataset)
    (gis:envelope-of roads-dataset)
    (gis:envelope-of wells-dataset)
  )

end


;; Draw vector shapes from datasets
to init-gis

  ; Fill shapes
  let fill-shapes false
  if fill-shapes [
    gis:set-drawing-color brown + 2
    gis:fill blocks-dataset 0
  ]

  ; Draw shape boundaries
  gis:set-drawing-color black
  gis:draw blocks-dataset 0

end

;; Color of a market
to-report color-of-market [market_num]
  report (10 * market) + 7
end

;; Market codes:
;;  1 = "Activites de services administratifs et de soutien"
;;  2 = "Activites financieres et d'assurance"
;;  3 = "Activites immobilieres"
;;  4 = "Activites specialisees, scientifiques et techniques"
;;  5 = "Administration publique"
;;  6 = "Agriculture, sylviculture et peche"
;;  7 = "Arts, spectacles et activites recreatives"
;;  8 = "Autres activites de services"
;;  9 = "Commerce ; reparation d'automobiles et de motocycles"
;;  10 = "Construction"
;;  11 = "Enseignement"
;;  12 = "Hebergement et restauration"
;;  13 = "Industrie manufacturiere"
;;  14 = "Information et communication"
;;  15 = "Production et distribution d'electricite, de gaz, de vapeur et d'air conditionne"
;;  16 = "Sante humaine et action sociale"
;;  17 = "Transports et entreposage"
;;  0 = *
@#$#@#$#@
GRAPHICS-WINDOW
185
10
798
474
-1
-1
5.0
1
11
1
1
1
0
0
0
1
-60
60
-45
45
1
1
1
ticks
30.0

CHOOSER
0
45
140
90
map-name
map-name
"rte-de-narbonne" "rue-saint-rome"
0

BUTTON
0
10
73
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
75
10
138
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
575
420
667
465
NIL
count shops
17
1
11

SLIDER
0
185
180
218
population
population
0
300
180.0
2
1
NIL
HORIZONTAL

PLOT
800
10
1015
160
Shops Funds
Funds
Nb shops
0.0
200.0
0.0
200.0
true
false
"" ""
PENS
"default" 10.0 1 -955883 true "" "set-plot-y-range 0 40 histogram [funds] of shops"

SLIDER
0
255
180
288
base-money
base-money
1
10
3.0
1
1
NIL
HORIZONTAL

CHOOSER
0
90
140
135
display-shops
display-shops
"All" "Relevant (?)" "Restaurants" "Retail stores" "Health"
1

CHOOSER
0
135
140
180
display-roads
display-roads
"no" "plain" "density" "funds" "well0" "well1" "well2"
0

PLOT
800
165
1015
315
Needs
NIL
NIL
0.0
17.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [need] of customers"
"pen-1" 1.0 1 -7500403 true "" "histogram [market] of shops"

BUTTON
140
10
215
43
NIL
add-noise
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
365
180
398
queue-speed
queue-speed
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
0
440
180
473
queue-per-customer
queue-per-customer
0
200
10.0
10
1
NIL
HORIZONTAL

SLIDER
0
290
180
323
patience
patience
0
1000
100.0
100
1
NIL
HORIZONTAL

MONITOR
670
420
790
465
NIL
sum [funds] of shops
0
1
11

SLIDER
0
400
180
433
max-duplicate-distance
max-duplicate-distance
1
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
0
330
180
363
starting-funds
starting-funds
10
100
30.0
10
1
NIL
HORIZONTAL

SLIDER
0
220
180
253
customer-vision
customer-vision
0
2
1.2
0.1
1
NIL
HORIZONTAL

PLOT
1020
10
1320
160
Shops
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all-shops" 1.0 0 -16777216 true "" "plot count shops"
"new-shops" 1.0 0 -10899396 true "" "plot new-shops"
"dead-shops" 1.0 0 -2674135 true "" "plot dead-shops"

SLIDER
880
340
1052
373
taxes
taxes
0
0.25
0.03
0.01
1
NIL
HORIZONTAL

BUTTON
220
10
307
43
NIL
add-well
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
880
380
1052
413
delay-max
delay-max
0
100
4.0
1
1
NIL
HORIZONTAL

PLOT
1020
165
1320
315
Average shop state
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"queue" 1.0 0 -16777216 true "" "plot mean [queue] of shops"
"funds" 1.0 0 -7500403 true "" "plot mean [funds] of shops"

SLIDER
880
420
1052
453
one-shop-over-n
one-shop-over-n
1
50
1.0
1
1
NIL
HORIZONTAL

SWITCH
1105
345
1297
378
use-weighted-wells
use-weighted-wells
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
