# ODD model description

Template used: *Grimm V, Berger U, DeAngelis DL, Polhill JG, Giske J, Railsback SF. 1010. The ODD protocol: a review and first update. Ecological Modelling 221: 2760-2768.*

---

## Purpose

The model aim to simulate :

 - business localisation (close to competitors and to high-traffic roads), with the hypothesis that it only depends on customer behaviors.
 - The response to a modification of the customer access.


## Entities, state variables, and scales

We modelize at the *block* level (a few streets)

 - Agents: 
     - Customers:
         - Individual attributes
             - Position (where do they are?)
             - Money (in how many shops they stop and buy?)
             - Needs (which kind of shop they have interest in?)
             - Destination (where do they walk to?)
         - Common variables
             - Delay (minimal time between two buying acts)
             - Vision (how far a shop is accessible)
             - Patience (If a shop's waiting lane (queue) is greater than it, the customer will not buy at this shop)
     - Shops:
         - Individual attributes
             - Market (which kind of activity they do?)
             - Funds (how many *heath* do they have?)
             - Queue (length of the customer waiting lane)
         - Common variables
             - Queue speed (decreasing speed of the waiting lane)
 - Spatial units (patches)
      - Blocks (unreachable locations)
      - Roads (reachable locations)
          - Distance to each well (for efficient local path-finding)
      - Wells (entrances and exits for customers):
          - Weight (how many customers will enter or exit from here?)
 - Environment
 - Collectives

## Process overview and scheduling

#### Customer behavior

Customers are generated at wells, and walk through the map to reach their exit wells. During their walk, they will intend to buy at shops corresponding to their need.

- **Birth/death:**
    - We want the population to be constant, so:
        - Customers are generated at wells during initialization
        - Customers who reach their exit well are instantaneously re-generated in a new entrance well.
    - At birth, state variables are set:
        - *destination*: where the customer leave the world
        - *need*: what the customer buys
- **Walk:**
    - At initialiation, road patches propagate distance to wells, so that every road patch knows its distance to each well.
    - During execution, a customer will move to the road patch that is the closest to her exit well, according to the previously computed values.
- **Buying:**
    - If a customer have at least 1 piece of money, and is enough close to a shop corresponding to its need,
        - If the waiting lane (queue) of the shop is not too long (lower than the customer's patience)
            - The customer give 1 piece of money to the shop.

#### Shop behavior

- **Funds:**
    - Funds increase by 1 when a customer buy in the shop
    - Funds decrease when a new customer is generated: its money is taken from a random shop. It is intended to represent a tax exactly equal to the incoming money, because we want the total amount of fund to remain constant
    
- **Birth/death:**
    - At initialization, shops are created according to the reality (using the Sirene dataset)
    - If a shop reach richness (2 times its starting funds), it pop a new similar shop close to him, and provide its starting funds. 
    - If a shop's funds reach zero, the shop die


## Design concepts

 - Basic principles
 - Emergence
     - Crowd emerge from individual customers, thus waiting lanes (queues) appear in very accessible shops
     - Commercial areas emerge from grouping shops
 - Adaptation
     - If the waiting lane of a shop is greater than *x*, the customer will continue to walk, expecting a new shop on her way
     - If a new source of customer is set, commercial areas are 'moving' (with new shops that open and old ones that close)
 - Objectives
     - The customer intent to satisfy all her needs, that is to spend money in the corresponding shops
     - The customer try to reach her exit well
 - Learning
 - Prediction
 - Sensing
 - Interaction
 - Stochasticity
 - Collectives
 - Observation
 
## Initialization

At *t=0*, the map is initialized with real-world data: roads are load from the *cadastre* dataset and shops from the *Sirene* dataset.

Every shop as the same amount of money, and differ only by its position and market (activity domain).

Wells (entrances and exits) are also geolocated, with a given weight (proportion of customer walking from/to it). 

Customers are initialized with the same amount of money to spent, with a entrance well and an exit well choose at weighted-random. They differ only in their need, so thay don't have interest in the same shops.


## Input data

- The map (buildings and roads) is loaded from the french *cadastre* dataset
- Shops' location and market are loaded from the *Sirene* dataset
