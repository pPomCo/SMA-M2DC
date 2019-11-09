# ODD model description

Template used: *Grimm V, Berger U, DeAngelis DL, Polhill JG, Giske J, Railsback SF. 1010. The ODD protocol: a review and first update. Ecological Modelling 221: 2760-2768.*

---

## Purpose

*Question: What is the purpose of the model?*

The model aim to simulate business response to a modification of the customer access.


## Entities, state variables, and scales

*Questions: What kinds of entities are in the model? By what state variables, or attributes, are these entities characterized? What are the temporal and spatial resolutions and extents of the model?*

We modelize at the *block* level (a few streets)

 - Agents: 
     - Customers:
         - Position (where do they are?)
         - Money (how many they can spend in shops?)
         - Needs (which kind of shop they have interest in?)
         - Destination (where do they walk to?)
     - Shops:
         - Market (which kind of activity they do?)
         - Funds (how many *heath* do they have?)
 - Spatial units
      - Blocks (unreachable locations)
      - Roads (reachable locations)
          - Customer-density (how many customers are here?)
          - Shop-density (how many shops are here?)
      - Wells (entrances and exits for customers):
          - Weight (how many customers will enter or exit from here?)
 - Environment
 - Collectives

## Process overview and scheduling

*Questions: Who (i.e., what entity) does what, and in what order? When are state variables updated? How is time modeled, as discrete steps or as a continuum over which both continuous processes and discrete events can occur? Except for very simple schedules, one should use pseudo-code to describe the schedule in every detail, so that the model can be re-implemented from this code. Ideally, the pseudo-code corresponds fully to the actual code used in the program implementing the ABM.*


## Design concepts

*Questions: There are eleven design concepts. Most of these were discussed extensively by Railsback (2001) and Grimm and Railsback (2005; Chapter. 5), and are summarized here via the following questions:*

 - Basic principles
 - Emergence
 - Adaptation
     - If the waiting lane of a shop is greater than *x*, the customer will continue to walk, expecting a new shop on her way
 - Objectives
     - The customer intent to satisfy all her needs, that is to spend money in the corresponding shops
 - Learning
 - Prediction
 - Sensing
 - Interaction
 - Stochasticity
 - Collectives
 - Observation
## Initialization

*Questions: What is the initial state of the model world, i.e., at time t = 0 of a simulation run? In detail, how many entities of what type are there initially, and what are the exact values of their state variables (or how were they set stochastically)? Is initialization always the same, or is it allowed to vary among simulations? Are the initial values chosen arbitrarily or based on data? References to those data should be provided.*


## Input data

*Question: Does the model use input from external sources such as data files or other models to represent processes that change over time?*


## Submodels

*Questions: What, in detail, are the submodels that represent the processes listed in ‘Process overview and scheduling’? What are the model parameters, their dimensions, and reference values? How were submodels designed or chosen, and how were they parameterized and then tested?*